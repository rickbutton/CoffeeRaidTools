---@class Private
local Private = select(2, ...)

-- Coffee's replacement for NSRT's pre-pull player checks. NSRT runs these
-- only on ready check; we also fire on BigWigs pull so the reminder lands
-- with enough time to actually do something about it before engage.
--
-- Ports from vendor/NorthernSkyRaidTools/ReadyCheck.lua:
--   NSI:BuffCheck         -> CheckRaidBuff        (class raid buff)
--   NSI:SoulstoneCheck    -> CheckSoulstone       (warlock)
--   NSI:SourceOfMagicCheck-> CheckSourceOfMagic   (augmentation evoker)
--
-- Class ID → raid buff spell ID (or list of spell IDs for Evoker, whose buff
-- has one spell ID per class of target). Mirrors NSRT's `buffs` table.
---@type table<number, number|number[]>
local BUFFS_BY_CLASS = {
    [1] = 6673, -- Warrior: Battle Shout
    [5] = 21562, -- Priest: Power Word: Fortitude
    [7] = 462854, -- Shaman: Skyfury
    [8] = 1459, -- Mage: Arcane Intellect
    [11] = 1126, -- Druid: Mark of the Wild
    [13] = { -- Evoker: Blessing of the Bronze (one spell ID per target class)
        381741,
        381757,
        381756,
        381732,
        381752,
        381748,
        381750,
        381749,
        381746,
        381751,
        381753,
        381754,
        381758,
    },
}

-- Classes whose buff applies to every raid member regardless of spec. Matches
-- NSRT's `class == 5 or class == 13 or class == 11 or class == 7` shortcut.
local CLASSES_THAT_ALWAYS_BUFF = {
    [5] = true, -- Priest
    [7] = true, -- Shaman
    [11] = true, -- Druid
    [13] = true, -- Evoker
}

-- For buff classes that only target some specs (warrior Battle Shout for melee,
-- mage Intellect for casters), NSRT keeps a per-class list of specIDs that
-- want the buff. Copied verbatim from vendor/NorthernSkyRaidTools/
-- ReadyCheck.lua `buffrequired` — keep in sync.
---@type table<number, table<number, boolean>>
local BUFF_REQUIRED_SPECS = {}
local function setSpecs(classID, specIDs)
    BUFF_REQUIRED_SPECS[classID] = {}
    for _, id in ipairs(specIDs) do
        BUFF_REQUIRED_SPECS[classID][id] = true
    end
end

setSpecs(1, { -- Battle Shout
    1,
    2,
    3,
    4,
    6,
    7,
    10,
    11,
    12,
    250,
    251,
    252,
    577,
    581,
    103,
    104,
    253,
    254,
    255,
    268,
    269,
    66,
    70,
    259,
    260,
    261,
    263,
    71,
    72,
    73,
})
setSpecs(8, { -- Arcane Intellect
    2,
    5,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    1480,
    102,
    105,
    1467,
    1468,
    1473,
    62,
    63,
    64,
    270,
    65,
    256,
    257,
    258,
    262,
    264,
    265,
    266,
    267,
})

---Does `unit` want the player's class buff? Always-buff classes apply to
---everyone; warrior / mage fall back to a spec list, with unit class ID used
---as a best-effort fallback when no peer spec has been received yet. Mirrors
---NSRT's `self.specs and self.specs[unit] or select(3, UnitClass(unit))`.
---@param unit string
---@param playerClassID number
---@return boolean
local function UnitWantsBuff(unit, playerClassID)
    if CLASSES_THAT_ALWAYS_BUFF[playerClassID] then
        return true
    end
    local required = BUFF_REQUIRED_SPECS[playerClassID]
    if not required then
        return false
    end
    local specOrClass = Private:GetUnitSpec(unit) or select(3, UnitClass(unit))
    return specOrClass and required[specOrClass] or false
end

---@param spellID number
---@return string?
local function SpellName(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.name or nil
end

---Return the rebuff reminder text (e.g. "Rebuff Battle Shout") for the given
---class ID, or nil if that class has no raid buff we track.
---@param classID number
---@return string?
local function RebuffTextForClass(classID)
    local spellID = BUFFS_BY_CLASS[classID]
    if not spellID then
        return nil
    end
    if type(spellID) == "table" then
        spellID = spellID[1]
    end
    local name = SpellName(spellID)
    if not name then
        return nil
    end
    return "Rebuff " .. name
end

---@param unit string
---@param singleSpellID number
local function FindAuraByID(unit, singleSpellID)
    local info = C_Spell.GetSpellInfo(singleSpellID)
    if not info then
        return nil
    end
    return C_UnitAuras.GetAuraDataBySpellName(unit, info.name)
end

---Look up the player's raid buff aura on `unit`. Returns the aura table if
---present, or nil if the unit doesn't have it.
---@param unit string
---@param spellID number|number[]
local function FindAura(unit, spellID)
    if type(spellID) == "table" then
        for _, id in ipairs(spellID) do
            local aura = FindAuraByID(unit, id)
            if aura then
                return aura
            end
        end
        return nil
    end
    return FindAuraByID(unit, spellID)
end

---Return true if any eligible raid member is missing the player's raid buff
---(or has it from a source who's no longer in the group). Gated on the target
---unit's spec so casters don't trigger a Battle Shout rebuff and vice versa.
---@return boolean
local function AnyoneNeedsRebuff()
    local _, _, classID = UnitClass("player")
    local spellID = BUFFS_BY_CLASS[classID]
    if not spellID then
        return false
    end

    for unit in Private:IterateGroupMembers() do
        if UnitIsVisible(unit) and UnitWantsBuff(unit, classID) then
            local aura = FindAura(unit, spellID)
            if aura then
                local source = aura.sourceUnit
                if source and UnitExists(source) and not UnitIsVisible(source) and not UnitIsUnit("player", source) then
                    -- Source left the raid; the buff will drop on pull.
                    return true
                end
            else
                return true
            end
        end
    end
    return false
end

---Run the rebuff check and play the reminder sound if anyone is missing the
---player's raid buff. Returns the reminder text that was played, or nil if
---nothing was played.
---@return string?
function Private:CheckRaidBuff()
    local _, _, classID = UnitClass("player")
    local text = RebuffTextForClass(classID)
    if not text then
        Private:DebugPrint("RaidBuffCheck: player class", classID, "has no tracked raid buff")
        return nil
    end
    if not AnyoneNeedsRebuff() then
        Private:DebugPrint("RaidBuffCheck: everyone is buffed")
        return nil
    end
    Private:DebugPrint("RaidBuffCheck: playing", text)
    Private:PlayReminderSound(text)
    return text
end

local SOULSTONE_SPELL_ID = 20707
local SOURCE_OF_MAGIC_SPELL_ID = 369459

-- A fresh buff must last at least this long to count as "already handled".
local MIN_REMAINING_SECONDS = 300

---@param unit string
---@param spellID number
---@return boolean # true when `unit` has a fresh aura from us for this spell
local function UnitHasFreshPlayerBuff(unit, spellID)
    local aura = FindAuraByID(unit, spellID)
    if not aura or not aura.sourceUnit then
        return false
    end
    if not UnitIsUnit("player", aura.sourceUnit) then
        return false
    end
    local expires = aura.expirationTime
    return expires and (expires - GetTime()) > MIN_REMAINING_SECONDS or false
end

---Warlock-only: play "Soulstone" when no healer has a fresh soulstone from
---the player. Skips the check if soulstone is on a long cooldown (mid-fight
---restart, etc.).
---@return string?
function Private:CheckSoulstone()
    local _, _, classID = UnitClass("player")
    if classID ~= 9 then
        return nil
    end

    local cooldown = C_Spell.GetSpellCooldown(SOULSTONE_SPELL_ID)
    if cooldown and cooldown.duration and cooldown.duration ~= 0 then
        local remaining = cooldown.duration + cooldown.startTime - GetTime()
        if remaining > 30 then
            Private:DebugPrint("RaidBuffCheck: soulstone on cooldown, skipping")
            return nil
        end
    end

    for unit in Private:IterateGroupMembers() do
        if UnitGroupRolesAssigned(unit) == "HEALER" and UnitIsVisible(unit) then
            if UnitHasFreshPlayerBuff(unit, SOULSTONE_SPELL_ID) then
                Private:DebugPrint("RaidBuffCheck: soulstone covered by", unit)
                return nil
            end
        end
    end

    Private:DebugPrint("RaidBuffCheck: playing Soulstone")
    Private:PlayReminderSound("Soulstone")
    return "Soulstone"
end

---Augmentation-evoker-only: play "Source of Magic" when no healer (other
---than the player) has a fresh SoM from the player. Skipped if the spell
---isn't talented.
---@return string?
function Private:CheckSourceOfMagic()
    local _, _, classID = UnitClass("player")
    if classID ~= 13 then
        return nil
    end

    local talented = C_SpellBook
        and C_SpellBook.IsSpellKnownOrInSpellBook
        and C_SpellBook.IsSpellKnownOrInSpellBook(SOURCE_OF_MAGIC_SPELL_ID, nil, true)
    if not talented then
        return nil
    end

    for unit in Private:IterateGroupMembers() do
        if UnitGroupRolesAssigned(unit) == "HEALER" and UnitIsVisible(unit) and not UnitIsUnit(unit, "player") then
            if UnitHasFreshPlayerBuff(unit, SOURCE_OF_MAGIC_SPELL_ID) then
                Private:DebugPrint("RaidBuffCheck: source of magic covered by", unit)
                return nil
            end
        end
    end

    Private:DebugPrint("RaidBuffCheck: playing Source of Magic")
    Private:PlayReminderSound("Source of Magic")
    return "Source of Magic"
end

local function RunAllChecks()
    Private:CheckRaidBuff()
    Private:CheckSoulstone()
    Private:CheckSourceOfMagic()
end

-- NSRT delays its ready-check checks by 1 second (see `C_Timer.After(1, ...)`
-- in NSRT's READY_CHECK handler) so peer NSI_SPEC broadcasts have time to
-- arrive. We do the same for our CRTSPEC broadcasts.
local CHECK_DELAY_SECONDS = 1

local function BroadcastAndCheckLater()
    Private:BroadcastOwnSpec()
    C_Timer.After(CHECK_DELAY_SECONDS, RunAllChecks)
end

---Expose the class map for tests and the /crt test rebuff command.
Private.RaidBuffCheckClasses = BUFFS_BY_CLASS
Private.RaidBuffCheckRebuffTextForClass = RebuffTextForClass

local CLASS_NAME_TO_ID = {
    warrior = 1,
    priest = 5,
    shaman = 7,
    mage = 8,
    druid = 11,
    evoker = 13,
}

---Resolve a short class name (e.g. "warrior") to a class ID, or nil.
---@param name string
---@return number?
function Private.RaidBuffCheckClassIDForName(name)
    return CLASS_NAME_TO_ID[name]
end

---Play the rebuff reminder for a specific class ID without running the check.
---Used by the /crt test rebuff <classID> chat command.
---@param classID number
---@return boolean true when a reminder was triggered
function Private:TestRaidBuffReminder(classID)
    local text = RebuffTextForClass(classID)
    if not text then
        CoffeeRaidTools:Print("No tracked raid buff for class " .. tostring(classID))
        return false
    end
    CoffeeRaidTools:Print("Playing: " .. text)
    Private:PlayReminderSound(text)
    return true
end

Private:RegisterEvent("READY_CHECK", BroadcastAndCheckLater)
Private:RegisterMessage("CRT_BigWigs_StartPull", BroadcastAndCheckLater)

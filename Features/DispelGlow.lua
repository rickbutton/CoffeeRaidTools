---@class Private
local Private = select(2, ...)
---@type Blizz
local Blizz = Private.Blizz

local LGF = LibStub("LibGetFrame-1.0")
local LCG = LibStub("LibCustomGlow-1.0")

local GLOW_KEY = "CRT_DispelGlow"

--- Cache: [unit] = { [auraInstanceID] = true }
---@type table<string, table<number, boolean>>
local dispellableAuras = {}

--- Cache: [unit] = frame currently glowing
---@type table<string, Frame>
local glowingFrames = {}

local currentEncounterID = nil
local currentEncounterName = nil
local isHealer = false

-- LibGetFrame callback anchor
local lgfCallbackTarget = {}

-- ---------------------------------------------------------------------------
-- Glow helpers
-- ---------------------------------------------------------------------------

local function ShowGlow(frame)
    local glowType = Private.db.dispelGlowType
    local color = Private.db.dispelGlowColor

    if glowType == "pixel" then
        LCG.PixelGlow_Start(frame, color, nil, nil, nil, nil, nil, nil, nil, GLOW_KEY)
    elseif glowType == "autocast" then
        LCG.AutoCastGlow_Start(frame, color, nil, nil, nil, nil, nil, GLOW_KEY)
    elseif glowType == "proc" then
        LCG.ProcGlow_Start(frame, { color = color, key = GLOW_KEY })
    end
end

local function HideGlow(frame)
    LCG.PixelGlow_Stop(frame, GLOW_KEY)
    LCG.AutoCastGlow_Stop(frame, GLOW_KEY)
    LCG.ProcGlow_Stop(frame, GLOW_KEY)
end

-- ---------------------------------------------------------------------------
-- State queries
-- ---------------------------------------------------------------------------

local function ShouldGlow()
    local enabled = Private.db.dispelGlowEnabled
    if enabled == "disabled" then
        return false
    end
    if enabled == "healer" and not isHealer then
        return false
    end

    if currentEncounterID then
        local override = Private.db.dispelGlowBossOverrides[currentEncounterID]
        if override ~= nil and not override.enabled then
            return false
        end
    end

    return true
end

local function HasDispellableAuras(unit)
    local auras = dispellableAuras[unit]
    if not auras then
        return false
    end
    return next(auras) ~= nil
end

-- ---------------------------------------------------------------------------
-- Glow update
-- ---------------------------------------------------------------------------

local function UpdateGlow(unit)
    local frame = LGF:GetUnitFrame(unit)
    local oldFrame = glowingFrames[unit]

    if oldFrame and oldFrame ~= frame then
        HideGlow(oldFrame)
        glowingFrames[unit] = nil
    end

    if not frame then
        return
    end

    if ShouldGlow() and HasDispellableAuras(unit) then
        ShowGlow(frame)
        glowingFrames[unit] = frame
    else
        if glowingFrames[unit] then
            HideGlow(frame)
            glowingFrames[unit] = nil
        end
    end
end

local function UpdateAllGlows()
    for unit in Private:IterateGroupMembers() do
        UpdateGlow(unit)
    end
end

local function StopAllGlows()
    for unit, frame in pairs(glowingFrames) do
        HideGlow(frame)
    end
    wipe(glowingFrames)
end

-- Exposed for Settings tab to call when appearance changes
function Private:RefreshDispelGlows()
    StopAllGlows()
    UpdateAllGlows()
end

-- ---------------------------------------------------------------------------
-- Aura scanning
-- ---------------------------------------------------------------------------

local function FullScanUnit(unit)
    if not dispellableAuras[unit] then
        dispellableAuras[unit] = {}
    else
        wipe(dispellableAuras[unit])
    end

    local i = 1
    while true do
        local aura = Blizz.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not aura then
            break
        end
        if aura.dispelName then
            dispellableAuras[unit][aura.auraInstanceID] = true
        end
        i = i + 1
    end
end

local function OnUnitAura(_, unit, updateInfo)
    if not unit or not unit:match("^raid%d") then
        return
    end

    if not dispellableAuras[unit] then
        dispellableAuras[unit] = {}
    end

    if not updateInfo or updateInfo.isFullUpdate then
        FullScanUnit(unit)
    else
        if updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                if aura.isHarmful and aura.dispelName then
                    dispellableAuras[unit][aura.auraInstanceID] = true
                end
            end
        end

        if updateInfo.removedAuraInstanceIDs then
            for _, id in ipairs(updateInfo.removedAuraInstanceIDs) do
                dispellableAuras[unit][id] = nil
            end
        end

        if updateInfo.updatedAuraInstanceIDs then
            for _, id in ipairs(updateInfo.updatedAuraInstanceIDs) do
                local aura = Blizz.GetAuraDataByAuraInstanceID(unit, id)
                if aura and aura.isHarmful and aura.dispelName then
                    dispellableAuras[unit][id] = true
                else
                    dispellableAuras[unit][id] = nil
                end
            end
        end
    end

    UpdateGlow(unit)
end

-- ---------------------------------------------------------------------------
-- Healer detection
-- ---------------------------------------------------------------------------

local function UpdateHealerStatus()
    isHealer = Blizz.GetSpecializationRole() == "HEALER"
end

-- ---------------------------------------------------------------------------
-- Roster management
-- ---------------------------------------------------------------------------

local function OnRosterUpdate()
    local activeUnits = {}
    for unit in Private:IterateGroupMembers() do
        activeUnits[unit] = true
    end

    -- Clean up stale units
    for unit in pairs(dispellableAuras) do
        if not activeUnits[unit] then
            dispellableAuras[unit] = nil
            if glowingFrames[unit] then
                HideGlow(glowingFrames[unit])
                glowingFrames[unit] = nil
            end
        end
    end

    -- Scan any new units
    for unit in pairs(activeUnits) do
        if not dispellableAuras[unit] then
            FullScanUnit(unit)
        end
    end

    UpdateAllGlows()
end

-- ---------------------------------------------------------------------------
-- Event registration
-- ---------------------------------------------------------------------------

Private:RegisterEvent("UNIT_AURA", OnUnitAura)

Private:RegisterEvent("GROUP_ROSTER_UPDATE", OnRosterUpdate)

Private:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    UpdateHealerStatus()
    OnRosterUpdate()
end)

Private:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(_, unit)
    if unit == "player" then
        UpdateHealerStatus()
        UpdateAllGlows()
    end
end)

Private:RegisterEvent("ENCOUNTER_START", function(_, encounterID, encounterName)
    currentEncounterID = encounterID
    currentEncounterName = encounterName

    -- Record boss in known list
    if not Private.db.dispelGlowKnownBosses[encounterID] then
        Private.db.dispelGlowKnownBosses[encounterID] = encounterName
    end

    UpdateAllGlows()
end)

Private:RegisterEvent("ENCOUNTER_END", function()
    currentEncounterID = nil
    currentEncounterName = nil
    UpdateAllGlows()
end)

-- ---------------------------------------------------------------------------
-- LibGetFrame callbacks — handle frame reassignment on roster changes
-- ---------------------------------------------------------------------------

-- Expose internals for testing
Private.DispelGlow = {
    ShouldGlow = ShouldGlow,
    SetIsHealer = function(v)
        isHealer = v
    end,
    SetEncounter = function(id, name)
        currentEncounterID = id
        currentEncounterName = name
    end,
    GetDispellableAuras = function()
        return dispellableAuras
    end,
    GetGlowingFrames = function()
        return glowingFrames
    end,
}

LGF.RegisterCallback(lgfCallbackTarget, "FRAME_UNIT_UPDATE", function(_, unit)
    if unit and unit:match("^raid%d") then
        UpdateGlow(unit)
    end
end)

LGF.RegisterCallback(lgfCallbackTarget, "FRAME_UNIT_REMOVED", function(_, unit)
    if glowingFrames[unit] then
        HideGlow(glowingFrames[unit])
        glowingFrames[unit] = nil
    end
end)

---@class Private
local Private = select(2, ...)
---@type Blizz
local Blizz = Private.Blizz

local ADDON_MEDIA = "Interface\\AddOns\\CoffeeRaidTools\\Media\\TTS\\"
local FALLBACK_NICKNAME = "Unknown"

---@class PrivateAuraSpellConfig
---@field spellID number
---@field label string
---@field soundFile? string
---@field soundDir? string
---@field perUnit boolean

---@class PrivateAuraBossSection
---@field boss string
---@field spells PrivateAuraSpellConfig[]

---@type PrivateAuraBossSection[]
Private.PrivateAuraSections = {
    {
        boss = "Vaelgor & Ezzorak",
        spells = {
            {
                spellID = 1255612, -- Dread Breath
                label = "Dread Breath",
                soundDir = "DreadBreath",
                perUnit = true,
            },
        },
    },
    {
        boss = "Crown of the Cosmos",
        spells = {
            {
                spellID = 1233602, -- Silverstrike Arrow
                label = "Silverstrike Arrow",
                soundFile = "ArrowOnYou",
                perUnit = false,
            },
        },
    },
}

---@type table<string, table<number, number>>
local registeredSounds = {} -- [unitToken][spellID] = soundID

local function RemoveAllSounds()
    for _, spells in pairs(registeredSounds) do
        for _, soundID in pairs(spells) do
            Blizz.RemovePrivateAuraAppliedSound(soundID)
        end
    end
    wipe(registeredSounds)
end

---@param unit string
---@param spellID number
---@param soundFile string
local function RegisterSound(unit, spellID, soundFile)
    if not Blizz.AuraIsPrivate(spellID) then
        return
    end

    if registeredSounds[unit] and registeredSounds[unit][spellID] then
        Blizz.RemovePrivateAuraAppliedSound(registeredSounds[unit][spellID])
        registeredSounds[unit][spellID] = nil
    end

    local soundID = Blizz.AddPrivateAuraAppliedSound({
        unitToken = unit,
        spellID = spellID,
        soundFileName = soundFile,
        outputChannel = "master",
    })

    if soundID then
        if not registeredSounds[unit] then
            registeredSounds[unit] = {}
        end
        registeredSounds[unit][spellID] = soundID
    end
end

local function RegisterPrivateAuraSounds()
    if Private:IsInCombat() then
        return
    end

    RemoveAllSounds()

    for _, section in ipairs(Private.PrivateAuraSections) do
        for _, config in ipairs(section.spells) do
            if not Private.db.disabledPrivateAuras[config.spellID] then
                if config.perUnit then
                    local soundBase = ADDON_MEDIA .. config.soundDir .. "\\"
                    for unit in Private:IterateGroupMembers() do
                        local nickname = CoffeeRaidTools:GetNickname(unit, true)
                        if nickname and not Blizz.issecretvalue(nickname) then
                            if not Private.RosterNicknames[nickname] then
                                Private:DebugPrint("PrivateAuras: no roster entry for", tostring(nickname))
                                CoffeeRaidTools:Print(
                                    "|cffff4040Warning:|r No roster entry for "
                                        .. tostring(nickname)
                                        .. ". Using fallback sound."
                                )
                                RegisterSound(unit, config.spellID, soundBase .. FALLBACK_NICKNAME .. ".mp3")
                            else
                                RegisterSound(unit, config.spellID, soundBase .. nickname .. ".mp3")
                            end
                        end
                    end
                else
                    RegisterSound("player", config.spellID, ADDON_MEDIA .. config.soundFile .. ".mp3")
                end
            end
        end
    end
end

---@param config PrivateAuraSpellConfig
---@param nickname? string
---@return string
function Private:GetPrivateAuraSoundPath(config, nickname)
    if config.perUnit then
        return ADDON_MEDIA .. config.soundDir .. "\\" .. (nickname or FALLBACK_NICKNAME) .. ".mp3"
    else
        return ADDON_MEDIA .. config.soundFile .. ".mp3"
    end
end

Private.RegisterPrivateAuraSounds = RegisterPrivateAuraSounds

Private:RegisterEvent("GROUP_ROSTER_UPDATE", function()
    RegisterPrivateAuraSounds()
end)

Private:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    RegisterPrivateAuraSounds()
end)

Private:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    RegisterPrivateAuraSounds()
end)

Private:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    RegisterPrivateAuraSounds()
end)

Private:RegisterEvent("READY_CHECK", function()
    RegisterPrivateAuraSounds()
end)

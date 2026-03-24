---@class Private
local Private = select(2, ...)
---@type Blizz
local Blizz = Private.Blizz

local ADDON_MEDIA = "Interface\\AddOns\\CoffeeRaidTools\\Media\\TTS\\"
local FALLBACK_NICKNAME = "Unknown"

---@class PrivateAuraSpellConfig
---@field spellIDs number[]
---@field soundFile? string
---@field soundDir? string
---@field perUnit boolean

---@class PrivateAuraBossSection
---@field boss string
---@field bigwigsModule? string
---@field spells PrivateAuraSpellConfig[]

-- Data is generated into PrivateAuraSoundsData.lua by pnpm run generate

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
    Private:DebugPrint("PrivateAuras: RegisterSound", unit, spellID, soundFile)
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
    else
        Private:DebugPrint("PrivateAuras: AddPrivateAuraAppliedSound returned nil for", unit, spellID)
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

---@param warnOnMissing? boolean
local function RegisterPrivateAuraSounds(warnOnMissing)
    if Private:IsInCombat() then
        return
    end

    RemoveAllSounds()

    for _, section in ipairs(Private.PrivateAuraSections) do
        for _, config in ipairs(section.spells) do
            if not Private.db.disabledPrivateAuras[config.spellIDs[1]] then
                for _, spellID in ipairs(config.spellIDs) do
                    if config.perUnit then
                        for unit in Private:IterateGroupMembers() do
                            local nickname = CoffeeRaidTools:GetNickname(unit, true)
                            if nickname and not Blizz.issecretvalue(nickname) then
                                ---@type string?
                                local rosterNickname = nickname
                                if not Private.RosterNicknames[nickname] then
                                    Private:DebugPrint("PrivateAuras: no roster entry for", tostring(nickname))
                                    if warnOnMissing then
                                        CoffeeRaidTools:Print(
                                            "|cffff4040Warning:|r No roster entry for "
                                                .. tostring(nickname)
                                                .. ". Using fallback sound."
                                        )
                                    end
                                    rosterNickname = nil
                                end
                                RegisterSound(unit, spellID, Private:GetPrivateAuraSoundPath(config, rosterNickname))
                            end
                        end
                    else
                        RegisterSound("player", spellID, Private:GetPrivateAuraSoundPath(config))
                    end
                end
            end
        end
    end
end

Private.RegisterPrivateAuraSounds = RegisterPrivateAuraSounds

---@param spellID number
function Private:TestPrivateAuraSound(spellID)
    local config
    for _, section in ipairs(Private.PrivateAuraSections) do
        for _, spell in ipairs(section.spells) do
            for _, id in ipairs(spell.spellIDs) do
                if id == spellID then
                    config = spell
                    break
                end
            end
        end
    end

    if not config then
        CoffeeRaidTools:Print("No private aura config for spell ID " .. spellID)
        return
    end

    if config.perUnit then
        local nickname = CoffeeRaidTools:GetNickname("target", true)
        if not nickname or Blizz.issecretvalue(nickname) then
            CoffeeRaidTools:Print("No valid target selected")
            return
        end
        ---@type string?
        local rosterNickname = nickname
        if not Private.RosterNicknames[nickname] then
            rosterNickname = nil
        end
        CoffeeRaidTools:Print("Playing: " .. Private:GetPrivateAuraSoundPath(config, rosterNickname))
        Blizz.PlaySoundFile(Private:GetPrivateAuraSoundPath(config, rosterNickname), "master")
    else
        CoffeeRaidTools:Print("Playing: " .. Private:GetPrivateAuraSoundPath(config))
        Blizz.PlaySoundFile(Private:GetPrivateAuraSoundPath(config), "master")
    end
end

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
    RegisterPrivateAuraSounds(true)
end)

Private:RegisterMessage("CRT_BigWigs_StartPull", function()
    RegisterPrivateAuraSounds(true)
end)

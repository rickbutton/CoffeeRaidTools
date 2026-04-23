---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

-- NSRT enforcement

local COFFEE_PROFILE = "Coffee"

local ReadyCheckForceTrue = {
    "RepairCheck",
    "GemCheck",
    "EnchantCheck",
    "RaidBuffCheck",
    "CraftedCheck",
    "MissingItemCheck",
    "SoulstoneCheck",
    "ItemLevelCheck",
}

local EncounterAlertIDs = {
    3176,
    3177,
    3178,
    3179,
    3180,
    3181,
    3182,
    3183,
    3306,
}

-- Extra per-encounter sub-flags to force true alongside `.enabled`.
local EncounterAlertExtraFlags = {
    [3179] = { "CCAddsDisplay" }, -- Fallen King Salhadaar
    [3180] = { "TauntAlerts", "HealAbsorbTicks" }, -- Lightblinded Vanguard
}

local QoLForceTrue = {
    "SoulwellDropped",
    "AutoInvite",
    "ResetBossDisplay",
    "LootBossReminder",
    "CauldronDropped",
    "RepairDropped",
    "FeastDropped",
    "GatewayUseableDisplay",
}

local NickNameSettings = {
    { key = "ShareNickNames", value = 3 }, -- Both
    { key = "AcceptNickNames", value = 3 }, -- Both
    { key = "NickNamesSyncAccept", value = 4 }, -- None
    { key = "NickNamesSyncSend", value = 3 }, -- None
}

-- Mirrors NSI.ignored in vendor/NorthernSkyRaidTools/Profiles.lua; keep in sync.
local PROFILE_IGNORED_KEYS = {
    Profiles = true,
    ProfileKeys = true,
    CurrentProfile = true,
    MainProfile = true,
}

local function DebugSet(path, before, after)
    Private:DebugPrint("NSRT " .. path .. ": " .. tostring(before) .. " -> " .. tostring(after))
end

---Apply enforced settings to a root table shaped like NSRT.
---
---@param root table
---@param battleTag string?
---@param pathLabel string
local function EnforceOnRoot(root, battleTag, pathLabel)
    if not root.ReadyCheckSettings then
        root.ReadyCheckSettings = {}
    end
    for _, key in ipairs(ReadyCheckForceTrue) do
        if root.ReadyCheckSettings[key] ~= true then
            DebugSet(pathLabel .. "ReadyCheckSettings." .. key, root.ReadyCheckSettings[key], true)
            root.ReadyCheckSettings[key] = true
        end
    end

    if not root.EncounterAlerts then
        root.EncounterAlerts = {}
    end
    for _, id in ipairs(EncounterAlertIDs) do
        if not root.EncounterAlerts[id] then
            root.EncounterAlerts[id] = {}
        end
        if root.EncounterAlerts[id].enabled ~= true then
            DebugSet(pathLabel .. "EncounterAlerts[" .. id .. "].enabled", root.EncounterAlerts[id].enabled, true)
            root.EncounterAlerts[id].enabled = true
        end
        local extras = EncounterAlertExtraFlags[id]
        if extras then
            for _, flag in ipairs(extras) do
                if root.EncounterAlerts[id][flag] ~= true then
                    DebugSet(
                        pathLabel .. "EncounterAlerts[" .. id .. "]." .. flag,
                        root.EncounterAlerts[id][flag],
                        true
                    )
                    root.EncounterAlerts[id][flag] = true
                end
            end
        end
    end

    if not root.QoL then
        root.QoL = {}
    end
    for _, key in ipairs(QoLForceTrue) do
        if root.QoL[key] ~= true then
            DebugSet(pathLabel .. "QoL." .. key, root.QoL[key], true)
            root.QoL[key] = true
        end
    end

    if not root.ReminderSettings then
        root.ReminderSettings = {}
    end
    if root.ReminderSettings.enabled ~= true then
        DebugSet(pathLabel .. "ReminderSettings.enabled", root.ReminderSettings.enabled, true)
        root.ReminderSettings.enabled = true
    end
    if root.ReminderSettings.UseTLReminders ~= false then
        DebugSet(pathLabel .. "ReminderSettings.UseTLReminders", root.ReminderSettings.UseTLReminders, false)
        root.ReminderSettings.UseTLReminders = false
    end
    if root.ReminderSettings.MRTNote ~= false then
        DebugSet(pathLabel .. "ReminderSettings.MRTNote", root.ReminderSettings.MRTNote, false)
        root.ReminderSettings.MRTNote = false
    end
    if root.ReminderSettings.SpellTTS ~= true then
        DebugSet(pathLabel .. "ReminderSettings.SpellTTS", root.ReminderSettings.SpellTTS, true)
        root.ReminderSettings.SpellTTS = true
    end
    if root.ReminderSettings.TextTTS ~= true then
        DebugSet(pathLabel .. "ReminderSettings.TextTTS", root.ReminderSettings.TextTTS, true)
        root.ReminderSettings.TextTTS = true
    end

    if not root.Settings then
        root.Settings = {}
    end
    if root.Settings["GlobalNickNames"] ~= true then
        DebugSet(pathLabel .. "Settings.GlobalNickNames", root.Settings["GlobalNickNames"], true)
        root.Settings["GlobalNickNames"] = true
    end
    for _, entry in ipairs(NickNameSettings) do
        if root.Settings[entry.key] ~= entry.value then
            DebugSet(pathLabel .. "Settings." .. entry.key, root.Settings[entry.key], entry.value)
            root.Settings[entry.key] = entry.value
        end
    end

    if battleTag then
        local expectedNickname = Private.BattleTagToNickname[battleTag:lower()]
        if expectedNickname and root.Settings["MyNickName"] ~= expectedNickname then
            DebugSet(pathLabel .. "Settings.MyNickName", root.Settings["MyNickName"], expectedNickname)
            root.Settings["MyNickName"] = expectedNickname
        end
    end
end

---Matches NSI:GetProfileKey() in vendor/NorthernSkyRaidTools/Profiles.lua; keep in sync.
local function GetPlayerProfileKey()
    local charName, realm = UnitFullName("player")
    if not realm or realm == "" then
        realm = GetNormalizedRealmName()
    end
    if not charName or not realm or realm == "" then
        return nil
    end
    return charName .. "-" .. realm
end

---Mirror of NSI:LoadProfile's copy loop (vendor/NorthernSkyRaidTools/Profiles.lua); keep in sync.
local function CopyProfileIntoActive(profileName)
    local profile = NSRT and NSRT.Profiles and NSRT.Profiles[profileName]
    if not profile then
        return
    end
    for k, v in pairs(profile) do
        if not PROFILE_IGNORED_KEYS[k] then
            NSRT[k] = type(v) == "table" and CopyTable(v) or v
        end
    end
end

local function NSRTHasProfiles()
    return NSRT and type(NSRT.Profiles) == "table"
end

local function EnforceNSRTPreProfile(battleTag)
    EnforceOnRoot(NSRT, battleTag, "")
end

local function EnforceNSRTWithProfiles(battleTag)
    local profiles = NSRT.Profiles
    local coffee = profiles[COFFEE_PROFILE]
    local isFirstInstall = coffee == nil

    if isFirstInstall then
        -- Seed from the user's currently active profile so we don't wipe their
        -- existing nicknames / reminders / assignments.
        local seedName = NSRT.CurrentProfile
        local seed = (seedName and profiles[seedName]) or profiles["default"]
        coffee = seed and CopyTable(seed) or {}
        profiles[COFFEE_PROFILE] = coffee
        Private:DebugPrint("CRT: created NSRT profile '" .. COFFEE_PROFILE .. "'")
    end

    EnforceOnRoot(coffee, battleTag, "Profiles." .. COFFEE_PROFILE .. ".")

    if isFirstInstall then
        NSRT.ProfileKeys = NSRT.ProfileKeys or {}
        local key = GetPlayerProfileKey()
        if key then
            NSRT.ProfileKeys[key] = COFFEE_PROFILE
        end
        NSRT.MainProfile = COFFEE_PROFILE
        NSRT.CurrentProfile = COFFEE_PROFILE
        CopyProfileIntoActive(COFFEE_PROFILE)
        EnforceOnRoot(NSRT, battleTag, "")
    elseif NSRT.CurrentProfile == COFFEE_PROFILE then
        EnforceOnRoot(NSRT, battleTag, "")
    end
end

local function EnforceNSRT()
    if not NSRT then
        return
    end

    local battleTag = select(2, BNGetInfo())

    if NSRTHasProfiles() then
        EnforceNSRTWithProfiles(battleTag)
    else
        EnforceNSRTPreProfile(battleTag)
    end
end

-- Event handling

Private.EnforceNSRT = EnforceNSRT
Private.EnforceNSRTOnRoot = EnforceOnRoot
Private.CopyNSRTProfileIntoActive = CopyProfileIntoActive
Private.GetNSRTPlayerProfileKey = GetPlayerProfileKey
Private.COFFEE_PROFILE = COFFEE_PROFILE

local EnforceFunctions = {
    NorthernSkyRaidTools = EnforceNSRT,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        local enforce = EnforceFunctions[addonName]
        if not enforce then
            return
        end
        enforce()
        return
    end

    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("ADDON_LOADED")
        self:UnregisterEvent("PLAYER_LOGIN")

        -- Re-run after NSRT's own init finishes: pre-profile NSRT upgrades
        -- haven't populated NSRT.Profiles by our ADDON_LOADED handler, so
        -- the Coffee profile can't be created until NSRT bootstraps it here.
        C_Timer.After(0, function()
            EnforceNSRT()
            Private:InvalidateLocalVersions()
        end)

        -- Disable TimelineReminders if it is still enabled
        if C_AddOns.GetAddOnEnableState("TimelineReminders") > 0 then
            C_AddOns.DisableAddOn("TimelineReminders")
            StaticPopup_Show("CRT_TR_DISABLED")
            return
        end

        local missing = {}
        for _, addon in ipairs(Private.AddonsToTrack) do
            if addon.name ~= "CoffeeRaidTools" and not C_AddOns.IsAddOnLoaded(addon.name) then
                missing[#missing + 1] = addon.name
            end
        end

        if #missing > 0 then
            StaticPopup_Show("CRT_MISSING_ADDONS", table.concat(missing, "\n"))
        end
    end
end)

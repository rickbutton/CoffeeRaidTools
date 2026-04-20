---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

-- NSRT enforcement

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

local function EnforceNSRT()
    if not NSRT then
        return
    end

    if not NSRT.ReadyCheckSettings then
        NSRT.ReadyCheckSettings = {}
    end
    for _, key in ipairs(ReadyCheckForceTrue) do
        if NSRT.ReadyCheckSettings[key] ~= true then
            Private:DebugPrint(
                "NSRT ReadyCheckSettings." .. key .. ": " .. tostring(NSRT.ReadyCheckSettings[key]) .. " -> true"
            )
            NSRT.ReadyCheckSettings[key] = true
        end
    end

    if not NSRT.EncounterAlerts then
        NSRT.EncounterAlerts = {}
    end
    for _, id in ipairs(EncounterAlertIDs) do
        if not NSRT.EncounterAlerts[id] then
            NSRT.EncounterAlerts[id] = {}
        end
        if NSRT.EncounterAlerts[id].enabled ~= true then
            Private:DebugPrint(
                "NSRT EncounterAlerts["
                    .. id
                    .. "].enabled: "
                    .. tostring(NSRT.EncounterAlerts[id].enabled)
                    .. " -> true"
            )
            NSRT.EncounterAlerts[id].enabled = true
        end
    end

    if not NSRT.QoL then
        NSRT.QoL = {}
    end
    for _, key in ipairs(QoLForceTrue) do
        if NSRT.QoL[key] ~= true then
            Private:DebugPrint("NSRT QoL." .. key .. ": " .. tostring(NSRT.QoL[key]) .. " -> true")
            NSRT.QoL[key] = true
        end
    end

    if not NSRT.ReminderSettings then
        NSRT.ReminderSettings = {}
    end
    if NSRT.ReminderSettings.enabled ~= true then
        Private:DebugPrint("NSRT ReminderSettings.enabled: " .. tostring(NSRT.ReminderSettings.enabled) .. " -> true")
        NSRT.ReminderSettings.enabled = true
    end

    if NSRT.ReminderSettings.UseTLReminders ~= false then
        Private:DebugPrint(
            "NSRT ReminderSettings.UseTLReminders: " .. tostring(NSRT.ReminderSettings.UseTLReminders) .. " -> false"
        )
        NSRT.ReminderSettings.UseTLReminders = false
    end

    if NSRT.ReminderSettings.MRTNote ~= false then
        Private:DebugPrint("NSRT ReminderSettings.MRTNote: " .. tostring(NSRT.ReminderSettings.MRTNote) .. " -> false")
        NSRT.ReminderSettings.MRTNote = false
    end

    if NSRT.ReminderSettings.SpellTTS ~= true then
        Private:DebugPrint("NSRT ReminderSettings.SpellTTS: " .. tostring(NSRT.ReminderSettings.SpellTTS) .. " -> true")
        NSRT.ReminderSettings.SpellTTS = true
    end

    if NSRT.ReminderSettings.TextTTS ~= true then
        Private:DebugPrint("NSRT ReminderSettings.TextTTS: " .. tostring(NSRT.ReminderSettings.TextTTS) .. " -> true")
        NSRT.ReminderSettings.TextTTS = true
    end

    -- Nickname enforcement
    if not NSRT.Settings then
        NSRT.Settings = {}
    end
    if NSRT.Settings["GlobalNickNames"] ~= true then
        Private:DebugPrint(
            "NSRT Settings.GlobalNickNames: " .. tostring(NSRT.Settings["GlobalNickNames"]) .. " -> true"
        )
        NSRT.Settings["GlobalNickNames"] = true
    end

    local nickNameSettings = {
        { key = "ShareNickNames", value = 3 }, -- Both
        { key = "AcceptNickNames", value = 3 }, -- Both
        { key = "NickNamesSyncAccept", value = 4 }, -- None
        { key = "NickNamesSyncSend", value = 3 }, -- None
    }
    for _, entry in ipairs(nickNameSettings) do
        if NSRT.Settings[entry.key] ~= entry.value then
            Private:DebugPrint(
                "NSRT Settings." .. entry.key .. ": " .. tostring(NSRT.Settings[entry.key]) .. " -> " .. entry.value
            )
            NSRT.Settings[entry.key] = entry.value
        end
    end

    local battleTag = select(2, BNGetInfo())
    if battleTag then
        local expectedNickname = Private.BattleTagToNickname[battleTag:lower()]
        if expectedNickname and NSRT.Settings["MyNickName"] ~= expectedNickname then
            Private:DebugPrint(
                "NSRT Settings.MyNickName: " .. tostring(NSRT.Settings["MyNickName"]) .. " -> " .. expectedNickname
            )
            NSRT.Settings["MyNickName"] = expectedNickname
        end
    end
end

-- Event handling

Private.EnforceNSRT = EnforceNSRT

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

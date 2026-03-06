---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

Private.enforceChanged = false

local function PopupOnShow(self)
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    C_Timer.After(0, function()
        self:SetHeight(self:GetHeight() + 10)
    end)
end

local TITLE = "|cffffd100CoffeeRaidTools|r"

StaticPopupDialogs["CRT_FORCE_RELOAD"] = {
    text = TITLE .. "\n\nA UI reload is required.",
    button1 = "Reload UI",
    OnAccept = ReloadUI,
    OnShow = PopupOnShow,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    showAlert = false,
}

StaticPopupDialogs["CRT_MISSING_ADDONS"] = {
    text = TITLE .. "\n\nRequired addon(s) missing:\n\n|cffff4040%s|r",
    button1 = "Ok",
    OnShow = PopupOnShow,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = false,
}

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
            Private.enforceChanged = true
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
            Private.enforceChanged = true
        end
    end

    if not NSRT.QoL then
        NSRT.QoL = {}
    end
    for _, key in ipairs(QoLForceTrue) do
        if NSRT.QoL[key] ~= true then
            Private:DebugPrint("NSRT QoL." .. key .. ": " .. tostring(NSRT.QoL[key]) .. " -> true")
            NSRT.QoL[key] = true
            Private.enforceChanged = true
        end
    end
end

-- TimelineReminders enforcement

local BattleTagToNickname = {
    ["waffletwo#1858"] = "Waffle",
}

local TRSettingsForceTrue = {
    { path = { "settings", "timeline", "nsrtNote" }, label = "TR settings.timeline.nsrtNote" },
    { path = { "settings", "timeline", "mrtNote" }, label = "TR settings.timeline.mrtNote" },
    { path = { "settings", "groupMode", "allowBroadcast" }, label = "TR settings.groupMode.allowBroadcast" },
}

local function EnforceTimelineReminders()
    if not LiquidRemindersSaved then
        return
    end

    -- Nickname enforcement
    local battleTag = select(2, Private.BNGetInfo())
    if battleTag then
        local expectedNickname = BattleTagToNickname[battleTag]
        if expectedNickname and LiquidRemindersSaved.nickname ~= expectedNickname then
            Private:DebugPrint("TR nickname: " .. tostring(LiquidRemindersSaved.nickname) .. " -> " .. expectedNickname)
            LiquidRemindersSaved.nickname = expectedNickname
            Private.enforceChanged = true
        end
    end

    -- Settings enforcement
    for _, entry in ipairs(TRSettingsForceTrue) do
        local tbl = LiquidRemindersSaved
        for i = 1, #entry.path - 1 do
            if not tbl[entry.path[i]] then
                tbl[entry.path[i]] = {}
            end
            tbl = tbl[entry.path[i]]
        end
        local key = entry.path[#entry.path]
        if tbl[key] ~= true then
            Private:DebugPrint(entry.label .. ": " .. tostring(tbl[key]) .. " -> true")
            tbl[key] = true
            Private.enforceChanged = true
        end
    end
end

-- Event handling

Private.EnforceNSRT = EnforceNSRT
Private.EnforceTimelineReminders = EnforceTimelineReminders

local EnforceFunctions = {
    NorthernSkyRaidTools = EnforceNSRT,
    TimelineReminders = EnforceTimelineReminders,
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
        self:UnregisterAllEvents()

        local missing = {}
        for _, addon in ipairs(Private.AddonsToTrack) do
            if addon.name ~= "CoffeeRaidTools" and not C_AddOns.IsAddOnLoaded(addon.name) then
                missing[#missing + 1] = addon.name
            end
        end

        if #missing > 0 then
            StaticPopup_Show("CRT_MISSING_ADDONS", table.concat(missing, "\n"))
        elseif Private.enforceChanged then
            StaticPopup_Show("CRT_FORCE_RELOAD")
        end
    end
end)

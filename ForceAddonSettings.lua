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

    if NSRT.ReminderSettings.UseTLReminders ~= true then
        Private:DebugPrint(
            "NSRT ReminderSettings.UseTLReminders: " .. tostring(NSRT.ReminderSettings.UseTLReminders) .. " -> true"
        )
        NSRT.ReminderSettings.UseTLReminders = true
    end
end

-- TimelineReminders enforcement

local BattleTagToNickname = {
    ["waffletwo#1858"] = "Waffle",
    ["bestman#1653"] = "Bestman",
    ["eeld#1234"] = "Eeld",
    ["bonestorm#11570"] = "Rocky",
    ["hm3boost#1688"] = "Bubble",
    ["pwnstar#11783"] = "Apollo",
    ["notlad#11770"] = "Peer",
    ["h8shot#1402"] = "Gold",
    ["mazed#11112"] = "Nmu",
    ["hundiddy#1280"] = "Hun",
    ["phaszr#1199"] = "Lancr",
    ["itsneahvil#1266"] = "Dez",
    ["ophidian#1948"] = "Scynical",
    ["mordrag#11554"] = "Jerk",
    ["sluff#11368"] = "Sluff",
    ["apexmachine#1449"] = "Apex",
    ["squeethetree#1185"] = "Squishes",
    ["xuedo#1579"] = "Xhul",
    ["drcuddlesphd#1611"] = "Drcuddles",
    ["jaybirrd#11458"] = "Errmac",
    ["klaus#12266"] = "Kami",
    ["tenille#1412"] = "Tenillee",
    ["puma#1523"] = "Annoyance",
}

local TRSettingsForceTrue = {
    { path = { "settings", "timeline", "nsrtNote" }, label = "TR settings.timeline.nsrtNote" },
    { path = { "settings", "timeline", "mrtNote" }, label = "TR settings.timeline.mrtNote" },
    { path = { "settings", "groupMode", "allowBroadcast" }, label = "TR settings.groupMode.allowBroadcast" },
}

function Private:ForceTRDefaultTemplates()
    if not LiquidRemindersSaved then
        return
    end

    if not LiquidRemindersSaved.defaultTemplates then
        LiquidRemindersSaved.defaultTemplates = {}
    end

    local voices = C_VoiceChat and C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices()
    local voiceID = voices and voices[1] and voices[1].voiceID or 0

    for _, templateType in ipairs({ "TEXT", "SPELL" }) do
        if not LiquidRemindersSaved.defaultTemplates[templateType] then
            LiquidRemindersSaved.defaultTemplates[templateType] = {}
        end

        local tts = LiquidRemindersSaved.defaultTemplates[templateType].tts
        if not tts then
            LiquidRemindersSaved.defaultTemplates[templateType].tts = {}
            tts = LiquidRemindersSaved.defaultTemplates[templateType].tts
        end

        Private:DebugPrint(
            "TR defaultTemplates." .. templateType .. ".tts.enabled: " .. tostring(tts.enabled) .. " -> true"
        )
        Private:DebugPrint(
            "TR defaultTemplates."
                .. templateType
                .. ".tts.voice: "
                .. tostring(tts.voice)
                .. " -> "
                .. tostring(voiceID)
        )
        Private:DebugPrint("TR defaultTemplates." .. templateType .. ".tts.time: " .. tostring(tts.time) .. " -> 0")

        tts.enabled = true
        tts.voice = voiceID
        tts.time = 0
    end

    Private.db.hasForcedTRTemplates = true
    CoffeeRaidTools:Print("TimelineReminders default template TTS has been enabled.")
end

local function EnforceTimelineReminders()
    if not LiquidRemindersSaved then
        return
    end

    -- Nickname enforcement
    local battleTag = select(2, Private.BNGetInfo())
    if battleTag then
        local expectedNickname = BattleTagToNickname[battleTag:lower()]
        if expectedNickname and LiquidRemindersSaved.nickname ~= expectedNickname then
            Private:DebugPrint("TR nickname: " .. tostring(LiquidRemindersSaved.nickname) .. " -> " .. expectedNickname)
            LiquidRemindersSaved.nickname = expectedNickname
        end
    end

    -- One-time default template TTS enforcement
    if not Private.db.hasForcedTRTemplates then
        Private:ForceTRDefaultTemplates()
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
        self:UnregisterEvent("ADDON_LOADED")
        self:UnregisterEvent("PLAYER_LOGIN")

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

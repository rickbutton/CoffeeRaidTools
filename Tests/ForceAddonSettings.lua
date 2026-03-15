---@class Private
local Private = select(2, ...)

local Tests, Asserts = Private.Tests:CreateSuite("ForceAddonSettings")
local AreEqual, IsTrue, IsFalse, Replace = Asserts.AreEqual, Asserts.IsTrue, Asserts.IsFalse, Asserts.Replace

function Tests:EnforceNSRTNilSafe()
    Replace(Private, "enforceChanged", false)
    Replace("NSRT", nil)
    Private.EnforceNSRT()
    IsFalse(NSRT)
end

function Tests:EnforceNSRTSetsReadyCheckSettings()
    Replace(Private, "enforceChanged", false)
    Replace("NSRT", {})
    Private.EnforceNSRT()
    IsTrue(NSRT.ReadyCheckSettings.RepairCheck)
    IsTrue(NSRT.ReadyCheckSettings.GemCheck)
    IsTrue(NSRT.ReadyCheckSettings.EnchantCheck)
    IsTrue(NSRT.ReadyCheckSettings.RaidBuffCheck)
    IsTrue(NSRT.ReadyCheckSettings.CraftedCheck)
    IsTrue(NSRT.ReadyCheckSettings.MissingItemCheck)
    IsTrue(NSRT.ReadyCheckSettings.SoulstoneCheck)
    IsTrue(NSRT.ReadyCheckSettings.ItemLevelCheck)
end

function Tests:EnforceNSRTSetsEncounterAlerts()
    Replace(Private, "enforceChanged", false)
    Replace("NSRT", {})
    Private.EnforceNSRT()
    IsTrue(NSRT.EncounterAlerts[3176].enabled)
    IsTrue(NSRT.EncounterAlerts[3183].enabled)
    IsTrue(NSRT.EncounterAlerts[3306].enabled)
end

function Tests:EnforceNSRTSetsQoL()
    Replace(Private, "enforceChanged", false)
    Replace("NSRT", {})
    Private.EnforceNSRT()
    IsTrue(NSRT.QoL.SoulwellDropped)
    IsTrue(NSRT.QoL.AutoInvite)
    IsTrue(NSRT.QoL.ResetBossDisplay)
    IsTrue(NSRT.QoL.LootBossReminder)
end

function Tests:EnforceNSRTPreservesExistingValues()
    Replace(Private, "enforceChanged", false)
    Replace("NSRT", { ReadyCheckSettings = { RepairCheck = true, CustomSetting = "keep" } })
    Private.EnforceNSRT()
    AreEqual("keep", NSRT.ReadyCheckSettings.CustomSetting)
    IsTrue(NSRT.ReadyCheckSettings.RepairCheck)
end

function Tests:EnforceTimelineRemindersNilSafe()
    Replace(Private, "enforceChanged", false)
    Replace("LiquidRemindersSaved", nil)
    Private.EnforceTimelineReminders()
    IsFalse(LiquidRemindersSaved)
end

function Tests:EnforceTimelineRemindersSetsNestedPaths()
    Replace(Private, "enforceChanged", false)
    Replace("LiquidRemindersSaved", {})
    Replace(Private, "BNGetInfo", function()
        return nil, nil
    end)
    Private.EnforceTimelineReminders()
    IsTrue(LiquidRemindersSaved.settings.timeline.nsrtNote)
    IsTrue(LiquidRemindersSaved.settings.timeline.mrtNote)
    IsTrue(LiquidRemindersSaved.settings.groupMode.allowBroadcast)
end

function Tests:EnforceTimelineRemindersCreatesIntermediateTables()
    Replace(Private, "enforceChanged", false)
    Replace("LiquidRemindersSaved", {})
    Replace(Private, "BNGetInfo", function()
        return nil, nil
    end)
    Private.EnforceTimelineReminders()
    AreEqual(type(LiquidRemindersSaved.settings), "table")
    AreEqual(type(LiquidRemindersSaved.settings.timeline), "table")
    AreEqual(type(LiquidRemindersSaved.settings.groupMode), "table")
end

function Tests:EnforceTimelineRemindersNickname()
    Replace(Private, "enforceChanged", false)
    Replace("LiquidRemindersSaved", {})
    Replace(Private, "BNGetInfo", function()
        return nil, "waffletwo#1858"
    end)
    Private.EnforceTimelineReminders()
    AreEqual("Waffle", LiquidRemindersSaved.nickname)
end

function Tests:EnforceTimelineRemindersUnknownBattleTag()
    Replace(Private, "enforceChanged", false)
    Replace("LiquidRemindersSaved", { nickname = "Original" })
    Replace(Private, "BNGetInfo", function()
        return nil, "unknown#0000"
    end)
    Private.EnforceTimelineReminders()
    AreEqual("Original", LiquidRemindersSaved.nickname)
end

-- Guild info version check

function Tests:ParseGuildInfoVersionReturnsVersion()
    Replace("GetGuildInfoText", function()
        return "Welcome to the guild!\n<CRT:42>"
    end)
    AreEqual("42", Private.ParseGuildInfoVersion())
end

function Tests:ParseGuildInfoVersionNoTag()
    Replace("GetGuildInfoText", function()
        return "Welcome to the guild!"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersion())
end

function Tests:ParseGuildInfoVersionNilText()
    Replace("GetGuildInfoText", function()
        return nil
    end)
    AreEqual(nil, Private.ParseGuildInfoVersion())
end

function Tests:ParseGuildInfoVersionMalformedTag()
    Replace("GetGuildInfoText", function()
        return "<CRT:abc>"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersion())
end

function Tests:ParseGuildInfoVersionPartialTag()
    Replace("GetGuildInfoText", function()
        return "<CRT:>"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersion())
end

function Tests:CheckGuildVersionReturnsTrueWhenOutdated()
    Replace("GetGuildInfoText", function()
        return "<CRT:99>"
    end)
    Replace(Private, "GetAddonVersion", function()
        return "42"
    end)
    IsTrue(Private.CheckGuildVersion())
end

function Tests:CheckGuildVersionReturnsFalseWhenCurrent()
    Replace("GetGuildInfoText", function()
        return "<CRT:42>"
    end)
    Replace(Private, "GetAddonVersion", function()
        return "42"
    end)
    IsFalse(Private.CheckGuildVersion())
end

function Tests:CheckGuildVersionReturnsFalseWhenNoTag()
    Replace("GetGuildInfoText", function()
        return "No version here"
    end)
    IsFalse(Private.CheckGuildVersion())
end

function Tests:CheckGuildVersionReturnsFalseWhenNoGuildInfo()
    Replace("GetGuildInfoText", function()
        return nil
    end)
    IsFalse(Private.CheckGuildVersion())
end

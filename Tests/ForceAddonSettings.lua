if not WoWUnit then return end

---@class Private
local Private = select(2, ...)

local AreEqual, IsTrue, IsFalse, Replace = WoWUnit.AreEqual, WoWUnit.IsTrue, WoWUnit.IsFalse, WoWUnit.Replace
local Tests = WoWUnit("CRT ForceAddonSettings")

function Tests:EnforceNSRTNilSafe()
    Replace("NSRT", nil)
    Private.EnforceNSRT()
    IsFalse(NSRT)
end

function Tests:EnforceNSRTSetsReadyCheckSettings()
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
    Replace("NSRT", {})
    Private.EnforceNSRT()
    IsTrue(NSRT.EncounterAlerts[3176].enabled)
    IsTrue(NSRT.EncounterAlerts[3183].enabled)
    IsTrue(NSRT.EncounterAlerts[3306].enabled)
end

function Tests:EnforceNSRTSetsQoL()
    Replace("NSRT", {})
    Private.EnforceNSRT()
    IsTrue(NSRT.QoL.SoulwellDropped)
    IsTrue(NSRT.QoL.AutoInvite)
    IsTrue(NSRT.QoL.ResetBossDisplay)
    IsTrue(NSRT.QoL.LootBossReminder)
end

function Tests:EnforceNSRTPreservesExistingValues()
    Replace("NSRT", { ReadyCheckSettings = { RepairCheck = true, CustomSetting = "keep" } })
    Private.EnforceNSRT()
    AreEqual("keep", NSRT.ReadyCheckSettings.CustomSetting)
    IsTrue(NSRT.ReadyCheckSettings.RepairCheck)
end

function Tests:EnforceTimelineRemindersNilSafe()
    Replace("LiquidRemindersSaved", nil)
    Private.EnforceTimelineReminders()
    IsFalse(LiquidRemindersSaved)
end

function Tests:EnforceTimelineRemindersSetsNestedPaths()
    Replace("LiquidRemindersSaved", {})
    Replace("BNGetInfo", function() return nil, nil end)
    Private.EnforceTimelineReminders()
    IsTrue(LiquidRemindersSaved.settings.timeline.nsrtNote)
    IsTrue(LiquidRemindersSaved.settings.timeline.mrtNote)
    IsTrue(LiquidRemindersSaved.settings.groupMode.allowBroadcast)
end

function Tests:EnforceTimelineRemindersCreatesIntermediateTables()
    Replace("LiquidRemindersSaved", {})
    Replace("BNGetInfo", function() return nil, nil end)
    Private.EnforceTimelineReminders()
    AreEqual(type(LiquidRemindersSaved.settings), "table")
    AreEqual(type(LiquidRemindersSaved.settings.timeline), "table")
    AreEqual(type(LiquidRemindersSaved.settings.groupMode), "table")
end

function Tests:EnforceTimelineRemindersNickname()
    Replace("LiquidRemindersSaved", {})
    Replace("BNGetInfo", function() return nil, "waffletwo#1858" end)
    Private.EnforceTimelineReminders()
    AreEqual("Waffle", LiquidRemindersSaved.nickname)
end

function Tests:EnforceTimelineRemindersUnknownBattleTag()
    Replace("LiquidRemindersSaved", { nickname = "Original" })
    Replace("BNGetInfo", function() return nil, "unknown#0000" end)
    Private.EnforceTimelineReminders()
    AreEqual("Original", LiquidRemindersSaved.nickname)
end

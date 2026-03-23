---@class Private
local Private = select(2, ...)
local Blizz = Private.Blizz

local Tests, Asserts = Private.Tests:CreateSuite("ForceAddonSettings")
local AreEqual, IsTrue, IsFalse, Replace = Asserts.AreEqual, Asserts.IsTrue, Asserts.IsFalse, Asserts.Replace

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

function Tests:EnforceNSRTSetsReminderSettingsEnabled()
    Replace("NSRT", {})
    Private.EnforceNSRT()
    IsTrue(NSRT.ReminderSettings.enabled)
end

function Tests:EnforceNSRTSetsUseTLRemindersFalse()
    Replace("NSRT", { ReminderSettings = { UseTLReminders = true } })
    Replace(Blizz, "BNGetInfo", function()
        return nil, nil
    end)
    Private.EnforceNSRT()
    IsFalse(NSRT.ReminderSettings.UseTLReminders)
end

function Tests:EnforceNSRTPreservesExistingValues()
    Replace("NSRT", { ReadyCheckSettings = { RepairCheck = true, CustomSetting = "keep" } })
    Private.EnforceNSRT()
    AreEqual("keep", NSRT.ReadyCheckSettings.CustomSetting)
    IsTrue(NSRT.ReadyCheckSettings.RepairCheck)
end

function Tests:EnforceNSRTSetsGlobalNickNames()
    Replace("NSRT", {})
    Replace(Blizz, "BNGetInfo", function()
        return nil, nil
    end)
    Private.EnforceNSRT()
    IsTrue(NSRT.Settings["GlobalNickNames"])
end

function Tests:EnforceNSRTSetsMyNickName()
    Replace("NSRT", {})
    Replace(Blizz, "BNGetInfo", function()
        return nil, "waffletwo#1858"
    end)
    Private.EnforceNSRT()
    AreEqual("Waffle", NSRT.Settings["MyNickName"])
end

function Tests:EnforceNSRTSetsMyNickNameCaseInsensitive()
    Replace("NSRT", {})
    Replace(Blizz, "BNGetInfo", function()
        return nil, "WaffleTwo#1858"
    end)
    Private.EnforceNSRT()
    AreEqual("Waffle", NSRT.Settings["MyNickName"])
end

function Tests:EnforceNSRTSkipsNickNameForUnknownBattleTag()
    Replace("NSRT", { Settings = { MyNickName = "Original" } })
    Replace(Blizz, "BNGetInfo", function()
        return nil, "unknown#0000"
    end)
    Private.EnforceNSRT()
    AreEqual("Original", NSRT.Settings["MyNickName"])
end

function Tests:EnforceNSRTSetsSpellTTS()
    Replace("NSRT", {})
    Replace(Blizz, "BNGetInfo", function()
        return nil, nil
    end)
    Private.EnforceNSRT()
    IsTrue(NSRT.ReminderSettings.SpellTTS)
end

function Tests:EnforceNSRTSetsTextTTS()
    Replace("NSRT", {})
    Replace(Blizz, "BNGetInfo", function()
        return nil, nil
    end)
    Private.EnforceNSRT()
    IsTrue(NSRT.ReminderSettings.TextTTS)
end

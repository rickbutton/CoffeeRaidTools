---@class Private
local Private = select(2, ...)
local Blizz = Private.Blizz

local Tests, Asserts = Private.Tests:CreateSuite("Versions")
local AreEqual, IsTrue, Replace = Asserts.AreEqual, Asserts.IsTrue, Asserts.Replace

function Tests:StringHashDeterministic()
    local hash1 = Private.StringHash("hello world")
    local hash2 = Private.StringHash("hello world")
    AreEqual(hash1, hash2)
end

function Tests:StringHashDifferentInputsDifferentOutputs()
    local hash1 = Private.StringHash("hello")
    local hash2 = Private.StringHash("world")
    IsTrue(hash1 ~= hash2)
end

function Tests:StringHashEmptyString()
    local hash = Private.StringHash("")
    IsTrue(hash ~= nil)
    IsTrue(type(hash) == "string")
end

function Tests:StringHashReturnsString()
    local hash = Private.StringHash("test input")
    AreEqual(type(hash), "string")
end

function Tests:GetAddonVersionLoaded()
    Replace(Blizz, "IsAddOnLoaded", function(name)
        return name == "TestAddon"
    end)
    Replace(Blizz, "GetAddOnMetadata", function(name, key)
        if name == "TestAddon" and key == "Version" then
            return "1.2.3"
        end
    end)
    AreEqual("1.2.3", Private.GetAddonVersion("TestAddon"))
end

function Tests:GetAddonVersionNotLoaded()
    Replace(Blizz, "IsAddOnLoaded", function()
        return false
    end)
    AreEqual("NONE", Private.GetAddonVersion("FakeAddon"))
end

function Tests:GetAddonVersionNilMetadata()
    Replace(Blizz, "IsAddOnLoaded", function()
        return true
    end)
    Replace(Blizz, "GetAddOnMetadata", function()
        return nil
    end)
    AreEqual("NONE", Private.GetAddonVersion("TestAddon"))
end

function Tests:GetNSRTNoteHashNotLoaded()
    Replace(Blizz, "IsAddOnLoaded", function()
        return false
    end)
    AreEqual("NONE", Private.GetNSRTNoteHash())
end

function Tests:GetNSRTNoteHashLoadedNoAPI()
    Replace(Blizz, "IsAddOnLoaded", function()
        return true
    end)
    Replace("NSAPI", nil)
    AreEqual("NONE", Private.GetNSRTNoteHash())
end

function Tests:GetNSRTNoteHashLoadedWithReminder()
    Replace(Blizz, "IsAddOnLoaded", function()
        return true
    end)
    Replace("NSAPI", {
        GetReminderString = function()
            return "personal note", "shared note"
        end,
    })
    local hash = Private.GetNSRTNoteHash()
    IsTrue(hash ~= "NONE")
    AreEqual(type(hash), "string")
    AreEqual(hash, Private.StringHash("shared note"))
end

function Tests:GetNSRTNoteHashLoadedEmptyReminder()
    Replace(Blizz, "IsAddOnLoaded", function()
        return true
    end)
    Replace("NSAPI", {
        GetReminderString = function()
            return "", ""
        end,
    })
    AreEqual("NONE", Private.GetNSRTNoteHash())
end

function Tests:CollectLocalVersionTableHasAllShortcodes()
    Replace(Blizz, "IsAddOnLoaded", function()
        return true
    end)
    Replace(Blizz, "GetAddOnMetadata", function()
        return "1.0.0"
    end)
    local versions = Private.CollectLocalVersionTable()

    for _, addon in ipairs(Private.AddonsToTrack) do
        IsTrue(versions[addon.shortcode] ~= nil)
    end
    IsTrue(versions["NSRTHASH"] ~= nil)
end

-- Guild info version check

function Tests:ParseGuildInfoVersionsReturnsCRT()
    Replace(Blizz, "GetGuildInfoText", function()
        return "Welcome to the guild!\n<CRT:42>"
    end)
    local versions = Private.ParseGuildInfoVersions()
    assert(versions)
    AreEqual("42", versions.CRT)
end

function Tests:ParseGuildInfoVersionsReturnsMultipleAddons()
    Replace(Blizz, "GetGuildInfoText", function()
        return "<CRT:42 NSRT:1.2.3>"
    end)
    local versions = Private.ParseGuildInfoVersions()
    assert(versions)
    AreEqual("42", versions.CRT)
    AreEqual("1.2.3", versions.NSRT)
end

function Tests:ParseGuildInfoVersionsNoTag()
    Replace(Blizz, "GetGuildInfoText", function()
        return "Welcome to the guild!"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:ParseGuildInfoVersionsNilText()
    Replace(Blizz, "GetGuildInfoText", function()
        return nil
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:ParseGuildInfoVersionsEmptyTag()
    Replace(Blizz, "GetGuildInfoText", function()
        return "<>"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:ParseGuildInfoVersionsPartialTag()
    Replace(Blizz, "GetGuildInfoText", function()
        return "<CRT:>"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:CheckGuildVersionsReturnsCRTWhenOutdated()
    Replace(Blizz, "GetGuildInfoText", function()
        return "<CRT:99>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    assert(outdated)
    AreEqual(1, #outdated)
    AreEqual("CoffeeRaidTools", outdated[1])
end

function Tests:CheckGuildVersionsReturnsEmptyWhenCurrent()
    Replace(Blizz, "GetGuildInfoText", function()
        return "<CRT:42>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    assert(outdated)
    AreEqual(0, #outdated)
end

function Tests:CheckGuildVersionsReturnsNilWhenNoTag()
    Replace(Blizz, "GetGuildInfoText", function()
        return "No version here"
    end)
    AreEqual(nil, Private.CheckGuildVersions())
end

function Tests:CheckGuildVersionsReturnsNilWhenNoGuildInfo()
    Replace(Blizz, "GetGuildInfoText", function()
        return nil
    end)
    AreEqual(nil, Private.CheckGuildVersions())
end

function Tests:CheckGuildVersionsSkipsUnknownShortcodes()
    Replace(Blizz, "GetGuildInfoText", function()
        return "<CRT:42 UNKNOWN:99>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(0, #outdated)
end

-- GetExpectedVersionTable

function Tests:GetExpectedVersionTableReturnsLeaderVersions()
    local leaderVersions = { CRT = "99", NSRTHASH = "abc" }
    Replace(Blizz, "IsInGroup", function()
        return true
    end)
    Replace(Private, "IterateGroupMembers", function()
        local units = { "raid1", "raid2" }
        local i = 0
        return function()
            i = i + 1
            return units[i]
        end
    end)
    Replace(Blizz, "UnitIsGroupLeader", function(unit)
        return unit == "raid1"
    end)
    Replace(Blizz, "UnitGUID", function(unit)
        return "guid-" .. unit
    end)
    Replace(Private, "GetGroupVersionsTable", function()
        return { ["guid-raid1"] = leaderVersions }
    end)
    AreEqual(leaderVersions, Private:GetExpectedVersionTable())
end

function Tests:GetExpectedVersionTableFallsBackWhenNotInGroup()
    local localVersions = { CRT = "1.0" }
    Replace(Blizz, "IsInGroup", function()
        return false
    end)
    Replace(Private, "GetLocalVersionTable", function()
        return localVersions
    end)
    AreEqual(localVersions, Private:GetExpectedVersionTable())
end

function Tests:GetExpectedVersionTableFallsBackWhenLeaderNotResponded()
    local localVersions = { CRT = "1.0" }
    Replace(Blizz, "IsInGroup", function()
        return true
    end)
    Replace(Private, "IterateGroupMembers", function()
        local units = { "raid1", "raid2" }
        local i = 0
        return function()
            i = i + 1
            return units[i]
        end
    end)
    Replace(Blizz, "UnitIsGroupLeader", function(unit)
        return unit == "raid1"
    end)
    Replace(Blizz, "UnitGUID", function()
        return "guid-leader"
    end)
    Replace(Private, "GetGroupVersionsTable", function()
        return {}
    end)
    Replace(Private, "GetLocalVersionTable", function()
        return localVersions
    end)
    AreEqual(localVersions, Private:GetExpectedVersionTable())
end

function Tests:GetExpectedVersionTableWorksWhenPlayerIsLeader()
    local leaderVersions = { CRT = "42" }
    Replace(Blizz, "IsInGroup", function()
        return true
    end)
    Replace(Private, "IterateGroupMembers", function()
        local units = { "player", "raid1" }
        local i = 0
        return function()
            i = i + 1
            return units[i]
        end
    end)
    Replace(Blizz, "UnitIsGroupLeader", function(unit)
        return unit == "player"
    end)
    Replace(Blizz, "UnitGUID", function(unit)
        return "guid-" .. unit
    end)
    Replace(Private, "GetGroupVersionsTable", function()
        return { ["guid-player"] = leaderVersions }
    end)
    AreEqual(leaderVersions, Private:GetExpectedVersionTable())
end

function Tests:GetExpectedVersionTableFallsBackWhenLeaderGUIDSecret()
    local localVersions = { CRT = "1.0" }
    Replace(Blizz, "IsInGroup", function()
        return true
    end)
    Replace(Private, "IterateGroupMembers", function()
        local units = { "raid1" }
        local i = 0
        return function()
            i = i + 1
            return units[i]
        end
    end)
    Replace(Blizz, "UnitIsGroupLeader", function()
        return true
    end)
    Replace(Blizz, "UnitGUID", function()
        return "secret-guid"
    end)
    Replace(Blizz, "issecretvalue", function()
        return true
    end)
    Replace(Private, "GetLocalVersionTable", function()
        return localVersions
    end)
    AreEqual(localVersions, Private:GetExpectedVersionTable())
end

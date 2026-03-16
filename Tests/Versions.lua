---@class Private
local Private = select(2, ...)

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
    Replace(C_AddOns, "IsAddOnLoaded", function(name)
        return name == "TestAddon"
    end)
    Replace(C_AddOns, "GetAddOnMetadata", function(name, key)
        if name == "TestAddon" and key == "Version" then
            return "1.2.3"
        end
    end)
    AreEqual("1.2.3", Private.GetAddonVersion("TestAddon"))
end

function Tests:GetAddonVersionNotLoaded()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return false
    end)
    AreEqual("NONE", Private.GetAddonVersion("FakeAddon"))
end

function Tests:GetAddonVersionNilMetadata()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return true
    end)
    Replace(C_AddOns, "GetAddOnMetadata", function()
        return nil
    end)
    AreEqual("NONE", Private.GetAddonVersion("TestAddon"))
end

function Tests:GetMRTNoteHashNotLoaded()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return false
    end)
    AreEqual("NONE", Private.GetMRTNoteHash())
end

function Tests:GetMRTNoteHashLoadedNoNote()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return true
    end)
    Replace("VMRT", nil)
    AreEqual("NONE", Private.GetMRTNoteHash())
end

function Tests:GetMRTNoteHashLoadedWithNote()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return true
    end)
    Replace("VMRT", { Note = { Text1 = "test note content" } })
    local hash = Private.GetMRTNoteHash()
    IsTrue(hash ~= "NONE")
    AreEqual(type(hash), "string")
    AreEqual(hash, Private.StringHash("test note content"))
end

function Tests:CollectLocalVersionTableHasAllShortcodes()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return true
    end)
    Replace(C_AddOns, "GetAddOnMetadata", function()
        return "1.0.0"
    end)
    Replace("VMRT", { Note = { Text1 = "note" } })

    local versions = Private.CollectLocalVersionTable()

    for _, addon in ipairs(Private.AddonsToTrack) do
        IsTrue(versions[addon.shortcode] ~= nil)
    end
    IsTrue(versions["MRTHASH"] ~= nil)
end

function Tests:CollectLocalVersionTableMRTHASHMatchesNote()
    Replace(C_AddOns, "IsAddOnLoaded", function()
        return true
    end)
    Replace(C_AddOns, "GetAddOnMetadata", function()
        return "1.0.0"
    end)
    Replace("VMRT", { Note = { Text1 = "my raid note" } })

    local versions = Private.CollectLocalVersionTable()
    AreEqual(Private.StringHash("my raid note"), versions["MRTHASH"])
end

-- Guild info version check

function Tests:ParseGuildInfoVersionsReturnsBothAddons()
    Replace("GetGuildInfoText", function()
        return "Welcome to the guild!\n<CRT:42 TR:1.2.3>"
    end)
    local versions = Private.ParseGuildInfoVersions()
    AreEqual("42", versions.CRT)
    AreEqual("1.2.3", versions.TR)
end

function Tests:ParseGuildInfoVersionsCRTOnly()
    Replace("GetGuildInfoText", function()
        return "<CRT:42>"
    end)
    local versions = Private.ParseGuildInfoVersions()
    AreEqual("42", versions.CRT)
    AreEqual(nil, versions.TR)
end

function Tests:ParseGuildInfoVersionsTROnly()
    Replace("GetGuildInfoText", function()
        return "<TR:5.0.0-beta>"
    end)
    local versions = Private.ParseGuildInfoVersions()
    AreEqual(nil, versions.CRT)
    AreEqual("5.0.0-beta", versions.TR)
end

function Tests:ParseGuildInfoVersionsNoTag()
    Replace("GetGuildInfoText", function()
        return "Welcome to the guild!"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:ParseGuildInfoVersionsNilText()
    Replace("GetGuildInfoText", function()
        return nil
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:ParseGuildInfoVersionsEmptyTag()
    Replace("GetGuildInfoText", function()
        return "<>"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:ParseGuildInfoVersionsPartialTag()
    Replace("GetGuildInfoText", function()
        return "<CRT:>"
    end)
    AreEqual(nil, Private.ParseGuildInfoVersions())
end

function Tests:CheckGuildVersionsReturnsCRTWhenOutdated()
    Replace("GetGuildInfoText", function()
        return "<CRT:99 TR:1.0>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
        if name == "TimelineReminders" then
            return "1.0"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(1, #outdated)
    AreEqual("CoffeeRaidTools", outdated[1])
end

function Tests:CheckGuildVersionsReturnsTRWhenOutdated()
    Replace("GetGuildInfoText", function()
        return "<CRT:42 TR:2.0>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
        if name == "TimelineReminders" then
            return "1.0"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(1, #outdated)
    AreEqual("TimelineReminders", outdated[1])
end

function Tests:CheckGuildVersionsReturnsBothWhenOutdated()
    Replace("GetGuildInfoText", function()
        return "<CRT:99 TR:2.0>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
        if name == "TimelineReminders" then
            return "1.0"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(2, #outdated)
end

function Tests:CheckGuildVersionsReturnsEmptyWhenCurrent()
    Replace("GetGuildInfoText", function()
        return "<CRT:42 TR:1.0>"
    end)
    Replace(Private, "GetAddonVersion", function(name)
        if name == "CoffeeRaidTools" then
            return "42"
        end
        if name == "TimelineReminders" then
            return "1.0"
        end
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(0, #outdated)
end

function Tests:CheckGuildVersionsReturnsEmptyWhenNoTag()
    Replace("GetGuildInfoText", function()
        return "No version here"
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(0, #outdated)
end

function Tests:CheckGuildVersionsReturnsEmptyWhenNoGuildInfo()
    Replace("GetGuildInfoText", function()
        return nil
    end)
    local outdated = Private.CheckGuildVersions()
    AreEqual(0, #outdated)
end

function Tests:CheckGuildVersionsSkipsUnknownShortcodes()
    Replace("GetGuildInfoText", function()
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

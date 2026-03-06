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

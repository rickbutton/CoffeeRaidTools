---@class Private
local Private = select(2, ...)
local Blizz = Private.Blizz

local Tests, Asserts = Private.Tests:CreateSuite("Messaging")
local AreEqual, IsTrue, IsFalse, Replace = Asserts.AreEqual, Asserts.IsTrue, Asserts.IsFalse, Asserts.Replace

function Tests:RoundTripSimpleMessage()
    local original = { op = "VREQ", data = {} }
    local encoded = Private.EncodeMessage(original)
    local decoded = Private.DecodeMessage(encoded)
    ---@cast decoded -nil
    AreEqual("VREQ", decoded.op)
end

function Tests:RoundTripVersionResponse()
    local versionData = { CRT = "1.0.0", BW = "2.0.0", NSRT = "3.0.0" }
    local original = { op = "VRES", data = versionData }
    local encoded = Private.EncodeMessage(original)
    local decoded = Private.DecodeMessage(encoded)
    ---@cast decoded -nil
    AreEqual("VRES", decoded.op)
    AreEqual("1.0.0", decoded.data.CRT)
    AreEqual("2.0.0", decoded.data.BW)
    AreEqual("3.0.0", decoded.data.NSRT)
end

function Tests:RoundTripReload()
    local original = { op = "RELOAD", data = {} }
    local encoded = Private.EncodeMessage(original)
    local decoded = Private.DecodeMessage(encoded)
    ---@cast decoded -nil
    AreEqual("RELOAD", decoded.op)
end

function Tests:RoundTripPreservesAllVersionFields()
    local versionData = {}
    for _, addon in ipairs(Private.AddonsToTrack) do
        versionData[addon.shortcode] = "v" .. addon.shortcode
    end
    versionData["NSRTHASH"] = "nsrthash456"

    local encoded = Private.EncodeMessage({ op = "VRES", data = versionData })
    local decoded = Private.DecodeMessage(encoded)
    ---@cast decoded -nil

    for _, addon in ipairs(Private.AddonsToTrack) do
        AreEqual("v" .. addon.shortcode, decoded.data[addon.shortcode])
    end
    AreEqual("nsrthash456", decoded.data["NSRTHASH"])
end

function Tests:DecodeGarbageReturnsNil()
    local result, err = Private.DecodeMessage("not a valid encoded string!!")
    IsFalse(result)
    IsTrue(err ~= nil)
end

function Tests:DecodeEmptyStringReturnsNil()
    local result, err = Private.DecodeMessage("")
    IsFalse(result)
    IsTrue(err ~= nil)
end

function Tests:GetGroupBroadcastTargetInstanceChat()
    Replace(Blizz, "IsInGroup", function(category)
        return category == LE_PARTY_CATEGORY_INSTANCE
    end)
    Replace(Blizz, "IsInRaid", function()
        return false
    end)
    AreEqual("INSTANCE_CHAT", Private.GetGroupBroadcastTarget())
end

function Tests:GetGroupBroadcastTargetRaid()
    Replace(Blizz, "IsInGroup", function()
        return false
    end)
    Replace(Blizz, "IsInRaid", function()
        return true
    end)
    AreEqual("RAID", Private.GetGroupBroadcastTarget())
end

function Tests:GetGroupBroadcastTargetParty()
    Replace(Blizz, "IsInGroup", function()
        return false
    end)
    Replace(Blizz, "IsInRaid", function()
        return false
    end)
    AreEqual("PARTY", Private.GetGroupBroadcastTarget())
end

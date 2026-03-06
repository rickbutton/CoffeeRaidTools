if not WoWUnit then return end

---@class Private
local Private = select(2, ...)

local AreEqual, IsTrue, IsFalse, Replace = WoWUnit.AreEqual, WoWUnit.IsTrue, WoWUnit.IsFalse, WoWUnit.Replace
local Tests = WoWUnit("CRT Messaging")

function Tests:RoundTripSimpleMessage()
    local original = { op = "VREQ", data = {} }
    local encoded = Private.EncodeMessage(original)
    local decoded = Private.DecodeMessage(encoded)
    AreEqual("VREQ", decoded.op)
end

function Tests:RoundTripVersionResponse()
    local versionData = { CRT = "1.0.0", BW = "2.0.0", NSRT = "3.0.0" }
    local original = { op = "VRES", data = versionData }
    local encoded = Private.EncodeMessage(original)
    local decoded = Private.DecodeMessage(encoded)
    AreEqual("VRES", decoded.op)
    AreEqual("1.0.0", decoded.data.CRT)
    AreEqual("2.0.0", decoded.data.BW)
    AreEqual("3.0.0", decoded.data.NSRT)
end

function Tests:RoundTripReload()
    local original = { op = "RELOAD", data = {} }
    local encoded = Private.EncodeMessage(original)
    local decoded = Private.DecodeMessage(encoded)
    AreEqual("RELOAD", decoded.op)
end

function Tests:RoundTripPreservesAllVersionFields()
    local versionData = {}
    for _, addon in ipairs(Private.AddonsToTrack) do
        versionData[addon.shortcode] = "v" .. addon.shortcode
    end
    versionData["MRTHASH"] = "somehash123"

    local encoded = Private.EncodeMessage({ op = "VRES", data = versionData })
    local decoded = Private.DecodeMessage(encoded)

    for _, addon in ipairs(Private.AddonsToTrack) do
        AreEqual("v" .. addon.shortcode, decoded.data[addon.shortcode])
    end
    AreEqual("somehash123", decoded.data["MRTHASH"])
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
    Replace("IsInGroup", function(category)
        return category == LE_PARTY_CATEGORY_INSTANCE
    end)
    Replace("IsInRaid", function() return false end)
    AreEqual("INSTANCE_CHAT", Private.GetGroupBroadcastTarget())
end

function Tests:GetGroupBroadcastTargetRaid()
    Replace("IsInGroup", function() return false end)
    Replace("IsInRaid", function() return true end)
    AreEqual("RAID", Private.GetGroupBroadcastTarget())
end

function Tests:GetGroupBroadcastTargetParty()
    Replace("IsInGroup", function() return false end)
    Replace("IsInRaid", function() return false end)
    AreEqual("PARTY", Private.GetGroupBroadcastTarget())
end

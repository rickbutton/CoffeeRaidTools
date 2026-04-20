describe("Messaging", function()
    after_each(Restore)

    describe("Encode / Decode round-trip", function()
        it("preserves a simple message", function()
            local encoded = Private.EncodeMessage({ op = "VREQ", data = {} })
            local decoded = Private.DecodeMessage(encoded)
            assert.is_not_nil(decoded)
            assert.are.equal("VREQ", decoded.op)
        end)

        it("preserves a version response", function()
            local versionData = { CRT = "1.0.0", BW = "2.0.0", NSRT = "3.0.0" }
            local encoded = Private.EncodeMessage({ op = "VRES", data = versionData })
            local decoded = Private.DecodeMessage(encoded)
            assert.is_not_nil(decoded)
            assert.are.equal("VRES", decoded.op)
            assert.are.equal("1.0.0", decoded.data.CRT)
            assert.are.equal("2.0.0", decoded.data.BW)
            assert.are.equal("3.0.0", decoded.data.NSRT)
        end)

        it("preserves a RELOAD message", function()
            local encoded = Private.EncodeMessage({ op = "RELOAD", data = {} })
            local decoded = Private.DecodeMessage(encoded)
            assert.is_not_nil(decoded)
            assert.are.equal("RELOAD", decoded.op)
        end)

        it("preserves every tracked addon shortcode", function()
            local versionData = {}
            for _, addon in ipairs(Private.AddonsToTrack) do
                versionData[addon.shortcode] = "v" .. addon.shortcode
            end
            versionData["NSRTHASH"] = "nsrthash456"

            local encoded = Private.EncodeMessage({ op = "VRES", data = versionData })
            local decoded = Private.DecodeMessage(encoded)
            assert.is_not_nil(decoded)

            for _, addon in ipairs(Private.AddonsToTrack) do
                assert.are.equal("v" .. addon.shortcode, decoded.data[addon.shortcode])
            end
            assert.are.equal("nsrthash456", decoded.data["NSRTHASH"])
        end)
    end)

    describe("DecodeMessage", function()
        it("returns nil and an error for garbage input", function()
            local result, err = Private.DecodeMessage("not a valid encoded string!!")
            assert.is_falsy(result)
            assert.is_not_nil(err)
        end)

        it("returns nil and an error for empty input", function()
            local result, err = Private.DecodeMessage("")
            assert.is_falsy(result)
            assert.is_not_nil(err)
        end)
    end)

    describe("GetGroupBroadcastTarget", function()
        it("returns INSTANCE_CHAT when in an instance group", function()
            Replace(Blizz, "IsInGroup", function(category)
                return category == LE_PARTY_CATEGORY_INSTANCE
            end)
            Replace(Blizz, "IsInRaid", function()
                return false
            end)
            assert.are.equal("INSTANCE_CHAT", Private.GetGroupBroadcastTarget())
        end)

        it("returns RAID when in a raid", function()
            Replace(Blizz, "IsInGroup", function()
                return false
            end)
            Replace(Blizz, "IsInRaid", function()
                return true
            end)
            assert.are.equal("RAID", Private.GetGroupBroadcastTarget())
        end)

        it("returns PARTY as the fallback", function()
            Replace(Blizz, "IsInGroup", function()
                return false
            end)
            Replace(Blizz, "IsInRaid", function()
                return false
            end)
            assert.are.equal("PARTY", Private.GetGroupBroadcastTarget())
        end)
    end)
end)

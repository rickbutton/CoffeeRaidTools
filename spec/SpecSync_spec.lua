describe("SpecSync", function()
    after_each(function()
        Private.SpecSyncReset()
        Restore()
    end)

    describe("BroadcastOwnSpec", function()
        it("sends the player's specID over AceComm when in a group", function()
            Replace("IsInRaid", function()
                return true
            end)
            Replace("IsInGroup", function(cat)
                return cat == nil
            end)
            Replace("GetSpecialization", function()
                return 1
            end)
            Replace("GetSpecializationInfo", function()
                return 73 -- Protection Warrior
            end)
            Replace("UnitGUID", function()
                return "Player-Me"
            end)

            local sent
            Replace(CoffeeRaidTools, "SendCommMessage", function(_, prefix, payload, target)
                sent = { prefix = prefix, payload = payload, target = target }
            end)

            Private:BroadcastOwnSpec()

            assert.is_not_nil(sent)
            assert.are.equal(Private.SpecSyncPrefix, sent.prefix)
            assert.are.equal("RAID", sent.target)
            assert.is_string(sent.payload)
        end)

        it("does nothing outside of a group", function()
            Replace("IsInRaid", function()
                return false
            end)
            Replace("IsInGroup", function()
                return false
            end)
            local sent = false
            Replace(CoffeeRaidTools, "SendCommMessage", function()
                sent = true
            end)

            Private:BroadcastOwnSpec()
            assert.is_false(sent)
        end)

        it("does nothing when GetSpecialization returns nil", function()
            Replace("IsInRaid", function()
                return true
            end)
            Replace("IsInGroup", function(cat)
                return cat == nil
            end)
            Replace("GetSpecialization", function()
                return nil
            end)
            local sent = false
            Replace(CoffeeRaidTools, "SendCommMessage", function()
                sent = true
            end)

            Private:BroadcastOwnSpec()
            assert.is_false(sent)
        end)

        it("caches the player's own spec so GetUnitSpec(player) works without a round trip", function()
            Replace("IsInRaid", function()
                return true
            end)
            Replace("IsInGroup", function(cat)
                return cat == nil
            end)
            Replace("GetSpecialization", function()
                return 1
            end)
            Replace("GetSpecializationInfo", function()
                return 73
            end)
            Replace("UnitGUID", function()
                return "Player-Me"
            end)
            Replace(CoffeeRaidTools, "SendCommMessage", function() end)

            Private:BroadcastOwnSpec()
            assert.are.equal(73, Private:GetUnitSpec("player"))
        end)
    end)

    describe("receiving peer specs", function()
        it("stores the sender's spec keyed by GUID", function()
            Replace("UnitGUID", function(unit)
                if unit == "raid3" then
                    return "Player-Them"
                elseif unit == "player" then
                    return "Player-Me"
                end
                return nil
            end)
            Replace("UnitIsUnit", function()
                return false
            end)

            -- Round-trip a real encoded payload.
            Replace("IsInRaid", function()
                return true
            end)
            Replace("IsInGroup", function(cat)
                return cat == nil
            end)
            Replace("GetSpecialization", function()
                return 1
            end)
            Replace("GetSpecializationInfo", function()
                return 268 -- Brewmaster Monk
            end)
            local captured
            Replace(CoffeeRaidTools, "SendCommMessage", function(_, _, payload)
                captured = payload
            end)
            Private:BroadcastOwnSpec()
            assert.is_not_nil(captured)

            -- Deliver it as if it came from raid3.
            Private.SpecSyncReceive(Private.SpecSyncPrefix, captured, "RAID", "raid3")

            assert.are.equal(268, Private:GetUnitSpec("raid3"))
        end)

        it("ignores payloads with the wrong shape", function()
            Replace("UnitGUID", function()
                return "Player-Them"
            end)
            Replace("UnitIsUnit", function()
                return false
            end)
            Private.SpecSyncReceive(Private.SpecSyncPrefix, "garbage", "RAID", "raid3")
            assert.is_nil(Private:GetUnitSpec("raid3"))
        end)
    end)

    describe("GetUnitSpec for player", function()
        it("returns the live spec for the player unit without needing a broadcast", function()
            Replace("UnitIsUnit", function(a, b)
                return a == "player" and b == "player"
            end)
            Replace("GetSpecialization", function()
                return 2
            end)
            Replace("GetSpecializationInfo", function()
                return 65 -- Holy Paladin
            end)
            Private.SpecSyncReset()
            assert.are.equal(65, Private:GetUnitSpec("player"))
        end)
    end)
end)

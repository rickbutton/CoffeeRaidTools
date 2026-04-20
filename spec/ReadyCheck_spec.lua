describe("ReadyCheck", function()
    after_each(Restore)

    describe("ShouldShowPopup", function()
        it("returns false when set to never", function()
            Private.db.readyCheckPopup = "never"
            assert.is_false(Private.ShouldShowPopup())
        end)

        it("returns true when set to always", function()
            Private.db.readyCheckPopup = "always"
            assert.is_true(Private.ShouldShowPopup())
        end)

        it("returns true for inraid when the player is in a raid", function()
            Private.db.readyCheckPopup = "inraid"
            Replace("IsInRaid", function()
                return true
            end)
            assert.is_true(Private.ShouldShowPopup())
        end)

        it("returns false for inraid when the player is not in a raid", function()
            Private.db.readyCheckPopup = "inraid"
            Replace("IsInRaid", function()
                return false
            end)
            assert.is_false(Private.ShouldShowPopup())
        end)

        it("returns true for inraidcoffee when both conditions are met", function()
            Private.db.readyCheckPopup = "inraidcoffee"
            Replace("IsInRaid", function()
                return true
            end)
            Replace(Private, "IsInCoffeeRaid", function()
                return true
            end)
            assert.is_true(Private.ShouldShowPopup())
        end)

        it("returns false for inraidcoffee when the raid is not a Coffee raid", function()
            Private.db.readyCheckPopup = "inraidcoffee"
            Replace("IsInRaid", function()
                return true
            end)
            Replace(Private, "IsInCoffeeRaid", function()
                return false
            end)
            assert.is_false(Private.ShouldShowPopup())
        end)

        it("returns false for inraidcoffee when the player is not in a raid", function()
            Private.db.readyCheckPopup = "inraidcoffee"
            Replace("IsInRaid", function()
                return false
            end)
            assert.is_false(Private.ShouldShowPopup())
        end)

        it("returns false for unknown settings", function()
            Private.db.readyCheckPopup = "somethingelse"
            assert.is_false(Private.ShouldShowPopup())
        end)
    end)

    describe("IsInCoffeeRaid", function()
        it("returns true when a majority of real players are in Coffee", function()
            local units = { "raid1", "raid2", "raid3" }
            local guildInfo = { raid1 = "Coffee", raid2 = "Coffee", raid3 = "Other" }
            local guids = { raid1 = "Player-1", raid2 = "Player-2", raid3 = "Player-3" }

            Replace(Private, "IterateGroupMembers", function()
                local i = 0
                return function()
                    i = i + 1
                    return units[i]
                end
            end)
            Replace(Private, "UnitIsRealPlayer", function()
                return true
            end)
            Replace("GetGuildInfo", function(unit)
                return guildInfo[unit]
            end)
            Replace("UnitGUID", function(unit)
                return guids[unit]
            end)
            assert.is_true(Private.IsInCoffeeRaid())
        end)

        it("returns false when Coffee players are a minority", function()
            local units = { "raid1", "raid2", "raid3" }
            local guildInfo = { raid1 = "Coffee", raid2 = "Other", raid3 = "Other" }
            local guids = { raid1 = "Player-1", raid2 = "Player-2", raid3 = "Player-3" }

            Replace(Private, "IterateGroupMembers", function()
                local i = 0
                return function()
                    i = i + 1
                    return units[i]
                end
            end)
            Replace(Private, "UnitIsRealPlayer", function()
                return true
            end)
            Replace("GetGuildInfo", function(unit)
                return guildInfo[unit]
            end)
            Replace("UnitGUID", function(unit)
                return guids[unit]
            end)
            assert.is_false(Private.IsInCoffeeRaid())
        end)

        it("returns false for an empty group", function()
            Replace(Private, "IterateGroupMembers", function()
                return function()
                    return nil
                end
            end)
            assert.is_false(Private.IsInCoffeeRaid())
        end)
    end)
end)

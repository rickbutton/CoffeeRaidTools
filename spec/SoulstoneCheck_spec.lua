describe("SoulstoneCheck", function()
    local function mockGroupMembers(units)
        Replace(Private, "IterateGroupMembers", function()
            local i = 0
            return function()
                i = i + 1
                return units[i]
            end
        end)
    end

    local function mockNotRestricted()
        Replace(Blizz, "ShouldAurasBeSecret", function()
            return false
        end)
    end

    local function mockSpellReady()
        Replace(Blizz, "GetSpellCooldown", function()
            return { duration = 0, startTime = 0 }
        end)
    end

    local function mockSpellInfo()
        Replace(Blizz, "GetSpellInfo", function()
            return { name = "Soulstone" }
        end)
    end

    local function mockTime(t)
        Replace(Blizz, "GetTime", function()
            return t
        end)
    end

    after_each(Restore)

    it("returns true when auras are secret", function()
        Replace(Blizz, "ShouldAurasBeSecret", function()
            return true
        end)
        assert.is_true(Private.HasSoulstoneOnHealer())
    end)

    it("returns true when Soulstone has a long cooldown", function()
        mockNotRestricted()
        mockTime(100)
        Replace(Blizz, "GetSpellCooldown", function()
            return { duration = 120, startTime = 50 }
        end)
        -- remaining = 120 + 50 - 100 = 70 (> 30)
        assert.is_true(Private.HasSoulstoneOnHealer())
    end)

    it("returns false when no healer has the buff", function()
        mockNotRestricted()
        mockSpellReady()
        mockSpellInfo()
        mockTime(100)
        mockGroupMembers({ "raid1", "raid2" })
        Replace(Blizz, "UnitGroupRolesAssigned", function(unit)
            return unit == "raid1" and "HEALER" or "DAMAGER"
        end)
        Replace(Blizz, "UnitIsVisible", function()
            return true
        end)
        Replace(Blizz, "GetAuraDataBySpellName", function()
            return nil
        end)
        assert.is_false(Private.HasSoulstoneOnHealer())
    end)

    it("returns true when a healer has an active Soulstone from the player", function()
        mockNotRestricted()
        mockSpellReady()
        mockSpellInfo()
        mockTime(100)
        mockGroupMembers({ "raid1" })
        Replace(Blizz, "UnitGroupRolesAssigned", function()
            return "HEALER"
        end)
        Replace(Blizz, "UnitIsVisible", function()
            return true
        end)
        Replace(Blizz, "GetAuraDataBySpellName", function()
            return { sourceUnit = "player", expirationTime = 900 }
        end)
        Replace(Blizz, "UnitExists", function()
            return true
        end)
        Replace(Blizz, "UnitIsUnit", function()
            return true
        end)
        -- remaining = 900 - 100 = 800 (> 300)
        assert.is_true(Private.HasSoulstoneOnHealer())
    end)

    it("returns false when the Soulstone is expiring soon", function()
        mockNotRestricted()
        mockSpellReady()
        mockSpellInfo()
        mockTime(100)
        mockGroupMembers({ "raid1" })
        Replace(Blizz, "UnitGroupRolesAssigned", function()
            return "HEALER"
        end)
        Replace(Blizz, "UnitIsVisible", function()
            return true
        end)
        Replace(Blizz, "GetAuraDataBySpellName", function()
            return { sourceUnit = "player", expirationTime = 350 }
        end)
        Replace(Blizz, "UnitExists", function()
            return true
        end)
        Replace(Blizz, "UnitIsUnit", function()
            return true
        end)
        -- remaining = 350 - 100 = 250 (< 300)
        assert.is_false(Private.HasSoulstoneOnHealer())
    end)

    it("returns false when the Soulstone came from another warlock", function()
        mockNotRestricted()
        mockSpellReady()
        mockSpellInfo()
        mockTime(100)
        mockGroupMembers({ "raid1" })
        Replace(Blizz, "UnitGroupRolesAssigned", function()
            return "HEALER"
        end)
        Replace(Blizz, "UnitIsVisible", function()
            return true
        end)
        Replace(Blizz, "GetAuraDataBySpellName", function()
            return { sourceUnit = "raid5", expirationTime = 900 }
        end)
        Replace(Blizz, "UnitExists", function()
            return true
        end)
        Replace(Blizz, "UnitIsUnit", function()
            return false
        end)
        assert.is_false(Private.HasSoulstoneOnHealer())
    end)

    it("skips non-healers", function()
        mockNotRestricted()
        mockSpellReady()
        mockSpellInfo()
        mockTime(100)
        mockGroupMembers({ "raid1" })
        Replace(Blizz, "UnitGroupRolesAssigned", function()
            return "DAMAGER"
        end)
        Replace(Blizz, "UnitIsVisible", function()
            return true
        end)
        Replace(Blizz, "GetAuraDataBySpellName", function()
            return nil
        end)
        assert.is_false(Private.HasSoulstoneOnHealer())
    end)

    it("skips invisible healers", function()
        mockNotRestricted()
        mockSpellReady()
        mockSpellInfo()
        mockTime(100)
        mockGroupMembers({ "raid1" })
        Replace(Blizz, "UnitGroupRolesAssigned", function()
            return "HEALER"
        end)
        Replace(Blizz, "UnitIsVisible", function()
            return false
        end)
        assert.is_false(Private.HasSoulstoneOnHealer())
    end)
end)

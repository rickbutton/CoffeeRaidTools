---@class Private
local Private = select(2, ...)
local Blizz = Private.Blizz

local Tests, Asserts = Private.Tests:CreateSuite("SoulstoneCheck")
local IsTrue, IsFalse, Replace = Asserts.IsTrue, Asserts.IsFalse, Asserts.Replace

local function MockGroupMembers(units)
    Replace(Private, "IterateGroupMembers", function()
        local i = 0
        return function()
            i = i + 1
            return units[i]
        end
    end)
end

local function MockNotRestricted()
    Replace(Blizz, "ShouldAurasBeSecret", function()
        return false
    end)
end

local function MockSpellReady()
    Replace(Blizz, "GetSpellCooldown", function()
        return { duration = 0, startTime = 0 }
    end)
end

local function MockSpellInfo()
    Replace(Blizz, "GetSpellInfo", function()
        return { name = "Soulstone" }
    end)
end

local function MockTime(time)
    Replace(Blizz, "GetTime", function()
        return time
    end)
end

function Tests:ReturnsTrueWhenAurasAreSecret()
    Replace(Blizz, "ShouldAurasBeSecret", function()
        return true
    end)
    IsTrue(Private.HasSoulstoneOnHealer())
end

function Tests:ReturnsTrueWhenSoulstoneOnLongCooldown()
    MockNotRestricted()
    MockTime(100)
    Replace(Blizz, "GetSpellCooldown", function()
        return { duration = 120, startTime = 50 }
    end)
    -- remaining = 120 + 50 - 100 = 70, which is > 30
    IsTrue(Private.HasSoulstoneOnHealer())
end

function Tests:ReturnsFalseWhenNoHealerHasBuff()
    MockNotRestricted()
    MockSpellReady()
    MockSpellInfo()
    MockTime(100)
    MockGroupMembers({ "raid1", "raid2" })
    Replace(Blizz, "UnitGroupRolesAssigned", function(unit)
        return unit == "raid1" and "HEALER" or "DAMAGER"
    end)
    Replace(Blizz, "UnitIsVisible", function()
        return true
    end)
    Replace(Blizz, "GetAuraDataBySpellName", function()
        return nil
    end)
    IsFalse(Private.HasSoulstoneOnHealer())
end

function Tests:ReturnsTrueWhenHealerHasActiveSoulstone()
    MockNotRestricted()
    MockSpellReady()
    MockSpellInfo()
    MockTime(100)
    MockGroupMembers({ "raid1" })
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
    -- remaining = 900 - 100 = 800, which is > 300
    IsTrue(Private.HasSoulstoneOnHealer())
end

function Tests:ReturnsFalseWhenSoulstoneExpiringSoon()
    MockNotRestricted()
    MockSpellReady()
    MockSpellInfo()
    MockTime(100)
    MockGroupMembers({ "raid1" })
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
    -- remaining = 350 - 100 = 250, which is < 300
    IsFalse(Private.HasSoulstoneOnHealer())
end

function Tests:ReturnsFalseWhenSoulstoneFromAnotherWarlock()
    MockNotRestricted()
    MockSpellReady()
    MockSpellInfo()
    MockTime(100)
    MockGroupMembers({ "raid1" })
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
    IsFalse(Private.HasSoulstoneOnHealer())
end

function Tests:SkipsNonHealers()
    MockNotRestricted()
    MockSpellReady()
    MockSpellInfo()
    MockTime(100)
    MockGroupMembers({ "raid1" })
    Replace(Blizz, "UnitGroupRolesAssigned", function()
        return "DAMAGER"
    end)
    Replace(Blizz, "UnitIsVisible", function()
        return true
    end)
    Replace(Blizz, "GetAuraDataBySpellName", function()
        return nil
    end)
    IsFalse(Private.HasSoulstoneOnHealer())
end

function Tests:SkipsInvisibleHealers()
    MockNotRestricted()
    MockSpellReady()
    MockSpellInfo()
    MockTime(100)
    MockGroupMembers({ "raid1" })
    Replace(Blizz, "UnitGroupRolesAssigned", function()
        return "HEALER"
    end)
    Replace(Blizz, "UnitIsVisible", function()
        return false
    end)
    IsFalse(Private.HasSoulstoneOnHealer())
end

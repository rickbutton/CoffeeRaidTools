if not WoWUnit then return end

---@class Private
local Private = select(2, ...)

local IsTrue, IsFalse, Replace = WoWUnit.IsTrue, WoWUnit.IsFalse, WoWUnit.Replace
local Tests = WoWUnit("CRT ReadyCheck")

function Tests:ShouldShowPopupNever()
    Private.db.readyCheckPopup = "never"
    IsFalse(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupAlways()
    Private.db.readyCheckPopup = "always"
    IsTrue(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupInRaidWhenInRaid()
    Private.db.readyCheckPopup = "inraid"
    Replace("IsInRaid", function() return true end)
    IsTrue(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupInRaidWhenNotInRaid()
    Private.db.readyCheckPopup = "inraid"
    Replace("IsInRaid", function() return false end)
    IsFalse(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupInRaidCoffeeWhenBothTrue()
    Private.db.readyCheckPopup = "inraidcoffee"
    Replace("IsInRaid", function() return true end)
    Replace(Private, "IsInCoffeeRaid", function() return true end)
    IsTrue(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupInRaidCoffeeWhenNotCoffee()
    Private.db.readyCheckPopup = "inraidcoffee"
    Replace("IsInRaid", function() return true end)
    Replace(Private, "IsInCoffeeRaid", function() return false end)
    IsFalse(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupInRaidCoffeeWhenNotInRaid()
    Private.db.readyCheckPopup = "inraidcoffee"
    Replace("IsInRaid", function() return false end)
    IsFalse(Private.ShouldShowPopup())
end

function Tests:ShouldShowPopupUnknownSetting()
    Private.db.readyCheckPopup = "somethingelse"
    IsFalse(Private.ShouldShowPopup())
end

function Tests:IsInCoffeeRaidMajorityCoffee()
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
    Replace(Private, "UnitIsRealPlayer", function() return true end)
    Replace("GetGuildInfo", function(unit) return guildInfo[unit] end)
    Replace("UnitGUID", function(unit) return guids[unit] end)
    IsTrue(Private.IsInCoffeeRaid())
end

function Tests:IsInCoffeeRaidMinorityCoffee()
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
    Replace(Private, "UnitIsRealPlayer", function() return true end)
    Replace("GetGuildInfo", function(unit) return guildInfo[unit] end)
    Replace("UnitGUID", function(unit) return guids[unit] end)
    IsFalse(Private.IsInCoffeeRaid())
end

function Tests:IsInCoffeeRaidEmptyGroup()
    Replace(Private, "IterateGroupMembers", function()
        return function() return nil end
    end)
    IsFalse(Private.IsInCoffeeRaid())
end

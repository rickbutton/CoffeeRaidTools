if not WoWUnit then return end

---@class Private
local Private = select(2, ...)

local AreEqual, IsTrue, Replace = WoWUnit.AreEqual, WoWUnit.IsTrue, WoWUnit.Replace
local Tests = WoWUnit("CRT ChatCommands")

function Tests:EmptyInputTogglesFrame()
    local toggled = false
    Replace(CoffeeRaidTools, "ToggleFrame", function() toggled = true end)
    CoffeeRaidTools:ChatCommandHandler("")
    IsTrue(toggled)
end

function Tests:NilInputTogglesFrame()
    local toggled = false
    Replace(CoffeeRaidTools, "ToggleFrame", function() toggled = true end)
    CoffeeRaidTools:ChatCommandHandler(nil)
    IsTrue(toggled)
end

function Tests:DebugCommandTogglesDebug()
    local original = Private.db.debug
    Replace(CoffeeRaidTools, "Print", function() end)
    CoffeeRaidTools:ChatCommandHandler("debug")
    AreEqual(not original, Private.db.debug)
    Private.db.debug = original
end

function Tests:UnknownCommandPrints()
    local printed = false
    Replace(CoffeeRaidTools, "Print", function() printed = true end)
    CoffeeRaidTools:ChatCommandHandler("nonexistentcommand")
    IsTrue(printed)
end

function Tests:UnknownTestSubcommandPrints()
    local printed = false
    Replace(CoffeeRaidTools, "Print", function() printed = true end)
    CoffeeRaidTools:ChatCommandHandler("test nonexistent")
    IsTrue(printed)
end

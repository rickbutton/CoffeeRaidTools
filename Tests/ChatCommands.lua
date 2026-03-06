---@class Private
local Private = select(2, ...)

local Tests, Asserts = Private.Tests:CreateSuite("ChatCommands")
local AreEqual, IsTrue, Replace = Asserts.AreEqual, Asserts.IsTrue, Asserts.Replace

function Tests:EmptyInputTogglesFrame()
    local toggled = false
    Replace(CoffeeRaidTools, "ToggleFrame", function()
        toggled = true
    end)
    CoffeeRaidTools:ChatCommandHandler("")
    IsTrue(toggled)
end

function Tests:NilInputTogglesFrame()
    local toggled = false
    Replace(CoffeeRaidTools, "ToggleFrame", function()
        toggled = true
    end)
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
    Replace(CoffeeRaidTools, "Print", function()
        printed = true
    end)
    CoffeeRaidTools:ChatCommandHandler("nonexistentcommand")
    IsTrue(printed)
end

function Tests:UnknownTestSubcommandPrints()
    local printed = false
    Replace(CoffeeRaidTools, "Print", function()
        printed = true
    end)
    CoffeeRaidTools:ChatCommandHandler("test nonexistent")
    IsTrue(printed)
end

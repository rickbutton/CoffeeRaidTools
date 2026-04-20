describe("ChatCommands", function()
    after_each(Restore)

    it("toggles the frame on empty input", function()
        local toggled = false
        Replace(CoffeeRaidTools, "ToggleFrame", function()
            toggled = true
        end)
        CoffeeRaidTools:ChatCommandHandler("")
        assert.is_true(toggled)
    end)

    it("toggles the frame on nil input", function()
        local toggled = false
        Replace(CoffeeRaidTools, "ToggleFrame", function()
            toggled = true
        end)
        CoffeeRaidTools:ChatCommandHandler(nil)
        assert.is_true(toggled)
    end)

    it("`debug` flips Private.db.debug", function()
        local original = Private.db.debug
        Replace(CoffeeRaidTools, "Print", function() end)
        CoffeeRaidTools:ChatCommandHandler("debug")
        assert.are.equal(not original, Private.db.debug)
        Private.db.debug = original
    end)

    it("prints a message for unknown top-level commands", function()
        local printed = false
        Replace(CoffeeRaidTools, "Print", function()
            printed = true
        end)
        CoffeeRaidTools:ChatCommandHandler("nonexistentcommand")
        assert.is_true(printed)
    end)

    it("prints a message for unknown `test` subcommands", function()
        local printed = false
        Replace(CoffeeRaidTools, "Print", function()
            printed = true
        end)
        CoffeeRaidTools:ChatCommandHandler("test nonexistent")
        assert.is_true(printed)
    end)
end)

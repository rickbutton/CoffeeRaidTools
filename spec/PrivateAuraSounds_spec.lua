describe("PrivateAuraSounds", function()
    local function mockIterateGroupMembers(units)
        Replace(Private, "IterateGroupMembers", function()
            local i = 0
            return function()
                i = i + 1
                return units[i]
            end
        end)
    end

    local function mockNickname(nicknames)
        Replace(CoffeeRaidTools, "GetNickname", function(_, unit)
            return nicknames[unit]
        end)
    end

    local function mockCombat(inCombat)
        Replace(Private, "IsInCombat", function()
            return inCombat
        end)
    end

    local function countAddsForUnits(calls, units)
        local lookup = {}
        for _, unit in ipairs(units) do
            lookup[unit] = true
        end
        local matched = {}
        for _, call in ipairs(calls) do
            if call.action == "add" and lookup[call.unit] then
                table.insert(matched, call)
            end
        end
        return matched
    end

    local function mockBlizzAPIs(calls)
        Replace(Blizz, "AuraIsPrivate", function()
            return true
        end)
        Replace(Blizz, "AddPrivateAuraAppliedSound", function(info)
            table.insert(
                calls,
                { action = "add", unit = info.unitToken, spellID = info.spellID, sound = info.soundFileName }
            )
            return #calls
        end)
        Replace(Blizz, "RemovePrivateAuraAppliedSound", function(soundID)
            table.insert(calls, { action = "remove", soundID = soundID })
        end)
        Replace(Blizz, "issecretvalue", function()
            return false
        end)
    end

    after_each(Restore)

    it("skips registration for disabled spells", function()
        Private.db.disabledPrivateAuras = { [1255612] = true }
        mockCombat(false)
        local calls = {}
        mockBlizzAPIs(calls)
        mockIterateGroupMembers({ "raid1" })
        mockNickname({ raid1 = "Waffle" })

        Private.RegisterPrivateAuraSounds()

        assert.are.equal(0, #countAddsForUnits(calls, { "raid1" }))
    end)

    it("skips registration while in combat", function()
        Private.db.disabledPrivateAuras = {}
        mockCombat(true)
        local calls = {}
        mockBlizzAPIs(calls)
        mockIterateGroupMembers({ "raid1" })
        mockNickname({ raid1 = "Waffle" })

        Private.RegisterPrivateAuraSounds()

        assert.are.equal(0, #countAddsForUnits(calls, { "raid1" }))
    end)

    it("uses the nickname-specific sound path for known nicknames", function()
        Private.db.disabledPrivateAuras = {}
        mockCombat(false)
        local calls = {}
        mockBlizzAPIs(calls)
        mockIterateGroupMembers({ "raid1" })
        mockNickname({ raid1 = "Waffle" })

        Private.RegisterPrivateAuraSounds()

        local addCalls = countAddsForUnits(calls, { "raid1" })
        assert.are.equal(1, #addCalls)
        assert.are.equal("raid1", addCalls[1].unit)
        assert.is_not_nil(addCalls[1].sound:find("DreadBreath\\Waffle"))
    end)

    it("falls back to the Unknown sound for un-rostered nicknames", function()
        Private.db.disabledPrivateAuras = {}
        mockCombat(false)
        local calls = {}
        mockBlizzAPIs(calls)
        mockIterateGroupMembers({ "raid1" })
        mockNickname({ raid1 = "SomeRandomPerson" })
        Replace(CoffeeRaidTools, "Print", function() end)

        Private.RegisterPrivateAuraSounds()

        local addCalls = countAddsForUnits(calls, { "raid1" })
        assert.are.equal(1, #addCalls)
        assert.is_not_nil(addCalls[1].sound:find("DreadBreath\\Unknown"))
    end)

    it("silently skips units whose nickname is a secret value", function()
        Private.db.disabledPrivateAuras = {}
        mockCombat(false)
        local calls = {}
        mockBlizzAPIs(calls)
        Replace(Blizz, "issecretvalue", function(value)
            return value == "SECRET"
        end)
        mockIterateGroupMembers({ "raid1" })
        mockNickname({ raid1 = "SECRET" })

        Private.RegisterPrivateAuraSounds()

        assert.are.equal(0, #countAddsForUnits(calls, { "raid1" }))
    end)

    it("registers sounds for every group member", function()
        Private.db.disabledPrivateAuras = {}
        mockCombat(false)
        local calls = {}
        mockBlizzAPIs(calls)
        mockIterateGroupMembers({ "raid1", "raid2", "raid3" })
        mockNickname({ raid1 = "Waffle", raid2 = "Gold", raid3 = "Hun" })

        Private.RegisterPrivateAuraSounds()

        local addCalls = countAddsForUnits(calls, { "raid1", "raid2", "raid3" })
        assert.are.equal(3, #addCalls)
        assert.are.equal("raid1", addCalls[1].unit)
        assert.are.equal("raid2", addCalls[2].unit)
        assert.are.equal("raid3", addCalls[3].unit)
    end)

    it("silently skips units with no nickname", function()
        Private.db.disabledPrivateAuras = {}
        mockCombat(false)
        local calls = {}
        mockBlizzAPIs(calls)
        mockIterateGroupMembers({ "raid1" })
        mockNickname({})

        Private.RegisterPrivateAuraSounds()

        assert.are.equal(0, #countAddsForUnits(calls, { "raid1" }))
    end)
end)

describe("RaidBuffCheck", function()
    after_each(Restore)

    local function MockSpells(map)
        Replace(C_Spell, "GetSpellInfo", function(spellID)
            local name = map[spellID]
            if not name then
                return nil
            end
            return { name = name, spellID = spellID }
        end)
    end

    local function MockGroup(units, unitFields)
        Replace(Private, "IterateGroupMembers", function()
            local i = 0
            return function()
                i = i + 1
                return units[i]
            end
        end)
        Replace("UnitIsVisible", function(unit)
            local f = unitFields[unit]
            return f and f.visible ~= false
        end)
        Replace("UnitExists", function(unit)
            return unitFields[unit] ~= nil
        end)
        Replace("UnitIsUnit", function(a, b)
            return a == b
        end)
        -- Chain to whatever UnitClass was set before MockGroup so tests that
        -- replaced it (e.g. to pin the player's class) still see their value
        -- for units that aren't in unitFields.
        local priorUnitClass = UnitClass
        Replace("UnitClass", function(unit)
            local f = unit and unitFields[unit]
            if f and f.classID then
                return "Stub", "STUB", f.classID
            end
            if priorUnitClass then
                return priorUnitClass(unit)
            end
            return "Stub", "STUB", 1
        end)
    end

    ---Build a GetAuraDataBySpellName mock from a {[unit] = {[spellName] = aura}} map.
    local function MockAuras(auraMap)
        Replace(C_UnitAuras, "GetAuraDataBySpellName", function(unit, name)
            local unitAuras = auraMap[unit]
            return unitAuras and unitAuras[name] or nil
        end)
    end

    describe("RebuffTextForClass", function()
        it("returns 'Rebuff <spell name>' for a known class", function()
            MockSpells({ [6673] = "Battle Shout" })
            assert.are.equal("Rebuff Battle Shout", Private.RaidBuffCheckRebuffTextForClass(1))
        end)

        it("uses the first spell ID in the list for Evoker", function()
            MockSpells({ [381741] = "Blessing of the Bronze" })
            assert.are.equal("Rebuff Blessing of the Bronze", Private.RaidBuffCheckRebuffTextForClass(13))
        end)

        it("returns nil for classes without a tracked raid buff", function()
            assert.is_nil(Private.RaidBuffCheckRebuffTextForClass(4)) -- Rogue
            assert.is_nil(Private.RaidBuffCheckRebuffTextForClass(9)) -- Warlock (Soulstone handled separately)
        end)

        it("returns nil when C_Spell.GetSpellInfo yields nothing", function()
            MockSpells({})
            assert.is_nil(Private.RaidBuffCheckRebuffTextForClass(1))
        end)
    end)

    describe("RaidBuffCheckClassIDForName", function()
        it("maps short class names to class IDs", function()
            assert.are.equal(1, Private.RaidBuffCheckClassIDForName("warrior"))
            assert.are.equal(5, Private.RaidBuffCheckClassIDForName("priest"))
            assert.are.equal(7, Private.RaidBuffCheckClassIDForName("shaman"))
            assert.are.equal(8, Private.RaidBuffCheckClassIDForName("mage"))
            assert.are.equal(11, Private.RaidBuffCheckClassIDForName("druid"))
            assert.are.equal(13, Private.RaidBuffCheckClassIDForName("evoker"))
        end)

        it("returns nil for unknown names", function()
            assert.is_nil(Private.RaidBuffCheckClassIDForName("rogue"))
            assert.is_nil(Private.RaidBuffCheckClassIDForName(""))
        end)
    end)

    describe("CheckRaidBuff", function()
        it("plays no sound when the player class has no tracked raid buff", function()
            Replace("UnitClass", function()
                return "Rogue", "ROGUE", 4
            end)
            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)
            assert.is_nil(Private:CheckRaidBuff())
            assert.is_nil(played)
        end)

        it("plays the rebuff sound when a raid member is missing the buff", function()
            Replace("UnitClass", function()
                return "Warrior", "WARRIOR", 1
            end)
            MockSpells({ [6673] = "Battle Shout" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = true },
            })
            MockAuras({
                raid1 = { ["Battle Shout"] = { sourceUnit = "player" } },
                -- raid2 has no buff
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Rebuff Battle Shout", Private:CheckRaidBuff())
            assert.are.equal("Rebuff Battle Shout", played)
        end)

        it("does not play when every visible member is buffed by the player", function()
            Replace("UnitClass", function()
                return "Warrior", "WARRIOR", 1
            end)
            MockSpells({ [6673] = "Battle Shout" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = true },
                player = { visible = true },
            })
            MockAuras({
                raid1 = { ["Battle Shout"] = { sourceUnit = "player" } },
                raid2 = { ["Battle Shout"] = { sourceUnit = "player" } },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_nil(Private:CheckRaidBuff())
            assert.is_nil(played)
        end)

        it("skips invisible (offline/phased) members", function()
            Replace("UnitClass", function()
                return "Warrior", "WARRIOR", 1
            end)
            MockSpells({ [6673] = "Battle Shout" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = false },
            })
            MockAuras({
                raid1 = { ["Battle Shout"] = { sourceUnit = "player" } },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_nil(Private:CheckRaidBuff())
            assert.is_nil(played)
        end)

        it("does not rebuff when the only unbuffed member is a caster (class not in Battle Shout list)", function()
            Replace("UnitClass", function()
                return "Warrior", "WARRIOR", 1
            end)
            MockSpells({ [6673] = "Battle Shout" })
            MockGroup({ "raid1" }, {
                raid1 = { visible = true, classID = 5 }, -- Priest: not in Battle Shout required list
            })
            MockAuras({})

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_nil(Private:CheckRaidBuff())
            assert.is_nil(played)
        end)

        it("does not rebuff Intellect when the only unbuffed member is a melee spec", function()
            Replace("UnitClass", function()
                return "Mage", "MAGE", 8
            end)
            MockSpells({ [1459] = "Arcane Intellect" })
            MockGroup({ "raid1" }, {
                raid1 = { visible = true, classID = 1 }, -- Warrior (not in Intellect list)
            })
            Replace(Private, "GetUnitSpec", function(_, unit)
                return unit == "raid1" and 73 or nil -- 73 = Prot Warrior, not in Intellect specs
            end)
            MockAuras({})

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_nil(Private:CheckRaidBuff())
            assert.is_nil(played)
        end)

        it("rebuffs Intellect when a peer-broadcast caster spec is missing the buff", function()
            Replace("UnitClass", function()
                return "Mage", "MAGE", 8
            end)
            MockSpells({ [1459] = "Arcane Intellect" })
            MockGroup({ "raid1" }, {
                raid1 = { visible = true, classID = 4 }, -- pretend "Rogue" class fallback
            })
            Replace(Private, "GetUnitSpec", function(_, unit)
                return unit == "raid1" and 64 or nil -- 64 = Frost Mage, in Intellect list
            end)
            MockAuras({})

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Rebuff Arcane Intellect", Private:CheckRaidBuff())
            assert.are.equal("Rebuff Arcane Intellect", played)
        end)

        it("rebuffs unconditionally for Priest class (PW:F)", function()
            Replace("UnitClass", function()
                return "Priest", "PRIEST", 5
            end)
            MockSpells({ [21562] = "Power Word: Fortitude" })
            MockGroup({ "raid1" }, {
                raid1 = { visible = true, classID = 4 }, -- Rogue, no spec data
            })
            MockAuras({})

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Rebuff Power Word: Fortitude", Private:CheckRaidBuff())
            assert.are.equal("Rebuff Power Word: Fortitude", played)
        end)

        it("finds the Evoker buff via any of its per-target spell IDs", function()
            Replace("UnitClass", function()
                return "Evoker", "EVOKER", 13
            end)
            MockSpells({
                [381741] = "Blessing of the Bronze A",
                [381757] = "Blessing of the Bronze B",
            })
            MockGroup({ "raid1" }, { raid1 = { visible = true } })
            MockAuras({
                raid1 = { ["Blessing of the Bronze B"] = { sourceUnit = "player" } },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Rebuff Blessing of the Bronze A", Private.RaidBuffCheckRebuffTextForClass(13))
            assert.is_nil(Private:CheckRaidBuff())
            assert.is_nil(played)
        end)
    end)

    describe("CheckSoulstone", function()
        local function AsWarlock()
            Replace("UnitClass", function()
                return "Warlock", "WARLOCK", 9
            end)
        end

        it("does nothing for non-warlocks", function()
            Replace("UnitClass", function()
                return "Mage", "MAGE", 8
            end)
            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)
            assert.is_nil(Private:CheckSoulstone())
            assert.is_nil(played)
        end)

        it("skips when soulstone is on long cooldown", function()
            AsWarlock()
            Replace(C_Spell, "GetSpellCooldown", function()
                return { duration = 600, startTime = GetTime() }
            end)
            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)
            assert.is_nil(Private:CheckSoulstone())
            assert.is_nil(played)
        end)

        it("plays when no healer has a fresh soulstone from the player", function()
            AsWarlock()
            MockSpells({ [20707] = "Soulstone" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = true },
            })
            Replace("UnitGroupRolesAssigned", function(unit)
                return unit == "raid1" and "HEALER" or "DAMAGER"
            end)
            MockAuras({})

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Soulstone", Private:CheckSoulstone())
            assert.are.equal("Soulstone", played)
        end)

        it("stays quiet when a healer has a fresh soulstone from the player", function()
            AsWarlock()
            MockSpells({ [20707] = "Soulstone" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = true },
            })
            Replace("UnitGroupRolesAssigned", function(unit)
                return unit == "raid1" and "HEALER" or "DAMAGER"
            end)
            MockAuras({
                raid1 = {
                    Soulstone = { sourceUnit = "player", expirationTime = GetTime() + 900 },
                },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_nil(Private:CheckSoulstone())
            assert.is_nil(played)
        end)

        it("plays when a healer's soulstone is from someone else", function()
            AsWarlock()
            MockSpells({ [20707] = "Soulstone" })
            MockGroup({ "raid1" }, { raid1 = { visible = true } })
            Replace("UnitGroupRolesAssigned", function()
                return "HEALER"
            end)
            MockAuras({
                raid1 = {
                    Soulstone = { sourceUnit = "raid9", expirationTime = GetTime() + 900 },
                },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Soulstone", Private:CheckSoulstone())
            assert.are.equal("Soulstone", played)
        end)

        it("plays when a healer's soulstone from the player is about to expire", function()
            AsWarlock()
            MockSpells({ [20707] = "Soulstone" })
            MockGroup({ "raid1" }, { raid1 = { visible = true } })
            Replace("UnitGroupRolesAssigned", function()
                return "HEALER"
            end)
            MockAuras({
                raid1 = {
                    Soulstone = { sourceUnit = "player", expirationTime = GetTime() + 60 },
                },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Soulstone", Private:CheckSoulstone())
            assert.are.equal("Soulstone", played)
        end)
    end)

    describe("CheckSourceOfMagic", function()
        local function AsEvokerWithSoM()
            Replace("UnitClass", function()
                return "Evoker", "EVOKER", 13
            end)
            Replace("C_SpellBook", {
                IsSpellKnownOrInSpellBook = function()
                    return true
                end,
            })
        end

        it("does nothing for non-evokers", function()
            Replace("UnitClass", function()
                return "Mage", "MAGE", 8
            end)
            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)
            assert.is_nil(Private:CheckSourceOfMagic())
            assert.is_nil(played)
        end)

        it("skips when Source of Magic isn't talented", function()
            Replace("UnitClass", function()
                return "Evoker", "EVOKER", 13
            end)
            Replace("C_SpellBook", {
                IsSpellKnownOrInSpellBook = function()
                    return false
                end,
            })
            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)
            assert.is_nil(Private:CheckSourceOfMagic())
            assert.is_nil(played)
        end)

        it("plays when no other healer has a fresh SoM from the player", function()
            AsEvokerWithSoM()
            MockSpells({ [369459] = "Source of Magic" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = true },
            })
            Replace("UnitGroupRolesAssigned", function()
                return "HEALER"
            end)
            MockAuras({})

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Source of Magic", Private:CheckSourceOfMagic())
            assert.are.equal("Source of Magic", played)
        end)

        it("stays quiet when another healer has a fresh SoM from the player", function()
            AsEvokerWithSoM()
            MockSpells({ [369459] = "Source of Magic" })
            MockGroup({ "raid1", "raid2" }, {
                raid1 = { visible = true },
                raid2 = { visible = true },
            })
            Replace("UnitGroupRolesAssigned", function()
                return "HEALER"
            end)
            MockAuras({
                raid1 = {
                    ["Source of Magic"] = { sourceUnit = "player", expirationTime = GetTime() + 3600 },
                },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_nil(Private:CheckSourceOfMagic())
            assert.is_nil(played)
        end)

        it("ignores SoM on the player themselves", function()
            AsEvokerWithSoM()
            MockSpells({ [369459] = "Source of Magic" })
            MockGroup({ "player" }, { player = { visible = true } })
            Replace("UnitGroupRolesAssigned", function()
                return "HEALER"
            end)
            MockAuras({
                player = {
                    ["Source of Magic"] = { sourceUnit = "player", expirationTime = GetTime() + 3600 },
                },
            })

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.are.equal("Source of Magic", Private:CheckSourceOfMagic())
            assert.are.equal("Source of Magic", played)
        end)
    end)

    describe("TestRaidBuffReminder", function()
        it("plays the rebuff sound without running the group check", function()
            MockSpells({ [21562] = "Power Word: Fortitude" })
            Replace(CoffeeRaidTools, "Print", function() end)

            local played
            Replace(Private, "PlayReminderSound", function(_, text)
                played = text
            end)

            assert.is_true(Private:TestRaidBuffReminder(5))
            assert.are.equal("Rebuff Power Word: Fortitude", played)
        end)

        it("returns false for an unknown class", function()
            Replace(CoffeeRaidTools, "Print", function() end)
            local called = false
            Replace(Private, "PlayReminderSound", function()
                called = true
            end)
            assert.is_false(Private:TestRaidBuffReminder(99))
            assert.is_false(called)
        end)
    end)
end)

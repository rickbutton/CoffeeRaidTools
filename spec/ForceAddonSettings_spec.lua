describe("ForceAddonSettings", function()
    after_each(Restore)

    it("is a no-op when NSRT is not present", function()
        Replace("NSRT", nil)
        Private.EnforceNSRT()
        assert.is_falsy(_G.NSRT)
    end)

    describe("pre-profile NSRT (no NSRT.Profiles)", function()
        it("sets every ready-check sub-setting", function()
            Replace("NSRT", {})
            Private.EnforceNSRT()
            assert.is_true(NSRT.ReadyCheckSettings.RepairCheck)
            assert.is_true(NSRT.ReadyCheckSettings.GemCheck)
            assert.is_true(NSRT.ReadyCheckSettings.EnchantCheck)
            assert.is_true(NSRT.ReadyCheckSettings.RaidBuffCheck)
            assert.is_true(NSRT.ReadyCheckSettings.CraftedCheck)
            assert.is_true(NSRT.ReadyCheckSettings.MissingItemCheck)
            assert.is_true(NSRT.ReadyCheckSettings.SoulstoneCheck)
            assert.is_true(NSRT.ReadyCheckSettings.ItemLevelCheck)
        end)

        it("enables each tracked encounter alert", function()
            Replace("NSRT", {})
            Private.EnforceNSRT()
            assert.is_true(NSRT.EncounterAlerts[3176].enabled)
            assert.is_true(NSRT.EncounterAlerts[3183].enabled)
            assert.is_true(NSRT.EncounterAlerts[3306].enabled)
        end)

        it("forces encounter alert sub-flags", function()
            Replace("NSRT", {})
            Private.EnforceNSRT()
            assert.is_true(NSRT.EncounterAlerts[3179].CCAddsDisplay)
            assert.is_true(NSRT.EncounterAlerts[3180].TauntAlerts)
            assert.is_true(NSRT.EncounterAlerts[3180].HealAbsorbTicks)
        end)

        it("forces the QoL defaults", function()
            Replace("NSRT", {})
            Private.EnforceNSRT()
            assert.is_true(NSRT.QoL.SoulwellDropped)
            assert.is_true(NSRT.QoL.AutoInvite)
            assert.is_true(NSRT.QoL.ResetBossDisplay)
            assert.is_true(NSRT.QoL.LootBossReminder)
        end)

        it("enables reminder settings", function()
            Replace("NSRT", {})
            Private.EnforceNSRT()
            assert.is_true(NSRT.ReminderSettings.enabled)
        end)

        it("forces UseTLReminders off", function()
            Replace("NSRT", { ReminderSettings = { UseTLReminders = true } })
            Replace("BNGetInfo", function()
                return nil, nil
            end)
            Private.EnforceNSRT()
            assert.is_false(NSRT.ReminderSettings.UseTLReminders)
        end)

        it("preserves unknown keys on nested tables", function()
            Replace("NSRT", { ReadyCheckSettings = { RepairCheck = true, CustomSetting = "keep" } })
            Private.EnforceNSRT()
            assert.are.equal("keep", NSRT.ReadyCheckSettings.CustomSetting)
            assert.is_true(NSRT.ReadyCheckSettings.RepairCheck)
        end)

        it("enables GlobalNickNames", function()
            Replace("NSRT", {})
            Replace("BNGetInfo", function()
                return nil, nil
            end)
            Private.EnforceNSRT()
            assert.is_true(NSRT.Settings["GlobalNickNames"])
        end)

        it("sets MyNickName from the battle tag", function()
            Replace("NSRT", {})
            Replace("BNGetInfo", function()
                return nil, "waffletwo#1858"
            end)
            Private.EnforceNSRT()
            assert.are.equal("Waffle", NSRT.Settings["MyNickName"])
        end)

        it("matches battle tags case-insensitively", function()
            Replace("NSRT", {})
            Replace("BNGetInfo", function()
                return nil, "WaffleTwo#1858"
            end)
            Private.EnforceNSRT()
            assert.are.equal("Waffle", NSRT.Settings["MyNickName"])
        end)

        it("leaves MyNickName alone for unknown battle tags", function()
            Replace("NSRT", { Settings = { MyNickName = "Original" } })
            Replace("BNGetInfo", function()
                return nil, "unknown#0000"
            end)
            Private.EnforceNSRT()
            assert.are.equal("Original", NSRT.Settings["MyNickName"])
        end)

        it("enables SpellTTS", function()
            Replace("NSRT", {})
            Replace("BNGetInfo", function()
                return nil, nil
            end)
            Private.EnforceNSRT()
            assert.is_true(NSRT.ReminderSettings.SpellTTS)
        end)

        it("enables TextTTS", function()
            Replace("NSRT", {})
            Replace("BNGetInfo", function()
                return nil, nil
            end)
            Private.EnforceNSRT()
            assert.is_true(NSRT.ReminderSettings.TextTTS)
        end)

        it("does not create a Profiles table on pre-profile NSRT", function()
            Replace("NSRT", {})
            Private.EnforceNSRT()
            assert.is_nil(NSRT.Profiles)
            assert.is_nil(NSRT.CurrentProfile)
            assert.is_nil(NSRT.MainProfile)
            assert.is_nil(NSRT.ProfileKeys)
        end)
    end)

    describe("post-profile NSRT (first install)", function()
        it("creates the Coffee profile seeded from the active profile", function()
            Replace("NSRT", {
                Profiles = {
                    default = {
                        NickNames = { ["Tester-TestRealm"] = "Test" },
                        Reminders = { ["Boss1"] = "line one" },
                        AssignmentSettings = { foo = "bar" },
                    },
                },
                ProfileKeys = {},
                CurrentProfile = "default",
                MainProfile = "default",
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            local coffee = NSRT.Profiles.Coffee
            assert.is_not_nil(coffee)
            assert.are.equal("Test", coffee.NickNames["Tester-TestRealm"])
            assert.are.equal("line one", coffee.Reminders["Boss1"])
            assert.are.equal("bar", coffee.AssignmentSettings.foo)
        end)

        it("enforces ready-check/QoL/reminder settings on the Coffee profile", function()
            Replace("NSRT", {
                Profiles = { default = {} },
                ProfileKeys = {},
                CurrentProfile = "default",
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            local coffee = NSRT.Profiles.Coffee
            assert.is_true(coffee.ReadyCheckSettings.RepairCheck)
            assert.is_true(coffee.EncounterAlerts[3176].enabled)
            assert.is_true(coffee.QoL.AutoInvite)
            assert.is_true(coffee.ReminderSettings.enabled)
            assert.is_true(coffee.ReminderSettings.SpellTTS)
            assert.is_false(coffee.ReminderSettings.UseTLReminders)
            assert.is_true(coffee.Settings.GlobalNickNames)
        end)

        it("switches the player onto the Coffee profile", function()
            Replace("NSRT", {
                Profiles = { default = {} },
                ProfileKeys = {},
                CurrentProfile = "default",
                MainProfile = "default",
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            assert.are.equal("Coffee", NSRT.CurrentProfile)
            assert.are.equal("Coffee", NSRT.MainProfile)
            assert.are.equal("Coffee", NSRT.ProfileKeys["Tester-TestRealm"])
        end)

        it("copies Coffee profile settings into live NSRT state", function()
            Replace("NSRT", {
                Profiles = { default = {} },
                ProfileKeys = {},
                CurrentProfile = "default",
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            assert.is_true(NSRT.ReadyCheckSettings.RepairCheck)
            assert.is_true(NSRT.EncounterAlerts[3306].enabled)
            assert.is_true(NSRT.QoL.LootBossReminder)
            assert.is_true(NSRT.ReminderSettings.enabled)
            assert.is_true(NSRT.Settings.GlobalNickNames)
        end)

        it("preserves existing seed data on the live NSRT tables", function()
            Replace("NSRT", {
                Profiles = {
                    default = {
                        Reminders = { Boss1 = "hello" },
                    },
                },
                ProfileKeys = {},
                CurrentProfile = "default",
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            assert.are.equal("hello", NSRT.Reminders.Boss1)
        end)

        it("sets MyNickName from the battle tag on the Coffee profile", function()
            Replace("NSRT", {
                Profiles = { default = {} },
                ProfileKeys = {},
                CurrentProfile = "default",
            })
            Replace("BNGetInfo", function()
                return nil, "waffletwo#1858"
            end)

            Private.EnforceNSRT()

            assert.are.equal("Waffle", NSRT.Profiles.Coffee.Settings.MyNickName)
            assert.are.equal("Waffle", NSRT.Settings.MyNickName)
        end)

        it("tolerates missing Profiles[CurrentProfile]", function()
            Replace("NSRT", {
                Profiles = {},
                ProfileKeys = {},
                CurrentProfile = nil,
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            assert.is_not_nil(NSRT.Profiles.Coffee)
            assert.is_true(NSRT.Profiles.Coffee.ReadyCheckSettings.RepairCheck)
            assert.are.equal("Coffee", NSRT.CurrentProfile)
        end)
    end)

    describe("post-profile NSRT (Coffee profile exists)", function()
        it("refreshes Coffee profile enforcement on subsequent loads", function()
            Replace("NSRT", {
                Profiles = {
                    Coffee = {
                        ReadyCheckSettings = { RepairCheck = false, CustomStuff = "keep" },
                    },
                },
                ProfileKeys = { ["Tester-TestRealm"] = "Coffee" },
                CurrentProfile = "Coffee",
                MainProfile = "Coffee",
                ReadyCheckSettings = { RepairCheck = false },
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            assert.is_true(NSRT.Profiles.Coffee.ReadyCheckSettings.RepairCheck)
            assert.are.equal("keep", NSRT.Profiles.Coffee.ReadyCheckSettings.CustomStuff)
            assert.is_true(NSRT.ReadyCheckSettings.RepairCheck)
        end)

        it("leaves the user alone when switched to a non-Coffee profile", function()
            Replace("NSRT", {
                Profiles = {
                    Coffee = { ReadyCheckSettings = { RepairCheck = true } },
                    other = { ReadyCheckSettings = { RepairCheck = false } },
                },
                ProfileKeys = { ["Tester-TestRealm"] = "other" },
                CurrentProfile = "other",
                MainProfile = "Coffee",
                ReadyCheckSettings = { RepairCheck = false },
            })
            Replace("BNGetInfo", function()
                return nil, nil
            end)

            Private.EnforceNSRT()

            assert.are.equal("other", NSRT.CurrentProfile)
            assert.is_false(NSRT.ReadyCheckSettings.RepairCheck)
            assert.is_true(NSRT.Profiles.Coffee.ReadyCheckSettings.RepairCheck)
        end)
    end)

    describe("pre-profile -> profile NSRT upgrade", function()
        -- Minimal mirror of the vendor NSRT LoadMyProfile / CreateProfile flow
        -- needed to exercise the ADDON_LOADED -> NSRT init -> re-enforce path.
        local NSI_ignored = {
            Profiles = true,
            ProfileKeys = true,
            CurrentProfile = true,
            MainProfile = true,
        }

        local function NSI_SaveProfile()
            if NSRT.CurrentProfile then
                NSRT.Profiles[NSRT.CurrentProfile] = {}
                for k, v in pairs(NSRT) do
                    if not NSI_ignored[k] then
                        NSRT.Profiles[NSRT.CurrentProfile][k] = type(v) == "table" and CopyTable(v) or v
                    end
                end
            end
        end

        local function NSI_AddMissingDefaults()
            if NSRT.Profiles == nil then
                NSRT.Profiles = {}
            end
            if NSRT.ProfileKeys == nil then
                NSRT.ProfileKeys = {}
            end
            if NSRT.CurrentProfile == nil then
                NSRT.CurrentProfile = "default"
            end
            if NSRT.MainProfile == nil then
                NSRT.MainProfile = "default"
            end
        end

        local function NSI_LoadMyProfile()
            NSI_AddMissingDefaults()
            local ProfileToLoad = "default"
            local key = "Tester-TestRealm"
            if NSRT.ProfileKeys[key] then
                ProfileToLoad = NSRT.ProfileKeys[key]
            elseif NSRT.MainProfile then
                ProfileToLoad = NSRT.MainProfile
            end
            if NSRT.Profiles[ProfileToLoad] then
                for k, v in pairs(NSRT.Profiles[ProfileToLoad]) do
                    if not NSI_ignored[k] then
                        NSRT[k] = type(v) == "table" and CopyTable(v) or v
                    end
                end
                NSRT.ProfileKeys[key] = ProfileToLoad
                NSRT.CurrentProfile = ProfileToLoad
            else
                NSRT.Profiles[ProfileToLoad] = {}
                NSI_SaveProfile()
                NSRT.ProfileKeys[key] = ProfileToLoad
                NSRT.CurrentProfile = ProfileToLoad
                NSI_SaveProfile()
            end
        end

        it("migrates the player onto Coffee when NSRT.Profiles is populated after ADDON_LOADED", function()
            Replace(C_AddOns, "IsAddOnLoaded", function()
                return true
            end)
            Replace("BNGetInfo", function()
                return nil, nil
            end)
            -- Saved NSRT predates the Profiles feature.
            Replace("NSRT", {
                ReadyCheckSettings = { RaidBuffCheck = false },
                NickNames = { ["Someone-Realm"] = "Some" },
            })

            -- Simulate CRT's ADDON_LOADED handler running first (takes
            -- pre-profile path because NSRT.Profiles isn't set yet).
            Private.EnforceNSRT()
            assert.is_nil(NSRT.Profiles)

            -- Simulate NSRT's ADDON_LOADED/PLAYER_LOGIN handler initializing
            -- its profile system, which leaves the player on "default".
            NSI_LoadMyProfile()
            assert.are.equal("default", NSRT.CurrentProfile)

            -- The deferred PLAYER_LOGIN re-enforcement should now pick up that
            -- NSRT has Profiles and migrate the player to Coffee.
            Private.EnforceNSRT()

            assert.are.equal("Coffee", NSRT.CurrentProfile)
            assert.is_not_nil(NSRT.Profiles.Coffee)
            assert.are.equal("Coffee", Private.GetNSRTProfileName())
        end)
    end)

    describe("GetNSRTPlayerProfileKey", function()
        it("combines the character name and realm", function()
            Replace("UnitFullName", function()
                return "Tester", "TestRealm"
            end)
            assert.are.equal("Tester-TestRealm", Private.GetNSRTPlayerProfileKey())
        end)

        it("falls back to GetNormalizedRealmName when realm is missing", function()
            Replace("UnitFullName", function()
                return "Tester", nil
            end)
            Replace("GetNormalizedRealmName", function()
                return "FallbackRealm"
            end)
            assert.are.equal("Tester-FallbackRealm", Private.GetNSRTPlayerProfileKey())
        end)

        it("returns nil when the player name is unavailable", function()
            Replace("UnitFullName", function()
                return nil, nil
            end)
            Replace("GetNormalizedRealmName", function()
                return "FallbackRealm"
            end)
            assert.is_nil(Private.GetNSRTPlayerProfileKey())
        end)
    end)

    describe("CopyNSRTProfileIntoActive", function()
        it("copies non-ignored keys from the named profile into flat NSRT", function()
            Replace("NSRT", {
                Profiles = {
                    Coffee = {
                        ReadyCheckSettings = { RepairCheck = true },
                        Reminders = { Boss = "text" },
                    },
                },
                ProfileKeys = {},
                CurrentProfile = "Coffee",
                MainProfile = "Coffee",
            })

            Private.CopyNSRTProfileIntoActive("Coffee")

            assert.is_true(NSRT.ReadyCheckSettings.RepairCheck)
            assert.are.equal("text", NSRT.Reminders.Boss)
        end)

        it("does not copy the profile-management keys", function()
            Replace("NSRT", {
                Profiles = {
                    Coffee = {
                        Profiles = { nested = "bad" },
                        ProfileKeys = { bad = "bad" },
                        CurrentProfile = "bad",
                        MainProfile = "bad",
                        Settings = { MyNickName = "Good" },
                    },
                },
                ProfileKeys = { ["Tester-TestRealm"] = "Coffee" },
                CurrentProfile = "Coffee",
                MainProfile = "Coffee",
            })

            Private.CopyNSRTProfileIntoActive("Coffee")

            assert.are.equal("Coffee", NSRT.CurrentProfile)
            assert.are.equal("Coffee", NSRT.MainProfile)
            assert.are.equal("Coffee", NSRT.ProfileKeys["Tester-TestRealm"])
            assert.is_nil(NSRT.Profiles.nested)
            assert.are.equal("Good", NSRT.Settings.MyNickName)
        end)

        it("deep-copies nested tables", function()
            local source = { RepairCheck = true, nested = { value = 1 } }
            Replace("NSRT", {
                Profiles = { Coffee = { ReadyCheckSettings = source } },
                CurrentProfile = "Coffee",
            })

            Private.CopyNSRTProfileIntoActive("Coffee")

            assert.are_not.equal(source, NSRT.ReadyCheckSettings)
            assert.are_not.equal(source.nested, NSRT.ReadyCheckSettings.nested)
            assert.is_true(NSRT.ReadyCheckSettings.RepairCheck)
            assert.are.equal(1, NSRT.ReadyCheckSettings.nested.value)
        end)
    end)
end)

describe("AlertOverrides", function()
    after_each(Restore)

    local function setup(encounterAlerts, overrides)
        Replace("NSRT", { EncounterAlerts = encounterAlerts })
        Replace(Private, "AlertOverrides", overrides)
    end

    it("is a no-op when NSRT is absent", function()
        Replace("NSRT", nil)
        Replace(Private, "AlertOverrides", {
            [3180] = { { diff = "all", internalID = "X", fields = { enabled = false } } },
        })
        assert.has_no.errors(function()
            Private.ApplyAlertOverrides()
        end)
    end)

    it("is a no-op when EncounterAlerts is absent", function()
        Replace("NSRT", {})
        Replace(Private, "AlertOverrides", {
            [3180] = { { diff = 16, internalID = "X", fields = { enabled = false } } },
        })
        assert.has_no.errors(function()
            Private.ApplyAlertOverrides()
        end)
    end)

    it("applies a forced field to the matching alert", function()
        setup({
            [3180] = {
                [16] = {
                    ["Sacred Toll"] = { enabled = true, name = "Sacred Toll" },
                },
            },
        }, {
            [3180] = {
                { diff = 16, internalID = "Sacred Toll", fields = { enabled = false } },
            },
        })

        Private.ApplyAlertOverrides()

        assert.is_false(NSRT.EncounterAlerts[3180][16]["Sacred Toll"].enabled)
        assert.are.equal("Sacred Toll", NSRT.EncounterAlerts[3180][16]["Sacred Toll"].name)
    end)

    it("applies multiple fields per override", function()
        setup({
            [3180] = { [16] = { ["A"] = { enabled = true, sound = "old", dur = 5 } } },
        }, {
            [3180] = {
                { diff = 16, internalID = "A", fields = { enabled = false, sound = "new", dur = 10 } },
            },
        })

        Private.ApplyAlertOverrides()

        local alert = NSRT.EncounterAlerts[3180][16]["A"]
        assert.is_false(alert.enabled)
        assert.are.equal("new", alert.sound)
        assert.are.equal(10, alert.dur)
    end)

    describe("diff resolution", function()
        local function tripleDiff(internalID, fields)
            return {
                [14] = { [internalID] = { enabled = true } },
                [15] = { [internalID] = { enabled = true } },
                [16] = { [internalID] = { enabled = true } },
            }
        end

        it("'all' applies to {14, 15, 16}", function()
            setup({ [3180] = tripleDiff("A") }, {
                [3180] = { { diff = "all", internalID = "A", fields = { enabled = false } } },
            })

            Private.ApplyAlertOverrides()

            assert.is_false(NSRT.EncounterAlerts[3180][14]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][15]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][16]["A"].enabled)
        end)

        it("nil diff defaults to all difficulties", function()
            setup({ [3180] = tripleDiff("A") }, {
                [3180] = { { internalID = "A", fields = { enabled = false } } },
            })

            Private.ApplyAlertOverrides()

            assert.is_false(NSRT.EncounterAlerts[3180][14]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][15]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][16]["A"].enabled)
        end)

        it("a list applies only to listed difficulties", function()
            setup({ [3180] = tripleDiff("A") }, {
                [3180] = { { diff = { 15, 16 }, internalID = "A", fields = { enabled = false } } },
            })

            Private.ApplyAlertOverrides()

            assert.is_true(NSRT.EncounterAlerts[3180][14]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][15]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][16]["A"].enabled)
        end)

        it("a single integer applies only to that diff", function()
            setup({ [3180] = tripleDiff("A") }, {
                [3180] = { { diff = 16, internalID = "A", fields = { enabled = false } } },
            })

            Private.ApplyAlertOverrides()

            assert.is_true(NSRT.EncounterAlerts[3180][14]["A"].enabled)
            assert.is_true(NSRT.EncounterAlerts[3180][15]["A"].enabled)
            assert.is_false(NSRT.EncounterAlerts[3180][16]["A"].enabled)
        end)
    end)

    it("skips missing alerts without raising", function()
        setup({
            [3180] = { [16] = { ["Present"] = { enabled = true } } },
        }, {
            [3180] = {
                { diff = 16, internalID = "Missing", fields = { enabled = false } },
                { diff = 16, internalID = "Present", fields = { enabled = false } },
            },
        })

        assert.has_no.errors(function()
            Private.ApplyAlertOverrides()
        end)
        assert.is_false(NSRT.EncounterAlerts[3180][16]["Present"].enabled)
    end)

    it("skips missing encounter tables without raising", function()
        setup({
            [3180] = { [16] = { ["A"] = { enabled = true } } },
        }, {
            [9999] = { { diff = 16, internalID = "X", fields = { enabled = false } } },
            [3180] = { { diff = 16, internalID = "A", fields = { enabled = false } } },
        })

        assert.has_no.errors(function()
            Private.ApplyAlertOverrides()
        end)
        assert.is_false(NSRT.EncounterAlerts[3180][16]["A"].enabled)
    end)

    it("deep-copies table-valued field overrides", function()
        local source = { 1, 2, 3 }
        setup({
            [3180] = { [16] = { ["A"] = { timers = nil } } },
        }, {
            [3180] = { { diff = 16, internalID = "A", fields = { timers = source } } },
        })

        Private.ApplyAlertOverrides()

        local applied = NSRT.EncounterAlerts[3180][16]["A"].timers
        assert.are_not.equal(source, applied)
        assert.are.same({ 1, 2, 3 }, applied)
        source[1] = 999
        assert.are.equal(1, applied[1])
    end)

    it("only re-applies overrides for the targeted encID when one is passed", function()
        setup({
            [3180] = { [16] = { ["A"] = { enabled = true } } },
            [3183] = { [16] = { ["B"] = { enabled = true } } },
        }, {
            [3180] = { { diff = 16, internalID = "A", fields = { enabled = false } } },
            [3183] = { { diff = 16, internalID = "B", fields = { enabled = false } } },
        })

        Private.ApplyAlertOverrides(3180)

        assert.is_false(NSRT.EncounterAlerts[3180][16]["A"].enabled)
        assert.is_true(NSRT.EncounterAlerts[3183][16]["B"].enabled)
    end)
end)

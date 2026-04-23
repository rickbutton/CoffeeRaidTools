describe("RaidStatus", function()
    local baseExpected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        RCLC = "1.0",
        NSRTHASH = "def",
    }

    describe("GeneratePlayerStatus", function()
        it("reports good when every shortcode matches", function()
            local player = {
                CRT = "1.0",
                BW = "2.0",
                NSRT = "1.0",
                RCLC = "1.0",
                NSRTHASH = "def",
            }
            local status = Private.GeneratePlayerStatus(player, baseExpected)
            assert.is_true(status.good)
            assert.is_false(status.noResponse)
            assert.are.equal(0, #status.failures)
        end)

        it("marks nil player versions as no-response", function()
            local status = Private.GeneratePlayerStatus(nil, { CRT = "1.0" })
            assert.is_false(status.good)
            assert.is_true(status.noResponse)
        end)

        it("flags an EXISTS-matched addon that is missing", function()
            local player = {
                CRT = "1.0",
                BW = "NONE",
                NSRT = "1.0",
                RCLC = "1.0",
                NSRTHASH = "def",
            }
            local status = Private.GeneratePlayerStatus(player, baseExpected)
            assert.is_false(status.good)
            assert.are.equal(1, #status.failures)
            assert.are.equal("BW", status.failures[1])
        end)

        it("flags an EQUAL-matched addon with a mismatched version", function()
            local player = {
                CRT = "0.9",
                BW = "2.0",
                NSRT = "1.0",
                RCLC = "1.0",
                NSRTHASH = "def",
            }
            local status = Private.GeneratePlayerStatus(player, baseExpected)
            assert.is_false(status.good)
            assert.are.equal("CRT=0.9", status.failures[1])
        end)

        it("flags an EQUAL-matched addon that is missing", function()
            local player = {
                CRT = "NONE",
                BW = "2.0",
                NSRT = "1.0",
                RCLC = "1.0",
                NSRTHASH = "def",
            }
            local status = Private.GeneratePlayerStatus(player, baseExpected)
            assert.is_false(status.good)
            assert.are.equal("CRT", status.failures[1])
        end)

        it("flags a mismatched NSRT note hash", function()
            local player = {
                CRT = "1.0",
                BW = "2.0",
                NSRT = "1.0",
                RCLC = "1.0",
                NSRTHASH = "different",
            }
            local status = Private.GeneratePlayerStatus(player, baseExpected)
            assert.is_false(status.good)
            assert.are.equal("NSRTNOTE", status.failures[1])
        end)
    end)

    describe("FormatStatusText", function()
        it("renders GOOD in green for healthy players", function()
            assert.are.equal(
                "|cff00ff00GOOD|r",
                Private.FormatStatusText({ good = true, failures = {}, noResponse = false })
            )
        end)

        it("renders NO RESPONSE in red when the player has not replied", function()
            assert.are.equal(
                "|cffff0000NO RESPONSE|r",
                Private.FormatStatusText({ good = false, failures = {}, noResponse = true })
            )
        end)

        it("joins failures with a space", function()
            assert.are.equal(
                "|cffff0000BW CRT=0.9|r",
                Private.FormatStatusText({
                    good = false,
                    failures = { "BW", "CRT=0.9" },
                    noResponse = false,
                })
            )
        end)
    end)

    describe("GenerateTooltipText", function()
        it("lists every shortcode when versions are populated", function()
            local player = {
                CRT = "1.0",
                BW = "2.0",
                NSRT = "3.0",
                RCLC = "5.0",
                NSRTHASH = "def",
            }
            local result = Private.GenerateTooltipText(player)
            assert.is_not_nil(result:find("CRT=1.0"))
            assert.is_not_nil(result:find("BW=2.0"))
            assert.is_not_nil(result:find("NSRTHASH=def"))
        end)

        it("returns NO RESPONSE when player versions are nil", function()
            assert.are.equal("NO RESPONSE", Private.GenerateTooltipText(nil))
        end)

        it("shows NONE for missing shortcodes", function()
            local result = Private.GenerateTooltipText({ CRT = "1.0" })
            assert.is_not_nil(result:find("BW=NONE"))
        end)
    end)
end)

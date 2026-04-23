describe("ReminderSounds", function()
    after_each(Restore)

    describe("HasReminderSound", function()
        it("returns true for a text string present in the generated data", function()
            assert.is_true(Private:HasReminderSound("Rebuff Battle Shout"))
        end)

        it("returns false for unknown text", function()
            assert.is_false(Private:HasReminderSound("not-a-real-reminder"))
        end)
    end)

    describe("PlayReminderSound", function()
        it("calls PlaySoundFile with the registered path for known text", function()
            local played
            Replace("PlaySoundFile", function(path, channel)
                played = { path = path, channel = channel }
            end)

            local result = Private:PlayReminderSound("Rebuff Battle Shout")

            assert.are.equal("sound", result)
            assert.is_not_nil(played)
            assert.is_truthy(played.path:find("RebuffBattleShout"))
            assert.are.equal("Master", played.channel)
        end)

        it("falls back to NSAPI:TTS when the text is not in our data", function()
            local spoken
            Replace("NSAPI", {
                TTS = function(_, text)
                    spoken = text
                end,
            })
            Replace("PlaySoundFile", function()
                error("should not call PlaySoundFile when falling back")
            end)

            local result = Private:PlayReminderSound("Something we do not have")

            assert.are.equal("tts", result)
            assert.are.equal("Something we do not have", spoken)
        end)

        it("returns nil when there is no sound and no NSAPI", function()
            Replace("NSAPI", nil)
            Replace("PlaySoundFile", function()
                error("should not call PlaySoundFile")
            end)

            assert.is_nil(Private:PlayReminderSound("Something we do not have"))
        end)

        it("prefers the registered sound over NSAPI:TTS when both are available", function()
            local spoken = false
            Replace("NSAPI", {
                TTS = function()
                    spoken = true
                end,
            })
            local played = false
            Replace("PlaySoundFile", function()
                played = true
            end)

            Private:PlayReminderSound("Rebuff Battle Shout")

            assert.is_true(played)
            assert.is_false(spoken)
        end)
    end)
end)

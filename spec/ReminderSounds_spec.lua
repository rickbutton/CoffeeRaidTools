describe("ReminderSounds", function()
    before_each(function()
        Private.db.disabledReminderSounds = {}
    end)
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
                return true
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
                return true
            end)

            Private:PlayReminderSound("Rebuff Battle Shout")

            assert.is_true(played)
            assert.is_false(spoken)
        end)

        it("falls back to NSAPI:TTS when the sound is disabled", function()
            Private.db.disabledReminderSounds["Rebuff Battle Shout"] = true
            local spoken
            Replace("NSAPI", {
                TTS = function(_, text)
                    spoken = text
                end,
            })
            Replace("PlaySoundFile", function()
                error("should not call PlaySoundFile when the sound is disabled")
            end)

            local result = Private:PlayReminderSound("Rebuff Battle Shout")

            assert.are.equal("tts", result)
            assert.are.equal("Rebuff Battle Shout", spoken)
        end)

        it("falls back to NSAPI:TTS when PlaySoundFile reports it will not play", function()
            local spoken
            Replace("NSAPI", {
                TTS = function(_, text)
                    spoken = text
                end,
            })
            Replace("PlaySoundFile", function()
                return false
            end)

            local result = Private:PlayReminderSound("Rebuff Battle Shout")

            assert.are.equal("tts", result)
            assert.are.equal("Rebuff Battle Shout", spoken)
        end)
    end)

    describe("InstallNSAPITTSHook", function()
        -- The hook captures the original at install time in a module upvalue
        -- and no-ops on subsequent calls, so we install once and exercise
        -- every branch in a single test against a spy original.
        it("intercepts owned+enabled, forwards otherwise, and respects NSRT TTS off", function()
            local originalArgs
            local originalNSAPI = {
                TTS = function(self, sound, ...)
                    originalArgs = { self = self, sound = sound, n = select("#", ...) }
                end,
            }
            if not NSAPI then
                _G.NSAPI = originalNSAPI
            else
                Replace(NSAPI, "TTS", originalNSAPI.TTS)
            end
            Private:InstallNSAPITTSHook()

            local playedPath
            Replace("PlaySoundFile", function(path)
                playedPath = path
                return true
            end)

            -- Owned + enabled + TTS on: plays our sound.
            originalArgs, playedPath = nil, nil
            NSAPI:TTS("Rebuff Battle Shout")
            assert.is_nil(originalArgs)
            assert.is_truthy(playedPath and playedPath:find("RebuffBattleShout"))

            -- Owned + disabled: forwards.
            Private.db.disabledReminderSounds["Rebuff Battle Shout"] = true
            originalArgs, playedPath = nil, nil
            NSAPI:TTS("Rebuff Battle Shout")
            assert.is_nil(playedPath)
            assert.is_not_nil(originalArgs)
            assert.are.equal("Rebuff Battle Shout", originalArgs.sound)

            -- Unowned string: forwards.
            originalArgs, playedPath = nil, nil
            NSAPI:TTS("Unowned reminder text")
            assert.is_nil(playedPath)
            assert.are.equal("Unowned reminder text", originalArgs.sound)

            -- Non-string: forwards untouched.
            originalArgs, playedPath = nil, nil
            NSAPI:TTS(42)
            assert.is_nil(playedPath)
            assert.are.equal(42, originalArgs.sound)

            -- NSRT.Settings.TTS == false: forwards even for owned+enabled.
            Private.db.disabledReminderSounds["Rebuff Battle Shout"] = nil
            local savedNSRT = _G.NSRT
            _G.NSRT = { Settings = { TTS = false } }
            originalArgs, playedPath = nil, nil
            NSAPI:TTS("Rebuff Battle Shout")
            _G.NSRT = savedNSRT
            assert.is_nil(playedPath)
            assert.are.equal("Rebuff Battle Shout", originalArgs.sound)
        end)
    end)
end)

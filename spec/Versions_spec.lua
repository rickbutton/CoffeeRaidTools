describe("Versions", function()
    after_each(Restore)

    describe("StringHash", function()
        it("is deterministic", function()
            assert.are.equal(Private.StringHash("hello world"), Private.StringHash("hello world"))
        end)

        it("returns different values for different inputs", function()
            assert.are_not.equal(Private.StringHash("hello"), Private.StringHash("world"))
        end)

        it("handles the empty string", function()
            local hash = Private.StringHash("")
            assert.is_not_nil(hash)
            assert.are.equal("string", type(hash))
        end)

        it("returns a string", function()
            assert.are.equal("string", type(Private.StringHash("test input")))
        end)
    end)

    describe("GetAddonVersion", function()
        it("returns the version metadata when the addon is loaded", function()
            Replace(Blizz, "IsAddOnLoaded", function(name)
                return name == "TestAddon"
            end)
            Replace(Blizz, "GetAddOnMetadata", function(name, key)
                if name == "TestAddon" and key == "Version" then
                    return "1.2.3"
                end
            end)
            assert.are.equal("1.2.3", Private.GetAddonVersion("TestAddon"))
        end)

        it("returns NONE when the addon is not loaded", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return false
            end)
            assert.are.equal("NONE", Private.GetAddonVersion("FakeAddon"))
        end)

        it("returns NONE when metadata is missing", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return true
            end)
            Replace(Blizz, "GetAddOnMetadata", function()
                return nil
            end)
            assert.are.equal("NONE", Private.GetAddonVersion("TestAddon"))
        end)
    end)

    describe("GetNSRTNoteHash", function()
        it("returns NONE when NSRT is not loaded", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return false
            end)
            assert.are.equal("NONE", Private.GetNSRTNoteHash())
        end)

        it("returns NONE when NSAPI is not present", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return true
            end)
            Replace("NSAPI", nil)
            assert.are.equal("NONE", Private.GetNSRTNoteHash())
        end)

        it("hashes the shared reminder note", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return true
            end)
            Replace("NSAPI", {
                GetReminderString = function()
                    return "personal note", "shared note"
                end,
            })
            local hash = Private.GetNSRTNoteHash()
            assert.are_not.equal("NONE", hash)
            assert.are.equal(Private.StringHash("shared note"), hash)
        end)

        it("returns NONE for an empty reminder", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return true
            end)
            Replace("NSAPI", {
                GetReminderString = function()
                    return "", ""
                end,
            })
            assert.are.equal("NONE", Private.GetNSRTNoteHash())
        end)
    end)

    describe("CollectLocalVersionTable", function()
        it("includes every tracked shortcode and NSRTHASH", function()
            Replace(Blizz, "IsAddOnLoaded", function()
                return true
            end)
            Replace(Blizz, "GetAddOnMetadata", function()
                return "1.0.0"
            end)
            local versions = Private.CollectLocalVersionTable()

            for _, addon in ipairs(Private.AddonsToTrack) do
                assert.is_not_nil(versions[addon.shortcode])
            end
            assert.is_not_nil(versions["NSRTHASH"])
        end)
    end)

    describe("ParseGuildInfoVersions", function()
        it("parses a single shortcode", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "Welcome to the guild!\n<CRT:42>"
            end)
            local versions = Private.ParseGuildInfoVersions()
            assert.is_not_nil(versions)
            assert.are.equal("42", versions.CRT)
        end)

        it("parses multiple shortcodes", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "<CRT:42 NSRT:1.2.3>"
            end)
            local versions = Private.ParseGuildInfoVersions()
            assert.is_not_nil(versions)
            assert.are.equal("42", versions.CRT)
            assert.are.equal("1.2.3", versions.NSRT)
        end)

        it("returns nil when no version tag is present", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "Welcome to the guild!"
            end)
            assert.is_nil(Private.ParseGuildInfoVersions())
        end)

        it("returns nil when guild info text is nil", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return nil
            end)
            assert.is_nil(Private.ParseGuildInfoVersions())
        end)

        it("returns nil for an empty tag", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "<>"
            end)
            assert.is_nil(Private.ParseGuildInfoVersions())
        end)

        it("returns nil for a partial tag", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "<CRT:>"
            end)
            assert.is_nil(Private.ParseGuildInfoVersions())
        end)
    end)

    describe("CheckGuildVersions", function()
        it("returns the outdated addon when the guild version is higher", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "<CRT:99>"
            end)
            Replace(Private, "GetAddonVersion", function(name)
                if name == "CoffeeRaidTools" then
                    return "42"
                end
            end)
            local outdated = Private.CheckGuildVersions()
            assert.is_not_nil(outdated)
            assert.are.equal(1, #outdated)
            assert.are.equal("CoffeeRaidTools", outdated[1])
        end)

        it("returns an empty list when versions match", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "<CRT:42>"
            end)
            Replace(Private, "GetAddonVersion", function(name)
                if name == "CoffeeRaidTools" then
                    return "42"
                end
            end)
            local outdated = Private.CheckGuildVersions()
            assert.is_not_nil(outdated)
            assert.are.equal(0, #outdated)
        end)

        it("returns nil when no tag is present", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "No version here"
            end)
            assert.is_nil(Private.CheckGuildVersions())
        end)

        it("returns nil when guild info is nil", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return nil
            end)
            assert.is_nil(Private.CheckGuildVersions())
        end)

        it("skips unknown shortcodes", function()
            Replace(Blizz, "GetGuildInfoText", function()
                return "<CRT:42 UNKNOWN:99>"
            end)
            Replace(Private, "GetAddonVersion", function(name)
                if name == "CoffeeRaidTools" then
                    return "42"
                end
            end)
            assert.are.equal(0, #Private.CheckGuildVersions())
        end)
    end)

    describe("GetExpectedVersionTable", function()
        it("returns the raid leader's versions when they have reported", function()
            local leaderVersions = { CRT = "99", NSRTHASH = "abc" }
            Replace(Blizz, "IsInGroup", function()
                return true
            end)
            Replace(Private, "IterateGroupMembers", function()
                local units = { "raid1", "raid2" }
                local i = 0
                return function()
                    i = i + 1
                    return units[i]
                end
            end)
            Replace(Blizz, "UnitIsGroupLeader", function(unit)
                return unit == "raid1"
            end)
            Replace(Blizz, "UnitGUID", function(unit)
                return "guid-" .. unit
            end)
            Replace(Private, "GetGroupVersionsTable", function()
                return { ["guid-raid1"] = leaderVersions }
            end)
            assert.are.equal(leaderVersions, Private:GetExpectedVersionTable())
        end)

        it("falls back to the local versions when not in a group", function()
            local localVersions = { CRT = "1.0" }
            Replace(Blizz, "IsInGroup", function()
                return false
            end)
            Replace(Private, "GetLocalVersionTable", function()
                return localVersions
            end)
            assert.are.equal(localVersions, Private:GetExpectedVersionTable())
        end)

        it("falls back to local when the leader has not responded", function()
            local localVersions = { CRT = "1.0" }
            Replace(Blizz, "IsInGroup", function()
                return true
            end)
            Replace(Private, "IterateGroupMembers", function()
                local units = { "raid1", "raid2" }
                local i = 0
                return function()
                    i = i + 1
                    return units[i]
                end
            end)
            Replace(Blizz, "UnitIsGroupLeader", function(unit)
                return unit == "raid1"
            end)
            Replace(Blizz, "UnitGUID", function()
                return "guid-leader"
            end)
            Replace(Private, "GetGroupVersionsTable", function()
                return {}
            end)
            Replace(Private, "GetLocalVersionTable", function()
                return localVersions
            end)
            assert.are.equal(localVersions, Private:GetExpectedVersionTable())
        end)

        it("works when the local player is the leader", function()
            local leaderVersions = { CRT = "42" }
            Replace(Blizz, "IsInGroup", function()
                return true
            end)
            Replace(Private, "IterateGroupMembers", function()
                local units = { "player", "raid1" }
                local i = 0
                return function()
                    i = i + 1
                    return units[i]
                end
            end)
            Replace(Blizz, "UnitIsGroupLeader", function(unit)
                return unit == "player"
            end)
            Replace(Blizz, "UnitGUID", function(unit)
                return "guid-" .. unit
            end)
            Replace(Private, "GetGroupVersionsTable", function()
                return { ["guid-player"] = leaderVersions }
            end)
            assert.are.equal(leaderVersions, Private:GetExpectedVersionTable())
        end)

        it("falls back when the leader's GUID is secret", function()
            local localVersions = { CRT = "1.0" }
            Replace(Blizz, "IsInGroup", function()
                return true
            end)
            Replace(Private, "IterateGroupMembers", function()
                local units = { "raid1" }
                local i = 0
                return function()
                    i = i + 1
                    return units[i]
                end
            end)
            Replace(Blizz, "UnitIsGroupLeader", function()
                return true
            end)
            Replace(Blizz, "UnitGUID", function()
                return "secret-guid"
            end)
            Replace(Blizz, "issecretvalue", function()
                return true
            end)
            Replace(Private, "GetLocalVersionTable", function()
                return localVersions
            end)
            assert.are.equal(localVersions, Private:GetExpectedVersionTable())
        end)
    end)
end)

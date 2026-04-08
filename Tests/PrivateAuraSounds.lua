---@class Private
local Private = select(2, ...)
local Blizz = Private.Blizz

local Tests, Asserts = Private.Tests:CreateSuite("PrivateAuras")
local IsTrue, AreEqual, Replace = Asserts.IsTrue, Asserts.AreEqual, Asserts.Replace

local function MockIterateGroupMembers(units)
    Replace(Private, "IterateGroupMembers", function()
        local i = 0
        return function()
            i = i + 1
            return units[i]
        end
    end)
end

local function MockNickname(nicknames)
    Replace(CoffeeRaidTools, "GetNickname", function(self, unit, noFormat)
        return nicknames[unit]
    end)
end

local function MockCombat(inCombat)
    Replace(Private, "IsInCombat", function()
        return inCombat
    end)
end

local function CountAddsForUnits(calls, units)
    local lookup = {}
    for _, unit in ipairs(units) do
        lookup[unit] = true
    end
    local matched = {}
    for _, call in ipairs(calls) do
        if call.action == "add" and lookup[call.unit] then
            tinsert(matched, call)
        end
    end
    return matched
end

local function MockBlizzAPIs(calls)
    Replace(Blizz, "AuraIsPrivate", function()
        return true
    end)
    Replace(Blizz, "AddPrivateAuraAppliedSound", function(info)
        tinsert(calls, { action = "add", unit = info.unitToken, spellID = info.spellID, sound = info.soundFileName })
        return #calls
    end)
    Replace(Blizz, "RemovePrivateAuraAppliedSound", function(soundID)
        tinsert(calls, { action = "remove", soundID = soundID })
    end)
    Replace(Blizz, "issecretvalue", function()
        return false
    end)
end

function Tests:DisabledSpellSkipsRegistration()
    Private.db.disabledPrivateAuras = { [1255612] = true }
    MockCombat(false)
    local calls = {}
    MockBlizzAPIs(calls)
    MockIterateGroupMembers({ "raid1" })
    MockNickname({ raid1 = "Waffle" })

    Private.RegisterPrivateAuraSounds()

    AreEqual(0, #CountAddsForUnits(calls, { "raid1" }))
end

function Tests:CombatGuardSkipsRegistration()
    Private.db.disabledPrivateAuras = {}
    MockCombat(true)
    local calls = {}
    MockBlizzAPIs(calls)
    MockIterateGroupMembers({ "raid1" })
    MockNickname({ raid1 = "Waffle" })

    Private.RegisterPrivateAuraSounds()

    AreEqual(0, #CountAddsForUnits(calls, { "raid1" }))
end

function Tests:KnownNicknameUsesCorrectSound()
    Private.db.disabledPrivateAuras = {}
    MockCombat(false)
    local calls = {}
    MockBlizzAPIs(calls)
    MockIterateGroupMembers({ "raid1" })
    MockNickname({ raid1 = "Waffle" })

    Private.RegisterPrivateAuraSounds()

    local addCalls = CountAddsForUnits(calls, { "raid1" })
    AreEqual(1, #addCalls)
    AreEqual("raid1", addCalls[1].unit)
    IsTrue(addCalls[1].sound:find("DreadBreath\\Waffle"))
end

function Tests:UnknownNicknameUsesFallback()
    Private.db.disabledPrivateAuras = {}
    MockCombat(false)
    local calls = {}
    MockBlizzAPIs(calls)
    MockIterateGroupMembers({ "raid1" })
    MockNickname({ raid1 = "SomeRandomPerson" })
    Replace(CoffeeRaidTools, "Print", function() end)

    Private.RegisterPrivateAuraSounds()

    local addCalls = CountAddsForUnits(calls, { "raid1" })
    AreEqual(1, #addCalls)
    IsTrue(addCalls[1].sound:find("DreadBreath\\Unknown"))
end

function Tests:SecretUnitSkippedSilently()
    Private.db.disabledPrivateAuras = {}
    MockCombat(false)
    local calls = {}
    MockBlizzAPIs(calls)
    Replace(Blizz, "issecretvalue", function(value)
        return value == "SECRET"
    end)
    MockIterateGroupMembers({ "raid1" })
    MockNickname({ raid1 = "SECRET" })

    Private.RegisterPrivateAuraSounds()

    AreEqual(0, #CountAddsForUnits(calls, { "raid1" }))
end

function Tests:PerUnitRegistersForEachMember()
    Private.db.disabledPrivateAuras = {}
    MockCombat(false)
    local calls = {}
    MockBlizzAPIs(calls)
    MockIterateGroupMembers({ "raid1", "raid2", "raid3" })
    MockNickname({ raid1 = "Waffle", raid2 = "Gold", raid3 = "Hun" })

    Private.RegisterPrivateAuraSounds()

    local addCalls = CountAddsForUnits(calls, { "raid1", "raid2", "raid3" })
    AreEqual(3, #addCalls)
    AreEqual("raid1", addCalls[1].unit)
    AreEqual("raid2", addCalls[2].unit)
    AreEqual("raid3", addCalls[3].unit)
end

function Tests:NilNicknameSkippedSilently()
    Private.db.disabledPrivateAuras = {}
    MockCombat(false)
    local calls = {}
    MockBlizzAPIs(calls)
    MockIterateGroupMembers({ "raid1" })
    MockNickname({})

    Private.RegisterPrivateAuraSounds()

    AreEqual(0, #CountAddsForUnits(calls, { "raid1" }))
end

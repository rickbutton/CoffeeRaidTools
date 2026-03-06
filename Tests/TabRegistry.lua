if not WoWUnit then return end

---@class Private
local Private = select(2, ...)

local AreEqual, IsTrue, IsFalse = WoWUnit.AreEqual, WoWUnit.IsTrue, WoWUnit.IsFalse
local Tests = WoWUnit("CRT TabRegistry")

local function CountTabs()
    local count = 0
    for _ in Private:IterateTabDescriptions() do
        count = count + 1
    end
    return count
end

function Tests:RegisterTabAddsToList()
    local before = CountTabs()
    Private:RegisterTab("unittest", "Unit Test", function() end)
    local after = CountTabs()
    AreEqual(before + 1, after)
end

function Tests:GetTabDescriptionFindsRegistered()
    Private:RegisterTab("unittest_find", "Find Me", function() end)
    local tab = Private:GetTabDescription("unittest_find")
    IsTrue(tab ~= nil)
    AreEqual("unittest_find", tab.key)
    AreEqual("Find Me", tab.title)
end

function Tests:GetTabDescriptionReturnsNilForUnknown()
    local tab = Private:GetTabDescription("nonexistent_key_12345")
    IsFalse(tab)
end

function Tests:IterateTabDescriptionsReturnsAll()
    local found = {}
    for _, tab in Private:IterateTabDescriptions() do
        found[tab.key] = true
    end
    IsTrue(found["raid"] ~= nil)
end

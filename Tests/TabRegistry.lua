---@class Private
local Private = select(2, ...)

local Tests, Asserts = Private.Tests:CreateSuite("TabRegistry")
local AreEqual, IsTrue, IsFalse = Asserts.AreEqual, Asserts.IsTrue, Asserts.IsFalse

local savedTabs

local function SaveTabs()
    savedTabs = {}
    for i, v in ipairs(Private.tabs) do
        savedTabs[i] = v
    end
end

local function RestoreTabs()
    Private.tabs = savedTabs
end

function Tests:RegisterTabAddsToList()
    SaveTabs()
    local before = #Private.tabs
    Private:RegisterTab("unittest", "Unit Test", function() end)
    local after = #Private.tabs
    AreEqual(before + 1, after)
    RestoreTabs()
end

function Tests:GetTabDescriptionFindsRegistered()
    SaveTabs()
    Private:RegisterTab("unittest_find", "Find Me", function() end)
    local tab = Private:GetTabDescription("unittest_find")
    IsTrue(tab ~= nil)
    AreEqual("unittest_find", tab.key)
    AreEqual("Find Me", tab.title)
    RestoreTabs()
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

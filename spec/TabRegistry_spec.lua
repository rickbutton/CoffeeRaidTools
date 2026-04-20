describe("TabRegistry", function()
    local savedTabs

    before_each(function()
        savedTabs = {}
        for i, v in ipairs(Private.tabs) do
            savedTabs[i] = v
        end
    end)

    after_each(function()
        Private.tabs = savedTabs
        Restore()
    end)

    it("RegisterTab appends to the list", function()
        local before = #Private.tabs
        Private:RegisterTab("unittest", "Unit Test", function() end)
        assert.are.equal(before + 1, #Private.tabs)
    end)

    it("GetTabDescription finds a registered tab", function()
        Private:RegisterTab("unittest_find", "Find Me", function() end)
        local tab = Private:GetTabDescription("unittest_find")
        assert.is_not_nil(tab)
        assert.are.equal("unittest_find", tab.key)
        assert.are.equal("Find Me", tab.title)
    end)

    it("GetTabDescription returns nil for unknown keys", function()
        assert.is_falsy(Private:GetTabDescription("nonexistent_key_12345"))
    end)

    it("IterateTabDescriptions yields pre-registered tabs", function()
        local found = {}
        for _, tab in Private:IterateTabDescriptions() do
            found[tab.key] = true
        end
        assert.is_not_nil(found["raid"])
    end)
end)

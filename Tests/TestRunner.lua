---@class Private
local Private = select(2, ...)

---@class TestSuite
---@field name string
---@field tests table<string, fun(self: TestSuite)>
---@field restore fun()

---@class TestRunner
---@field suites TestSuite[]
Private.Tests = {
    suites = {},
}

---@param name string
---@return table suite, table asserts
function Private.Tests:CreateSuite(name)
    local tests = {}
    local suite = setmetatable({ name = name, tests = tests }, {
        __newindex = function(t, key, value)
            if type(value) == "function" then
                tests[key] = value
            else
                rawset(t, key, value)
            end
        end,
    })
    tinsert(self.suites, suite)

    local replacements = {}

    local asserts = {}

    function asserts.AreEqual(expected, actual)
        if expected ~= actual then
            error(("AreEqual failed: expected %s, got %s"):format(tostring(expected), tostring(actual)), 2)
        end
    end

    function asserts.IsTrue(value)
        if not value then
            error(("IsTrue failed: got %s"):format(tostring(value)), 2)
        end
    end

    function asserts.IsFalse(value)
        if value then
            error(("IsFalse failed: got %s"):format(tostring(value)), 2)
        end
    end

    function asserts.Replace(tableOrName, keyOrValue, replacement)
        if type(tableOrName) == "string" then
            local original = _G[tableOrName]
            tinsert(replacements, { target = _G, key = tableOrName, original = original })
            _G[tableOrName] = keyOrValue
        else
            local original = tableOrName[keyOrValue]
            tinsert(replacements, { target = tableOrName, key = keyOrValue, original = original })
            tableOrName[keyOrValue] = replacement
        end
    end

    rawset(suite, "restore", function()
        for i = #replacements, 1, -1 do
            local r = replacements[i]
            r.target[r.key] = r.original
        end
        wipe(replacements)
    end)

    return suite, asserts
end

---@param suiteName? string
function Private.Tests:RunAll(suiteName)
    local totalPassed, totalFailed = 0, 0

    for _, suite in ipairs(self.suites) do
        if not suiteName or suite.name == suiteName then
            local passed, failed = 0, 0

            for testName, testFunc in pairs(suite.tests) do
                local ok, err = pcall(testFunc, suite)
                suite.restore()

                if ok then
                    passed = passed + 1
                else
                    failed = failed + 1
                    CoffeeRaidTools:Print(("|cffff0000FAIL|r %s:%s - %s"):format(suite.name, testName, tostring(err)))
                end
            end

            totalPassed = totalPassed + passed
            totalFailed = totalFailed + failed

            local color = failed > 0 and "ff0000" or "00ff00"
            CoffeeRaidTools:Print(("|cff%s%s|r: %d passed, %d failed"):format(color, suite.name, passed, failed))
        end
    end

    local summaryColor = totalFailed > 0 and "ff0000" or "00ff00"
    CoffeeRaidTools:Print(("|cff%sTotal: %d passed, %d failed|r"):format(summaryColor, totalPassed, totalFailed))
end

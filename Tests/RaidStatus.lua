---@class Private
local Private = select(2, ...)

local Tests, Asserts = Private.Tests:CreateSuite("RaidStatus")
local AreEqual, IsTrue, IsFalse = Asserts.AreEqual, Asserts.IsTrue, Asserts.IsFalse

function Tests:StatusAllGood()
    local expected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local player = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local status = Private.GeneratePlayerStatus(player, expected)
    IsTrue(status.good)
    IsFalse(status.noResponse)
    AreEqual(0, #status.failures)
end

function Tests:StatusNilPlayerVersions()
    local expected = { CRT = "1.0" }
    local status = Private.GeneratePlayerStatus(nil, expected)
    IsFalse(status.good)
    IsTrue(status.noResponse)
end

function Tests:StatusMissingExistsAddon()
    local expected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local player = {
        CRT = "1.0",
        BW = "NONE",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local status = Private.GeneratePlayerStatus(player, expected)
    IsFalse(status.good)
    AreEqual(1, #status.failures)
    AreEqual("BW", status.failures[1])
end

function Tests:StatusWrongEqualVersion()
    local expected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local player = {
        CRT = "0.9",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local status = Private.GeneratePlayerStatus(player, expected)
    IsFalse(status.good)
    AreEqual("CRT=0.9", status.failures[1])
end

function Tests:StatusMissingEqualAddon()
    local expected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local player = {
        CRT = "NONE",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local status = Private.GeneratePlayerStatus(player, expected)
    IsFalse(status.good)
    AreEqual("CRT", status.failures[1])
end

function Tests:StatusMRTHashMismatch()
    local expected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local player = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "different",
        NSRTHASH = "def",
    }
    local status = Private.GeneratePlayerStatus(player, expected)
    IsFalse(status.good)
    AreEqual("MRTNOTE", status.failures[1])
end

function Tests:StatusNSRTHashMismatch()
    local expected = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local player = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "1.0",
        MRT = "3.0",
        RCLC = "1.0",
        TR = "1.0",
        MRTHASH = "abc",
        NSRTHASH = "different",
    }
    local status = Private.GeneratePlayerStatus(player, expected)
    IsFalse(status.good)
    AreEqual("NSRTNOTE", status.failures[1])
end

function Tests:FormatStatusTextGood()
    local text = Private.FormatStatusText({ good = true, failures = {}, noResponse = false })
    AreEqual("|cff00ff00GOOD|r", text)
end

function Tests:FormatStatusTextNoResponse()
    local text = Private.FormatStatusText({ good = false, failures = {}, noResponse = true })
    AreEqual("|cffff0000NO RESPONSE|r", text)
end

function Tests:FormatStatusTextFailures()
    local text = Private.FormatStatusText({ good = false, failures = { "BW", "CRT=0.9" }, noResponse = false })
    AreEqual("|cffff0000BW CRT=0.9|r", text)
end

function Tests:TooltipTextNormal()
    local player = {
        CRT = "1.0",
        BW = "2.0",
        NSRT = "3.0",
        MRT = "4.0",
        RCLC = "5.0",
        TR = "6.0",
        MRTHASH = "abc",
        NSRTHASH = "def",
    }
    local result = Private.GenerateTooltipText(player)
    IsTrue(result:find("CRT=1.0") ~= nil)
    IsTrue(result:find("BW=2.0") ~= nil)
    IsTrue(result:find("MRTHASH=abc") ~= nil)
    IsTrue(result:find("NSRTHASH=def") ~= nil)
end

function Tests:TooltipTextNilPlayerVersions()
    local result = Private.GenerateTooltipText(nil)
    AreEqual("NO RESPONSE", result)
end

function Tests:TooltipTextMissingShortcodeShowsNONE()
    local player = { CRT = "1.0" }
    local result = Private.GenerateTooltipText(player)
    IsTrue(result:find("BW=NONE") ~= nil)
end

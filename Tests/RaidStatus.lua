if not WoWUnit then return end

---@class Private
local Private = select(2, ...)

local AreEqual, IsTrue, IsFalse = WoWUnit.AreEqual, WoWUnit.IsTrue, WoWUnit.IsFalse
local Tests = WoWUnit("CRT RaidStatus")

function Tests:StatusTextAllGood()
    local expected = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local player = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local result = Private.GenerateStatusText(player, expected)
    AreEqual("|cff00ff00GOOD|r", result)
end

function Tests:StatusTextNilPlayerVersions()
    local expected = { CRT = "1.0" }
    local result = Private.GenerateStatusText(nil, expected)
    AreEqual("|cffff0000NO RESPONSE|r", result)
end

function Tests:StatusTextMissingExistsAddon()
    local expected = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local player = { CRT = "1.0", BW = "NONE", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local result = Private.GenerateStatusText(player, expected)
    IsTrue(result:find("BW") ~= nil)
end

function Tests:StatusTextWrongEqualVersion()
    local expected = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local player = { CRT = "0.9", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local result = Private.GenerateStatusText(player, expected)
    IsTrue(result:find("CRT=0.9") ~= nil)
end

function Tests:StatusTextMissingEqualAddon()
    local expected = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local player = { CRT = "NONE", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local result = Private.GenerateStatusText(player, expected)
    IsTrue(result:find("CRT") ~= nil)
    IsFalse(result:find("CRT="))
end

function Tests:StatusTextMRTHashMismatch()
    local expected = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "abc" }
    local player = { CRT = "1.0", BW = "2.0", NSRT = "1.0", MRT = "3.0", RCLC = "1.0", TR = "1.0", MRTHASH = "different" }
    local result = Private.GenerateStatusText(player, expected)
    IsTrue(result:find("NOTE") ~= nil)
end

function Tests:TooltipTextNormal()
    local player = { CRT = "1.0", BW = "2.0", NSRT = "3.0", MRT = "4.0", RCLC = "5.0", TR = "6.0", MRTHASH = "abc" }
    local result = Private.GenerateTooltipText(player)
    IsTrue(result:find("CRT=1.0") ~= nil)
    IsTrue(result:find("BW=2.0") ~= nil)
    IsTrue(result:find("MRTHASH=abc") ~= nil)
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

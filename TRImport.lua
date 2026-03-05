---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

local BattleTagToNickname = {
    ["waffletwo#1858"] = "Waffle",
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, _, addonName)
    if addonName ~= "TimelineReminders" then return end
    self:UnregisterAllEvents()

    if not LiquidRemindersSaved then return end

    local battleTag = select(2, BNGetInfo())
    if not battleTag then return end

    local expectedNickname = BattleTagToNickname[battleTag]
    if not expectedNickname then return end

    if LiquidRemindersSaved.nickname ~= expectedNickname then
        Private:DebugPrint("TR nickname: " .. tostring(LiquidRemindersSaved.nickname) .. " -> " .. expectedNickname)
        LiquidRemindersSaved.nickname = expectedNickname
    end
end)

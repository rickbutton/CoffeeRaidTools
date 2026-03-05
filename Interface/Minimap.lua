---@class Private
local Private = select(2, ...)

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local dataObject = LDB:NewDataObject("CoffeeRaidTools", {
    type = "launcher",
    text = "Coffee Raid Tools",
    icon = "Interface\\AddOns\\CoffeeRaidTools\\Media\\minimap",
    OnClick = function(_, button)
        if button == "LeftButton" then
            CoffeeRaidTools:ToggleFrame()
        elseif button == "RightButton" then
            if Private.frame and Private:GetCurrentTab() == "settings" then
                CoffeeRaidTools:CloseFrame()
            else
                CoffeeRaidTools:OpenFrame("settings")
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Coffee Raid Tools")
        tooltip:AddLine("|cffffffffLeft Click|r - main window", 0.8, 0.8, 0.8)
        tooltip:AddLine("|cffffffffRight Click|r - open settings", 0.8, 0.8, 0.8)
    end,
})

if Private.db.minimapIcon == nil then
    Private.db.minimapIcon = {}
end

LDBIcon:Register("CoffeeRaidTools", dataObject, Private.db.minimapIcon)

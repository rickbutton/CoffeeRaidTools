---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local function DrawTab(container)
    ---@type AceGUILabel
    local lbl = AceGUI:Create("Label")
    lbl:SetText("settings")
    lbl:SetFullWidth(true)
    container:AddChild(lbl)
end

Private:RegisterTab("settings", "Settings", DrawTab)




---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local function DrawTab(container)
    ---@type AceGUICheckBox
    local debugCheckbox = AceGUI:Create("CheckBox")
    debugCheckbox:SetLabel("Enable Debug Logs")
    debugCheckbox:SetValue(Private.db.debug)
    debugCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        Private.db.debug = value
    end)
    debugCheckbox:SetFullWidth(true)
    container:AddChild(debugCheckbox)
end

Private:RegisterTab("settings", "Settings", DrawTab)




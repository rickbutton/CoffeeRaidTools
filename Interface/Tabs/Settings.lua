---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local function CreateSectionTitle(text)
    ---@type AceGUILabel
    local label = AceGUI:Create("Label")
    label:SetText(text)
    label:SetFullWidth(true)
    label:SetFont(GameFontNormalLarge:GetFont())
    label:SetColor(1, 0.82, 0)
    return label
end

local function CreateSpacer()
    ---@type AceGUILabel
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    return spacer
end

local function CreateSettingsCheckbox(key, label)
    ---@type AceGUICheckBox
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetLabel(label)
    checkbox:SetValue(Private.db[key])
    checkbox:SetCallback("OnValueChanged", function(widget, event, value)
        Private.db[key] = value
    end)
    checkbox:SetFullWidth(true)
    return checkbox
end

local function DrawTab(container)
    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("Settings"))
    container:AddChild(CreateSpacer())

    container:AddChild(CreateSettingsCheckbox("debug", "Enable Debug Logs"))
    container:AddChild(CreateSettingsCheckbox("testGroupVersionList", "Test Group Version List"))
end

Private:RegisterTab("settings", "Settings", DrawTab)




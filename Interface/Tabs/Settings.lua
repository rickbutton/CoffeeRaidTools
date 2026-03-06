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

---@param key string
---@param label string
---@param values table<string, string>
---@param order string[]
local function CreateSettingsDropdown(key, label, values, order)
    ---@type AceGUIDropdown
    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetLabel(label)
    dropdown:SetList(values, order)
    dropdown:SetValue(Private.db[key])
    dropdown:SetCallback("OnValueChanged", function(widget, event, value)
        Private.db[key] = value
    end)
    dropdown:SetFullWidth(true)
    return dropdown
end

local function DrawTab(container)
    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("General"))
    container:AddChild(CreateSpacer())

    container:AddChild(CreateSettingsCheckbox("debug", "Enable Debug Logs"))
    container:AddChild(CreateSettingsCheckbox("testGroupVersionList", "Test Group Version List"))

    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("Ready Check"))
    container:AddChild(CreateSpacer())

    container:AddChild(CreateSettingsDropdown(
        "readyCheckPopup",
        "Check Players on Ready Check",
        {
            never = "Never",
            always = "Always",
            inraid = "In Raid",
            inraidcoffee = "In Raid with Coffee Players",
        },
        { "never", "inraid", "inraidcoffee", "always" }
    ))

    if Private.db.devMode then
        container:AddChild(CreateSpacer())
        container:AddChild(CreateSectionTitle("Dev Mode"))
        container:AddChild(CreateSpacer())
        container:AddChild(CreateSettingsCheckbox("runTestsOnLoad", "Run Tests on Addon Load"))
    end
end

Private:RegisterTab("settings", "Settings", DrawTab)




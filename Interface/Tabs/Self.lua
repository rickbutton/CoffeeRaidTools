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

local function CreateSeparator()
    ---@type AceGUIHeading
    local separator = AceGUI:Create("Heading")
    separator:SetFullWidth(true)
    return separator
end

local function CreateSpacer()
    ---@type AceGUILabel
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    return spacer
end

local function CreateAddonRow(addonName, statusText)
    ---@type AceGUISimpleGroup
    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    
    ---@type AceGUIInteractiveLabel
    local nameLabel = AceGUI:Create("InteractiveLabel")
    nameLabel:SetText(addonName)
    nameLabel:SetRelativeWidth(0.3)
    nameLabel:SetFont(GameFontNormal:GetFont())
    
    ---@type AceGUILabel
    local statusLabel = AceGUI:Create("Label")
    statusLabel:SetText(statusText)
    statusLabel:SetRelativeWidth(0.7)
    
    row:AddChild(nameLabel)
    row:AddChild(statusLabel)
    return row
end

local function FormatVersion(version)
    if version == "NONE" then
        return "|cffff0000Not Installed|r"
    else
        return "|cff00ff00" .. version .. "|r"
    end
end

---@param container AceGUIContainer
local function DrawTab(container)
    container:SetLayout("List")

    -- Addons section
    container:AddChild(CreateSectionTitle("Installed AddOns"))
    container:AddChild(CreateSeparator())

    for _, addon in ipairs(Private.AddonsToTrack) do
        local version = Private:GetLocalVersion(addon.shortcode)
        if addon.shortcode == "AU" then version = "NONE" end
        container:AddChild(CreateAddonRow(addon.name, FormatVersion(version)))
    end
    
    container:AddChild(CreateSpacer())
    
    -- WeakAuras section
    container:AddChild(CreateSectionTitle("Installed WeakAuras"))

    for _, aura in ipairs(Private.WeakAurasToTrack) do
        local version = Private:GetLocalVersion(aura.shortcode)
        container:AddChild(CreateAddonRow(aura.name, FormatVersion(version)))
    end
end

Private:RegisterTab("self", "Self", DrawTab)

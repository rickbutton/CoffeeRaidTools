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

    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("Player Info"))
    container:AddChild(CreateSpacer())

    local nickname, format = CoffeeRaidTools:GetNickname("player")
    container:AddChild(CreateAddonRow("Character Name", CoffeeRaidTools:GetCharacterNameWithRealm("player")))
    container:AddChild(CreateAddonRow("Nickname", string.format(format, nickname)))

    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("Installed AddOns"))
    container:AddChild(CreateSpacer())

    for _, addon in ipairs(Private.AddonsToTrack) do
        local version = Private:GetLocalVersion(addon.shortcode)
        container:AddChild(CreateAddonRow(addon.name, FormatVersion(version)))
    end
end

Private:RegisterTab("local", "Player", DrawTab)

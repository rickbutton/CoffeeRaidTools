---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local function NewSection(title)
    ---@type AceGUIInlineGroup
    local group = AceGUI:Create("InlineGroup")
    group:SetLayout("List")
    group:SetTitle(title)
    return group
end

---@param container AceGUIContainer
local function DrawTab(container)
    container:SetLayout("List")

    local addonSection = NewSection("Installed AddOns")
    container:AddChild(addonSection)

    local addons = {
        "MRT",
        "BigWigs",
        "TimelineReminders",
        "AuraUpdater",
        "RCLootCouncil",
    }
    ---@type AceGUIInlineGroup
    for _, v in ipairs(addons) do
        ---@class AceGUILabel
        local lbl = AceGUI:Create("Label")
        lbl:SetText(v)
        lbl:SetJustifyH("LEFT")

        addonSection:AddChild(lbl)
    end
    addonSection.content:SetPoint("TOPLEFT", 20, -10)

    local weakAuraSection = NewSection("Installed WeakAuras")
    container:AddChild(weakAuraSection)
end

Private:RegisterTab("self", "Self", DrawTab)

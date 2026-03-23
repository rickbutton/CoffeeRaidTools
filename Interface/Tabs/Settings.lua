---@class Private
local Private = select(2, ...)
---@type Blizz
local Blizz = Private.Blizz
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
    dropdown:SetWidth(220)
    return dropdown
end

local function DrawTab(container)
    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("Ready Check"))
    container:AddChild(CreateSpacer())

    container:AddChild(CreateSettingsDropdown("readyCheckPopup", "Check Players on Ready Check", {
        never = "Never",
        always = "Always",
        inraid = "In Raid",
        inraidcoffee = "In Raid with Coffee Players",
    }, { "never", "inraid", "inraidcoffee", "always" }))

    container:AddChild(CreateSpacer())
    container:AddChild(CreateSectionTitle("Private Aura Sounds"))
    container:AddChild(CreateSpacer())

    for _, section in ipairs(Private.PrivateAuraSections) do
        ---@type AceGUILabel
        local bossLabel = AceGUI:Create("Label")
        bossLabel:SetText(section.boss)
        bossLabel:SetFullWidth(true)
        bossLabel:SetFont(GameFontNormal:GetFont())
        bossLabel:SetColor(0.8, 0.8, 0.8)
        container:AddChild(bossLabel)

        for _, config in ipairs(section.spells) do
            ---@type AceGUISimpleGroup
            local row = AceGUI:Create("SimpleGroup")
            row:SetFullWidth(true)
            row:SetLayout("Flow")

            ---@type AceGUICheckBox
            local cb = AceGUI:Create("CheckBox")
            cb:SetLabel(config.label)
            cb:SetValue(not Private.db.disabledPrivateAuras[config.spellID])
            cb:SetCallback("OnValueChanged", function(widget, event, value)
                Private.db.disabledPrivateAuras[config.spellID] = (not value) or nil
            end)
            cb:SetCallback("OnEnter", function()
                ---@diagnostic disable-next-line: invisible
                GameTooltip:SetOwner(cb.frame, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(config.spellID)
                GameTooltip:Show()
            end)
            cb:SetCallback("OnLeave", function()
                GameTooltip:Hide()
            end)
            cb:SetRelativeWidth(0.35)
            row:AddChild(cb)

            if config.perUnit then
                ---@type AceGUIButton
                local btn = AceGUI:Create("Button")
                btn:SetText("Test")
                btn:SetRelativeWidth(0.2)
                row:AddChild(btn)

                local rosterNames = { Unknown = "Unknown" }
                local rosterOrder = {}
                for nickname in pairs(Private.RosterNicknames) do
                    rosterNames[nickname] = nickname
                    tinsert(rosterOrder, nickname)
                end
                table.sort(rosterOrder)
                tinsert(rosterOrder, "Unknown")

                ---@type AceGUIDropdown
                local dropdown = AceGUI:Create("Dropdown")
                dropdown:SetList(rosterNames, rosterOrder)
                dropdown:SetRelativeWidth(0.35)

                local playerNickname = CoffeeRaidTools:GetNickname("player", true)
                if playerNickname and rosterNames[playerNickname] then
                    dropdown:SetValue(playerNickname)
                end

                row:AddChild(dropdown)

                btn:SetCallback("OnClick", function()
                    local selected = dropdown:GetValue()
                    if selected then
                        Blizz.PlaySoundFile(Private:GetPrivateAuraSoundPath(config, selected), "master")
                    end
                end)
            else
                ---@type AceGUIButton
                local btn = AceGUI:Create("Button")
                btn:SetText("Test")
                btn:SetRelativeWidth(0.2)
                btn:SetCallback("OnClick", function()
                    Blizz.PlaySoundFile(Private:GetPrivateAuraSoundPath(config), "master")
                end)
                row:AddChild(btn)
            end

            container:AddChild(row)
        end
    end

    if Private.db.devMode then
        container:AddChild(CreateSpacer())
        container:AddChild(CreateSectionTitle("Dev Mode"))
        container:AddChild(CreateSpacer())
        container:AddChild(CreateSettingsCheckbox("debug", "Enable Debug Logs"))
        container:AddChild(CreateSettingsCheckbox("runTestsOnLoad", "Run Tests on Addon Load"))
        container:AddChild(CreateSettingsCheckbox("testGroupVersionList", "Test Group Version List"))
    end
end

Private:RegisterTab("settings", "Settings", DrawTab)

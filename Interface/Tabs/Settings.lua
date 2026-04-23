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
    dropdown:SetWidth(220)
    return dropdown
end

local function DrawTab(container)
    container:SetLayout("Fill")

    ---@type AceGUIScrollFrame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    scrollFrame:SetLayout("List")
    container:AddChild(scrollFrame)

    scrollFrame:AddChild(CreateSpacer())
    scrollFrame:AddChild(CreateSectionTitle("Ready Check"))
    scrollFrame:AddChild(CreateSpacer())

    scrollFrame:AddChild(CreateSettingsDropdown("readyCheckPopup", "Check Players on Ready Check", {
        never = "Never",
        always = "Always",
        inraid = "In Raid",
        inraidcoffee = "In Raid with Coffee Players",
    }, { "never", "inraid", "inraidcoffee", "always" }))

    scrollFrame:AddChild(CreateSpacer())
    scrollFrame:AddChild(CreateSectionTitle("Private Aura Sounds"))
    scrollFrame:AddChild(CreateSpacer())

    do
        ---@type AceGUICheckBox
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel("Disable BigWigs private aura sounds for CRT-managed spells")
        cb:SetValue(Private.db.disableConflictingBigWigsPrivateAuraSounds)
        cb:SetCallback("OnValueChanged", function(widget, event, value)
            Private.db.disableConflictingBigWigsPrivateAuraSounds = value
            Private:UpdateBigWigsPrivateAuras()
        end)
        cb:SetFullWidth(true)
        scrollFrame:AddChild(cb)
    end

    scrollFrame:AddChild(CreateSpacer())

    for _, section in ipairs(Private.PrivateAuraSections) do
        scrollFrame:AddChild(CreateSpacer())

        ---@type AceGUILabel
        local bossLabel = AceGUI:Create("Label")
        bossLabel:SetText(section.boss)
        bossLabel:SetFullWidth(true)
        bossLabel:SetFont(GameFontNormal:GetFont())
        bossLabel:SetColor(0.8, 0.8, 0.8)
        scrollFrame:AddChild(bossLabel)

        for i, config in ipairs(section.spells) do
            if i > 1 then
                scrollFrame:AddChild(CreateSpacer())
            end

            local primaryID = config.spellIDs[1]

            ---@type AceGUISimpleGroup
            local row = AceGUI:Create("SimpleGroup")
            row:SetFullWidth(true)
            row:SetLayout("Flow")

            ---@type AceGUICheckBox
            local cb = AceGUI:Create("CheckBox")
            cb:SetLabel(C_Spell.GetSpellName(primaryID) or tostring(primaryID))
            cb:SetValue(not Private.db.disabledPrivateAuras[primaryID])
            cb:SetCallback("OnValueChanged", function(widget, event, value)
                Private.db.disabledPrivateAuras[primaryID] = (not value) or nil
            end)
            cb:SetCallback("OnEnter", function()
                ---@diagnostic disable-next-line: invisible
                GameTooltip:SetOwner(cb.frame, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(primaryID)
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
                        PlaySoundFile(Private:GetPrivateAuraSoundPath(config, selected), "master")
                    end
                end)
            else
                ---@type AceGUIButton
                local btn = AceGUI:Create("Button")
                btn:SetText("Test")
                btn:SetRelativeWidth(0.2)
                btn:SetCallback("OnClick", function()
                    PlaySoundFile(Private:GetPrivateAuraSoundPath(config), "master")
                end)
                row:AddChild(btn)
            end

            scrollFrame:AddChild(row)
        end
    end

    scrollFrame:AddChild(CreateSpacer())
    scrollFrame:AddChild(CreateSectionTitle("Reminder Sounds"))
    scrollFrame:AddChild(CreateSpacer())

    do
        local reminderNames = {}
        local reminderOrder = {}
        local seen = {}
        for _, section in ipairs(Private.ReminderSoundSections or {}) do
            for _, reminder in ipairs(section.reminders) do
                if not seen[reminder.text] then
                    seen[reminder.text] = true
                    reminderNames[reminder.text] = reminder.text
                    tinsert(reminderOrder, reminder.text)
                end
            end
        end

        ---@type AceGUISimpleGroup
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")

        ---@type AceGUIDropdown
        local dropdown = AceGUI:Create("Dropdown")
        dropdown:SetLabel("Reminder")
        dropdown:SetList(reminderNames, reminderOrder)
        dropdown:SetRelativeWidth(0.6)
        if reminderOrder[1] then
            dropdown:SetValue(reminderOrder[1])
        end
        row:AddChild(dropdown)

        ---@type AceGUIButton
        local btn = AceGUI:Create("Button")
        btn:SetText("Test")
        btn:SetRelativeWidth(0.2)
        btn:SetCallback("OnClick", function()
            local selected = dropdown:GetValue()
            if not selected then
                return
            end
            local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
            local path = LSM and LSM:Fetch("sound", selected)
            if path and path ~= 1 then
                PlaySoundFile(path, "Master")
            else
                CoffeeRaidTools:Print("No sound registered for: " .. selected)
            end
        end)
        row:AddChild(btn)

        scrollFrame:AddChild(row)
    end

    scrollFrame:AddChild(CreateSpacer())
    scrollFrame:AddChild(CreateSectionTitle("Memory Game (Midnight Falls)"))
    scrollFrame:AddChild(CreateSpacer())

    scrollFrame:AddChild(CreateSettingsCheckbox("memoryGamePicker", "Show rune picker buttons during mechanic"))

    do
        ---@type AceGUIButton
        local unlockBtn = AceGUI:Create("Button")
        unlockBtn:SetText("Unlock Frames")
        unlockBtn:SetRelativeWidth(0.4)

        local unlocked = false
        unlockBtn:SetCallback("OnClick", function()
            unlocked = not unlocked
            Private:MemoryGameSetTestMode(unlocked)
            unlockBtn:SetText(unlocked and "Lock Frames" or "Unlock Frames")
        end)
        scrollFrame:AddChild(unlockBtn)
    end

    if Private.db.devMode then
        scrollFrame:AddChild(CreateSpacer())
        scrollFrame:AddChild(CreateSectionTitle("Dev Mode"))
        scrollFrame:AddChild(CreateSpacer())
        scrollFrame:AddChild(CreateSettingsCheckbox("debug", "Enable Debug Logs"))
        scrollFrame:AddChild(CreateSettingsCheckbox("testGroupVersionList", "Test Group Version List"))
    end
end

Private:RegisterTab("settings", "Settings", DrawTab)

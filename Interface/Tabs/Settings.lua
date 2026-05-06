---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local ENCOUNTERS_VALUE = "encounters"
local GENERAL_VALUE = "general"
local DEVMODE_VALUE = "devmode"

local treeStatus = {}

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

---@param container AceGUIContainer
---@param config PrivateAuraSpellConfig
local function AddPrivateAuraRow(container, config)
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
    cb:SetRelativeWidth(config.perUnit and 0.35 or 0.6)
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

    container:AddChild(row)
end

---@param container AceGUIContainer
---@param reminderSection ReminderSoundBossSection
local function AddReminderRows(container, reminderSection)
    for i, reminder in ipairs(reminderSection.reminders) do
        if i > 1 then
            container:AddChild(CreateSpacer())
        end

        local text = reminder.text

        ---@type AceGUISimpleGroup
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")

        ---@type AceGUICheckBox
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(text)
        cb:SetValue(not Private.db.disabledReminderSounds[text])
        cb:SetCallback("OnValueChanged", function(widget, event, value)
            Private.db.disabledReminderSounds[text] = (not value) or nil
        end)
        cb:SetRelativeWidth(0.6)
        row:AddChild(cb)

        ---@type AceGUIButton
        local btn = AceGUI:Create("Button")
        btn:SetText("Test")
        btn:SetRelativeWidth(0.2)
        btn:SetCallback("OnClick", function()
            local path = Private:GetReminderSoundPath(text)
            if path then
                PlaySoundFile(path, "Master")
            end
        end)
        row:AddChild(btn)

        container:AddChild(row)
    end
end

---@class EncounterEntry
---@field boss string
---@field value string
---@field spellSection? PrivateAuraBossSection
---@field reminderSection? ReminderSoundBossSection

---@return EncounterEntry[], ReminderSoundBossSection?
local function BuildEncounterEntries()
    ---@type EncounterEntry[]
    local entries = {}
    ---@type table<string, EncounterEntry>
    local byBoss = {}
    ---@type ReminderSoundBossSection?
    local generalReminder = nil

    local function getOrCreate(boss)
        local entry = byBoss[boss]
        if not entry then
            entry = { boss = boss, value = boss }
            byBoss[boss] = entry
            tinsert(entries, entry)
        end
        return entry
    end

    for _, section in ipairs(Private.PrivateAuraSections) do
        getOrCreate(section.boss).spellSection = section
    end

    for _, section in ipairs(Private.ReminderSoundSections or {}) do
        if section.encounterID then
            getOrCreate(section.boss).reminderSection = section
        elseif section.boss == "General" and not generalReminder then
            generalReminder = section
        end
    end

    return entries, generalReminder
end

---@param container AceGUIContainer
---@param entry EncounterEntry
local function RenderEncounterPage(container, entry)
    container:AddChild(CreateSectionTitle(entry.boss))
    container:AddChild(CreateSpacer())

    if entry.spellSection then
        ---@type AceGUILabel
        local header = AceGUI:Create("Label")
        header:SetText("Private Aura Sounds")
        header:SetFullWidth(true)
        header:SetFont(GameFontNormal:GetFont())
        header:SetColor(0.8, 0.8, 0.8)
        container:AddChild(header)

        for i, config in ipairs(entry.spellSection.spells) do
            if i > 1 then
                container:AddChild(CreateSpacer())
            end
            AddPrivateAuraRow(container, config)
        end

        container:AddChild(CreateSpacer())
    end

    if entry.reminderSection then
        ---@type AceGUILabel
        local header = AceGUI:Create("Label")
        header:SetText("Reminder Sounds")
        header:SetFullWidth(true)
        header:SetFont(GameFontNormal:GetFont())
        header:SetColor(0.8, 0.8, 0.8)
        container:AddChild(header)

        AddReminderRows(container, entry.reminderSection)
        container:AddChild(CreateSpacer())
    end

    if entry.boss == "Midnight Falls" then
        ---@type AceGUILabel
        local header = AceGUI:Create("Label")
        header:SetText("Memory Game")
        header:SetFullWidth(true)
        header:SetFont(GameFontNormal:GetFont())
        header:SetColor(0.8, 0.8, 0.8)
        container:AddChild(header)

        container:AddChild(CreateSettingsCheckbox("memoryGamePicker", "Show rune picker buttons during mechanic"))

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
        container:AddChild(unlockBtn)
    end
end

---@param container AceGUIContainer
---@param generalReminder? ReminderSoundBossSection
local function RenderGeneralPage(container, generalReminder)
    container:AddChild(CreateSectionTitle("Ready Check"))
    container:AddChild(CreateSpacer())

    container:AddChild(CreateSettingsDropdown("readyCheckPopup", "Check Players on Ready Check", {
        never = "Never",
        always = "Always",
        inraid = "In Raid",
        inraidcoffee = "In Raid with Coffee Players",
    }, { "never", "inraid", "inraidcoffee", "always" }))

    if generalReminder then
        container:AddChild(CreateSpacer())
        container:AddChild(CreateSectionTitle("General Reminder Sounds"))
        container:AddChild(CreateSpacer())
        AddReminderRows(container, generalReminder)
    end
end

---@param container AceGUIContainer
local function RenderEncountersParentPage(container)
    container:AddChild(CreateSectionTitle("Encounters"))
    container:AddChild(CreateSpacer())

    ---@type AceGUICheckBox
    local cb = AceGUI:Create("CheckBox")
    cb:SetLabel("Disable BigWigs private aura sounds for CRT-managed spells")
    cb:SetValue(Private.db.disableConflictingBigWigsPrivateAuraSounds)
    cb:SetCallback("OnValueChanged", function(widget, event, value)
        Private.db.disableConflictingBigWigsPrivateAuraSounds = value
        Private:UpdateBigWigsPrivateAuras()
    end)
    cb:SetFullWidth(true)
    container:AddChild(cb)
end

---@param container AceGUIContainer
local function RenderDevModePage(container)
    container:AddChild(CreateSectionTitle("Dev Mode"))
    container:AddChild(CreateSpacer())
    container:AddChild(CreateSettingsCheckbox("debug", "Enable Debug Logs"))
    container:AddChild(CreateSettingsCheckbox("testGroupVersionList", "Test Group Version List"))
end

local function DrawTab(container)
    container:SetLayout("Fill")

    local entries, generalReminder = BuildEncounterEntries()

    local encounterChildren = {}
    for _, entry in ipairs(entries) do
        tinsert(encounterChildren, { value = entry.value, text = entry.boss })
    end

    local tree = {
        { value = GENERAL_VALUE, text = "General" },
        { value = ENCOUNTERS_VALUE, text = "Encounters", children = encounterChildren },
    }
    if Private.db.devMode then
        tinsert(tree, { value = DEVMODE_VALUE, text = "Dev Mode" })
    end

    ---@type AceGUITreeGroup
    local treeGroup = AceGUI:Create("TreeGroup")
    treeGroup:SetFullWidth(true)
    treeGroup:SetFullHeight(true)
    treeGroup:SetLayout("Fill")
    treeGroup:EnableButtonTooltips(false)
    treeGroup:SetTree(tree)
    treeGroup:SetStatusTable(treeStatus)
    container:AddChild(treeGroup)

    local validValues = { [GENERAL_VALUE] = true, [ENCOUNTERS_VALUE] = true }
    if Private.db.devMode then
        validValues[DEVMODE_VALUE] = true
    end
    for _, entry in ipairs(entries) do
        validValues[ENCOUNTERS_VALUE .. "\001" .. entry.value] = true
    end

    local function RenderPage(pageContainer, uniqueValue)
        ---@type AceGUIScrollFrame
        local scrollFrame = AceGUI:Create("ScrollFrame")
        scrollFrame:SetFullWidth(true)
        scrollFrame:SetFullHeight(true)
        scrollFrame:SetLayout("List")
        pageContainer:AddChild(scrollFrame)

        scrollFrame:AddChild(CreateSpacer())

        if uniqueValue == GENERAL_VALUE then
            RenderGeneralPage(scrollFrame, generalReminder)
        elseif uniqueValue == ENCOUNTERS_VALUE then
            RenderEncountersParentPage(scrollFrame)
        elseif uniqueValue == DEVMODE_VALUE then
            RenderDevModePage(scrollFrame)
        else
            local prefix = ENCOUNTERS_VALUE .. "\001"
            if string.sub(uniqueValue, 1, #prefix) == prefix then
                local bossValue = string.sub(uniqueValue, #prefix + 1)
                for _, entry in ipairs(entries) do
                    if entry.value == bossValue then
                        RenderEncounterPage(scrollFrame, entry)
                        break
                    end
                end
            end
        end
    end

    treeGroup:SetCallback("OnGroupSelected", function(widget, event, uniqueValue)
        widget:ReleaseChildren()
        RenderPage(widget, uniqueValue)
    end)

    local toSelect = treeStatus.selected
    if not toSelect or not validValues[toSelect] then
        toSelect = GENERAL_VALUE
    end
    treeGroup:SelectByValue(toSelect)
end

Private:RegisterTab("settings", "Settings", DrawTab)

---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local function CreateSpacer()
    ---@type AceGUILabel
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    return spacer
end

local function CreateSeparator()
    ---@type AceGUIHeading
    local sep = AceGUI:Create("Heading")
    sep:SetFullWidth(true)
    return sep
end

---@class PlayerStatus
---@field good boolean
---@field failures string[]
---@field noResponse boolean

---@param playerVersions VersionTable?
---@param expectedVersions VersionTable
---@return PlayerStatus
local function GeneratePlayerStatus(playerVersions, expectedVersions)
    if not playerVersions then
        return { good = false, failures = {}, noResponse = true }
    end

    local failures = {}

    for _, addon in ipairs(Private.AddonsToTrack) do
        local playerVersion = playerVersions[addon.shortcode]
        local expectedVersion = expectedVersions[addon.shortcode]

        if addon.matcher == "EXISTS" then
            if playerVersion == "NONE" or not playerVersion then
                table.insert(failures, addon.shortcode)
            end
        elseif addon.matcher == "EQUAL" then
            if playerVersion ~= expectedVersion then
                if playerVersion == "NONE" or not playerVersion then
                    table.insert(failures, addon.shortcode)
                else
                    table.insert(failures, addon.shortcode .. "=" .. playerVersion)
                end
            end
        end
    end

    if playerVersions["MRTHASH"] ~= expectedVersions["MRTHASH"] then
        table.insert(failures, "NOTE")
    end

    return { good = #failures == 0, failures = failures, noResponse = false }
end

---@param status PlayerStatus
---@return string
local function FormatStatusText(status)
    if status.noResponse then
        return "|cffff0000NO RESPONSE|r"
    end
    if status.good then
        return "|cff00ff00GOOD|r"
    end
    return "|cffff0000" .. table.concat(status.failures, " ") .. "|r"
end

local function GenerateTooltipText(playerVersions)
    local entries = {}

    if not playerVersions then
        return "NO RESPONSE"
    end

    for _, addon in ipairs(Private.AddonsToTrack) do
        table.insert(entries, addon.shortcode .. "=" .. (playerVersions[addon.shortcode] or "NONE"))
    end

    table.insert(entries, "MRTHASH=" .. (playerVersions["MRTHASH"] or "NONE"))

    return table.concat(entries, "\n")
end

-- Relative widths must sum to < 1.0 to avoid AceGUI Flow layout wrapping due
-- to IEEE 754 floating point rounding (width*0.2 + width*0.8 can exceed width
-- for certain pixel widths).
local NAME_COL_WIDTH = 0.2
local STATUS_COL_WIDTH = 0.79

local function CreateTableRow(playerName, statusText, tooltipText)
    ---@type AceGUISimpleGroup
    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    row:SetFullWidth(true)

    ---@type AceGUILabel
    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(playerName)
    nameLabel:SetFont(GameFontHighlightSmall:GetFont())
    nameLabel:SetRelativeWidth(NAME_COL_WIDTH)

    row:AddChild(nameLabel)

    ---@type AceGUIInteractiveLabel
    local statusLabel = AceGUI:Create("InteractiveLabel")
    statusLabel:SetText(statusText)
    statusLabel:SetFont(GameFontHighlightSmall:GetFont())
    statusLabel:SetRelativeWidth(STATUS_COL_WIDTH)

    if tooltipText and tooltipText ~= "" then
        statusLabel:SetCallback("OnEnter", function()
            ---@diagnostic disable-next-line:invisible
            GameTooltip:SetOwner(statusLabel.frame, "ANCHOR_RIGHT")
            ---@diagnostic disable-next-line: missing-parameter
            GameTooltip:SetText(tooltipText)
            GameTooltip:Show()
        end)
        statusLabel:SetCallback("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    row:AddChild(statusLabel)
    return row
end

---@class PlayerData
---@field name string
---@field versions VersionTable?

---@param expectedVersions VersionTable
---@param allGood boolean
local function GenerateMockPlayerData(expectedVersions, allGood)
    ---@type [PlayerData]
    local players = {}

    for i = 1, 20 do
        local playerName = "Player" .. i
        local playerVersions = {}

        local scenario = allGood and 1 or math.random(1, 4)

        for _, addon in ipairs(Private.AddonsToTrack) do
            if scenario == 1 then
                playerVersions[addon.shortcode] = expectedVersions[addon.shortcode]
            elseif scenario == 2 then
                playerVersions[addon.shortcode] = math.random() > 0.7 and "NONE" or expectedVersions[addon.shortcode]
            elseif scenario == 3 then
                if math.random() > 0.5 then
                    playerVersions[addon.shortcode] = expectedVersions[addon.shortcode]
                else
                    playerVersions[addon.shortcode] = math.random() > 0.5 and "NONE" or "v1.2.3"
                end
            else
                playerVersions[addon.shortcode] = "NONE"
            end
        end

        if scenario == 1 then
            playerVersions["MRTHASH"] = expectedVersions["MRTHASH"]
        else
            playerVersions["MRTHASH"] = math.random() > 0.6 and expectedVersions["MRTHASH"] or "different_hash"
        end

        table.insert(players, { name = playerName, versions = playerVersions })
    end

    return players
end

local function GetPlayerData()
    local groupVersions = Private:GetGroupVersionsTable()

    ---@type [PlayerData]
    local players = {}
    for unit in Private:IterateGroupMembers() do
        local playerName, nameFormat = CoffeeRaidTools:GetNickname(unit)
        local guid = Private.UnitGUID(unit)
        if not issecretvalue(guid) and guid and Private:UnitIsRealPlayer(unit) then
            local versions = groupVersions[guid]
            if versions then
                table.insert(players, { name = string.format(nameFormat, playerName), versions = versions })
            else
                table.insert(players, { name = string.format(nameFormat, playerName), versions = nil })
            end
        end
    end
    return players
end

local function CreateTableHeader()
    ---@type AceGUISimpleGroup
    local header = AceGUI:Create("SimpleGroup")
    header:SetLayout("Flow")
    header:SetFullWidth(true)

    ---@type AceGUILabel
    local playerLabel = AceGUI:Create("Label")
    playerLabel:SetText("|cffffd700Player|r")
    playerLabel:SetFont(GameFontNormalSmall:GetFont())
    playerLabel:SetRelativeWidth(NAME_COL_WIDTH)
    header:AddChild(playerLabel)

    ---@type AceGUILabel
    local statusLabel = AceGUI:Create("Label")
    statusLabel:SetText("|cffffd700Status|r")
    statusLabel:SetFont(GameFontNormalSmall:GetFont())
    statusLabel:SetRelativeWidth(STATUS_COL_WIDTH)
    header:AddChild(statusLabel)

    return header
end

local currentContainer = nil

---@class DrawRaidContentOptions
---@field useTestData boolean?
---@field useTestDataAllGood boolean?
---@field showTitle boolean?

---@param container AceGUIContainer
---@param opts DrawRaidContentOptions?
---@return boolean allGood
function Private:DrawRaidContent(container, opts)
    local useTestData = opts and opts.useTestData or false
    local showTitle = not opts or opts.showTitle ~= false

    container:SetLayout("Flow")

    if not useTestData and Private:IsInCombat() then
        container:AddChild(CreateSpacer())
        ---@type AceGUILabel
        local restricted = AceGUI:Create("Label")
        restricted:SetText("|cffff8800Data unavailable during combat.|r")
        restricted:SetFullWidth(true)
        restricted:SetFont(GameFontNormal:GetFont())
        container:AddChild(restricted)
        return false
    end

    ---@type AceGUISimpleGroup
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("List")

    if showTitle then
        headerGroup:AddChild(CreateSpacer())

        ---@type AceGUISimpleGroup
        local titleRow = AceGUI:Create("SimpleGroup")
        titleRow:SetFullWidth(true)
        titleRow:SetLayout("Flow")

        ---@type AceGUILabel
        local titleLabel = AceGUI:Create("Label")
        titleLabel:SetText("Raid Configuration")
        titleLabel:SetFont(GameFontNormalLarge:GetFont())
        titleLabel:SetColor(1, 0.82, 0)
        titleLabel:SetRelativeWidth(0.5)
        titleRow:AddChild(titleLabel)

        ---@type AceGUICheckBox
        local filterCheckbox = AceGUI:Create("CheckBox")
        filterCheckbox:SetLabel("Only Show Mismatches")
        filterCheckbox:SetValue(Private.db.onlyShowMismatches)
        filterCheckbox:SetCallback("OnValueChanged", function(_, _, value)
            Private.db.onlyShowMismatches = value
            container:ReleaseChildren()
            Private:DrawRaidContent(container, opts)
        end)
        filterCheckbox:SetRelativeWidth(0.49)
        titleRow:AddChild(filterCheckbox)

        headerGroup:AddChild(titleRow)
        headerGroup:AddChild(CreateSpacer())
    else
        ---@type AceGUICheckBox
        local filterCheckbox = AceGUI:Create("CheckBox")
        filterCheckbox:SetLabel("Only Show Mismatches")
        filterCheckbox:SetValue(Private.db.onlyShowMismatches)
        filterCheckbox:SetCallback("OnValueChanged", function(_, _, value)
            Private.db.onlyShowMismatches = value
            container:ReleaseChildren()
            Private:DrawRaidContent(container, opts)
        end)
        headerGroup:AddChild(filterCheckbox)
    end

    local useTestDataAllGood = opts and opts.useTestDataAllGood or false

    local expectedVersions = Private:GetLocalVersionTable()
    local players
    if useTestDataAllGood then
        players = GenerateMockPlayerData(expectedVersions, true)
    elseif useTestData then
        players = GenerateMockPlayerData(expectedVersions, false)
    else
        players = GetPlayerData()
    end

    local filterMismatches = Private.db.onlyShowMismatches
    local allGood = true

    ---@type { name: string, statusText: string, tooltipText: string }[]
    local rows = {}
    for _, player in ipairs(players) do
        local status = GeneratePlayerStatus(player.versions, expectedVersions)
        if not status.good then
            allGood = false
        end
        if not filterMismatches or not status.good then
            local statusText = FormatStatusText(status)
            local tooltipText = GenerateTooltipText(player.versions)
            table.insert(rows, { name = player.name, statusText = statusText, tooltipText = tooltipText })
        end
    end

    if filterMismatches and #rows == 0 then
        container:AddChild(headerGroup)
        ---@type AceGUILabel
        local allGoodLabel = AceGUI:Create("Label")
        allGoodLabel:SetText("|cff00ff00All players are up to date.|r")
        allGoodLabel:SetFullWidth(true)
        allGoodLabel:SetFont(GameFontNormal:GetFont())
        container:AddChild(allGoodLabel)
        return true
    end

    headerGroup:AddChild(CreateTableHeader())
    headerGroup:AddChild(CreateSeparator())
    container:AddChild(headerGroup)

    ---@type AceGUIScrollFrame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    scrollFrame:SetLayout("List")

    -- Add scrollFrame to container BEFORE adding rows so that it receives
    -- a valid content.width from the parent layout. Without this, rows are
    -- initially laid out at width 0 and may not re-layout correctly.
    container:AddChild(scrollFrame)

    for i, row in ipairs(rows) do
        if i > 1 then
            scrollFrame:AddChild(CreateSeparator())
        end
        scrollFrame:AddChild(CreateTableRow(row.name, row.statusText, row.tooltipText))
    end

    return allGood
end

local function DrawTab(container)
    currentContainer = container
    Private:DrawRaidContent(container, { useTestData = Private.db.testGroupVersionList })
end

---@param container AceGUIContainer
local function ReleaseTab(container)
    currentContainer = nil
end

local function HandleVersionsChanged()
    if currentContainer then
        currentContainer:ReleaseChildren()
        DrawTab(currentContainer)
    end
end

Private.GeneratePlayerStatus = GeneratePlayerStatus
Private.FormatStatusText = FormatStatusText
Private.GenerateTooltipText = GenerateTooltipText

Private:RegisterTab("raid", "Raid", DrawTab, ReleaseTab)
Private:RegisterMessage("VERSIONS_CHANGED", HandleVersionsChanged)
Private:RegisterEvent("PLAYER_REGEN_DISABLED", HandleVersionsChanged)
Private:RegisterEvent("PLAYER_REGEN_ENABLED", HandleVersionsChanged)
Private:RegisterEvent("GROUP_ROSTER_UPDATE", HandleVersionsChanged)

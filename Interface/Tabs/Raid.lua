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

local function CreateSeparator()
    ---@type AceGUIHeading
    local sep = AceGUI:Create("Heading")
    sep:SetFullWidth(true)
    return sep
end

---@param playerVersions VersionTable?
---@param expectedVersions VersionTable
local function GenerateStatusText(playerVersions, expectedVersions)
    local failures = {}

    if not playerVersions then
        return "|cffff0000" .. "NO RESPONSE" .. "|r"
    end

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

    if #failures == 0 then
        return "|cff00ff00GOOD|r"
    else
        return "|cffff0000" .. table.concat(failures, " ") .. "|r"
    end
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

local function GenerateMockPlayerData(expectedVersions)
    ---@type [PlayerData]
    local players = {}

    for i = 1, 20 do
        local playerName = "Player" .. i
        local playerVersions = {}

        local scenario = math.random(1, 4)

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

        table.insert(players, {name = playerName, versions = playerVersions})
    end

    return players
end

local function GetPlayerData()
    local groupVersions = Private:GetGroupVersionsTable()

    ---@type [PlayerData]
    local players = {}
    for unit in Private:IterateGroupMembers() do
        local playerName, nameFormat = CoffeeRaidTools:GetNickname(unit)
        local guid = UnitGUID(unit)
        if guid and Private:UnitIsRealPlayer(unit) then
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
---@field showTitle boolean?

---@param container AceGUIContainer
---@param opts DrawRaidContentOptions?
function Private:DrawRaidContent(container, opts)
    local useTestData = opts and opts.useTestData or false
    local showTitle = not opts or opts.showTitle ~= false

    container:SetLayout("Flow")

    ---@type AceGUISimpleGroup
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("List")

    if showTitle then
        headerGroup:AddChild(CreateSpacer())
        headerGroup:AddChild(CreateSectionTitle("Raid Configuration"))
        headerGroup:AddChild(CreateSpacer())
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

    local expectedVersions = Private:GetLocalVersionTable()
    local players
    if useTestData then
        players = GenerateMockPlayerData(expectedVersions)
    else
        players = GetPlayerData()
    end

    for i, player in ipairs(players) do
        local statusText = GenerateStatusText(player.versions, expectedVersions)
        local tooltipText = GenerateTooltipText(player.versions)

        scrollFrame:AddChild(CreateTableRow(player.name, statusText, tooltipText))

        if i < #players then
            scrollFrame:AddChild(CreateSeparator())
        end
    end
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

Private.GenerateStatusText = GenerateStatusText
Private.GenerateTooltipText = GenerateTooltipText

Private:RegisterTab("raid", "Raid", DrawTab, ReleaseTab)
Private:RegisterMessage("VERSIONS_CHANGED", HandleVersionsChanged)

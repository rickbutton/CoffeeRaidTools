---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local function GenerateStatusText(playerVersions, expectedVersions)
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
    
    for _, aura in ipairs(Private.WeakAurasToTrack) do
        if playerVersions[aura.shortcode] ~= expectedVersions[aura.shortcode] then
            local playerVersion = playerVersions[aura.shortcode]
            if playerVersion == "NONE" or not playerVersion then
                table.insert(failures, aura.shortcode)
            else
                table.insert(failures, aura.shortcode .. "=" .. playerVersion)
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
    
    for _, addon in ipairs(Private.AddonsToTrack) do
        table.insert(entries, addon.shortcode .. "=" .. (playerVersions[addon.shortcode] or "NONE"))
    end
    
    for _, aura in ipairs(Private.WeakAurasToTrack) do
        table.insert(entries, aura.shortcode .. "=" .. (playerVersions[aura.shortcode] or "NONE"))
    end
    
    table.insert(entries, "MRTHASH=" .. (playerVersions["MRTHASH"] or "NONE"))
    
    return table.concat(entries, "\n")
end


local function CreateTableRow(playerName, statusText, tooltipText)
    ---@type AceGUISimpleGroup
    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    
    ---@type AceGUILabel
    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(playerName)
    nameLabel:SetFont(GameFontHighlightSmall:GetFont())
    nameLabel:SetRelativeWidth(0.2)
    row:AddChild(nameLabel)
    
    ---@type AceGUIInteractiveLabel
    local statusLabel = AceGUI:Create("InteractiveLabel")
    statusLabel:SetText(statusText)
    statusLabel:SetFont(GameFontHighlightSmall:GetFont())
    statusLabel:SetRelativeWidth(0.8)
    
    if tooltipText and tooltipText ~= "" then
        statusLabel:SetCallback("OnEnter", function()
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

local function GenerateMockPlayerData(expectedVersions)
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
        
        for _, aura in ipairs(Private.WeakAurasToTrack) do
            if scenario == 1 then
                playerVersions[aura.shortcode] = expectedVersions[aura.shortcode]
            elseif scenario == 2 then
                playerVersions[aura.shortcode] = math.random() > 0.7 and "NONE" or expectedVersions[aura.shortcode]
            elseif scenario == 3 then
                if math.random() > 0.5 then
                    playerVersions[aura.shortcode] = expectedVersions[aura.shortcode]
                else
                    playerVersions[aura.shortcode] = math.random() > 0.5 and "NONE" or "20241201"
                end
            else
                playerVersions[aura.shortcode] = "NONE"
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

local function CreateTableHeader()
    ---@type AceGUISimpleGroup
    local header = AceGUI:Create("SimpleGroup")
    header:SetLayout("Flow")
    header:SetFullWidth(true)
    
    ---@type AceGUILabel
    local playerLabel = AceGUI:Create("Label")
    playerLabel:SetText("|cffffd700Player|r")
    playerLabel:SetFont(GameFontNormalSmall:GetFont())
    playerLabel:SetRelativeWidth(0.2)
    header:AddChild(playerLabel)
    
    ---@type AceGUILabel
    local statusLabel = AceGUI:Create("Label")
    statusLabel:SetText("|cffffd700Status|r")
    statusLabel:SetFont(GameFontNormalSmall:GetFont())
    statusLabel:SetRelativeWidth(0.8)
    header:AddChild(statusLabel)
    
    return header
end

local function DrawTab(container)
    container:SetLayout("List")
    
    container:AddChild(CreateTableHeader())
    
    ---@type AceGUIHeading
    local headerSeparator = AceGUI:Create("Heading")
    headerSeparator:SetFullWidth(true)
    container:AddChild(headerSeparator)
    
    ---@type AceGUIScrollFrame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    scrollFrame:SetLayout("List")
    
    local expectedVersions = Private:GetLocalVersionTable()
    local players = GenerateMockPlayerData(expectedVersions)
    
    for i, player in ipairs(players) do
        local statusText = GenerateStatusText(player.versions, expectedVersions)
        local tooltipText = GenerateTooltipText(player.versions)
        
        scrollFrame:AddChild(CreateTableRow(player.name, statusText, tooltipText))
        
        if i < #players then
            ---@type AceGUIHeading
            local separator = AceGUI:Create("Heading")
            separator:SetFullWidth(true)
            scrollFrame:AddChild(separator)
        end
    end
    
    container:AddChild(scrollFrame)
end

Private:RegisterTab("raid", "Raid", DrawTab)


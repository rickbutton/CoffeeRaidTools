---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

local AUTO_DISMISS_SECONDS = 5

---@type AceGUIFrame?
local readyCheckFrame = nil
local readyCheckUseTestData = false
local readyCheckUseTestDataAllGood = false
---@type FunctionContainer?
local autoDismissTicker = nil

local function CancelAutoDismiss()
    if autoDismissTicker then
        autoDismissTicker:Cancel()
        autoDismissTicker = nil
    end
end

local function StartAutoDismiss()
    CancelAutoDismiss()
    if not readyCheckFrame then
        return
    end

    local remaining = AUTO_DISMISS_SECONDS
    readyCheckFrame:SetStatusText("Closing in " .. remaining .. "s...")

    autoDismissTicker = C_Timer.NewTicker(1, function()
        remaining = remaining - 1
        if remaining <= 0 then
            Private:CloseReadyCheckPopup()
        elseif readyCheckFrame then
            readyCheckFrame:SetStatusText("Closing in " .. remaining .. "s...")
        end
    end, AUTO_DISMISS_SECONDS)
end

local function RefreshReadyCheckPopup()
    if readyCheckFrame then
        local alreadyDismissing = autoDismissTicker ~= nil
        readyCheckFrame:ReleaseChildren()
        local allGood = Private:DrawRaidContent(readyCheckFrame, {
            useTestData = readyCheckUseTestData,
            useTestDataAllGood = readyCheckUseTestDataAllGood,
            showTitle = false,
        })
        if allGood then
            if not alreadyDismissing then
                StartAutoDismiss()
            end
        else
            CancelAutoDismiss()
            readyCheckFrame:SetStatusText("")
        end
    end
end

function Private:CloseReadyCheckPopup()
    CancelAutoDismiss()
    if readyCheckFrame then
        AceGUI:Release(readyCheckFrame)
        readyCheckFrame = nil
    end
end

---@param useTestData boolean?
---@param useTestDataAllGood boolean?
function Private:OpenReadyCheckPopup(useTestData, useTestDataAllGood)
    if readyCheckFrame then
        return
    end
    if not useTestData and not useTestDataAllGood and Private:IsInCombat() then
        return
    end

    ---@type AceGUIFrame
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Coffee Raid Tools - Ready Check")
    frame:SetStatusText("")
    frame:SetLayout("Flow")
    frame:SetWidth(500)
    frame:SetHeight(400)
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget)
        CancelAutoDismiss()
        AceGUI:Release(widget)
        readyCheckFrame = nil
    end)

    readyCheckFrame = frame
    readyCheckUseTestData = useTestData or false
    readyCheckUseTestDataAllGood = useTestDataAllGood or false
    RefreshReadyCheckPopup()
end

local function IsInCoffeeRaid()
    local totalMembers = 0
    local coffeeMembers = 0
    for unit in Private:IterateGroupMembers() do
        if Private:UnitIsRealPlayer(unit) then
            totalMembers = totalMembers + 1
            local guildName = Private.GetGuildInfo(unit)
            if not issecretvalue(guildName) and guildName == "Coffee" then
                coffeeMembers = coffeeMembers + 1
            end
        end
    end
    return totalMembers > 0 and (coffeeMembers / totalMembers) > 0.5
end

Private.IsInCoffeeRaid = IsInCoffeeRaid

local function ShouldShowPopup()
    local setting = Private.db.readyCheckPopup
    if setting == "never" then
        return false
    elseif setting == "always" then
        return true
    elseif setting == "inraid" then
        return Private.IsInRaid()
    elseif setting == "inraidcoffee" then
        return Private.IsInRaid() and Private.IsInCoffeeRaid()
    end
    return false
end

Private.ShouldShowPopup = ShouldShowPopup

local function HandleReadyCheck()
    if ShouldShowPopup() then
        Private:OpenReadyCheckPopup(false)
    end
end

local function HandleReadyCheckFinished()
    Private:CloseReadyCheckPopup()
end

Private:RegisterEvent("READY_CHECK", HandleReadyCheck)
Private:RegisterEvent("READY_CHECK_FINISHED", HandleReadyCheckFinished)
Private:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    Private:CloseReadyCheckPopup()
end)
Private:RegisterEvent("GROUP_ROSTER_UPDATE", RefreshReadyCheckPopup)
Private:RegisterMessage("VERSIONS_CHANGED", RefreshReadyCheckPopup)

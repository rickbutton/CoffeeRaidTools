---@class Private
local Private = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")

---@type AceGUIFrame?
local readyCheckFrame = nil

function Private:CloseReadyCheckPopup()
    if readyCheckFrame then
        AceGUI:Release(readyCheckFrame)
        readyCheckFrame = nil
    end
end

---@param useTestData boolean?
function Private:OpenReadyCheckPopup(useTestData)
    if readyCheckFrame then return end

    ---@type AceGUIFrame
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Coffee Raid Tools - Ready Check")
    frame:SetStatusText("")
    frame:SetLayout("Flow")
    frame:SetWidth(500)
    frame:SetHeight(400)
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        readyCheckFrame = nil
    end)

    Private:DrawRaidContent(frame, { useTestData = useTestData, showTitle = false })

    readyCheckFrame = frame
end

local function IsInCoffeeRaid()
    local totalMembers = 0
    local coffeeMembers = 0
    for unit in Private:IterateGroupMembers() do
        if Private:UnitIsRealPlayer(unit) then
            totalMembers = totalMembers + 1
            local guildName = GetGuildInfo(unit)
            if guildName == "Coffee" then
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
        return IsInRaid()
    elseif setting == "inraidcoffee" then
        return IsInRaid() and Private.IsInCoffeeRaid()
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

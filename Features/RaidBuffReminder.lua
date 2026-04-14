---@class Private
local Private = select(2, ...)
---@type Blizz
local Blizz = Private.Blizz

local INSTANCE_QUEST_MAP = {
    [2912] = 93922, -- Voidspire
    [2939] = 93923, -- Dreamrift
    [2913] = 93924, -- March on Quel'Danas
}

local BUFF_QUEST_IDS = {}
for _, questID in pairs(INSTANCE_QUEST_MAP) do
    BUFF_QUEST_IDS[questID] = true
end

local reminderFrame = nil

local function ShowReminder()
    if reminderFrame then
        reminderFrame:Show()
        return
    end

    reminderFrame = Blizz.CreateFrame("Frame", nil, Blizz.UIParent)
    reminderFrame:SetAllPoints()
    reminderFrame:SetFrameStrata("HIGH")

    local text = reminderFrame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", 0, 0)
    text:SetFont(Blizz.GameFontNormalLarge:GetFont(), 48, "OUTLINE")
    text:SetTextColor(1, 0.2, 0.2, 1)
    text:SetText("GET RAID BUFF")

    reminderFrame:Show()
end

local function HideReminder()
    if reminderFrame then
        reminderFrame:Hide()
    end
end

local function Update()
    local _, _, _, _, _, _, _, instanceID = Blizz.GetInstanceInfo()
    local questID = INSTANCE_QUEST_MAP[instanceID]

    if questID and not Blizz.IsQuestFlaggedCompleted(questID) then
        Private:DebugPrint("RaidBuff: showing reminder, instance", instanceID, "quest", questID)
        ShowReminder()
    else
        Private:DebugPrint("RaidBuff: hiding reminder, instance", instanceID, "quest", tostring(questID))
        HideReminder()
    end
end

Private:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
Private:RegisterEvent("ZONE_CHANGED_NEW_AREA", Update)
Private:RegisterEvent("QUEST_TURNED_IN", function(_, questID)
    Private:DebugPrint("RaidBuff: QUEST_TURNED_IN", questID)
    if BUFF_QUEST_IDS[questID] then
        Private:DebugPrint("RaidBuff: buff quest completed, hiding reminder")
        HideReminder()
    end
end)

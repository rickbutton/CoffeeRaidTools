---@class Private
local Private = select(2, ...)

local BREAK_IMAGES = {
    "Interface\\AddOns\\CoffeeRaidTools\\Media\\Break\\break0",
    "Interface\\AddOns\\CoffeeRaidTools\\Media\\Break\\break1",
    "Interface\\AddOns\\CoffeeRaidTools\\Media\\Break\\break2",
    "Interface\\AddOns\\CoffeeRaidTools\\Media\\Break\\break3",
}

---@type Frame?
local breakFrame = nil
---@type FontString?
local breakTimerText = nil
---@type FunctionContainer?
local countdownTicker = nil
local breakEndTime = 0

local function CloseBreakDisplay()
    if countdownTicker then
        countdownTicker:Cancel()
        countdownTicker = nil
    end
    if breakFrame then
        breakFrame:Hide()
        breakFrame = nil
        breakTimerText = nil
    end
end

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

local function UpdateCountdown()
    if not breakFrame or not breakTimerText then
        return
    end

    local remaining = math.ceil(breakEndTime - GetTime())
    if remaining <= 0 then
        CloseBreakDisplay()
        return
    end

    breakTimerText:SetText(FormatTime(remaining))
end

local function ShowBreakDisplay(seconds)
    CloseBreakDisplay()

    local imageIndex = math.random(1, #BREAK_IMAGES)
    local imagePath = BREAK_IMAGES[imageIndex]

    local frame = CreateFrame("Frame", "CoffeeRaidToolsBreakFrame", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetSize(400, 480)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -UIParent:GetHeight() * 0.15)
    frame:EnableMouse(false)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
    label:SetPoint("TOP", frame, "TOP", 0, 0)
    label:SetText("Break Time!")
    label:SetTextColor(0.8, 0.8, 0.8, 1)

    local timer = frame:CreateFontString(nil, "OVERLAY")
    timer:SetFont(STANDARD_TEXT_FONT, 40, "OUTLINE")
    timer:SetPoint("TOP", label, "BOTTOM", 0, -4)
    timer:SetTextColor(1, 1, 1, 1)

    local image = frame:CreateTexture(nil, "ARTWORK")
    image:SetTexture(imagePath)
    image:SetSize(400, 400)
    image:SetPoint("TOP", timer, "BOTTOM", 0, -10)
    image:SetTexCoord(0, 1, 0, 1)

    breakFrame = frame
    breakTimerText = timer
    breakEndTime = GetTime() + seconds

    UpdateCountdown()
    countdownTicker = C_Timer.NewTicker(1, UpdateCountdown)
end

---@param seconds number
local function HandleBreakStart(_, _, seconds) ---@diagnostic disable-line: unused-local
    if seconds and seconds > 0 then
        ShowBreakDisplay(seconds)
    end
end

local function HandleBreakStop()
    CloseBreakDisplay()
end

Private:RegisterMessage("BigWigs_StartBreak", HandleBreakStart)
Private:RegisterMessage("BigWigs_StopBreak", HandleBreakStop)

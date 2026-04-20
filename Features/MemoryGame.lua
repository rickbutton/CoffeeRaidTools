---@class Private
local Private = select(2, ...)

local ENCOUNTER_ID = 3183
local RUNE_ICON_SIZE = 46
local RUNE_ICON_FONT_SIZE = 12
local ICON_INSET = 2
local HIGHLIGHT_ALPHA = 0.10
local SLOT_GAP = 7
local PAD = 10
local CLOCK_FRAME_SIZE = 242
local HIDE_DELAY = 20

local CLOCK_POSITIONS = {
    { x = 50, y = 68 }, -- 1: top right
    { x = 78, y = -2 }, -- 2: right
    { x = 0, y = -68 }, -- 3: bottom center
    { x = -78, y = -2 }, -- 4: left
    { x = -50, y = 68 }, -- 5: top left
}

local C = {
    bg = { 0.08, 0.08, 0.10, 0.97 },
    border = { 0.20, 0.20, 0.24, 1.0 },
    slotEmpty = { 0.10, 0.10, 0.13, 1.0 },
    slotBorder = { 0.25, 0.25, 0.30, 1.0 },
    slotActive = { 0.30, 0.48, 0.75, 1.0 },
}

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local SPRITE_SHEET_ID = 7412681
local SPRITE_SHEET_SIZE = 512

--- Each rune sends its sprite-sheet coordinates via /raid. The message content
--- identifies which rune was clicked.
local RUNES = {
    { coords = "27:107:299:374" }, -- Circle
    { coords = "22:98:377:507" }, -- Diamond
    { coords = "18:112:3:86" }, -- Triangle
    { coords = "23:105:86:201" }, -- T
    { coords = "11:123:210:291" }, -- Cross
}

--- Timer data per difficulty. Each entry has the time (seconds from pull) and
--- whether the clock fills in reverse order (slots 5→1 instead of 1→5).
---@type table<number, {time: number, reversed: boolean}[]>
local MEMORY_GAME_TIMERS = {
    [14] = {
        { time = 10, reversed = false },
        { time = 80, reversed = false },
        { time = 150, reversed = false },
    },
    [15] = {
        { time = 10, reversed = false },
        { time = 80, reversed = false },
        { time = 150, reversed = false },
    },
}

-- State
local pickerFrame = nil
local clockFrame = nil
local clockSlots = {}
local clockFontStrings = {}
local clockNumbers = {}
local runeCount = 0
local inverted = false
local activeTimers = {}
local hideTimer = nil
local encounterActive = false
local testMode = false
local pickerButtons = {}
local chatHandlers = {}

local function CancelAllTimers()
    for i, timer in ipairs(activeTimers) do
        if timer and timer.Cancel then
            timer:Cancel()
        end
        activeTimers[i] = nil
    end
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

local function SavePosition(dbKey, frame)
    local cx = frame:GetLeft() + frame:GetWidth() / 2
    local cy = frame:GetBottom() + frame:GetHeight() / 2
    local parentCx = UIParent:GetWidth() / 2
    local parentCy = UIParent:GetHeight() / 2
    local x = cx - parentCx
    local y = cy - parentCy
    Private:DebugPrint("MemoryGame SavePosition", dbKey, "x=", x, "y=", y)
    Private.db.memoryGamePositions[dbKey] = { x = x, y = y }
end

local function RestorePosition(dbKey, frame)
    local saved = Private.db.memoryGamePositions[dbKey]
    if saved then
        Private:DebugPrint("MemoryGame RestorePosition", dbKey, "x=", saved.x, "y=", saved.y)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", nil, "CENTER", saved.x, saved.y)
    else
        Private:DebugPrint("MemoryGame RestorePosition", dbKey, "no saved position")
    end
end

local function SetFrameLocked(frame, locked)
    frame:SetMovable(not locked)
    frame:EnableMouse(not locked)
    if locked then
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
    else
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
    end
end

local function UpdateSlotNumbers()
    for i = 1, #RUNES do
        if clockNumbers[i] then
            local label = inverted and (#RUNES - i + 1) or i
            clockNumbers[i]:SetText(tostring(label))
            clockNumbers[i]:Show()
        end
    end
end

local function ResetClock()
    runeCount = 0
    for i = 1, #RUNES do
        if clockFontStrings[i] then
            clockFontStrings[i]:SetText("")
            clockFontStrings[i]:Hide()
        end
        if clockSlots[i] then
            clockSlots[i]:SetBackdropBorderColor(unpack(C.slotBorder))
        end
    end
    UpdateSlotNumbers()
    if clockFrame then
        clockFrame:Hide()
    end
end

local RUNE_ESCAPE_PREFIX = string.format(
    "|T%d:%d:%d:0:0:%d:%d:",
    SPRITE_SHEET_ID,
    RUNE_ICON_SIZE - ICON_INSET * 2,
    RUNE_ICON_SIZE - ICON_INSET * 2,
    SPRITE_SHEET_SIZE,
    SPRITE_SHEET_SIZE
)

--- Display a rune in a clock slot. msg is the secret coordinate string from chat.
local function DisplayRune(slot, msg)
    if not clockFrame then
        return
    end

    if not clockFontStrings[slot] then
        local cs = clockSlots[slot]
        local fs = cs:CreateFontString(nil, "ARTWORK")
        fs:SetFont("Fonts\\FRIZQT__.TTF", RUNE_ICON_FONT_SIZE)
        fs:SetPoint("CENTER", cs, "CENTER", 0, 0)
        clockFontStrings[slot] = fs
    end

    if clockNumbers[slot] then
        clockNumbers[slot]:Hide()
    end
    clockFontStrings[slot]:SetFormattedText("%s%s|t", RUNE_ESCAPE_PREFIX, msg)
    clockFontStrings[slot]:Show()
    clockSlots[slot]:SetBackdropBorderColor(unpack(C.slotActive))
end

local function ShowPicker()
    if pickerFrame and Private.db.memoryGamePicker then
        pickerFrame:SetAlpha(1)
    end
end

local function HidePicker()
    if pickerFrame then
        pickerFrame:SetAlpha(0)
    end
end

local function OnRuneDetected(msg)
    if not encounterActive and not testMode then
        return
    end

    runeCount = runeCount + 1
    if runeCount > #RUNES then
        return
    end

    local slot = inverted and (#RUNES - runeCount + 1) or runeCount
    DisplayRune(slot, msg)

    if clockFrame then
        clockFrame:Show()
    end

    if testMode then
        return
    end

    if hideTimer then
        hideTimer:Cancel()
    end
    hideTimer = C_Timer.NewTimer(HIDE_DELAY, function()
        ResetClock()
        HidePicker()
        hideTimer = nil
    end)
end

local CHAT_EVENTS = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" }

local function OnChatMessage(_, msg)
    OnRuneDetected(msg)
end

local function RegisterChatEvents()
    for _, event in ipairs(CHAT_EVENTS) do
        chatHandlers[event] = OnChatMessage
        Private:RegisterEvent(event, OnChatMessage)
    end
end

local function UnregisterChatEvents()
    for event, handler in pairs(chatHandlers) do
        Private:UnregisterEvent(event, handler)
    end
    chatHandlers = {}
end

local function BuildClockFrame()
    if clockFrame then
        return
    end

    clockFrame = CreateFrame("Frame", "CRTMemoryClockFrame", UIParent, "BackdropTemplate")
    clockFrame:SetSize(CLOCK_FRAME_SIZE, CLOCK_FRAME_SIZE)
    clockFrame:SetPoint("CENTER", nil, "CENTER", -400, 200)
    clockFrame:SetClampedToScreen(true)
    clockFrame:SetFrameStrata("MEDIUM")
    clockFrame:SetBackdrop(BACKDROP)
    clockFrame:SetBackdropColor(unpack(C.bg))
    clockFrame:SetBackdropBorderColor(unpack(C.border))

    RestorePosition("clock", clockFrame)

    for i = 1, #RUNES do
        local pos = CLOCK_POSITIONS[i]
        local slot = CreateFrame("Frame", nil, clockFrame, "BackdropTemplate")
        slot:SetSize(RUNE_ICON_SIZE, RUNE_ICON_SIZE)
        slot:SetBackdrop(BACKDROP)
        slot:SetBackdropColor(unpack(C.slotEmpty))
        slot:SetBackdropBorderColor(unpack(C.slotBorder))
        slot:SetPoint("CENTER", clockFrame, "CENTER", pos.x, pos.y)
        slot:SetScript("OnShow", function(self)
            PixelUtil.SetPoint(self, "CENTER", clockFrame, "CENTER", pos.x, pos.y)
            PixelUtil.SetSize(self, RUNE_ICON_SIZE, RUNE_ICON_SIZE)
        end)
        local num = slot:CreateFontString(nil, "BACKGROUND")
        num:SetFont("Fonts\\FRIZQT__.TTF", 20)
        num:SetPoint("CENTER", slot, "CENTER", 0, 0)
        clockNumbers[i] = num

        clockSlots[i] = slot
    end

    -- Center circle
    local circle = clockFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    circle:SetSize(80, 80)
    circle:SetPoint("CENTER", clockFrame, "CENTER", 0, 0)
    circle:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
    circle:SetVertexColor(0.25, 0.25, 0.30, 0.8)

    -- Tank role icon overlapping the top of the circle
    local tankIcon = clockFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    tankIcon:SetSize(32, 32)
    tankIcon:SetPoint("CENTER", circle, "TOP", 0, 0)
    tankIcon:SetTexture("Interface\\LFGFRAME\\UI-LFG-ICON-ROLES")
    tankIcon:SetTexCoord(0, 66 / 256, 67 / 256, 132 / 256)

    SetFrameLocked(clockFrame, true)
    clockFrame:Hide()
end

local function BuildPickerFrame()
    if pickerFrame then
        return
    end

    local FRAME_W = #RUNES * RUNE_ICON_SIZE + (#RUNES - 1) * SLOT_GAP + PAD * 2 + 2
    local FRAME_H = RUNE_ICON_SIZE + PAD * 2

    pickerFrame = CreateFrame("Frame", "CRTMemoryPickerFrame", UIParent, "BackdropTemplate")
    pickerFrame:SetSize(FRAME_W, FRAME_H)
    pickerFrame:SetPoint("CENTER", nil, "CENTER", -400, 100)
    pickerFrame:SetClampedToScreen(true)
    pickerFrame:SetFrameStrata("MEDIUM")
    pickerFrame:SetBackdrop(BACKDROP)
    pickerFrame:SetBackdropColor(unpack(C.bg))
    pickerFrame:SetBackdropBorderColor(unpack(C.border))

    RestorePosition("picker", pickerFrame)

    for i = 1, #RUNES do
        local rune = RUNES[i]
        local btn =
            CreateFrame("Button", "CRTMemoryRuneBtn" .. i, pickerFrame, "SecureActionButtonTemplate, BackdropTemplate")
        btn:SetSize(RUNE_ICON_SIZE, RUNE_ICON_SIZE)
        btn:SetPoint("BOTTOMLEFT", pickerFrame, "BOTTOMLEFT", PAD + (i - 1) * (RUNE_ICON_SIZE + SLOT_GAP), PAD)
        btn:SetBackdrop(BACKDROP)
        btn:SetBackdropColor(unpack(C.slotEmpty))
        btn:SetBackdropBorderColor(unpack(C.slotBorder))

        local icon = btn:CreateFontString("CRTMemoryRuneBtn" .. i .. "Text", "ARTWORK")
        icon:SetFont("Fonts\\FRIZQT__.TTF", RUNE_ICON_FONT_SIZE)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetText(string.format("%s%s|t", RUNE_ESCAPE_PREFIX, rune.coords))

        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", "/raid " .. rune.coords)
        btn:SetAttribute("useOnKeyDown", false)
        btn:RegisterForClicks("AnyUp", "AnyDown")

        local hi = btn:CreateTexture(nil, "HIGHLIGHT")
        hi:SetAllPoints()
        hi:SetColorTexture(1, 1, 1, HIGHLIGHT_ALPHA)
        btn:SetHighlightTexture(hi)

        btn:SetScript("PostClick", function(_, _, down)
            if down then
                return
            end
            if testMode then
                CoffeeRaidTools:Print("Rune " .. i .. " clicked")
                OnRuneDetected(rune.coords)
            end
        end)

        pickerButtons[i] = btn
    end

    SetFrameLocked(pickerFrame, true)
    pickerFrame:SetAlpha(0)
    pickerFrame:Show()
end

local function BuildFrames()
    BuildClockFrame()
    BuildPickerFrame()
end

local function StartEncounter(difficultyID)
    if encounterActive then
        return
    end
    encounterActive = true

    BuildFrames()

    local timers = MEMORY_GAME_TIMERS[difficultyID]
    if not timers then
        return
    end

    ResetClock()

    -- Schedule picker show/hide at mechanic times
    for _, entry in ipairs(timers) do
        local showTimer = C_Timer.NewTimer(entry.time, function()
            ResetClock()
            inverted = entry.reversed
            UpdateSlotNumbers()
            ShowPicker()
            local autoHide = C_Timer.NewTimer(HIDE_DELAY, function()
                HidePicker()
                ResetClock()
            end)
            tinsert(activeTimers, autoHide)
        end)
        tinsert(activeTimers, showTimer)
    end

    RegisterChatEvents()
end

local function StopEncounter()
    if not encounterActive then
        return
    end
    encounterActive = false
    inverted = false

    CancelAllTimers()
    ResetClock()
    HidePicker()
    UnregisterChatEvents()
end

-- Event handlers

Private:RegisterEvent("ENCOUNTER_START", function(_, encounterID, _, difficultyID)
    if encounterID == ENCOUNTER_ID then
        StartEncounter(difficultyID)
    end
end)

Private:RegisterEvent("ENCOUNTER_END", function(_, encounterID)
    if encounterID == ENCOUNTER_ID then
        StopEncounter()
    end
end)

-- Test mode / unlock support

Private:RegisterMessage("CRT_EncounterTools_SetTestMode", function(_, enabled)
    Private:MemoryGameSetTestMode(enabled)
end)

function Private:MemoryGameSetTestMode(enabled)
    BuildFrames()
    if not pickerFrame or not clockFrame then
        return
    end

    testMode = enabled
    SetFrameLocked(pickerFrame, not enabled)
    SetFrameLocked(clockFrame, not enabled)

    -- Disable/enable picker button macros so they do nothing while unlocked
    for i = 1, #RUNES do
        if pickerButtons[i] then
            if enabled then
                pickerButtons[i]:SetAttribute("type", nil)
            else
                pickerButtons[i]:SetAttribute("type", "macro")
            end
        end
    end
    if enabled then
        ResetClock()
        pickerFrame:SetScript("OnDragStop", function()
            pickerFrame:StopMovingOrSizing()
            SavePosition("picker", pickerFrame)
        end)
        clockFrame:SetScript("OnDragStop", function()
            clockFrame:StopMovingOrSizing()
            SavePosition("clock", clockFrame)
        end)
        pickerFrame:SetAlpha(1)
        clockFrame:Show()
    else
        pickerFrame:SetAlpha(0)
        clockFrame:Hide()
        ResetClock()
    end
end

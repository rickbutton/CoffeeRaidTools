---@class Private
local Private = select(2, ...)

-- Lightblinded Vanguard (3180) — Execution Sentence soak widget.
--
-- Four soak markers laid out in a 2×2 grid:
--   1  2
--   4  3
-- Each slot's marker icon and assigned healers are read from the active
-- NSRT shared reminder (NSAPI:GetReminderString) between
--   coffee-paladins-soak-assign-start
--   coffee-paladins-soak-assign-end
-- Note line N maps to slot N.
--
-- For each healer assigned to a slot we register two private aura anchors
-- (auraIndex=1 and auraIndex=2) to that slot's frame. Per fight data, the
-- only private auras a healer can have are Avenger's Shield (always idx 1)
-- and Execution Sentence (idx 2 if AS is up, else idx 1). AS expires ~2s
-- after the soak lands, so the marker shows AS briefly before resolving
-- to the soak icon — acceptable.

local ENCOUNTER_ID = 3180

local SOAK_START_TAG = "coffee-paladins-soak-assign-start"
local SOAK_END_TAG = "coffee-paladins-soak-assign-end"

local SLOT_SIZE = 64
local ICON_SIZE = 48
local SLOT_GAP = 16
local FRAME_PAD = 8

local FRAME_W = SLOT_SIZE * 2 + SLOT_GAP + FRAME_PAD * 2
local FRAME_H = SLOT_SIZE * 2 + SLOT_GAP + FRAME_PAD * 2

-- Slot offsets from frame center. Index = note line index.
local SLOT_OFFSETS = {
    { x = -(SLOT_SIZE + SLOT_GAP) / 2, y = (SLOT_SIZE + SLOT_GAP) / 2 }, -- 1: top-left
    { x = (SLOT_SIZE + SLOT_GAP) / 2, y = (SLOT_SIZE + SLOT_GAP) / 2 }, -- 2: top-right
    { x = (SLOT_SIZE + SLOT_GAP) / 2, y = -(SLOT_SIZE + SLOT_GAP) / 2 }, -- 3: bottom-right
    { x = -(SLOT_SIZE + SLOT_GAP) / 2, y = -(SLOT_SIZE + SLOT_GAP) / 2 }, -- 4: bottom-left
}

local C = {
    bg = { 0.08, 0.08, 0.10, 0.85 },
    border = { 0.20, 0.20, 0.24, 1.0 },
    slotEmpty = { 0.10, 0.10, 0.13, 1.0 },
    slotBorder = { 0.25, 0.25, 0.30, 1.0 },
}

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

---@class SoakAssignment
---@field marker string lowercase marker name (e.g. "star")
---@field names string[] healer names as written in the note

---Parse soak assignment lines from a pre-extracted block. Each line is
---passed through Private:ParseMarkerLine.
---@param lines string[]
---@return SoakAssignment[]
local function AssignmentsFromLines(lines)
    local assignments = {}
    for _, line in ipairs(lines) do
        local marker, names = Private:ParseMarkerLine(line)
        if marker then
            tinsert(assignments, { marker = marker, names = names or {} })
        end
    end
    return assignments
end

---Read the active NSRT shared reminder and return parsed soak
---assignments. Returns nil if the reminder is missing or doesn't
---contain the soak block.
---@return SoakAssignment[]?
function Private:GetLBVSoakAssignments()
    local lines = Private:GetNSRTSharedReminderBlock(SOAK_START_TAG, SOAK_END_TAG)
    if not lines then
        return nil
    end
    return AssignmentsFromLines(lines)
end

-- State
local soakFrame = nil
local slotFrames = {}
local slotIcons = {}
local activeAnchors = {}
local encounterActive = false
local testMode = false

local function SavePosition()
    if not soakFrame then
        return
    end
    local cx = soakFrame:GetLeft() + soakFrame:GetWidth() / 2
    local cy = soakFrame:GetBottom() + soakFrame:GetHeight() / 2
    local parentCx = UIParent:GetWidth() / 2
    local parentCy = UIParent:GetHeight() / 2
    Private.db.lightblindedVanguardSoakPosition = { x = cx - parentCx, y = cy - parentCy }
end

local function RestorePosition()
    if not soakFrame then
        return
    end
    local saved = Private.db.lightblindedVanguardSoakPosition
    soakFrame:ClearAllPoints()
    if saved then
        soakFrame:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    else
        soakFrame:SetPoint("CENTER", UIParent, "CENTER", -300, 100)
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
        frame:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            SavePosition()
        end)
    end
end

local function BuildFrame()
    if soakFrame then
        return
    end

    soakFrame = CreateFrame("Frame", "CRTLBVSoakFrame", UIParent, "BackdropTemplate")
    soakFrame:SetSize(FRAME_W, FRAME_H)
    soakFrame:SetClampedToScreen(true)
    soakFrame:SetFrameStrata("MEDIUM")
    soakFrame:SetBackdrop(BACKDROP)
    soakFrame:SetBackdropColor(unpack(C.bg))
    soakFrame:SetBackdropBorderColor(unpack(C.border))

    for i = 1, 4 do
        local off = SLOT_OFFSETS[i]
        local slot = CreateFrame("Frame", "CRTLBVSoakSlot" .. i, soakFrame, "BackdropTemplate")
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)
        slot:SetPoint("CENTER", soakFrame, "CENTER", off.x, off.y)
        slot:SetBackdrop(BACKDROP)
        slot:SetBackdropColor(unpack(C.slotEmpty))
        slot:SetBackdropBorderColor(unpack(C.slotBorder))

        local icon = slot:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
        icon:Hide()

        slotFrames[i] = slot
        slotIcons[i] = icon
    end

    RestorePosition()
    SetFrameLocked(soakFrame, true)
    soakFrame:Hide()
end

local function ClearSlotVisuals()
    for i = 1, 4 do
        if slotIcons[i] then
            slotIcons[i]:SetTexture(nil)
            slotIcons[i]:Hide()
        end
    end
end

---@param assignments SoakAssignment[]
local function ApplyAssignmentsToSlots(assignments)
    ClearSlotVisuals()
    for slotIndex = 1, math.min(4, #assignments) do
        local assignment = assignments[slotIndex]
        local markerIndex = Private:GetMarkerIndex(assignment.marker)
        local texPath = markerIndex and Private:GetMarkerTexturePath(markerIndex)
        if texPath then
            slotIcons[slotIndex]:SetTexture(texPath)
            slotIcons[slotIndex]:Show()
        end
    end
end

local function RemoveAllAnchors()
    for _, anchorID in ipairs(activeAnchors) do
        if anchorID then
            C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
        end
    end
    activeAnchors = {}
end

---@param unit string
---@param slotFrame table
local function AddAnchorsForUnit(unit, slotFrame)
    for auraIndex = 1, 2 do
        local id = C_UnitAuras.AddPrivateAuraAnchor({
            unitToken = unit,
            auraIndex = auraIndex,
            parent = slotFrame,
            isContainer = false,
            showCountdownFrame = true,
            showCountdownNumbers = false,
            iconInfo = {
                iconAnchor = {
                    point = "CENTER",
                    relativeTo = slotFrame,
                    relativePoint = "CENTER",
                    offsetX = 0,
                    offsetY = 0,
                },
                iconWidth = ICON_SIZE,
                iconHeight = ICON_SIZE,
                borderScale = 1,
            },
        })
        if id then
            tinsert(activeAnchors, id)
        else
            Private:DebugPrint("LBVSoak: failed AddPrivateAuraAnchor for", unit, "idx", auraIndex)
        end
    end
end

---@param assignments SoakAssignment[]
local function RegisterAnchors(assignments)
    RemoveAllAnchors()
    for slotIndex = 1, math.min(4, #assignments) do
        local assignment = assignments[slotIndex]
        local slotFrame = slotFrames[slotIndex]
        if slotFrame then
            for _, name in ipairs(assignment.names) do
                local unit = Private:GetUnitForName(name)
                if not unit then
                    Private:DebugPrint("LBVSoak: no unit for", name)
                else
                    if not Private:IsHealer(unit) then
                        Private:DebugPrint("LBVSoak: not a healer:", name, unit)
                    end
                    AddAnchorsForUnit(unit, slotFrame)
                end
            end
        end
    end
end

local function StartEncounter()
    if encounterActive then
        return
    end
    if not Private.db.lightblindedVanguardSoakWidget then
        return
    end
    encounterActive = true

    BuildFrame()

    local assignments = Private:GetLBVSoakAssignments()
    if not assignments or #assignments == 0 then
        Private:DebugPrint("LBVSoak: no soak assignment block in NSRT shared reminder")
        ClearSlotVisuals()
        soakFrame:Show()
        return
    end

    ApplyAssignmentsToSlots(assignments)
    RegisterAnchors(assignments)
    soakFrame:Show()
end

local function StopEncounter()
    if not encounterActive then
        return
    end
    encounterActive = false

    RemoveAllAnchors()
    ClearSlotVisuals()
    if soakFrame then
        soakFrame:Hide()
    end
end

Private:RegisterEvent("ENCOUNTER_START", function(_, encounterID)
    if encounterID == ENCOUNTER_ID then
        StartEncounter()
    end
end)

Private:RegisterEvent("ENCOUNTER_END", function(_, encounterID)
    if encounterID == ENCOUNTER_ID then
        StopEncounter()
    end
end)

-- Test mode: unlock the frame for repositioning. Populates slots from the
-- active NSRT shared reminder (if present) so the user can sanity-check
-- assignments without an active encounter. No PA anchors are added.

function Private:LBVSoakIsTestMode()
    return testMode
end

function Private:LBVSoakSetTestMode(enabled)
    BuildFrame()
    if not soakFrame then
        return
    end

    testMode = enabled
    SetFrameLocked(soakFrame, not enabled)

    if enabled then
        local assignments = Private:GetLBVSoakAssignments()
        if assignments and #assignments > 0 then
            ApplyAssignmentsToSlots(assignments)
        else
            ClearSlotVisuals()
        end
        soakFrame:Show()
    else
        if not encounterActive then
            ClearSlotVisuals()
            soakFrame:Hide()
        end
    end
end

---@class Private
local Private = select(2, ...)

-- Generic helpers for parsing tagged blocks out of shared notes (MRT or
-- NSRT) and translating raid-target marker names into texture paths /
-- inline icon escapes. Encounter-specific consumers live in
-- EncounterTools/ and call ExtractNoteBlock with their own sentinels.

---@type table<string, number>
local MARKER_NAME_TO_INDEX = {
    star = 1,
    circle = 2,
    diamond = 3,
    triangle = 4,
    moon = 5,
    square = 6,
    cross = 7,
    skull = 8,
}

local MARKER_TEXTURE_PREFIX = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"

---Return the icon index (1-8) for a marker name like "star" or "skull",
---or nil if the name isn't one of the recognized eight.
---@param name string
---@return number?
function Private:GetMarkerIndex(name)
    if not name then
        return nil
    end
    return MARKER_NAME_TO_INDEX[name:lower()]
end

---Return the raid target texture path for a marker index (1-8), or nil
---if the index is out of range.
---@param index number
---@return string?
function Private:GetMarkerTexturePath(index)
    if not index or index < 1 or index > 8 then
        return nil
    end
    return MARKER_TEXTURE_PREFIX .. index
end

---Return an inline icon escape (|T...|t) for a marker name suitable for
---FontString:SetText. Returns the original `{name}` literal if the name
---isn't recognized so the user sees the failure in-game.
---@param markerName string
---@param size? number
---@return string
function Private:GetMarkerInlineIcon(markerName, size)
    local index = Private:GetMarkerIndex(markerName)
    if not index then
        return "{" .. (markerName or "?") .. "}"
    end
    local pixels = size or 0
    return string.format("|T%s%d:%d:%d|t", MARKER_TEXTURE_PREFIX, index, pixels, pixels)
end

local function escapePattern(s)
    return s:gsub("[%-%.%%%+%*%?%[%]%^%$%(%)]", "%%%1")
end

---Return the lines between `startTag` and `endTag` in `text`, or nil if
---either tag is missing. Tags must appear on their own line.
---@param text string
---@param startTag string
---@param endTag string
---@return string[]?
function Private:ExtractNoteBlock(text, startTag, endTag)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    local startPattern = "\n?" .. escapePattern(startTag) .. "[^\n]*\n"
    local endPattern = "\n?" .. escapePattern(endTag) .. "[^\n]*"

    local _, blockStart = text:find(startPattern)
    if not blockStart then
        return nil
    end

    local blockEnd = text:find(endPattern, blockStart + 1)
    if not blockEnd then
        return nil
    end

    local block = text:sub(blockStart + 1, blockEnd - 1)
    local lines = {}
    for line in block:gmatch("[^\n]+") do
        local trimmed = line:trim()
        if trimmed ~= "" then
            tinsert(lines, trimmed)
        end
    end
    return lines
end

---Parse a single assignment line of the form "{marker} Name1 Name2 ...".
---Returns the marker name (without braces, lowercase) and the list of
---names, or nil if the line doesn't start with a valid marker.
---@param line string
---@return string?, string[]?
function Private:ParseMarkerLine(line)
    if type(line) ~= "string" then
        return nil, nil
    end
    local marker, rest = line:match("^{(%a+)}%s*(.*)$")
    if not marker then
        return nil, nil
    end
    if not MARKER_NAME_TO_INDEX[marker:lower()] then
        return nil, nil
    end
    local names = {}
    for token in (rest or ""):gmatch("%S+") do
        tinsert(names, token)
    end
    return marker:lower(), names
end

---Return the active NSRT shared reminder text, or nil if NSRT isn't
---loaded or hasn't published one. This is the same string the version
---hash check feeds into StringHash, so consumers stay in sync with the
---reminder that's actually broadcast raid-wide.
---@return string?
function Private:GetNSRTSharedReminder()
    if not C_AddOns.IsAddOnLoaded("NorthernSkyRaidTools") then
        return nil
    end
    if not NSAPI or not NSAPI.GetReminderString then
        return nil
    end
    local _, shared = NSAPI:GetReminderString()
    if type(shared) ~= "string" or shared == "" then
        return nil
    end
    return shared
end

---Pull the active NSRT shared reminder and return the lines between the
---given tags, or nil if the reminder is missing or the block isn't
---present.
---@param startTag string
---@param endTag string
---@return string[]?
function Private:GetNSRTSharedReminderBlock(startTag, endTag)
    local text = Private:GetNSRTSharedReminder()
    if not text then
        return nil
    end
    return Private:ExtractNoteBlock(text, startTag, endTag)
end

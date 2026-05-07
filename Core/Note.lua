---@class Private
local Private = select(2, ...)

-- Parse blocks out of the MRT shared note (VMRT.Note.Text1). Each consumer
-- declares its own start/end sentinel; the helper below reads the raw note
-- and returns just the lines between them. Soak assignments use one such
-- block and pass each line through ParseMarkerLine.

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

local SOAK_START_TAG = "coffee-paladins-soak-assign-start"
local SOAK_END_TAG = "coffee-paladins-soak-assign-end"

---@class SoakAssignment
---@field marker string lowercase marker name (e.g. "star")
---@field names string[] healer names as written in the note

---Parse the soak assignment block from arbitrary note text. Returns up to
---four assignments in note order, or nil if the block is missing.
---@param text string
---@return SoakAssignment[]?
function Private:ParseSoakAssignments(text)
    local lines = Private:ExtractNoteBlock(text, SOAK_START_TAG, SOAK_END_TAG)
    if not lines then
        return nil
    end
    local assignments = {}
    for _, line in ipairs(lines) do
        local marker, names = Private:ParseMarkerLine(line)
        if marker then
            tinsert(assignments, { marker = marker, names = names or {} })
        end
    end
    return assignments
end

---Convenience wrapper: read the MRT shared note (VMRT.Note.Text1) and
---return parsed soak assignments. Returns nil if MRT isn't loaded or the
---block isn't present.
---@return SoakAssignment[]?
function Private:GetSoakAssignmentsFromMRT()
    local note = _G.VMRT and _G.VMRT.Note and _G.VMRT.Note.Text1
    if type(note) ~= "string" then
        return nil
    end
    return Private:ParseSoakAssignments(note)
end

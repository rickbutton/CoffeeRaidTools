---@class Private
local Private = select(2, ...)

---@param reversed boolean?
---@param forceParty boolean?
function Private:IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and Private.IsInRaid()) and "raid" or "party"
    local numGroupMembers = unit == "party" and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)
    return function()
        local ret
        if i == 0 and unit == "party" then
            ret = "player"
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end
        i = i + (reversed and -1 or 1)
        return ret
    end
end

---@param unit string
function Private:UnitIsRealPlayer(unit)
    local guid = Private.UnitGUID(unit)
    return guid and guid:find("^Player-") ~= nil
end

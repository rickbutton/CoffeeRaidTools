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

---@param unit UnitToken
---@return boolean
function Private:IsSecretUnit(unit)
    return C_Secrets.ShouldUnitIdentityBeSecret(unit)
end

---@return boolean
function Private:IsInCombat()
    return InCombatLockdown()
end

---@return boolean
function Private:UseTestGroupVersionList()
    return Private.db.devMode and Private.db.testGroupVersionList
end

-- Override AceEvent registration on Private to support multiple handlers per
-- event/message. AceEvent normally allows only one handler per (self, event)
-- pair; these overrides maintain a list of handlers keyed by function reference
-- and dispatch to all of them from a single AceEvent registration.
--
-- UnregisterEvent/UnregisterMessage accept an optional function reference to
-- remove a specific handler. Without it, all handlers for that event are removed.

local AceRegisterEvent = Private.RegisterEvent
local AceUnregisterEvent = Private.UnregisterEvent
local AceRegisterMessage = Private.RegisterMessage
local AceUnregisterMessage = Private.UnregisterMessage

---@type table<string, function[]>
local eventHandlers = {}
---@type table<string, function[]>
local messageHandlers = {}

---@param self table
---@param event string
---@param handler function
function Private.RegisterEvent(self, event, handler)
    if self ~= Private then
        return AceRegisterEvent(self, event, handler)
    end
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        AceRegisterEvent(Private, event, function(eventName, ...)
            for _, fn in ipairs(eventHandlers[event]) do
                fn(eventName, ...)
            end
        end)
    end
    table.insert(eventHandlers[event], handler)
end

---@param self table
---@param event string
---@param handler? function
function Private.UnregisterEvent(self, event, handler)
    if self ~= Private then
        return AceUnregisterEvent(self, event)
    end
    if not eventHandlers[event] then
        return
    end
    if handler then
        for i, fn in ipairs(eventHandlers[event]) do
            if fn == handler then
                table.remove(eventHandlers[event], i)
                break
            end
        end
        if #eventHandlers[event] == 0 then
            eventHandlers[event] = nil
            AceUnregisterEvent(Private, event)
        end
    else
        eventHandlers[event] = nil
        AceUnregisterEvent(Private, event)
    end
end

---@param self table
---@param message string
---@param handler function
function Private.RegisterMessage(self, message, handler)
    if self ~= Private then
        return AceRegisterMessage(self, message, handler)
    end
    if not messageHandlers[message] then
        messageHandlers[message] = {}
        AceRegisterMessage(Private, message, function(messageName, ...)
            for _, fn in ipairs(messageHandlers[message]) do
                fn(messageName, ...)
            end
        end)
    end
    table.insert(messageHandlers[message], handler)
end

---@param self table
---@param message string
---@param handler? function
function Private.UnregisterMessage(self, message, handler)
    if self ~= Private then
        return AceUnregisterMessage(self, message)
    end
    if not messageHandlers[message] then
        return
    end
    if handler then
        for i, fn in ipairs(messageHandlers[message]) do
            if fn == handler then
                table.remove(messageHandlers[message], i)
                break
            end
        end
        if #messageHandlers[message] == 0 then
            messageHandlers[message] = nil
            AceUnregisterMessage(Private, message)
        end
    else
        messageHandlers[message] = nil
        AceUnregisterMessage(Private, message)
    end
end

---@param unit string
function Private:UnitIsRealPlayer(unit)
    local guid = Private.UnitGUID(unit)
    if issecretvalue(guid) then
        return false
    end
    return guid and guid:find("^Player-") ~= nil
end

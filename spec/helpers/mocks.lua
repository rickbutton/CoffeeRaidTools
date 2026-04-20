-- Mocking helper modeled after the old TestRunner's Replace() pattern.
-- Only used for targets we own (Private, Blizz, CoffeeRaidTools, _G flag slots).
-- Spec files call Replace() inside an `it` block; after_each(Restore) cleans up.

local M = {}

local restorers = {}

--- Replace a field on a table and record the original for later restoration.
--- Overload: when called as (name, value), replaces _G[name].
function M.Replace(tableOrName, keyOrValue, replacement)
    if type(tableOrName) == "string" then
        table.insert(restorers, { target = _G, key = tableOrName, original = _G[tableOrName] })
        _G[tableOrName] = keyOrValue
    else
        table.insert(restorers, { target = tableOrName, key = keyOrValue, original = tableOrName[keyOrValue] })
        tableOrName[keyOrValue] = replacement
    end
end

function M.Restore()
    for i = #restorers, 1, -1 do
        local r = restorers[i]
        r.target[r.key] = r.original
    end
    restorers = {}
end

_G.Replace = M.Replace
_G.Restore = M.Restore

return M

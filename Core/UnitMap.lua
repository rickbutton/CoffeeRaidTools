---@class Private
local Private = select(2, ...)

-- Maintain a name <-> unit token mapping for the current group/raid. Other
-- features (e.g. soak assignments parsed out of the MRT note) need to resolve
-- "Nickname" / "Charname" / "Charname-Realm" strings to a `raid{N}` unit.
--
-- Updates run on GROUP_ROSTER_UPDATE outside combat. If we're in combat when
-- the roster changes, the rebuild is deferred to PLAYER_REGEN_ENABLED so we
-- don't race with secure code paths.

---@type table<string, string>
local nameToUnit = {}

---@type table<string, string>
local unitToName = {}

local pendingRebuild = false

local function ClearMaps()
    wipe(nameToUnit)
    wipe(unitToName)
end

local function StoreName(name, unit)
    if not name or name == "" then
        return
    end
    if issecretvalue(name) then
        return
    end
    nameToUnit[name] = unit
end

local function Rebuild()
    pendingRebuild = false
    ClearMaps()

    if not IsInGroup() and not IsInRaid() then
        return
    end

    for unit in Private:IterateGroupMembers() do
        if UnitExists(unit) then
            local nickname = CoffeeRaidTools:GetNickname(unit, true)
            local fullName = CoffeeRaidTools:GetCharacterNameWithRealm(unit)
            local bareName = UnitNameUnmodified(unit)

            local canonical = nickname or fullName or bareName
            if canonical and not issecretvalue(canonical) then
                unitToName[unit] = canonical
            end

            StoreName(nickname, unit)
            StoreName(fullName, unit)
            StoreName(bareName, unit)
        end
    end
end

local function RequestRebuild()
    if InCombatLockdown() then
        pendingRebuild = true
        return
    end
    Rebuild()
end

---Resolve a character name, character-realm string, or nickname to a unit
---token. Returns nil if the name isn't in the current group.
---@param name string
---@return string?
function Private:GetUnitForName(name)
    if not name or name == "" then
        return nil
    end
    return nameToUnit[name]
end

---Return the canonical display name for a unit (nickname when available,
---character-realm fallback). Returns nil if the unit isn't tracked.
---@param unit string
---@return string?
function Private:GetNameForUnit(unit)
    if not unit then
        return nil
    end
    return unitToName[unit]
end

---Test-only: drop both maps.
function Private.UnitMapReset()
    ClearMaps()
    pendingRebuild = false
end

---Test-only: trigger a rebuild from the current mocked group state.
function Private.UnitMapRebuild()
    Rebuild()
end

Private:RegisterEvent("GROUP_ROSTER_UPDATE", RequestRebuild)
Private:RegisterEvent("PLAYER_ENTERING_WORLD", RequestRebuild)
Private:RegisterEvent("PLAYER_LOGIN", RequestRebuild)
Private:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    if pendingRebuild then
        Rebuild()
    end
end)

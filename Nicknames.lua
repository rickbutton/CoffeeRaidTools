---@class Private
local Private = select(2, ...)

---@param unit string
function CoffeeRaidTools:GetNameFormatString(unit)
    local formatString = "%s"
    local classFileName = UnitClassBase(unit)

    if classFileName then
        formatString = string.format("|c%s%%s|r", RAID_CLASS_COLORS[classFileName].colorStr)
    end
    return formatString
end

---@param unit string
function CoffeeRaidTools:GetCharacterNameWithRealm(unit)
    local name, realm = UnitNameUnmodified(unit)
    if issecretvalue(name) then
        return name
    end
    if not realm then
        realm = GetNormalizedRealmName()
    end
    if not realm then
        return name
    end
    return string.format("%s-%s", name, realm)
end

---@param unit string
---@param noFormat? boolean
function CoffeeRaidTools:GetNickname(unit, noFormat)
    local format = "%s"
    if not noFormat then
        format = CoffeeRaidTools:GetNameFormatString(unit)
    end

    if TimelineReminders then
        local name = TimelineReminders:GetNickname(unit)
        return name, format
    else
        local name = CoffeeRaidTools:GetCharacterNameWithRealm(unit)
        return name, format
    end
end

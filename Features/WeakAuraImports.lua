---@class Private
local Private = select(2, ...)

---@param boss string
---@return WeakAuraImportBossSection?
function Private:GetWeakAuraImportsForBoss(boss)
    for _, section in ipairs(Private.WeakAuraImportSections) do
        if section.boss == boss then
            return section
        end
    end
    return nil
end

---@param importString string
---@return boolean
function Private:ImportWeakAura(importString)
    if type(importString) ~= "string" or importString == "" then
        CoffeeRaidTools:Print("|cffff4040No import string is set for this M33kAura yet.|r")
        return false
    end

    if not M33kAuras or type(M33kAuras.Import) ~= "function" then
        CoffeeRaidTools:Print("|cffff4040M33kAuras is not loaded. Install M33kAuras to import.|r")
        return false
    end

    M33kAuras.Import(importString)
    return true
end

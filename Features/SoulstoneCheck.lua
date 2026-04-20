---@class Private
local Private = select(2, ...)

local SOULSTONE_SPELL_ID = 20707
local WARLOCK_CLASS_ID = 9
local COOLDOWN_THRESHOLD = 30
local BUFF_MIN_REMAINING = 300

function Private.HasSoulstoneOnHealer()
    if C_Secrets.ShouldAurasBeSecret() then
        return true
    end

    local cooldown = C_Spell.GetSpellCooldown(SOULSTONE_SPELL_ID)
    if cooldown and cooldown.duration ~= 0 then
        local remaining = cooldown.duration + cooldown.startTime - GetTime()
        if remaining > COOLDOWN_THRESHOLD then
            return true
        end
    end

    local spellInfo = C_Spell.GetSpellInfo(SOULSTONE_SPELL_ID)
    if not spellInfo then
        return true
    end

    for unit in Private:IterateGroupMembers() do
        if UnitGroupRolesAssigned(unit) == "HEALER" and UnitIsVisible(unit) then
            local aura = C_UnitAuras.GetAuraDataBySpellName(unit, spellInfo.name)
            if aura then
                local source = aura.sourceUnit
                if UnitExists(source) and UnitIsUnit("player", source) then
                    if aura.expirationTime - GetTime() > BUFF_MIN_REMAINING then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--Private:RegisterMessage("CRT_BigWigs_StartPull", function()
--    local classID = select(3, UnitClass("player"))
--    if classID ~= WARLOCK_CLASS_ID then
--        return
--    end
--
--    if not Private.HasSoulstoneOnHealer() then
--        SendChatMessage("I didn't soulstone a healer! Please Ping Me!", "YELL")
--    end
--end)

---@class Private
local Private = select(2, ...)
---@type Blizz
local Blizz = Private.Blizz

local SOULSTONE_SPELL_ID = 20707
local WARLOCK_CLASS_ID = 9
local COOLDOWN_THRESHOLD = 30
local BUFF_MIN_REMAINING = 300

function Private.HasSoulstoneOnHealer()
    if Blizz.ShouldAurasBeSecret() then
        return true
    end

    local cooldown = Blizz.GetSpellCooldown(SOULSTONE_SPELL_ID)
    if cooldown and cooldown.duration ~= 0 then
        local remaining = cooldown.duration + cooldown.startTime - Blizz.GetTime()
        if remaining > COOLDOWN_THRESHOLD then
            return true
        end
    end

    local spellInfo = Blizz.GetSpellInfo(SOULSTONE_SPELL_ID)
    if not spellInfo then
        return true
    end

    for unit in Private:IterateGroupMembers() do
        if Blizz.UnitGroupRolesAssigned(unit) == "HEALER" and Blizz.UnitIsVisible(unit) then
            local aura = Blizz.GetAuraDataBySpellName(unit, spellInfo.name)
            if aura then
                local source = aura.sourceUnit
                if Blizz.UnitExists(source) and Blizz.UnitIsUnit("player", source) then
                    if aura.expirationTime - Blizz.GetTime() > BUFF_MIN_REMAINING then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--Private:RegisterMessage("CRT_BigWigs_StartPull", function()
--    local classID = select(3, Blizz.UnitClass("player"))
--    if classID ~= WARLOCK_CLASS_ID then
--        return
--    end
--
--    if not Private.HasSoulstoneOnHealer() then
--        Blizz.SendChatMessage("I didn't soulstone a healer! Please Ping Me!", "YELL")
--    end
--end)

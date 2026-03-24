---@class Private
local Private = select(2, ...)

---@return boolean success
local function UpdateBigWigsPrivateAuras()
    if not BigWigs then
        Private:DebugPrint("BigWigsOverrides: BigWigs not loaded, skipping")
        return false
    end
    local soundModule = BigWigs:GetPlugin("Sounds", true)
    if not soundModule or not soundModule.db then
        Private:DebugPrint("BigWigsOverrides: Sounds plugin not available, skipping")
        return false
    end

    local paDB = soundModule.db.profile.privateaura
    local enabled = Private.db.disableConflictingBigWigsPrivateAuraSounds
    Private:DebugPrint("BigWigsOverrides: updating, enabled =", tostring(enabled))
    local disabledCount, revertedCount = 0, 0
    for _, section in ipairs(Private.PrivateAuraSections) do
        if section.bigwigsModule then
            for _, config in ipairs(section.spells) do
                for _, spellID in ipairs(config.spellIDs) do
                    if enabled and not Private.db.disabledPrivateAuras[config.spellIDs[1]] then
                        if not paDB[section.bigwigsModule] then
                            paDB[section.bigwigsModule] = {}
                        end
                        paDB[section.bigwigsModule][spellID] = "None"
                        disabledCount = disabledCount + 1
                    else
                        if paDB[section.bigwigsModule] then
                            paDB[section.bigwigsModule][spellID] = nil
                            revertedCount = revertedCount + 1
                        end
                    end
                end
            end
        end
    end
    Private:DebugPrint("BigWigsOverrides: done, disabled", disabledCount, "reverted", revertedCount)
    return true
end

function Private:UpdateBigWigsPrivateAuras()
    UpdateBigWigsPrivateAuras()
end

local applied = false
local function TryApply()
    if not applied then
        applied = UpdateBigWigsPrivateAuras()
    end
end

Private:RegisterMessage("CRT_BigWigs_CoreEnabled", TryApply)

Private:RegisterMessage("CRT_BigWigs_ProfileUpdate", function()
    applied = false
    TryApply()
end)

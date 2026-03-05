---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

StaticPopupDialogs["CRT_NSRT_IMPORT_RELOAD"] = {
    text = "CoffeeRaidTools needs to reload your UI.",
    button1 = "Reload UI",
    OnAccept = ReloadUI,
    OnShow = function(self)
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        C_Timer.After(0, function()
            self:SetHeight(self:GetHeight() + 10)
        end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    showAlert = true,
}

local ReadyCheckForceTrue = {
    "RepairCheck",
    "GemCheck",
    "EnchantCheck",
    "RaidBuffCheck",
    "CraftedCheck",
    "MissingItemCheck",
    "SoulstoneCheck",
    "ItemLevelCheck",
}

local EncounterAlertIDs = {
    3176, 3177, 3178, 3179, 3180, 3181, 3182, 3183, 3306,
}

local QoLForceTrue = {
    "SoulwellDropped",
    "AutoInvite",
    "ResetBossDisplay",
    "LootBossReminder",
    "CauldronDropped",
    "RepairDropped",
    "FeastDropped",
    "GatewayUseableDisplay",
}

frame:SetScript("OnEvent", function(self, _, addonName)
    if addonName ~= "NorthernSkyRaidTools" then return end
    self:UnregisterAllEvents()

    if not NSRT then return end

    local changed = false

    -- ReadyCheckSettings
    if not NSRT.ReadyCheckSettings then
        NSRT.ReadyCheckSettings = {}
    end
    for _, key in ipairs(ReadyCheckForceTrue) do
        if NSRT.ReadyCheckSettings[key] ~= true then
            Private:DebugPrint("NSRT ReadyCheckSettings." .. key .. ": " .. tostring(NSRT.ReadyCheckSettings[key]) .. " -> true")
            NSRT.ReadyCheckSettings[key] = true
            changed = true
        end
    end

    -- EncounterAlerts
    if not NSRT.EncounterAlerts then
        NSRT.EncounterAlerts = {}
    end
    for _, id in ipairs(EncounterAlertIDs) do
        if not NSRT.EncounterAlerts[id] then
            NSRT.EncounterAlerts[id] = {}
        end
        if NSRT.EncounterAlerts[id].enabled ~= true then
            Private:DebugPrint("NSRT EncounterAlerts[" .. id .. "].enabled: " .. tostring(NSRT.EncounterAlerts[id].enabled) .. " -> true")
            NSRT.EncounterAlerts[id].enabled = true
            changed = true
        end
    end

    -- QoL
    if not NSRT.QoL then
        NSRT.QoL = {}
    end
    for _, key in ipairs(QoLForceTrue) do
        if NSRT.QoL[key] ~= true then
            Private:DebugPrint("NSRT QoL." .. key .. ": " .. tostring(NSRT.QoL[key]) .. " -> true")
            NSRT.QoL[key] = true
            changed = true
        end
    end

    if changed then
        StaticPopup_Show("CRT_NSRT_IMPORT_RELOAD")
    end
end)

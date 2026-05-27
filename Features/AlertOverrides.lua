---@diagnostic disable: undefined-global

---@class Private
local Private = select(2, ...)

-- Customization overlay for NSRT encounter alerts (new schema).
--
-- After NSRT imports Reloe's alerts on PLAYER_LOGIN, Coffee can force
-- arbitrary field values on specific alerts via this table. Apply is
-- driven by NSRT_ALERT_FULL_UPDATE / NSRT_ALERT_ENCOUNTER_UPDATE callbacks
-- registered in Features/ForceAddonSettings.lua.

---@class AlertOverride
---@field diff integer|integer[]|"all" -- 14 normal, 15 heroic, 16 mythic
---@field internalID string             -- alert key at NSRT.EncounterAlerts[encID][diffID]
---@field fields table                  -- field -> forced value (deep-copied for tables)

-- Helper: looks up the LSM key for a CRT reminder sound. Falls back to a
-- raw "Coffee: <text>" string if Features/ReminderSounds.lua hasn't loaded yet
-- (only happens in tests; production load order in CoffeeRaidTools.toc guarantees
-- ReminderSounds is loaded before this file).
local function COFFEE(text)
    if Private.CoffeeLSMKey then
        return Private.CoffeeLSMKey(text)
    end
    return "|cffff0000Coffee:|r " .. text
end

---@type table<integer, AlertOverride[]>
Private.AlertOverrides = {
    -- [3176] Imperator Averzian
    [3176] = {
        { diff = "all", internalID = "Soaks", fields = { sound = COFFEE("Soak") } },
    },
    -- [3177] Vorasius
    [3177] = {
        { diff = "all", internalID = "Knock", fields = { sound = COFFEE("Knock") } },
        { diff = "all", internalID = "Breath", fields = { sound = COFFEE("Breath") } },
    },
    -- [3178] Vaelgor & Ezzorak
    [3178] = {
        { diff = "all", internalID = "Spread", fields = { sound = COFFEE("Spread") } },
        { diff = "all", internalID = "Tether", fields = { sound = COFFEE("Tether") } },
        { diff = "all", internalID = "Breath", fields = { sound = COFFEE("Breath") } },
    },
    -- [3179] Fallen-King Salhadaar
    [3179] = {
        { diff = "all", internalID = "Beams", fields = { sound = COFFEE("Beams") } },
        { diff = "all", internalID = "Orbs", fields = { sound = COFFEE("Orbs") } },
        { diff = "all", internalID = "CC Adds", fields = { sound = COFFEE("CC Adds") } },
    },
    -- [3180] Lightblinded Vanguard
    [3180] = {
        { diff = "all", internalID = "Sacred Toll", fields = { sound = COFFEE("Sacred Toll") } },
        { diff = "all", internalID = "TauntAlerts", fields = { sound = COFFEE("Taunt") } },
    },
    -- [3181] Crown of the Cosmos
    [3181] = {
        { diff = "all", internalID = "Stop Cast", fields = { sound = COFFEE("Stop Cast") } },
        { diff = "all", internalID = "Bait", fields = { sound = COFFEE("Bait") } },
        { diff = "all", internalID = "Explosion", fields = { sound = COFFEE("Explosion") } },
    },
    -- [3182] Beloren
    [3182] = {
        { diff = "all", internalID = "Gateway", fields = { sound = COFFEE("Gateway") } },
    },
    -- [3183] Midnight Falls
    [3183] = {
        { diff = "all", internalID = "MemoryGame", fields = { sound = COFFEE("Memory Game") } },
        { diff = "all", internalID = "Glaives", fields = { sound = COFFEE("Glaives") } },
        { diff = "all", internalID = "Interrupts", fields = { sound = COFFEE("Interrupts") } },
        { diff = "all", internalID = "P1 Taunt First", fields = { sound = COFFEE("Taunt") } },
        { diff = "all", internalID = "P1 Taunt Second", fields = { sound = COFFEE("Taunt") } },
        { diff = "all", internalID = "P2 Taunts First", fields = { sound = COFFEE("Taunt") } },
        { diff = "all", internalID = "P2 Taunts Second", fields = { sound = COFFEE("Taunt") } },
        { diff = "all", internalID = "Soak Star", fields = { sound = COFFEE("Soak Star") } },
        { diff = "all", internalID = "Soak Orange", fields = { sound = COFFEE("Soak Orange") } },
        { diff = "all", internalID = "Soak Skull", fields = { sound = COFFEE("Soak Skull") } },
        { diff = "all", internalID = "Soak Cross", fields = { sound = COFFEE("Soak X") } },
        { diff = "all", internalID = "HC Soaks", fields = { sound = COFFEE("Soaks") } },
        { diff = "all", internalID = "Move", fields = { sound = COFFEE("Move") } },
        { diff = "all", internalID = "Blazes", fields = { sound = COFFEE("Blazes") } },
        { diff = "all", internalID = "P4 Move", fields = { sound = COFFEE("Move") } },
        { diff = "all", internalID = "Left Memory Game", fields = { sound = COFFEE("Memory Game") } },
        { diff = "all", internalID = "Right Memory Game", fields = { sound = COFFEE("Memory Game") } },
        { diff = "all", internalID = "Left Soaks", fields = { sound = COFFEE("Soaks") } },
        { diff = "all", internalID = "Right Soaks", fields = { sound = COFFEE("Soaks") } },
    },
    -- [3306] Chimaerus the Undreamt God
    [3306] = {
        { diff = "all", internalID = "Debuffs", fields = { sound = COFFEE("Debuffs") } },
    },
}

local DIFF_IDS = { 14, 15, 16 }

local function ResolveDiffs(diff)
    if diff == nil or diff == "all" then
        return DIFF_IDS
    end
    if type(diff) == "number" then
        return { diff }
    end
    return diff
end

---Apply Coffee's alert overrides on top of NSRT's freshly imported alerts.
---@param targetEncID integer? -- when set, only re-apply this encounter's overrides
local function ApplyAlertOverrides(targetEncID)
    if not NSRT or type(NSRT.EncounterAlerts) ~= "table" then
        return
    end
    for encID, overrides in pairs(Private.AlertOverrides or {}) do
        if not targetEncID or encID == targetEncID then
            local encTable = NSRT.EncounterAlerts[encID]
            if encTable then
                for _, override in ipairs(overrides) do
                    for _, diffID in ipairs(ResolveDiffs(override.diff)) do
                        local diffTable = encTable[diffID]
                        local alert = diffTable and diffTable[override.internalID]
                        if alert then
                            for key, value in pairs(override.fields) do
                                local target = type(value) == "table" and CopyTable(value) or value
                                if alert[key] ~= target then
                                    Private:DebugPrint(
                                        string.format(
                                            "NSRT EncounterAlerts[%d][%d][%q].%s: %s -> %s",
                                            encID,
                                            diffID,
                                            tostring(override.internalID),
                                            tostring(key),
                                            tostring(alert[key]),
                                            tostring(target)
                                        )
                                    )
                                    alert[key] = target
                                end
                            end
                        else
                            Private:DebugPrint(
                                string.format(
                                    "CRT alert override skipped: [%d][%d][%q] not imported",
                                    encID,
                                    diffID,
                                    tostring(override.internalID)
                                )
                            )
                        end
                    end
                end
            end
        end
    end
end

Private.ApplyAlertOverrides = ApplyAlertOverrides

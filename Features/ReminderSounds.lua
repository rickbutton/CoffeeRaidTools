---@class Private
local Private = select(2, ...)

---@class ReminderSoundConfig
---@field text string
---@field soundFile string

---@class ReminderSoundBossSection
---@field boss string
---@field encounterID? number
---@field reminders ReminderSoundConfig[]

-- Data is generated into ReminderSoundsData.lua by pnpm run generate

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if not LSM then
    Private:DebugPrint("ReminderSounds: LibSharedMedia-3.0 not available")
    return
end

local ADDON_MEDIA = "Interface\\AddOns\\CoffeeRaidTools\\Media\\Reminders\\"

for _, section in ipairs(Private.ReminderSoundSections or {}) do
    for _, reminder in ipairs(section.reminders) do
        LSM:Register("sound", reminder.text, ADDON_MEDIA .. reminder.soundFile .. ".mp3")
    end
end

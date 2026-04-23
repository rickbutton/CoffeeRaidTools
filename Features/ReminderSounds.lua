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

local ADDON_MEDIA = "Interface\\AddOns\\CoffeeRaidTools\\Media\\Reminders\\"

---@type table<string, string>
local soundPathByText = {}
for _, section in ipairs(Private.ReminderSoundSections or {}) do
    for _, reminder in ipairs(section.reminders) do
        soundPathByText[reminder.text] = ADDON_MEDIA .. reminder.soundFile .. ".mp3"
    end
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    for text, path in pairs(soundPathByText) do
        LSM:Register("sound", text, path)
    end
else
    Private:DebugPrint("ReminderSounds: LibSharedMedia-3.0 not available")
end

---Play the sound registered for `text` if we have one; otherwise fall back to
---NSRT's TTS so callers always get something audible. Returns the playback
---channel used: "sound", "tts", or nil if neither was available.
---@param text string
---@return "sound"|"tts"|nil
function Private:PlayReminderSound(text)
    local path = soundPathByText[text]
    if path then
        PlaySoundFile(path, "Master")
        return "sound"
    end
    if NSAPI and NSAPI.TTS then
        NSAPI:TTS(text)
        return "tts"
    end
    Private:DebugPrint("PlayReminderSound: no sound and no NSAPI:TTS for", text)
    return nil
end

---@return boolean
function Private:HasReminderSound(text)
    return soundPathByText[text] ~= nil
end

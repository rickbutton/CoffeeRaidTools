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

-- LSM exposure: register every CRT reminder sound under "|cffff0000Coffee:|r <text>"
-- so the new-schema NSRT alert overlay (Features/AlertOverrides.lua) can reference
-- them by LSM key. NSRT strips color codes during lookup, so the colored key still
-- resolves at fire time. Idempotent across reloads.
local COFFEE_LSM_PREFIX = "|cffff0000Coffee:|r "

local function CoffeeLSMKey(text)
    return COFFEE_LSM_PREFIX .. text
end

Private.CoffeeLSMKey = CoffeeLSMKey

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    local registered = {}
    for text, path in pairs(soundPathByText) do
        local key = CoffeeLSMKey(text)
        if not registered[key] then
            registered[key] = true
            LSM:Register("sound", key, path)
        end
    end
end

---Plays the CRT sound for `text` if we own it and the user hasn't disabled it.
---@param text any
---@return boolean played
local function TryPlayOwnedSound(text)
    if type(text) ~= "string" then
        return false
    end
    local path = soundPathByText[text]
    if not path then
        return false
    end
    if Private.db.disabledReminderSounds[text] then
        return false
    end
    local willPlay = PlaySoundFile(path, "Master")
    return willPlay
end

---@param text string
---@return string?
function Private:GetReminderSoundPath(text)
    return soundPathByText[text]
end

---@return boolean
function Private:HasReminderSound(text)
    return soundPathByText[text] ~= nil
end

local originalNSAPITTS

---Play the sound registered for `text` if we have one and it's enabled;
---otherwise fall back to NSRT's TTS. Returns the playback channel used:
---"sound", "tts", or nil if neither was available.
---@param text string
---@return "sound"|"tts"|nil
function Private:PlayReminderSound(text)
    if TryPlayOwnedSound(text) then
        return "sound"
    end
    local fallback = originalNSAPITTS or (NSAPI and NSAPI.TTS)
    if fallback then
        fallback(NSAPI, text)
        return "tts"
    end
    Private:DebugPrint("PlayReminderSound: no sound and no NSAPI:TTS for", text)
    return nil
end

function Private:InstallNSAPITTSHook()
    if not NSAPI or not NSAPI.TTS or originalNSAPITTS then
        return
    end
    originalNSAPITTS = NSAPI.TTS
    function NSAPI:TTS(sound, ...)
        local ttsOn = not (NSRT and NSRT.Settings and NSRT.Settings["TTS"] == false)
        if ttsOn and TryPlayOwnedSound(sound) then
            return
        end
        return originalNSAPITTS(self, sound, ...)
    end
end

Private:RegisterEvent("PLAYER_LOGIN", function()
    Private:InstallNSAPITTSHook()
end)

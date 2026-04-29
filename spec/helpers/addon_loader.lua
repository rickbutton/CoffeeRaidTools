-- Loads Ace3 libraries and addon source files under busted.
-- Libraries live under .release/CoffeeRaidTools/Libs/ after `pnpm run build:full`.
---@diagnostic disable: undefined-global

local LIBS_DIR = ".release/CoffeeRaidTools/Libs"

local function loadLib(path)
    local fn, err = loadfile(LIBS_DIR .. "/" .. path)
    if not fn then
        error("Failed to load library " .. path .. ": " .. tostring(err))
    end
    return fn()
end

loadLib("LibStub/LibStub.lua")
loadLib("CallbackHandler-1.0/CallbackHandler-1.0.lua")
loadLib("AceAddon-3.0/AceAddon-3.0.lua")
loadLib("AceEvent-3.0/AceEvent-3.0.lua")
loadLib("AceHook-3.0/AceHook-3.0.lua")
loadLib("AceComm-3.0/ChatThrottleLib.lua")
loadLib("AceComm-3.0/AceComm-3.0.lua")
loadLib("AceConsole-3.0/AceConsole-3.0.lua")
loadLib("AceDB-3.0/AceDB-3.0.lua")
loadLib("AceDBOptions-3.0/AceDBOptions-3.0.lua")
loadLib("LibSerialize/LibSerialize.lua")
loadLib("LibDeflate/LibDeflate.lua")

-- AceGUI is stubbed rather than loaded: its runtime creates real frames that
-- are unnecessary for logic tests. A table with a Create method returning a
-- noop widget is enough to let UI modules load.
local function makeStubWidget()
    return setmetatable({}, {
        __index = function()
            return function() end
        end,
    })
end
local AceGUIStub = {
    Create = function()
        return makeStubWidget()
    end,
    Release = function() end,
}
LibStub:NewLibrary("AceGUI-3.0", 1)
for k, v in pairs(AceGUIStub) do
    LibStub("AceGUI-3.0")[k] = v
end

local ADDON_NAME = "CoffeeRaidTools"

---@class Private
local Private = {}

local loaded = {}

--- Load an addon Lua file as if it were loaded by the WoW client: `...` resolves
--- to (ADDON_NAME, Private). Idempotent — files are only loaded once.
local function loadAddonFile(path)
    if loaded[path] then
        return
    end
    loaded[path] = true
    local fn, err = loadfile(path)
    if not fn then
        error("Failed to load addon file " .. path .. ": " .. tostring(err))
    end
    fn(ADDON_NAME, Private)
end

_G.LoadAddonFile = loadAddonFile

loadAddonFile("CoffeeRaidTools.lua")
loadAddonFile("Core/Util.lua")
loadAddonFile("Core/Nicknames.lua")
loadAddonFile("Core/Roster.lua")
loadAddonFile("Core/Versions.lua")
loadAddonFile("Core/SpecSync.lua")

loadAddonFile("Features/ForceAddonSettings.lua")
loadAddonFile("Features/ReadyCheck.lua")
loadAddonFile("Features/PrivateAuraSoundsData.lua")
loadAddonFile("Features/PrivateAuraSounds.lua")
loadAddonFile("Features/ReminderSoundsData.lua")
loadAddonFile("Features/ReminderSounds.lua")
loadAddonFile("Features/RaidBuffCheck.lua")

loadAddonFile("Interface/Tabs/Raid.lua")

_G.Private = Private

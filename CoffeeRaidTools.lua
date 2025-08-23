---@type string
local AddonName = ...

---@class Private : AceEvent-3.0
local Private = select(2, ...)
local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(Private)

---@class CoffeeRaidTools : AceAddon-3.0, AceConsole-3.0, AceComm-3.0
CoffeeRaidTools = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0", "AceComm-3.0")

---@class CoffeeRaidToolsSaved
CoffeeRaidToolsSaved = CoffeeRaidToolsSaved or {}
---@class CoffeeRaidToolsSaved
Private.db = CoffeeRaidToolsSaved

if Private.db.debug == nil then
    Private.db.debug = false
end

if Private.db.testGroupVersionList == nil then
    Private.db.testGroupVersionList = false
end

---@class TabDescription
---@field key string
---@field title string
---@field draw fun(container: AceGUIContainer)
---@field release? fun(container: AceGUIContainer)

---@class TabRegistry
---@field [number] TabDescription

---@type TabRegistry
Private.tabs = {}

---@param key string
---@param title string
---@param draw fun(container: AceGUIContainer)
---@param release? fun(container: AceGUIContainer)
function Private:RegisterTab(key, title, draw, release)
    tinsert(Private.tabs, { key = key, title = title, draw = draw, release = release })
end
function Private:GetTabDescription(key)
    for _, v in Private:IterateTabDescriptions() do
        if v.key == key then
            return v
        end
    end
    return nil
end
function Private:IterateTabDescriptions()
    return ipairs(Private.tabs)
end

function Private:DebugPrint(...)
    if Private.db.debug then
        CoffeeRaidTools:Print("|cffff0000DEBUG|r", ...)
    end
end

function CoffeeRaidTools:OnInitialize()
end

function CoffeeRaidTools:OnEnable()
end

function CoffeeRaidTools:OnDisable()
end

function CoffeeRaidTools:ChatCommandHandler()
    CoffeeRaidTools:ToggleFrame()
end

CoffeeRaidTools:RegisterChatCommand("crt", "ChatCommandHandler")

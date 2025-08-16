---@type string
local AddonName = ...
---@class Private
local Private = select(2, ...)

---@class CoffeeRaidTools : AceAddon-3.0, AceConsole-3.0, AceComm-3.0
CoffeeRaidTools = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0", "AceComm-3.0")

---@class TabDescription
---@field key string
---@field title string
---@field draw fun(container: AceGUIContainer)

---@class TabRegistry
---@field [number] TabDescription

---@type TabRegistry
Private.tabs = {}

function Private:RegisterTab(key, title, draw)
    tinsert(Private.tabs, { key = key, title = title, draw = draw })
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

function CoffeeRaidTools:OnInitialize()
    --CoffeeRaidTools:OpenFrame()
end

function CoffeeRaidTools:OnEnable()
end

function CoffeeRaidTools:OnDisable()
end

function CoffeeRaidTools:ChatCommandHandler()
    CoffeeRaidTools:ToggleFrame()
end

CoffeeRaidTools:RegisterChatCommand("crt", "ChatCommandHandler")

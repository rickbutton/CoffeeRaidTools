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

if Private.db.readyCheckPopup == nil then
    Private.db.readyCheckPopup = "never"
end

if Private.db.devMode == nil then
    Private.db.devMode = false
end

if Private.db.runTestsOnLoad == nil then
    Private.db.runTestsOnLoad = false
end

if Private.db.onlyShowMismatches == nil then
    Private.db.onlyShowMismatches = false
end

if Private.db.hasForcedTRTemplates == nil then
    Private.db.hasForcedTRTemplates = false
end

Private.IsInRaid = IsInRaid
Private.IsInGroup = IsInGroup
Private.UnitGUID = UnitGUID
Private.GetGuildInfo = GetGuildInfo
Private.BNGetInfo = BNGetInfo
Private.UnitIsGroupLeader = UnitIsGroupLeader

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

-- Popups

local function PopupOnShow(self)
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    C_Timer.After(0, function()
        self:SetHeight(self:GetHeight() + 10)
    end)
end

local TITLE = "|cffffd100CoffeeRaidTools|r"

StaticPopupDialogs["CRT_FORCE_RELOAD"] = {
    text = TITLE .. "\n\nA UI reload is required.",
    button1 = "Reload UI",
    OnAccept = ReloadUI,
    OnShow = PopupOnShow,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    showAlert = false,
}

StaticPopupDialogs["CRT_MISSING_ADDONS"] = {
    text = TITLE .. "\n\nRequired addon(s) missing:\n\n|cffff4040%s|r",
    button1 = "Ok",
    OnShow = PopupOnShow,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = false,
}

StaticPopupDialogs["CRT_UPDATE_AVAILABLE"] = {
    text = TITLE .. "\n\nUpdates available for:\n\n|cffff4040%s|r\n\nPlease update with |cff00ccffCoffee Updater|r.",
    button1 = "Ok",
    OnShow = PopupOnShow,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = false,
}

function CoffeeRaidTools:OnInitialize() end

function CoffeeRaidTools:OnEnable()
    if Private.db.devMode and Private.db.runTestsOnLoad then
        Private.Tests:RunAll()
    end
end

function CoffeeRaidTools:OnDisable() end

local function TogglePopup(name, ...)
    if StaticPopup_Visible(name) then
        StaticPopup_Hide(name)
    else
        StaticPopup_Show(name, ...)
    end
end

local TestCommands = {
    missingaddon = function()
        TogglePopup("CRT_MISSING_ADDONS", "TestAddon1\nTestAddon2")
    end,
    readycheck = function()
        Private:OpenReadyCheckPopup(true)
    end,
    readycheckgood = function()
        Private:OpenReadyCheckPopup(false, true)
    end,
    resettrtemplate = function()
        Private.db.hasForcedTRTemplates = false
        CoffeeRaidTools:Print("TR template force flag reset. Will re-apply on next load.")
    end,
    closereadycheck = function()
        Private:CloseReadyCheckPopup()
    end,
    break10 = function()
        Private:SendMessage("BigWigs_StartBreak", nil, 10, UnitName("player"), false, false, "Break time", 134062)
    end,
    breakstop = function()
        Private:SendMessage("BigWigs_StopBreak", nil, 0, UnitName("player"), false, false)
    end,
    update = function()
        TogglePopup("CRT_UPDATE_AVAILABLE", "CoffeeRaidTools\nTimelineReminders")
    end,
}

local ChatCommands = {
    reload = function()
        TogglePopup("CRT_FORCE_RELOAD")
    end,
    greload = function()
        StaticPopup_Show("CRT_FORCE_RELOAD")
        Private:BroadcastGroupMessage("RELOAD", {})
    end,
    debug = function()
        Private.db.debug = not Private.db.debug
        CoffeeRaidTools:Print("Debug mode " .. (Private.db.debug and "enabled" or "disabled"))
    end,
    devmode = function()
        Private.db.devMode = not Private.db.devMode
        CoffeeRaidTools:Print("Dev mode " .. (Private.db.devMode and "enabled" or "disabled"))
    end,
}

function CoffeeRaidTools:ChatCommandHandler(input)
    local cmd = input and input:trim():lower() or ""
    if cmd == "" then
        CoffeeRaidTools:ToggleFrame()
        return
    end

    local first, rest = cmd:match("^(%S+)%s*(.*)$")
    if first == "test" then
        local subcommand = rest and rest:trim() or ""
        if subcommand == "" then
            Private.Tests:RunAll()
        else
            local handler = TestCommands[subcommand]
            if handler then
                handler()
            else
                CoffeeRaidTools:Print("Unknown test command: " .. subcommand)
            end
        end
        return
    end

    local handler = ChatCommands[first]
    if handler then
        handler()
    else
        CoffeeRaidTools:Print("Unknown command: " .. cmd)
    end
end

CoffeeRaidTools:RegisterChatCommand("crt", "ChatCommandHandler")

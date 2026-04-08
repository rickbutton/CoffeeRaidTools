---@type string
local AddonName = ...

---@class Private : AceEvent-3.0
local Private = select(2, ...)
local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(Private)

Private.VERSION = "@project-version@"

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

if Private.db.disabledPrivateAuras == nil then
    Private.db.disabledPrivateAuras = {}
end

if Private.db.disableConflictingBigWigsPrivateAuraSounds == nil then
    Private.db.disableConflictingBigWigsPrivateAuraSounds = true
end

if Private.db.memoryGamePicker == nil then
    Private.db.memoryGamePicker = false
end

if Private.db.memoryGamePositions == nil then
    Private.db.memoryGamePositions = {}
end

Private.catalystWarningEnabled = false
Private.greatVaultWarningEnabled = false

Private.Blizz = {}
---@class Blizz
local Blizz = Private.Blizz

Blizz.IsInRaid = IsInRaid
Blizz.GetInstanceInfo = GetInstanceInfo
Blizz.IsInGroup = IsInGroup
Blizz.UnitGUID = UnitGUID
Blizz.GetGuildInfo = GetGuildInfo
Blizz.BNGetInfo = BNGetInfo
Blizz.UnitIsGroupLeader = UnitIsGroupLeader
Blizz.GetGuildInfoText = GetGuildInfoText
Blizz.IsAddOnLoaded = C_AddOns.IsAddOnLoaded
Blizz.GetAddOnMetadata = C_AddOns.GetAddOnMetadata
Blizz.GetAddOnEnableState = C_AddOns.GetAddOnEnableState
Blizz.DisableAddOn = C_AddOns.DisableAddOn
Blizz.issecretvalue = issecretvalue
Blizz.PlaySoundFile = PlaySoundFile
Blizz.AddPrivateAuraAppliedSound = C_UnitAuras.AddPrivateAuraAppliedSound
Blizz.RemovePrivateAuraAppliedSound = C_UnitAuras.RemovePrivateAuraAppliedSound
Blizz.AuraIsPrivate = C_UnitAuras.AuraIsPrivate
Blizz.GetSpellName = C_Spell.GetSpellName
Blizz.GetTime = GetTime
Blizz.CreateFrame = CreateFrame
Blizz.UnitClass = UnitClass
Blizz.UnitGroupRolesAssigned = UnitGroupRolesAssigned
Blizz.UnitIsVisible = UnitIsVisible
Blizz.UnitExists = UnitExists
Blizz.UnitIsUnit = UnitIsUnit
Blizz.SendChatMessage = SendChatMessage
Blizz.GetSpellCooldown = C_Spell.GetSpellCooldown
Blizz.GetAuraDataBySpellName = C_UnitAuras.GetAuraDataBySpellName
Blizz.GetSpellInfo = C_Spell.GetSpellInfo
Blizz.ShouldAurasBeSecret = C_Secrets.ShouldAurasBeSecret
Blizz.UIParent = UIParent
Blizz.GameFontNormalLarge = GameFontNormalLarge
Blizz.NewTimer = C_Timer.NewTimer
Blizz.GetTtsVoices = C_VoiceChat.GetTtsVoices()

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

StaticPopupDialogs["CRT_TR_DISABLED"] = {
    text = TITLE .. "\n\nTimelineReminders has been disabled.\nA UI reload is required.",
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
    closereadycheck = function()
        Private:CloseReadyCheckPopup()
    end,
    break10 = function()
        Private:SendMessage("CRT_BigWigs_StartBreak", nil, 10, UnitName("player"), false, false, "Break time", 134062)
    end,
    breakstop = function()
        Private:SendMessage("CRT_BigWigs_StopBreak", nil, 0, UnitName("player"), false, false)
    end,
    update = function()
        TogglePopup("CRT_UPDATE_AVAILABLE", "CoffeeRaidTools")
    end,
    pa = function(args)
        local spellID = tonumber(args)
        if not spellID then
            CoffeeRaidTools:Print("Usage: /crt test pa <spellID>")
            return
        end
        Private:TestPrivateAuraSound(spellID)
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
    encountertools = function(args)
        local sub = args and args:trim():lower() or ""
        if sub == "unlock" then
            Private.encounterToolsUnlocked = not Private.encounterToolsUnlocked
            Private:SendMessage("CRT_EncounterTools_SetTestMode", Private.encounterToolsUnlocked)
            CoffeeRaidTools:Print("Encounter tools " .. (Private.encounterToolsUnlocked and "unlocked" or "locked"))
        else
            CoffeeRaidTools:Print("Usage: /crt encountertools unlock")
        end
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
            local sub, subrest = subcommand:match("^(%S+)%s*(.*)$")
            local handler = TestCommands[sub]
            if handler then
                handler(subrest)
            else
                CoffeeRaidTools:Print("Unknown test command: " .. subcommand)
            end
        end
        return
    end

    local handler = ChatCommands[first]
    if handler then
        handler(rest)
    else
        CoffeeRaidTools:Print("Unknown command: " .. cmd)
    end
end

CoffeeRaidTools:RegisterChatCommand("crt", "ChatCommandHandler")

-- WoW global API stubs needed by Ace3 libraries and the addon under test.
-- Loaded before any addon or library code runs.

_G.tinsert = table.insert
_G.tremove = table.remove
_G.tconcat = table.concat
_G.wipe = function(t)
    for k in pairs(t) do
        t[k] = nil
    end
    return t
end

_G.format = string.format
_G.strmatch = string.match
_G.strsub = string.sub
_G.strlen = string.len
_G.strfind = string.find
_G.strlower = string.lower
_G.strupper = string.upper
_G.strbyte = string.byte
_G.strchar = string.char
_G.strrep = string.rep
_G.strtrim = function(s)
    if not s then
        return ""
    end
    return s:match("^%s*(.-)%s*$")
end
-- WoW adds :trim() to the string metatable.
getmetatable("").__index.trim = _G.strtrim
_G.strjoin = function(sep, ...)
    return table.concat({ ... }, sep)
end
_G.strsplit = function(sep, str, max)
    if str == nil then
        return
    end
    local t = {}
    local start = 1
    local splitStart, splitEnd = string.find(str, sep, start, true)
    while splitStart do
        if max and #t >= max - 1 then
            break
        end
        table.insert(t, string.sub(str, start, splitStart - 1))
        start = splitEnd + 1
        splitStart, splitEnd = string.find(str, sep, start, true)
    end
    table.insert(t, string.sub(str, start))
    return unpack(t)
end

if not _G.unpack and _G.table and _G.table.unpack then
    _G.unpack = _G.table.unpack
end
if not _G.loadstring and _G.load then
    _G.loadstring = _G.load
end

_G.GetTime = function()
    return os.clock()
end
_G.time = os.time

_G.GetLocale = function()
    return "enUS"
end
_G.GetBuildInfo = function()
    return "12.0.0", "00000", "Jan 1 2026", 120000
end
_G.GetRealmName = function()
    return "TestRealm"
end
_G.GetNormalizedRealmName = function()
    return "TestRealm"
end
_G.GetCurrentRegion = function()
    return 1
end
_G.GetCurrentRegionName = function()
    return "US"
end
_G.GetCVar = function()
    return "0"
end
_G.GetAddOnMetadata = function()
    return nil
end
_G.IsLoggedIn = function()
    return true
end
_G.IsLoggedIn = function()
    return true
end
_G.InCombatLockdown = function()
    return false
end
_G.GetFramerate = function()
    return 60
end
_G.ReloadUI = function() end

_G.UnitName = function()
    return "Tester", "TestRealm"
end
_G.UnitNameUnmodified = function()
    return "Tester", "TestRealm"
end
_G.UnitClass = function()
    return "Warrior", "WARRIOR", 1
end
_G.UnitClassBase = function()
    return "WARRIOR"
end
_G.UnitRace = function()
    return "Human", "Human"
end
_G.UnitFactionGroup = function()
    return "Alliance", "Alliance"
end
_G.UnitSex = function()
    return 2
end
_G.UnitFullName = function()
    return "Tester", "TestRealm"
end
_G.UnitRealmRelationship = function()
    return 1
end
_G.UnitIsConnected = function()
    return true
end
_G.UnitExists = function()
    return false
end
_G.UnitIsUnit = function()
    return false
end
_G.UnitGUID = function()
    return nil
end
_G.UnitIsGroupLeader = function()
    return false
end
_G.UnitIsVisible = function()
    return false
end
_G.UnitGroupRolesAssigned = function()
    return "NONE"
end
_G.GetGuildInfo = function()
    return nil
end
_G.GetGuildInfoText = function()
    return nil
end
_G.BNGetInfo = function()
    return nil
end
_G.SendChatMessage = function() end
_G.PlaySoundFile = function() end

_G.IsInRaid = function()
    return false
end
_G.IsInGroup = function()
    return false
end
_G.GetNumGroupMembers = function()
    return 0
end
_G.GetNumSubgroupMembers = function()
    return 0
end

_G.LE_PARTY_CATEGORY_HOME = 1
_G.LE_PARTY_CATEGORY_INSTANCE = 2

_G.issecretvalue = function()
    return false
end

_G.Enum = _G.Enum or {}
_G.Enum.SendAddonMessageResult = {
    Success = 0,
    AddonMessageThrottle = 3,
    NotInGroup = 5,
    ChannelThrottle = 8,
    GeneralError = 9,
}

_G.C_AddOns = {
    IsAddOnLoaded = function()
        return false
    end,
    GetAddOnMetadata = function()
        return nil
    end,
    GetAddOnEnableState = function()
        return 0
    end,
    DisableAddOn = function() end,
}
_G.C_Timer = {
    After = function() end,
    NewTimer = function()
        return { Cancel = function() end }
    end,
    NewTicker = function()
        return { Cancel = function() end }
    end,
}
_G.C_UnitAuras = {
    AddPrivateAuraAppliedSound = function()
        return 1
    end,
    RemovePrivateAuraAppliedSound = function() end,
    AuraIsPrivate = function()
        return true
    end,
    GetAuraDataBySpellName = function()
        return nil
    end,
}
_G.C_Spell = {
    GetSpellName = function()
        return nil
    end,
    GetSpellInfo = function()
        return nil
    end,
    GetSpellCooldown = function()
        return { duration = 0, startTime = 0 }
    end,
}
_G.C_Secrets = {
    ShouldAurasBeSecret = function()
        return false
    end,
    ShouldUnitIdentityBeSecret = function()
        return false
    end,
}
_G.C_ChatInfo = {
    RegisterAddonMessagePrefix = function() end,
    SendAddonMessage = function()
        return true
    end,
    SendAddonMessageLogged = function()
        return true
    end,
}
_G.RegisterAddonMessagePrefix = function() end
_G.SendAddonMessage = function() end

_G.C_QuestLog = {
    IsQuestFlaggedCompleted = function()
        return false
    end,
}
_G.C_VoiceChat = {
    GetTtsVoices = function()
        return {}
    end,
}

_G.GetInstanceInfo = function()
    return "TestInstance", "none"
end

_G.hooksecurefunc = function() end
_G.geterrorhandler = function()
    return function(err)
        return err
    end
end
_G.securecall = function(fn, ...)
    return fn(...)
end
_G.securecallfunction = _G.securecall

_G.CopyTable = function(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = _G.CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function noop() end
local function makeFrame()
    local frame
    frame = setmetatable({}, {
        __index = function(_, key)
            if key == "RegisterEvent"
                or key == "UnregisterEvent"
                or key == "SetScript"
                or key == "Show"
                or key == "Hide"
                or key == "ClearAllPoints"
                or key == "SetPoint"
                or key == "SetHeight"
                or key == "SetWidth"
                or key == "EnableMouse"
                or key == "SetMovable"
                or key == "RegisterForDrag"
                or key == "SetAlpha"
            then
                return noop
            end
            if key == "GetHeight" or key == "GetWidth" then
                return function()
                    return 0
                end
            end
            return noop
        end,
    })
    return frame
end

_G.CreateFrame = function(_, name)
    local frame = makeFrame()
    if name then
        _G[name] = frame
    end
    return frame
end

_G.UIParent = makeFrame()
_G.GameFontNormal = { GetFont = function() end }
_G.GameFontNormalLarge = { GetFont = function() end }
_G.GameFontNormalSmall = { GetFont = function() end }
_G.GameFontHighlightSmall = { GetFont = function() end }
_G.RAID_CLASS_COLORS = setmetatable({}, {
    __index = function()
        return { colorStr = "ffffffff" }
    end,
})

_G.GameTooltip = makeFrame()
_G.StaticPopupDialogs = {}
_G.StaticPopup_Show = function() end
_G.StaticPopup_Hide = function() end
_G.StaticPopup_Visible = function()
    return nil
end

_G.SlashCmdList = {}
_G.hash_SlashCmdList = {}

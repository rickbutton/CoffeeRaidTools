---@class Private
local Private = select(2, ...)

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

---@alias AddonShortcode "CRT" | "BW" | "NSRT" | "MRT" | "RCLC" | "TR"
---@alias TrackedShortcode AddonShortcode | "MRTHASH"

local BROADCAST_INTERVAL = 3

---@enum Matcher
local Matchers = {
    EXISTS = "EXISTS",
    EQUAL = "EQUAL",
}

---@class TrackedAddonMetadata
---@field name string
---@field shortcode AddonShortcode
---@field matcher Matcher
---@field transformVersion? fun(v: string?): string?

---@type TrackedAddonMetadata[]
Private.AddonsToTrack = {
    {
        name = "CoffeeRaidTools",
        shortcode = "CRT",
        matcher = Matchers.EQUAL,
        transformVersion = function(v)
            if not v then
                return v
            end
            return v:match("^([^-]+)") or v
        end,
    },
    {
        name = "BigWigs",
        shortcode = "BW",
        matcher = Matchers.EXISTS,
    },
    {
        name = "NorthernSkyRaidTools",
        shortcode = "NSRT",
        matcher = Matchers.EQUAL,
    },
    {
        name = "MRT",
        shortcode = "MRT",
        matcher = Matchers.EXISTS,
    },
    {
        name = "RCLootCouncil",
        shortcode = "RCLC",
        matcher = Matchers.EQUAL,
    },
    {
        name = "TimelineReminders",
        shortcode = "TR",
        matcher = Matchers.EQUAL,
    },
}

---@param msg table
---@return string
local function EncodeMessage(msg)
    local serialized = LibSerialize:Serialize(msg)
    local compressed = LibDeflate:CompressDeflate(serialized)
    return LibDeflate:EncodeForWoWAddonChannel(compressed)
end

---@param payload string
---@return table?, string?
local function DecodeMessage(payload)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then
        return nil, "unable to decode addon message payload"
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "unable to decompress addon message payload"
    end
    local success, msg = LibSerialize:Deserialize(decompressed)
    if not success then
        return nil, "unable to deserialize addon message payload"
    end
    if type(msg) ~= "table" then
        return nil, "invalid addon message type"
    end
    return msg
end

local function StringHash(text)
    local counter = 1
    local len = string.len(text)
    for i = 1, len, 3 do
        counter = math.fmod(counter * 8161, 4294967279) -- 2^32 - 17: Prime!
            + (string.byte(text, i) * 16776193)
            + ((string.byte(text, i + 1) or (len - i + 256)) * 8372226)
            + ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
    end
    return "" .. math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

local function GetMRTNoteHash()
    if C_AddOns.IsAddOnLoaded("MRT") then
        if VMRT and VMRT.Note.Text1 then
            local text = VMRT.Note.Text1
            local hashed = StringHash(text)
            return hashed
        end
        return "NONE"
    end
    return "NONE"
end

local function GetAddonVersion(name)
    if C_AddOns.IsAddOnLoaded(name) then
        return C_AddOns.GetAddOnMetadata(name, "Version") or "NONE"
    end
    return "NONE"
end

---@param addon TrackedAddonMetadata
---@return string
local function GetTransformedAddonVersion(addon)
    local version = Private.GetAddonVersion(addon.name)
    if addon.transformVersion then
        version = addon.transformVersion(version)
    end
    return version
end

---@class VersionTable
---@field [TrackedShortcode] string

---@return VersionTable
local function CollectLocalVersionTable()
    ---@type VersionTable
    local versions = {}

    -- addon versions
    for i, addon in ipairs(Private.AddonsToTrack) do
        versions[addon.shortcode] = GetTransformedAddonVersion(addon)
    end

    -- hash mrt note
    versions["MRTHASH"] = GetMRTNoteHash()

    return versions
end

---@type table<string, VersionTable?>
local groupVersions = {}
local function ResetGroupVersionsData()
    local oldData = groupVersions
    local newData = {}
    for unit in Private:IterateGroupMembers() do
        if Private:UnitIsRealPlayer(unit) and UnitExists(unit) then
            local guid = Private.UnitGUID(unit)
            if not issecretvalue(guid) and guid then
                newData[guid] = oldData[guid]
            end
        end
    end

    local didDelete = false
    for guid, _ in pairs(oldData) do
        if newData[guid] == nil and oldData[guid] ~= nil then
            didDelete = true
            break
        end
    end
    groupVersions = newData

    if didDelete then
        Private:SendMessage("VERSIONS_CHANGED")
    end
end

---@param guid string
---@param data VersionTable
local function SetGroupVersionData(guid, data)
    Private:DebugPrint("SetGroupVersionData(", guid, ")")
    groupVersions[guid] = data
    Private:SendMessage("VERSIONS_CHANGED")
end

---@alias GroupBroadcastTarget "INSTANCE_CHAT" | "RAID" | "PARTY"
---@alias BroadcastTarget GroupBroadcastTarget | "GUILD"

---@return GroupBroadcastTarget
local function GetGroupBroadcastTarget()
    if Private.IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif Private.IsInRaid() then
        return "RAID"
    else
        return "PARTY"
    end
end

---@alias MessageOpcode "VREQ" | "VRES" | "RELOAD"

---@param op MessageOpcode
---@param target BroadcastTarget
---@param data any
local function BroadcastMessage(op, target, data)
    Private:DebugPrint("BroadcastMessage(", op, ",", target, ")")
    local encoded = EncodeMessage({ op = op, data = data })
    CoffeeRaidTools:SendCommMessage("CRT", encoded, target)
end

---@param op MessageOpcode
---@param data any
local function BroadcastGroupMessage(op, data)
    BroadcastMessage(op, GetGroupBroadcastTarget(), data)
end

---@param op MessageOpcode
---@param data any
local function BroadcastGuildMessage(op, data)
    BroadcastMessage(op, "GUILD", data)
end

---@param guild boolean
local function BroadcastVersionRequest(guild)
    if guild then
        BroadcastGuildMessage("VREQ", {})
    else
        BroadcastGroupMessage("VREQ", {})
    end
end

local versionBroadcastQueued = false
local lastVersionBroadcastTime = 0

local function BroadcastVersions()
    Private:DebugPrint("BroadcastVersions()")
    local playerGuid = Private.UnitGUID("player")
    if not issecretvalue(playerGuid) and playerGuid then
        SetGroupVersionData(playerGuid, Private:GetLocalVersionTable())
    end

    if versionBroadcastQueued then
        return
    end

    local timeToNext = 0
    local timeSinceLast = GetTime() - lastVersionBroadcastTime

    if timeSinceLast < BROADCAST_INTERVAL then
        timeToNext = BROADCAST_INTERVAL - timeSinceLast
    end

    C_Timer.After(timeToNext, function()
        local versions = Private:GetLocalVersionTable()
        BroadcastGuildMessage("VRES", versions)
        BroadcastGroupMessage("VRES", versions)
        versionBroadcastQueued = false
        lastVersionBroadcastTime = GetTime()
    end)
    versionBroadcastQueued = true
end

local function HandleVersionRequest(sender)
    local isSelf = UnitIsUnit(sender, "player")
    if not issecretvalue(isSelf) and isSelf then
        return
    end

    BroadcastVersions()
end

local function HandleVersionResponse(sender, data)
    local isSelf = UnitIsUnit(sender, "player")
    if not issecretvalue(isSelf) and isSelf then
        return
    end

    local guid = Private.UnitGUID(sender)
    if not issecretvalue(guid) and guid then
        SetGroupVersionData(guid, data)
    end
end

local function HandleAddonMessage(prefix, payload, dist, sender)
    local msg, err = DecodeMessage(payload)
    if not msg then
        return Private:DebugPrint("HandleAddonMessage failed:", err)
    end
    Private:DebugPrint("HandleAddonMessage(", msg.op, ",", sender, ")")

    if msg.op == "VREQ" then
        HandleVersionRequest(sender)
    elseif msg.op == "VRES" then
        HandleVersionResponse(sender, msg.data)
    elseif msg.op == "RELOAD" then
        StaticPopup_Show("CRT_FORCE_RELOAD")
    else
        Private:DebugPrint("invalid msg opcode", msg.op)
    end
end

local function HandleGroupUpdate(event)
    if event == "GROUP_JOINED" or event == "GROUP_FORMED" then
        BroadcastVersions()
        BroadcastVersionRequest(false)
    elseif event == "PLAYER_ENTERING_WORLD" then
        BroadcastVersions()
        BroadcastVersionRequest(false)
        BroadcastVersionRequest(true)
    elseif event == "GROUP_ROSTER_UPDATE" then
        ResetGroupVersionsData()
    end
end

---@type VersionTable?
local localVersions = nil
---@return VersionTable
function Private:GetLocalVersionTable()
    if not localVersions then
        localVersions = CollectLocalVersionTable()
    end
    return localVersions
end

---@param shortcode TrackedShortcode
---@return string
function Private:GetLocalVersion(shortcode)
    local tbl = Private:GetLocalVersionTable()
    return tbl[shortcode] or error("invalid version shortcode " .. shortcode)
end

function Private:GetGroupVersionsTable()
    return groupVersions
end

function Private:BroadcastGroupMessage(op, data)
    BroadcastMessage(op, GetGroupBroadcastTarget(), data)
end

Private.StringHash = StringHash
Private.GetMRTNoteHash = GetMRTNoteHash
Private.GetAddonVersion = GetAddonVersion
Private.CollectLocalVersionTable = CollectLocalVersionTable
Private.EncodeMessage = EncodeMessage
Private.DecodeMessage = DecodeMessage
Private.GetGroupBroadcastTarget = GetGroupBroadcastTarget

local function InvalidateLocalVersions()
    localVersions = nil
end

Private.InvalidateLocalVersions = InvalidateLocalVersions

local noteChangeTimer = nil

local function HandleMRTNoteChange()
    Private:DebugPrint("HandleMRTNoteChange called")
    if noteChangeTimer then
        Private:DebugPrint("Cancelling existing note change timer")
        noteChangeTimer:Cancel()
    end
    noteChangeTimer = C_Timer.NewTimer(2, function()
        noteChangeTimer = nil
        local oldHash = Private:GetLocalVersion("MRTHASH")
        InvalidateLocalVersions()
        local newHash = Private:GetLocalVersion("MRTHASH")
        Private:DebugPrint("MRT note hash check: old=", oldHash, "new=", newHash)
        if oldHash ~= newHash then
            Private:DebugPrint("MRT note hash changed:", oldHash, "->", newHash)
            BroadcastVersions()
        else
            Private:DebugPrint("MRT note hash unchanged, skipping broadcast")
        end
    end)
end

local function TryRegisterMRTCallback()
    if GMRT and GMRT.F then
        Private:DebugPrint("Registering GMRT Note_UpdateText callback")
        GMRT.F:RegisterCallback("Note_UpdateText", function(...)
            Private:DebugPrint("Note_UpdateText callback fired, args:", ...)
            HandleMRTNoteChange()
        end, "CoffeeRaidTools")
        return true
    end
    return false
end

if not TryRegisterMRTCallback() then
    Private:DebugPrint("GMRT not yet available, waiting for ADDON_LOADED")
    Private:RegisterEvent("ADDON_LOADED", function(_, addonName)
        if addonName == "MRT" then
            Private:DebugPrint("MRT addon loaded, attempting callback registration")
            TryRegisterMRTCallback()
            Private:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

-- Guild info version check

---@return table<string, string>?
local function ParseGuildInfoVersions()
    local info = GetGuildInfoText()
    if not info then
        return nil
    end
    local block = info:match("<(.-)>")
    if not block then
        return nil
    end
    local versions = {}
    for key, value in block:gmatch("(%w+):(%S+)") do
        versions[key] = value
    end
    if not next(versions) then
        return nil
    end
    return versions
end

---@return string[]?
local function CheckGuildVersions()
    local guildVersions = ParseGuildInfoVersions()
    if not guildVersions then
        return nil
    end
    local shortcodeToAddon = {}
    for _, addon in ipairs(Private.AddonsToTrack) do
        shortcodeToAddon[addon.shortcode] = addon
    end
    local outdated = {}
    for shortcode, guildVersion in pairs(guildVersions) do
        local addon = shortcodeToAddon[shortcode]
        if addon then
            local localVersion = GetTransformedAddonVersion(addon)
            if localVersion ~= guildVersion then
                table.insert(outdated, addon.name)
            end
        end
    end
    return outdated
end

Private.ParseGuildInfoVersions = ParseGuildInfoVersions
Private.CheckGuildVersions = CheckGuildVersions

local guildVersionChecked = false
local function HandleGuildRosterUpdate()
    if guildVersionChecked or InCombatLockdown() then
        return
    end
    local outdated = CheckGuildVersions()
    if not outdated then
        return
    end
    guildVersionChecked = true
    if #outdated > 0 then
        StaticPopup_Show("CRT_UPDATE_AVAILABLE", table.concat(outdated, "\n"))
    end
end

CoffeeRaidTools:RegisterComm("CRT", HandleAddonMessage)
Private:RegisterEvent("GROUP_ROSTER_UPDATE", HandleGroupUpdate)
Private:RegisterEvent("GROUP_JOINED", HandleGroupUpdate)
Private:RegisterEvent("GROUP_FORMED", HandleGroupUpdate)
Private:RegisterEvent("PLAYER_ENTERING_WORLD", HandleGroupUpdate)
Private:RegisterEvent("GUILD_ROSTER_UPDATE", HandleGuildRosterUpdate)

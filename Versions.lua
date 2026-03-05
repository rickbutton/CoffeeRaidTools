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

local function StringHash(text)
    local counter = 1
    local len = string.len(text)
    for i = 1, len, 3 do
        counter = math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
        (string.byte(text, i) * 16776193) +
        ((string.byte(text, i + 1) or (len - i + 256)) * 8372226) +
        ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
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

---@class VersionTable
---@field [TrackedShortcode] string

---@return VersionTable
local function CollectLocalVersionTable()
    ---@type VersionTable
    local versions = {}

    -- addon versions
    for i, addon in ipairs(Private.AddonsToTrack) do
        ---@type string?
        local version = GetAddonVersion(addon.name)
        if addon.transformVersion then
            version = addon.transformVersion(version)
        end
        versions[addon.shortcode] = version
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
            local guid = UnitGUID(unit)
            if guid then
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
    local target
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
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

    local msg = { op = op, data = data }
    local serialized = LibSerialize:Serialize(msg)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
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
    local playerGuid = UnitGUID("player")
    if playerGuid then
        SetGroupVersionData(playerGuid, Private:GetLocalVersionTable())
    end

    if versionBroadcastQueued then return end

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
    if UnitIsUnit(sender, "player") then return end

    BroadcastVersions()
end

local function HandleVersionResponse(sender, data)
    if UnitIsUnit(sender, "player") then return end

    local guid = UnitGUID(sender)
    if guid then
        SetGroupVersionData(guid, data)
    end
end

local function HandleAddonMessage(prefix, payload, dist, sender)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return Private:DebugPrint("unable to decode addon message payload") end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return Private:DebugPrint("unable to decompress addon message payload") end
    local success, msg = LibSerialize:Deserialize(decompressed)
    if not success then return Private:DebugPrint("unable to deserialize addon message payload", msg) end

    if type(msg) ~= "table" then return Private:DebugPrint("invalid addon message type", type(msg)) end
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

CoffeeRaidTools:RegisterComm("CRT", HandleAddonMessage)
Private:RegisterEvent("GROUP_ROSTER_UPDATE", HandleGroupUpdate)
Private:RegisterEvent("GROUP_JOINED", HandleGroupUpdate)
Private:RegisterEvent("GROUP_FORMED", HandleGroupUpdate)
Private:RegisterEvent("PLAYER_ENTERING_WORLD", HandleGroupUpdate)

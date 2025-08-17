---@class Private
local Private = select(2, ...)

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

---@enum Matcher
local Matchers = {
    EXISTS = "EXISTS",
    EQUAL = "EQUAL",
    OPTIONAL = "OPTIONAL"
}

---@class TrackedAddonMetadata
---@field name string
---@field shortcode string
---@field matcher Matcher
---@field transformVersion? fun(v: string?): string?

---@type TrackedAddonMetadata[]
Private.AddonsToTrack = {
    {
        name = "WeakAuras",
        shortcode = "WA",
        matcher = Matchers.EXISTS,
    },
    {
        name = "MRT",
        shortcode = "MRT",
        matcher = Matchers.EXISTS
    },
    { 
        name = "BigWigs",
        shortcode = "BW",
        matcher = Matchers.EQUAL
    },
    { 
        name = "TimelineReminders",
        shortcode = "TR",
        matcher = Matchers.EQUAL
    },
    { 
        name = "AuraUpdater",
        shortcode = "AU",
        matcher = Matchers.EQUAL,
        transformVersion = function(v)
            if v then return v:match("(v%d+)")
            else return nil end
        end,
    },
    { 
        name = "RCLootCouncil",
        shortcode = "RCLC",
        matcher = Matchers.EQUAL,
    },
}

---@class TrackedWeakAuraMetadata
---@field name string
---@field shortcode string

---@type TrackedWeakAuraMetadata[]
Private.WeakAurasToTrack = {
    { name = "Coffee - Utilities", shortcode = "CUTIL" },
    { name = "Coffee - Manaforge Omega", shortcode = "CRAID" },
    { name = "LiquidWeakAuras", shortcode = "LUTIL" },
    { name = "Liquid Anchors", shortcode = "LANC" },
    { name = "Manaforge Omega", shortcode = "LRAID" },
    { name = "Interrupt Anchor", shortcode = "INT" },
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
    local cn = GetUnitName("player", true)
    -- 0 == not enabled
    -- 1 == enabled for other characters
    -- 2 == enabled globally (or for this character when specified)
    if C_AddOns.GetAddOnEnableState(name, cn) == 2 then
        return C_AddOns.GetAddOnMetadata(name, "Version") or "NONE"
    end
    return "NONE"
end

---@class VersionTable
---@field [string] string

---@return VersionTable
local function CollectLocalVersionTable()
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

    -- weakaura versions
    local auraVersions = (AuraUpdater and
        AuraUpdater.GetManagedWeakAuraVersions and
        AuraUpdater:GetManagedWeakAuraVersions()) or {}
    for _, wa in ipairs(Private.WeakAurasToTrack) do
        versions[wa.shortcode] = auraVersions[wa.name] or "NONE"
    end

    -- hash mrt note
    versions["MRTHASH"] = GetMRTNoteHash()

    return versions
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

---@param shortcode string
---@return string
function Private:GetLocalVersion(shortcode)
    local tbl = Private:GetLocalVersionTable()
    return tbl[shortcode] or error("invalid version shortcode " .. shortcode)
end


local function GetBroadcastTarget()
    local type
    local target = nil
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        type = "INSTANCE_CHAT"
    elseif IsInRaid() then
        type = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        type = "PARTY"
    else
        local cn = GetUnitName("player", true)
        type="WHISPER"
        target=cn
    end
    return type, target
end

local function BroadcastMessage(op, data)
    local type, target = GetBroadcastTarget()

    local msg = { op = op, data = data }
    local serialized = LibSerialize:Serialize(msg)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    CoffeeRaidTools:SendCommMessage("CRT", encoded, type, target)
end

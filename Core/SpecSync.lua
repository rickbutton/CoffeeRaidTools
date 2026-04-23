---@class Private
local Private = select(2, ...)

-- Peer spec sync over AceComm. We broadcast our own spec on ready check /
-- pull and collect peers' specs into a GUID-keyed table so the rebuff check
-- in Features/RaidBuffCheck.lua can gate on the target's spec the same way
-- NSRT does in NSI:BuffCheck.

local COMM_PREFIX = "CRTSPEC"

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

---@type table<string, number> [GUID] = specID
local specsByGUID = {}

local function Encode(msg)
    local serialized = LibSerialize:Serialize(msg)
    local compressed = LibDeflate:CompressDeflate(serialized)
    return LibDeflate:EncodeForWoWAddonChannel(compressed)
end

local function Decode(payload)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then
        return nil
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil
    end
    local success, msg = LibSerialize:Deserialize(decompressed)
    if not success or type(msg) ~= "table" then
        return nil
    end
    return msg
end

local function BroadcastTarget()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

---Broadcast our current spec ID to the group. No-op if we aren't in a group.
function Private:BroadcastOwnSpec()
    local target = BroadcastTarget()
    if not target then
        return
    end
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then
        return
    end
    local specID = GetSpecializationInfo and GetSpecializationInfo(specIndex)
    if type(specID) ~= "number" then
        return
    end
    Private:DebugPrint("SpecSync: broadcasting specID", specID, "to", target)
    local playerGUID = UnitGUID("player")
    if playerGUID and not issecretvalue(playerGUID) then
        specsByGUID[playerGUID] = specID
    end
    local encoded = Encode({ specID = specID })
    CoffeeRaidTools:SendCommMessage(COMM_PREFIX, encoded, target)
end

---Look up a peer's spec. Returns the specID we last received from them over
---the group comm, or nil if we never heard from them.
---@param unit string
---@return number?
function Private:GetUnitSpec(unit)
    if UnitIsUnit(unit, "player") then
        local idx = GetSpecialization and GetSpecialization()
        local specID = idx and GetSpecializationInfo and GetSpecializationInfo(idx)
        if type(specID) == "number" then
            return specID
        end
    end
    local guid = UnitGUID(unit)
    if not guid or issecretvalue(guid) then
        return nil
    end
    return specsByGUID[guid]
end

local function HandleSpecMessage(_, payload, _, sender)
    local msg = Decode(payload)
    if not msg or type(msg.specID) ~= "number" then
        return
    end
    local guid = UnitGUID(sender)
    if not guid or issecretvalue(guid) then
        return
    end
    Private:DebugPrint("SpecSync: received specID", msg.specID, "from", sender)
    specsByGUID[guid] = msg.specID
end

local function ClearStaleSpecs()
    local alive = {}
    for unit in Private:IterateGroupMembers() do
        local guid = UnitGUID(unit)
        if guid and not issecretvalue(guid) then
            alive[guid] = true
        end
    end
    for guid in pairs(specsByGUID) do
        if not alive[guid] then
            specsByGUID[guid] = nil
        end
    end
end

Private.SpecSyncPrefix = COMM_PREFIX
Private.SpecSyncReceive = HandleSpecMessage

---Test-only: drop all cached peer specs.
function Private.SpecSyncReset()
    wipe(specsByGUID)
end

CoffeeRaidTools:RegisterComm(COMM_PREFIX, HandleSpecMessage)
Private:RegisterEvent("GROUP_ROSTER_UPDATE", ClearStaleSpecs)
Private:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
    Private:BroadcastOwnSpec()
end)

local LibDeflate = dofile("scripts/compiler/LibDeflate.lua")
local LibSerialize = dofile("scripts/compiler/LibSerialize.lua")

local configForDeflate = { level = 9 }
local configForLS = { errorOnUnserializableType = false }

-- Table to string encoding
local function TableToString(inTable)
    local serialized = LibSerialize:SerializeEx(configForLS, inTable)
    local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
    return "!WA:2!" .. LibDeflate:EncodeForPrint(compressed)
end

-- String to table decoding
local function StringToTable(inString)
    -- encoding format:
    -- version 0: simple b64 string, compressed with LC and serialized with AS
    -- version 1: b64 string prepended with "!", compressed with LD and serialized with AS
    -- version 2+: b64 string prepended with !WA:N! (where N is encode version)
    --   compressed with LD and serialized with LS
    local _, _, encodeVersion, encoded = inString:find("^(!WA:%d+!)(.+)$")
    if encodeVersion then
        encodeVersion = tonumber(encodeVersion:match("%d+"))
    else
        encoded, encodeVersion = inString:gsub("^%!", "")
    end
    
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return nil, "Error decoding."
    end
    
    local decompressed
    if encodeVersion > 0 then
        decompressed = LibDeflate:DecompressDeflate(decoded)
        if not decompressed then
            return nil, "Error decompressing"
        end
    else
        -- For version 0, we would need LibCompress which we don't have
        -- We'll just return an error for version 0 strings
        return nil, "Version 0 encoding not supported in this implementation"
    end
    
    local success, deserialized
    if encodeVersion < 2 then
        -- For version 1, we would need AceSerializer which we don't have
        -- We'll just return an error for version 1 strings
        return nil, "Version 1 encoding not supported in this implementation"
    else
        success, deserialized = LibSerialize:Deserialize(decompressed)
    end
    
    if not success then
        return nil, "Error deserializing"
    end
    
    return deserialized
end

-- Export the API
WeakAuraCompiler = {
    StringToTable = StringToTable,
    TableToString = TableToString,
}

return WeakAuraCompiler

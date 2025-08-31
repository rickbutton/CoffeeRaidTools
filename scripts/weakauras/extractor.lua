---@module "scripts.weakauras.relimport"
---@diagnostic disable-next-line:undefined-global
local relImport = require("scripts.weakauras.relimport")

local codec = relImport("codec")
local serpent = relImport("libs.serpent")

local args = { ... }
if #args ~= 1 then
    print("Usage: lua decode-strings.lua <weakaura-name>")
    print("Example: lua decode-strings.lua \"Liquid - Manaforge Omega\"")
    ---@diagnostic disable-next-line:undefined-global
    os.exit(1)
end

local weakauraName = args[1]
local inputPath = "WeakAuras/Strings/" .. weakauraName .. ".txt"
local outputPath = "WeakAuras/Tables/" .. weakauraName .. ".lua"

-- Read the input file
---@diagnostic disable-next-line:undefined-global
local inputFile = io.open(inputPath, "r")
if not inputFile then
    print("Error: Could not open file: " .. inputPath)
    ---@diagnostic disable-next-line:undefined-global
    os.exit(1)
end

local encodedString = inputFile:read("*all")
inputFile:close()

-- Decode the string
local decodedTable, err = codec.StringToTable(encodedString)
if not decodedTable then
    print("Error decoding WeakAura: " .. (err or "unknown error"))
    ---@diagnostic disable-next-line:undefined-global
    os.exit(1)
end

-- Serialize the table to Lua source
local serialized = serpent.serialize(decodedTable, {
    indent = "  ",
    comment = false,
    sortkeys = true,
    sparse = true,
    compact = false,
    fatal = true,
    nocode = true,
    metatostring = false,
})

---@diagnostic disable-next-line:undefined-global
local outputFile = io.open(outputPath, "w")
-- Write the output file
if not outputFile then
    print("Error: Could not create file: " .. outputPath)
    ---@diagnostic disable-next-line:undefined-global
    os.exit(1)
end

outputFile:write("local weakaura = " .. serialized .. "\n\nreturn weakaura\n")
outputFile:close()

print("Successfully decoded '" .. weakauraName .. "'")
print("Input:  " .. inputPath)
print("Output: " .. outputPath)

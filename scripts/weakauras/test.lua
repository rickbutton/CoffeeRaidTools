---@module "scripts.weakauras.relimport"
---@diagnostic disable-next-line:undefined-global
local relImport = require("scripts.weakauras.relimport")

local lu = relImport("libs.luaunit")
local codec = relImport("codec")

local AURA_DIR = "scripts/weakauras/test_fixtures"
TestWeakAurasCodec = {}

---@param path string
---@return string
local function readFile(path)
    ---@diagnostic disable-next-line:undefined-global
    local file = io.open(path, "r")
    if not file then
        lu.fail("failed to read file " .. path)
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function listDirectory(path, pattern)
    local files = {}
    ---@diagnostic disable-next-line:undefined-global
    local separator = package.config:sub(1,1)
    
    local command
    if separator == "\\" then
        pattern = pattern or "*"
        command = 'dir /b "' .. path:gsub("/", "\\") .. '\\' .. pattern .. '" 2>nul'
    else
        pattern = pattern or "*"
        command = 'ls "' .. path .. '"/' .. pattern .. ' 2>/dev/null'
    end
    
    ---@diagnostic disable-next-line:undefined-global
    local handle = io.popen(command)
    if handle then
        for filename in handle:lines() do
            local just_filename = filename:match("([^/\\]+)$")
            if just_filename then
                table.insert(files, just_filename)
            end
        end
        handle:close()
    end
    
    return files
end

local function getAuraFiles()
    local files = {}
    local filenames = listDirectory(AURA_DIR, "*.txt")
    for _, filename in ipairs(filenames) do
        table.insert(files, {
            path = AURA_DIR .. "/" .. filename,
            name = filename
        })
    end
    return files
end

function TestWeakAurasCodec:testDecodeInvalidString()
    local invalid_strings = {
        "",
        "not a weakaura",
        "!WA:2!",
        "!WA:2!invalid base64 @#$%",
    }
    
    for _, str in ipairs(invalid_strings) do
        local result, err = codec.StringToTable(str)
        lu.assertNil(result, "Expected nil for invalid string: " .. str)
        lu.assertNotNil(err, "Expected error message for invalid string: " .. str)
    end
end

function TestWeakAurasCodec:testEncodeDecode()
    local test_data = {
        { value = 42, type = "number" },
        { value = "test string", type = "string" },
        { value = true, type = "boolean" },
        { value = { a = 1, b = 2, c = { nested = true } }, type = "table" }
    }
    
    for _, test in ipairs(test_data) do
        local encoded = codec.TableToString(test.value)
        lu.assertNotNil(encoded, "Failed to encode " .. test.type)
        lu.assertStrContains(encoded, "!WA:2!", false, "Encoded string should have version prefix")
        
        local decoded, err = codec.StringToTable(encoded)
        lu.assertNotNil(decoded, "Failed to decode " .. test.type .. ": " .. (err or "unknown"))
        lu.assertEquals(decoded, test.value, "Round-trip failed for " .. test.type)
    end
end

do
    local files = getAuraFiles()
    lu.assertTrue(#files > 0, "No aura files found in '" .. AURA_DIR .. "' directory")
    for _, file in ipairs(files) do
        TestWeakAurasCodec["test_" .. file.name] = function()
            local content = readFile(file.path)
            content = content:gsub("^%s+", ""):gsub("%s+$", "")

            local decoded, decode_err = codec.StringToTable(content)
            lu.assertIsTable(decoded, decode_err)
            
            local reencoded = codec.TableToString(decoded)
            lu.assertIsString(reencoded)

            local redecoded, redecode_err = codec.StringToTable(reencoded)
            lu.assertIsTable(redecoded, redecode_err)
            
            lu.assertEquals(decoded, redecoded)
        end
    end
end

---@diagnostic disable-next-line:undefined-global
os.exit(lu.LuaUnit.run())

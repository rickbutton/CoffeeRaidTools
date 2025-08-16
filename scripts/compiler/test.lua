local codec = dofile("compiler.lua")

local test_results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
}

local function deep_equals(t1, t2, path, differences)
    path = path or ""
    differences = differences or {}
    
    -- Handle nil values
    if t1 == nil and t2 == nil then
        return true
    elseif t1 == nil or t2 == nil then
        table.insert(differences, path .. ": one value is nil (t1=" .. tostring(t1) .. ", t2=" .. tostring(t2) .. ")")
        return false
    end
    
    -- Check types
    local type1, type2 = type(t1), type(t2)
    if type1 ~= type2 then
        table.insert(differences, path .. ": type mismatch (" .. type1 .. " vs " .. type2 .. ")")
        return false
    end
    
    -- For non-tables, compare directly
    if type1 ~= "table" then
        if t1 ~= t2 then
            table.insert(differences, path .. ": value mismatch (" .. tostring(t1) .. " vs " .. tostring(t2) .. ")")
            return false
        end
        return true
    end
    
    -- For tables, check all keys
    local checked = {}
    local all_equal = true
    
    -- Check all keys in t1
    for k, v in pairs(t1) do
        checked[k] = true
        local new_path = path == "" and tostring(k) or (path .. "." .. tostring(k))
        if not deep_equals(v, t2[k], new_path, differences) then
            all_equal = false
            -- Continue checking to find all differences
        end
    end
    
    -- Check for keys in t2 that aren't in t1
    for k, v in pairs(t2) do
        if not checked[k] then
            local new_path = path == "" and tostring(k) or (path .. "." .. tostring(k))
            table.insert(differences, new_path .. ": key exists in t2 but not in t1")
            all_equal = false
        end
    end
    
    return all_equal
end

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil, "Could not open file: " .. path
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function get_aura_files()
    local files = {}
    local handle = io.popen('dir /b "auras\\*.txt" 2>nul')
    if handle then
        for filename in handle:lines() do
            table.insert(files, "auras\\" .. filename)
        end
        handle:close()
    end
    return files
end

local function test_aura_file(filepath)
    test_results.total = test_results.total + 1
    local filename = filepath:match("([^\\]+)$")
    
    local content, err = read_file(filepath)
    if not content then
        test_results.failed = test_results.failed + 1
        test_results.errors[filename] = err
        return false
    end
    
    -- Trim whitespace
    content = content:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Decode the string
    local decoded, decode_err = codec.StringToTable(content, true)
    if not decoded then
        test_results.failed = test_results.failed + 1
        test_results.errors[filename] = "Decode error: " .. (decode_err or "unknown")
        return false
    end
    
    -- Re-encode the data
    local reencoded = codec.TableToString(decoded, true)
    if not reencoded then
        test_results.failed = test_results.failed + 1
        test_results.errors[filename] = "Re-encode error"
        return false
    end
    
    -- Decode the re-encoded string
    local redecoded, redecode_err = codec.StringToTable(reencoded, true)
    if not redecoded then
        test_results.failed = test_results.failed + 1
        test_results.errors[filename] = "Re-decode error: " .. (redecode_err or "unknown")
        return false
    end
    
    -- Check string equality
    local strings_equal = (content == reencoded)
    
    -- Deep comparison
    local differences = {}
    local structures_equal = deep_equals(decoded, redecoded, "", differences)
    
    if structures_equal and strings_equal then
        test_results.passed = test_results.passed + 1
        print("[PASS] " .. filename)
        return true
    else
        test_results.failed = test_results.failed + 1
        local error_msg = ""
        
        if not strings_equal then
            error_msg = "String mismatch: length " .. #content .. " vs " .. #reencoded
        end
        
        if not structures_equal then
            if error_msg ~= "" then error_msg = error_msg .. "; " end
            error_msg = error_msg .. "Structure differences: "
            local shown = 0
            for _, diff in ipairs(differences) do
                if shown > 0 then error_msg = error_msg .. "; " end
                error_msg = error_msg .. diff
                shown = shown + 1
                if shown >= 3 then
                    error_msg = error_msg .. " (+" .. (#differences - 3) .. " more)"
                    break
                end
            end
        end
        
        test_results.errors[filename] = error_msg
        print("[FAIL] " .. filename .. " - " .. error_msg)
        return false
    end
end

local function run_tests()
    local files = get_aura_files()
    
    if #files == 0 then
        print("ERROR: No aura files found in 'auras' directory")
        return
    end
    
    print("Testing " .. #files .. " files...")
    print("")
    
    for _, filepath in ipairs(files) do
        test_aura_file(filepath)
    end
    
    print("")
    print("========================================")
    print("Test Summary:")
    print("   Total: " .. test_results.total)
    print("  Passed: " .. test_results.passed)
    print("  Failed: " .. test_results.failed)
    
    if test_results.failed > 0 then
        print("")
        print("Failed tests:")
        for filename, error in pairs(test_results.errors) do
            print("  " .. filename .. ": " .. error)
        end
    end
    
    print("========================================")
    if test_results.failed == 0 then
        print("All tests passed!")
    else
        print("Some tests failed.")
    end
end

-- Run the tests
run_tests()
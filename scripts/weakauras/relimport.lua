---@param mod string
local function relImport(mod)
    local scriptpath = arg and arg[0]
    if scriptpath then
        local dir = scriptpath:match([[^(.+[\/])[^\/]+$]])
        if dir and #dir > 0 then
            ---@diagnostic disable-next-line:undefined-global
            local oldPath = package.path
            ---@diagnostic disable-next-line:undefined-global
            package.path = dir .. '?.lua;' .. package.path
            ---@diagnostic disable-next-line:undefined-global
            local value = require(mod)
            ---@diagnostic disable-next-line:undefined-global
            package.path = oldPath
            return value
        end
    else
        print("no script path?")
        ---@diagnostic disable-next-line:undefined-global
        os.exit(1)
    end
end
return relImport

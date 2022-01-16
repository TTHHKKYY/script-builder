--[[
    libraries that run right before any script is executed using download.lua

    authors: @rwilliaise
]]

local __oldRequire = require

local require = function(module)
    if (typeof(module) == "Instance") or (type(module) == "number") then
        return __oldRequire(module)
    end

    -- search in local dir
    local foundScript = __scripts[module]

    if foundScript then
        -- locals transfer over from the original main.lua script (which is sort of bad but shhh)
        local start = "local PKG_ROOT = \"" .. foundScript.Repo "\"\n"
        start = start .. "local PKG_NAME = \"" .. foundTarget.Parent .. "\"\n"
        start = start .. "local PATH = \"" .. foundScript.Path .. "\"\n"

        return loadstring(start .. foundScript.Source)()
    end

    return nil
end

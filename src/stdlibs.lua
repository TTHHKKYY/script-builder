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
    
end

(function()
    
end)()

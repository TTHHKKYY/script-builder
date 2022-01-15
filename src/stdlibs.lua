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



    local function Recurse(Path)
        local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s",PKG_ROOT,Path))
        local ListData = Http:JSONDecode(List)
        
        for _,File in pairs(ListData) do
            if File["type"] == "dir" then
                print("/" .. File["path"] .. "/")
                Recurse(File["path"])
            end
            if File["type"] == "file" then
                print("/" .. File["path"])
            end
        end
    end
    
    print("Index of the default branch:")
    Recurse(Value or "/")
end

(function()
    
end)()

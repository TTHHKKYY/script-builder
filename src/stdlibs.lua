--[[
    libraries that run right before any script is executed using download.lua

    authors: @rwilliaise
]]

local __oldRequire = require

local require, import = (function()
    local Http = game:GetService("HttpService")
    local LocalPlayer = owner
    
    _G[LocalPlayer] = _G[LocalPlayer] or {}
    _G[LocalPlayer].FetchIndex = _G[LocalPlayer].FetchIndex or {}
    
    local Settings = _G[LocalPlayer]
    
    local function Fetch(Path, Repo, NoCache)
        Repo = Repo or Settings.GithubRepo
    
        if (not NoCache) and Settings.FetchIndex[Repo] and Settings.FetchIndex[Repo][Path] then
            local cache = Settings.FetchIndex[Repo][Path]
    
            if os.clock() - cache.TTD > 0 then
                Settings.FetchIndex[Repo][Path] = nil
            else
                return cache.Data
            end
        end
        local out = Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s", Repo, Path))
    
        Settings.FetchIndex[Repo] = Settings.FetchIndex[Repo] or {}
        Settings.FetchIndex[Repo][Path] = { TTD = os.clock() + 120, Data = out }
    
        return out
    end

    local function GetSource(module)
    
        -- search in local dir
    
        local foundScript = __scripts[module]
    
        if not foundScript then
            foundScript = __scripts[PKG_NAME .. "/" .. module]
        end
    
        if foundScript then
            -- locals transfer over from the original main.lua script (which is sort of bad but shhh)
            local start = "local PKG_ROOT = \"" .. foundScript.Repo .. "\"\n"
            start = start .. "local PKG_NAME = \"" .. foundScript.Parent .. "\"\n"
            start = start .. "local PATH = \"" .. foundScript.Path .. "\"\n"

            local Data = Fetch(foundScript.Branch .. "/" .. foundScript.Path, foundScript.Repo)
            return start .. Data
        end

        return "warn(\"Script \" .. " .. module .. " .. \" not found!\");return nil"
    end

    return (function(module)
        if (typeof(module) == "Instance") or (type(module) == "number") then
            return __oldRequire(module)
        end
    
        return loadstring(GetSource(module))()
    end), GetSource
end)()
    

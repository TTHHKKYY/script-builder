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
        local start = "local PKG_ROOT = \"" .. foundScript.Repo "\"\n"
        start = start .. "local PKG_NAME = \"" .. foundTarget.Parent .. "\"\n"
        start = start .. "local PATH = \"" .. foundScript.Path .. "\"\n"
        start = start .. ("local __stdlibs = [=%s=[%s]=%s=]"):format("=", stdlibs, "=")

        -- require resolve
        start = start .. "local __scripts = {\n"

        for k, v in pairs(__scripts) do
            local name = k
            if v.Parent == "" then
                name = PKG_NAME .. v.__named
            end
            if v.Parent == foundTarget.Parent then
                name = v.__named
            end
            start = start .. ("\t[\"%s\"] = { Source = [=[%s]=], __named = \"%s\", Path = \"%s\", Parent = \"%s\" },\n"):format(name, v.Source, v.__named, v.Path, v.Parent)
        end

        start = start .. "}\n\n"
        start = start .. __stdlibs .. "\n"

        return loadstring(start .. foundScript.Source)()
    end

    return nil
end
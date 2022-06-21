local Http = game:GetService("HttpService")
local BaseUrl = "https://raw.githubusercontent.com/TTHHKKYY/script-builder/main/src/scripts/grab/"

local LocalPlayer = owner

local function include(file)
	print("Get Server " .. BaseUrl .. file)
	NS(Http:GetAsync(BaseUrl .. "server.lua"),workspace)
end

local function AddCSLuaFile(file)
	print("Get Client " .. BaseUrl .. file)
	NLS(Http:GetAsync(BaseUrl .. "client.lua"),LocalPlayer.PlayerGui)
end

include("server.lua")
AddCSLuaFile("client.lua")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remote = Instance.new("RemoteEvent")

Remote.OnServerEvent:Connect(function(_,Hit)
	local Explosion = Instance.new("Explosion")
	
	Explosion.Position = Hit
	Explosion.Parent = workspace
end)

Remote.Name = "ExplodeCursor"
Remote.Parent = owner

-- from Client.lua
NLS([[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mouse = Players.LocalPlayer:GetMouse()
local Remote = Players.LocalPlayer:WaitForChild("ExplodeCursor",math.huge)
local Adornment = Instance.new("SphereHandleAdornment")

Mouse.Button1Down:Connect(function()
	Remote:FireServer(Mouse.Hit.p)
end)

Adornment.Color3 = BrickColor.new("Bright orange").Color
Adornment.Adornee = workspace
Adornment.Parent = Players.LocalPlayer.PlayerGui

while true do
	Adornment.CFrame = CFrame.new(Mouse.Hit.p)
	RunService.Heartbeat:Wait()
end
]],owner.Backpack)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Character = owner.Character
local Remotes = Instance.new("Folder")
local Play = Instance.new("RemoteEvent")
local Stop = Instance.new("RemoteEvent")

--ffghjkgh67
local Radio = Instance.new("Part",Character)
Radio.Name = "Radio"
Radio.CFrame = Character.Torso.CFrame * CFrame.new(Vector3.new(0,0,0.9)) * CFrame.Angles(0,math.rad(180),math.rad(45))
Radio.CanCollide = false
Radio.Anchored = true
Radio.Size = Vector3.new(3.2, 1.43, 0.8)

local Mesh = Instance.new("FileMesh",Radio)
Mesh.MeshId = "rbxassetid://151760030"
Mesh.TextureId = "rbxassetid://151760072"

local Weld = Instance.new("ManualWeld")
Weld.Part0 = Character.Torso
Weld.Part1 = Radio
Weld.C0 = CFrame.new()
Weld.C1 = Character.Torso.CFrame:inverse() * Radio.CFrame
Weld.Parent = Radio
Radio.Anchored = false

local Sound = Instance.new("Sound",Radio)
Sound.Name = "Music"
Sound.Looped = true
Sound.Volume = 1
--

Play.OnServerEvent:Connect(function(_,Id)
	Sound.SoundId = "rbxassetid://" .. Id
	Sound:Play()
end)

Stop.OnServerEvent:Connect(function()
	Sound:Stop()
end)

if ReplicatedStorage:FindFirstChild("RadioPlayer") then
	ReplicatedStorage.RadioPlayer:Destroy()
end

Play.Name = "Play"
Play.Parent = Remotes
Stop.Name = "Stop"
Stop.Parent = Remotes
Remotes.Name = "RadioPlayer"
Remotes.Parent = owner

-- from Client.lua
NLS([[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = Players.LocalPlayer:WaitForChild("RadioPlayer",math.huge)
local Humanoid = Players.LocalPlayer.Character:WaitForChild("Humanoid",math.huge)

--ffghjkgh67
local Gui = Instance.new("ScreenGui",Players.LocalPlayer.PlayerGui)

local Frame = Instance.new("Frame",Gui)
Frame.BackgroundColor3 = Color3.new(58/255,58/255,58/255)
Frame.BorderColor3 = Color3.new(0,0,0)
Frame.BorderSizePixel = 2
Frame.Size = UDim2.new(0,300,0,200)
Frame.Position = UDim2.new(0,20,.5,-100)
 
local Play = Instance.new("TextButton",Frame)
Play.BackgroundColor3 = Color3.new(0,85/255,0)
Play.BorderColor3 = Color3.new(0,0,0)
Play.BorderSizePixel = 2
Play.Size = UDim2.new(.3,0,.2,0)
Play.Position = UDim2.new(.1,0,.7,0)
Play.Text = "Play"
Play.TextColor3 = Color3.new(255,255,255)
Play.TextScaled = true
 
local Stop = Instance.new("TextButton",Frame)
Stop.BackgroundColor3 = Color3.new(170/255,0,0)
Stop.BorderColor3 = Color3.new(0,0,0)
Stop.BorderSizePixel = 2
Stop.Size = UDim2.new(.3,0,.2,0)
Stop.Position = UDim2.new(.6,0,.7,0)
Stop.Text = "Stop"
Stop.TextColor3 = Color3.new(255,255,255)
Stop.TextScaled = true
 
local Input = Instance.new("TextBox",Frame)
Input.BackgroundColor3 = Color3.new(0,0,127/255)
Input.BorderColor3 = Color3.new(0,0,0)
Input.BorderSizePixel = 2
Input.Size = UDim2.new(.5,0,.25,0)
Input.Position = UDim2.new(.25,0,.3,0)
Input.Text = ""
Input.TextColor3 = Color3.new(255,255,255)
Input.TextScaled = true
--

Play.Activated:Connect(function()
	local Sound = tonumber(Input.Text)
	
	if Sound then
		Remotes.Play:FireServer(Sound)
	end
end)

Stop.Activated:Connect(function()
	Remotes.Stop:FireServer()
end)

Humanoid.Died:Connect(function()
	Gui:Destroy()
end)

]],owner.Backpack)

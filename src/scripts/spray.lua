local LocalPlayer = owner

local Remote = Instance.new("RemoteEvent")
local Sound = Instance.new("Sound")

local RayData = RaycastParams.new()

local LastRemote = LocalPlayer:FindFirstChild("SprayImage") do
	if LastRemote then
		LastRemote:Destroy()
	end
end

Remote.Name = "SprayImage"
Remote.Parent = LocalPlayer

RayData.IgnoreWater = true
RayData.FilterType = Enum.RaycastFilterType.Blacklist
RayData.FilterDescendantsInstances = {LocalPlayer.Character}

Sound.Volume = 1
Sound.SoundId = "rbxassetid://5034673872"
Sound.Parent = LocalPlayer.Character.PrimaryPart

Remote.OnServerEvent:Connect(function(Player,Image,Layer,Ray)
	if Player == LocalPlayer then
		local Result = workspace:Raycast(Ray.Origin,Ray.Direction * 2048,RayData)
		
		if Result and Result.Instance then
			local Adornment = Instance.new("ImageHandleAdornment")
			
			Adornment.ZIndex = Layer
			Adornment.Size = Vector2.new(4,4)
			Adornment.Image = "rbxassetid://" .. Image
			Adornment.CFrame = CFrame.new(Result.Position + Result.Normal * 0.01,Result.Position + Result.Normal)
			Adornment.Adornee = workspace
			Adornment.Parent = workspace
			
			Sound:Play()
		end
	end
end)

NLS([[
	local LocalPlayer = owner
	
	local Mouse = LocalPlayer:GetMouse()
	local Camera = workspace.CurrentCamera
	
	local Remote = LocalPlayer.SprayImage
	
	local Interface = Instance.new("ScreenGui")
	local Preview = Instance.new("ImageLabel")
	local Input = Instance.new("TextBox")
	local Layer = Instance.new("TextBox")
	
	local LastInterface = LocalPlayer.PlayerGui:FindFirstChild("SprayerInterface") do
		if LastInterface then
			LastInterface:Destroy()
		end
	end
	
	Input.BackgroundColor3 = Color3.new(1,1,1)
	Input.BorderColor3 = Color3.new(0,0,0)
	Input.TextColor3 = Color3.new(0,0,0)
	Input.Size = UDim2.new(0,300,0,50)
	Input.Position = UDim2.new(1,-420,1,-60)
	Input.BackgroundTransparency = 0.6
	Input.TextSize = 20
	Input.TextXAlignment = Enum.TextXAlignment.Left
	Input.Parent = Interface
	
	Layer.BackgroundColor3 = Color3.new(1,1,1)
	Layer.BorderColor3 = Color3.new(0,0,0)
	Layer.TextColor3 = Color3.new(0,0,0)
	Layer.Size = UDim2.new(0,50,0,50)
	Layer.Position = UDim2.new(1,-115,1,-60)
	Layer.TextSize = 20
	Layer.Text = 0
	Layer.Parent = Interface
	
	Preview.BackgroundColor3 = Color3.new(1,1,1)
	Preview.BorderColor3 = Color3.new(0,0,0)
	Preview.Size = UDim2.new(0,50,0,50)
	Preview.Position = UDim2.new(1,-60,1,-60)
	Preview.Image = ""
	Preview.Parent = Interface
	
	Interface.ResetOnSpawn = true
	Interface.Name = "SprayerInterface"
	Interface.Parent = LocalPlayer.PlayerGui
	
	Layer.FocusLost:Connect(function()
		local Value = tonumber(Layer.Text)
		
		if Value then
			Layer.Text = math.clamp(Value,-1,10)
		else
			Layer.Text = 0
		end
	end)
	
	Input.FocusLost:Connect(function()
		Preview.Image = "rbxassetid://" .. Input.Text
	end)
	
	Mouse.Button1Down:Connect(function()
		Remote:FireServer(Input.Text,Layer.Text,Mouse.UnitRay)
	end)
]],LocalPlayer.Backpack)

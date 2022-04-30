local LocalPlayer = owner

local Mouse = LocalPlayer:GetMouse()
local Remote = LocalPlayer.HeadCrabCanister

local function ClearAdornments()
	for _,Adornment in pairs(workspace:GetChildren()) do
		if Adornment.Name == "CanisterLaunchLocation" then
			Adornment:Destroy()
		end
	end
end

Mouse.KeyDown:Connect(function(Key)
	if Key == "k" then
		if Mouse.Target then
			local Adornment = Instance.new("SphereHandleAdornment")
			
			Adornment.Radius = 1
			Adornment.Transparency = 0.4
			Adornment.Color3 = Color3.new(1.0,0.7,0.0)
			Adornment.CFrame = Mouse.Hit
			Adornment.Name = "CanisterLaunchLocation"
			Adornment.Adornee = workspace
			Adornment.Parent = workspace
			
			Remote:FireServer("place",Mouse.Hit)
		end
	end
	if Key == "l" then
		ClearAdornments()
		Remote:FireServer("launch")
	end
end)

ClearAdornments()

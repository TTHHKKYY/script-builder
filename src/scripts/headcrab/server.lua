local TweenService = game:GetService("TweenService")

local LocalPlayer = owner

local CanisterTween = TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut)

local LastRemote = LocalPlayer:FindFirstChild("HeadCrabCanister") do
	if LastRemote then
		LastRemote:Destroy()
	end
end

local Remote = Instance.new("RemoteEvent")

Remote.Name = "HeadCrabCanister"
Remote.Parent = LocalPlayer

local Extras

local function NewInstance(Class)
	local Success,Object = pcall(Instance.new,Class)

	if Success then
		if Class == "Sound" then
			table.insert(ExtraSounds, Object)
		end
		if Class == "Explosion" then
			table.insert(ExtraExplosions, Object)
		end
		return Object
	else
		local found = workspace:FindFirstChildOfClass(Class)
		if found then
			return found
		end
		for _, v in pairs(Extras) do
			if v:IsA(Class) and v.Parent == nil then
				return v
			end
		end
		warn("Unable to create " .. Class)
	end
end

local function GetCanisters()
	local Canisters = {}
	
	for _,Part in pairs(workspace:GetChildren()) do
		if Part.Name == LocalPlayer.Name .. "HeadCrabCanister" then
			table.insert(Canisters,Part)
		end
	end
	return Canisters
end

Remote.OnServerEvent:Connect(function(Player,Event,...)
	local arg = {...}
	
	if Player == LocalPlayer then
		if Event == "place" then
			local Location = arg[1]
			
			---- canister
			local Canister = NewInstance("Part")
			
			assert(Canister,"Unable to create canister part. Please slow down.")
			
			Canister.Anchored = true
			Canister.Locked = true
			Canister.Size = Vector3.new(4,4,12.5)
			Canister.CFrame = CFrame.new(math.random(-1000,1000),3000,math.random(-1000,1000)) * CFrame.Angles(math.rad(-90),0,0) + Location.p
			Canister.Name = LocalPlayer.Name .. "HeadCrabCanister"
			
			local Smoke = NewInstance("Smoke")
			
			if Smoke then
				Smoke.Enabled = false
				Smoke.Opacity = 0.1
				Smoke.Size = 1
				Smoke.RiseVelocity = 0
				Smoke.Color = Color3.new(1,1,1)
				Smoke.Parent = Canister
			end
			
			local Mesh = NewInstance("FileMesh")
			
			if Mesh then
				Mesh.MeshId = "rbxassetid://9485186641"
				Mesh.TextureId = "rbxassetid://9485186557"
				Mesh.Scale = Vector3.new(0.25,0.25,0.25)
				Mesh.Parent = Canister
			end
			
			----
			
			---- trail
			
			local TrailStart = NewInstance("Attachment")
			
			if TrailStart then
				TrailStart.CFrame = CFrame.new()
				TrailStart.Parent = Canister
			end
			
			local TrailEnd = NewInstance("Attachment")
			
			if TrailEnd then
				TrailEnd.CFrame = CFrame.new(0,0,3)
				TrailEnd.Parent = Canister
			end
			
			local Trail = NewInstance("Trail")
			
			if Trail then
				Trail.Color = ColorSequence.new
						{
							ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
							ColorSequenceKeypoint.new(1,Color3.new(1,1,1))
						}
				
				Trail.Transparency = NumberSequence.new
						{
							NumberSequenceKeypoint.new(0.0,0),
							NumberSequenceKeypoint.new(0.5,0),
							NumberSequenceKeypoint.new(1.0,1)
						}
				
				Trail.Attachment0 = TrailStart
				Trail.Attachment1 = TrailEnd
				Trail.Parent = Canister
			end
			
			----
			
			---- sound effects
			
			local Hiss = NewInstance("Sound")
			
			if Hiss then
				Hiss.Looped = true
				Hiss.Volume = 0.7
				Hiss.SoundId = "rbxassetid://5057582133"
				Hiss.Parent = Canister
			end
			
			local Land = NewInstance("Sound")
			
			if Land then
				Land.Volume = 0.3
				Land.SoundId = "rbxassetid://7990171197"
				Land.Parent = Canister
			end
			
			----
			
			local Explosion = NewInstance("Explosion")
			
			if Explosion then
				Explosion.BlastRadius = 20
				Explosion.Position = Location.p
			end
			
			---- wait for launch message
			
			while true do
				local Player,Event = Remote.OnServerEvent:Wait()
				
				if Player == LocalPlayer and Event == "launch" then
					break
				end
			end
			
			Canister.Parent = workspace
			
			TweenService:Create(Canister,CanisterTween,{CFrame = Location * CFrame.Angles(math.rad(-90),0,0)}):Play()
			task.wait(CanisterTween.Time)
			
			if Smoke then Smoke.Enabled = true end
			
			if Hiss then Hiss:Play() end
			if Land then Land:Play() end
			
			if Explosion then Explosion.Parent = workspace end
		end
		
		if Event == "unanchor" then
			for _,Part in pairs(GetCanisters()) do
				Part.Anchored = false
				Part.Locked = false
				
				Part.Velocity = Vector3.new(50,50,50) * ((math.random() - 0.5) * 2)
				Part.RotVelocity = Vector3.new(90,90,90) * ((math.random() - 0.5) * 2)
			end
		end
		
		if Event == "clear" then
			for _,Part in pairs(GetCanisters()) do
				for _, v in pairs(Part:GetDescendants()) do
					table.insert(Extras, v)
					v.Parent = nil
				end
				Part.Parent = nil
			end
		end
	end
end)

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

Remote.OnServerEvent:Connect(function(Player,Event,...)
	local arg = {...}
	
	if Player == LocalPlayer then
		if Event == "place" then
			local Location = arg[1]
			
			local Canister = Instance.new("Part")
			local Smoke = Instance.new("Smoke")
			local Mesh = Instance.new("FileMesh")
			
			Smoke.Enabled = false
			Smoke.Opacity = 0.1
			Smoke.Size = 1
			Smoke.RiseVelocity = 0
			Smoke.Color = Color3.new(1,1,1)
			Smoke.Parent = Canister
			
			Mesh.MeshId = "rbxassetid://9485186641"
			Mesh.TextureId = "rbxassetid://9485186557"
			Mesh.Scale = Vector3.new(0.25,0.25,0.25)
			Mesh.Parent = Canister
			
			local Hiss = Instance.new("Sound")
			local Land = Instance.new("Sound")
			
			Hiss.Looped = true
			Hiss.Volume = 2
			Hiss.SoundId = "rbxassetid://5057582133"
			Hiss.Parent = Canister
			
			Land.Volume = 1
			Land.SoundId = "rbxassetid://7990171197"
			Land.Parent = Canister
			
			local Trail = Instance.new("Trail")
			local TrailStart = Instance.new("Attachment")
			local TrailEnd = Instance.new("Attachment")
			
			TrailStart.CFrame = CFrame.new()
			TrailStart.Parent = Canister
			
			TrailEnd.CFrame = CFrame.new(0,0,3)
			TrailEnd.Parent = Canister
			
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
			
			Canister.Anchored = true
			Canister.Locked = true
			Canister.Size = Vector3.new(4,4,12.5)
			Canister.CFrame = CFrame.new(math.random(-1000,1000),3000,math.random(-1000,1000)) + Location.p
			
			local Explosion = Instance.new("Explosion")
			
			Explosion.BlastRadius = 20
			Explosion.Position = Location.p
			
			while true do
				local Player,Event = Remote.OnServerEvent:Wait()
				
				if Player == LocalPlayer and Event == "launch" then
					break
				end
			end
			
			Canister.Parent = workspace
			
			TweenService:Create(Canister,CanisterTween,{CFrame = Location * CFrame.Angles(math.rad(-90),0,0)}):Play()
			task.wait(CanisterTween.Time)
			
			Explosion.Parent = workspace
			
			Smoke.Enabled = true
			
			Hiss:Play()
			Land:Play()
		end
	end
end)

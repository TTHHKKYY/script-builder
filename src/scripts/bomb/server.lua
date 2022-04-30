local LocalPlayer = owner

local LastRemote = LocalPlayer:FindFirstChild("BombToolDetonateEvent") do
	if LastRemote then
		LastRemote:Destroy()
	end
end

local LastRemote = LocalPlayer:FindFirstChild("BombToolThrowEvent") do
	if LastRemote then
		LastRemote:Destroy()
	end
end

local Detonate = Instance.new("RemoteEvent")
local Throw = Instance.new("RemoteEvent")

Detonate.Name = "BombToolDetonateEvent"
Detonate.Parent = LocalPlayer

Throw.Name = "BombToolThrowEvent"
Throw.Parent = LocalPlayer

local Bomb = Instance.new("Part")
local Mesh = Instance.new("FileMesh")

Mesh.Scale = Vector3.new(0.4,0.4,0.4)
Mesh.MeshId = "rbxassetid://12891705"
Mesh.TextureId = "rbxassetid://12891577"
Mesh.Parent = Bomb

Bomb.Size = Vector3.new(1,0.8,2)

local Bombs = {}

Detonate.OnServerEvent:Connect(function(Player)
	if Player == LocalPlayer then
		for i,Part in pairs(Bombs) do
			local Success,Explosion = pcall(Instance.new,"Explosion")
			
			if Success then
				Explosion.BlastRadius = 30
				Explosion.Position = Part.Position
				Explosion.Parent = workspace
			else
				warn("Unable to create an explosion.")
			end
			
			Part:Destroy()
			Bombs[i] = nil
		end
	end
end)

Throw.OnServerEvent:Connect(function(Player,Camera)
	if Player == LocalPlayer and Player.Character.PrimaryPart then
		local Dupe = Bomb:Clone()
		
		Dupe.Velocity = Camera.LookVector * 50
		Dupe.RotVelocity = Vector3.new(math.random(-100,100) / 100,math.random(-100,100) / 100,math.random(-100,100) / 100) * 20
		Dupe.Position = Player.Character.Head.Position + Player.Character.Head.CFrame.LookVector * 2
		Dupe.Parent = workspace
		
		Dupe:SetNetworkOwner(nil)
		table.insert(Bombs,Dupe)
	end
end)

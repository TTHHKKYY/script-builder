local LocalPlayer = owner

local Grab do
	Grab = LocalPlayer:FindFirstChild("GrabObject")
	
	if Grab then
		Grab:Destroy()
	end
	
	Grab = Instance.new("RemoteFunction")
	Grab.Name = "GrabObject"
	Grab.Parent = LocalPlayer
end

local Drop do
	Drop = LocalPlayer:FindFirstChild("DropObject")
	
	if Drop then
		Drop:Destroy()
	end
	
	Drop = Instance.new("RemoteEvent")
	Drop.Name = "DropObject"
	Drop.Parent = LocalPlayer
end

local HeldPart

function Grab.OnServerInvoke(Player,Target)
	if Player.UserId == LocalPlayer.UserId then
		if not HeldPart then
			if Target and not Target.Anchored then
				Target:SetNetworkOwner(Player)
				HeldPart = Target
				return Target
			end
		end
	end
	return nil
end

Drop.OnServerEvent:Connect(function(Player)
	if Player == LocalPlayer then
		if HeldPart then
			HeldPart:SetNetworkOwner(nil)
			HeldPart:SetNetworkOwnershipAuto()
			HeldPart = nil
		end
	end
end)

local LocalPlayer = owner

local Block = Instance.new("Part")

local Debounce = false

Block.Touched:Connect(function(Touchee)
	if not Debounce then
		local Humanoid = Touchee.Parent:FindFirstChild("Humanoid")
		
		if Humanoid then
			local Glue = Humanoid.RootPart:FindFirstChild("Weld")
			
			if not Glue then			
				local Glue = Instance.new("Weld")
				
				Glue.Part0 = Humanoid.RootPart
				Glue.Part1 = Block
				Glue.C1 = CFrame.new(Humanoid.RootPart.Position - Block.Position)
				Glue.Parent = Humanoid.RootPart
				Humanoid.PlatformStand = true
			end
		end
	end
end)

Block.Name = "Glue"
Block.BrickColor = BrickColor.new("Bright yellow")
Block.Size = Vector3.new(8,8,8)
Block.Position = LocalPlayer.Character.PrimaryPart.Position + Vector3.new(0,32,0)
Block.TopSurface = Enum.SurfaceType.Glue
Block.FrontSurface = Enum.SurfaceType.Glue
Block.BottomSurface = Enum.SurfaceType.Glue
Block.BackSurface = Enum.SurfaceType.Glue
Block.LeftSurface = Enum.SurfaceType.Glue
Block.RightSurface = Enum.SurfaceType.Glue
Block.Parent = workspace

while wait(0.1) do
	Debounce = not Debounce
end

--Inspired by JJK83's glue block.

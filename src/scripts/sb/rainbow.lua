local RunService = game:GetService("RunService")

local Colors = 499

for i=0,Colors do
	local Part = Instance.new("Part")
	
	Part.Anchored = true
	Part.Color = Color3.fromHSV(i / Colors,1,1)
	Part.CFrame = CFrame.new(i * 0.1,10,10)
	Part.Size = Vector3.new(0.1,10,1)
	Part.Parent = workspace
	RunService.Heartbeat:Wait()
end

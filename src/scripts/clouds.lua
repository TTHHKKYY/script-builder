local Clouds = Instance.new("Clouds")

Clouds.Cover = 0.6
Clouds.Parent = workspace.Terrain

while true do
	Clouds.Color = Color3.fromHSV(os.clock() * 180 % 360 / 360,1,1)
	Clouds.Cover = (math.sin(os.clock())) * 0.5 + 0.5
	task.wait()
end

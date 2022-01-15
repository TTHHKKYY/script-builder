local LocalPlayer = owner

local Remote = Instance.new("RemoteEvent")

local LastRemote = LocalPlayer:FindFirstChild("UploadPainting") do
	if LastRemote then
		LastRemote:Destroy()
	end
end

Remote.Name = "UploadPainting"
Remote.Parent = LocalPlayer

print("Hold E while dragging your cursor over the canvas to draw.")
print("Click Submit to draw whats on the canvas.")

Remote.OnServerEvent:Connect(function(Player,Data,Scale)
	if Player == LocalPlayer then
		local Origin = LocalPlayer.Character:GetModelCFrame()
		local Model = Instance.new("Model")
		
		Model.Parent = workspace
		
		for _,Pixel in ipairs(Data) do
			local Part = Instance.new("Part")
			
			Part.Anchored = true
			Part.Locked = true
			Part.Size = Vector3.new(Scale,1,Scale)
			Part.Position = Vector3.new(Pixel.x * Scale,1,Pixel.y * Scale) + Origin.p
			Part.Color = Pixel.Color
			Part.Parent = Model
			
			-- avoid creating parts too fast.
			task.wait(0.05)
		end
	end
end)

NLS([[
local ContextAction = game:GetService("ContextActionService")

local LocalPlayer = owner

local Interface = Instance.new("ScreenGui")
local Container = Instance.new("Frame")
local Palette = Instance.new("ScrollingFrame")

local Submit = Instance.new("TextButton")

local Grid = Instance.new("UIGridLayout")
local List = Instance.new("UIListLayout")

local Remote = LocalPlayer.UploadPainting

local Image = {}
local BrushColor = Color3.new()
local BrushDown = false

local LastInterface = LocalPlayer.PlayerGui:FindFirstChild("PaintingInterface") do
	if LastInterface then
		LastInterface:Destroy()
	end
end

Grid.CellPadding = UDim2.new(0,0,0,0)
Grid.CellSize = UDim2.new(0,32,0,32)
Grid.Parent = Container

List.Parent = Palette

Container.BackgroundColor3 = Color3.new(1,1,1)
Container.BorderColor3 = Color3.new()
Container.Size = UDim2.new(0,512,0,512)
Container.Position = UDim2.new(0.5,256,0.3,-256)
Container.Parent = Interface

Palette.ClipsDescendants = true
Palette.BackgroundColor3 = Color3.new(1,1,1)
Palette.BorderColor3 = Color3.new()
Palette.Size = UDim2.new(0,128,0,512 - 68)
Palette.Position = UDim2.new(0.5,256 - 132,0.3,-256)
Palette.CanvasSize = UDim2.new()
Palette.ScrollBarThickness = 0
Palette.AutomaticCanvasSize = Enum.AutomaticSize.Y
Palette.ScrollingDirection = Enum.ScrollingDirection.Y
Palette.Parent = Interface

Submit.BackgroundColor3 = Color3.new(1,1,1)
Submit.BorderColor3 = Color3.new()
Submit.Size = UDim2.new(0,128,0,64)
Submit.Position = UDim2.new(0.5,256 - 132,0.3,256 - 64)

Submit.Font = Enum.Font.Arial
Submit.TextSize = 40
Submit.TextColor3 = Color3.new()
Submit.Text = "Submit"

Submit.Parent = Interface

Interface.ResetOnSpawn = true
Interface.Name = "PaintingInterface"
Interface.Parent = LocalPlayer.PlayerGui

for x=-8,7 do
	for y=-8,7 do
		local VisualPixel = Instance.new("TextButton")
		local Pixel = {}
		
		VisualPixel.AutoButtonColor = false
		VisualPixel.BackgroundColor3 = Color3.new(1,1,1)
		VisualPixel.BorderSizePixel = 0
		VisualPixel.Text = ""
		VisualPixel.Parent = Container
		
		Pixel.x = x
		Pixel.y = y
		Pixel.Color = Color3.new(1,1,1)
		table.insert(Image,Pixel)
		
		VisualPixel.MouseEnter:Connect(function()
			if BrushDown then
				Pixel.Color = BrushColor
				VisualPixel.BackgroundColor3 = BrushColor
			end
		end)
	end
end

do
	local MediumStoned = false
	
	for i=1,1032 do
		local Color = BrickColor.new(i)
		
		if Color.Name == "Medium stone grey" then
			if not MediumStoned then
				MediumStoned = true
			else
				continue
			end
		end
		
		local Item = Instance.new("TextButton")
		
		Item.BorderSizePixel = 0
		Item.BackgroundColor3 = Color.Color	
		Item.Size = UDim2.new(1,0,0,32)
		
		if Color.r > 0.5 and Color.g > 0.5 and Color.b > 0.5 then
			Item.TextColor3 = Color3.new(0,0,0)
		else
			Item.TextColor3 = Color3.new(1,1,1)
		end
		
		Item.TextSize = 8
		Item.Text = Color.Name
		Item.Parent = Palette
		
		Item.Activated:Connect(function()
			BrushColor = Color.Color
		end)
	end
end

Submit.Activated:Connect(function()
	Remote:FireServer(Image,2)
end)

ContextAction:BindAction("PaintingBrushDown",function(_,State)
	if State == Enum.UserInputState.Begin then
		BrushDown = true
	end
	if State == Enum.UserInputState.End then
		BrushDown = false
	end
end,false,Enum.KeyCode.E)
]],LocalPlayer.Backpack)

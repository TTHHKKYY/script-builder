local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))

local LocalPlayer = owner

-- destroy the last interface, if there was.
local LastInterface = LocalPlayer.PlayerGui:FindFirstChild("RepositoryIndex") do
	if LastInterface then
		LastInterface:Destroy()
	end
end

local Interface = Instance.new("ScreenGui")
local Container = Instance.new("ScrollingFrame")
local List = Instance.new("UIListLayout")

local Button = Instance.new("TextButton")

---- interface

List.Parent = Container

Button.TextSize = 25
Button.BackgroundTransparency = 1
Button.TextColor3 = Color3.new(0,0,0)
Button.Size = UDim2.new(1,0,0,30)
Button.TextXAlignment = Enum.TextXAlignment.Left

Container.BackgroundTransparency = 0.8
Container.BackgroundColor3 = BrickColor.new("White").Color
Container.BorderColor3 = BrickColor.new("Black").Color
Container.ScrollBarImageColor3 = BrickColor.new("Black").Color

Container.CanvasSize = UDim2.new()
Container.Size = UDim2.new(0,300,0,600)
Container.Position = UDim2.new(1,-380,1,-610)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.Parent = Interface

Interface.ResetOnSpawn = false
Interface.Name = "RepositoryIndex"
Interface.Parent = LocalPlayer.PlayerGui

local function ClearInterface()
	for _,Item in pairs(Container:GetChildren()) do
		if Item ~= List then
			Item:Destroy()
		end
	end
end

----

LocalPlayer.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	if string.find(Arguments[1],"^/") then
		local Command = Arguments[1]
		
		loadstring(Http:GetAsync(Arguments[2]))
	end
end)

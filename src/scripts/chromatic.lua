local Part = Instance.new("Part")

local A = Instance.new("Attachment")
local B = Instance.new("Attachment")
local Trail = Instance.new("Trail")

local LocalPlayer = owner
local Humanoid = LocalPlayer.Character.Humanoid
local RootPart = LocalPlayer.Character.Humanoid.RootPart

local Rainbow = {}
local Transparency = {}
local Hues = 10
local Fade = 10

local Alive = true

for i=0,Hues do
	local ColorFrame = ColorSequenceKeypoint.new(i / Hues,Color3.fromHSV(i / Hues,1,1))
	table.insert(Rainbow,ColorFrame)
end
for i=0,Fade do
	local TransparencyFrame = NumberSequenceKeypoint.new(i / Fade,i / Fade)
	table.insert(Transparency,TransparencyFrame)
end

A.Position = Vector3.new(0,0.1,0)
A.Parent = Part

B.Position = Vector3.new(0,-0.1,0)
B.Parent = Part

Part.Anchored = true
Part.CanCollide = false
Part.CanTouch = false
Part.Locked = true
Part.Transparency = 1
Part.Size = Vector3.new(0.1,0.1,0.1)
Part.Parent = workspace

Trail.Color = ColorSequence.new(Rainbow)
Trail.Transparency = NumberSequence.new(Transparency)
Trail.Attachment0 = A
Trail.Attachment1 = B
Trail.Parent = Part

Humanoid.Died:Connect(function()
	Alive = false
end)

while Alive do
	local x = math.cos(os.clock()) * 5
	local y = math.sin(os.clock() * 3)
	local z = math.sin(os.clock()) * 5
	
	Part.Position = Part.Position:Lerp(RootPart.Position + Vector3.new(x,y,z),0.6)
	task.wait()
end

Part:Destroy()

--[[
i saw the owner of the game using a script
that give himself a ball orbiting around himself.

i thought it looked cool, so i wanted to make
something similar to it.
--]]

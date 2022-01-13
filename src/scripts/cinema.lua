local Board = Instance.new("Part")

local Interface = Instance.new("SurfaceGui")
local Player = Instance.new("VideoFrame")

local Floor = Instance.new("Part")

local Origin = Vector3.new(0,1,-30)
local x = 19.20
local y = 10.80

local LastSelection = 0

local Content =
{
	5608384572,
	5608392925,
	5608400507,
	5608403837,
	5608411652,
	5608390467,
	5670869502,
	5608402438,
	5608381934,
	5608389672,
	5608386285,
	5608413286,
	5608412605,
	5608250999,
	5608398904,
	5608410019,
	5608268502,
	5608410985,
	5608339667,
	5608327482,
	5608360493,
	5608349310,
	5608333583,
	5608422571,
	5608342423,
	5608330602,
	5608337069,
	5608359401,
	5670824523,
	5670802294,
	5608321996,
	5670826209,
	5670804538,
	5670799859,
	5670809466,
	5608369138,
	5670822962,
	5608370112,
	5608368298,
	5670785995,
	5608304953,
	5608303923,
	5608309393,
	5608292559,
	5608281849,
	5608297917,
	5670794788,
	5608290551,
	5608285055,
	5608310319
}

Interface.ClipsDescendants = true
Interface.PixelsPerStud = 100
Interface.Face = Enum.NormalId.Front
Interface.Adornee = Board
Interface.Parent = Board

Player.Volume = 0
Player.Size = UDim2.new(1,0,1,0)
Player.Parent = Interface

Board.Anchored = true
Board.Locked = true
Board.Size = Vector3.new(x,y,1)
Board.CFrame = CFrame.new(0,Origin.y + y / 2,Origin.z) * CFrame.Angles(0,math.rad(180),0)
Board.Color = Color3.new(0,0,0)
Board.Parent = workspace

for i=-2,2 do
	local Seat = Instance.new("Seat")
	
	Seat.Anchored = true
	Seat.Locked = true
	Seat.Size = Vector3.new(2,1.2,2)
	Seat.CFrame = CFrame.new(i * 3,Origin.y + 0.6,Origin.z + 15)
	Seat.BrickColor = BrickColor.new("Bright red")
	Seat.TopSurface = Enum.SurfaceType.Smooth
	Seat.BottomSurface = Enum.SurfaceType.Smooth
	Seat.Parent = workspace
end

Floor.Anchored = true
Floor.Locked = true
Floor.Size = Vector3.new(x + 3,2,y * 2 + 3)
Floor.CFrame = CFrame.new(Origin.x,Origin.y - 1,Origin.z + (y / 2))
Floor.BrickColor = BrickColor.new("Light stone grey")
Floor.TopSurface = Enum.SurfaceType.Universal
Floor.Parent = workspace

print("video frames are cool")

while true do
	local Choice = math.random(1,#Content)
	
	if LastSelection ~= Choice then
		LastSelection = Choice
		Player.Video = "rbxassetid://" .. Content[Choice]
		
		repeat task.wait()
		until Player.IsLoaded
		
		Player:Play()
		Player.Ended:Wait()
	end
end

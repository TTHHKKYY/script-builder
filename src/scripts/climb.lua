local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextAction = game:GetService("ContextActionService")

--[[
this script is a modified version of
www.roblox.com/games/8429846395/
--]]

---- globals

local Camera = workspace.CurrentCamera

repeat task.wait()
until Players.LocalPlayer.Character

local Character = Players.LocalPlayer.Character
local Humanoid = Players.LocalPlayer.Character:WaitForChild("Humanoid",math.huge)
local RootPart = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart",math.huge)

if Humanoid.RigType == Enum.HumanoidRigType.R15 then
	warn("Running this script with R15 will cause problems!")
end

local RayLength = 3
local RayFilter = {Character}

local FallTimer = math.huge

local Activity =
{
	Climbing = false,
	Sliding = false,
	Dashing = false,
}

---- end of globals

---- last hit

local LastHit = {}

function LastHit.Used(x)
	for _,Normal in pairs(LastHit) do
		if x == Normal then
			return true
		end
	end
	return false
end

function LastHit.Add(x)
	table.insert(LastHit,x)
end

function LastHit.Clear()
	for i in ipairs(LastHit) do
		LastHit[i] = nil
	end
end

---- end of last hit

local function HasCharacter()
	if Character and Humanoid and RootPart then
		return true
	end
	return false
end

local function ClearMovers()
	if HasCharacter() then
		for _,Mover in pairs(RootPart:GetChildren()) do
			if Mover:IsA("BodyMover") then
				Mover:Destroy()
			end
		end
	end
end

---- modules for void sb

local Ray do
	Ray = function(Origin,Look,Ignore,Whitelist)
		local Arguments = RaycastParams.new()
		local Result
		
		if type(Ignore) == "table" then
			Arguments.FilterDescendantsInstances = Ignore
		else
			Arguments.FilterDescendantsInstances = {Ignore}
		end
		if Whitelist then
			Arguments.FilterType = Enum.RaycastFilterType.Whitelist
		else
			Arguments.FilterType = Enum.RaycastFilterType.Blacklist
		end
		
		Result = workspace:Raycast(Origin,Look,Arguments)
		
		if Result then
			return {Part = Result.Instance,Hit = Result.Position,Normal = Result.Normal,Material = Result.Material}
		end
		return {}
	end
end

local Sound do
	Sound = {}
	
	local Index =
	{
		["Landing"] =
		{
			220194573,
			268941254
		},
		["Sliding"] =
		{
			22917014
		}
	}
	
	function Sound.LoadRandom(Name,Parent)
		if Index[Name] then
			local Sound = Instance.new("Sound")
			
			Sound.Volume = 1
			Sound.TimePosition = 0.1
			Sound.SoundId = "rbxassetid://" .. Index[Name][math.random(1,#Index[Name])]
			
			Sound.Ended:Connect(function()
				Sound:Destroy()
			end)
			Sound.Stopped:Connect(function()
				Sound:Destroy()
			end)
			
			Sound.Parent = Parent
			return Sound
		end
	end
end

---- create StarterPlayer
local StarterPlayer = {}

StarterPlayer.CharacterWalkSpeed = 32
StarterPlayer.CharacterJumpPower = 30
StarterPlayer.CharacterMaxSlopeAngle = 60

Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
Humanoid.MaxSlopeAngle = StarterPlayer.CharacterMaxSlopeAngle
Humanoid.JumpPower = StarterPlayer.CharacterJumpPower

workspace.Gravity = 90

---- character events

do
	local Alive = true
	local Healing = false
	
	---- reset
	
	Humanoid.Died:Connect(function()
		ClearMovers()
		LastHit.Clear()
		
		Humanoid = nil
		RootPart = nil
		Character = nil
		
		Alive = false
		Healing = false
		
		for k in pairs(Activity) do
			Activity[k] = false
		end
	end)
	
	---- healing
	
	Humanoid.HealthChanged:Connect(function(Health)
		if not Healing and Health < 100 then
			Healing = true
			task.wait(5)
			
			while Healing do
				if Humanoid.Health == 100 then
					Healing = false
					break
				end
				
				Humanoid.Health = math.min(Humanoid.Health + 1,100)
				task.wait(0.1)
			end
		end
	end)
	
	---- reset and fall damage
	
	Humanoid.StateChanged:Connect(function(_,State)
		if State == Enum.HumanoidStateType.Landed then
			local FallTime = os.clock() - FallTimer
			
			LastHit.Clear()
			
			Activity.Dashing = false
			
			if FallTime > 1.5 then
				local Damage = (FallTime - 1.5) * 80
				
				Sound.LoadRandom("Landing",workspace):Play()
				
				-- second chance. less than 10 damage below fatal
				if Humanoid.Health - Damage < 1 and Humanoid.Health - Damage > -10 then
					RootPart.Velocity = Vector3.new()
					Humanoid.Health = 1
					
					for i=1,800 do
						local Height = -2 + (i / 400)
						local Speed = StarterPlayer.CharacterWalkSpeed / 64 * (i / 12.5)
						local Jump = StarterPlayer.CharacterJumpPower / 32 * (i / 25)
						
						Humanoid.HipHeight = Height
						Humanoid.WalkSpeed = Speed
						Humanoid.JumpPower = 0
						
						if Jump > 15 then
							Humanoid.JumpPower = Jump
						end
						RunService.Stepped:Wait()
					end
				else
					-- take damage normally if above or below fatal
					Humanoid.Health = math.max(Humanoid.Health - Damage,0)
				end
			end
		end
		if State == Enum.HumanoidStateType.Freefall then
			FallTimer = os.clock()
		end
	end)
end

---- end of character events

ContextAction:BindActionAtPriority("Climb",function(_,State)
	if State == Enum.UserInputState.Begin and HasCharacter() and RootPart.Velocity.y > -80 then
		local Wall = Ray(RootPart.Position,RootPart.CFrame.LookVector * RayLength,RayFilter)
		
		-- wall jump
		if Activity.Climbing then
			ClearMovers()
			
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			RootPart.Velocity = Vector3.new(0,StarterPlayer.CharacterJumpPower + 10,0)
			Activity.Climbing = false
			return Enum.ContextActionResult.Sink
		end
		
		-- not climbing already, start climbing
		if Wall.Part and not LastHit.Used(Wall.Normal) then
			local Mover = Instance.new("BodyVelocity")
			local Align = Instance.new("BodyPosition")
			
			Align.MaxForce = Vector3.new(math.huge,0,math.huge)
			Align.Position = Vector3.new(Wall.Hit.x,0,Wall.Hit.z) + (Wall.Normal * 2)
			Align.Parent = RootPart
			
			Mover.MaxForce = Vector3.new(0,math.huge,0)
			Mover.Velocity = Vector3.new(0,50,0)
			Mover.Parent = RootPart
			
			Activity.Climbing = true
			LastHit.Add(Wall.Normal)
			
			while Activity.Climbing do
				local CheckWall = Ray(RootPart.Position,-Wall.Normal * RayLength,RayFilter)
				local CheckRoof = Ray(RootPart.Position + Vector3.new(0,2,0),Vector3.new(0,2,0),RayFilter)
				
				-- drop if there is a roof
				if CheckRoof.Part and CheckRoof.Part.CanCollide then
					ClearMovers()
					Activity.Climbing = false
					break
				end
				
				-- stop if theres no wall, or if the mover slowed down enough
				if Mover.Velocity.y < 0.01 or not CheckWall.Part then
					ClearMovers()
					
					Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					RootPart.Velocity = Vector3.new(0,StarterPlayer.CharacterJumpPower,0)
					Activity.Climbing = false
					break
				end
				
				Mover.Velocity = Mover.Velocity:Lerp(Vector3.new(),0.05)
				RunService.Heartbeat:Wait()
			end
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end,false,2000,Enum.KeyCode.Space)

ContextAction:BindActionAtPriority("Slide",function(_,State)
	if State == Enum.UserInputState.Begin and HasCharacter() then
		Activity.Sliding = true
		
		-- wait until there is a floor
		repeat local Floor = Ray(RootPart.Position,Vector3.new(0,-5,0),RayFilter); RunService.Heartbeat:Wait()
		until Floor.Part or not Activity.Sliding
		
		-- start sliding
		if Activity.Sliding then -- shift may have stopped being held
			local CrawlSpeed = StarterPlayer.CharacterWalkSpeed / 2
			local StopSpeed = StarterPlayer.CharacterWalkSpeed / 10
			local MoveDirection = Humanoid.MoveDirection
			
			local SlidingSound = Sound.LoadRandom("Sliding",workspace)
			local Mover = Instance.new("BodyVelocity")
			
			Mover.MaxForce = Vector3.new(math.huge,0,math.huge)
			Mover.Velocity = MoveDirection * (StarterPlayer.CharacterWalkSpeed + 10)
			Mover.Parent = RootPart
			
			Humanoid.HipHeight = -1.8
			Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed / 2
			
			SlidingSound.Looped = true
			SlidingSound:Play()
			
			while Activity.Sliding do
				local CheckFloor = Ray(RootPart.Position,Vector3.new(0,-5,0),RayFilter)
				local CheckWall = Ray(RootPart.Position,MoveDirection * 4,RayFilter)
				
				-- the player might have died.
				if not HasCharacter() then
					break
				end
				
				-- if there is a floor slow down the mover
				if CheckFloor.Part then
					Mover.Velocity = Mover.Velocity - (MoveDirection * 0.3)
				end
				
				-- if theres a wall, stop completely
				if CheckWall.Part and CheckWall.Part.CanCollide then
					ClearMovers()
					break
				end
				
				-- check if the player is trying to move during the slide
				if Humanoid.MoveDirection.Magnitude * CrawlSpeed > Mover.Velocity.Magnitude then
					ClearMovers()
					break
				end
				
				-- check if the BodyVelocity is below the StopSpeed
				if Mover.Velocity.Magnitude < StopSpeed then
					ClearMovers()
					break
				end
				
				-- pause the sliding sound if there is no floor, continue playing if there is.
				if CheckFloor.Part and not SlidingSound.IsPlaying then
					SlidingSound:Play()
				elseif not CheckFloor.Part and SlidingSound.IsPlaying then
					SlidingSound:Pause()
				end
				
				SlidingSound.Volume = Mover.Velocity.Magnitude / StarterPlayer.CharacterWalkSpeed
				RunService.Heartbeat:Wait()
			end
			
			SlidingSound:Stop()
			SlidingSound:Destroy()
		end
	end
	if State == Enum.UserInputState.End and HasCharacter() then
		ClearMovers()
		
		Humanoid.HipHeight = 0
		Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		Activity.Sliding = false
	end
	return Enum.ContextActionResult.Pass
end,false,2000,Enum.KeyCode.LeftShift)

ContextAction:BindActionAtPriority("Dash",function(_,State)
	if State == Enum.UserInputState.Begin and HasCharacter() and not Activity.Dashing then
		local Floor = Ray(RootPart.Position,Vector3.new(0,-10,0),RayFilter)
		
		-- the player must be airborne. the player must be moving. the player must not be falling too fast
		if not Floor.Part and Humanoid.MoveDirection.Magnitude > 0 and RootPart.Velocity.y > -60 then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			LastHit.Clear()
			
			Activity.Dashing = true
			
			-- if the player is sliding, do a stronger dash
			if Activity.Sliding then
				Activity.Sliding = false
				ClearMovers()
				
				RootPart.Velocity = Humanoid.MoveDirection * (StarterPlayer.CharacterWalkSpeed * 4)
				return Enum.ContextActionResult.Sink
			end
			
			-- normal dash
			RootPart.Velocity = Humanoid.MoveDirection * (StarterPlayer.CharacterWalkSpeed * 3)
			
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end,false,1900,Enum.KeyCode.Space)

local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = owner

local Camera = workspace.CurrentCamera

local Mouse = LocalPlayer:GetMouse()

local HeldPart
local Align,Gyro

local function Drop(Throw)
	Align:Destroy()
	Gyro:Destroy()
	
	HeldPart.LocalTransparencyModifier = HeldPart.Transparency
	
	if Throw then
		HeldPart.Velocity = HeldPart.Velocity + HeldPart.CFrame.LookVector * 40
	end
	
	LocalPlayer.DropObject:FireServer()
	HeldPart = nil
end

local function Hold()
	while HeldPart do
		local Head = LocalPlayer.Character:FindFirstChild("Head")
		
		if Head then
			Align.Position = Head.Position + (Camera.CFrame.LookVector * math.max(HeldPart.Size.Magnitude,8))
			Gyro.CFrame = Camera.CFrame
		end
		
		RunService.RenderStepped:Wait()
	end
end

UserInput.InputBegan:Connect(function(Input,Focused)
	if not Focused and UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) then
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if HeldPart then
				Drop(true)
			else
				local Target = LocalPlayer.GrabObject:InvokeServer(Mouse.Target)
				
				if Target then
					Align = Instance.new("BodyPosition")
					
					Align.Name = "GrabAlign"
					Align.P = 40000
					Align.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
					Align.Parent = Target
					
					Gyro = Instance.new("BodyGyro")
					
					Gyro.Name = "GrabGyro"
					Gyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
					Gyro.Parent = Target
					
					Target.LocalTransparencyModifier = math.max(Target.Transparency,0.5)
					
					HeldPart = Target
					
					Hold()
				end
			end
		end
		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			if HeldPart then
				Drop(false)
			end
		end
	end
end)

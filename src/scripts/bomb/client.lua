local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local Detonate = Players.LocalPlayer.BombToolDetonateEvent
local Throw = Players.LocalPlayer.BombToolThrowEvent

while true do
	local Input,Proccessed = UserInput.InputBegan:Wait()
	
	if not Proccessed then
		if Input.KeyCode == Enum.KeyCode.T then
			Detonate:FireServer()
		end
		if Input.KeyCode == Enum.KeyCode.R then
			Throw:FireServer(Camera.CFrame)
		end
	end
end

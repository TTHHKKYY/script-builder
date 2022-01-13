local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))

local LocalPlayer = owner
local User = ""
local Repo = ""

LocalPlayer.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	local Command = Arguments[1]
	local Value = Arguments[2]
	
	-- /help is already in use by the default chat scripts
	if Command == "/githelp" then
		print("/user NAME")
		print("/repo NAME")
		print("/index [PATH]")
		print("/loadfile PATH")
		
		print("Current user: " .. User)
		print("Current repository: " .. Repo)
	end
	
	if Command == "/user" then
		assert(Value,"Missing username.")
		print("Set user to " .. Value)
		
		User = Value
	end
	if Command == "/repo" then
		assert(Value,"Missing repository name.")
		print("Set repository to " .. Value)
		
		Repo = Value
	end
	
	if Command == "/index" then
		assert(User ~= "","User is not set.")
		assert(Repo ~= "","Repository is not set.")
		
		local Index = Http:GetAsync(string.format("https://api.github.com/repos/%s/%s/contents/%s",User,Repo,Value or "/"))
		local IndexData = Http:JSONDecode(Index)
		
		for _,File in pairs(IndexData) do
			print("/" .. File["path"])
		end
	end
	
	if Command == "/loadfile" then
		assert(User ~= "","User is not set.")
		assert(Repo ~= "","Repository is not set.")
		assert(Value,"Path is missing.")
		
		local Data = Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s/%s",User,Repo,Value))
		local Compiled,Error = loadstring(Data)
		
		if Compiled then
			Compiled()
		else
			error(Error)
		end
	end
end)

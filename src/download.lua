local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))
print("Say /githelp for commands and usage.")

local LocalPlayer = owner

local User = ""
local Repo = ""

local function IsValid()
	assert(User ~= "","User is not set.")
	assert(Repo ~= "","Repository is not set.")
end

LocalPlayer.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	local Command = Arguments[1]
	local Value = Arguments[2]
	
	-- /help is already in use by the default chat scripts
	if Command == "/githelp" then
		print("/user NAME")
		print("/repo NAME")
		print("/index [PATH]")
		print("/loadfile BRANCH/PATH")
		print("/getmain")
		
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
		IsValid()
		
		function Recurse(Path)
			local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/%s/contents/%s",User,Repo,Path))
			local ListData = Http:JSONDecode(List)
			
			for _,File in pairs(ListData) do
				if File["type"] == "dir" then
					print("/" .. File["path"] .. "/")
					Recurse(File["path"])
				end
				if File["type"] == "file" then
					print("/" .. File["path"])
				end
			end
		end
		
		Recurse(Value or "/")
	end
	
	if Command == "/loadfile" then
		IsValid()
		assert(Value,"Path is missing.")
		
		local Data = Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s/%s",User,Repo,Value))
		local Compiled,Error = loadstring(Data)
		
		if Compiled then
			Compiled()
		else
			error(Error)
		end
	end
	
	if Command == "/getmain" then
		IsValid()
		
		local Repository = Http:GetAsync(string.format("https://api.github.com/repos/%s/%s",User,Repo))
		local RepisotryData = Http:JSONDecode(Repository)
		
		print("The default branch is " .. RepisotryData["default_branch"])
	end
end)

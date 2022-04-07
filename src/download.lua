local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))
print("Say /githelp for commands and usage.")

local LocalPlayer = owner

-- use globals to avoid data loss after using g/ns
if not _G[LocalPlayer] then
	_G[LocalPlayer] = {}
end
if not _G[LocalPlayer].GithubUser and not _G[LocalPlayer].GithubRepo then
	_G[LocalPlayer].GithubUser = ""
	_G[LocalPlayer].GithubRepo = ""
end

local Settings = _G[LocalPlayer]

local function IsValid()
	assert(Settings.GithubUser ~= "","User is not set.")
	assert(Settings.GithubRepo ~= "","Repository is not set.")
end

LocalPlayer.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	local Command = Arguments[1]
	local Value = Arguments[2]
	
	-- /help is already in use by the default chat system
	if Command == "/githelp" then
		print("/user NAME")
		print("/repo NAME")
		print("/index [PATH] [RECURSE]")
		print("/load BRANCH/PATH")
		print("/loadcl BRANCH/PATH")
		print("/getmain")
		
		print() -- newline
		print("Current user: " .. Settings.GithubUser)
		print("Current repository: " .. Settings.GithubRepo)
	end
	
	if Command == "/user" then
		assert(Value,"Missing username.")
		print("Set user to " .. Value)
		
		Settings.GithubUser = Value
	end
	if Command == "/repo" then
		assert(Value,"Missing repository name.")
		print("Set repository to " .. Value)
		
		Settings.GithubRepo = Value
	end
	
	if Command == "/index" then
		IsValid()
		
		local ShouldRecurse = Arguments[3]
		local Path = Value or "/"
		
		function Recurse(Path)
			local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/%s/contents/%s",Settings.GithubUser,Settings.GithubRepo,Path))
			local ListData = Http:JSONDecode(List)
			
			for _,File in pairs(ListData) do
				if File["type"] == "dir" then
					print("/" .. File["path"] .. "/")
					
					if ShouldRecurse then
						Recurse(File["path"])
					end
				end
				if File["type"] == "file" then
					print("/" .. File["path"])
				end
			end
		end
		
		print("Index of " .. Path)
		Recurse(Path)
	end
	
	if Command == "/load" or Command == "/loadcl" then
		IsValid()
		assert(Value,"Path is missing.")
		
		local Data = Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s/%s",Settings.GithubUser,Settings.GithubRepo,Value))
		
		-- server
		if Command == "/load" then
			NS(Data,workspace)
		end
		
		-- client
		if Command == "/loadcl" then
			NLS(Data,LocalPlayer.Backpack)
		end
	end
	
	if Command == "/getmain" then
		IsValid()
		
		local Repository = Http:GetAsync(string.format("https://api.github.com/repos/%s/%s",Settings.GithubUser,Settings.GithubRepo))
		local RepisotryData = Http:JSONDecode(Repository)
		
		print("The default branch is " .. RepisotryData["default_branch"])
	end
end)

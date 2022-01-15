--[[
	package-based version of download.lua

	authors: @rwilliaise @TTHHKKYY
]]

local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))
print("Say /githelp for commands and usage.")

local LocalPlayer = owner

-- setup global variables, to avoid data loss after using g/ns
if not _G[LocalPlayer] then
	_G[LocalPlayer] = {}
end
if not _G[LocalPlayer].GithubRepo then
	_G[LocalPlayer].GithubRepo = ""
end

local Settings = _G[LocalPlayer]

local function IsValid()
	assert(Settings.GithubRepo ~= "","Repository is not set.")
end

---- package management

local function GetPkgs()

	function Recurse(Path)
		local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s",Settings.GithubRepo,Path))
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
	
	print("Index of the default branch:")
	Recurse(Value or "/")
end

local function ResolvePkg()

end

local function Fetch(Path)
	return Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s"), Settings.GithubRepo, Path)
end

local stdlibs = Fetch("packages/src/download.lua")

local function PrependLibs(script)
	local start = "local PKG_ROOT = \"" .. Settings.GithubRepo "\"\n"
	start = start .. stdlibs

	return start .. script
end

---- end of package management

LocalPlayer.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	local Command = Arguments[1]
	local Value = Arguments[2]
	
	-- /help is already in use by the default chat scripts
	if Command == "/githelp" then
		print("/repo USER/NAME")
		print("\tsets the current repository")
		print("/index [PATH]")
		print("\tlist all files under PATH or root")
		print("/findpkg [PATH]")
		print("\tfind all packages under PATH or root")
		print("/load PKG")
		print("\tloads and runs a package server-side")
		print("/loadcl PKG")
		print("\tloads and runs a package client-side")
		print("/getmain")
		print("\tfetches the default branch")
		
		print("") -- newline
		print("Current repository: " .. Settings.GithubRepo)
	end

	if Command == "/repo" then
		assert(Value,"Missing repository name.")

		local Split = string.split(Value, "/")
		assert(#Split == 2, "Invalid repo!")

		local Repository = Http:GetAsync(string.format("https://api.github.com/repos/%s",Value))

		if Repository.message == "Not Found" then
			error("Repository not found.")
		end

		print("Set repository to " .. Value)
		
		Settings.GithubRepo = Value
	end
	
	if Command == "/index" then
		IsValid()
		
		local function Recurse(Path)
			local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s",Settings.GithubRepo,Path))
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
		
		print("Index of the default branch:")
		Recurse(Value or "/")
	end

	if Command == "/findpkg" then
		IsValid()

		function Recurse(Path)
			local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s",Settings.GithubRepo,Path))
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
		
		print("Index of the default branch:")
		Recurse(Value or "/")
	end
	
	if Command == "/load" or Command == "/loadcl" then
		IsValid()
		assert(Value,"Path is missing.")
		
		local Data = Fetch(Value)
		
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
		
		local Repository = Http:GetAsync(string.format("https://api.github.com/repos/%s",Settings.GithubRepo))
		local RepositoryData = Http:JSONDecode(Repository)
		
		print("The default branch is " .. RepisotryData["default_branch"])
	end
end)

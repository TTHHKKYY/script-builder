--[[
	package-based version of download.lua

	example download.json:

	{
		"name": "farding",
		"main": "main.lua"
	}

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

local RepoCache = {}

local function IsValid()
	assert(Settings.GithubRepo ~= "","Repository is not set.")
end

---- package management

local function Fetch(Path, Repo)
	return Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s"), Repo or Settings.GithubRepo, Path)
end

local stdlibs = Fetch("packages/src/download.lua", "TTHHKKYY/script-builder")

local function GetDefaultBranch(Repo)
	local Cached = RepoCache[Repo]
	if Cached then
		if os.clock() - Cached.TTL > 0 then
			RepoCache[Repo] = nil
		elseif Cached.DefaultBranch then
			return Cached.DefaultBranch
		end
	end

	local Repository = Http:GetAsync(string.format("https://api.github.com/repos/%s",Repo or Settings.GithubRepo))
	local RepositoryData = Http:JSONDecode(Repository)

	RepoCache[Repo] = Cached or {TTL = os.clock() + 60}
	RepoCache[Repo].DefaultBranch = RepositoryData["default_branch"]

	return RepoCache[Repo].DefaultBranch
end

local function GetContents(RepoStart, Branch, Repo)
	local Out = {}

	Branch = Branch or GetDefaultBranch(Repo)
	RepoStart = RepoStart or "/"

	local Length = #RepoStart

	local function Recurse(StartPath)
		local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s",Repo,StartPath))
		local ListData = Http:JSONDecode(List)

		for _, File in pairs(ListData) do
			local Path = File["path"]
			local Name = File["name"]
			if File["type"] == "dir" then
				table.insert(Out, { Name = Name, Path = Path:sub(Length, -1), FullPath = Path, Type = "dir", Parent = Path:sub(1, -#name - 1) })
				Recurse(Path)
			end
			if File["type"] == "file" then
				table.insert(Out, { Name = Name, Path = Path:sub(Length, -1), FullPath = Path, Type = "file", Parent = Path:sub(1, -#name - 1), Data = Fetch(Branch .. "/" .. Path) })
				Recurse(Path)
			end
		end
	end

	Recurse(RepoStart)

	return Out
end

local function GetPkgs(StartPath, Branch, Repo)
	local Packages = {}

	Repo = Repo or Settings.GithubRepo
	Branch = Branch or GetDefaultBranch(Repo)
	StartPath = StartPath or "/"

	local Length = #StartPath

	local function Recurse(Path)
		local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s?ref=%s",Repo,Path,Branch))
		local ListData = Http:JSONDecode(List)
		
		for _,File in pairs(ListData) do
			if File["type"] == "dir" then
				Recurse(File["path"])
			end
			if File["type"] == "file" and File["name"] == "download.json" then
				local path = File["path"]
				local name = "download.json"
				local data = Http:JSONDecode(Fetch(Branch .. "/" .. path))

				if data and data.name then
					Packages[name] = { Name = data.name, Path = Path:sub(Length, -1), Type = "file", Parent = Path:sub(Length, -#name - 1), Data = data }
				end
			end
		end
	end
	Recurse(StartPath)

	return Packages
end

local function PrependLibs(target, libs)
	local start = "local PKG_ROOT = \"" .. Settings.GithubRepo "\"\n"
	start = start .. "local PATH = \"" .. target.Path .. "\"\n"
	start = start .. ("local __stdlibs = [===[%s]===]"):format(stdlibs)

	-- require resolve
	start = start .. "local __scripts = {\n"

	for k, v in pairs(libs) do
		start = start .. ("[\"%s\"] = { Source = [===[%s]===], Parent = \"%s\" }"):format(k, v.Source, v.Parent)
	end

	start = start .. "}\n\n"

	start = start .. stdlibs
	return start .. target.Source
end

local function RunPkg(name)
	local Pkgs = GetPkgs()
	local Pkg = Pkgs[name]

	if Pkg and Pkg.Data and Pkg.Data.main then
		local libs = {}

		local PkgContents = GetContents(Pkg.Parent, nil, Settings.GithubRepo)

		local function ProcessLib(File, Parent)
			if File.Path:find("%.lua$") then
				local original = Parent
				if Parent then
					Parent = Parent .. "/"
				else
					Parent = ""
				end

				libs[Parent .. File.Name] = { Source = File.Data, Path = File.Path, Parent = original or "root" }
			end
		end

		local function RecurseDependencies(Child, Repo)
			print("Downloading package " .. Child.Name)
			local Contents = GetContents(Child.Parent, nil, Repo)

			for _, File in pairs(Contents) do
				ProcessLib(File, Child.Name)
			end

			if Child.dependencies then
				for k, v in pairs(Child.dependencies) do
					local dependencyPackages = GetPkgs("/", nil, k)

					local dependency = dependencyPackages[v]
					if dependency then
						RecurseDependencies(dependency, k)
					end
				end
			end
		end

		RecurseDependencies(Pkg, Settings.GithubRepo)

		
	end
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
		print("/index PATH")
		print("\tlist all files under PATH or root")
		print("/findpkg PATH")
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

		local Packages = GetPkgs(Value)

		for _, v in pairs(Packages) do
			if v.Name and v.Data then
				print(v.Name)
				print("\t" .. (v.Data.description or "No description provided."))
			end
		end
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
		
		print("The default branch is " .. GetDefaultBranch())
	end
end)

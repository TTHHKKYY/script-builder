--[[
	package-based version of download.lua

	example download.json:
	{
		"name": "test-pkg",
		"main": "main.lua",
		"dependencies": {
			"Black-Mesas/sb-pkgs": "helper-lib"
		}
	}

	this will allow you to access helper-lib 

	authors: @rwilliaise @TTHHKKYY
]]

local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))
print("Say /githelp for commands and usage.")

local LocalPlayer = owner

-- setup global variables, to avoid data loss after using g/ns
_G[LocalPlayer] = _G[LocalPlayer] or {}
_G[LocalPlayer].GithubRepo = _G[LocalPlayer].GithubRepo or ""
_G[LocalPlayer].RepoIndex = _G[LocalPlayer].RepoIndex or {}
_G[LocalPlayer].FetchIndex = _G[LocalPlayer].FetchIndex or {}

local Settings = _G[LocalPlayer]

local RepoCache = {}

local function IsValid()
	assert(Settings.GithubRepo ~= "","Repository is not set.")
end

---- package management

local function Fetch(Path, Repo, NoCache)
	Repo = Repo or Settings.GithubRepo

	if (not NoCache) and Settings.FetchIndex[Repo] and Settings.FetchIndex[Repo][Path] then
		local cache = Settings.FetchIndex[Repo][Path]

		if os.clock() - cache.TTD > 0 then
			Settings.FetchIndex[Repo][Path] = nil
		else
			return cache.Data
		end
	end
	local out = Http:GetAsync(string.format("https://raw.githubusercontent.com/%s/%s", Repo, Path))

	Settings.FetchIndex[Repo] = Settings.FetchIndex[Repo] or {}
	Settings.FetchIndex[Repo][Path] = { TTD = os.clock() + 120, Data = out }

	return out
end

local stdlibs = Fetch("packages/src/stdlibs.lua", "TTHHKKYY/script-builder")

local function GetDefaultBranch(Repo)
	Repo = Repo or Settings.GithubRepo
	local Cached = RepoCache[Repo]
	if Cached then
		if os.clock() - Cached.TTD > 0 then
			RepoCache[Repo] = nil
		elseif Cached.DefaultBranch then
			return Cached.DefaultBranch
		end
	end

	local Repository = Http:GetAsync(string.format("https://api.github.com/repos/%s", Repo or Settings.GithubRepo))
	local RepositoryData = Http:JSONDecode(Repository)

	RepoCache[Repo] = Cached or {TTD = os.clock() + 120}
	RepoCache[Repo].DefaultBranch = RepositoryData["default_branch"]

	return RepoCache[Repo].DefaultBranch
end

local function GetContents(RepoStart, Branch, Repo)

	Repo = Repo or Settings.GithubRepo
	Branch = Branch or GetDefaultBranch(Repo)
	RepoStart = RepoStart or "/"

	local FileSystem

	if Settings.RepoIndex[Repo] and Settings.RepoIndex[Repo][Branch] then
		local cached = Settings.RepoIndex[Repo][Branch] 

		if os.clock() - cached.TTD > 0 then
			Settings.RepoIndex[Repo][Branch] = nil
		end
	end

	if Settings.RepoIndex[Repo] and Settings.RepoIndex[Repo][Branch] then
		FileSystem = Settings.RepoIndex[Repo][Branch]
	else
		FileSystem = {
			TTD = os.clock() + 3600,
			Files = {}
		}
	
		local function Recurse(StartPath)
			local List = Http:GetAsync(string.format("https://api.github.com/repos/%s/contents/%s",Repo,StartPath))
			local ListData = Http:JSONDecode(List)

			for _, File in pairs(ListData) do
				if type(File) ~= "table" then continue end
				local Path = File["path"]
				local Name = File["name"]
				if File["type"] == "dir" then
					local outFile = { Name = Name, FullPath = Path, Type = "dir", Parent = StartPath }
					FileSystem.Files[Path] = outFile
	
					Recurse(Path)
				end
				if File["type"] == "file" then
					local outFile = { Name = Name, FullPath = Path, Type = "file", Parent = StartPath }
					FileSystem.Files[Path] = outFile
				end
			end
		end

		Recurse("")

		Settings.RepoIndex[Repo] = Settings.RepoIndex[Repo] or {}
		Settings.RepoIndex[Repo][Branch] = FileSystem
	end


	if RepoStart:sub(-1, -1) ~= "/" then
		RepoStart = RepoStart .. "/" -- trailing slash ALWAYS
	end
	
	local Out = {}

	for _, v in pairs(FileSystem.Files) do
		if #v.FullPath <= #RepoStart then continue end
		for i = 1, #RepoStart do
			if v.FullPath:sub(i, i) ~= RepoStart:sub(i, i) then
				continue
			end
		end

		table.insert(Out, { Name = v.Name, FullPath = v.FullPath, Path = v.FullPath:sub(#RepoStart + 1), Type = v.Type, Parent = v.Parent })
	end

	return Out
end

local function GetPkgs(StartPath, Branch, Repo)

	Repo = Repo or Settings.GithubRepo
	Branch = Branch or GetDefaultBranch(Repo)
	RepoStart = RepoStart or "/"

	local Packages = {}
	local Contents = GetContents(StartPath, Branch, Repo)

	for _, File in pairs(Contents) do
		if File.Name == "download.json" and File.Type == "file" then
			local path = File.FullPath
			local name = "download.json"
			local data = Http:JSONDecode(Fetch(Branch .. "/" .. path))

			if data and data.name then
				Packages[data.name] = { Name = data.name, FullPath = File.FullPath, Path = File.Path, Parent = File.Parent, Data = data }
			end
		end
	end

	return Packages
end

local function PrependLibs(target, libs)
	local start = "local PKG_ROOT = \"" .. Settings.GithubRepo .. "\"\n"
	start = start .. "local PKG_NAME = \"" .. target.PackageName .. "\""
	start = start .. "local PATH = \"" .. target.Path .. "\"\n"
	start = start .. ("local __stdlibs = [===[%s]===]\n"):format(stdlibs)

	-- require resolve
	start = start .. "local __scripts = {\n"

	for k, v in pairs(libs) do
		start = start .. ("\t[\"%s\"] = { Source = [=[%s]=], Path = \"%s\", Parent = \"%s\" },\n"):format(k, v.Source, v.Path, v.Parent)
	end

	start = start .. "}\n\n"

	start = start .. stdlibs
	return start .. target.Source
end

local function RunPkg(name, branch)
	branch = branch or GetDefaultBranch(Settings.GithubRepo)

	local Pkgs = GetPkgs()
	local Pkg = Pkgs[name]

	assert(Pkg, "No package found named " .. name)
	assert(Pkg.Data, "Malformed package " .. name)
	assert(Pkg.Data.main, "Can't run package " .. name)

	local PkgContents = GetContents(Pkg.Parent, branch, Settings.GithubRepo)
	local Main

	for _, v in pairs(PkgContents) do
		if v.Path == Pkg.Data.main then
			Main = v
		end
	end

	assert(Main, Pkg.Data.main .. " not found!")

	local MainData = Fetch(branch .. "/" .. Main.FullPath)

	local libs = {}

	local function ProcessLib(File, Repo, Branch, Parent)
		if File.Path:find("%.lua$") then
			local original = Parent
			if Parent then
				Parent = Parent .. "/"
			else
				Parent = ""
			end

			local data = Fetch(Branch .. "/" .. File.FullPath, Repo)
			libs[Parent .. File.Path] = { Source = data, __named = File.Path, Path = File.FullPath, Parent = original or "" }
		end
	end

	local function RecurseDependencies(Child, Branch, Repo, Root)
		print("Downloading package " .. Child.Name)

		Branch = Branch or GetDefaultBranch(Repo)
		local Contents = GetContents(Child.Parent, Branch, Repo)

		for _, File in pairs(Contents) do
			ProcessLib(File, Repo, Branch, if Root then nil else Child.Name)
		end

		if Child.Data.dependencies then
			for drepo, dpkg in pairs(Child.Data.dependencies) do
				local searchRepo, searchBranch
				local split = string.split(drepo, "#")
		
				searchRepo = split[1]
				if #split0 > 1 then
					searchBranch = split[2]
				end

				local dependencyPackages = GetPkgs("/", searchBranch, searchRepo)

				local dependency = dependencyPackages[dpkg]
				if dependency then
					RecurseDependencies(dependency, searchBranch, searchRepo)
				end
			end
		end
	end

	RecurseDependencies(Pkg, nil, Settings.GithubRepo, true)

	local Runnable = PrependLibs({Source = MainData, Path = Main.FullPath, PackageName = name}, libs)

	NS(Runnable, workspace)
end

---- end of package management

LocalPlayer.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	local Command = Arguments[1]
	local Value = Arguments[2]
	
	-- /help is already in use by the default chat scripts
	if Command == "/githelp" then
		print("/repo USER/NAME")
		print("   sets the current repository")
		print("/cc USER/NAME[#BRANCH]")
		print("   clear cache of repository [and branch] (expensive!)")
		print("/index [PATH[#BRANCH]]")
		print("   list all files under PATH or root")
		print("/findpkg [PATH[#BRANCH]]")
		print("   find all packages under PATH or root")
		print("/load PKG")
		print("   loads and runs a package server-side")
		print("/loadcl PKG")
		print("   loads and runs a package client-side")
		print("/getmain")
		print("   fetches the default branch")
		
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
	
	if Command == "/cc" then
		IsValid()

		local repo, branch
		local split0 = string.split(Value, "#")

		repo = split0[1]
		if #split0 > 1 then
			branch = split0[2]
		end

		if not branch then
			Settings.RepoIndex[repo] = nil
			Settings.FetchIndex[repo] = nil
			print(("Cleared cache for repo %s"):format(repo))
		else
			Settings.RepoIndex[repo][branch] = nil
			print(("Cleared cache for repo %s, branch %s"):format(repo, branch))
		end
	end

	if Command == "/index" then
		IsValid()

		local path, branch

		if Value or Value ~= "" then
			local split0 = string.split(Value, "#")

			path = split0[1]
			if #split0 > 1 then
				branch = split0[2]
			end
		end
		
		for _, v in pairs(GetContents(path, branch)) do
			print(v.FullPath)
		end
	end

	if Command == "/findpkg" then
		IsValid()
		
		local path, branch

		if Value or Value ~= "" then
			local split0 = string.split(Value, "#")

			path = split0[1]
			if #split0 > 1 then
				branch = split0[2]
			end
		end

		local Packages = GetPkgs(path, branch)

		for _, v in pairs(Packages) do
			if v.Name and v.Data then
				print(v.Name)
				print("   " .. (v.Data.desc or "No description provided."))
			end
		end
	end
	
	if Command == "/load" then
		IsValid()
		assert(Value,"Package argument is missing.")
		RunPkg(Value)
	end
	
	if Command == "/getmain" then
		IsValid()
		
		print("The default branch is " .. GetDefaultBranch())
	end
end)

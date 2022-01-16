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
	RepoStart = RepoStart or ""

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

	if RepoStart == "/" then
		RepoStart = ""
	end
	
	local Out = {}

	for _, v in pairs(FileSystem.Files) do
		if #v.FullPath < #RepoStart then
			continue 
		end
		local fail = false
		for i = 1, #RepoStart do
			if v.FullPath:sub(i, i) ~= RepoStart:sub(i, i) then
				fail = true
				break
			end
		end

		if fail then continue end

		table.insert(Out, { Name = v.Name, FullPath = v.FullPath, Path = v.FullPath:sub(#RepoStart + 2), Type = v.Type, Parent = v.Parent })
	end

	return Out
end

local function GetPkgs(StartPath, Branch, Repo)

	Repo = Repo or Settings.GithubRepo
	Branch = Branch or GetDefaultBranch(Repo)
	StartPath = StartPath or ""

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

local function PrependLibs(target, libs, preprocessor)
	local start = "local PKG_ROOT = \"" .. Settings.GithubRepo .. "\"\n"
	start = start .. "local PKG_NAME = \"" .. target.PackageName .. "\"\n"
	start = start .. "local PATH = \"" .. target.Path .. "\"\n\n"

	-- require resolve
	start = start .. "local __scripts = {\n"

	for k, v in pairs(libs) do
		start = start .. ("   [\"%s\"] = { Path = \"%s\", Branch = \"%s\", Repo = \"%s\", Parent = \"%s\" },\n"):format(k, v.Path, v.Branch, v.Repo, v.Parent)
	end

	start = start .. "}\n\n"
	start = start .. stdlibs

	local OutSource = target.Source
	if preprocessor and (#preprocessor > 0) then
		start = start .. "---- preprocessor start\n\n"
		for _, v in pairs(preprocessor) do
			local success, err = pcall(function()
				local processor = loadstring(v)()

				if processor.AppendLibs then
					start = processor.AppendLibs(target, libs, start)
				end

				if processor.ReplaceSource then
					OutSource = processor.ReplaceSource(target, libs, OutSource)
				end
			end)

			if not success then
				warn("Preprocessor failure! Error: " .. err)
			end
		end
		start = start .. "\n---- end of preprocessor\n\n"
	end
	return start .. OutSource
end

local function GetDependencies(TargetPkg, TargetBranch, TargetRepo, Main)
	local libs = {}

	local function ProcessLib(File, Repo, Branch, Parent)
		if File.Path:find("%.lua$") then
			if libs[File.Path] then
				warn("Dependency " .. file.Path .. " (" .. libs[File.Path].Repo .. ") already exists!")
			end
			libs[File.Path] = { __named = File.Path, Branch = Branch, Repo = Repo, Path = File.FullPath, Parent = Parent or "" }
		end
	end

	local function RecurseDependencies(Child, Branch, Repo)
		print("Loading package " .. Child.Name)

		Branch = Branch or GetDefaultBranch(Repo)
		local Contents = GetContents(Child.Parent, Branch, Repo)

		for _, File in pairs(Contents) do
			if File.FullPath == Main.FullPath then continue end
			if File.Path == Child.Data.main then continue end
			ProcessLib(File, Repo, Branch, Child.Name)
		end

		if Child.Data.dependencies then
			for drepo, dpkgs in pairs(Child.Data.dependencies) do
				if type(dpkgs) ~= "table" then 
					dpkgs = {dpkgs}
				end

				local searchRepo, searchBranch
				local split = string.split(drepo, "#")
		
				searchRepo = split[1]
				if #split > 1 then
					searchBranch = split[2]
				end

				local dependencyPackages = GetPkgs("", searchBranch, searchRepo)
				
				for _, dpkg in pairs(dpkgs) do
					local dependency = dependencyPackages[dpkg]
					if dependency then
						RecurseDependencies(dependency, searchBranch, searchRepo)
					end
				end
			end
		end
	end

	RecurseDependencies(TargetPkg, TargetBranch, TargetRepo)
	return libs
end

local function FetchMain(Pkg, repo, branch)
	branch = branch or GetDefaultBranch(Settings.GithubRepo)

	local PkgContents = GetContents(Pkg.Parent, branch, repo)
	local Main

	for _, v in pairs(PkgContents) do
		if v.Path == Pkg.Data.main then
			Main = v
		end
	end

	assert(Main, Pkg.Data.main .. " not found!")

	local MainData = Fetch(branch .. "/" .. Main.FullPath)

	return Main, MainData
end

local function GetPkgCode(name, branch)
	branch = branch or GetDefaultBranch(Settings.GithubRepo)

	local Pkgs = GetPkgs("", branch)
	local Pkg = Pkgs[name]

	assert(Pkg, ("No package found named %s"):format(name))
	assert(Pkg.Data, ("Malformed package %s"):format(name))
	assert(Pkg.Data.main, ("Can't run package %s"):format(name))

	local Main, MainData = FetchMain(Pkg, Settings.GithubRepo, branch)
	local libs = GetDependencies(Pkg, branch, Settings.GithubRepo, Main)

	local preprocessors = {}

	if Pkg.Data.preprocessor then
		for drepo, dpkgs in pairs(Pkg.Data.preprocessor) do
			if type(dpkgs) ~= "table" then 
				dpkgs = {dpkgs}
			end

			local searchRepo, searchBranch
			local split = string.split(drepo, "#")

			searchRepo = split[1]
			if #split > 1 then
				searchBranch = split[2]
			end

			local pPkgs = GetPkgs("", searchBranch, searchRepo)

			for _, dpkg in pairs(dpkgs) do
				local dependency = pPkgs[dpkg]
				if dependency then
					if not dependency.Data or not dependency.Data.main then
						warn(("Preprocessor %s is not runnable!"):format(dpkg))
						continue 
					end

					local pMain, pMainData = FetchMain(dependency, searchRepo, searchBranch)
					local dLibs = GetDependencies(dependency, searchBranch, searchRepo, pMain)
					print("Applying preprocessor " .. searchRepo .. "/" .. dpkg)
					table.insert(preprocessors, PrependLibs({Source = pMainData, Path = pMain.FullPath, PackageName = dpkg}, dLibs))
				end
			end
		end
	end

	return PrependLibs({Source = MainData, Path = Main.FullPath, PackageName = name}, libs, preprocessors)
end

local function RunPkg(name, branch)
	branch = branch or GetDefaultBranch(Settings.GithubRepo)

	local Runnable = GetPkgCode(name, branch)

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
		print("/reload OBJ")
		print("   fetch an specified object again. Possible values: stdlibs")
		print("/[f]cc [USER/NAME[#BRANCH]]")
		print("   clear [both] cache(s) of current repository [or branch] (expensive!)")
		print("/index [PATH[#BRANCH]]")
		print("   list all files under PATH or root")
		print("/findpkg [PATH[#BRANCH]]")
		print("   find all packages under PATH or root")
		print("/dump PKG")
		print("   dump run code from package")
		print("/load PKG")
		print("   loads and runs a package server-side")
		print("/loadcl PKG")
		print("   loads and runs a package client-side")
		print("/rates")
		print("   gets current ratelimit")
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

		local RepositoryData = Http:JSONDecode(Repository)
		if RepositoryData.message == "Not Found" then
			error("Repository not found.")
		end

		print("Set repository to " .. Value)
		
		Settings.GithubRepo = Value
	end
	
	if Command == "/reload" then
		if Value == "stdlibs" then

			return
		end
		error("Invalid argument!")
	end

	if Command == "/cc" then
		IsValid()

		if Value and Value ~= "" then
			local repo, branch
			local split0 = string.split(Value, "#")

			repo = split0[1]
			if #split0 > 1 then
				branch = split0[2]
			end

			if not branch then
				Settings.FetchIndex[repo] = nil
				print(("Cleared fetch cache for repo %s"):format(repo))
			else
				Settings.FetchIndex[repo][branch] = nil
				print(("Cleared fetch cache for repo %s, branch %s"):format(repo, branch))
			end
		else
			Settings.FetchIndex[Settings.GithubRepo] = nil
			print(("Cleared fetch cache for repo %s"):format(Settings.GithubRepo))
		end
	end

	if Command == "/fcc" then
		IsValid()

		if Value and Value ~= "" then
			local repo, branch
			local split0 = string.split(Value, "#")

			repo = split0[1]
			if #split0 > 1 then
				branch = split0[2]
			end

			if not branch then
				Settings.FetchIndex[repo] = nil
				Settings.RepoIndex[repo] = nil
				print(("Cleared all caches for repo %s"):format(repo))
			else
				Settings.FetchIndex[repo][branch] = nil
				Settings.RepoIndex[repo][branch] = nil
				print(("Cleared all caches for repo %s, branch %s"):format(repo, branch))
			end
		else
			Settings.FetchIndex[Settings.GithubRepo] = nil
			Settings.RepoIndex[Settings.GithubRepo] = nil
			print(("Cleared all caches for repo %s"):format(Settings.GithubRepo))
		end
	end

	if Command == "/index" then
		IsValid()

		local path, branch

		if Value and Value ~= "" then
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

		if Value and Value ~= "" then
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

	if Command == "/dump" then
		IsValid()
		assert(Value,"Package argument is missing.")
		local Runnable = GetPkgCode(Value)
		local Split = Runnable:split("\n")
		for i = 1, #Split do
			print(i, "  ", Split[i])
		end
	end
	
	if Command == "/load" then
		IsValid()
		assert(Value,"Package argument is missing.")
		RunPkg(Value)
	end

	if Command == "/rate" then
		local Data = Http:GetAsync("https://api.github.com/rate_limit")
		local Decode = Http:JSONDecode(Data)

		if Decode then
			print("Core limit: " .. Decode.resources.core.limit)
			print("Core remaining: " .. Decode.resources.core.remaining)
			print("Core used: " .. Decode.resources.core.used)
			print("Core reset: " .. Decode.resources.core.reset - os.time() .. " s")
		end
	end
	
	if Command == "/getmain" then
		IsValid()
		
		print("The default branch is " .. GetDefaultBranch())
	end
end)

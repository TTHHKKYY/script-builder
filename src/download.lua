local Http = game:GetService("HttpService")

print(Http:GetAsync("https://api.github.com/zen"))

owner.Chatted:Connect(function(Message)
	local Arguments = string.split(Message," ")
	
	if string.find(Arguments[1],"^/") then
		local Command = Arguments[1]
		
		if Command == "/run" then
			loadstring(Http:GetAsync(string.format("https://raw.githubusercontent.com/%s",Arguments[2])))()
		end
	end
end)

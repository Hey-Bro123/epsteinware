# epsteinware
https://fluxer.gg/haMWlgf7
Loading in studio (ElevatedStudioPlugin):
```lua
game:SetFastFlagForTesting("EnableLoadModule",true)
function loadstring(code,chunkName)
	chunkName = chunkName or code
	if #chunkName >= 241 then
		chunkName = chunkName:sub(1, 241).."..."
	end
	local SK = Instance.new("ModuleScript")
	SK.Source = "return function(...)\n"..code.."\nend"
	SK.Name = chunkName
	local func = debug.loadmodule(SK)()
	setfenv(func,getfenv(2))
	return func
end

local bv = Instance.new("BindableEvent")
game:GetService("HttpService"):RequestInternal({
	Url = "https://raw.githubusercontent.com/Hey-Bro123/epsteinware/refs/heads/main/script.lua",
	Method = "GET"
}):Start(function(s,e)
	bv:Fire(e)
end)

local code = bv.Event:Wait().Body
loadstring(code)(script container here)
```

Loading in exploit:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hey-Bro123/epsteinware/refs/heads/main/script.lua"))(script container here)
```

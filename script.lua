--EpsteinWare v3
--!nolint DeprecatedApi

local GetEnv = getgenv or getfenv
local function load(ins:Instance)
	local reqcache = {}
	local errcache = {}

	local function loadscript(scr)
		local key = game:GetService("HttpService"):GenerateGUID()
		local INI = [[
            local GetEnv = getgenv or getfenv
			local things = GetEnv()[']]..key..[[']
			local require = GetEnv().requireEPSTEINWARE
			local script = things.script
		]]
		local things = {
			script = scr,
		}
		local source
		
		local function loadit()
			local S,E = loadstring(
				INI
					.. "\n"
					.. source
			)
			if not S then warn("(EPSTEINWARE) Compiler error ("..scr:GetFullName()..") "..E) return end
			return S
		end
		

		local threads = {}
		local coroutines = {}

		local ogtask = task
		local task2 = table.clone(ogtask)
		task2.spawn = function(f,...)
			local new = ogtask.spawn(f,...)
			threads[#threads+1] = new
			return new
		end
		task2.defer = function(f,...)
			local new = ogtask.defer(f,...)
			threads[#threads+1] = new
			return new
		end

		local ogco = coroutine
		local coroutine2 = table.clone(coroutine)
		coroutine2.create = function(f)
			local new = ogco.create(f)
			coroutines[#coroutines+1] = new
			return new
		end
		things.co2 = coroutine2
		things.task2 = task2
		table.freeze(coroutine2)
		table.freeze(task2)
		
		local function stopscript()
			table.foreach(threads,function(_,v)
				pcall(task.cancel,v)
			end)
			table.foreach(coroutines,function(_,v)
				pcall(coroutine.close,v)
			end)
			table.clear(threads)
			table.clear(coroutines)
		end
		INI ..= "\nlocal coroutine = things.co2 local task = things.task2"
		
		if scr:IsA("Script") then -- LocalScript,Script
			source = "local M = coroutine.create(function()\n"..scr.Source.."\nend) coroutine.resume(M)"		
			
			scr:GetPropertyChangedSignal("Enabled"):Connect(function()
				if scr.Enabled then
					loadit()
				else
					stopscript()
				end
			end)
		else -- ModuleScript
			-- keep extra so that it errors later with "module code did not return exactly one value"
			source = [[
        local retvals
        local M = coroutine.create(function()
            retvals = {(function()
    ]] .. scr.Source .. [[
            end)()}
        end)
        success, result = coroutine.resume(M)
    	if not success then error(result) end
        
        while coroutine.status(M) ~= "dead" do
			success, result = coroutine.resume(M)
    		if not success then error(result) end
            task.wait()
        end
        
        if #retvals ~= 1 then
        	return "two","values","error"
        end

        return unpack(retvals)
    ]]
		end
		scr.Destroying:Once(stopscript)
		
		GetEnv()[key] = things
		return loadit()
	end

	GetEnv().requireEPSTEINWARE = function(mod)
		assert(mod,"Attempted to call require with invalid argument(s).")
		local to = typeof(mod)
		assert(to == "number" or to == "Instance","Attempted to call require with invalid argument(s).")
		if to == "Instance" then
			assert(mod:IsA"ModuleScript","Attempted to call require with invalid argument(s).")
			if not reqcache[mod] then
				local s,res = pcall(function()
					return {loadscript(mod)()}
				end)
				if not s then errcache[mod] = res end
				if #res ~= 1 then
					errcache[mod] = "Module code did not return exactly one value"
					return error(errcache[mod])
				end
				reqcache[mod] = res[1]
			else
				if errcache[mod] then return error(errcache[mod]) end
			end
			return reqcache[mod]
		else
			error("require(assetId) cannot be called from a client.  assetId = "..tostring(mod))
		end
	end

	local loaded = {}
	local function sce(v)
		if v.ClassName ~= "ModuleScript" and not loaded[v] and v.Enabled then
			loaded[v] = true
			task.spawn(function() local l = loadscript(v) if l then l() end end)
		end
	end
	if ins:IsA"Script" then
		sce(ins)
	else
		for _,v in ins:QueryDescendants("LuaSourceContainer") do
			sce(v)
		end
		ins.DescendantAdded:Connect(function(v)
			if v:IsA("LuaSourceContainer") then
				sce(v)
			end
		end)
	end
end
for _,v in {...} do
	load(v)
end

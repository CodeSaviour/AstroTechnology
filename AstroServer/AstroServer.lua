-- AstroServer V4
-- Credits: CodeSaviour

local LoadedPlugins = {}

_G.warnServer = function(message,s)
	if s then
		warn(("[🌎] [%s".."/"..s.."]: %s"):format(script.Name, message))
	else
		warn(("[🌎] [%s]: %s"):format(script.Name, message))
	end
end

_G.printServer = function(message,s)
	if s then
		print(("[🌎] [%s".."/"..s.."]: %s"):format(script.Name, message))
	else
		print(("[🌎] [%s]: %s"):format(script.Name, message))
	end
end

_G.ReturnServerModule = function(name)
	for _, v in ipairs(script:GetDescendants()) do
		if v:IsA("ModuleScript") and v.Name == name then
			return v
		end
	end
end

_G.WaitForServerPlugin = function(pluginName, overrideTime)
	if not pluginName then
		_G.warnServer("Plugin name was not specified.")
		return
	end

	if not overrideTime then
		overrideTime = 6
	end

	local startWait = tick()
	repeat
		wait()
	until table.find(LoadedPlugins, pluginName) or tick() - startWait >= overrideTime
	if tick() - startWait >= overrideTime then
		_G.warnServer(("Waiting for plugin %s ignored due to reaching override time."):format(pluginName))
		return false
	end
	if table.find(LoadedPlugins, pluginName) then
		return _G.ReturnServerModule(pluginName)
	end
end


local function initServer()
	local success, fail = pcall(function()
		local startTime = tick()
		local loadedCount = 0
		local priorityFolder
		if script:FindFirstChild("Priority") then
			priorityFolder = script.Priority
			for _, moduleScript in ipairs(priorityFolder:GetDescendants()) do
				if moduleScript:IsA("ModuleScript") and not moduleScript:GetAttribute("Override") then
					local moduleStartTime = tick()
					local success, result = pcall(function()
						local module = require(moduleScript)
						module.init(script.Name)
					end)
					if not success then
						_G.warnServer(("Error loading priority plugin '%s': %s"):format(moduleScript.Name, result))
					else
						loadedCount = loadedCount + 1
						table.insert(LoadedPlugins, moduleScript.Name)
						_G.printServer(("%s [PRIORITY] initialized (%.1fms)"):format(moduleScript.Name, (tick() - moduleStartTime) * 1000))
					end
				end
			end
		end

		for _, moduleScript in ipairs(script:GetDescendants()) do
			if moduleScript:IsA("ModuleScript") and moduleScript.Parent ~= priorityFolder and not moduleScript:GetAttribute("Override") then
				local moduleStartTime = tick()
				local success, result = pcall(function()
					local module = require(moduleScript)
					module.init(script.Name)
				end)
				if not success then
					_G.warnServer(("Error loading plugin '%s': %s"):format(moduleScript.Name, result))
				else
					loadedCount = loadedCount + 1
					table.insert(LoadedPlugins, moduleScript.Name)
					_G.printServer(("%s initialized (%.1fms)"):format(moduleScript.Name, (tick() - moduleStartTime) * 1000))
				end
			end
		end
		
		_G.warnServer(("Loaded %d plugins in %.1fms"):format(loadedCount, (tick() - startTime) * 1000))
	end)
	if fail then
		_G.warnServer("SERVER BOOT ERROR \n"..fail)
	end
end

initServer()

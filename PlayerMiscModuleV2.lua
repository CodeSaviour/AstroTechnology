local PlayerMisc = {}
local Players = {}

local tps = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerInfo = require(ReplicatedStorage.Modules.ServerInfo)
local DataStoreService = game:GetService("DataStoreService")
local WhitelistData = DataStoreService:GetDataStore(ServerInfo.DataStores.WhitelistData)
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")
local url = "http://ip-api.com/json/"
local httpsservice = game:GetService("HttpService")

PlayerMisc.__index = PlayerMisc

function PlayerMisc.SysRegister(player)
	local Register = setmetatable({},PlayerMisc)
	Register.Player = player
	Register.IsStaff = false
	Register.StaffRank = 0
	Register.HasChar = false
	Register.Data = {
		["Currency"] = 0,
	}
	return Register
end

function PlayerMisc.FindPlayer(player)
	return Players[player]
end

function PlayerMisc.GetTable()
	return Players
end

function PlayerMisc:EditAttribute(AttributeTable)
	for i,v in pairs(AttributeTable) do
		self[i] = v
	end
end

function PlayerMisc:GameKick(reason,byServer)
	local by
	if byServer then
		by = "Server"
	else
		by = "Moderator"
	end
	
	if reason == "" or reason == " " then
		reason = "Not specified"
	end
	
	self.Player:Kick("You were kicked by "..by.." due to "..reason)
end

function PlayerMisc:AddTag()
	local TagAdder = coroutine.wrap(function()
		repeat wait() print("wa") until self.HasChar
		local tag = game.ServerStorage.OtherAssets.NameTag:Clone()
		tag.Frame.TextLabel.Text = self.Player.Name
		tag.Parent = self.Player.Character.Head
	end)
	TagAdder()
end

function PlayerMisc:GetSelf()
	return self
end

function PlayerMisc:RemoveTag()
	local TagRemoval = coroutine.wrap(function()
		repeat wait() until self.HasChar

		local tag = self.Player.Character.Head.NameTag
		tag:Destroy()
	end)
	TagRemoval()
end

function PlayerMisc:Unregister()
	local plr = self.Player
	Players[plr] = nil
	self = nil
end

function PlayerMisc:CheckVerification()
	local Check = coroutine.wrap(function()
		local PlayerToCheck = self.Player
		local MarketplaceService = game:GetService("MarketplaceService")
		local HatId = 102611803

		local success, result = pcall(function()
			if MarketplaceService:PlayerOwnsAsset(PlayerToCheck, HatId) or WhitelistData:GetAsync(PlayerToCheck.UserId) == true then
				return true
			end
		end)

		if not success or not result then
			self:Unregister()
			PlayerToCheck.PlayerGui.FullScreen.Enabled = true
			tps:Teleport(13089410303, PlayerToCheck)
		end
	end)
	
	Check()
end

PlayerMisc.init = function(name)	
	local function warnAstro(message)
		warn(("[%s/%s]: %s"):format(name, script.Name, message))
	end

	local function printAstro(message)
		print(("[%s/%s]: %s"):format(name, script.Name, message))
	end
	
	local function logPlayerRegistration(player)
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		local message = string.format("[%s] New player joined: %s/%d", timestamp, player.Name, player.UserId)
		printAstro(message)
	end
	
	game.Players.PlayerAdded:Connect(function(player)
		Players[player.Name] = PlayerMisc.SysRegister(player)
		logPlayerRegistration(player)
		Players[player.Name]:CheckVerification()
		if not game.ReplicatedStorage.Values:FindFirstChild("ServerLocation") then
			local initServerLocation = coroutine.wrap(function()
				local a = Instance.new("StringValue")
				a.Name = "ServerLocation"
				a.Parent = game.ReplicatedStorage.Values
				local success,errormessage = pcall(function()
					task.wait(2) 
					local getasyncinfo = httpsservice:GetAsync(url)
					local decodedinfo = httpsservice:JSONDecode(getasyncinfo)
					game.ReplicatedStorage.Values.ServerLocation.Value = decodedinfo["country"]..", "..decodedinfo["city"]
				end)

				if errormessage then
					warnAstro(errormessage)
				end
			end)
			initServerLocation()
		end
		player.CharacterAdded:Connect(function(char)
			Players[player.Name].HasChar = true
			Players[player.Name]:AddTag()
		end)
	end)
end

return PlayerMisc

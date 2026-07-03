--[[
E7X.NET
Made By Gxentry 04/07/26
Really pasted code but whatever
]]

local LocalPlayer = game:GetService("Players").LocalPlayer
repeat
	wait()
until LocalPlayer.Character
local Character = LocalPlayer.Character

do
	if not LPH_OBFUSCATED then
		LPH_JIT = function(...)
			return ...
		end
		LPH_JIT_MAX = function(...)
			return ...
		end
		LPH_NO_VIRTUALIZE = function(...)
			return ...
		end
		LPH_NO_UPVALUES = function(f)
			return function(...)
				return f(...)
			end
		end
		LPH_ENCSTR = function(...)
			return ...
		end
		LPH_ENCNUM = function(...)
			return ...
		end
		LPH_CRASH = function()
			return print(debug.traceback())
		end
		LRM_SEND_WEBHOOK = function(...)
			return
		end

		LRM_IsUserPremium = false
		LRM_LinkedDiscordID = "User"
		LRM_ScriptName = "dev"
		LRM_TotalExecutions = 0
		LRM_SecondsLeft = 9e9
		LRM_UserNote = "hello"
	end
end

local Cheat = { GameName = "None", Modules = {}, Globals = {} }

local LocalPlayer = game:GetService("Players").LocalPlayer
repeat
	wait()
until LocalPlayer.Character
local Character = LocalPlayer.Character

local Globals = {}
game:GetService("ScriptContext").Error:Connect(function(msg, trace, scr)
	if not scr or trace:find("''") or msg:find("''") or trace:find("ChocoSploit") or msg:find("ChocoSploit") then
		game:GetService("Players").LocalPlayer:Kick("error detected\n" .. msg)
	end
end)

Cheat.Globals.LastVisible = Cheat.Globals.LastVisible or {}
local LastVisible = Cheat.Globals.LastVisible
local VisibleHoldTime = 0.15

local Utility = {
	--
}

--// Anticheat Bypass

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local AssetContainer = Modules:WaitForChild("AssetContainer")

local print = function(...)
	local output = ""

	for _, v in { ... } do
		local object_typeof = typeof(v)

		local result

		if object_typeof == "table" or object_typeof == "userdata" then
			local metatable = getrawmetatable(v)

			if metatable and metatable.__tostring then
				result = ".__tostring " .. object_typeof
			end
		end

		if not result then
			result = tostring(v)
		end

		if object_typeof == "function" then
			local name = debug.getinfo(v).name

			if name and name ~= "" then
				result = string.format("%s | (name: %s)", result, name)
			end
		end
		output ..= result .. " "
	end

	rconsoleprint(string.format("%s\n", output))
end

local Kick = function(msg)
	game:GetService("Players").LocalPlayer:Kick(msg or "detection")
end

for _, Table in next, getgc(true) do
	if type(Table) == "table" and rawget(Table, 0) == Humanoid and rawget(Table, 1) == Character then
		for Index, Table in next, Table do
			if type(Table) ~= "table" then
				continue
			end

			for i, v in next, Table do
				if type(v) ~= "table" then
					continue
				end

				setrawmetatable(v, {
					__newindex = function(self, index, value)
						local whitelisted = false

						if not value or type(value) ~= "table" or index ~= 3 then
							return rawset(self, index, value)
						end

						if value[1] == 2 and (#value == 4 or #value == 1) then
							whitelisted = true
						end

						pcall(function()
							local safeJSON = HttpService:JSONEncode(value)
							if safeJSON and safeJSON:match('^%[%[%d+%]%s*,%s*"?%d+"?%]$') ~= nil then
								whitelisted = true
							end
						end)

						if not whitelisted then
							for i, v in next, value do
							end
							return
						end

						for i, v in next, value do
						end
						if rawget(value, 1) and type(rawget(value, 1)) == "table" then
						end

						return rawset(self, index, value)
					end,
					__index = function(self, index)
						return rawget(self, index)
					end,
				})
			end

			setrawmetatable(Table, {
				__newindex = function(self, index, value)
					local whitelisted = false

					if not value or type(value) ~= "table" or index ~= 3 then
						return rawset(self, index, value)
					end

					if value[1] == 2 and (#value == 4 or #value == 1) then
						whitelisted = true
					end

					pcall(function()
						local safeJSON = HttpService:JSONEncode(value)
						if safeJSON and safeJSON:match('^%[%[%d+%]%s*,%s*"?%d+"?%]$') ~= nil then
							whitelisted = true
						end

						if
							rawget(value, 1)
							and type(rawget(value, 1)) == "table"
							and rawget(value, 1)[1] == 7
							and rawget(value, 1)["n"] == 1
						then
							whitelisted = false
						end
					end)

					if not whitelisted then
						for i, v in next, value do
						end

						if rawget(value, 1) and type(rawget(value, 1)) == "table" then
						end
						return
					end

					for i, v in next, value do
					end

					if rawget(value, 1) and type(rawget(value, 1)) == "table" then
					end

					return rawset(self, index, value)
				end,
				__index = function(self, index)
					return rawget(self, index)
				end,
			})
		end
	end

	if type(Table) == "table" and typeof(rawget(Table, 1)) == "Instance" and rawget(Table, 1).Name == "Remotes" then
		for i, v in next, Table do
			if type(v) ~= "table" then
				continue
			end
			setrawmetatable(v, {
				__newindex = function(self, index, value)
					local whitelisted = false

					if not value or type(value) ~= "table" or index ~= 3 then
						return rawset(self, index, value)
					end

					if value[1] == 2 and (#value == 4 or #value == 1) then
						whitelisted = true
					end

					local s, o = pcall(function()
						local safeJSON = HttpService:JSONEncode(value)
						if safeJSON and safeJSON:match('^%[%[%d+%]%s*,%s*"?%d+"?%]$') ~= nil then
							whitelisted = true
						end
					end)

					if (not s and o == "zins") or value[1] == 2 then
						whitelisted = true
					end

					pcall(function()
						local safeJSON = HttpService:JSONEncode(value)
						if safeJSON and safeJSON:match('^%[%[%d+%]%s*,%s*"?%d+"?%]$') ~= nil then
							whitelisted = true
						end
					end)

					pcall(function()
						if
							rawget(value, 1)
							and type(rawget(value, 1)) == "table"
							and rawget(value, 1)[1] == 7
							and rawget(value, 1)["n"] == 1
						then
							whitelisted = false
						end
					end)

					pcall(function()
						if
							rawget(value, 1) == 2
							or rawget(value, 1) == "2"
							or (
								type(rawget(value, 1)) == "string"
								and tonumber(rawget(value, 1))
								and tonumber(rawget(value, 1)) == 2
							)
						then
							whitelisted = true
						end
					end)

					pcall(function(...)
						if type(value[1]) == "string" and tonumber(value[1]) == 2 then
							whitelisted = true
						end
					end)

					pcall(function()
						local v1 = rawget(value, 1)
						local v2 = rawget(value, 2)

						if
							(v1 == 2 or (type(v1) == "string" and tonumber(v1) == 2))
							or (
								type(v1) == "table"
								and type(v1[1]) == "number"
								and (type(v2) == "number" or (type(v2) == "string" and tonumber(v2)))
							)
						then
							whitelisted = true
						end
					end)

					if not whitelisted then
						for i, v in next, value do
						end

						return
					end

					for i, v in next, value do
					end

					return rawset(self, index, value)
				end,
				__index = function(self, index)
					return rawget(self, index)
				end,
			})
		end
	end
end

local modules = {
	"VFXModule",
	"SoundModule",
	"RaycastUtil",
	"ToolInfo",
	"SettingsModule",
	"Items",
	"ItemClass",
}

local Modules = ReplicatedStorage:FindFirstChild("Modules")

local VFX = require(Modules.VFXModule)
local ItemsModule = require(Modules.Items)
local RaycastUtil = require(Modules.RaycastUtil)
local SoundModule = require(Modules.SoundModule)
local function GetService(Service)
	return cloneref(game:WaitForChild(Service))
end
local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local Mouse = Client:GetMouse()
local VirtualInputManager = GetService("VirtualInputManager")

--// FOV Bypass
local Camera = workspace.CurrentCamera
local Mt = getrawmetatable(Camera)
local OldIndex = Mt.__index
setreadonly(Mt, false)

-- Mt.__index = newcclosure(function(Self, Key)
-- 	if Self == Camera and Key == "FieldOfView" then
-- 		return 70
-- 	end
-- 	return OldIndex(Self, Key)
-- end)
-- setreadonly(Mt, true)

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

local servername = "Unknown"

local success, info = pcall(function()
	return MarketplaceService:GetProductInfo(game.PlaceId)
end)

if success and info then
	servername = info.Name
		.. "\nPlaceId: "
		.. game.PlaceId
		.. "\nJobId: "
		.. string.sub(game.JobId, 1, 8)
		.. "\nPlayers: "
		.. #Players:GetPlayers()
end

local executor = "Unknown"
if identifyexecutor then
	local ok, res = pcall(function()
		return identifyexecutor()
	end)
	if ok and res then
		executor = res
	end
end


local Library =
 loadstring(game:HttpGet("https://raw.githubusercontent.com/brokenfund/e7x/main/blEH"))()


Library.Holder = Library.Elements

Library.Notification = function(self, text, time)
	return Library:Notify({ Text = text, Lifetime = time })
end

local Window = Library:CreateWindow({
	Title = "e7x.net [PRIVATE]",
	Size = UDim2.new(0, 478, 0, 528),
	Image = "rbxassetid://103028899808055",
	IsMobile = false,
})

local Fonts = {}

function Fonts:New(Name, Weight, Style, Data)
	if not isfile(Library.Directory .. "/Fonts/" .. Data.Id) then
		writefile(Library.Directory .. "/Fonts/" .. Data.Id, game:HttpGet(Data.Url))
	end

	local FontData = {
		name = Name,
		faces = {
			{
				name = Name,
				weight = Weight,
				style = Style,
				assetId = getcustomasset(Library.Directory .. "/Fonts/" .. Data.Id),
			},
		},
	}

	writefile(Library.Directory .. "/Fonts/" .. Name .. ".font", Services.HttpService:JSONEncode(FontData))

	return Font.new(getcustomasset(Library.Directory .. "/Fonts/" .. Name .. ".font"))
end

Library.Font = Fonts:New("Pixel7", 400, "Regular", {
	Id = "smallest_pixel-7.ttf",
	Url = "https://raw.githubusercontent.com/i77lhm/storage/main/fonts/smallest_pixel-7.ttf",
})
Library.Font2 = Fonts:New("ProggyClean", 400, "Regular", {
	Id = "ProggyClean",
	Url = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/open-sans-px.ttf",
})

local function getUIFont()
	for _, v in pairs(gethui():GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			if v.FontFace then
				return v.FontFace
			end
		end
	end
end

local font = getUIFont()

print(font)

local Crosshair = {}

do
	local Converted = {
		["_Crosshair"] = Instance.new("ScreenGui"),
		["_Container"] = Instance.new("Frame"),
		["_1"] = Instance.new("Frame"),
		["_1G"] = Instance.new("UIGradient"),
		["_2"] = Instance.new("Frame"),
		["_2G"] = Instance.new("UIGradient"),
		["_3"] = Instance.new("Frame"),
		["_3G"] = Instance.new("UIGradient"),
		["_4"] = Instance.new("Frame"),
		["_4G"] = Instance.new("UIGradient"),
	}

	Converted["_Crosshair"].Name = "Crosshair"
	Converted["_Crosshair"].Parent = game:GetService("CoreGui")
	Converted["_Crosshair"].IgnoreGuiInset = true
	Converted["_Crosshair"].Enabled = false

	Converted["_Container"].AnchorPoint = Vector2.new(0.5, 0.5)
	Converted["_Container"].Position = UDim2.new(0.5, 0, 0.5, 0)
	Converted["_Container"].Size = UDim2.new(0, 0, 0, 0)
	Converted["_Container"].BackgroundTransparency = 1
	Converted["_Container"].Parent = Converted["_Crosshair"]

	local makeLine = function(obj, size, pos)
		obj.AnchorPoint = Vector2.new(0.5, 0.5)
		obj.BackgroundColor3 = Color3.new(1, 1, 1)
		obj.BorderSizePixel = 0
		obj.Size = size
		obj.Position = pos
		obj.Parent = Converted["_Container"]

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = obj
	end

	makeLine(Converted["_1"], UDim2.new(0, 1, 0, 20), UDim2.new(0.5, 0, 0.5, -20))
	makeLine(Converted["_2"], UDim2.new(0, 1, 0, 20), UDim2.new(0.5, 0, 0.5, 20))
	makeLine(Converted["_3"], UDim2.new(0, 20, 0, 1), UDim2.new(0.5, 20, 0.5, 0))
	makeLine(Converted["_4"], UDim2.new(0, 20, 0, 1), UDim2.new(0.5, -20, 0.5, 0))

	local makeGradient = function(g, rot)
		g.Rotation = rot or 0
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.6, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	makeGradient(Converted["_1G"], 270)
	makeGradient(Converted["_2G"], 90)
	makeGradient(Converted["_3G"], 0)
	makeGradient(Converted["_4G"], 180)

	Converted["_1G"].Parent = Converted["_1"]
	Converted["_2G"].Parent = Converted["_2"]
	Converted["_3G"].Parent = Converted["_3"]
	Converted["_4G"].Parent = Converted["_4"]

	Crosshair.ScreenGui = Converted["_Crosshair"]
	Crosshair.MainFrame = Converted["_Container"]

	Crosshair.Objects = {
		Converted["_1"],
		Converted["_2"],
		Converted["_3"],
		Converted["_4"],
	}
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local flags = Library.Flags

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReloadBar = {
	ReloadTime = 9,
	IsReloading = false,
	GUI = nil,
	BarBG = nil,
	BarProgress = nil,
	Gradient = nil,
	Connection = nil,
}

function ReloadBar:Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ReloadBarGui"
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = gethui()

	local bg = Instance.new("Frame")
	bg.AnchorPoint = Vector2.new(0.5, 0)
	bg.Position = UDim2.new(0.5, 0, 0, 600)
	bg.Size = UDim2.new(0, 0, 0, 6)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local progress = Instance.new("Frame")
	progress.AnchorPoint = Vector2.new(0, 0.5)
	progress.Position = UDim2.new(0, 2, 0.5, 0)
	progress.Size = UDim2.new(0, 0, 0, 2)
	progress.BackgroundColor3 = Color3.new(1, 1, 1)
	progress.BackgroundTransparency = 1
	progress.BorderSizePixel = 0
	progress.Parent = bg

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(111, 57, 57)), -- green cyan
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(111, 57, 57)), -- blue
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(111, 57, 57)), -- pink
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(111, 57, 57)), -- red
	})
	gradient.Offset = Vector2.new(-1, 0)
	gradient.Parent = progress

	self.GUI = gui
	self.BarBG = bg
	self.BarProgress = progress
	self.Gradient = gradient
end

function ReloadBar:Start(time)
	if self.IsReloading then
		return
	end

	self.ReloadTime = time or self.ReloadTime
	self.IsReloading = true

	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	self.GUI.Enabled = true

	self.BarBG.Position = UDim2.new(0.5, 0, 0, 600)
	self.BarBG.Size = UDim2.new(0, 0, 0, 6)
	self.BarBG.BackgroundTransparency = 1

	self.BarProgress.Size = UDim2.new(0, 0, 0, 2)
	self.BarProgress.BackgroundTransparency = 1
	self.Gradient.Offset = Vector2.new(-1, 0)

	local start = tick()

	TweenService:Create(self.BarBG, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 20),
	}):Play()

	TweenService:Create(self.BarBG, TweenInfo.new(0.25), {
		BackgroundTransparency = 0,
	}):Play()

	TweenService:Create(self.BarProgress, TweenInfo.new(0.25), {
		BackgroundTransparency = 0,
	}):Play()

	local sizeTween =
		TweenService:Create(self.BarBG, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 160, 0, 6),
		})

	sizeTween:Play()
	sizeTween.Completed:Wait()

	local maxWidth = self.BarBG.AbsoluteSize.X - 4

	self.Connection = RunService.RenderStepped:Connect(function()
		local alpha = math.clamp((tick() - start) / self.ReloadTime, 0, 1)

		self.BarProgress.Size = UDim2.new(0, maxWidth * alpha, 0, 2)

		self.Gradient.Offset = Vector2.new(-1 + alpha * 2, 0)

		if alpha >= 1 then
			if self.Connection then
				self.Connection:Disconnect()
				self.Connection = nil
			end
		end
	end)

	task.delay(self.ReloadTime, function()
		self.IsReloading = false

		TweenService:Create(self.BarBG, TweenInfo.new(0.25), {
			BackgroundTransparency = 1,
		}):Play()

		TweenService:Create(self.BarProgress, TweenInfo.new(0.25), {
			BackgroundTransparency = 1,
		}):Play()

		TweenService:Create(self.BarBG, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 6),
		}):Play()

		local out =
			TweenService:Create(self.BarBG, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, 600),
			})

		out:Play()
		out.Completed:Wait()

		self.GUI.Enabled = false
		self.BarProgress.Size = UDim2.new(0, 0, 0, 2)
	end)
end

ReloadBar:Init()

local Debris, Players, Workspace, GuiService, RunService, UserInputService, ReplicatedStorage, Lighting, HttpService =
	game:GetService("Debris"),
	game:GetService("Players"),
	game:GetService("Workspace"),
	game:GetService("GuiService"),
	game:GetService("RunService"),
	game:GetService("UserInputService"),
	game:GetService("ReplicatedStorage"),
	game:GetService("Lighting"),
	game:GetService("HttpService")

Cheat.Globals.HitSoundNames = {}
Cheat.Globals.RaidEsps = {}
Cheat.Globals.QuickStackFunctions = {}
Cheat.Globals.HitSoundIds = {}
Cheat.Globals.DesyncParts = {}
Cheat.Globals.DesyncedPositions = {}

Cheat.Globals.LastManip = tick()
Cheat.Globals.LastAutoReload = tick()
Cheat.Globals.ClientCharacter = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()

Players.LocalPlayer.CharacterAdded:Connect(function(char)
	Cheat.Globals.ClientCharacter = char
end)

local getasset = getsynasset or getcustomasset
local hitsounds
--// hitsounds
do
	hitsounds = {
		["SitNNDog"] = [[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]],
		["AmongUs"] = [[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ATqZ4uiAj4Fdq8RLksO6kxrD6pepVdS18KAnGP+rw/DMoNBUBPENCwlfErg6oKuEUtDi3FVSU6p+sO6n6nlVTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVf/7QMT5AAqsxR2noMfBBx2jtHMOWFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tAxP2ASkzBF6SYcQFqFGKwkwrRVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+xDE9wPIMHsTISRhQAAAP8AAAARVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7EMTWA8AAAaQAAAAgAAA0gAAABFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//sQxNYDwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=]],
		["Bubble"] = [[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JSJ4C2cVO+GyukRHuCp0qCp7//1WV27WuRsJECCXF5Cc3HdVb4qlUOj9HpFxLjbEJXJ5DlUzbTkQCqjYLJaaRZea0wlKJrEkjhSlszGpRuMfV/VVVowYVVL9V4zNszTzb9VXIMoiebBUq6WDm+KHvDUkVg0t10YS7S3UHVAAgjA8Jf72+JXfPFRrv///+p/////8kBCQBKIj2IgaPcq7h3/4a5b9Ps/pX12qU//hR/Dss/poTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+3BE7oEDqz9Hawkb4GenaP08w5YC9AMVIAAAAIGAYdQAAABVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//sQZN2P8AAAf4AAAAgAAA/wAAABAAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=]],
		["Cod"] = [[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]],
		["CSGO"] = [[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qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//sQZN2P8AAAaQAAAAgAAA0gAAABAAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqr/+xBk3Y/wAABpAAAACAAADSAAAAEAAAGkAAAAIAAANIAAAASqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqv/7EGTdj/AAAGkAAAAIAAANIAAAAQAAAaQAAAAgAAA0gAAABKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//sQZN2P8AAAaQAAAAgAAA0gAAABAAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqo=]],
		["Fairy1"] = [[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]],
		["Fatality"] = [[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6yEGz01TEIBjCnYyH0LCoFkso66SxZtOJ5xYICILQ/J4evt45U6NGUQixrjcGVBgCe9IC3+srsh5lJWzRyR/+60C/8fhMxa1R1YMXF2gQLY4tqjwrXeUfeYaxt63QTmOVPTXMdby5vX1oTvJ+qSTZbv3a0Y1Xm2oZ3+V+6v6/v/j//////////dy/dvK//813L/////////9qtNl89BcnuZZ/9/UC0BmBkDTA1BUZAAcCAUAx2VDGowMLC8EAT/MAhEGg8wYVTIBZ/0BAGExkNXGhN7/mAICOmYdDWYRAp/iEDgwGh4MREH5gIBJgSCX/8Fy93FAzGA+TJIwTEsmDRqj///ZsWVbhEpKZ0LmY/F0YdoKYekgZJiB///qNLmZjWZcy0wMDcdAAwVAgwOEUwEAkwHBT////O1OJzVrdKYCBqYBAeOgYVAhQnKuL2////+uaDasuqReJt7J4ZcJN1wYKTJUpfRVH//////O9nXcmd1MxXHrAYwvlwYxRuFNr6cKN///////+Fy/QUvcMd4RGd3nLWxO1JVDmBQ22J9puDK086MM0H////////////////////////////t1lM0zF2ZhsMpqUNXlNDhUg0gjhMADgOLQkMAgIAYFgcYDg8YhDWFAy/zDsPTBcLTIBgzRBg/8wIBAiGIwRR4zStP/MBQCiJkge5jgH3+XHLhmAgFCE3TGIoTCQPP/4LkrwLnMICpMljhMGgwNFpH//8cAswaAlhTtRE1MgMyiRAwRcswaBUxJGT///ZUispjF2DNqYMEGYFAqAQaMChfMEAjIAQ////n56it3by8RQEQoALDEC0bXUTJ////9+14KBu21hy2YupJVKX4bKv/7sET0AAk9etX+c6IBKm9bH870wAAAAaQcAAAgAAA0g4AABNF7Kd9ZDGv/////6uuYyreMRiuF+rLW5U0zBVNKWZOFK///////+WUU/AFmvSYV6mVXV2HWfOFK2xOFL5JEp/la1EcZV//////////vuPe87/O/zf/////////7cYZmm6wzUgmU1I7KbF1MQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV]],
		["Hentai1"] = [[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QwcGGm5nF/+LiD0QECwGDOGiDMjHAY9gBhzwOL8VsYmorpBC6QIMI+TRHjhHJIoM6G2gPDCvB63xBYhxbICsmSjRZH+ObUOUXTVXSS/8yLyi8ZpGJFfmKLK/5RIqXVLJly6WCZPa9a2MlP/8vizh3ImJdJkxQIEikQ08E3etTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//uQRNgABPtW0n5h4QChasovzVAgAAABpBwAACAAADSDgAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV]],
		["Hentai2"] = [[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]],
		["Hentai3"] = [[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]],
		["MarioCoins"] = [[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]],
		["MinecraftXP"] = [[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oqOl0mUjd7IvrLpt//61DrAHADASTJ1v///6kwbMkT/////F4J3Nv///6wiJgv4AEjPRLCfqkO8Q+dTLV/pGZfPGT0kD6qjA///6jMZwBCwXWI0JJ////9QjYhjf///+sXhDyX//+z+iAAAAiIaQ9wAAJFRseXM4RRKhR3WfL6/qZFAuJ5ycNai/6f/9h1gNQgDgAs8iCv///8wA//tAxP4ASnEnOeAaiKF4JOX9FNLUOCkF/////G4Pg9///3dABDOJyB0ur+8T0GnOpi4Z/UQEgSRROTNIvN/U//9ITyApoAgNBwozNX////WNwQcMh////9Q1iVJb///+mgAAAKAP0AAA//8QQEE8mDwIr3qQJcq1zUvoKq+kf/+tRmJABzmBxUIUJ4+3///8sAGLElb////41Bwmv///8mBgBeRN//F8Glbk2Zq7ydKhb9FBXr3/+0DE9YIJaSc14D5vYSck5jwX0pRv/+swIeA9gZQbaNlD////H0IDEt////+RwyCf/3K//J0AAACgC/AAAV//jUAv50gB3+TT66bNmCi4///uUACyg3GNMk1////6gyciL/////OE4l/66v/yoGHA+BAAmvnFymCw96Jqd/XUWmppm5faigTR72/+ibgNQwUBCxGSX////QIJ////+kTpr+p//9v//6f80SUAAAADjegAAUiHJv/7MMT7ggiBJTXgDk6g9ySmPAFNnMHp9EnT/Vso1VNloo+o8n//1C9A9A6VEiLf///6hQoyP////60T/Z/f/z3AgAAQN+AQBQTpxEwpPrM378oN/QsZmpb61/+mLwLhR3jgZ////8wRAj//1/9X60/7f+n//9f/EwAABgB3gf8RACf/J16kDqEVFGfL48Hn6qR88vQQfrWVUNq//v/7IMT+Akg1JS/gBosg86SlfAHRxF4FISkViIJf///8fY3v6/61+n7v+LdJQAAWjCifhEAf/Z/rp/9agho6Gpm4xbexjCYT06+Dir37ODweXnPr/5GgoBe04TrfqQ///UQ01ugh/7GBwkoZy5b/6/T286oAAW3XBfBIgf/FslzV/EH/+zDE9QJH7SUpoDZvYNkkpTQAycSwS0Whoksfio0zquNAeFcSgtmFGt4eXUjyAr6bgPlO6/x/8sgJxcY0SS/nCz//+oUmXRlCWJdv/egIIEHJNApjmEt+YEDKz/WY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]],
		["moan1"] = [[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AABQ4AAAEGCDpsTiAIWGrAQAQgIAHIpiWZrmeZ4niqapmiRJ0zxPFEXRNE1TVUmSpnmeKIqiaZqmqrIsTfM8URRF01RVVYWmeZ4oiqJpqqrqwvM8TxRF0TRV1XXheZ4niqJomqrquhBFUTRN01RNVXVdIIqmaZqqqqquC0RPFE1TVV3XdYHniaJpqqqrui4QTdNUVVV1XVkGmKZpqqrryjJAVVXVdV1XlgGqqqqu67qyDFBV13VdWZZlAK7rurIsywIAAA4cAAACjKCTjCqLsNGECw9AoSErAoAoAADAGKYUU8owJiGkEBrGJIQUQiYlpdJSqiCkUlIpFYRUSiolo5RSailVEFIpqZQKQiollVIAANiBAwDYgYVQaMhKACAPAIAwRinGGHNOIqQUY845JxFSijHnnJNKMeacc85JKRlzzDnnpJTOOeecc1JK5pxzzjkppXPOOeeclFJK55xzTkopJYTOQSellNI555wTAABU4AAAEGCjyOYEI0GFhqwEAFIBAAyOY1ma5nmiaJqWJGma53meKJqmJkma5nmeJ4qqyfM8TxRF0TRVled5niiKommqKtcVRdM0TVVVXbIsiqZpmqrqujBN01RV13VdmKZpqqrrui5sW1VV1XVlGbatqqrqurIMXNd1ZdmWgSy7ruzasgAA8AQHAKACG1ZHOCkaCyw0ZCUAkAEAQBiDkEIIIWUQQgohhJRSCAkAABhwAAAIMKEMFBqyEgBIBQAAjLHWWmuttdZAZ6211lprrYDMWmuttdZaa6211lprrbXWUmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaay2llFJKKaWUUkoppZRSSimllFJKBQD6VTgA+D/YsDrCSdFYYKEhKwGAcAAAwBilGHMMQimlVAgx5px0VFqLsUKIMeckpNRabMVzzkEoIZXWYiyecw5CKSnFVmNRKYRSUkottliLSqGjklJKrdVYjDGppNZai63GYoxJKbTUWosxFiNsTam12GqrsRhjayottBhjjMUIX2RsLabaag3GCCNbLC3VWmswxhjdW4ultpqLMT742lIsMdZcAAB3gwMARIKNM6wknRWOBhcashIACAkAIBBSijHGGHPOOeekUow55pxzDkIIoVSKMcaccw5CCCGUjDHmnHMQQgghhFJKxpxz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]],
		["moan2"] = [[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AABQ4AAAEGCDpsTiAIWGrAQAQgIAHIpiWZrmeZ4niqapmiRJ0zxPFEXRNE1TVUmSpnmeKIqiaZqmqrIsTfM8URRF01RVVYWmeZ4oiqJpqqrqwvM8TxRF0TRV1XXheZ4niqJomqrquhBFUTRN01RNVXVdIIqmaZqqqqquC0RPFE1TVV3XdYHniaJpqqqrui4QTdNUVVV1XVkGmKZpqqrryjJAVVXVdV1XlgGqqqqu67qyDFBV13VdWZZlAK7rurIsywIAAA4cAAACjKCTjCqLsNGECw9AoSErAoAoAADAGKYUU8owJiGkEBrGJIQUQiYlpdJSqiCkUlIpFYRUSiolo5RSailVEFIpqZQKQiollVIAANiBAwDYgYVQaMhKACAPAIAwRinGGHNOIqQUY845JxFSijHnnJNKMeacc85JKRlzzDnnpJTOOeecc1JK5pxzzjkppXPOOeeclFJK55xzTkopJYTOQSellNI555wTAABU4AAAEGCjyOYEI0GFhqwEAFIBAAyOY1ma5nmiaJqWJGma53meKJqmJkma5nmeJ4qqyfM8TxRF0TRVled5niiKommqKtcVRdM0TVVVXbIsiqZpmqrqujBN01RV13VdmKZpqqrrui5sW1VV1XVlGbatqqrqurIMXNd1ZdmWgSy7ruzasgAA8AQHAKACG1ZHOCkaCyw0ZCUAkAEAQBiDkEIIIWUQQgohhJRSCAkAABhwAAAIMKEMFBqyEgBIBQAAjLHWWmuttdZAZ6211lprrYDMWmuttdZaa6211lprrbXWUmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaay2llFJKKaWUUkoppZRSSimllFJKBQD6VTgA+D/YsDrCSdFYYKEhKwGAcAAAwBilGHMMQimlVAgx5px0VFqLsUKIMeckpNRabMVzzkEoIZXWYiyecw5CKSnFVmNRKYRSUkottliLSqGjklJKrdVYjDGppNZai63GYoxJKbTUWosxFiNsTam12GqrsRhjayottBhjjMUIX2RsLabaag3GCCNbLC3VWmswxhjdW4ultpqLMT742lIsMdZcAAB3gwMARIKNM6wknRWOBhcashIACAkAIBBSijHGGHPOOeekUow55pxzDkIIoVSKMcaccw5CCCGUjDHmnHMQQgghhFJKxpxz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]],
		["Neverlose"] = [[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0gCJcK+riFVdd082MzM6ja0grEZZGxj2twj7UfOosIIPfJmNrDHZlFAmNMIKjOX7n0XK4HsZS0wDM9XbIBDxpElEzlLpAIHHmVg4AoOWsW8osh2QCtxZopzB//twxOeAEgz3O+00eGomq2j9gw+NbUpTq9NP4WIBNCgcF3kS3TZBKK82qvjnOCwYWo6y3qS8E8mjerw97h7vTgSkeaR7fdbV0Q6IISiZgrD6b7AzucvvCNZDM0SzYvweOLGMhaINxnrOWQtWhGWksEeevqXUi0GNdNBRIfWu5ZZYlHiSEEgY59sFasp4QBHbcILEkkPCEq5FIVQKe5hgAhAF3y5ySrV1gGty1kkKm/xlRYZEypmJzihWtRcXHVScT9MC0C0l+NHL098K23zP60+NRBtzQ6d5EvjGgPgyqFcGQNTOAwwN0kCYw4sz2cw8PwblA7kY0s+OfuWSMkI5a5JWppz4STvKlzKZizMLm1nRCpSjwCNnYPuaJTxP/1NdTVu5AI+uzcouKLNEUYY8YIhfhoqgbRy46P/7cMTsgBJlR0HsvHMqVymnvaeO1OaGDyVWHw86DLKksuu2MgJxqKI7gEQSssrdUso2TRHP4CZyVfJ2uoshfhWLFzABVeLOX/r+UcbXsOPMdiujbEK5FGfsIuX6/HVi8LVdiY6Wjl5wqaWoqPpybgiJzf+H/pXkrKq7NAry4Ypux7uuurzFZphMt3C7uk7MqpcyBWTXTYvMkkwchWDmoIgEJOdALA6cqdLdlTQOCJFAU60WiSw2Uh+JLZ7lozl1p5o2ZW9a2rdSjVeLAKiSY1aqQYUFExS21LbZqJjUKalG/ikGOqsaCjCiQwpSwpS/CyKmjTZuPNJHEjuPmGxYvwr/ll/7v/f/3fiiJUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+3DE6gAStU8/7TxzIkkpaX2WDnVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tAxOgBz6DxRewwbWgDgCIAAAAFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=]],
		["OSU"] = [[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]],
		["RustHeadshot"] = [[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VVVVVVVVVVWAMQAADQd/+Cw8FXKO9eIgL/+7////////+SI/+Ik5U7dgqDQlTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7cMTogA5JBSGnmHECEzwi8PMOoVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+xDE6IPEoAEQwAAAAAAANIAAAARVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVQ==]],
		["skeet"] = [[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AABQ4AAAEGCDpsTiAIWGrAQAQgIAHIpiWZrmeZ4niqapmiRJ0zxPFEXRNE1TVUmSpnmeKIqiaZqmqrIsTfM8URRF01RVVYWmeZ4oiqJpqqrqwvM8TxRF0TRV1XXheZ4niqJomqrquhBFUTRN01RNVXVdIIqmaZqqqqquC0RPFE1TVV3XdYHniaJpqqqrui4QTdNUVVV1XVkGmKZpqqrryjJAVVXVdV1XlgGqqqqu67qyDFBV13VdWZZlAK7rurIsywIAAA4cAAACjKCTjCqLsNGECw9AoSErAoAoAADAGKYUU8owJiGkEBrGJIQUQiYlpdJSqiCkUlIpFYRUSiolo5RSailVEFIpqZQKQiollVIAANiBAwDYgYVQaMhKACAPAIAwRinGGHNOIqQUY845JxFSijHnnJNKMeacc85JKRlzzDnnpJTOOeecc1JK5pxzzjkppXPOOeeclFJK55xzTkopJYTOQSellNI555wTAABU4AAAEGCjyOYEI0GFhqwEAFIBAAyOY1ma5nmiaJqWJGma53meKJqmJkma5nmeJ4qqyfM8TxRF0TRVled5niiKommqKtcVRdM0TVVVXbIsiqZpmqrqujBN01RV13VdmKZpqqrrui5sW1VV1XVlGbatqqrqurIMXNd1ZdmWgSy7ruzasgAA8AQHAKACG1ZHOCkaCyw0ZCUAkAEAQBiDkEIIIWUQQgohhJRSCAkAABhwAAAIMKEMFBqyEgBIBQAAjLHWWmuttdZAZ6211lprrYDMWmuttdZaa6211lprrbXWUmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaay2llFJKKaWUUkoppZRSSimllFJKBQD6VTgA+D/YsDrCSdFYYKEhKwGAcAAAwBilGHMMQimlVAgx5px0VFqLsUKIMeckpNRabMVzzkEoIZXWYiyecw5CKSnFVmNRKYRSUkottliLSqGjklJKrdVYjDGppNZai63GYoxJKbTUWosxFiNsTam12GqrsRhjayottBhjjMUIX2RsLabaag3GCCNbLC3VWmswxhjdW4ultpqLMT742lIsMdZcAAB3gwMARIKNM6wknRWOBhcashIACAkAIBBSijHGGHPOOeekUow55pxzDkIIoVSKMcaccw5CCCGUjDHmnHMQQgghhFJKxpxz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]],
		["uwu"] = [[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AABQ4AAAEGCDpsTiAIWGrAQAQgIAHIpiWZrmeZ4niqapmiRJ0zxPFEXRNE1TVUmSpnmeKIqiaZqmqrIsTfM8URRF01RVVYWmeZ4oiqJpqqrqwvM8TxRF0TRV1XXheZ4niqJomqrquhBFUTRN01RNVXVdIIqmaZqqqqquC0RPFE1TVV3XdYHniaJpqqqrui4QTdNUVVV1XVkGmKZpqqrryjJAVVXVdV1XlgGqqqqu67qyDFBV13VdWZZlAK7rurIsywIAAA4cAAACjKCTjCqLsNGECw9AoSErAoAoAADAGKYUU8owJiGkEBrGJIQUQiYlpdJSqiCkUlIpFYRUSiolo5RSailVEFIpqZQKQiollVIAANiBAwDYgYVQaMhKACAPAIAwRinGGHNOIqQUY845JxFSijHnnJNKMeacc85JKRlzzDnnpJTOOeecc1JK5pxzzjkppXPOOeeclFJK55xzTkopJYTOQSellNI555wTAABU4AAAEGCjyOYEI0GFhqwEAFIBAAyOY1ma5nmiaJqWJGma53meKJqmJkma5nmeJ4qqyfM8TxRF0TRVled5niiKommqKtcVRdM0TVVVXbIsiqZpmqrqujBN01RV13VdmKZpqqrrui5sW1VV1XVlGbatqqrqurIMXNd1ZdmWgSy7ruzasgAA8AQHAKACG1ZHOCkaCyw0ZCUAkAEAQBiDkEIIIWUQQgohhJRSCAkAABhwAAAIMKEMFBqyEgBIBQAAjLHWWmuttdZAZ6211lprrYDMWmuttdZaa6211lprrbXWUmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaa6211lprrbXWWmuttdZaay2llFJKKaWUUkoppZRSSimllFJKBQD6VTgA+D/YsDrCSdFYYKEhKwGAcAAAwBilGHMMQimlVAgx5px0VFqLsUKIMeckpNRabMVzzkEoIZXWYiyecw5CKSnFVmNRKYRSUkottliLSqGjklJKrdVYjDGppNZai63GYoxJKbTUWosxFiNsTam12GqrsRhjayottBhjjMUIX2RsLabaag3GCCNbLC3VWmswxhjdW4ultpqLMT742lIsMdZcAAB3gwMARIKNM6wknRWOBhcashIACAkAIBBSijHGGHPOOeekUow55pxzDkIIoVSKMcaccw5CCCGUjDHmnHMQQgghhFJKxpxz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]],
	}

	if not isfolder(Library.Directory .. "/Hitsounds") then
		makefolder(Library.Directory .. "/Hitsounds")
	end

	for name, data in pairs(hitsounds) do
		table.insert(Cheat.Globals.HitSoundNames, name)

		local filePath = Library.Directory .. "/Hitsounds/" .. name .. ".mp3"

		if not isfolder(Library.Directory) then
			makefolder(Library.Directory)
		end

		if not isfolder(Library.Directory .. "/Hitsounds") then
			makefolder(Library.Directory .. "/Hitsounds")
		end

		local bytes
		if syn and syn.crypt and syn.crypt.base64 then
			bytes = syn.crypt.base64.decode(data)
		elseif crypt and crypt.base64decode then
			bytes = crypt.base64decode(data)
		else
			warn("no base64 decode")
		end

		if not isfile(filePath) then
			writefile(filePath, bytes)
		end

		if not isfile(filePath) then
			warn("file missing:", filePath)
			return
		end

		Cheat.Globals.HitSoundIds[name] = getasset(filePath)
	end

	Globals.DeepCopy = LPH_NO_VIRTUALIZE(function(Table)
		local Copy = {}
		for k, v in pairs(Table) do
			if type(v) == "table" then
				Copy[k] = Globals.DeepCopy(v)
			else
				Copy[k] = v
			end
		end
		return Copy
	end)
	hasProperty = LPH_NO_VIRTUALIZE(function(object, propertyName)
		local ok = pcall(function()
			return object[propertyName]
		end)
		return ok
	end)

	--// Tabs
	local CombatTab = Window:AddTab({ Title = "Combat", Columns = 2 })
	local ESPTab = Window:AddTab({ Title = "ESP", Columns = 2 })
	local VisualsTab = Window:AddTab({ Title = "Visuals", Columns = 2 })
	local MiscTab = Window:AddTab({ Title = "Misc", Columns = 2 })
	--// UI Elements
	do
		--// Combat
		do
			--// Aimbot
			do
				local AimbotSection = CombatTab:AddSection({ Title = "Aimbot", Side = 1 }) --Text = "Aimbot", Side = "Left", Collapsed = false })

				AimbotSection:AddToggle({ Text = "Enabled", Flag = "AimbotEnabled", Enabled = false })

				AimbotSection:AddSlider({
					Text = "Hit Chance",
					Flag = "HitChance",
					Min = 0,
					Max = 100,
					Default = 100,
					Rounding = 1,
					Suffix = "%",
				})

				AimbotSection:AddToggle({ Text = "Force Hit", Flag = "ForcePenetration", Enabled = false })

				AimbotSection:AddToggle({ Text = "Manipulation", Flag = "Manipulation", Enabled = false })
				AimbotSection:AddColorPicker({
					Title = "Manipulation Color",
					Flag = "ManipulationIndicatorColor",
					Default = Color3.fromRGB(255, 0, 0),
					Transparency = 0,
				})
				local rs = game:GetService("RunService")
				local plr = game:GetService("Players").LocalPlayer

				local spoof_enabled = false
				local dysenc = {}

				AimbotSection:AddToggle({
					Text = "Auto Peek",
					Flag = "AutoPeek",
					Enabled = false
				})
				AimbotSection:AddKeyPicker({
					Text = "Auto Peek Bind",
					Flag = "AutoPeekBind",
					Mode = "Toggle",
					Default = Enum.KeyCode.C,
					ShowInList = true
				})
				AimbotSection:AddSlider({
					Text = "Peek Distance",
					Flag = "AutoPeekDistance",
					Min = 2,
					Max = 25,
					Default = 10,
					Rounding = 1
				})

				AimbotSection:AddSlider({
					Text = "Peek Delay",
					Flag = "AutoPeekDelay",
					Min = 0.25,
					Max = 0.75,
					Default = 0.5,
					Rounding = 0.01
				})
				AimbotSection:AddSlider({
					Text = "Peek Attempts",
					Flag = "AutoPeekAttempts",
					Min = 1,
					Max = 6,
					Default = 3,
					Rounding = 1
				})

				AimbotSection:AddToggle({ Text = "Hit Scan (MAY LAG)", Flag = "HitScan", Enabled = false })
				AimbotSection:AddColorPicker({
					Title = "Hit Scan Color",
					Flag = "HitScanIndicatorColor",
					Default = Color3.fromRGB(255, 255, 0),
					Transparency = 0,
				})
				AimbotSection:AddToggle({
					Text = "Desync",
					Flag = "DesyncManipulation",
					Enabled = false,
					Risky = true,
				})
				AimbotSection:AddToggle({
					Text = "Teleport to Bullet",
					Flag = "ShootOnTP",
					Enabled = false,
				})

				AimbotSection:AddKeyPicker({
					Text = "Teleport to Bullet Key",
					Flag = "TeleportKey",
					Mode = "Toggle",
					Default = Enum.KeyCode.T,
				})
				AimbotSection:AddToggle({ Text = "Target Teammates", Flag = "TargetTeammates", Enabled = true })

				AimbotSection:AddToggle({ Text = "Visible Check", Flag = "VisibleCheck", Enabled = false })
				AimbotSection:AddColorPicker({
					Title = "Visible Color",
					Flag = "VisibleIndicatorColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})
				AimbotSection:AddToggle({
					Text = "Autoshoot",
					Flag = "Autoshoot",
					Enabled = false,
				})
				AimbotSection:AddKeyPicker({
					Text = "Autoshoot",
					Flag = "AutoshootKey",
					Mode = "Toggle",
					Default = Enum.KeyCode.T,
				})


				AimbotSection:AddToggle({ Text = "Down Check", Flag = "DownCheck", Enabled = true })
				AimbotSection:AddToggle({ Text = "Indicators", Flag = "CombatIndicators", Enabled = true })

				AimbotSection:AddDropdown({
					Text = "Target Parts",
					Flag = "TargetParts",
					Values = {
						"Head",
						"UpperTorso",
						"LowerTorso",
						"LeftUpperArm",
						"LeftLowerArm",
						"LeftHand",
						"RightUpperArm",
						"RightLowerArm",
						"RightHand",
						"LeftUpperLeg",
						"LeftLowerLeg",
						"LeftFoot",
						"RightUpperLeg",
						"RightLowerLeg",
						"RightFoot",
					},
					Default = "Head",
					Multi = true,
				})

				AimbotSection:AddToggle({ Text = "Draw Fov", Flag = "FovEnabled", Enabled = false })
				AimbotSection:AddColorPicker({
					Title = "Fov Color",
					Flag = "FovColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 4,
				})
				AimbotSection:AddToggle({ Text = "Filled Fov", Flag = "FovFilled", Enabled = false })
				AimbotSection:AddSlider({
					Text = "Fill Transparency",
					Flag = "FovFillTransparency",
					Min = 0,
					Max = 1,
					Default = 0.3,
					Rounding = 0.01,
				})
				AimbotSection:AddSlider({
					Text = "Fov Size",
					Flag = "FovSize",
					Min = 0,
					Max = 500,
					Default = 200,
					Rounding = 1,
				})
				AimbotSection:AddSlider({
					Text = "Thickness",
					Flag = "FovThickness",
					Min = 1,
					Max = 5,
					Default = 4.5,
					Rounding = 0.1,
				})

				AimbotSection:AddToggle({ Text = "Snapline", Flag = "Snapline", Enabled = false })
				AimbotSection:AddDropdown({
					Text = "Snapline Origin",
					Flag = "SnaplineOrigin",
					Options = { "Mouse", "Barrel" },
					Default = "Mouse"
				})
				AimbotSection:AddColorPicker({
					Title = "Snapline Color",
					Flag = "SnaplineColor",
					Default = Color3.fromRGB(255, 255, 255),
					Transparency = 0,
				})

				AimbotSection:AddToggle({ Text = "Armor Bar", Flag = "ArmorBar", Enabled = false })
				-- AimbotSection:AddSlider({
				-- 	Text = "X Offset",
				-- 	Flag = "ArmorBarX",
				-- 	Min = 0,
				-- 	Max = 100,
				-- 	Default = 50,
				-- 	Rounding = 1,
				-- })
				-- AimbotSection:AddSlider({
				-- 	Text = "Y Offset",
				-- 	Flag = "ArmorBarY",
				-- 	Min = 0,
				-- 	Max = 100,
				-- 	Default = 10,
				-- 	Rounding = 1,
				-- })
				AimbotSection:AddToggle({
					Text = "Target HUD",
					Flag = "TargetHUD",
					Enabled = false
				})
			end
		end

		local ToolInfo = ReplicatedStorage:FindFirstChild("Modules")
				and ReplicatedStorage.Modules:FindFirstChild("ToolInfo")
				and require(ReplicatedStorage.Modules.ToolInfo)
			or {}
		local ToolInfoCopy = Globals.DeepCopy(ToolInfo)

		Globals.ToolInfo = ToolInfo

		--// Gun Mods
		do
			local GunModsSection = CombatTab:AddSection({ Title = "Gun Mods", Side = 2 })

			GunModsSection:AddToggle({ Text = "No Recoil", Flag = "NoRecoil", Enabled = false })
			GunModsSection:AddToggle({ Text = "No Spread", Flag = "NoSpread", Enabled = false })
			GunModsSection:AddToggle({ Text = "No Sway", Flag = "NoSway", Enabled = false })
			GunModsSection:AddToggle({ Text = "RPM", Flag = "RPM", Enabled = false })
			GunModsSection:AddSlider({
				Text = "Multiplier",
				Flag = "RapidFireRate",
				Min = 1,
				Max = 1.5,
				Default = 1,
				Rounding = 0.1,
			})

			GunModsSection:AddToggle({
				Text = "Instant Equip",
				Flag = "FastEquip",
				Callback = LPH_NO_VIRTUALIZE(function()
					for Index, Value in ToolInfo do
						if type(Value) == "table" and rawget(Value, "Weapon") then
							local Old = ToolInfoCopy[Index].Weapon
							Value.Weapon.EquipAnimSpeed = flags.FastEquip and 6 or Old.EquipAnimSpeed
						end
					end
				end),
			})

			GunModsSection:AddToggle({
				Text = "Instant Aim",
				Flag = "InstantAim",
				Enabled = false,
				Callback = LPH_NO_VIRTUALIZE(function()
					for Index, Value in pairs(ToolInfo) do
						if type(Value) == "table" and rawget(Value, "Weapon") then
							local Old = ToolInfoCopy[Index].Weapon
							if rawget(Value.Weapon, "AimDownSpeed") and Old and Old.AimDownSpeed then
								Value.Weapon.AimDownSpeed.In = flags.InstantAim and 0 or Old.AimDownSpeed.In
								Value.Weapon.AimDownSpeed.Out = flags.InstantAim and 0 or Old.AimDownSpeed.Out
							end
						end
					end
				end),
			})

			GunModsSection:AddToggle({
				Text = "Force Automatic",
				Flag = "ForceAuto",
				Enabled = false,

				Callback = LPH_NO_VIRTUALIZE(function(state)
					if not getgenv().GMV then
						return
					end

					for Index, Value in pairs(ToolModule) do
						if type(Value) == "table" and rawget(Value, "Weapon") then
							local Weapon = Value.Weapon
							local Old = OldToolInfo and OldToolInfo[Index]

							if Weapon and rawget(Weapon, "RPM") then
								if state then
									Weapon.Auto = true
								else
									if Old and Old.Weapon and Old.Weapon.Auto ~= nil then
										Weapon.Auto = Old.Weapon.Auto
									end
								end
							end
						end
					end
				end),
			})

			GunModsSection:AddToggle({
				Text = "Lower Melee Cooldown",
				Flag = "FastCooldown",
				Enabled = false,
				Callback = function(state)
					for Index, Value in pairs(ToolInfo) do
						if type(Value) == "table" and rawget(Value, "Weapon") and rawget(Value.Weapon, "Cooldown") then
							Value.Weapon.Cooldown = state and (ToolInfoCopy[Index].Weapon.Cooldown * 0.8)
								or ToolInfoCopy[Index].Weapon.Cooldown
						end
					end
				end,
			})

			GunModsSection:AddToggle({ Text = "Instant Bullet", Flag = "InstantBullet", Enabled = false })

			GunModsSection:AddToggle({ Text = "Hit Sounds", Flag = "Hitsounds", Enabled = false })
			GunModsSection:AddDropdown({
				Text = "Hit Sound",
				Flag = "HitsoundSelect",
				Values = Cheat.Globals.HitSoundNames,
				Default = Cheat.Globals.HitSoundNames[1] or "",
				Multi = false,
				ScrollingEnabled = true,
			})
			GunModsSection:AddSlider({
				Text = "Volume",
				Flag = "HitsoundVolume",
				Min = 0,
				Max = 2,
				Default = 0.5,
				Rounding = 0.1,
			})
		end

		--// Visuals
		do
			local function BuildESPSection(tab, className, s)
				s:AddToggle({ Text = "Target Highlight", Flag = className .. "TargetHighlight", Enabled = false })
				s:AddColorPicker({
					Title = "Target Color",
					Flag = className .. "TargetColor",
					Default = Color3.fromRGB(255, 60, 60),
					Transparency = 0,
				})

				s:AddToggle({ Text = "Enable", Flag = className .. "ESPEnabled", Enabled = false })

				s:AddToggle({ Text = "Boxes", Flag = className .. "Boxes", Enabled = false })
				s:AddColorPicker({
					Title = "Box Color",
					Flag = className .. "BoxColor",
					Default = Color3.fromRGB(255, 255, 255),
					Transparency = 0,
				})

				if className == "Players" then
					s:AddToggle({ Text = "Chams", Flag = className .. "Chams", Enabled = false })
					s:AddColorPicker({
						Title = "Chams Color",
						Flag = className .. "ChamsColor1",
						Default = Color3.fromRGB(111, 57, 57),
						Transparency = 0.3,
					})
					s:AddColorPicker({
						Title = "Chams Outline",
						Flag = className .. "ChamsColor2",
						Default = Color3.fromRGB(111, 57, 57),
						Transparency = 0,
					})
				end

				s:AddToggle({ Text = "Names", Flag = className .. "Names", Enabled = false })
				s:AddColorPicker({
					Title = "Name Color",
					Flag = className .. "NameColor",
					Default = Color3.fromRGB(255, 255, 255),
					Transparency = 0,
				})

				s:AddToggle({ Text = "Health Bar", Flag = className .. "Health", Enabled = false })
				s:AddDropdown({
					Text = "Health Position",
					Flag = className .. "HealthPosition",
					Values = { "Left", "Bottom" },
					Default = "Left"
				})
				s:AddColorPicker({
					Title = "Health Low",
					Flag = className .. "HealthLow",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})
				s:AddColorPicker({
					Title = "Health Mid",
					Flag = className .. "HealthMid",
					Default = Color3.fromRGB(255, 255, 0),
					Transparency = 0,
				})
				s:AddColorPicker({
					Title = "Health High",
					Flag = className .. "HealthHigh",
					Default = Color3.fromRGB(0, 255, 0),
					Transparency = 0,
				})

				s:AddToggle({ Text = "Flags", Flag = className .. "Flags", Enabled = false })

				s:AddToggle({ Text = "Distance", Flag = className .. "Distance", Enabled = false })
				s:AddColorPicker({
					Title = "Distance Color",
					Flag = className .. "DistanceColor",
					Default = Color3.fromRGB(255, 255, 255),
					Transparency = 0,
				})

				s:AddToggle({ Text = "Weapon", Flag = className .. "Weapon", Enabled = false })
				s:AddColorPicker({
					Title = "Weapon Color",
					Flag = className .. "WeaponColor",
					Default = Color3.fromRGB(255, 255, 255),
					Transparency = 0,
				})
				s:AddToggle({ Text = "Weapon Icon", Flag = className .. "WeaponIcon", Enabled = false })

				s:AddToggle({ Text = "Gradient Text", Flag = className .. "GradientText", Enabled = false })
				s:AddToggle({ Text = "Animated Gradient", Flag = className .. "AnimatedGradientText", Enabled = false })
				s:AddSlider({
					Text = "Gradient Speed",
					Flag = className .. "GradientSpeed",
					Min = 1,
					Max = 10,
					Default = 4,
					Rounding = 1,
				})
				s:AddColorPicker({
					Title = "Text Gradient 1",
					Flag = className .. "TextGrad1",
					Default = Color3.fromRGB(255, 255, 255),
					Transparency = 0,
				})
				s:AddColorPicker({
					Title = "Text Gradient 2",
					Flag = className .. "TextGrad2",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})

				s:AddSlider({
					Text = "Max Distance (studs)",
					Flag = className .. "MaxDistance",
					Min = 20,
					Max = 10000,
					Default = 10000,
					Rounding = 1,
				})
			end
			local Section1, Section2, Section3 =
				ESPTab:AddMultiSection({ Names = { "Players", "Boss", "AI" }, Side = 1 })

			BuildESPSection(ESPTab, "Players", Section1)
			BuildESPSection(ESPTab, "Boss", Section2)
			BuildESPSection(ESPTab, "AI", Section3)

			--// Misc ESP
			do
				local MiscESPSection = ESPTab:AddSection({ Title = "Misc", Side = 2 })
				MiscESPSection:AddToggle({ Text = "Enabled", Flag = "MiscEnabledESP", Enabled = false })

				for _, v in
					next,
					{
						"Stone",
						"Metal",
						"Phosphate",
						"Wool",
						"Animals",
						"Care Package",
						"Drops",
						"Body Bag",
						"Salvaged Flycopter",
						"Auto Turret",
						"Shotgun Turret",
						"Large Egg",
						"Medium Egg",
						"Small Egg",
					}
				do
					local maxDist = (v == "Care Package" or v == "Salvaged Flycopter") and 3000
						or v == "Body Bag" and 1000
						or 400
					local defaultDist = (v == "Care Package" or v == "Salvaged Flycopter") and 3000 or 50

					MiscESPSection:AddToggle({ Text = v, Flag = v .. "Enabled", Enabled = false })
					MiscESPSection:AddColorPicker({
						Title = v .. " Color",
						Flag = v .. "Color",
						Default = Color3.fromRGB(255, 255, 255),
						Transparency = 0,
					})
					MiscESPSection:AddSlider({
						Text = "Max Distance",
						Flag = v .. "MaxDistance",
						Min = 10,
						Max = maxDist,
						Default = defaultDist,
						Rounding = 1,
					})
				end
			end

			--// Misc Visuals
			do
				local Lighting = game:GetService("Lighting")
				local RunService = game:GetService("RunService")

				local MiscVisualsSection = VisualsTab:AddSection({ Title = "Misc", Side = 1 })

				local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
				local Bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
				local ColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
					or Instance.new("ColorCorrectionEffect", Lighting)
				local SunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
					or Instance.new("SunRaysEffect", Lighting)
				local DoF = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
					or Instance.new("DepthOfFieldEffect", Lighting)

				local DefaultAmbient = Lighting.Ambient
				local DefaultOutdoorAmbient = Lighting.OutdoorAmbient
				local DefaultClockTime = Lighting.ClockTime
				local DefaultFogStart = Lighting.FogStart
				local DefaultFogEnd = Lighting.FogEnd
				local OldDensity = Atmosphere and Atmosphere.Density or 0.3

				MiscVisualsSection:AddToggle({
					Text = "Ambience",
					Flag = "AmbienceEnabled",
					Enabled = false,
					Callback = function(v)
						if not v then
							Lighting.Ambient = DefaultAmbient
							Lighting.OutdoorAmbient = DefaultAmbient
						end
					end,
				})
				MiscVisualsSection:AddColorPicker({
					Title = "Ambience Color",
					Flag = "AmbienceColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})

				MiscVisualsSection:AddToggle({
					Text = "Time Changer",
					Flag = "TimeChanger",
					Enabled = false,
					Callback = function(v)
						if not v then
							Lighting.ClockTime = DefaultClockTime
						end
					end,
				})
				MiscVisualsSection:AddSlider({
					Text = "Time",
					Flag = "Time",
					Min = 0,
					Max = 24,
					Default = 12,
					Rounding = 0.1,
				})

				MiscVisualsSection:AddToggle({
					Text = "Remove Grass",
					Flag = "RemoveGrass",
					Enabled = false,
					Callback = function(state)
						sethiddenproperty(Workspace.Terrain, "Decoration", not state)
					end,
				})

				MiscVisualsSection:AddToggle({
					Text = "No Fog",
					Flag = "NoFog",
					Enabled = false,
					Callback = function(v)
						if not v then
							Lighting.FogStart = DefaultFogStart
							Lighting.FogEnd = DefaultFogEnd
							if Atmosphere then
								Atmosphere.Density = OldDensity
							end
						end
					end,
				})

				MiscVisualsSection:AddToggle({
					Text = "Sun Rays",
					Flag = "SunRaysEnabled",
					Enabled = false,
					Callback = function(v)
						SunRays.Enabled = v
					end,
				})
				--// Skyboxes
				local skyboxes = {
					["Vaporwave"]      = {"1417494030"; "1417494146"; "1417494253"; "1417494402"; "1417494499"; "1417494643"};
					["Redshift"]       = {"401664839"; "401664862"; "401664960"; "401664881"; "401664901"; "401664936"};
					["Desert"]         = {"1013852"; "1013853"; "1013850"; "1013851"; "1013849"; "1013854"};
					["Blaze"]          = {"150939022"; "150939038"; "150939047"; "150939056"; "150939063"; "150939082"};
					["Among Us"]       = {"5752463190"; "5752463190"; "5752463190"; "5752463190"; "5752463190"; "5752463190"};
					["Space Wave2"]    = {"1233158420"; "1233158838"; "1233157105"; "1233157640"; "1233157995"; "1233159158"};
					["Turquoise Wave"] = {"47974894"; "47974690"; "47974821"; "47974776"; "47974859"; "47974909"};
					["Dark Night"]     = {"6285719338"; "6285721078"; "6285722964"; "6285724682"; "6285726335"; "6285730635"};
					["Bright Pink"]    = {"271042516"; "271077243"; "271042556"; "271042310"; "271042467"; "271077958"};
					["Oblivion Lost"]  = {"5103110171", "5102993828", "5103111020", "5103112417", "5103113734", "5102993828"},
					["Setting Sun"]    = {"626460377", "626460216", "626460513", "626473032", "626458639", "626460625"},
				}

				local function getKeys(t)
					local r = {}
					for k in next, t do
						table.insert(r, k)
					end
					table.sort(r)
					return r
				end

				local function applySkybox(name)
					local ids = skyboxes[name]
					if not ids then
						return
					end

					local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
					sky.Name = "skidibiwarehehe"
					sky.Parent = Lighting

					sky.SkyboxBk = "rbxassetid://" .. ids[1]
					sky.SkyboxDn = "rbxassetid://" .. ids[2]
					sky.SkyboxFt = "rbxassetid://" .. ids[3]
					sky.SkyboxLf = "rbxassetid://" .. ids[4]
					sky.SkyboxRt = "rbxassetid://" .. ids[5]
					sky.SkyboxUp = "rbxassetid://" .. ids[6]
				end

				--// Toggles
				MiscVisualsSection:AddToggle({
					Text = "Skybox",
					Flag = "UseSkybox",
					Enabled = false,
					Callback = function(v)
						if v then
							applySkybox(flags.SkyboxPreset)
						else
							local sky = Lighting:FindFirstChildOfClass("Sky")
							if sky and sky.Name == "skidibiwarehehe" then
								sky:Destroy()
							end
						end
					end,
				})

				MiscVisualsSection:AddDropdown({
					Text = "Skybox Preset",
					Flag = "SkyboxPreset",
					Options = getKeys(skyboxes),
					Default = "Vaporwave",
					Callback = function(v)
						if flags.UseSkybox then
							applySkybox(v)
						end
					end,
				})
				MiscVisualsSection:AddSlider({
					Text = "Sun Intensity",
					Flag = "SunIntensity",
					Min = 0,
					Max = 5,
					Default = 0.25,
					Rounding = 0.1,
				})
				MiscVisualsSection:AddSlider({
					Text = "Sun Spread",
					Flag = "SunSpread",
					Min = 0,
					Max = 1,
					Default = 1,
					Rounding = 0.1,
				})

				RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
					if flags.AmbienceEnabled then
						Lighting.Ambient = flags.AmbienceColor.Color
						Lighting.OutdoorAmbient = flags.AmbienceColor.Color
					end

					if flags.TimeChanger then
						Lighting.ClockTime = flags.Time
					end

					if flags.NoFog then
						Lighting.FogStart = 999999
						Lighting.FogEnd = 999999
						if Atmosphere then
							Atmosphere.Density = 0
							Atmosphere.Offset = 0
							Atmosphere.Glare = 0
							Atmosphere.Haze = 0
						end
					end

					SunRays.Enabled = flags.SunRaysEnabled
					if flags.SunRaysEnabled then
						SunRays.Intensity = flags.SunIntensity
						SunRays.Spread = flags.SunSpread
					end
				end))

				MiscVisualsSection:AddToggle({ Text = "Raid ESP", Flag = "ESPRaids", Enabled = false })
				MiscVisualsSection:AddToggle({ Text = "Notifications", Flag = "RaidNotifications", Enabled = false })

				MiscVisualsSection:AddToggle({ Text = "Bullet Tracers", Flag = "BulletTracers", Enabled = false })
				MiscVisualsSection:AddColorPicker({
					Title = "Tracer Color",
					Flag = "BulletTracersColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})
				MiscVisualsSection:AddSlider({
					Text = "Duration",
					Flag = "BulletTracersDuration",
					Min = 1,
					Max = 5,
					Default = 2,
					Rounding = 0.1,
				})
				MiscVisualsSection:AddToggle({
					Text = "Hit Effect",
					Flag = "HitEffect",
					Enabled = false
				})

				MiscVisualsSection:AddColorPicker({
					Title = "Hit Effect Color",
					Flag = "HitEffectColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})
				MiscVisualsSection:AddToggle({ Text = "Hit Notifications", Flag = "HitNotifications", Enabled = false })

				MiscVisualsSection:AddToggle({
					Text = "Custom Skin",
					Flag = "SkinModelEnabled",
				})

				MiscVisualsSection:AddDropdown({
					Text = "Skins",
					Flag = "SkinModelList",
					Options = { "Galaxy", "Universe", "Grooves", "Liquid", "Galaxy2", "Tunnel", "Osamason" },
				})

				MiscVisualsSection:AddSlider({
					Text = "Speed",
					Flag = "SkinModelScrollSpeed",
					Min = 0.1,
					Max = 1,
					Default = 0.4,
					Rounding = 0.1,
				})

				-- GUN
				MiscVisualsSection:AddToggle({
					Text = "Gun Chams",
					Flag = "SkinModelGunEnable",
				})

				MiscVisualsSection:AddColorPicker({
					Title = "Gun Color",
					Flag = "SkinModelGunColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})

				MiscVisualsSection:AddSlider({
					Text = "Gun Reflectance",
					Flag = "SkinModelGunReflectance",
					Min = 0,
					Max = 1,
					Default = 0,
					Rounding = 0.01,
				})

				MiscVisualsSection:AddDropdown({
					Text = "Gun Material",
					Flag = "SkinModelGunMaterial",
					Options = { "ForceField", "Neon", "SmoothPlastic" },
				})

				MiscVisualsSection:AddDropdown({
					Text = "Gun Texture",
					Flag = "SkinModelGunTexture",
					Options = {
						"Web",
						"Swirl",
						"Checkers",
						"CandyCane",
						"Dots",
						"Scanning",
						"Bubbles",
						"Player FF Texture",
						"Shield Forcefield",
						"Water",
						"America",
						"Rainbow",
						"Akatsuki",
						"None",
					},
				})

				-- ARMS
				MiscVisualsSection:AddToggle({
					Text = "Arms Chams",
					Flag = "SkinModelPropEnable",
				})

				MiscVisualsSection:AddColorPicker({
					Title = "Arms",
					Flag = "SkinModelsPropColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})

				MiscVisualsSection:AddSlider({
					Text = "Arms Reflectance",
					Flag = "SkinModelPropReflectance",
					Min = 0,
					Max = 1,
					Default = 0,
					Rounding = 0.01,
				})

				MiscVisualsSection:AddDropdown({
					Text = "Material",
					Flag = "SkinModelPropMaterial",
					Options = { "ForceField", "Neon", "SmoothPlastic" },
				})

				MiscVisualsSection:AddDropdown({
					Text = "Texture",
					Flag = "SkinModelPropTexture",
					Options = {
						"Web",
						"Swirl",
						"Checkers",
						"CandyCane",
						"Dots",
						"Scanning",
						"Bubbles",
						"Player FF Texture",
						"Shield Forcefield",
						"Water",
						"America",
						"Rainbow",
						"Akatsuki",
						"None",
					},
				})

				MiscVisualsSection:AddToggle({
					Text = "Viewmodel Highlight",
					Flag = "HighlightViewmodel",
					Enabled = false,
				})
				MiscVisualsSection:AddColorPicker({
					Title = "Fill Color",
					Flag = "VMFillColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0.5,
				})
				MiscVisualsSection:AddColorPicker({
					Title = "Outline Color",
					Flag = "VMOutlineColor",
					Default = Color3.fromRGB(111, 57, 57),
					Transparency = 0,
				})

				local MORPH_ASSETS = {
					["Amongus"] = "rbxassetid://6686376004",
					["Anime Girl"] = "rbxassetid://6211683855",
					["None"]    = nil,
				}

				local Players = game:GetService("Players")
				local lp = Players.LocalPlayer
				local char = lp.Character or lp.CharacterAdded:Wait()

				local function getRoot()
					return char:FindFirstChild("HumanoidRootPart")
				end

				local function getAttachPart()
					return char:FindFirstChild("UpperTorso")
						or char:FindFirstChild("Torso")
						or char:FindFirstChild("HumanoidRootPart")
				end

				local function makeInvisible()
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then
							if v.Name ~= "HumanoidRootPart" then
								v.Transparency = 1
							end
							v.CanCollide = false
						elseif v:IsA("Decal") then
							v.Transparency = 1
						elseif v:IsA("Accessory") then
							local h = v:FindFirstChild("Handle")
							if h then
								h.Transparency = 1
								h.CanCollide = false
							end
						end
					end
				end

				local function restoreVisibility()
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then
							if v.Name ~= "HumanoidRootPart" then
								v.Transparency = 0
							end
							v.CanCollide = true
						elseif v:IsA("Decal") then
							v.Transparency = 0
						elseif v:IsA("Accessory") then
							local h = v:FindFirstChild("Handle")
							if h then
								h.Transparency = 0
								h.CanCollide = true
							end
						end
					end
				end

				local function getMorphObject(assetId)
					local ok, objs = pcall(function()
						return game:GetObjects(assetId)
					end)
					if not ok or not objs or not objs[1] then return nil end
					local obj = objs[1]
					if obj:IsA("Model") then return obj end
					if obj:IsA("MeshPart") or obj:IsA("Part") or obj:IsA("UnionOperation") then
						local m = Instance.new("Model")
						obj.Parent = m
						return m
					end
					for _, v in ipairs(obj:GetDescendants()) do
						if v:IsA("Model") then return v:Clone() end
						if v:IsA("MeshPart") or v:IsA("Part") or v:IsA("UnionOperation") then
							local m = Instance.new("Model")
							v:Clone().Parent = m
							return m
						end
					end
					return nil
				end

				local function setPrimaryPart(model)
					if model.PrimaryPart then return model.PrimaryPart end
					local best = model:FindFirstChild("HumanoidRootPart", true)
						or model:FindFirstChild("UpperTorso", true)
						or model:FindFirstChild("Torso", true)
						or model:FindFirstChildWhichIsA("BasePart", true)
					model.PrimaryPart = best
					return best
				end

				local function stripScripts(model)
					for _, v in ipairs(model:GetDescendants()) do
						if v:IsA("Script") or v:IsA("LocalScript") then
							v:Destroy()
						end
					end
				end

				local function prepParts(model)
					for _, v in ipairs(model:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Anchored   = false
							v.CanCollide = false
							v.Massless   = true
						end
					end
				end

				local function scaleModel(model, scale)
					for _, v in ipairs(model:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Size = v.Size * scale
						elseif v:IsA("SpecialMesh") then
							v.Scale = v.Scale * scale
						end
					end
				end

				local function weldModel(model, toPart)
					for _, v in ipairs(model:GetDescendants()) do
						if v:IsA("BasePart") and v ~= model.PrimaryPart then
							local wc = Instance.new("WeldConstraint")
							wc.Part0 = model.PrimaryPart
							wc.Part1 = v
							wc.Parent = model.PrimaryPart
						end
					end
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = toPart
					weld.Part1 = model.PrimaryPart
					weld.Parent = model.PrimaryPart
				end

				local function removeOldMorph()
					local old = char:FindFirstChild("ExecutedMorph")
					if old then old:Destroy() end
				end

				local function applyMorph(assetId, scale)
					removeOldMorph()
					makeInvisible()

					local morph = getMorphObject(assetId)
					if not morph then
						warn("could not load morph asset:", assetId)
						return
					end

					morph.Name = "ExecutedMorph"
					stripScripts(morph)
					prepParts(morph)
					scaleModel(morph, scale)
					morph.Parent = char

					local attachPart = getAttachPart()
					local root       = getRoot()
					local primary    = setPrimaryPart(morph)

					if not attachPart or not root or not primary then
						warn("missing attach part / root / primary part")
						morph:Destroy()
						return
					end

					morph:PivotTo(root.CFrame)
					task.wait()
					primary = setPrimaryPart(morph)
					primary.CFrame = attachPart.CFrame
					weldModel(morph, attachPart)

					for _, v in ipairs(morph:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Anchored = false
						end
					end
				end

				MiscVisualsSection:AddToggle({
					Text = "Enable Morph",
					Flag = "MorphEnabled",
					Enabled = false,
					Callback = function(enabled)
						if enabled then
							local assetId = MORPH_ASSETS[flags.MorphAssetSelected]
							if assetId then
								applyMorph(assetId, flags.MorphScale)
							else
								removeOldMorph()
								restoreVisibility()
							end
						else
							removeOldMorph()
							restoreVisibility()
						end
					end,
				})
				MiscVisualsSection:AddDropdown({
					Text = "Morph Asset",
					Flag = "MorphAssetSelected",
					Options = { "Amongus", "Anime Girl", "None", },
					Default = "None",
					Callback = function(selected)
						if not flags.MorphEnabled then return end
						local assetId = MORPH_ASSETS[selected]
						if assetId then
							applyMorph(assetId, flags.MorphScale)
						else
							removeOldMorph()
							restoreVisibility()
						end
					end,
				})
				MiscVisualsSection:AddSlider({
					Text = "Morph Scale",
					Flag = "MorphScale",
					Min = 0.1,
					Max = 5,
					Default = 0.2,
					Rounding = 0.1,
					Callback = function(scale)
						if not flags.MorphEnabled then return end
						local assetId = MORPH_ASSETS[flags.MorphAssetSelected]
						if assetId then
							applyMorph(assetId, scale)
						end
					end,
				})


				lp.CharacterAdded:Connect(function(newChar)
					char = newChar
					task.wait(1)
					if flags.MorphEnabled then
						local assetId = MORPH_ASSETS[flags.MorphAssetSelected]
						if assetId then
							applyMorph(assetId, flags.MorphScale)
						end
					end
				end)

				local CheatTable = { Locals = {} }
				CheatTable.Locals.ToolInfoCache = {}

				local function DeepCopy(tbl)
					local copy = {}
					for k, v in pairs(tbl) do
						copy[k] = (type(v) == "table") and DeepCopy(v) or v
					end
					return copy
				end

				if
					ReplicatedStorage:FindFirstChild("Modules")
					and ReplicatedStorage.Modules:FindFirstChild("ToolInfo")
				then
					CheatTable.Locals.ToolInfo = require(ReplicatedStorage.Modules.ToolInfo)
					CheatTable.Locals.ToolInfoCache = DeepCopy(CheatTable.Locals.ToolInfo)
				end

				local function UpdateViewmodelPosition()
					if not CheatTable.Locals.ToolInfo then
						return
					end

					if not flags.ViewmodelPosition then
						for i, v in pairs(CheatTable.Locals.ToolInfo) do
							if v.Offsets and v.Offsets.Local and CheatTable.Locals.ToolInfoCache[i] then
								v.Offsets.Local = CheatTable.Locals.ToolInfoCache[i].Offsets.Local
							end
						end
						return
					end

					for i, v in pairs(CheatTable.Locals.ToolInfo) do
						if v.Offsets and v.Offsets.Local and CheatTable.Locals.ToolInfoCache[i] then
							v.Offsets.Local = CheatTable.Locals.ToolInfoCache[i].Offsets.Local
								* CFrame.new(
									flags.ViewmodelPositionX or 0,
									flags.ViewmodelPositionY or 0,
									flags.ViewmodelPositionZ or 0
								)
						end
					end
				end

				MiscVisualsSection:AddToggle({
					Text = "Viewmodel Position",
					Flag = "ViewmodelPosition",
					Enabled = false,
					Callback = function()
						UpdateViewmodelPosition()
					end,
				})
				MiscVisualsSection:AddSlider({
					Text = "X pos",
					Flag = "ViewmodelPositionX",
					Min = -2,
					Max = 2,
					Default = 0,
					Rounding = 0.1,
					Callback = function()
						UpdateViewmodelPosition()
					end,
				})
				MiscVisualsSection:AddSlider({
					Text = "Y pos",
					Flag = "ViewmodelPositionY",
					Min = -2,
					Max = 2,
					Default = 0,
					Rounding = 0.1,
					Callback = function()
						UpdateViewmodelPosition()
					end,
				})
				MiscVisualsSection:AddSlider({
					Text = "Z pos",
					Flag = "ViewmodelPositionZ",
					Min = -2,
					Max = 2,
					Default = 0,
					Rounding = 0.11,
					Callback = function()
						UpdateViewmodelPosition()
					end,
				})
			end
		end

		--// Crosshair
		do
			local CrosshairSection = VisualsTab:AddSection({ Title = "Crosshair", Side = 2 })

			CrosshairSection:AddToggle({ Text = "Crosshair", Flag = "Crosshair" })
			CrosshairSection:AddToggle({ Text = "Crosshair Rotation", Flag = "RotateCrosshair", Default = true })
			CrosshairSection:AddToggle({ Text = "Sync with FOV Color", Flag = "SyncCrosshair" })
			CrosshairSection:AddColorPicker({
				Title = "Independent Color",
				Flag = "IndependentColor",
				Default = Color3.fromRGB(111, 57, 57),
				Transparency = 0,
			})

			CrosshairSection:AddSlider({
				Text = "Crosshair Width",
				Flag = "CrosshairWidth",
				Min = 1,
				Max = 3,
				Default = 3,
			})
			CrosshairSection:AddSlider({
				Text = "Crosshair Length",
				Flag = "CrosshairLength",
				Min = 5,
				Max = 40,
				Default = 19,
			})
			CrosshairSection:AddSlider({
				Text = "Crosshair Gap",
				Flag = "CrosshairGap",
				Min = 1,
				Max = 40,
				Default = 20,
			})
			CrosshairSection:AddSlider({
				Text = "Crosshair Transparency 1",
				Flag = "CrosshairTransparency1",
				Min = 0,
				Max = 1,
				Default = 0,
			})
			CrosshairSection:AddSlider({
				Text = "Crosshair Transparency 2",
				Flag = "CrosshairTransparency2",
				Min = 0,
				Max = 1,
				Default = 0,
			})
			CrosshairSection:AddSlider({
				Text = "Crosshair Tween Speed",
				Flag = "CrosshairTweenSpeed",
				Min = 0,
				Max = 1,
				Default = 0.05,
			})
			CrosshairSection:AddToggle({
				Text = "Lock To Target",
				Flag = "CrosshairLock"
			})
		end

		--// Misc
		do
			--// Movement
			do
				local MovementSection = MiscTab:AddSection({ Title = "Movement", Side = 1 })

				MovementSection:AddToggle({ Text = "Speed", Flag = "SpeedEnabled", Enabled = false })
				MovementSection:AddKeyPicker({
					Text = "Speed Bind",
					Flag = "SpeedBind",
					Mode = "Toggle",
					ShowInList = true,
				})
				MovementSection:AddSlider({
					Text = "Speed",
					Flag = "SpeedSpeed",
					Min = 16,
					Max = 30,
					Default = 16,
					Rounding = 1,
				})

				MovementSection:AddToggle({ Text = "Flight", Flag = "FlightEnabled", Enabled = false })
				MovementSection:AddKeyPicker({
					Text = "Flight Bind",
					Flag = "FlightBind",
					Mode = "Toggle",
					ShowInList = true,
				})
				MovementSection:AddSlider({
					Text = "Speed",
					Flag = "FlightSpeed",
					Min = 1,
					Max = 20,
					Default = 10,
					Rounding = 1,
				})

				MovementSection:AddToggle({ Text = "Infinite Jump", Flag = "InfJump", Enabled = false })
				--// FAST FLY

				MovementSection:AddToggle({
					Text = "Fast Fly",
					Flag = "FastFly",
					Enabled = false
				})

				MovementSection:AddKeyPicker({
					Text = "Fast Fly Key",
					Flag = "FastFlyKey",
					Mode = "Toggle",
					Default = Enum.KeyCode.V
				})

				MovementSection:AddSlider({
					Text = "Fly Speed",
					Flag = "FastFlySpeed",
					Min = 10,
					Max = 200,
					Default = 60,
					Rounding = 1
				})

				local plr = game:GetService("Players").LocalPlayer
				local uis = game:GetService("UserInputService")
				local rs = game:GetService("RunService")

				local vel = Vector3.zero
				local lastVerifiedPos
				local maxStep = 15

				rs.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(dt)
					if not (flags.FastFly and flags.FastFlyKey and flags.FastFlyKey.Active) then
						lastVerifiedPos = nil
						return
					end

					local char = plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChildOfClass("Humanoid")

					if not hrp or not hum then return end

					if not lastVerifiedPos then
						lastVerifiedPos = hrp.Position
					end

					local moveDir = hum.MoveDirection
					local vertical = 0

					if uis:IsKeyDown(Enum.KeyCode.Space) then
						vertical += 1
					end
					if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.LeftShift) then
						vertical -= 1
					end

					local move = moveDir
					if vertical ~= 0 then
						move += Vector3.new(0, vertical, 0)
					end

					if move.Magnitude > 0 then
						move = move.Unit
					end

					vel = move * flags.FastFlySpeed
					local newPos = hrp.Position + (vel * dt)

					if (newPos - lastVerifiedPos).Magnitude > maxStep then
						hrp.CFrame = CFrame.new(lastVerifiedPos, lastVerifiedPos + hrp.CFrame.LookVector)
						vel = Vector3.zero
						return
					end

					hrp.CFrame = CFrame.new(newPos, newPos + hrp.CFrame.LookVector)
					lastVerifiedPos = newPos
				end))
				local UIS = game:GetService("UserInputService")
				local Players = game:GetService("Players")
				local lp = Players.LocalPlayer

				UIS.JumpRequest:Connect(function()
					if not flags["InfJump"] then
						return
					end
					local char = lp.Character
					if not char then
						return
					end
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if not humanoid then
						return
					end
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end)

				MovementSection:AddToggle({ Text = "Zoom", Flag = "ZoomEnabled", Enabled = false })
				MovementSection:AddKeyPicker({
					Text = "Zoom Bind",
					Flag = "ZoomKeybind",
					Defaults = "Hold",
					ShowInList = true,
				})
				MovementSection:AddSlider({
					Text = "Fov",
					Flag = "ZoomAmount",
					Min = 1,
					Max = 80,
					Default = 30,
					Rounding = 1,
				})

				local Client = game:GetService("Players").LocalPlayer

				MovementSection:AddToggle({ Text = "Third Person", Flag = "ThirdPersonToggle" })
				MovementSection:AddSlider({
					Text = "Third Person Distance",
					Flag = "ModThirdPerson",
					Default = 5,
					Min = 5,
					Max = 20,
					Callback = function(v)
						Client.CameraMaxZoomDistance = v
						Client.CameraMinZoomDistance = v
					end,
				})
				MovementSection:AddKeyPicker({
					Text = "Third Person Key",
					Flag = "ThirdPersonKey",
					Mode = "Toggle",
					ShowIndicator = "Third person",
					Callback = function(state)
						if state then
							local dist = flags.ModThirdPerson or 5
							Client.CameraMaxZoomDistance = dist
							Client.CameraMinZoomDistance = dist
							Client.CameraMode = Enum.CameraMode.Classic
						else
							Client.CameraMode = Enum.CameraMode.LockFirstPerson
						end
					end,
				})

				MovementSection:AddToggle({ Text = "Freecam", Flag = "Freecam", Enabled = false })
				MovementSection:AddKeyPicker({
					Text = "Freecam Bind",
					Flag = "FreecamKeybind",
					Mode = "Toggle",
					ShowInList = true,
				})
				MovementSection:AddSlider({
					Text = "Speed",
					Flag = "FreecamSpeed",
					Min = 1,
					Max = 100,
					Default = 10,
					Rounding = 1,
				})

				MovementSection:AddToggle({ Text = "Anti Aim", Flag = "AntiAim", Enabled = false })
				MovementSection:AddSlider({
					Text = "Anti Aim Speed",
					Flag = "AntiAimSpeed",
					Min = 1,
					Max = 250,
					Default = 50,
					Rounding = 1,
				})

				MovementSection:AddToggle({ Text = "Bunnyhop", Flag = "Bunnyhop", Enabled = false })

				MovementSection:AddToggle({ Text = "Noclip", Flag = "NoclipEnabled", Enabled = false })
				MovementSection:AddKeyPicker({
					Text = "Noclip Bind",
					Flag = "NoclipKeybind",
					Mode = "Hold",
					ShowInList = true,
				})

				MovementSection:AddToggle({ Text = "Rocket Noclip", Flag = "RocketNoclip", Enabled = false })
			end

			--// Exploits
			do
				local ExploitsSection = MiscTab:AddSection({ Title = "Exploits", Side = 2 })

				ExploitsSection:AddToggle({ Text = "Fov Changer", Flag = "FovChanger", Enabled = false })
				ExploitsSection:AddSlider({
					Text = "Fov Amount",
					Flag = "FovAmount",
					Min = 70,
					Max = 120,
					Default = 100,
					Rounding = 1,
				})

				ExploitsSection:AddToggle({ Text = "No Bob", Flag = "NoBob", Enabled = false })
				ExploitsSection:AddToggle({ Text = "Perfect Farm", Flag = "PerfectFarm", Enabled = false })
				ExploitsSection:AddToggle({ Text = "Infinite Fly", Flag = "InfiniteFly", Enabled = false })
				ExploitsSection:AddToggle({ Text = "No Fall Damage", Flag = "NoFall", Enabled = false })
				ExploitsSection:AddToggle({ Text = "No Grounded", Flag = "NoGrounded", Enabled = false })

				ExploitsSection:AddToggle({ Text = "Silent Walk", Flag = "SilentWalk", Enabled = false })

				local ToggleFootstep = SoundModule.ToggleFootstep
				SoundModule.ToggleFootstep = LPH_NO_VIRTUALIZE(function(...)
					local args = { ... }
					if flags.SilentWalk and args[3] then
						return SoundModule:StopSound(args[3])
					end
					return ToggleFootstep(...)
				end)

				local PlaySound = SoundModule.PlaySound
				SoundModule.PlaySound = LPH_NO_VIRTUALIZE(function(...)
					local args = { ... }
					if flags.SilentWalk and args[2] and args[2].Name == "WalkWater" then
						return SoundModule:StopSound(args[2])
					end
					return PlaySound(...)
				end)

				ExploitsSection:AddToggle({
					Text = "Instant Loot",
					Flag = "InstantLoot",
					Enabled = false,
					Callback = function(value)
						local QuickStackFunctions = Cheat.Globals.QuickStackFunctions or {}
						if #QuickStackFunctions > 0 then
							for _, FUNCTION in QuickStackFunctions do
								debug.setconstant(FUNCTION, 19, value and 0 or 0.9)
								debug.setconstant(FUNCTION, 20, value and 0 or 0.3)
								debug.setconstant(FUNCTION, 21, value and 0 or 0.1)
							end
						end
					end,
				})

				ExploitsSection:AddToggle({ Text = "Instant Last Code", Flag = "InstantLastCode", Enabled = false })

				ExploitsSection:AddToggle({ Text = "No damage & Sound Mini", Flag = "FlycopterSilent", Enabled = false })
						local blocklist = {
							EngineSound = true,
							CrashSound = true,
							GearSound = true,
							StartupSound = true,
							Shutoff = true,
							RotorWash = true
						}

						local old
						old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
							if not checkcaller() and flags.FlycopterSilent then
								local method = getnamecallmethod()

								if method == "FireServer" and self:IsA("RemoteEvent") and self:IsDescendantOf(flycopter) then
									local action = ...

									if self.Name == "ReplicateEffect" and blocklist[action] then
										return
									end

									if self.Name == "ReplicateHealth" and action == "TakeDamage" then
										return
									end
								end
							end

							return old(self, ...)
						end))
				ExploitsSection:AddToggle({ Text = "Shoot in Mini", Flag = "ShootMini", Enabled = false })
				local oldindex; oldindex = hookmetamethod(game, "__index", function(self, key)
					if not checkcaller() then
						if key == 'SeatPart' and tostring(self) == 'Humanoid' and flags.ShootMini then
							local caller = getcallingscript()
							if caller and tostring(caller) == 'ViewmodelController' then
								return nil
							end
						end
					end

					return oldindex(self, key)
				end)
				ExploitsSection:AddToggle({ Text = "BTR Teleport", Flag = "BTRTeleport", Enabled = false })
				ExploitsSection:AddKeyPicker({
					Text = "Teleport Keybind",
					Flag = "BTRTeleportKey",
					Mode = "Hold",
					Default = Enum.KeyCode.X,
					Callback = function()
						if not flags.BTRTeleport then
							return
						end

						local player = game.Players.LocalPlayer
						if not player then
							return
						end

						local Character = player.Character
						if not Character then
							return
						end

						local playerHRP = Character:FindFirstChild("HumanoidRootPart")
						if not playerHRP then
							return
						end

						local events = workspace:FindFirstChild("Events")
						local btr = events and events:FindFirstChild("BTR")

						if not btr or not btr:IsA("Model") then
							return Library:Notify({ Text = "ULTIMATE | BTR NOT FOUND IN GAME", Lifetime = 2 })
						end

						local targetPart = btr:FindFirstChild("HumanoidRootPart")
						local humanoid = btr:FindFirstChildOfClass("Humanoid")

						if not targetPart or not humanoid or humanoid.Health <= 0 then
							return Library:Notify({ Text = "ULTIMATE | BTR NOT VALID / DEAD", Lifetime = 2 })
						end

						Library:Notify({ Text = "ULTIMATE | BTR FOUND, ATTEMPTING TP", Lifetime = 1 })
						targetPart.CFrame = playerHRP.CFrame
					end,
				})
				ExploitsSection:AddToggle({
					Text = "Spoof Username",
					Flag = "SpoofUsername",
					Enabled = false,
				})
				ExploitsSection:AddToggle({ Text = "Anti Fling", Flag = "AntiFling", Enabled = false })

				ExploitsSection:AddToggle({
					Text = "Reload Bar",
					Flag = "ReloadBarEnabled",
					Enabled = false,
				})
			end
		end
	end

	task.wait(0.3) --Library.TweeningSpeed)
	Window:InitPanels()
	Library:AutoLoad()

	--// Game Code
	local Camera = Workspace.CurrentCamera
	local Client = Players.LocalPlayer
	repeat
		wait()
	until Client and Client.Character and Workspace:FindFirstChild("VFX")
	local wsVFXFolder = Workspace.VFX
	local VMs = wsVFXFolder and wsVFXFolder:FindFirstChild("VMs")
	local Drops = workspace:FindFirstChild("Drops")
	local Plants = workspace:FindFirstChild("Plants")
	local Animals = workspace:FindFirstChild("Animals")

	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local rsVFXFolder = ReplicatedStorage:WaitForChild("VFX")
	local Values = ReplicatedStorage:WaitForChild("Values")

	local ItemClass = Modules and require(Modules:WaitForChild("ItemClass"))
	local VFXModule = Modules and require(Modules.VFXModule)
	local ItemsModule = Modules and require(Modules.Items)
	local RaycastUtil = Modules and require(Modules.RaycastUtil)
	local SettingsModule = Modules and require(Modules.SettingsModule)
	local SoundModule = Modules and require(Modules.SoundModule)
	local ToolInfo = Modules and require(Modules.ToolInfo)

	if not (ItemClass and VFXModule and ItemsModule and RaycastUtil and SettingsModule and SoundModule) then
		Client:Kick("Failed to load game modules.")
		return
	end

	local clanController, clanControllerShared
	if Client:FindFirstChild("PlayerScripts") and Client.PlayerScripts:FindFirstChild("ClanController") then
		clanController = getsenv(Client.PlayerScripts:WaitForChild("ClanController"))
		clanControllerShared = clanController and clanController.shared
	else
		clanControllerShared = { cachedTeamModels = {} }
	end

	local isTeam = LPH_NO_VIRTUALIZE(function(player)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return false
		end
		local teamCache = clanControllerShared and clanControllerShared.cachedTeamModels
		return teamCache and teamCache[player.UserId] or false
	end)

	local getgun = function(character)
		if not character then
			return "None"
		end
		for _, model in character:GetChildren() do
			if not model:IsA("Model") then
				continue
			end

			if model.Name == "Hair" or model.Name == "HolsterModel" then
				continue
			end

			if not model.PrimaryPart then
				continue
			end

			if
				model:FindFirstChild("Detail")
				or model:FindFirstChild("Main")
				or model:FindFirstChild("Handle")
				or model:FindFirstChild("Attachments")
				or model:FindFirstChild("ArrowAttach")
				or model:FindFirstChild("Attach")
			then
				return model.Name
			end
		end

		return "None"
	end

	RunService.RenderStepped:Connect(function()
		local Character = Client.Character
		if not Character then
			return
		end

		local Root = Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if not Root or not Humanoid then
			return
		end

		if flags.AntiAim then
			local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

			if isShooting then
				Humanoid.AutoRotate = true
			else
				local spin_speed = math.rad((flags.AntiAimSpeed or 50) / 10)

				Humanoid.AutoRotate = false
				Root.CFrame = Root.CFrame * CFrame.Angles(0, spin_speed, 0)
			end
		else
			Humanoid.AutoRotate = true
		end
	end)

	local Targeting = {
		TargetPart = nil,
		TargetCharacter = nil,
		ManipulatedPosition = nil,
		ManipPos = nil,
		Targets = {},
	}

	RunService.Heartbeat:Connect(function()
		if not flags.AntiFling then
			return
		end

		for _, p in ipairs(players:GetPlayers()) do
			if p ~= local_player then
				local char = p.Character
				if char then
					for _, part in ipairs(char:GetChildren()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end
			end
		end
	end)

	--// Gun Mods
	do
		local oldAttachmentStats = ItemClass.AttachmentStats
		ItemClass.AttachmentStats = LPH_NO_UPVALUES(function(v50, v51)
			local tb = debug.traceback()
			local r = oldAttachmentStats(v50, v51)

			if tb and tb:find("ViewmodelController") and r then
				if flags["RPM"] then
					r.FireRateMult = flags["RapidFireRate"] - 1
				end

				if flags["InstantBullet"] then
					r.SpeedMult = 100
				end

				if flags["NoRecoil"] then
					r.RecoilMult = -1
				end

				if flags["NoSpread"] then
					r.AimSpreadMult = -1
					r.HipSpreadMult = -1
				end

				if flags["NoSway"] then
					r.SwayMult = -1
				end
				r.HideTracer = true;
			end

			return r
		end)
		local modules = ReplicatedStorage:FindFirstChild("Modules")
		local items_module = modules and modules:FindFirstChild("Items")

		local weapon_icons = {}

		if items_module then
			local items_table = require(items_module)

			for _, v in pairs(items_table) do
				if typeof(v) == "table" then
					if v.Name and v.Image then
						if typeof(v.Image) == "table" then
							weapon_icons[v.Name] = v.Image.Default
						else
							weapon_icons[v.Name] = v.Image
						end
					end
				end
			end
		else
			warn("Items module not found")
		end

		local RaidEvent = Instance.new("BindableEvent", ReplicatedStorage)



		do
			local S_HUMANOID = "Humanoid"
			local S_HRP = "HumanoidRootPart"
			local S_HEAD = "Head"
			local hui = (gethui and gethui()) or game:GetService("CoreGui")
			local ESP = {}

			local ScreenGui = Instance.new("ScreenGui")
			ScreenGui.IgnoreGuiInset = true
			ScreenGui.Parent = hui

			local OUTLINE = 1
			local BOX_THICKNESS = 2
			local CONSTANT_THICKNESS = true
			local NAME_PADDING_X = 6
			local NAME_PADDING_Y = 2

			local BoxMath = LPH_JIT_MAX(function(model)
				if not model then
					return nil, nil, false
				end

				local root = model:FindFirstChild(S_HRP)
				local head = model:FindFirstChild(S_HEAD)
				if not root or not head then
					return nil, nil, false
				end

				local rootPos = Camera:WorldToViewportPoint(root.Position)
				if rootPos.Z <= 0 then
					return nil, nil, false
				end

				local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
				local bottomPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

				local height = math.abs(topPos.Y - bottomPos.Y)
				if height < 2 then
					return nil, nil, false
				end

				local width = height
				local pos = Vector2.new(rootPos.X - width / 2, topPos.Y)
				local size = Vector2.new(width, height)

				return pos, size, true
			end)

			local function createBox(parent, color)
				local box = Instance.new("Frame")
				box.BackgroundTransparency = 1
				box.Parent = parent
				local sides = {}
				for i = 1, 4 do
					local f = Instance.new("Frame")
					f.BorderSizePixel = 0
					f.BackgroundColor3 = color
					f.Parent = box
					sides[i] = f
				end
				return box, sides
			end

			local function newText()
				local t = Instance.new("TextLabel")
				t.BackgroundTransparency = 1
				t.TextColor3 = Color3.new(1, 1, 1)
				t.TextTransparency = 0
				t.TextStrokeColor3 = Color3.new(0, 0, 0)
				t.TextStrokeTransparency = 0
				t.FontFace = Library.Font
				t.TextSize = 11
				t.TextXAlignment = Enum.TextXAlignment.Center
				t.TextYAlignment = Enum.TextYAlignment.Center
				return t
			end

			local TextGradientRegistry = {}

			local function setTextGradient(label, color1, color2, animated, speed)
				local grad = label:FindFirstChild("Grad")
				if not grad then
					grad = Instance.new("UIGradient")
					grad.Name = "Grad"
					grad.Rotation = 0
					grad.Parent = label
				end
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, color1),
					ColorSequenceKeypoint.new(0.5, color2),
					ColorSequenceKeypoint.new(1, color1),
				})
				grad.Enabled = true
				grad.Offset = Vector2.new(0, 0)
				TextGradientRegistry[label] = { Gradient = grad, Animated = animated, Speed = speed or 4 }
			end

			local function clearTextGradient(label)
				TextGradientRegistry[label] = nil
				local grad = label:FindFirstChild("Grad")
				if grad then
					grad.Enabled = false
					grad.Offset = Vector2.new(0, 0)
				end
			end

			local function applyTextColor(label, color, flags, class)
				if flags[class .. "GradientText"] then
					setTextGradient(
						label,
						flags[class .. "TextGrad1"].Color,
						flags[class .. "TextGrad2"].Color,
						flags[class .. "AnimatedGradientText"],
						flags[class .. "GradientSpeed"] or 4
					)
				else
					clearTextGradient(label)
					label.TextColor3 = color
				end
			end

			local function rgbString(color)
				return string.format(
					"rgb(%d,%d,%d)",
					math.floor(color.R * 255),
					math.floor(color.G * 255),
					math.floor(color.B * 255)
				)
			end

			RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
				if not next(TextGradientRegistry) then return end
				for label, info in pairs(TextGradientRegistry) do
					if not label or not label.Parent then
						TextGradientRegistry[label] = nil
					elseif info.Animated then
						local t = tick() * (info.Speed or 4)
						info.Gradient.Offset = Vector2.new((t % 2) - 1, 0)
					else
						info.Gradient.Offset = Vector2.new(0, 0)
					end
				end
			end))

			local function createESP(char, name, classname)
				local root = char:FindFirstChild(S_HRP)
				local head = char:FindFirstChild(S_HEAD)
				local hum = char:FindFirstChildOfClass(S_HUMANOID)
				local holder = Instance.new("Frame")
				holder.BackgroundTransparency = 1
				holder.Visible = false
				holder.Parent = ScreenGui

				local nameText = newText()
				nameText.Text = name
				nameText.Parent = holder

				local boxGroup = Instance.new("Frame")
				boxGroup.BackgroundTransparency = 1
				boxGroup.Parent = holder

				local outerBox, outerSides = createBox(boxGroup, Color3.new(0, 0, 0))
				local gradBox, gradSides = createBox(boxGroup, Color3.new(1, 1, 1))
				local innerBox, innerSides = createBox(boxGroup, Color3.new(0, 0, 0))

				local gradients = {}
				for i = 1, 4 do
					local g = Instance.new("UIGradient")
					g.Rotation = 90
					g.Parent = gradSides[i]
					gradients[i] = g
				end

				local healthBack = Instance.new("Frame")
				healthBack.BackgroundTransparency = 1
				healthBack.BorderSizePixel = 0
				healthBack.Parent = holder

				local healthOutline = Instance.new("Frame")
				healthOutline.BackgroundColor3 = Color3.new(0, 0, 0)
				healthOutline.BorderSizePixel = 0
				healthOutline.Parent = healthBack

				local healthInner = Instance.new("Frame")
				healthInner.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				healthInner.BorderSizePixel = 0
				healthInner.Parent = healthBack

				local healthFillHolder = Instance.new("Frame")
				healthFillHolder.BackgroundTransparency = 1
				healthFillHolder.BorderSizePixel = 0
				healthFillHolder.ClipsDescendants = true
				healthFillHolder.Parent = healthInner

				local healthFill = Instance.new("Frame")
				healthFill.BorderSizePixel = 0
				healthFill.AnchorPoint = Vector2.new(0, 1)
				healthFill.Position = UDim2.fromScale(0, 1)
				healthFill.Size = UDim2.fromScale(1, 1)
				healthFill.BackgroundColor3 = Color3.new(1, 1, 1)
				healthFill.Parent = healthFillHolder

				local healthGrad = Instance.new("UIGradient")
				healthGrad.Name = "Grad"
				healthGrad.Rotation = -90
				healthGrad.Parent = healthFill

				local distText = newText()
				distText.Parent = holder

				local weaponText = newText()
				weaponText.Text = "[None]"
				weaponText.Parent = holder

				local weaponIcon = Instance.new("ImageLabel")
				weaponIcon.BackgroundTransparency = 1
				weaponIcon.Size = UDim2.fromOffset(26, 26)
				weaponIcon.AnchorPoint = Vector2.new(0.5, 0)
				weaponIcon.Visible = false
				weaponIcon.Parent = holder

				local flagsText = newText()
				flagsText.TextXAlignment = Enum.TextXAlignment.Left
				flagsText.TextYAlignment = Enum.TextYAlignment.Top
				flagsText.RichText = true
				flagsText.TextWrapped = false
				flagsText.Visible = false
				flagsText.Parent = holder

				local cham
				if classname == "Players" then
					cham = Instance.new("Highlight")
					cham.Parent = ScreenGui
					cham.Adornee = char
					cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				end

				local lastBoxColor = nil

				ESP[char] = {
					Holder = holder,
					Name = nameText,
					BoxGroup = boxGroup,
					OuterBox = outerBox,
					OuterSides = outerSides,
					GradBox = gradBox,
					GradSides = gradSides,
					Gradients = gradients,
					InnerBox = innerBox,
					InnerSides = innerSides,
					HealthBack = healthBack,
					HealthOutline = healthOutline,
					HealthInner = healthInner,
					HealthFillHolder = healthFillHolder,
					HealthFill = healthFill,
					HealthGrad = healthGrad,
					Distance = distText,
					Weapon = weaponText,
					WeaponIcon = weaponIcon,
					FlagsText = flagsText,
					Class = classname,
					Cham = cham,
					LastBoxColor = lastBoxColor,
					Root = char:FindFirstChild("HumanoidRootPart"),
					Head = char:FindFirstChild("Head"),
					Hum = char:FindFirstChildOfClass("Humanoid"),

					_lastUpdate = 0,
					_lastDist = nil,
					_lastFlags = nil,
				}
			end

			local function sizeSides(sides, w, h, t)
				sides[1].Position = UDim2.fromOffset(0, 0)
				sides[1].Size = UDim2.fromOffset(w, t)
				sides[2].Position = UDim2.fromOffset(0, h - t)
				sides[2].Size = UDim2.fromOffset(w, t)
				sides[3].Position = UDim2.fromOffset(0, 0)
				sides[3].Size = UDim2.fromOffset(t, h)
				sides[4].Position = UDim2.fromOffset(w - t, 0)
				sides[4].Size = UDim2.fromOffset(t, h)
			end

			local espLastTick = 0
			RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
				local now = tick()
				if now - espLastTick < 1 / 80 then
					return
				end
				espLastTick = now

				for char, e in pairs(ESP) do
					if not char or not e then
						continue
					end

					local class = e.Class
					if not class then
						continue
					end

					local flags = Library.Flags
					local enabled = flags[class .. "ESPEnabled"]

					if not enabled then
						e.Holder.Visible = false
						if e.Cham then
							e.Cham.Enabled = false
						end
						continue
					end


					local hum = e.Hum
					local hrp = e.Root
					local head = e.Head

					if not hrp or not head or not hum then
						e.Root = char:FindFirstChild("HumanoidRootPart")
						e.Head = char:FindFirstChild("Head")
						e.Hum = char:FindFirstChildOfClass("Humanoid")

						hrp = e.Root
						head = e.Head
						hum = e.Hum
					end

					if not hrp or not hum or hum.Health <= 0 then
						e.Holder.Visible = false
						if e.Cham then
							e.Cham.Enabled = false
						end
						continue
					end


					local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
					local now = tick()

					local rate = distance < 200 and 1/80 or 1/60
					if now - e._lastUpdate < rate then
						continue
					end
					e._lastUpdate = now

					local pos, size, ok = BoxMath(char)
					if not ok then
						e.Holder.Visible = false
						if e.Cham then
							e.Cham.Enabled = false
						end
						continue
					end


					if not hrp then
						continue
					end


					size = Vector2.new(math.min(size.X, 120), math.min(size.Y, 180))

					if distance > (flags[class .. "MaxDistance"] or 10000) then
						e.Holder.Visible = false
						if e.Cham then
							e.Cham.Enabled = false
						end
						continue
					end

					local healthPosition = tostring(flags[class .. "HealthPosition"] or "Left")
					local barW = 4
					local gap = 4
					local reservedLeft = healthPosition == "Left" and (barW + gap + OUTLINE) or OUTLINE

					e.Holder.Position = UDim2.fromOffset(pos.X - reservedLeft, pos.Y)
					e.Holder.Visible = true

					e.BoxGroup.Position = UDim2.fromOffset(reservedLeft, 0)
					e.BoxGroup.Size = UDim2.fromOffset(size.X, size.Y)

					e.Name.Position = UDim2.fromOffset(reservedLeft - NAME_PADDING_X, -15 - NAME_PADDING_Y)
					e.Name.Size = UDim2.fromOffset(size.X + NAME_PADDING_X * 2, 14 + NAME_PADDING_Y * 2)
					e.Name.Visible = flags[class .. "Names"]

					local isTarget = false
					if Targeting and Targeting.TargetPart and hrp then
						isTarget = (hrp.Position - Targeting.TargetPart.Position).Magnitude < 2
					end

					local nameColor = (typeof(flags[class .. "NameColor"]) == "table" and flags[class .. "NameColor"].Color) or Color3.new(1, 1, 1)
					if isTarget and flags[class .. "TargetHighlight"] then
						nameColor = flags[class .. "TargetColor"].Color
					end
					applyTextColor(e.Name, nameColor, flags, class)

					e.OuterBox.Position = UDim2.fromOffset(-OUTLINE, -OUTLINE)
					e.OuterBox.Size = UDim2.fromOffset(size.X + OUTLINE * 2, size.Y + OUTLINE * 2)
					sizeSides(e.OuterSides, size.X + OUTLINE * 2, size.Y + OUTLINE * 2, OUTLINE)

					e.GradBox.Position = UDim2.fromOffset(0, 0)
					e.GradBox.Size = UDim2.fromOffset(size.X, size.Y)
					sizeSides(e.GradSides, size.X, size.Y, BOX_THICKNESS)

					e.InnerBox.Position = UDim2.fromOffset(OUTLINE, OUTLINE)
					e.InnerBox.Size = UDim2.fromOffset(size.X - OUTLINE * 2, size.Y - OUTLINE * 2)
					sizeSides(e.InnerSides, size.X - OUTLINE * 2, size.Y - OUTLINE * 2, OUTLINE)

					local boxOn = flags[class .. "Boxes"]
					e.OuterBox.Visible = boxOn
					e.GradBox.Visible = boxOn
					e.InnerBox.Visible = boxOn

					local boxColor = flags[class .. "BoxColor"].Color
					if isTarget and flags[class .. "TargetHighlight"] then
						boxColor = flags[class .. "TargetColor"].Color
					end

					if e.LastBoxColor ~= boxColor then
						e.LastBoxColor = boxColor
						local cs = ColorSequence.new({
							ColorSequenceKeypoint.new(0, boxColor),
							ColorSequenceKeypoint.new(1, boxColor),
						})
						for _, g in ipairs(e.Gradients) do
							g.Color = cs
						end
					end

					e.HealthBack.Visible = flags[class .. "Health"]
					if healthPosition == "Bottom" then
						e.HealthBack.Position = UDim2.fromOffset(reservedLeft, size.Y + 2)
						e.HealthBack.Size = UDim2.fromOffset(size.X, barW)

						e.HealthOutline.Position = UDim2.fromOffset(0, 0)
						e.HealthOutline.Size = UDim2.fromOffset(size.X, barW)

						e.HealthInner.Position = UDim2.fromOffset(1, 1)
						e.HealthInner.Size = UDim2.fromOffset(size.X - 2, barW - 2)

						e.HealthFillHolder.Position = UDim2.fromOffset(0, 0)
						e.HealthFillHolder.Size = UDim2.fromScale(1, 1)

						local hpBottom = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
						e.HealthFill.AnchorPoint = Vector2.new(0, 0)
						e.HealthFill.Position = UDim2.fromScale(0, 0)
						e.HealthFill.Size = UDim2.fromScale(hpBottom, 1)
					else
						e.HealthBack.Position = UDim2.fromOffset(reservedLeft - barW - gap, 0)
						e.HealthBack.Size = UDim2.fromOffset(barW, size.Y)

						e.HealthOutline.Position = UDim2.fromOffset(0, 0)
						e.HealthOutline.Size = UDim2.fromOffset(barW, size.Y)

						e.HealthInner.Position = UDim2.fromOffset(1, 1)
						e.HealthInner.Size = UDim2.fromOffset(barW - 2, size.Y - 2)

						e.HealthFillHolder.Position = UDim2.fromOffset(0, 0)
						e.HealthFillHolder.Size = UDim2.fromScale(1, 1)

						local hpLeft = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
						e.HealthFill.AnchorPoint = Vector2.new(0, 1)
						e.HealthFill.Position = UDim2.fromScale(0, 1)
						e.HealthFill.Size = UDim2.fromScale(1, hpLeft)
					end

					if healthPosition == "Bottom" then
						e.HealthGrad.Rotation = 0
					else
						e.HealthGrad.Rotation = -90
					end

					e.HealthGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, flags[class .. "HealthLow"].Color),
						ColorSequenceKeypoint.new(0.5, flags[class .. "HealthMid"].Color),
						ColorSequenceKeypoint.new(1, flags[class .. "HealthHigh"].Color),
					})

					if class == "Players" and e.Cham then
						if flags[class .. "Chams"] then
							e.Cham.Enabled = true

							local fill = flags[class .. "ChamsColor1"].Color
							local outline = flags[class .. "ChamsColor2"].Color
							if isTarget and flags[class .. "TargetHighlight"] then
								fill = flags[class .. "TargetColor"].Color
								outline = flags[class .. "TargetColor"].Color
							end

							e.Cham.FillColor = fill
							e.Cham.OutlineColor = outline
							e.Cham.FillTransparency = 1 - flags[class .. "ChamsColor1"].Transparency
							e.Cham.OutlineTransparency = 1 - flags[class .. "ChamsColor2"].Transparency
						else
							e.Cham.Enabled = false
						end
					end

					local flagsText = ""
					if flags[class .. "Flags"] then
						if isTarget and Targeting and Targeting.ManipulatedPosition and Targeting.TargetPart then
							flagsText = flagsText
								.. "<font color=\"" .. rgbString(flags.ManipulationIndicatorColor.Color) .. "\">MANIPULATED</font>\n"
								.. "<font color=\"rgb(255,255,255)\">" .. Targeting.TargetPart.Name:lower() .. "</font>"
						end

						if isTarget and Targeting and flags.HitScan and Targeting.ScannedPosition and Targeting.TargetPart then
							if flagsText ~= "" then
								flagsText = flagsText .. "\n"
							end
							flagsText = flagsText
								.. "<font color=\"" .. rgbString(flags.HitScanIndicatorColor.Color) .. "\">HITSCANNED</font>\n"
								.. "<font color=\"rgb(255,255,255)\">" .. Targeting.TargetPart.Name:lower() .. "</font>"
						end

						if isTarget and Targeting and Targeting.TargetObject and Targeting.TargetObject.CoreInformation and Targeting.TargetObject.CoreInformation.Visible and Targeting.TargetPart then
							if flagsText ~= "" then
								flagsText = flagsText .. "\n"
							end
							flagsText = flagsText
								.. "<font color=\"" .. rgbString(flags.VisibleIndicatorColor.Color) .. "\">VISIBLE</font>\n"
								.. "<font color=\"rgb(255,255,255)\">" .. Targeting.TargetPart.Name:lower() .. "</font>"
						end
					end

					e.FlagsText.Position = UDim2.fromOffset(reservedLeft + size.X + 4, 0)
					e.FlagsText.Size = UDim2.fromOffset(120, size.Y)
					e.FlagsText.Text = flagsText
					e.FlagsText.Visible = flagsText ~= ""

					local distanceY = size.Y + (healthPosition == "Bottom" and 10 or 6)
					e.Distance.Position = UDim2.fromOffset(reservedLeft, distanceY)
					e.Distance.Size = UDim2.fromOffset(size.X, 14)
					e.Distance.Visible = flags[class .. "Distance"]
					local distFloor = math.floor(distance)
					if e._lastDist ~= distFloor then
						e._lastDist = distFloor
						e.Distance.Text = distFloor .. " studs"
					end

					local distColor = flags[class .. "DistanceColor"].Color
					if isTarget and flags[class .. "TargetHighlight"] then
						distColor = flags[class .. "TargetColor"].Color
					end
					applyTextColor(e.Distance, distColor, flags, class)

					local weaponVisible = flags[class .. "Weapon"]
					local iconVisible = flags[class .. "WeaponIcon"] and weaponVisible

					local weaponY = distanceY + 14
					e.Weapon.Position = UDim2.fromOffset(reservedLeft, weaponY)
					e.Weapon.Size = UDim2.fromOffset(size.X, 14)
					e.Weapon.Visible = weaponVisible

					if weaponVisible or iconVisible then
						local tool = getgun(char)
						if e._lastTool ~= tool then
							e._lastTool = tool
							e.Weapon.Text = "[" .. tostring(tool) .. "]"
						end

						if iconVisible then
							local icon = weapon_icons and weapon_icons[tool]
							if icon then
								e.WeaponIcon.Visible = true
								e.WeaponIcon.Image = icon
								e.WeaponIcon.Position = UDim2.fromOffset(reservedLeft + size.X / 2, weaponY + 16)
							else
								e.WeaponIcon.Visible = false
							end
						else
							e.WeaponIcon.Visible = false
						end

						local weaponColor = flags[class .. "WeaponColor"].Color
						if isTarget and flags[class .. "TargetHighlight"] then
							weaponColor = flags[class .. "TargetColor"].Color
						end
						applyTextColor(e.Weapon, weaponColor, flags, class)
					else
						e.WeaponIcon.Visible = false
					end
				end
			end))

			local function removeESP(char)
				local e = ESP[char]
				if not e then
					return
				end
				e.Holder:Destroy()
				if e.Cham then
					e.Cham:Destroy()
				end
				ESP[char] = nil
			end

			local function hookPlayer(p)
				if p == Client then
					return
				end
				p.CharacterAdded:Connect(function(c)
					createESP(c, p.Name, "Players")
				end)
				p.CharacterRemoving:Connect(function(c)
					removeESP(c)
				end)
				if p.Character then
					createESP(p.Character, p.Name, "Players")
				end
			end

			for _, p in ipairs(Players:GetPlayers()) do
				hookPlayer(p)
			end
			local LastVisiblePart = {}
			Players.PlayerAdded:Connect(hookPlayer)
			Client.CharacterAdded:Connect(function()
				for k in next, LastVisiblePart do
					if not k.Parent then
						LastVisiblePart[k] = nil
					end
				end
			end)
			local SoldierClassType = {
				Brutus = "Boss",
				Bruno = "Boss",
				BTR = "Boss",
				Boris = "Boss",
				Soldier = "AI",
			}

			local Military = workspace:FindFirstChild("Military")
			local Events = workspace:FindFirstChild("Events")

			if Military and Events then
				local function CacheSoldier(model)
					if typeof(model) ~= "Instance" then
						return
					end
					if not model.Parent then
						return
					end
					local classType = SoldierClassType[model.Name]
					if not classType then
						return
					end
					if rawget(ESP, model) then
						return
					end
					createESP(model, model.Name, classType)
				end

				local function OnModelAdded(model)
					task.defer(function()
						if typeof(model) == "Instance" and model.Parent then
							CacheSoldier(model)
						end
					end)
				end

				local function OnModelRemoved(model)
					removeESP(model)
				end

				for _, obj in ipairs(Events:GetChildren()) do
					if obj.Name == "BTR" then
						CacheSoldier(obj)
					end
				end

				Events.ChildAdded:Connect(function(obj)
					if obj.Name == "BTR" then
						OnModelAdded(obj)
					end
				end)

				Events.ChildRemoved:Connect(function(obj)
					if obj.Name == "BTR" then
						OnModelRemoved(obj)
					end
				end)

				for _, folder in ipairs(Military:GetChildren()) do
					for _, soldier in ipairs(folder:GetChildren()) do
						if soldier:IsA("Model") then
							CacheSoldier(soldier)
						end
					end

					folder.ChildAdded:Connect(function(soldier)
						if soldier:IsA("Model") then
							OnModelAdded(soldier)
						end
					end)

					folder.ChildRemoved:Connect(function(soldier)
						if soldier:IsA("Model") then
							OnModelRemoved(soldier)
						end
					end)
				end
			end
		end
				local isTarget = false

				if Targeting and Targeting.TargetPart then
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hrp then
						if (hrp.Position - Targeting.TargetPart.Position).Magnitude < 2 then
							isTarget = true
						end
					end
				end
				--// Fov Circle
				do
					local FovCircleOutline = Drawing.new("Circle")
					FovCircleOutline.Visible = false
					FovCircleOutline.NumSides = 64
					FovCircleOutline.ZIndex = 9
					FovCircleOutline.Filled = false
					FovCircleOutline.Transparency = 1
					FovCircleOutline.Radius = 200
					FovCircleOutline.Thickness = 4
					FovCircleOutline.Color = Color3.fromRGB(0, 0, 0)

					local FovCircle = Drawing.new("Circle")
					FovCircle.Visible = false
					FovCircle.NumSides = 64
					FovCircle.ZIndex = 10
					FovCircle.Filled = false
					FovCircle.Transparency = 1
					FovCircle.Radius = 200
					FovCircle.Thickness = 2
					FovCircle.Color = Color3.fromRGB(255, 20, 147)

					local FovFill = Drawing.new("Circle")
					FovFill.Visible = false
					FovFill.NumSides = 64
					FovFill.ZIndex = 8
					FovFill.Filled = true
					FovFill.Transparency = 1
					FovFill.Radius = 200
					FovFill.Thickness = 0
					FovFill.Color = Color3.fromRGB(255, 20, 147)

					local textHolder = Instance.new("Frame")
					textHolder.BackgroundTransparency = 1
					textHolder.BorderSizePixel = 0
					textHolder.ZIndex = 3
					textHolder.AnchorPoint = Vector2.new(0.5, 0)
					textHolder.Size = UDim2.fromOffset(0, 0)
					textHolder.Position = UDim2.new(0.5, 0, 0.5, 10)
					textHolder.AutomaticSize = Enum.AutomaticSize.XY
					textHolder.Visible = true

					local ScreenGui = Instance.new("ScreenGui")
					ScreenGui.IgnoreGuiInset = true
					ScreenGui.DisplayOrder = 999
					ScreenGui.Parent = gethui()

					textHolder.Parent = ScreenGui

					local layout = Instance.new("UIListLayout")
					layout.FillDirection = Enum.FillDirection.Vertical
					layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					layout.VerticalAlignment = Enum.VerticalAlignment.Top
					layout.Padding = UDim.new(0, 2)
					layout.Parent = textHolder

					local manipulationText = Instance.new("TextLabel")
					manipulationText.BackgroundTransparency = 1
					manipulationText.Size = UDim2.fromOffset(0, 0)
					manipulationText.AutomaticSize = Enum.AutomaticSize.XY
					manipulationText.TextWrapped = false
					manipulationText.FontFace = Library.Font
					manipulationText.TextSize = 14
					manipulationText.TextColor3 = Color3.new(1, 1, 1)
					manipulationText.TextStrokeColor3 = Color3.new(0, 0, 0)
					manipulationText.TextStrokeTransparency = 0
					manipulationText.ZIndex = textHolder.ZIndex
					manipulationText.Parent = textHolder

					local hitscanText = Instance.new("TextLabel")
					hitscanText.BackgroundTransparency = 1
					hitscanText.Size = UDim2.fromOffset(0, 0)
					hitscanText.AutomaticSize = Enum.AutomaticSize.XY
					hitscanText.TextWrapped = false
					hitscanText.FontFace = Library.Font
					hitscanText.TextSize = 14
					hitscanText.TextColor3 = Color3.new(1, 1, 1)
					hitscanText.TextStrokeColor3 = Color3.new(0, 0, 0)
					hitscanText.TextStrokeTransparency = 0
					hitscanText.ZIndex = textHolder.ZIndex
					hitscanText.Parent = textHolder

					local visibleText = Instance.new("TextLabel")
					visibleText.BackgroundTransparency = 1
					visibleText.Size = UDim2.fromOffset(0, 0)
					visibleText.AutomaticSize = Enum.AutomaticSize.XY
					visibleText.TextWrapped = false
					visibleText.FontFace = Library.Font
					visibleText.TextSize = 14
					visibleText.TextColor3 = Color3.new(1, 1, 1)
					visibleText.TextStrokeColor3 = Color3.new(0, 0, 0)
					visibleText.TextStrokeTransparency = 0
					visibleText.ZIndex = textHolder.ZIndex
					visibleText.Parent = textHolder

					local lastupd = tick()

					RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
						if tick() - lastupd < 1/30 then return end
						lastupd = tick()

						local radius = flags.FovSize or 200
						local thickness = flags.FovThickness or 2

						local vp = Camera.ViewportSize
						local pos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

						if flags.CombatIndicators then
							if Targeting.ManipulatedPosition and Targeting.TargetPart then
								local dist = (Camera.CFrame.Position - Targeting.ManipulatedPosition).Magnitude
								local name = Targeting.TargetPart.Name:lower()

								manipulationText.Text = "<font color=\"rgb("..math.floor(flags.ManipulationIndicatorColor.Color.R*255)..","..math.floor(flags.ManipulationIndicatorColor.Color.G*255)..","..math.floor(flags.ManipulationIndicatorColor.Color.B*255)..")\">MANIPULATED</font>\n<font color=\"rgb(255,255,255)\">"..name.." - "..math.floor(dist).." studs</font>"
								manipulationText.RichText = true

								manipulationText.Visible = true
								hitscanText.Visible = false
								visibleText.Visible = false

							elseif flags.HitScan and Targeting.ScannedPosition and Targeting.TargetPart then
								local dist = (Targeting.TargetPart.Position - Targeting.ScannedPosition).Magnitude
								local name = Targeting.TargetPart.Name:lower()

								hitscanText.Text = "<font color=\"rgb("..math.floor(flags.HitScanIndicatorColor.Color.R*255)..","..math.floor(flags.HitScanIndicatorColor.Color.G*255)..","..math.floor(flags.HitScanIndicatorColor.Color.B*255)..")\">HITSCANNED</font>\n<font color=\"rgb(255,255,255)\">"..name.." - "..math.floor(dist).." studs</font>"
								hitscanText.RichText = true

								hitscanText.Visible = true
								manipulationText.Visible = false
								visibleText.Visible = false

							elseif Targeting.TargetObject and Targeting.TargetObject.CoreInformation and Targeting.TargetObject.CoreInformation.Visible and Targeting.TargetPart then
								local name = Targeting.TargetPart.Name:lower()

								visibleText.Text = "<font color=\"rgb("..math.floor(flags.VisibleIndicatorColor.Color.R*255)..","..math.floor(flags.VisibleIndicatorColor.Color.G*255)..","..math.floor(flags.VisibleIndicatorColor.Color.B*255)..")\">VISIBLE</font>\n<font color=\"rgb(255,255,255)\">"..name.."</font>"
								visibleText.RichText = true

								visibleText.Visible = true
								manipulationText.Visible = false
								hitscanText.Visible = false

							else
								manipulationText.Visible = false
								hitscanText.Visible = false
								visibleText.Visible = false
							end
						else
							manipulationText.Visible = false
							hitscanText.Visible = false
							visibleText.Visible = false
						end

						if not flags.FovEnabled then
							FovCircle.Visible = false
							FovCircleOutline.Visible = false
							FovFill.Visible = false
							return
						end

						local base = flags.FovColor
						local fovColor = base.Color or base

						if Targeting and Targeting.TargetPart and flags.PlayersTargetHighlight then
							fovColor = flags.PlayersTargetColor.Color
						end

						FovCircle.Position = pos
						FovCircleOutline.Position = pos
						FovFill.Position = pos

						FovCircle.Radius = radius
						FovCircleOutline.Radius = radius
						FovFill.Radius = radius

						local filled = flags.FovFilled == true
						local fillTrans = flags.FovFillTransparency or 1

						FovCircleOutline.Filled = false
						FovCircleOutline.Thickness = thickness + 2
						FovCircleOutline.Transparency = 1
						FovCircleOutline.Color = Color3.new(0, 0, 0)

						FovCircle.Filled = false
						FovCircle.Thickness = thickness
						FovCircle.Transparency = 1
						FovCircle.Color = fovColor

						FovFill.Filled = filled
						FovFill.Thickness = 0
						FovFill.Transparency = filled and fillTrans or 1
						FovFill.Color = fovColor

						FovCircle.Visible = flags.FovEnabled
						FovCircleOutline.Visible = flags.FovEnabled
						FovFill.Visible = flags.FovEnabled and filled
					end))
				end
					local CurrentTarget2D = nil

					local Snapline = Drawing.new("Line")
					Snapline.Thickness = 2
					Snapline.Visible = false

					local SnaplineOutline1 = Drawing.new("Line")
					SnaplineOutline1.Thickness = 2
					SnaplineOutline1.Color = Color3.new(0, 0, 0)
					SnaplineOutline1.Visible = false

					local SnaplineOutline2 = Drawing.new("Line")
					SnaplineOutline2.Thickness = 2
					SnaplineOutline2.Color = Color3.new(0, 0, 0)
					SnaplineOutline2.Visible = false

					RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
						if not flags.Snapline then
							Snapline.Visible = false
							SnaplineOutline1.Visible = false
							SnaplineOutline2.Visible = false
							return
						end

						local part = Targeting and Targeting.TargetPart
						if not part then
							Snapline.Visible = false
							SnaplineOutline1.Visible = false
							SnaplineOutline2.Visible = false
							return
						end

						local cam = workspace.CurrentCamera
						local pos, onScreen = cam:WorldToViewportPoint(part.Position)
						if not onScreen then
							Snapline.Visible = false
							SnaplineOutline1.Visible = false
							SnaplineOutline2.Visible = false
							return
						end

						local viewport = cam.ViewportSize
						local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
						local radius = flags.FovSize or 200

						local targetPos = Vector2.new(pos.X, pos.Y)
						CurrentTarget2D = targetPos
						if (targetPos - center).Magnitude > radius then
							Snapline.Visible = false
							SnaplineOutline1.Visible = false
							SnaplineOutline2.Visible = false
							return
						end

						local origin2D

						if flags.SnaplineOrigin == "Barrel" then
							local origin3D

							if workspace:FindFirstChild("VFX") and workspace.VFX:FindFirstChild("VMs") then
								local Viewmodels = workspace.VFX.VMs:GetChildren()

								if #Viewmodels >= 1 then
									local VM = Viewmodels[1]
									local Weapon = VM and VM:FindFirstChild("Weapon")
									local Barrel = Weapon and Weapon:FindFirstChild("FlashPart")

									if Barrel then
										local barrelPos, visible = cam:WorldToViewportPoint(Barrel.Position)
										if visible then
											origin2D = Vector2.new(barrelPos.X, barrelPos.Y)
										end
									end
								end
							end


							if not origin2D then
								origin2D = center
							end
						else
							origin2D = game:GetService("UserInputService"):GetMouseLocation()
						end

						if (origin2D - center).Magnitude > radius then
							Snapline.Visible = false
							SnaplineOutline1.Visible = false
							SnaplineOutline2.Visible = false
							return
						end

						local from = origin2D
						local to = targetPos

						local dir = (to - from)
						if dir.Magnitude == 0 then
							return
						end
						dir = dir.Unit

						local perp = Vector2.new(-dir.Y, dir.X)
						local offset = perp * 1.5

						SnaplineOutline1.From = from + offset
						SnaplineOutline1.To = to + offset
						SnaplineOutline1.Visible = false

						SnaplineOutline2.From = from - offset
						SnaplineOutline2.To = to - offset
						SnaplineOutline2.Visible = false

						Snapline.From = from
						Snapline.To = to

						local col = flags.SnaplineColor
						Snapline.Color = typeof(col) == "table" and col.Color or col or Color3.fromRGB(255,255,255)

						Snapline.Visible = true
					end))

					Crosshair.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)

					RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
						if not Crosshair or not Crosshair.ScreenGui then
							return
						end

						Crosshair.ScreenGui.Enabled = flags.Crosshair
						if not flags.Crosshair then
							return
						end

						local Length = flags.CrosshairLength
						local Width = flags.CrosshairWidth
						local Gap = flags.CrosshairGap

						local Color = typeof(flags.IndependentColor) == "table" and flags.IndependentColor.Color
							or flags.IndependentColor

						local Camera = workspace.CurrentCamera
						if not Camera then
							return
						end

						local ScreenSize = Camera.ViewportSize
						local pos2D = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)

						local scale = 1

						if flags.CrosshairLock then
							local worldPos

							if Targeting and Targeting.TargetPart then
								worldPos = Targeting.TargetPart.Position
							end

							if worldPos then
								local pos, onScreen = Camera:WorldToViewportPoint(worldPos)
								if onScreen then
									pos2D = Vector2.new(pos.X, pos.Y)

									local dist = (Camera.CFrame.Position - worldPos).Magnitude
									scale = math.clamp(1 - (dist / 300), 0.5, 1)
								end
							end
						end

						local sLength = Length * scale
						local sWidth = Width * scale
						local sGap = Gap * scale

						Crosshair.Objects[1].Size = UDim2.new(0, sWidth, 0, sLength)
						Crosshair.Objects[2].Size = UDim2.new(0, sWidth, 0, sLength)
						Crosshair.Objects[3].Size = UDim2.new(0, sLength, 0, sWidth)
						Crosshair.Objects[4].Size = UDim2.new(0, sLength, 0, sWidth)

						Crosshair.Objects[1].Position = UDim2.new(0.5, 0, 0.5, -sGap)
						Crosshair.Objects[2].Position = UDim2.new(0.5, 0, 0.5, sGap)
						Crosshair.Objects[3].Position = UDim2.new(0.5, sGap, 0.5, 0)
						Crosshair.Objects[4].Position = UDim2.new(0.5, -sGap, 0.5, 0)

						if flags.RotateCrosshair then
							Crosshair.MainFrame.Rotation += 0.5
						else
							Crosshair.MainFrame.Rotation = 0
						end

						for i = 1, 4 do
							Crosshair.Objects[i].BackgroundColor3 = Color

							local g = Crosshair.Objects[i]:FindFirstChildOfClass("UIGradient")
							if g then
								g.Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0),
									NumberSequenceKeypoint.new(0.6334, flags.CrosshairTransparency1),
									NumberSequenceKeypoint.new(1, flags.CrosshairTransparency2),
								})
							end
						end

						Crosshair.MainFrame.Position = UDim2.new(0, pos2D.X, 0, pos2D.Y)
					end))
					Visuals = Visuals or {}

					if not Visuals.VMHighlight then
						local h = Instance.new("Highlight")
						h.Name = "VMHighlight"
						h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						h.Enabled = false
						h.Parent = game:GetService("CoreGui")
						Visuals.VMHighlight = h
					end

					--// Misc ESP
					do
						local miscCache = {}

						local ScreenGui = Instance.new("ScreenGui")
						ScreenGui.IgnoreGuiInset = true
						ScreenGui.Parent = gethui()

						local function espify(obj, staticname, manualflag)
							if not obj or miscCache[obj] then
								return
							end

							local flag = manualflag or obj.Name:gsub("_Node$", "")

							local label = Instance.new("TextLabel")
							label.BackgroundTransparency = 1
							label.TextSize = 12
							label.FontFace = Library.Font
							label.TextColor3 = Color3.new(1, 1, 1)
							label.AnchorPoint = Vector2.new(0.5, 0.5)
							label.AutomaticSize = Enum.AutomaticSize.XY
							label.Size = UDim2.fromOffset(0, 0)
							label.Visible = false
							label.Parent = ScreenGui

							local stroke = Instance.new("UIStroke")
							stroke.Thickness = 1
							stroke.Color = Color3.new(0, 0, 0)
							stroke.Parent = label

							miscCache[obj] = {
								obj = obj,
								label = label,
								stroke = stroke,
								flag = flag,
								staticname = staticname,
							}
						end

						local function removeEsp(obj)
							local data = miscCache[obj]
							if data then
								data.label:Destroy()
								miscCache[obj] = nil
							end
						end

						local nodes = workspace:FindFirstChild("Nodes")
						local bases = workspace:FindFirstChild("Bases")


						if nodes then
							local function addNode(v)
								if v:IsA("BasePart") or v:IsA("Model") then
									espify(v)
								end
							end

							for _, v in nodes:GetChildren() do
								addNode(v)
							end
							nodes.ChildAdded:Connect(addNode)
							nodes.ChildRemoved:Connect(removeEsp)
						end


						if bases then
							local eggNames = {
								["Large Egg"] = true,
								["Medium Egg"] = true,
								["Small Egg"] = true,
							}

							local function handleDescendant(obj)
								if not obj then
									return
								end

								-- normal misc objects
								if
									obj:IsA("Model")
									and (
										obj.Name == "Care Package"
										or obj.Name == "Salvaged Flycopter"
										or obj.Name == "Body Bag"
										or obj.Name == "Auto Turret"
										or obj.Name == "Shotgun Turret"
									)
								then
									espify(obj)
									return
								end


								if obj:IsA("Model") and eggNames[obj.Name] then
									local parent = obj.Parent
									while parent do
										if parent.Name == "Loners" then
											espify(obj, obj.Name, obj.Name)
											break
										end
										parent = parent.Parent
									end
								end
							end

							for _, v in ipairs(bases:GetDescendants()) do
								handleDescendant(v)
							end

							bases.DescendantAdded:Connect(handleDescendant)
							bases.DescendantRemoving:Connect(removeEsp)
						end


						if Drops and Plants then
							local function addDrop(item)
								if not item:IsA("Model") or miscCache[item] then
									return
								end
								local flags = Library.Flags
								local distance = (Camera.CFrame.Position - item:GetPivot().Position).Magnitude
								if distance <= (flags.DropsMaxDistance or math.huge) then
									espify(item, item.Name, "Drops")
								end
							end

							local function addPlant(plant)
								if not plant:IsA("Model") or miscCache[plant] then
									return
								end
								local flags = Library.Flags
								local name = string.gsub(plant.Name, " Plant", "")
								local distance = (Camera.CFrame.Position - plant:GetPivot().Position).Magnitude
								if name == "Wool" and distance <= (flags.WoolMaxDistance or math.huge) then
									espify(plant, "Wool", "Wool")
								end
							end

							for _, item in pairs(Drops:GetChildren()) do
								addDrop(item)
							end
							for _, plant in pairs(Plants:GetChildren()) do
								addPlant(plant)
							end

							Drops.ChildAdded:Connect(addDrop)
							Drops.ChildRemoved:Connect(removeEsp)
							Plants.ChildAdded:Connect(addPlant)
							Plants.ChildRemoved:Connect(removeEsp)
						end


						if Animals then
							local function addAnimal(animal)
								if not animal:IsA("Model") then
									return
								end
								local name = animal.Name:lower():gsub("prefab_animal_", ""):gsub("_", " ")
								espify(animal, name, "Animals")
							end

							for _, animal in pairs(Animals:GetChildren()) do
								addAnimal(animal)
							end
							Animals.ChildAdded:Connect(addAnimal)
							Animals.ChildRemoved:Connect(removeEsp)
						end


						local step = 1 / 60
						local lastTick = tick()

						RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
							local now = tick()
							if now - lastTick < step then
								return
							end
							lastTick = now

							local flags = Library.Flags
							local miscEnabled = flags.MiscEnabledESP
							local camPos = Camera.CFrame.Position

							for obj, data in next, miscCache do
								if not obj or not obj.Parent then
									data.label:Destroy()
									miscCache[obj] = nil
									continue
								end

								if not miscEnabled or not flags[data.flag .. "Enabled"] then
									data.label.Visible = false
									continue
								end

								local worldPos = obj:IsA("BasePart") and obj.Position or obj:GetPivot().Position

								local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
								if not onScreen then
									data.label.Visible = false
									continue
								end

								local dist = (camPos - worldPos).Magnitude
								local maxDist = flags[data.flag .. "MaxDistance"] or math.huge
								if dist > maxDist then
									data.label.Visible = false
									continue
								end

								local name = data.staticname or data.flag

								data.label.Visible = true
								data.label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
								data.label.Text = string.format("%s \n%d Studs", name, math.floor(dist))

								local col = flags[data.flag .. "Color"]
								if col then
									data.label.TextColor3 = col.Color
								end
							end
						end))
					end

					local CurrentVM = nil

					local VMs = workspace:WaitForChild("VFX"):WaitForChild("VMs")

					VMs.ChildAdded:Connect(function(vm)
						if vm:IsA("Model") then
							CurrentVM = vm
						end
					end)

					VMs.ChildRemoved:Connect(function(vm)
						if vm == CurrentVM then
							CurrentVM = nil
						end
					end)

					Utility.GetCurrentItem = function()
						return CurrentVM
					end

					RunService.RenderStepped:Connect(function()
						local vm = Utility.GetCurrentItem()

						if flags.HighlightViewmodel and vm and Visuals.VMHighlight then
							Visuals.VMHighlight.Adornee = vm
							Visuals.VMHighlight.Enabled = true

							local fill = flags.VMFillColor
							if typeof(fill) == "table" then
								Visuals.VMHighlight.FillColor = fill.Color
								Visuals.VMHighlight.FillTransparency = fill.Transparency
							end

							local outline = flags.VMOutlineColor
							if typeof(outline) == "table" then
								Visuals.VMHighlight.OutlineColor = outline.Color
								Visuals.VMHighlight.OutlineTransparency = outline.Transparency
							end
						else
							if Visuals.VMHighlight then
								Visuals.VMHighlight.Enabled = false
							end
						end
					end)

					do
						local raidGui = Library.Holder.Instance

						local clusters = {}

						local function destroyUI(cl)
							local ui = cl.ui
							if ui then
								ui:Destroy()
								cl.ui = nil
							end
						end

						local function buildUI(cl)
							destroyUI(cl)

							local root = Instance.new("Frame")
							root.BackgroundTransparency = 1
							root.AnchorPoint = Vector2.new(0.5, 1)
							root.Size = UDim2.fromOffset(200, 64)
							root.Parent = raidGui

							local vlist = Instance.new("UIListLayout")
							vlist.FillDirection = Enum.FillDirection.Vertical
							vlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
							vlist.VerticalAlignment = Enum.VerticalAlignment.Center
							vlist.Padding = UDim.new(0, 2)
							vlist.Parent = root

							local function outline(lbl)
								lbl.TextStrokeTransparency = 0
								lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
							end

							local title = Instance.new("TextLabel")
							title.BackgroundTransparency = 1
							title.Size = UDim2.fromOffset(200, 16)
							title.Text = "Raid"
							title.TextColor3 = Color3.fromRGB(255, 60, 60)
							title.TextSize = 14
							title.FontFace = Library.Font
							title.TextXAlignment = Enum.TextXAlignment.Center
							title.LayoutOrder = 1
							outline(title)
							title.Parent = root

							local infoRow = Instance.new("Frame")
							infoRow.BackgroundTransparency = 1
							infoRow.Size = UDim2.fromOffset(200, 16)
							infoRow.LayoutOrder = 2
							infoRow.Parent = root

							local hinfo = Instance.new("UIListLayout")
							hinfo.FillDirection = Enum.FillDirection.Horizontal
							hinfo.HorizontalAlignment = Enum.HorizontalAlignment.Center
							hinfo.VerticalAlignment = Enum.VerticalAlignment.Center
							hinfo.Padding = UDim.new(0, 8)
							hinfo.Parent = infoRow

							local distLabel = Instance.new("TextLabel")
							distLabel.BackgroundTransparency = 1
							distLabel.Size = UDim2.fromOffset(80, 16)
							distLabel.TextColor3 = Color3.new(1, 1, 1)
							distLabel.TextSize = 14
							distLabel.FontFace = Library.Font
							distLabel.TextXAlignment = Enum.TextXAlignment.Center
							outline(distLabel)
							distLabel.Parent = infoRow

							local timeLabel = Instance.new("TextLabel")
							timeLabel.BackgroundTransparency = 1
							timeLabel.Size = UDim2.fromOffset(100, 16)
							timeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
							timeLabel.TextSize = 14
							timeLabel.FontFace = Library.Font
							timeLabel.TextXAlignment = Enum.TextXAlignment.Center
							outline(timeLabel)
							timeLabel.Parent = infoRow

							local iconsRow = Instance.new("Frame")
							iconsRow.BackgroundTransparency = 1
							iconsRow.Size = UDim2.new(1, 0, 0, 36)
							iconsRow.Parent = root
							iconsRow.LayoutOrder = 3

							local hicons = Instance.new("UIListLayout")
							hicons.FillDirection = Enum.FillDirection.Horizontal
							hicons.HorizontalAlignment = Enum.HorizontalAlignment.Center
							hicons.VerticalAlignment = Enum.VerticalAlignment.Center
							hicons.Padding = UDim.new(0, 4)
							hicons.Parent = iconsRow

							local counts = {}
							for i = 1, #cl.items do
								local img = cl.items[i].image
								counts[img] = (counts[img] or 0) + 1
							end

							local order = {}
							for img in counts do
								table.insert(order, img)
							end

							table.sort(order, function(a, b)
								return counts[a] > counts[b]
							end)

							for i = 1, #order do
								local img = order[i]

								local holder = Instance.new("Frame")
								holder.Size = UDim2.fromOffset(36, 36)
								holder.BackgroundTransparency = 1
								holder.Parent = iconsRow

								local icon = Instance.new("ImageLabel")
								icon.Size = UDim2.fromScale(1, 1)
								icon.BackgroundTransparency = 1
								icon.Image = img
								icon.Parent = holder

								local c = counts[img]
								if c > 1 then
									local badge = Instance.new("TextLabel")
									badge.AnchorPoint = Vector2.new(1, 0)
									badge.Position = UDim2.new(1, 0, 0, 0)
									badge.Size = UDim2.fromOffset(18, 14)
									badge.BackgroundTransparency = 0.2
									badge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
									badge.TextColor3 = Color3.new(1, 1, 1)
									badge.TextSize = 14
									badge.FontFace = Library.Font
									badge.Text = tostring(c)
									outline(badge)
									badge.Parent = holder

									Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
								end
							end

							vlist:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
								root.Size = UDim2.fromOffset(200, vlist.AbsoluteContentSize.Y)
							end)

							cl.ui = root
							cl.distLabel = distLabel
							cl.timeLabel = timeLabel
						end

						RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
							local camCF = Camera.CFrame
							local camPos = camCF.Position
							local now = tick()

							local n = #clusters
							for i = 1, n do
								if not flags.ESPRaids then
									if ui then
										ui.Visible = false
									end
									continue
								end
								local cl = clusters[i]
								local ui = cl.ui
								if ui then
									local v3, on = Camera:WorldToViewportPoint(cl.center)
									on = on and (v3.Z > 0)

									if ui.Visible ~= on then
										ui.Visible = on
									end

									if on then
										local d = (cl.center - camPos).Magnitude
										local s = math.clamp(64 + d * 0.02, 48, 128)

										if cl._lastSize ~= s then
											cl._lastSize = s
											ui.Size = UDim2.fromOffset(s, s)
										end

										local x, y = v3.X, v3.Y
										if cl._lastX ~= x or cl._lastY ~= y then
											cl._lastX, cl._lastY = x, y
											ui.Position = UDim2.fromOffset(x, y)
										end

										local dist_label = cl.distLabel
										if dist_label then
											dist_label.Text = string.format("%d studs", math.floor(d + 0.5))
										end

										local time_label = cl.timeLabel
										if time_label then
											local t = cl.lastBoomAt
											if t then
												local ago = now - t
												if ago < 0 then
													ago = 0
												end
												time_label.Text = string.format("last %.1fs", ago)
											else
												time_label.Text = "last ?"
											end
										end
									end
								end
							end
						end))

						local gcIndex = 1
						RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
							local now = tick()
							local n = #clusters
							if n == 0 then
								return
							end

							local checks = math.min(n, 32)
							for _ = 1, checks do
								if n == 0 then
									break
								end

								if gcIndex > n then
									gcIndex = 1
								end

								local cl = clusters[gcIndex]
								if now - cl.lastUpdate >= 600 then
									destroyUI(cl)
									table.remove(clusters, gcIndex)
									n -= 1
								else
									gcIndex += 1
								end
							end
						end))

						local boom = {
							["C4"] = { image = "rbxassetid://13169199238", name = "Timed Explosive Charge" },
							["DynamiteBundle"] = { image = "rbxassetid://15127431071", name = "Dynamite Bundle" },
							["DynamiteStick"] = { image = "rbxassetid://15127430886", name = "Dynamite Stick" },
							["Rocket"] = { image = "rbxassetid://15132772763", name = "Rocket" },
						}

						RaidEvent.Event:Connect(LPH_NO_VIRTUALIZE(function(Type, cf)
							local pos = (typeof(cf) == "CFrame") and cf.Position or cf
							local info = boom[Type]
							if not info then
								return
							end

							if flags.ESPRaids then
								local now = tick()
								local best, bestDist = nil, 400

								for _, cl in clusters do
									local dist = (pos - cl.center).Magnitude
									if dist < bestDist then
										best, bestDist = cl, dist
									end
								end

								if best then
									table.insert(best.items, { pos = pos, image = info.image })
									best.sum += pos
									best.n += 1
									best.center = best.sum / best.n
									best.lastUpdate = now
									best.lastBoomAt = now
									buildUI(best)
								else
									local cl = {
										items = { { pos = pos, image = info.image } },
										sum = pos,
										n = 1,
										center = pos,
										lastUpdate = now,
										lastBoomAt = now,
										ui = nil,
									}
									table.insert(clusters, cl)
									buildUI(cl)
								end
							end

							if flags.RaidNotifications then
								local p = pos
								local coords = math.floor(p.X) .. ", " .. math.floor(p.Y) .. ", " .. math.floor(p.Z)
								Library:Notification("A " .. info.name .. " has been used at " .. coords, 10)
							end
						end))
					end
				end

				local Assets = {
					Textures = {
						Web = "rbxassetid://301464986",
						Swirl = "rbxassetid://8133639623",
						Checkers = "rbxassetid://5790215150",
						CandyCane = "rbxassetid://6853532738",
						Dots = "rbxassetid://5830615971",
						Scanning = "rbxassetid://5843010904",
						Bubbles = "rbxassetid://1461576423",
						["Player FF Texture"] = "rbxassetid://4494641460",
						["Shield Forcefield"] = "rbxassetid://361073795",
						Water = "rbxasset://textures/water/normal_21.dds",
						America = "rbxassetid://936775406",
						Rainbow = "rbxassetid://252684207",
						Akatsuki = "rbxassetid://10913193650",
						None = "",
					},
					Shaders = {
						Galaxy = "rbxassetid://102123368175852",
						Universe = "rbxassetid://118495641668346",
						Grooves = "rbxassetid://125656202528237",
						Liquid = "rbxassetid://125656202528237",
						Galaxy2 = "rbxassetid://125656202528237",
						Tunnel = "rbxassetid://71437209144052",
						Osamason = "rbxassetid://129433290925875",
					},
					ShaderAnimatedTextures = {},
				}

				local function makeArmCham(part, color3, transparency, material, texture, reflectance)
					if part:FindFirstChild("__ARM_CLONE") then
						return
					end

					local clone = part:Clone()
					clone.Name = "__ARM_CLONE"
					clone.Anchored = false
					clone.CanCollide = false
					clone.CanTouch = false
					clone.CanQuery = false
					clone.Massless = true
					clone.Color = color3 or part.Color
					clone.Transparency = transparency or 0
					clone.Material = Enum.Material[material] or Enum.Material.SmoothPlastic
					clone.Reflectance = reflectance or 0

					if clone:IsA("MeshPart") and material == "ForceField" then
						clone.TextureID = texture or ""
					end

					clone.Parent = part

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = clone
					weld.Part1 = part
					weld.Parent = clone

					part.LocalTransparencyModifier = 1
				end

				task.spawn(function()
					local frameRate = 1 / 30
					local scrollFactor = 0.03
					while true do
						task.wait(frameRate)
						for _, d in ipairs(Assets.ShaderAnimatedTextures) do
							local t = d.texture
							local s = d.scrollSpeed
							if t and t.Parent then
								t.OffsetStudsU += s * scrollFactor
								t.OffsetStudsV += s * scrollFactor
							end
						end
					end
				end)

				if VMs then
					VMs.ChildAdded:Connect(function(VM)
						if VM.Name == "IgnoreMe" then
							return
						end

						task.spawn(function()
							task.wait(0.2)

							if VM:FindFirstChild("Humanoid") then
								VM.Humanoid.AnimationPlayed:Connect(function(track)
									if not flags.ReloadBarEnabled then
										return
									end
									if track.Animation and track.Animation.Name:lower():find("reload") then
										local duration = 2
										local weaponName = VM.Name
										if ToolInfo[weaponName] and ToolInfo[weaponName].Weapon then
											duration = ToolInfo[weaponName].Weapon.ReloadDuration or 2
										end
										ReloadBar:Start(duration)
									end
								end)
							end

							local Viewmodel = Workspace.VFX.VMs:FindFirstChildOfClass("Model")
							if not Viewmodel then
								return
							end

							local Arms = Viewmodel:WaitForChild("Arms", 9e9)
							local Weapon = Viewmodel:WaitForChild("Weapon", 9e9)

							for _, Part in ipairs(Viewmodel:GetDescendants()) do
								if not (Part:IsA("Part") or Part:IsA("MeshPart")) then
									continue
								end

								for _, c in ipairs(Part:GetChildren()) do
									if c:IsA("SurfaceAppearance") then
										c:Destroy()
									end
								end

								if Part:IsDescendantOf(Weapon) and flags.SkinModelEnabled and Part:IsA("MeshPart") then
									for _, c in ipairs(Part:GetChildren()) do
										if c:IsA("Texture") and c.Name == "WeaponShaderTexture" then
											c:Destroy()
										end
									end

									local faces = {
										Enum.NormalId.Front,
										Enum.NormalId.Back,
										Enum.NormalId.Left,
										Enum.NormalId.Right,
										Enum.NormalId.Top,
										Enum.NormalId.Bottom,
									}

									for _, face in ipairs(faces) do
										local tex = Instance.new("Texture")
										tex.Name = "WeaponShaderTexture"
										tex.Face = face
										tex.Texture = Assets.Shaders[flags.SkinModelList]
										tex.Parent = Part

										if flags.SkinModelScrollSpeed ~= 0 then
											table.insert(Assets.ShaderAnimatedTextures, {
												texture = tex,
												scrollSpeed = flags.SkinModelScrollSpeed,
											})
										end
									end
								end

								if
									flags.SkinModelGunEnable
									and not flags.SkinModelEnabled
									and Part:IsDescendantOf(Weapon)
								then
									local col = flags.SkinModelGunColor
									local mat = flags.SkinModelGunMaterial

									if col then
										Part.Color = col.Color
										Part.Transparency = col.Transparency or 0
									end

									if Part:IsA("MeshPart") then
										Part.TextureID = ""
									end

									for _, c in ipairs(Part:GetChildren()) do
										if c:IsA("Texture") or c:IsA("Decal") then
											c:Destroy()
										end
									end

									if mat == "Neon" or mat == "ForceField" or mat == "SmoothPlastic" then
										Part.Material = Enum.Material[mat]
									end

									Part.Reflectance = flags.SkinModelGunReflectance or 0

									if Part:IsA("MeshPart") and mat == "ForceField" then
										Part.TextureID = Assets.Textures[flags.SkinModelGunTexture] or ""
									end
								end

								if Part:IsDescendantOf(Arms) then
									local existing = Part:FindFirstChild("__ARM_CLONE")

									if flags.SkinModelPropEnable then
										local col = flags.SkinModelsPropColor
										local mat = flags.SkinModelPropMaterial

										if not existing then
											makeArmCham(
												Part,
												col and col.Color or nil,
												col and col.Transparency or 0,
												mat,
												Assets.Textures[flags.SkinModelPropTexture],
												flags.SkinModelPropReflectance
											)
										end
									else
										if existing then
											existing:Destroy()
											Part.LocalTransparencyModifier = 0
										end
									end
								end
							end
						end)
					end)
				end
				--// Targeting
				do
					Cheat.Globals.RaycastParams = RaycastParams.new()
					Cheat.Globals.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
					Cheat.Globals.RaycastParams.IgnoreWater = true

					local IsPartVisible = LPH_NO_VIRTUALIZE(function(Part, Origin)
						if not Part then
							return false
						end
						local Head = Cheat.Globals.ClientCharacter
							and Cheat.Globals.ClientCharacter:FindFirstChild("Head")
						if not Head then
							return false
						end
						Origin = Origin or Head.CFrame.Position
						local to = Part.CFrame.Position
						local dir = (to - Origin)
						local RayResult = workspace:Raycast(Origin, dir, Cheat.Globals.RaycastParams)
						if not RayResult then
							return true
						end
						local inst = RayResult.Instance
						return inst and inst:IsDescendantOf(Part.Parent) or false
					end)

					local GetDistanceFromCenter = LPH_JIT_MAX(function(part)
						local position = part
						if typeof(part) == "Instance" then
							position = part.CFrame.Position
						end
						local sp, on = Camera:WorldToViewportPoint(position)
						if not on then
							return math.huge
						end
						local c = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
						return (c - Vector2.new(sp.X, sp.Y)).Magnitude
					end)

					local vectors = {
						Vector3.new(0.5, 0, 0),
						Vector3.new(-0.5, 0, 0),
						Vector3.new(0, 0, 0.5),
						Vector3.new(0, 0, -0.5),
						Vector3.new(0, 0.5, 0),
						Vector3.new(0, -0.5, 0),
						Vector3.new(0.5, 0.5, 0),
						Vector3.new(0.5, -0.5, 0),
						Vector3.new(-0.5, 0.5, 0),
						Vector3.new(-0.5, -0.5, 0),
						Vector3.new(0, 0.5, 0.5),
						Vector3.new(0, -0.5, 0.5),
						Vector3.new(0, 0.5, -0.5),
						Vector3.new(0, -0.5, -0.5),
						Vector3.new(1, 0, 0),
						Vector3.new(-1, 0, 0),
						Vector3.new(0, 0, 1),
						Vector3.new(0, 0, -1),
						Vector3.new(0, 1, 0),
						Vector3.new(0, -1, 0),
					}

					local manipOffsets = {
						Vector3.new(3, 0, 0),
						Vector3.new(-3, 0, 0),
						Vector3.new(6, 0, 0),
						Vector3.new(-6, 0, 0),
						Vector3.new(4, 0, 0),
						Vector3.new(-4, 0, 0),

						Vector3.new(3, 2, 0),
						Vector3.new(-3, 2, 0),
						Vector3.new(6, 2, 0),
						Vector3.new(-6, 2, 0),
						Vector3.new(4, 2, 0),
						Vector3.new(-4, 2, 0),

						Vector3.new(0.2, 3.9, 0),
						Vector3.new(1.8, 4.1, 1),
						Vector3.new(2.1, 4.4, 1.1),
						Vector3.new(0.15, 5.2, 0.1),
						Vector3.new(-1.8, 5.4, -0.2),
						Vector3.new(-2.3, 6.0, -0.4),
						Vector3.new(0.1, 6.0, 0.0),

						Vector3.new(7, 0, 0),
						Vector3.new(-7, 0, 0),
						Vector3.new(7, 2, 0),
						Vector3.new(-7, 2, 0),

						Vector3.new(0.1, 7.5, 0.0),
						Vector3.new(0.1, 8.0, 0.0),

						Vector3.new( 0,-3, 0),
						Vector3.new( 3,-3, 0), Vector3.new(-3,-3, 0),
						Vector3.new( 6,-4, 0), Vector3.new(-6,-4, 0),
						Vector3.new( 0,-4, 0),
						Vector3.new( 3,-4, 2), Vector3.new(-3,-4,-2),
					}

					local is_cframe_visible = LPH_NO_VIRTUALIZE(function(cfrom, cto)
						if not (cfrom and cto) then
							return false
						end
						local hit = workspace:Raycast(
							cfrom.Position,
							cto.Position - cfrom.Position,
							Cheat.Globals.RaycastParams
						)
						return not hit
					end)

					local is_part_visible = LPH_NO_VIRTUALIZE(function(originCF, target_part)
						if not (originCF and target_part) then
							return false
						end

						if typeof(originCF) == "Vector3" then
							originCF = CFrame.new(originCF)
						elseif typeof(originCF) ~= "CFrame" then
							return false
						end

						local originPos = originCF.Position
						local targetPos = target_part:GetPivot().Position
						local direction = targetPos - originPos

						local hit = workspace:Raycast(originPos, direction, Cheat.Globals.RaycastParams)
						if not hit then
							return true
						end
						return hit.Instance and hit.Instance.Parent == target_part.Parent or false
					end)

					local get_hit_scan_pos = LPH_NO_VIRTUALIZE(function(origin_cframe, target_part)
						for _, vector in vectors do
							local modified = target_part.CFrame * CFrame.new(vector * 4)

							if
								is_part_visible(modified, target_part) and is_cframe_visible(origin_cframe, modified)
							then
								return modified.Position
							end
						end

						return
					end)

					local FindVisiblePosition = LPH_NO_VIRTUALIZE(function(Origin, Destination)
						local o = (typeof(Origin) == "CFrame") and Origin or CFrame.new(Origin)
						local doHitScan = flags.HitScan

						for i = 1, #manipOffsets do
							local pos = o * manipOffsets[i]
							if IsPartVisible(Destination, pos) then
								return pos
							elseif doHitScan then
								local hs = get_hit_scan_pos(CFrame.new(pos), Destination)
								if hs then
									return pos, hs
								end
							end
						end
						return nil
					end)
					local LastVisiblePart = {}
					local _lastTargetTick = 0
					RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
						local _now = tick()
						if _now - _lastTargetTick < 1/45 then return end
						_lastTargetTick = _now
						debug.profilebegin("Targeting Loop")
						for name, player in pairs(Players:GetPlayers()) do
							if not Targeting.Targets[player] and player ~= Client then
								Targeting.Targets[player] = {
									Class = "Player",
									Player = player,
									Character = player.Character,
									CoreInformation = { Visible = false, OnScreen = false, Root = nil },
									LastUpdate = 0,
									Humanoid = nil,
									Root = nil,
								}
							end
						end
						Cheat.Globals.RaycastParams.FilterDescendantsInstances = {
							Camera,
							Cheat.Globals.ClientCharacter,
							workspace:FindFirstChild("VFX"),
							workspace:FindFirstChild("RocketFactoryPinkCardInvisWalls"),
						}

						local Silent = flags.AimbotEnabled or false
						local TargetParts = flags.TargetParts or { "Head" }
						if not TargetParts or #TargetParts == 0 then
							return
						end

						local DesiredPartName = TargetParts[math.random(#TargetParts)] or "Head"
						local ManipulationActive = Silent and (flags.Manipulation == true) or false
						local HitScanActive = (flags.HitScan == true) or false
						local UseVisibleCheck = flags.VisibleCheck == true
						local DownCheck = flags.DownCheck == true
						local ClosestDistance = (flags.FovSize or 0)

						local ClosestTarget = nil
						local EntityCharacter = nil
						local EntityData = nil
						local EntityInstance = nil
						local Manipulated = false
						local Visible = false
						local HitScanned, ScannedPosition, ScannedPart = nil, nil
						local ManipulatedPart, ManipulatedPosition, ManipulatedPlayer = nil, nil, nil

						local now = tick()

						for Entity, Object in pairs(Targeting.Targets) do
							if not Object then
								continue
							end
							if not Object.Character or not Object.Character.Parent then
								Object.Character = (Object.Class == "Player" and Object.Player.Character) or nil
							end

							local character = Object.Character
							if not character or not character.Parent then
								Object.CoreInformation = { Visible = false, OnScreen = false, Root = nil }
								continue
							end

							if now - (Object.LastUpdate or 0) > 1 / 30 then
								Object.LastUpdate = now
								local Humanoid = character:FindFirstChildOfClass("Humanoid")
								if Humanoid then
									Object.Humanoid = Humanoid
								end
								if Object.Class == "Player" or Object.Class == "AI" then
									Object.Root = (Humanoid and Humanoid.RootPart)
										or character:FindFirstChild("HumanoidRootPart")
								end
								if not Object.Root then
									Object.Root = character:FindFirstChild("RootPart")
										or character:FindFirstChild("HumanoidRootPart")
								end

								local root = Object.Root
								if not root then
									Object.CoreInformation = { Visible = false, OnScreen = false, Root = nil }
								elseif (Camera.CFrame.Position - root.Position).Magnitude > 2000 then
									Object.CoreInformation = { Visible = false, OnScreen = false, Root = root }
								else
									local parts = character:GetChildren()
									local inf = math.huge
									local minx, miny, minz = inf, inf, inf
									local maxx, maxy, maxz = -inf, -inf, -inf
									local rc = root.CFrame
									for _, Part in ipairs(parts) do
										if Part:IsA("BasePart") then
											local Cf = rc:ToObjectSpace(Part.CFrame)
											local sx, sy, sz = Part.Size.X, Part.Size.Y, Part.Size.Z
											local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Cf:components()
											local wsx = 0.5
												* (math.abs(R00) * sx + math.abs(R01) * sy + math.abs(R02) * sz)
											local wsy = 0.5
												* (math.abs(R10) * sx + math.abs(R11) * sy + math.abs(R12) * sz)
											local wsz = 0.5
												* (math.abs(R20) * sx + math.abs(R21) * sy + math.abs(R22) * sz)
											minx = math.min(minx, X - wsx)
											miny = math.min(miny, Y - wsy)
											minz = math.min(minz, Z - wsz)
											maxx = math.max(maxx, X + wsx)
											maxy = math.max(maxy, Y + wsy)
											maxz = math.max(maxz, Z + wsz)
										end
									end
									local minv = Vector3.new(minx, miny, minz)
									local maxv = Vector3.new(maxx, maxy, maxz)
									local middle = (maxv + minv) * 0.5
									local cf = rc - rc.Position + rc * middle
									local half = (maxv - minv) * 0.5
									local hx, hy, hz = math.min(half.X, 5), math.min(half.Y, 10), math.min(half.Z, 5)
									local offsets = {
										Vector3.new(hx, hy, hz),
										Vector3.new(hx, hy, -hz),
										Vector3.new(hx, -hy, hz),
										Vector3.new(hx, -hy, -hz),
										Vector3.new(-hx, hy, hz),
										Vector3.new(-hx, hy, -hz),
										Vector3.new(-hx, -hy, hz),
										Vector3.new(-hx, -hy, -hz),
									}
									local on = false
									for i = 1, 8 do
										local _, s = Camera:WorldToViewportPoint(cf * offsets[i])
										if s then
											on = true
											break
										end
									end

									if not on then
										local head = character:FindFirstChild("Head")
										local vis = head and IsPartVisible(head) or false


									else
										local part = character:FindFirstChild(DesiredPartName)

										if part then
											local vis = IsPartVisible(part)
											local now = tick()

											local cache = character and LastVisiblePart[character]

											if vis then
												LastVisiblePart[character] = {
													Part = part,
													Time = now,
												}

												Object.CoreInformation = {
													Visible = true,
													VisiblePart = part,
													Root = root,
													RootPosition = root.Position,
													OnScreen = on,
												}
											elseif cache and (now - cache.Time < VisibleHoldTime) then
												Object.CoreInformation = {
													Visible = true,
													VisiblePart = cache.Part,
													Root = root,
													RootPosition = root.Position,
													OnScreen = on,
												}
											else
												Object.CoreInformation = {
													Visible = false,
													VisiblePart = nil,
													Root = root,
													RootPosition = root.Position,
													OnScreen = on,
												}
											end
										end
									end

									Object.CoreInformation = {
										Visible = false,
										VisiblePart = nil,
										Root = root,
										RootPosition = root.Position,
										OnScreen = on,
									}
									local visPart = nil
									local names = {
										"HumanoidRootPart",
										"RightLowerLeg",
										"LeftLowerLeg",
										"RightUpperArm",
										"LeftUpperArm",
									}
									for _, n in ipairs(names) do
										local p = character:FindFirstChild(n)
										if p and p:IsA("BasePart") then
											local vis = IsPartVisible(p)
											local now = tick()

											if vis then
												if character then
													LastVisiblePart[character] = { Part = p, Time = now }
												end
												visPart = p
												break
											end
											local cache = LastVisiblePart and LastVisiblePart[character]

											if
												cache
												and cache.Part
												and cache.Time
												and (now - cache.Time < VisibleHoldTime)
											then
												visPart = cache.Part
												break
											end
										end
									end
									Object.CoreInformation = {
										Visible = visPart ~= nil,
										VisiblePart = visPart,
										Root = root,
										RootPosition = root.Position,
										OnScreen = on,
									}
								end
							end

							local Core = Object.CoreInformation
							if not flags.TargetTeammates and isTeam(Entity) then
								continue
							end
							if not (Core and Core.Root and Entity ~= Client) then
								continue
							end
							if not (Core.OnScreen and not Object.Teammate and flags.AimbotEnabled) then
								continue
							end

							local humanoid = character:FindFirstChildOfClass("Humanoid")
							if not humanoid or humanoid.Health <= 0 then
								continue
							end
							if DownCheck and humanoid:GetAttribute("Downed") then
								continue
							end

							local Distance = GetDistanceFromCenter(Core.Root)
							if Distance >= ClosestDistance then
								continue
							end

							local tpart = nil
							if UseVisibleCheck and Core.Visible then
								tpart = Core.VisiblePart
							elseif not UseVisibleCheck then
								tpart = character:FindFirstChild(DesiredPartName)
							end

							if Cheat.Globals.DesyncedPositions[character] and Cheat.Globals.DesyncParts[character] then
								tpart = Cheat.Globals.DesyncParts[character]
							end

							if character.Name == "BTR" then
								tpart = character:FindFirstChild("HumanoidRootPart")
							end

							if tpart then
								ClosestDistance = Distance
								ClosestTarget = tpart
								EntityCharacter = character
								EntityData = Object
								EntityInstance = Entity
								Visible = Core.Visible
							end
						end

						if
							not Visible
							and Cheat.Globals.ClientCharacter
							and Cheat.Globals.ClientCharacter:FindFirstChild("Head")
							and ClosestTarget
							and EntityData
						then
							if now - (EntityData.LastManip or 0) > 0 then
								EntityData.LastManip = now
								local HeadCFrame = Cheat.Globals.ClientCharacter.Head.CFrame

								if HitScanActive then
									local VisiblePos3 = get_hit_scan_pos(HeadCFrame, ClosestTarget)
									if VisiblePos3 then
										HitScanned = true
										ScannedPart = ClosestTarget
										ScannedPosition = VisiblePos3
										ManipulatedPlayer = EntityData.Pointer
									end
								end

								if ManipulationActive and not HitScanned then
									local vp, HitScanPos = FindVisiblePosition(HeadCFrame, ClosestTarget)
									if vp then
										Manipulated = true
										ManipulatedPart = ClosestTarget
										ManipulatedPosition = vp
										ManipulatedPlayer = EntityData.Pointer
										if HitScanPos then
											HitScanned = true
											ScannedPart = ClosestTarget
											ScannedPosition = HitScanPos
										end
									end
								end

								EntityData.LastManipCFG = {
									Manipulated = Manipulated,
									ManipulatedPosition = ManipulatedPosition,
									ManipulatedPart = ManipulatedPart,
									ManipulatedPlayer = ManipulatedPlayer,
								}
							elseif EntityData.LastManipCFG then
								Manipulated = EntityData.LastManipCFG.Manipulated
								ManipulatedPosition = EntityData.LastManipCFG.ManipulatedPosition
								ManipulatedPart = EntityData.LastManipCFG.ManipulatedPart
								ManipulatedPlayer = EntityData.LastManipCFG.ManipulatedPlayer
							end
						end

						Targeting.TargetPart = ClosestTarget
						Targeting.TargetCharacter = EntityCharacter
						Targeting.TargetObject = EntityData
						Targeting.ScannedPosition = ScannedPosition
						Targeting.ManipulatedPosition = Manipulated and ManipulatedPosition or nil
						debug.profileend()
					end))

					local TrialModList = {
						[4619800148] = "Trial Moderator", --//gobliniukss
						[113179883] = "Trial Moderator", --// DopeIlI
						[1771300283] = "Trial Moderator", --// severalracks
						[1077540175] = "Trial Moderator", --// i3riefcase
						[3320377356] = "Trial Moderator", --// Kriffith
						[3508020028] = "Trial Moderator", ---.. SOLDIER
						[3122439095] = "Trial Moderator", --// CHANCE L	FAO
						[3034556584] = "Trial Moderator", -- Adam
						[886544546] = "Trial Moderator",
						[1616925260] = "Trial Moderator",
						[165053216] = "Trial Moderator",
						[1992294235] = "Trial Moderator",
						[971641336] = "Trial Moderator",
						[1937065322] = "Trial Moderator", -- gxentry
					}

					local FlaggedRoles = {
						"OG",
						"Game Tester",
						"Game Moderator",
						"Developers",
						"Lead Developer",
						"Co-Founder",
						"Founder",
						"Trial Moderator",
					}

					local function CheckMod(Player)
						local Role = TrialModList[Player.UserId] or Player:GetRoleInGroup(1154360)

						if table.find(FlaggedRoles, Role) then
							Library:Notification("Staff detected! [" .. Player.Name .. "] Role: " .. Role, 30)
							Library:AddMod({
								Title = Player.Name,
							})
							return
						end
					end

					for _, Player in ipairs(Players:GetPlayers()) do
						if Player ~= Client then
							Targeting.Targets[Player] = {
								Class = "Player",
								Player = Player,
								Character = Player.Character,
								LastUpdate = 0,
								Root = nil,
								CoreInformation = { Visible = false, OnScreen = false, Root = nil },
							}
							pcall(CheckMod, Player)
						end
					end

					Players.PlayerAdded:Connect(function(Player)
						if Player ~= Client then
							Targeting.Targets[Player] = {
								Class = "Player",
								Player = Player,
								Character = Player.Character,
								LastUpdate = 0,
								Root = nil,
								CoreInformation = { Visible = false, OnScreen = false, Root = nil },
							}
							pcall(CheckMod, Player)
						end
					end)

					Players.PlayerRemoving:Connect(function(Player)
						Targeting.Targets[Player] = nil
						if Player.Character then
							LastVisiblePart[Player.Character] = nil
						end
					end)

					local SoldierClassType = {
						Brutus = "Boss",
						Bruno = "Boss",
						BTR = "Boss",
						Boris = "Boss",
						Soldier = "AI",
					}

					local Military = workspace:FindFirstChild("Military")
					if Military then
						local Events = workspace:FindFirstChild("Events")
						local CacheSoldier = function(Soldier)
							local ClassType = SoldierClassType[Soldier.Name]
							if not ClassType then
								return
							end

							Targeting.Targets[Soldier] = {
								Class = ClassType,
								Player = Soldier,
								Character = Soldier,
								LastUpdate = 0,
								Root = nil,
								CoreInformation = { Visible = false, OnScreen = false, Root = nil },
							}
						end

						for Index, BTR in Events:GetChildren() do
							if BTR.Name == "BTR" then
								CacheSoldier(BTR)
							end
						end

						Events.ChildAdded:Connect(function(BTR)
							task.wait(1)
							if BTR.Name == "BTR" then
								CacheSoldier(BTR)
							end
						end)

						for _, Folder in Military:GetChildren() do
							for Index, Soldier in Folder:GetChildren() do
								if Soldier:IsA("Model") then
									CacheSoldier(Soldier)
								end
							end

							Folder.ChildAdded:Connect(function(Soldier)
								task.wait(1)
								if Soldier:IsA("Model") then
									CacheSoldier(Soldier)
								end
							end)
						end
					end
				end

				do
					local RunService = game:GetService("RunService")
					local Players = game:GetService("Players")

					repeat task.wait() until getgenv().Library

					local Cfg, Items

					LPH_NO_VIRTUALIZE(function()
						for _, v in pairs(getgc(true)) do
							if type(v) == "table" and rawget(v, "UpdateStats") and rawget(v, "SetTargetStatsVisibility") then
								Cfg = v
							end

							if type(v) == "table" and rawget(v, "TargetStats") and rawget(v, "Username") then
								Items = v
							end
						end
					end)()

					if not Cfg or not Items then
						warn("TargetStats system not found")
						return
					end

					local lastPlayer = nil

					local getTarget = LPH_NO_VIRTUALIZE(function()
						if Targeting and Targeting.TargetPart then
							local m = Targeting.TargetPart
							while m and not m:FindFirstChildOfClass("Humanoid") do
								m = m.Parent
							end
							return m
						end
						return nil
					end)

					local lastPlayer = nil
					local lastHUDTick = 0

					RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
						if not flags.TargetHUD then
							Cfg.SetTargetStatsVisibility(false)
							lastPlayer = nil
							return
						end

						local now = tick()
						if now - lastHUDTick < 0.05 then return end
						lastHUDTick = now

						local char = getTarget()
						if not char then
							Cfg.SetTargetStatsVisibility(false)
							lastPlayer = nil
							return
						end

						local humanoid = char:FindFirstChildOfClass("Humanoid")
						if not humanoid then
							Cfg.SetTargetStatsVisibility(false)
							return
						end

						local player = Players:GetPlayerFromCharacter(char)
						if not player then
							Cfg.SetTargetStatsVisibility(false)
							return
						end

						Cfg.SetTargetStatsVisibility(true)

						if player ~= lastPlayer then
							lastPlayer = player
							Cfg:UpdateStatsProfile(player)
						end

						local root = char:FindFirstChild("HumanoidRootPart")
						local myRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

						local dist = 0
						if root and myRoot then
							dist = math.floor((root.Position - myRoot.Position).Magnitude)
						end

						Cfg:UpdateStats({
							Health = tostring(math.floor(humanoid.Health)),
							MaxHealth = humanoid.MaxHealth,
							Distance = tostring(dist)
						})
					end))
				end
				do
					local RunService = game:GetService("RunService")

					repeat task.wait() until getgenv().Library and Library.HUD
					repeat task.wait() until Library.HUD.Instance

					local Items
					for _, v in pairs(getgc(true)) do
						if type(v) == "table" and rawget(v, "ImageHolder") and rawget(v, "InventoryViewer") then
							Items = v
							break
						end
					end

					if not Items then
						warn("Items not found")
						return
					end


					local EnsureLayout = LPH_NO_VIRTUALIZE(function()
						if not Items.ImageHolder.Instance:FindFirstChildOfClass("UIGridLayout") then
							Library:Create("UIGridLayout", {
								Parent = Items.ImageHolder.Instance,
								SortOrder = Enum.SortOrder.LayoutOrder,
								CellSize = UDim2.new(0, 75, 0, 75),
							})
						end

						if not Items.ImageHolder.Instance:FindFirstChildOfClass("UISizeConstraint") then
							Library:Create("UISizeConstraint", {
								Parent = Items.ImageHolder.Instance,
								MaxSize = Vector2.new(350, math.huge)
							})
						end
					end)

					local last_target = nil
					local last_hash = ""
					local visible = false

					local clear = LPH_NO_VIRTUALIZE(function()
						if visible then
							visible = false

							for _, v in ipairs(Items.ImageHolder.Instance:GetChildren()) do
								if v:IsA("Frame") then
									v:Destroy()
								end
							end

							Items.InventoryViewer:Tween({ GroupTransparency = 1 })
						end

						last_target = nil
						last_hash = ""
					end)

					local update = LPH_NO_VIRTUALIZE(function(data)
						EnsureLayout()

						Items.InventoryViewer:Tween({ GroupTransparency = 0 })

						Items.InvViewerInfo.Instance.Text =
							string.format("Armor Viewer - %s Items", #data.Images)

						Items.Description.Instance.Text =
							string.format("User: %s (%s)", data.Name, data.DisplayName)

						for _, v in ipairs(Items.ImageHolder.Instance:GetChildren()) do
							if v:IsA("Frame") then
								v:Destroy()
							end
						end

						for _, img in ipairs(data.Images) do
							local frame = Library:Create("Frame", {
								Parent = Items.ImageHolder.Instance,
								Size = UDim2.new(0, 100, 0, 100),
								BorderSizePixel = 0,
								BackgroundColor3 = Library.Themes.Preset["LowContrast"],
							}):Themify("LowContrast", "BackgroundColor3")

							Library:Create("UIStroke", {
								Parent = frame.Instance,
								Color = Library.Themes.Preset["Outline"],
								BorderOffset = UDim.new(0, -1),
							}):Themify("Outline", "Color")

							Library:Create("UIStroke", {
								Parent = frame.Instance,
								Color = Library.Themes.Preset["Inline"],
								BorderOffset = UDim.new(0, -2),
							}):Themify("Inline", "Color")

							Library:Create("ImageLabel", {
								Parent = frame.Instance,
								Size = UDim2.new(1, 0, 1, 0),
								BackgroundTransparency = 1,
								Image = img,
								ScaleType = Enum.ScaleType.Crop
							})

							Library:Create("UIPadding", {
								Parent = frame.Instance,
								PaddingTop = UDim.new(0, 10),
								PaddingBottom = UDim.new(0, 10),
								PaddingLeft = UDim.new(0, 10),
								PaddingRight = UDim.new(0, 10),
							})
						end
					end)

					local lastArmorTick = 0
					RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
						if not flags.ArmorBar then
							clear()
							return
						end

						local now = tick()
						if now - lastArmorTick < 0.1 then return end
						lastArmorTick = now

						local targetChar
						if Targeting and Targeting.TargetPart then
							local m = Targeting.TargetPart.Parent
							while m and not m:FindFirstChildOfClass("Humanoid") do
								m = m.Parent
							end
							targetChar = m
						end

						if not targetChar then
							clear()
							return
						end

						local icons = {}
						local usedSlots = {}

						for _, child in ipairs(targetChar:GetChildren()) do
							local num, skin = child.Name:match("Armor_(%d+)/(.*)")
							if num then
								num = tonumber(num)

								if not usedSlots[num] then
									usedSlots[num] = true

									local item = ItemsModule and ItemsModule[num]

									if item and item.Type == "Armor" then
										local image = ""

										if type(item.Image) == "table" then
											image = (skin and item.Image[skin]) or item.Image.Default
										else
											image = item.Image
										end

										local id = tostring(image):match("%d+")
										if id then
											table.insert(icons, "rbxassetid://" .. id)
										end
									end
								end
							end
						end

						local hash = table.concat(icons, "|")

						if targetChar ~= last_target or hash ~= last_hash then
							last_target = targetChar
							last_hash = hash
							visible = true

							update({
								Name = targetChar.Name,
								DisplayName = targetChar.Name,
								Images = icons
							})
						end
					end))
				end

				--// Misc
				do
					setreadonly(math, false)
					local oldabs = math.abs
					math.abs = function(x)
						if flags.NoBob and debug.traceback():find("ViewmodelController") then
							for level = 2, 4 do
								if isvalidlevel(level) then
									local stack = getstack(level)
									local v = stack and stack[2]
									if type(v) == "boolean" then
										setstack(level, 2, true)
									end
								end
							end
						end

						return oldabs(x)
					end
					setreadonly(math, true)

					do --// Movement
						RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(dt)
							local Character = Cheat.Globals.ClientCharacter
							local Root = Character and Character:FindFirstChild("HumanoidRootPart")
							local Humanoid = Character and Character:FindFirstChild("Humanoid")
							local IsFlying
							do
								if flags.AutoPeek and flags.AutoPeekBind and flags.AutoPeekBind.Active and Targeting and Targeting.TargetPart then
									local now = tick()

									Cheat.Globals.AutoPeekData = Cheat.Globals.AutoPeekData or {
										Last = 0
									}

									local data = Cheat.Globals.AutoPeekData

									local visible =
										(Targeting.TargetObject and Targeting.TargetObject.CoreInformation and Targeting.TargetObject.CoreInformation.Visible)
										or Targeting.Visible

									local shouldPeek =
										visible
										or Targeting.ManipulatedPosition
										or Targeting.ScannedPosition

									if shouldPeek and (now - data.Last > flags.AutoPeekDelay) then
										data.Last = now

										local basePos = Root.Position
										local look = Root.CFrame.LookVector
										local rightVec = Root.CFrame.RightVector
										local upVec = Vector3.new(0, 1, 0)

										local targetPart = Targeting.TargetPart
										local distance = flags.AutoPeekDistance or 8
										local attempts = math.clamp(tonumber(flags.AutoPeekAttempts) or 3, 1, 8)

										Cheat.Globals.LastPeekPos = Cheat.Globals.LastPeekPos or basePos

										local toTarget = (targetPart.Position - basePos).Unit


										local rightDot = rightVec:Dot(toTarget)
										local upDot = upVec:Dot(toTarget)

										local offset

										if math.abs(upDot) > math.abs(rightDot) then
											local verticalSide = (upDot > 0) and 1 or -1
											offset = upVec * distance * verticalSide
										else
											local side = (rightDot > 0) and 1 or -1
											offset = rightVec * distance * side
										end

										local targetPos = basePos + offset

										for i = 1, attempts do
											if (targetPos - Cheat.Globals.LastPeekPos).Magnitude <= 25 then
												Root.CFrame = CFrame.new(targetPos, targetPos + look)

												local moved = (Root.Position - basePos).Magnitude

												if moved > 1 then
													Cheat.Globals.LastPeekPos = targetPos
													break
												end
											end
										end
									end
								else
									Cheat.Globals.LastPeekPos = nil
								end
							end
							if Humanoid and Root and Humanoid.Health > 0 then
								if flags.SpeedEnabled and flags["SpeedBind"].Active and not IsFlying and Root then
									local x, z = 0, 0
									if UserInputService:IsKeyDown(Enum.KeyCode.D) then
										x += 1
									end
									if UserInputService:IsKeyDown(Enum.KeyCode.A) then
										x -= 1
									end
									if UserInputService:IsKeyDown(Enum.KeyCode.W) then
										z += 1
									end
									if UserInputService:IsKeyDown(Enum.KeyCode.S) then
										z -= 1
									end

									if x ~= 0 or z ~= 0 then
										local cf = Camera.CFrame
										local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
										local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit

										local move = (right * x + forward * z).Unit
										local hv = move * flags.SpeedSpeed
										Root.Velocity = Vector3.new(hv.X, Root.Velocity.Y, hv.Z)
									end
								end

								if
									flags.Bunnyhop
									and Humanoid.FloorMaterial ~= Enum.Material.Air
									and UserInputService:IsKeyDown(Enum.KeyCode.Space)
								then
									Humanoid.Jump = true
								end

								if flags["FlightEnabled"] and flags["FlightBind"].Active then
									task.spawn(function()
										IsFlying = true
										if Humanoid and Humanoid.Health > 0 then
											local Delta = dt * flags.FlightSpeed * 3
											local MoveVector = Vector3.zero

											local look = Camera.CFrame.LookVector
											local right = Camera.CFrame.RightVector

											if UserInputService:IsKeyDown(Enum.KeyCode.W) then
												MoveVector += Vector3.new(look.X, 0, look.Z)
											end
											if UserInputService:IsKeyDown(Enum.KeyCode.S) then
												MoveVector -= Vector3.new(look.X, 0, look.Z)
											end
											if UserInputService:IsKeyDown(Enum.KeyCode.A) then
												MoveVector -= Vector3.new(right.X, 0, right.Z)
											end
											if UserInputService:IsKeyDown(Enum.KeyCode.D) then
												MoveVector += Vector3.new(right.X, 0, right.Z)
											end

											if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
												MoveVector += Vector3.new(0, 1, 0)
											end
											if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
												MoveVector += Vector3.new(0, -1, 0)
											end

											if MoveVector.Magnitude > 0 then
												MoveVector = MoveVector.Unit
											end

											local MovementDelta = MoveVector * Delta
											local Position = Root.CFrame.Position + MovementDelta

											Humanoid.PlatformStand = false
											Root.Velocity = Vector3.zero
											Root.CFrame =
												CFrame.new(Position, Position + Vector3.new(look.X, 0, look.Z))
										end
									end)
								end

								if
									flags.Freecam
									and flags["FreecamKeybind"]
									and flags["FreecamKeybind"].Active
									and not IsFlying
								then
									task.spawn(function()
										if not Root then
											return
										end

										Cheat.Globals.NeedToReturn = true

										local CameraLookVector = Camera.CFrame.LookVector
										local NormalCameraLookVector = CameraLookVector

										if not Cheat.Globals.SavedPosition then
											Cheat.Globals.SavedPosition = Root.CFrame
										end

										sethiddenproperty(Root, "NetworkIsSleeping", true)

										local UpPos = Vector3.new(0, 1, 0)
										local DownPos = Vector3.new(0, -1, 0)
										local NonePos = Vector3.new(0, 0, 0)

										local BaseCFrame = Root.CFrame
										local IsUpPressed = UserInputService:IsKeyDown(Enum.KeyCode.E)
										local IsDownPressed = UserInputService:IsKeyDown(Enum.KeyCode.Q)
										local IsForwardPressed = UserInputService:IsKeyDown(119) -- W
										local IsBackwardPressed = UserInputService:IsKeyDown(115) -- S

										Root.Anchored = true
										Root.Velocity = NonePos

										local Delta = dt * flags.FreecamSpeed * 3

										local MovementVector = (
											Humanoid.MoveDirection
											+ (IsUpPressed and UpPos or NonePos)
											+ (IsDownPressed and DownPos or NonePos)
											+ (IsForwardPressed and Vector3.new(0, NormalCameraLookVector.Y, 0) or NonePos)
											+ (
												IsBackwardPressed and Vector3.new(0, -NormalCameraLookVector.Y, 0)
												or NonePos
											)
										) * Delta

										BaseCFrame += MovementVector
										local Position = BaseCFrame.p
										Root.CFrame = CFrame.new(
											Position,
											Position + Vector3.new(CameraLookVector.X, 0, CameraLookVector.Z)
										)
										Humanoid.AutoRotate = false
									end)
								else
									if Cheat.Globals.NeedToReturn then
										Humanoid.AutoRotate = true
										Cheat.Globals.NeedToReturn = false
										sethiddenproperty(Root, "NetworkIsSleeping", false)

										for _, Value in Character:GetChildren() do
											if Value:IsA("BasePart") then
												sethiddenproperty(Value, "NetworkIsSleeping", false)
											end
										end

										Root.CFrame = Cheat.Globals.SavedPosition
										Root.Anchored = false
										Cheat.Globals.SavedPosition = nil
									end
								end

								if flags.InfiniteFly and IsFlying then
									local Origin = Root.Position
									local Result =
										workspace:Raycast(Origin, Vector3.new(0, -1000, 0), Cheat.Globals.RaycastParams)
									if Result and Result.Distance > 4 then
										task.spawn(function()
											local OldVel = Root.Velocity
											for _, Part in Character:GetChildren() do
												if Part:IsA("BasePart") then
													Part.Velocity = Vector3.new(0, -9999, 0)
												end
											end
											RunService.RenderStepped:Wait()
											for _, Part in Character:GetChildren() do
												if Part:IsA("BasePart") then
													Part.Velocity = OldVel
												end
											end
										end)
									end
								end

								if flags.NoFall and not IsFlying then
									local Origin = Root.Position
									local Result =
										workspace:Raycast(Origin, Vector3.new(0, -1000, 0), Cheat.Globals.RaycastParams)

									if Result and Result.Distance > 10 then
										task.spawn(function()
											local OldVel = Root.Velocity
											for _, Part in Character:GetChildren() do
												if Part:IsA("BasePart") then
													Part.Velocity = Vector3.new(0, 9999, 0)
												end
											end
											RunService.RenderStepped:Wait()
											for _, Part in Character:GetChildren() do
												if Part:IsA("BasePart") then
													Part.Velocity = OldVel
												end
											end
										end)
									end
								end
							end
						end))

						local desync = {}

						RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
							for _, Part in workspace.RocketFactoryPinkCardInvisWalls:GetChildren() do
								if Part:IsA("Part") then
									Part.CanCollide = flags.RocketNoclip
								end
							end
							if
								flags.NoclipEnabled
								and flags.NoclipKeybind.Active
								and Client.Character
								and Client.Character:FindFirstChild("HumanoidRootPart")
							then
								desync[1] = Client.Character.HumanoidRootPart.CFrame
								desync[2] = Client.Character.HumanoidRootPart.AssemblyLinearVelocity
								local SpoofThis = Client.Character.HumanoidRootPart.CFrame
								SpoofThis = (SpoofThis + Vector3.new(0, -2.2, 0)) * CFrame.Angles(math.rad(90), 0, 0)
								Client.Character.HumanoidRootPart.CFrame = SpoofThis
								RunService.RenderStepped:Wait()
								if Client.Character and Client.Character.HumanoidRootPart then
									Client.Character.HumanoidRootPart.CFrame = desync[1]
									Client.Character.HumanoidRootPart.AssemblyLinearVelocity = desync[2]
								end
							end
						end))

						local defaultFov = Camera.FieldOfView
						local currentFov = defaultFov

						RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
							local zoomOn = flags.ZoomEnabled and flags.ZoomKeybind.Active
							local fovOn = flags.FovChanger


							local targetFov = defaultFov

							if zoomOn then
								targetFov = flags.ZoomAmount
							elseif fovOn then
								targetFov = flags.FovAmount
							end

							local speed = flags.FovSmoothness or 0.15
							currentFov = currentFov + (targetFov - currentFov) * speed

							Camera.FieldOfView = currentFov

							if not zoomOn and not fovOn then
								defaultFov = currentFov
							end
						end))
					end
				end
				local function CreateHitEffect(HitPosition)
					local Model = Instance.new("Model", Workspace)

					local Part0 = Instance.new("Part")
					Part0.Size = Vector3.new(0.2, 0.2, 0.2)
					Part0.Position = HitPosition
					Part0.Anchored = true
					Part0.CanCollide = false
					Part0.Transparency = 1
					Part0.CanQuery = false
					Part0.Parent = Model

					local Emitter = Instance.new("ParticleEmitter")
					Emitter.Parent = Part0

					Emitter.Texture = "rbxassetid://10198439352"
					Emitter.Lifetime = NumberRange.new(0.3, 0.5)
					Emitter.Rate = 0
					Emitter.Speed = NumberRange.new(0, 0)
					Emitter.RotSpeed = NumberRange.new(0, 0)
					Emitter.Brightness = 20

					Emitter.Size = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 8),
						NumberSequenceKeypoint.new(1, 8),
					})

					Emitter.Color = ColorSequence.new(
						Color3.new(1,1,1),
						Library.Flags.HitEffectColor.Color
					)

					Emitter.LightEmission = 1
					Emitter.VelocitySpread = 0
					Emitter.Enabled = true

					Emitter.EmissionDirection = Enum.NormalId.Top
					Emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
					Emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
					Emitter.Shape = Enum.ParticleEmitterShape.Box
					Emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
					Emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume

					Emitter:Emit(1)

					Emitter.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 0.7),
					})

					task.delay(2, function()
						Model:Destroy()
					end)
				end
				--// Main Hooks
				do
					local OldRaycast = RaycastUtil.Raycast
					RaycastUtil.Raycast = LPH_NO_VIRTUALIZE(function(self, ...)
						local Arguments = { ... }

						if not checkcaller() then
							local Traceback = debug.traceback()

							if Traceback and Traceback:find("ViewmodelController") and flags.Reach then
								Arguments[2] = Arguments[2] * 10
							end

							if flags.PerfectFarm then
								local Output = { OldRaycast(self, ...) }
								local HitInstance = Output[1]
								local HitPosition = Output[2]

								if not HitInstance or typeof(HitInstance) ~= "Instance" then
									return unpack(Output)
								end

								if not HitPosition or typeof(HitPosition) ~= "Vector3" then
									return unpack(Output)
								end

								local Model = HitInstance.Parent
								if not Model or (not Model:IsA("Model")) then
									return unpack(Output)
								end

								local Folder = Model.Parent
								if
									Folder
									and (Folder.Name == "Trees" or Folder.Name == "Nodes")
									and Folder:IsA("Folder")
								then
									local CriticalPart = Model:FindFirstChild("NodeSpark")
										or Model:FindFirstChild("TreeX")
									if
										CriticalPart
										and typeof(CriticalPart) == "Instance"
										and CriticalPart:IsA("Model")
										and CriticalPart.PrimaryPart
									then
										Output[1] = CriticalPart.PrimaryPart
										return unpack(Output)
									end
								end
							end
						end

						return OldRaycast(self, unpack(Arguments))
					end)

					setreadonly(getgenv().task, false)
					local oldtaskspawn = getgenv().task.spawn
					getgenv().task.spawn = newcclosure(LPH_NO_VIRTUALIZE(function(func, ...)
						local traceback = debug.traceback()

						if func and type(func) == "function" and traceback:find("InteractController") then
							if flags.InstantLastCode then
								for i, v in debug.getconstants(func) do
									if type(v) == "number" and v == 0.4 then
										debug.setconstant(func, i, 0)
									end
								end
							end
						end

						if not func or type(func) ~= "function" then
							return
						end

						return oldtaskspawn(func, ...)
					end))
					setreadonly(getgenv().task, true)

					local hitsoundsbind = Instance.new("BindableEvent", game:GetService("ReplicatedStorage"))
					local bullettracersbind = Instance.new("BindableEvent", game:GetService("ReplicatedStorage"))
					local hitnotificationsbind = Instance.new("BindableEvent", game:GetService("ReplicatedStorage"))

					hitnotificationsbind.Event:Connect(function(part, char)
						if flags.HitNotifications then
							local player = Players:GetPlayerFromCharacter(char)
							if player then
								local orighealth = char:FindFirstChildOfClass("Humanoid").Health
								local start = tick()
								local hum = char:FindFirstChildOfClass("Humanoid")
								hum.HealthChanged:Once(function(health)
									local duration = tick() - start
									if duration > 0.7 then
										return
									end
									Library:Notification(
										"Hit "
											.. player.Name
											.. " in their "
											.. part.Name
											.. " for "
											.. math.floor(orighealth - health)
											.. " damage",
										5
									)
								end)
							end
						end
					end)

					hitsoundsbind.Event:Connect(function()
						if
							flags.Hitsounds
							and flags.HitsoundSelect
							and Cheat.Globals.HitSoundIds[flags.HitsoundSelect]
						then
							local sound = Instance.new("Sound")
							sound.SoundId = Cheat.Globals.HitSoundIds[flags.HitsoundSelect]
							sound.Volume = flags.HitsoundVolume
							sound.PlayOnRemove = true
							sound.Parent = workspace
							sound:Destroy()
						end
					end)

					bullettracersbind.Event:Connect(function(position)
						if not flags.BulletTracers then
							return
						end

						local character = Client.Character
						if not character then
							return
						end

						local head = character:FindFirstChild("Head")
						if not head then
							return
						end

						local att0 = Instance.new("Attachment")
						att0.Name = "IgnoreMe"
						att0.WorldPosition = head.Position
						att0.Parent = VMs

						local att1 = Instance.new("Attachment")
						att1.Name = "IgnoreMe"
						att1.WorldPosition = position
						att1.Parent = VMs

						local beam = Instance.new("Beam")
						beam.Name = "IgnoreMe"
						beam.Attachment0 = att0
						beam.Attachment1 = att1

						beam.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 0),
						})

						beam.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, flags.BulletTracersColor.Color),
							ColorSequenceKeypoint.new(1, flags.BulletTracersColor.Color),
						})


						beam.Texture = "rbxassetid://128372145766358"
						beam.TextureLength = 30
						beam.TextureMode = Enum.TextureMode.Wrap
						beam.TextureSpeed = 2

						beam.Width0 = 0.4
						beam.Width1 = 0.4

						beam.FaceCamera = true
						beam.LightEmission = 0
						beam.LightInfluence = 0
						beam.Brightness = 150

						beam.Parent = VMs

						local expiry = flags.BulletTracersDuration or 1
						Debris:AddItem(att0, expiry)
						Debris:AddItem(att1, expiry)
						Debris:AddItem(beam, expiry)
					end)

					local CreateBlood = VFXModule.CreateBlood
					VFXModule.CreateBlood = LPH_NO_UPVALUES(function(self, hit, position)
						local tb = debug.traceback()

						if not tb:find("ReplicatedStorage.Modules.VFXModule:153 function HitVFX") then
							hitnotificationsbind:Fire(hit, hit.Parent)
							hitsoundsbind:Fire()
							bullettracersbind:Fire(position)
						end

						return CreateBlood(self, hit, position)
					end)

					local CreateHole = VFXModule.CreateHole
					VFXModule.CreateHole = LPH_NO_UPVALUES(function(self, hit, position, normal, material, item, impactOnly)
						local tb = debug.traceback()

						if not tb:find("ReplicatedStorage.Modules.VFXModule:153 function HitVFX") then
							bullettracersbind:Fire(position)
						end

						return CreateHole(self, hit, position, normal, material, item, impactOnly)
					end)

					local CreateExplosion = VFXModule.CreateExplosion
					VFXModule.CreateExplosion = LPH_NO_UPVALUES(function(...)
						local Arguments = { ... }

						local Type = tostring(Arguments[5])
						local CFrame = Arguments[2]

						task.spawn(function()
							RaidEvent:Fire(Type, CFrame)
						end)

						return CreateExplosion(...)
					end)


					local v1 = "#\250)\215\028\001U\143\237}\154\218\231Cl-\015H\001\147"
					local LastPredictionPos
					local CreateProjectile = VFXModule.CreateProjectile
					VFXModule.CreateProjectile = LPH_NO_UPVALUES(function(self, ...)
						local Args = { ... }

						local Traceback = debug.traceback()
						if
							Traceback:find("ViewmodelController")
							and Args[1].StepFunction ~= "FakeStepFunc"
							and Args[1].HitFunction ~= "FakeHitFunc"
							and not tostring(Args[1].HitFunction):find("Ignore")
						then
							if flags.ShootOnTP and flags.TeleportKey and flags.TeleportKey.Active then
								local char = Client.Character
								if char and char:FindFirstChild("HumanoidRootPart") then
									char.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
								end
							end
							local now = tick()

							if flags.ForcePenetration then
								for _, v in ipairs(workspace:GetChildren()) do
									if not v:IsA("Folder") then
										continue
									end

									if v.Name == "Military" or v.Name == "Events" then
										continue
									end

									local skip = false
									for _, c in ipairs(v:GetChildren()) do
										if
											c:IsA("Model")
											and (
												c.Name == "Soldier"
												or c.Name == "Brutus"
												or c.Name == "Bruno"
												or c.Name == "Boris"
												or c.Name == "BTR"
											)
										then
											skip = true
											break
										end
									end

									if not skip then
										table.insert(Args[1].Filters, v)
									end
								end
								table.insert(Args[1].Filters, workspace.Terrain)
							end

							Cheat.Globals.ShouldHit = (
								(math.floor(Random.new():NextNumber(0, 1) * 100) / 100) <= (flags.HitChance / 100)
							)
							local isvalidstack3 = isvalidlevel(3)
							local isvalidstack2 = isvalidlevel(2)
							local stacklevel = isvalidstack3 and 3 or isvalidstack2 and 2

							if stacklevel and Targeting.TargetPart and Client.Character then
								LastPredictionPos = nil
								local HitFunction = Args[1].HitFunction
								local startPos = Args[1].Position or Args[1].PositionFirst or Camera.CFrame.Position
								local manipPos = Targeting.ManipulatedPosition
								local targetPos = Targeting.ScannedPosition or Targeting.TargetPart and Targeting.TargetPart.Position

								-- if flags.InstantBullet then
								--     Args[1].Speed = 9e9
								--     Args[1].Gravity = 0
								-- end

								local gun = getgun(Client.Character)
								local oldspeed = Args[1].Speed
								if
									gun
									and ToolInfo[gun]
									and Cheat.Globals.ClientCharacter
									and Cheat.Globals.ClientCharacter:FindFirstChild("InventoryController")
									and Cheat.Globals.ClientCharacter:FindFirstChild("ViewmodelController")
								then
									local InventoryController = Cheat.Globals.ClientCharacter.InventoryController
									local ViewmodelController = Cheat.Globals.ClientCharacter.ViewmodelController
									local v376 = InventoryController.Fetch:Invoke()
									local v377
									if not v376 then
										v377 = nil
									else
										local l_Toolbar_5 = v376.Toolbar
										if not l_Toolbar_5 then
											v377 = nil
										else
											local v379 = l_Toolbar_5[ViewmodelController:GetAttribute("Equipped")]
											v377 = false
											if v379 ~= nil then
												v377 = false
												if v379 ~= 0 then
													v377 = v379
												end
											end
										end
									end

									if v377 then
										v376 = v377.Ammo
										v382 = ItemsModule[v377.ID]
									end
									if v376 then
										v381 = ItemsModule[v376.ID].AmmoStats
									end

									local bullet = ToolInfo[gun].Bullet
									oldspeed = bullet.Speed * (v381.SpeedMult or 1)
								end

								local Speed, Gravity = Args[1].Speed, Args[1].Gravity
								local Distance = (Camera.CFrame.Position - targetPos).Magnitude
								local TimeToHit = Distance / oldspeed

								local G = Gravity * -196.2
								local Drop = -0.5 * G * TimeToHit * TimeToHit
								if tostring(Drop):find("nan") then
									Drop = 0
								end

								LastPredictionPos = Vector3.new(0, Drop, 0)
								local fire_remote_func = debug.getupvalue(Args[1].MissFunction, 1)

								if
									fire_remote_func
									and type(fire_remote_func) == "function"
									and not (isfunctionhooked(fire_remote_func))
								then
									-- print("hooking")
									local old_fire_remote
									old_fire_remote = hookfunction(
										fire_remote_func,
										LPH_NO_UPVALUES(function(remote_type, remote, hash, ...)
											local args = { ... }
											if hash == v1 then
												if not (rawlen(args) == 8) then
													return old_fire_remote(remote_type, remote, hash, unpack(args))
												end
												-- print("detected and ud")

												-- server_Time, v382.Name, camera_cframe, char_cframe:PointToObjectSpace(l_Position_0), char_cframe, spread_stuff, v431, mouse_raycast
												if not Targeting.TargetPart or not Cheat.Globals.ShouldHit then
													return old_fire_remote(remote_type, remote, hash, unpack(args))
												end

												local modified_pos = Targeting.ManipulatedPosition
												local target_position = Targeting.ScannedPosition
													or Targeting.TargetPart.Position

												if LastPredictionPos then
													target_position = target_position + LastPredictionPos
												end

												local character_pos = args[5].Position
												local camera_pos = args[3].Position
												if modified_pos then
													-- print("using manip pos!")
													character_pos = modified_pos
													camera_pos = modified_pos
												end
												args[8] = target_position

												-- fix for viewmodel origin
												if flags.ThirdPersonToggle and flags.ThirdPersonKey.Active then
													local flash_point_pos = args[5]:PointToWorldSpace(args[4])
													local calculated_offset =
														args[3]:PointToObjectSpace(flash_point_pos)
													args[3] = CFrame.lookAt(character_pos, target_position)
													args[4] = calculated_offset
												print('easy third person bypass :P')
												else
													args[3] = CFrame.lookAt(camera_pos, target_position)
												end

												local hawk = CFrame.lookAt(character_pos, target_position)
												local pitch, yaw, _ = hawk:ToEulerAnglesYXZ()

												-- root pos shouldn't have roll/pitch
												args[5] = CFrame.new(hawk.Position)
													* CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
												-- print("modifying")
											end

											return old_fire_remote(remote_type, remote, hash, unpack(args))
										end)
									)
								end

								if flags.HitScan and Targeting.ScannedPosition then
									-- print("hit scanning")
									task.defer(
										HitFunction,
										Targeting.TargetPart,
										Targeting.ScannedPosition,
										Vector3.new(0, 0, 1),
										Targeting.TargetPart.Material
									)
									return
								end
							end

							if Args[1]["Terminate"] then
								Args[1]["Terminate"] = nil
							end

							if Targeting.TargetPart and Cheat.Globals.ShouldHit then
								local p = Targeting.TargetPart
								local hit = p and p.Position
								if p and hit then
									local origin = Args[1].Position
									local dir = (hit - origin).Unit
									local cp = CFrame.new(origin, hit).Position
									if Targeting.ManipulatedPosition or Targeting.ManipPos then
										local mp = Targeting.ManipulatedPosition or Targeting.ManipPos
										dir = (hit - mp).Unit
										cp = CFrame.new(mp, hit).p
									end
									Args[1].Position = cp
									if Args[1].PositionFirst then
										Args[1].PositionFirst = cp
									end
									Args[1].DirectionFirst = dir
									Args[1].Direction = dir
								end
							end
						end

						return CreateProjectile(self, unpack(Args))
					end)

					local Players = game:GetService("Players")
					local local_player = Players.LocalPlayer

					RunService.RenderStepped:Connect(function()
						if not local_player then
							return
						end

						local gui = local_player:FindFirstChild("PlayerGui")
						if not gui then
							return
						end

						local main = gui:FindFirstChild("Main")
						local team = main and main:FindFirstChild("Team")
						local list = team and team:FindFirstChild("TeamList")

						if not list or not flags.SpoofUsername then
							return
						end

						for _, v in ipairs(list:GetDescendants()) do
							if v:IsA("TextLabel") and string.find(v.Text, local_player.Name, 1, true) then
								v.Text = "discord.gg/e7x.net"
							end
						end
					end)
					local UpdateChar = LPH_NO_VIRTUALIZE(function()
						local character = Client.Character or Client.CharacterAdded:Wait()
						Cheat.Globals.ClientCharacter = character

						local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
						local InventoryController = character:WaitForChild("InventoryController")
						local EquipArmor = InventoryController:WaitForChild("EquipArmor")

						for _, conn in getconnections(EquipArmor.Event) do
							local f = conn.Function
							if not f then
								continue
							end
							for _, v in debug.getupvalues(f) do
								if type(v) ~= "function" then
									continue
								end
								local Constants = debug.getconstants(v)
								if Constants[1] == "ArmorEquip" and Constants[5] == "GetAttribute" then
									if flags.InstantLoot then
										debug.setconstant(v, 19, 0)
										debug.setconstant(v, 20, 0)
										debug.setconstant(v, 21, 0)
									end
									table.insert(Cheat.Globals.QuickStackFunctions, v)
								end
							end
						end
						for _, c in getconnections(hum.StateChanged) do
							local fn = c.Function
							if type(fn) == "function" then
								local i = debug.getinfo(fn)
								if i and i.short_src and i.short_src:find("ViewmodelController") then
									local Old
									Old = hookfunction(fn, function(oldState, newState, ...)
										if flags.NoGrounded then
											oldState = Enum.HumanoidStateType.Running
											newState = Enum.HumanoidStateType.Running
										end
										local s, r = pcall(Old, oldState, newState, ...)
										if s then
											return r
										end
										return nil
									end)
								end
							else
								c:Disconnect()
							end
						end
					end)

					UpdateChar()
					Client.CharacterAdded:Connect(UpdateChar)
				end
			end

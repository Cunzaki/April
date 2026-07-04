local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Flags = {}

Flags.AimbotTargetPart = "Head"
Flags.AimbotFovRadius = 50
Flags.AimbotMaxDistance = 1000
Flags.ModCheckerBehavior = "Notify"
Flags.LootEspDistance = 500
Flags.NodeEspDistance = 500
Flags.MiniEspDistance = 500
Flags.PlantEspDistance = 500
Flags.RaidEspDistance = 2000
Flags.FovColor = Color3.fromRGB(255, 255, 255)
Flags.FovAlpha = 1
Flags.SnaplineColor = Color3.fromRGB(255, 255, 255)
Flags.SnaplineAlpha = 1
Flags.CheaterDetectorColor = Color3.fromRGB(255, 13, 13)
Flags.CheaterDetectorAlpha = 1
Flags.DropsColor = Color3.fromRGB(110, 149, 255)
Flags.DropsAlpha = 1
Flags.BodybagColor = Color3.fromRGB(255, 100, 100)
Flags.BodybagAlpha = 1
Flags.StoneColor = Color3.new(0.5, 0.5, 0.5)
Flags.StoneAlpha = 1
Flags.MetalColor = Color3.new(1, 0.6, 0.1)
Flags.MetalAlpha = 1
Flags.PhosphateColor = Color3.new(1, 1, 0.5)
Flags.PhosphateAlpha = 1
Flags.WoolColor = Color3.new(0.92, 0.92, 0.92)
Flags.WoolAlpha = 1
Flags.TomatoColor = Color3.new(1, 0.18, 0.18)
Flags.TomatoAlpha = 1
Flags.PumpkinColor = Color3.new(1, 0.62, 0.13)
Flags.PumpkinAlpha = 1
Flags.CornColor = Color3.new(1, 1, 0.22)
Flags.CornAlpha = 1
Flags.MinicopterColor = Color3.fromRGB(24, 66, 255)
Flags.MinicopterAlpha = 1
Flags.RaidColor = Color3.fromRGB(255, 14, 14)
Flags.RaidAlpha = 1

local BulletInfo = {
	["Pumpkin Launcher"] = { Speed = 80, Gravity = 0.16 },
	["Military M4A1"] = { Speed = 2100, Gravity = 0.55 },
	["Salvaged AK74u"] = { Speed = 1800, Gravity = 0.6 },
	["Nail Gun"] = { Speed = 165, Gravity = 0.25 },
	["Salvaged RPG"] = { Speed = 100, Gravity = 0.12 },
	["Salvaged Python"] = { Speed = 1800, Gravity = 0.6 },
	["Salvaged M14"] = { Speed = 2100, Gravity = 0.55 },
	["Salvaged SMG"] = { Speed = 1800, Gravity = 0.6 },
	["Salvaged P250"] = { Speed = 1400, Gravity = 0.6 },
	["Salvaged Sniper"] = { Speed = 2400, Gravity = 0.55 },
	["Wooden Bow"] = { Speed = 320, Gravity = 0.2 },
	["Salvaged Pipe Rifle"] = { Speed = 1700, Gravity = 0.6 },
	["Salvaged AK47"] = { Speed = 2100, Gravity = 0.55 },
	["Crossbow"] = { Speed = 420, Gravity = 0.2 },
	["Salvaged Pump Action"] = { Speed = 650, Gravity = 0.6 },
	["Military AA12"] = { Speed = 600, Gravity = 0.6 },
	["Salvaged Skorpion"] = { Speed = 1600, Gravity = 0.6 },
	["Military Barrett"] = { Speed = 2500, Gravity = 0.55 },
	["Military PKM"] = { Speed = 2400, Gravity = 0.55 },
	["Bruno's M4A1"] = { Speed = 2100, Gravity = 0.55 },
	["Military MP7"] = { Speed = 1900, Gravity = 0.6 },
	["Military USP"] = { Speed = 1500, Gravity = 0.6 },
	["Salvaged Shotgun"] = { Speed = 400, Gravity = 0.6 },
	["Salvaged Break Action"] = { Speed = 550, Gravity = 0.6 },
	["Military Grenade Launcher"] = { Speed = 85, Gravity = 0.15 },
	["Salvaged Grenade Launcher"] = { Speed = 85, Gravity = 0.15 },
	["Salvaged Double Barrel"] = { Speed = 550, Gravity = 0.6 },
	["Military M39"] = { Speed = 2400, Gravity = 0.52 },
}

local ModeratorIDs = {
	[51281722] = "Game Moderator",
	[7178750309] = "Game Moderator",
	[113179883] = "Game Moderator",
	[3122439095] = "Game Moderator",
	[991290934] = "Game Moderator",
	[3968854760] = "Game Moderator",
	[81993536] = "Game Moderator",
	[1004214871] = "Game Moderator",
	[3034930770] = "Game Moderator",
	[2364950171] = "Game Moderator",
	[1528346843] = "Game Moderator",
	[165053216] = "Game Moderator",
	[1127954045] = "Game Moderator",
	[3640120679] = "Game Moderator",
	[602009251] = "Game Moderator",
	[372791101] = "Game Moderator",
	[1378169111] = "Game Moderator",
	[3020799797] = "Game Moderator",
	[2567998467] = "Game Moderator",
	[4243907215] = "Game Moderator",
	[353983652] = "Game Moderator",
	[1406181681] = "Game Moderator",
	[2229169589] = "Game Moderator",
	[3004094651] = "Game Moderator",
	[839333692] = "Game Moderator",
	[979624578] = "Game Moderator",
	[1478885961] = "Game Moderator",
	[399754916] = "Game Moderator",
	[1193091081] = "Game Moderator",
	[4553863490] = "Game Moderator",
	[4225513035] = "Game Moderator",
	[41482597] = "Game Moderator",
	[2924549627] = "Game Moderator",
	[2732967856] = "Game Moderator",
	[1937516999] = "Game Moderator",
	[1374319325] = "Game Moderator",
	[1058831985] = "Game Moderator",
	[9621064456] = "Game Moderator",
	[584370127] = "Game Moderator",
	[813030262] = "Game Moderator",
	[3470393585] = "Game Moderator",
	[122915793] = "Game Moderator",
	[1534692727] = "Game Moderator",
	[7278178099] = "Game Moderator",
	[8593140875] = "Game Moderator",
	[2525997354] = "Game Moderator",
	[3126891654] = "Game Moderator",
	[1190967808] = "Game Moderator",
	[833946684] = "Game Moderator",
	[202751467] = "Game Moderator",
	[510349404] = "Game Moderator",
	[174212818] = "Contribution",
	[25548179] = "Lead Developer",
	[363101315] = "Lead Developer",
	[47983795] = "Co-Founder",
	[16681869] = "Founder",
}

-- helper functions
local function LoadOffsets()
	local Success, Response = pcall(function()
		return game:HttpGet("https://offsets.imtheo.lol/Offsets.json")
	end)
	if not Success then
		warn("Failed to grab offsets.")
		return nil
	end
	local Decoded = HttpService:JSONDecode(Response)
	if Decoded and Decoded.Offsets then
		return Decoded.Offsets
	end
	return nil
end

local Offsets = LoadOffsets()
if not Offsets then
	warn("Failed to load offsets.")
end

local Cache = getgc({ "RecoilMult", "RangeMult", "SpeedMult", "AimSpreadMult", "HipSpreadMult" })

local function EnableNoRecoil()
	applygc(Cache, "RecoilMult", -1)
end
local function DisableNoRecoil()
	applygc(Cache, "RecoilMult", 1)
end
local function EnableExtendRange()
	applygc(Cache, "RangeMult", 10)
end
local function DisableExtendRange()
	applygc(Cache, "RangeMult", 1)
end
local function EnableNoSpread()
	applygc(Cache, "AimSpreadMult", -1)
	applygc(Cache, "HipSpreadMult", -1)
end
local function DisableNoSpread()
	applygc(Cache, "AimSpreadMult", 1)
	applygc(Cache, "HipSpreadMult", 1)
end

local function ResolveTargetPart(Character, Head, HumanoidRootPart)
	local Mouse = LocalPlayer:GetMouse()
	local MousePos = Vector2.new(Mouse.X, Mouse.Y)
	local TargetPartName = Flags.AimbotTargetPart

	if TargetPartName == "Humanoid Root Part" then
		return HumanoidRootPart or Head
	elseif TargetPartName == "Closest" then
		local ClosestPartDist = math.huge
		local ClosestPart = Head
		for _, Part in Character:GetChildren() do
			if not Part:IsA("BasePart") then
				continue
			end
			if not Part.Position then
				continue
			end
			local PartScreen, PartOnScreen = WorldToScreen(Part.Position)
			if not PartOnScreen then
				continue
			end
			local dx = PartScreen.X - MousePos.X
			local dy = PartScreen.Y - MousePos.Y
			local PartDist = math.sqrt(dx * dx + dy * dy)
			if PartDist < ClosestPartDist then
				ClosestPartDist = PartDist
				ClosestPart = Part
			end
		end
		return ClosestPart
	else
		return Head
	end
end

local function FindClosestViableTarget()
	local ClosestTarget
	local ClosestDistance = math.huge
	local Mouse = LocalPlayer:GetMouse()
	local MousePos = Vector2.new(Mouse.X, Mouse.Y)
	local LocalChar = LocalPlayer.Character
	if not LocalChar then
		return
	end
	local LocalRoot = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")

	for _, Player in Players:GetPlayers() do
		if Player.Name == LocalPlayer.Name then
			continue
		end
		local Char = Player.Character
		if not Char then
			continue
		end
		local Head = Char:FindFirstChild("Head")
		if not Head then
			continue
		end
		local Humanoid = Char:FindFirstChild("Humanoid")
		if not Humanoid then
			continue
		end
		if Humanoid.Health <= 0 then
			continue
		end
		local HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart")
		if not HumanoidRootPart then
			continue
		end

		if Flags.SafezoneCheck then
			local Success, Value = pcall(function()
				return Player:GetAttribute("SafeZone")
			end)
			if not Success then
				continue
			end
			if Value then
				continue
			end
		end

		local TargetPart = ResolveTargetPart(Char, Head, HumanoidRootPart)
		if not TargetPart then
			continue
		end

		if LocalRoot and (LocalRoot.Position - TargetPart.Position).Magnitude > Flags.AimbotMaxDistance then
			continue
		end

		local ScreenPos, OnScreen = WorldToScreen(TargetPart.Position)
		if not OnScreen then
			continue
		end

		local dx = ScreenPos.X - MousePos.X
		local dy = ScreenPos.Y - MousePos.Y
		local Distance = math.sqrt(dx * dx + dy * dy)
		if Flags.AimbotFovCheck and Distance > (Flags.AimbotFovRadius or 50) then
			continue
		end

		if Distance < ClosestDistance then
			ClosestDistance = Distance
			ClosestTarget = {
				Player = Player,
				Character = Char,
				Head = Head,
				HumanoidRootPart = HumanoidRootPart,
				Humanoid = Humanoid,
				TargetPart = TargetPart,
				ScreenDistance = Distance,
				ScreenPos = Vector2.new(ScreenPos.X, ScreenPos.Y),
			}
		end
	end

	return ClosestTarget
end

local function GetHeldWeapon(Char)
	if not Char then
		return "None"
	end
	for _, Model in Char:GetChildren() do
		if not Model:IsA("Model") then
			continue
		end
		if Model.Name == "Hair" or Model.Name == "HolsterModel" then
			continue
		end
		if
			Model:FindFirstChild("Detail")
			or Model:FindFirstChild("Main")
			or Model:FindFirstChild("Handle")
			or Model:FindFirstChild("Attachments")
			or Model:FindFirstChild("ArrowAttach")
			or Model:FindFirstChild("Attach")
		then
			return Model.Name
		end
	end
	return "None"
end

local function GetBulletInfo(WeaponName)
	if not WeaponName then
		return nil
	end
	return BulletInfo[WeaponName]
end

local function CalculateDrop(BulletSpeed, BulletGravity, Position, Origin)
	local Distance = (Origin - Position).Magnitude
	local TimeToHit = Distance / BulletSpeed
	local G = BulletGravity * -195
	local Drop = -0.5 * G * TimeToHit * TimeToHit
	if tostring(Drop):find("nan") then
		Drop = 0
	end
	return Drop
end

local function CalculateTargetPosition(BulletSpeed, BulletGravity, Velocity, Position, Origin)
	local MovePred = Velocity * ((Origin - Position).Magnitude / BulletSpeed)
	local Drop = CalculateDrop(BulletSpeed, BulletGravity, Position, Origin)
	return Position + Vector3.new(MovePred.X, MovePred.Y, MovePred.Z) + Vector3.new(0, Drop, 0)
end

local function CalculateTargetPositionNoYPred(BulletSpeed, BulletGravity, Velocity, Position, Origin)
	local MovePred = Velocity * ((Origin - Position).Magnitude / BulletSpeed)
	local Drop = CalculateDrop(BulletSpeed, BulletGravity, Position, Origin)
	return Position + Vector3.new(MovePred.X, 0, MovePred.Z) + Vector3.new(0, Drop, 0)
end

local function IsCheater(Player)
	if not Player then
		return false
	end
	local Success, Age = pcall(function()
		return memory_read("int", Player.Address + Offsets.Player.AccountAge)
	end)
	if not Success then
		warn("Failed to read account age")
		return false
	end
	if Age <= 60 then
		return true
	end
	local Char = Player.Character
	if not Char then
		return false
	end
	local Hrp = Char:FindFirstChild("HumanoidRootPart")
	if not Hrp then
		return false
	end
	local Velocity = Hrp.Velocity
	if Velocity.Y <= -1000 or Velocity.Y >= 1000 then
		return true
	end
	return false
end
-- end of helper functions

-- ui
local Lib
local URL = "https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.lua"

for i = 1, 10 do
	local cb = "?cb=" .. tostring((math.floor(tick() * 1000) + i * 7919) % 2000000000)
	local ok, body = pcall(game.HttpGet, game, URL .. cb)

	if not (ok and type(body) == "string" and #body > 1000 and body:find("INSUI_FILE_END", 1, true)) then
		task.wait(0.4)
		continue
	end

	local chunk = loadstring(body)
	if not chunk then
		task.wait(0.4)
		continue
	end

	local ok2, res = pcall(chunk)

	if ok2 and type(res) == "table" and type(res.CreateWindow) == "function" then
		Lib = res
		break
	end

	for _, src in
		{
			getgenv,
			function()
				return _G
			end,
			function()
				return shared
			end,
		}
	do
		local env = pcall(src) and src() or {}
		local candidate = type(env) == "table" and env.INSui
		if type(candidate) == "table" and type(candidate.CreateWindow) == "function" then
			Lib = candidate
			break
		end
	end

	if Lib then
		break
	end
	task.wait(0.4)
end

if type(Lib) ~= "table" then
	return warn("INS ui failed to load, run again")
end

local Win = Lib:CreateWindow({
	title = "Divine.land",
	subtitle = "auto",
	size = Vector2.new(720, 540),
	menuKey = "rightshift",
	configFolder = "divineland",
	configName = "default",
	opacity = 1,
	gameInput = false,
	autoSave = true,
	startOpen = true,
})

Win:SetTheme({
	accentA = Color3.fromRGB(0, 217, 192),
	accentB = Color3.fromRGB(0, 168, 232),
	bg = Color3.fromRGB(6, 14, 20),
	sidebar = Color3.fromRGB(10, 22, 30),
})

Win:AddSettingsTab("cog")

-- combat
local CombatTab = Win:Tab("Combat", "crosshair")

local AimbotSec = CombatTab:Section("Aimbot", "Left")

local AimbotToggle = AimbotSec:Toggle("Aimbot", false, function(Bool)
	Flags.Aimbot = Bool
	if not Bool then
		Flags.LockedTarget = nil
	end
end)

AimbotToggle:AddKeybind("MouseButton2", "Hold", function(Bool)
	Flags.AimbotActive = Bool
end)

AimbotSec:Toggle("Auto Prediction", false, function(Bool)
	Flags.AutoPrediction = Bool
end):Tooltip("Automatically adjusts prediction based on velocity and held weapon.")

AimbotSec:Dropdown("Target Part", { "Head" }, { "Head", "Humanoid Root Part", "Closest" }, false, function(v)
	Flags.AimbotTargetPart = v[1]
end)

AimbotSec:Slider("Max Distance", 1000, 50, 50, 1500, "m", function(v)
	Flags.AimbotMaxDistance = v
end)

AimbotSec:Toggle("Safezone Check", false, function(Bool)
	Flags.SafezoneCheck = Bool
end)

local FovToggle = AimbotSec:Toggle("FOV Check", false, function(Bool)
	Flags.AimbotFovCheck = Bool
end)

FovToggle:AddColorpicker("FOV Color", Color3.fromRGB(255, 255, 255), function(C, A)
	Flags.FovColor = C
	Flags.FovAlpha = A
end)

AimbotSec:Slider("FOV Radius", 50, 1, 10, 250, "px", function(v)
	Flags.AimbotFovRadius = v
end)

local SnaplineToggle = AimbotSec:Toggle("Snapline", false, function(Bool)
	Flags.Snapline = Bool
end)

SnaplineToggle:AddColorpicker("Snapline Color", Color3.fromRGB(255, 255, 255), function(C, A)
	Flags.SnaplineColor = C
	Flags.SnaplineAlpha = A
end)

local GunModsSec = CombatTab:Section("Gun Mods", "Right")

GunModsSec:Toggle("No Recoil", false, function(Bool)
	if Bool then
		EnableNoRecoil()
	else
		DisableNoRecoil()
	end
end)

GunModsSec:Toggle("Extend Range", false, function(Bool)
	if Bool then
		EnableExtendRange()
	else
		DisableExtendRange()
	end
end)

GunModsSec:Toggle("No Spread", false, function(Bool)
	if Bool then
		EnableNoSpread()
	else
		DisableNoSpread()
	end
end)
-- end of combat

-- esp
local EspTab = Win:Tab("ESP", "eye")

local PlayerVisSec = EspTab:Section("Player", "Left")

PlayerVisSec:Toggle("Armor Viewer", false, function(Bool)
	Flags.ArmorViewer = Bool
end)

local CheaterDetectorToggle = PlayerVisSec:Toggle("Cheater Detector", false, function(Bool)
	Flags.CheaterDetector = Bool
end):Tooltip("Detects unusual velocities and new accounts.")

CheaterDetectorToggle:AddColorpicker("Cheater Detector Color", Color3.fromRGB(255, 13, 13), function(C, A)
	Flags.CheaterDetectorColor = C
	Flags.CheaterDetectorAlpha = A
end)
-- end of esp

-- misc esp
local LootSec = EspTab:Section("Loot", "Left")

local ItemsToggle = LootSec:Toggle("Dropped Items", false, function(Bool)
	Flags.DropsEsp = Bool
end)

ItemsToggle:AddColorpicker("Dropped Items Color", Color3.fromRGB(110, 149, 255), function(C, A)
	Flags.DropsColor = C
	Flags.DropsAlpha = A
end)

local BodybagToggle = LootSec:Toggle("Bodybag", false, function(Bool)
	Flags.BodybagEsp = Bool
end)

BodybagToggle:AddColorpicker("Bodybag Color", Color3.fromRGB(255, 100, 100), function(C, A)
	Flags.BodybagColor = C
	Flags.BodybagAlpha = A
end)

LootSec:Slider("Loot Distance", 500, 50, 100, 1500, "m", function(v)
	Flags.LootEspDistance = v
end)

local NodeSec = EspTab:Section("Nodes", "Right")

local StoneToggle = NodeSec:Toggle("Stone ESP", false, function(Bool)
	Flags.StoneEsp = Bool
end)

StoneToggle:AddColorpicker("Stone Node Color", Color3.new(0.5, 0.5, 0.5), function(C, A)
	Flags.StoneColor = C
	Flags.StoneAlpha = A
end)

local MetalToggle = NodeSec:Toggle("Metal ESP", false, function(Bool)
	Flags.MetalEsp = Bool
end)

MetalToggle:AddColorpicker("Metal Node Color", Color3.new(1, 0.6, 0.1), function(C, A)
	Flags.MetalColor = C
	Flags.MetalAlpha = A
end)

local PhosphateToggle = NodeSec:Toggle("Phosphate ESP", false, function(Bool)
	Flags.PhosphateEsp = Bool
end)

PhosphateToggle:AddColorpicker("Phosphate Node Color", Color3.new(1, 1, 0.5), function(C, A)
	Flags.PhosphateColor = C
	Flags.PhosphateAlpha = A
end)

NodeSec:Slider("Node Distance", 500, 50, 100, 1500, "m", function(v)
	Flags.NodeEspDistance = v
end)

local PlantSec = EspTab:Section("Plants", "Left")

local WoolToggle = PlantSec:Toggle("Wool ESP", false, function(Bool)
	Flags.WoolEsp = Bool
end)

WoolToggle:AddColorpicker("Wool Color", Color3.new(0.92, 0.92, 0.92), function(C, A)
	Flags.WoolColor = C
	Flags.WoolAlpha = A
end)

local TomatoToggle = PlantSec:Toggle("Tomato ESP", false, function(Bool)
	Flags.TomatoEsp = Bool
end)

TomatoToggle:AddColorpicker("Tomato Color", Color3.new(1, 0.18, 0.18), function(C, A)
	Flags.TomatoColor = C
	Flags.TomatoAlpha = A
end)

local PumpkinToggle = PlantSec:Toggle("Pumpkin ESP", false, function(Bool)
	Flags.PumpkinEsp = Bool
end)

PumpkinToggle:AddColorpicker("Pumpkin Color", Color3.new(1, 0.62, 0.13), function(C, A)
	Flags.PumpkinColor = C
	Flags.PumpkinAlpha = A
end)

local CornToggle = PlantSec:Toggle("Corn ESP", false, function(Bool)
	Flags.CornEsp = Bool
end)

CornToggle:AddColorpicker("Corn Color", Color3.new(1, 1, 0.22), function(C, A)
	Flags.CornColor = C
	Flags.CornAlpha = A
end)

PlantSec:Slider("Plant Distance", 500, 50, 100, 1500, "m", function(v)
	Flags.PlantEspDistance = v
end)

local MiscEspSec = EspTab:Section("Misc", "Right")

local MinicopterToggle = MiscEspSec:Toggle("Minicopter ESP", false, function(Bool)
	Flags.MiniEsp = Bool
end)

MinicopterToggle:AddColorpicker("Minicopter Color", Color3.fromRGB(24, 66, 255), function(C, A)
	Flags.MinicopterColor = C
	Flags.MinicopterAlpha = A
end)

MiscEspSec:Slider("Minicopter Distance", 500, 50, 100, 1500, "m", function(v)
	Flags.MiniEspDistance = v
end)

local RaidToggle = MiscEspSec:Toggle("Raid ESP", false, function(Bool)
	Flags.RaidEsp = Bool
end)

RaidToggle:AddColorpicker("Raid Color", Color3.fromRGB(255, 14, 14), function(C, A)
	Flags.RaidColor = C
	Flags.RaidAlpha = A
end)

MiscEspSec:Slider("Raid Distance", 2000, 100, 500, 5000, "m", function(v)
	Flags.RaidEspDistance = v
end)
-- end of misc esp

-- movement
local MovementTab = Win:Tab("Movement", "user")

local MoveSec = MovementTab:Section("Movement", "Left")

MoveSec:Toggle("Bunny Hop", false, function(Bool)
	Flags.BHop = Bool
end)
-- end of movement

-- misc
local MiscTab = Win:Tab("Misc", "code")

local ModCheckerSec = MiscTab:Section("Mod Checker", "Left")

ModCheckerSec:Toggle("Mod Checker", false, function(Bool)
	Flags.ModChecker = Bool
end)

ModCheckerSec:Dropdown("Mod Checker Behavior", { "Notify" }, { "Notify", "Kick" }, false, function(v)
	Flags.ModCheckerBehavior = v[1]
end):Tooltip("Kick Behavior will crash your Roblox!")
-- end of misc
-- end of ui

do
	RunService.Heartbeat:Connect(function()
		local Camera = Workspace.CurrentCamera
		local Char = LocalPlayer.Character
		if not Char then
			return
		end

		if Flags.Aimbot and Flags.AimbotActive then
			if not Flags.LockedTarget or not Flags.LockedTarget.Humanoid or Flags.LockedTarget.Humanoid.Health <= 0 then
				Flags.LockedTarget = FindClosestViableTarget()
			end

			if not Flags.LockedTarget or not Flags.LockedTarget.TargetPart then
				return
			end

			local TargetPos = Flags.LockedTarget.TargetPart.Position
			local HeldWeapon = GetHeldWeapon(Char)
			local Info = GetBulletInfo(HeldWeapon)

			if not Info or not Flags.AutoPrediction then
				Camera.lookAt(Camera.Position, Flags.LockedTarget.TargetPart.Position)
				return
			end

			if HeldWeapon == "Wooden Bow" or HeldWeapon == "Crossbow" then
				TargetPos = CalculateTargetPositionNoYPred(
					Info.Speed,
					Info.Gravity,
					Flags.LockedTarget.TargetPart.Velocity,
					Flags.LockedTarget.TargetPart.Position,
					Camera.Position
				)
			else
				TargetPos = CalculateTargetPosition(
					Info.Speed,
					Info.Gravity,
					Flags.LockedTarget.TargetPart.Velocity,
					Flags.LockedTarget.TargetPart.Position,
					Camera.Position
				)
			end

			Camera.lookAt(Camera.Position, TargetPos)
		else
			Flags.LockedTarget = nil
		end
	end)
end

do
	local FovCircle = Drawing.new("Circle")
	FovCircle.Thickness = 1
	FovCircle.NumSides = 120
	local FovCircleOutline = Drawing.new("Circle")
	FovCircleOutline.Thickness = 1
	FovCircleOutline.NumSides = 120

	local Snapline = Drawing.new("Line")
	Snapline.Thickness = 1
	local SnaplineOutline = Drawing.new("Line")
	SnaplineOutline.Thickness = 3

	RunService.RenderStepped:Connect(function()
		local Mouse = LocalPlayer:GetMouse()
		local MousePos = Vector2.new(Mouse.X, Mouse.Y)

		if Flags.AimbotFovCheck then
			FovCircleOutline.Position = MousePos
			FovCircleOutline.Radius = Flags.AimbotFovRadius + 1
			FovCircleOutline.Color = Color3.fromRGB(0, 0, 0)
			FovCircleOutline.Transparency = Flags.FovAlpha
			FovCircleOutline.Visible = true

			FovCircle.Position = MousePos
			FovCircle.Radius = Flags.AimbotFovRadius
			FovCircle.Color = Flags.FovColor
			FovCircle.Transparency = Flags.FovAlpha
			FovCircle.ZIndex = 5
			FovCircle.Outline = true
			FovCircle.Visible = true
		else
			FovCircle.Visible = false
			FovCircleOutline.Visible = false
		end

		if Flags.Snapline and Flags.Aimbot and Flags.AimbotActive and Flags.LockedTarget then
			local ScreenPos, OnScreen = WorldToScreen(Flags.LockedTarget.TargetPart.Position)
			if not OnScreen then
				Snapline.Visible = false
				SnaplineOutline.Visible = false
				return
			end
			Snapline.From = MousePos
			Snapline.To = ScreenPos
			Snapline.Color = Color3.fromRGB(255, 255, 255)
			Snapline.ZIndex = 5
			Snapline.Visible = true

			SnaplineOutline.From = MousePos
			SnaplineOutline.To = ScreenPos
			SnaplineOutline.Color = Color3.fromRGB(0, 0, 0)
			SnaplineOutline.Visible = true
		else
			Snapline.Visible = false
			SnaplineOutline.Visible = false
		end
	end)
end

do
	local BoxCount = 8
	local BoxSize = 64
	local BoxSpacing = 5
	local TopMargin = 55
	local BoxRounding = 10
	local BgColor = Color3.fromRGB(71, 71, 71)
	local BgTransparency = 0.75

	local ImageCache = {}
	local ImageBaseUrl = "https://raw.githubusercontent.com/sigma4skin/matcha-fallen/main/armor_images/"

	local Cheaters = {}
	local CheaterLabels = {}

	local SlotDrawings = {}
	for i = 1, BoxCount do
		local Bg = Drawing.new("Square")
		Bg.Filled = true
		Bg.Visible = false
		Bg.Transparency = BgTransparency
		Bg.Color = BgColor
		Bg.Corner = BoxRounding
		Bg.ZIndex = 4

		local Img = Drawing.new("Image")
		Img.Visible = false
		Img.ZIndex = 5

		SlotDrawings[i] = { Bg = Bg, Img = Img, LastIcon = nil }
	end

	local function HideAllSlots()
		for i = 1, BoxCount do
			SlotDrawings[i].Bg.Visible = false
			SlotDrawings[i].Img.Visible = false
			SlotDrawings[i].LastIcon = nil
		end
	end

	local function GetOrCreateLabel(Index)
		if not CheaterLabels[Index] then
			local Label = Drawing.new("Text")
			Label.Text = "CHEATER"
			Label.Color = Color3.fromRGB(255, 13, 13)
			Label.Outline = true
			Label.Font = Drawing.Fonts.UI
			Label.Size = 14
			Label.Center = true
			Label.Visible = false
			Label.ZIndex = 10
			CheaterLabels[Index] = Label
		end
		return CheaterLabels[Index]
	end

	local function HideAllCheaterLabels()
		for _, Label in CheaterLabels do
			Label.Visible = false
		end
	end

	local function GetImage(ArmorId)
		if not ArmorId then
			return nil
		end
		local Cached = ImageCache[ArmorId]
		if Cached ~= nil then
			return Cached or nil
		end
		ImageCache[ArmorId] = false
		local Url = ImageBaseUrl .. ArmorId .. ".png"
		task.spawn(function()
			local Ok, Data = pcall(function()
				return game:HttpGet(Url)
			end)
			if not Ok or not Data then
				ImageCache[ArmorId] = false
				warn("Failed to load image for ", ArmorId)
				return
			end
			ImageCache[ArmorId] = Data
		end)
		return nil
	end

	local SlotCache = {}
	local ArmorViewerTargetChar = nil

	local function RebuildSlotCache(Char)
		SlotCache = {}
		if not Char then
			return
		end
		local Seen = {}
		local Idx = 1
		for _, Child in Char:GetChildren() do
			if Idx > BoxCount then
				break
			end
			local ArmorId = Child.Name:match("^Armor_%d+")
			if ArmorId and not Seen[ArmorId] then
				Seen[ArmorId] = true
				SlotCache[Idx] = { ArmorId = ArmorId, Icon = GetImage(ArmorId) }
				Idx += 1
			end
		end
	end

	local function UpdateSlotCacheImages()
		for _, Slot in SlotCache do
			if Slot and not Slot.Icon then
				local Img = ImageCache[Slot.ArmorId]
				if Img then
					Slot.Icon = Img
				end
			end
		end
	end

	local CheaterDetectorLastUpdate = 0
	local CHEATER_DETECTOR_INTERVAL = 3
	local ArmorViewerLastUpdate = 0
	local ARMOR_VIEWER_INTERVAL = 2

	RunService.RenderStepped:Connect(function()
		local Camera = Workspace.CurrentCamera
		if not Camera then
			HideAllSlots()
			return
		end
		local Viewport = Camera.ViewportSize
		local Now = tick()

		if Flags.ArmorViewer and Flags.LockedTarget then
			local TargetChar = Flags.LockedTarget.Character
			if TargetChar ~= ArmorViewerTargetChar or Now - ArmorViewerLastUpdate >= ARMOR_VIEWER_INTERVAL then
				ArmorViewerLastUpdate = Now
				ArmorViewerTargetChar = TargetChar
				RebuildSlotCache(TargetChar)
			end
			UpdateSlotCacheImages()

			local TotalWidth = BoxCount * BoxSize + (BoxCount - 1) * BoxSpacing
			local StartX = (Viewport.X - TotalWidth) / 2
			local Y = TopMargin

			for I = 1, BoxCount do
				local Slot = SlotCache[I]
				local Draw = SlotDrawings[I]
				local X = StartX + (I - 1) * (BoxSize + BoxSpacing)
				Draw.Bg.Position = Vector2.new(X, Y)
				Draw.Bg.Size = Vector2.new(BoxSize, BoxSize)
				Draw.Bg.Visible = true

				if Slot ~= nil and Slot.Icon ~= nil then
					if Draw.LastIcon ~= Slot.Icon then
						Draw.Img.Data = Slot.Icon
						Draw.LastIcon = Slot.Icon
					end
					Draw.Img.Position = Vector2.new(X + 2, Y + 2)
					Draw.Img.Size = Vector2.new(BoxSize - 4, BoxSize - 4)
					Draw.Img.Visible = true
				else
					Draw.Img.Visible = false
					Draw.LastIcon = nil
				end
			end
		else
			if ArmorViewerTargetChar ~= nil then
				ArmorViewerTargetChar = nil
				SlotCache = {}
			end
			HideAllSlots()
		end

		if Flags.CheaterDetector and Now - CheaterDetectorLastUpdate >= CHEATER_DETECTOR_INTERVAL then
			CheaterDetectorLastUpdate = Now
			for _, Player in Players:GetPlayers() do
				if not Player or Player.Name == LocalPlayer.Name then
					continue
				end
				if Cheaters[Player.Name] == nil then
					Cheaters[Player.Name] = IsCheater(Player)
				end
			end
		end

		if Flags.CheaterDetector then
			local LabelIndex = 0
			for _, Player in Players:GetPlayers() do
				if not Player or Player.Name == LocalPlayer.Name then
					continue
				end
				if not Cheaters[Player.Name] then
					continue
				end
				local Char = Player.Character
				if not Char then
					continue
				end
				local Head = Char:FindFirstChild("Head")
				if not Head then
					continue
				end
				local Humanoid = Char:FindFirstChild("Humanoid")
				if not Humanoid then
					continue
				end
				if Humanoid.Health <= 0 then
					continue
				end
				local ScreenPos, OnScreen = WorldToScreen(Head.Position + Vector3.new(0, 2.5, 0))
				if not OnScreen then
					continue
				end
				LabelIndex += 1
				local Label = GetOrCreateLabel(LabelIndex)
				Label.Position = Vector2.new(ScreenPos.X, ScreenPos.Y)
				Label.Visible = true
			end
			for I = LabelIndex + 1, #CheaterLabels do
				CheaterLabels[I].Visible = false
			end
		else
			HideAllCheaterLabels()
			Cheaters = {}
		end
	end)
end

do
	RunService.Heartbeat:Connect(function()
		local Char = LocalPlayer.Character
		local Humanoid = Char and Char:FindFirstChild("Humanoid")

		local InAir = Humanoid and memory_read("int", Humanoid.Address + Offsets.Humanoid.FloorMaterial) == 1792

		if Flags.BHop and not InAir and iskeypressed(32) and isrbxactive() then
			memory_write("byte", Humanoid.Address + Offsets.Humanoid.Jump, 1)
		end
	end)
end

do
	local EspPool = {}

	local function GetOrCreateEspLabel(Index)
		if not EspPool[Index] then
			local Label = Drawing.new("Text")
			Label.Color = Color3.fromRGB(255, 255, 255)
			Label.Outline = true
			Label.Font = Drawing.Fonts.UI
			Label.Size = 14
			Label.Center = true
			Label.Visible = false
			Label.ZIndex = 8
			EspPool[Index] = Label
		end
		return EspPool[Index]
	end

	local function HideAllEspLabels()
		for _, Label in EspPool do
			Label.Visible = false
		end
	end

	local function GetDropEntries()
		local Entries = {}
		local Drops = workspace:FindFirstChild("Drops")
		if not Drops then
			return Entries
		end
		for _, Item in Drops:GetChildren() do
			if not Item:IsA("Model") then
				continue
			end
			local Root = Item.PrimaryPart or Item:FindFirstChildWhichIsA("BasePart")
			if not Root then
				continue
			end
			local Ok, Pos = pcall(function()
				return Root.Position
			end)
			if not Ok or not Pos then
				continue
			end
			table.insert(Entries, {
				Position = Pos,
				Text = Item.Name,
				Color = Flags.DropsColor,
				Alpha = Flags.DropsAlpha,
				MaxDistance = Flags.LootEspDistance,
			})
		end
		return Entries
	end

	local function GetBodybagEntries()
		local Entries = {}
		local Bodybags = Workspace.Bases.Loners:FindFirstChild("Body Bag")
		if not Bodybags then
			return Entries
		end
		for _, Bag in Bodybags:GetChildren() do
			if not Bag:IsA("Model") then
				continue
			end
			local Main = Bag:FindFirstChild("Main")
			if not Main then
				continue
			end
			table.insert(Entries, {
				Position = Main.Position + Vector3.new(0, 1, 0),
				Text = "Bodybag",
				Color = Flags.BodybagColor,
				Alpha = Flags.BodybagAlpha,
				MaxDistance = Flags.LootEspDistance,
			})
		end
		return Entries
	end

	local function GetNodeEntries()
		local Entries = {}
		local Nodes = Workspace:FindFirstChild("Nodes")
		if not Nodes then
			return Entries
		end
		for _, Node in Nodes:GetChildren() do
			if not Node:IsA("Model") then
				continue
			end
			local BasePart = Node.PrimaryPart or Node:FindFirstChildWhichIsA("BasePart")
			if not BasePart then
				continue
			end
			if Flags.StoneEsp and Node.Name == "Stone_Node" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Stone Node",
					Color = Flags.StoneColor,
					Alpha = Flags.StoneAlpha,
					MaxDistance = Flags.NodeEspDistance,
				})
			elseif Flags.MetalEsp and Node.Name == "Metal_Node" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Metal Node",
					Color = Flags.MetalColor,
					Alpha = Flags.MetalAlpha,
					MaxDistance = Flags.NodeEspDistance,
				})
			elseif Flags.PhosphateEsp and Node.Name == "Phosphate_Node" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Phosphate Node",
					Color = Flags.PhosphateColor,
					Alpha = Flags.PhosphateAlpha,
					MaxDistance = Flags.NodeEspDistance,
				})
			end
		end
		return Entries
	end

	local function GetPlantEntries()
		local Entries = {}
		local Plants = Workspace:FindFirstChild("Plants")
		if not Plants then
			return Entries
		end
		for _, Plant in Plants:GetChildren() do
			if not Plant:IsA("Model") then
				continue
			end
			local BasePart = Plant.PrimaryPart or Plant:FindFirstChildWhichIsA("BasePart")
			if not BasePart then
				continue
			end
			if Flags.WoolEsp and Plant.Name == "Wool Plant" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Wool",
					Color = Flags.WoolColor,
					Alpha = Flags.WoolAlpha,
					MaxDistance = Flags.PlantEspDistance,
				})
			elseif Flags.TomatoEsp and Plant.Name == "Tomato Plant" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Tomato",
					Color = Flags.TomatoColor,
					Alpha = Flags.TomatoAlpha,
					MaxDistance = Flags.PlantEspDistance,
				})
			elseif Flags.PumpkinEsp and Plant.Name == "Pumpkin Plant" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Pumpkin",
					Color = Flags.PumpkinColor,
					Alpha = Flags.PumpkinAlpha,
					MaxDistance = Flags.PlantEspDistance,
				})
			elseif Flags.CornEsp and Plant.Name == "Corn Plant" then
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "Corn",
					Color = Flags.CornColor,
					Alpha = Flags.CornAlpha,
					MaxDistance = Flags.PlantEspDistance,
				})
			end
		end
		return Entries
	end

	local function GetMiniEntries()
		local Entries = {}
		local Minis = Workspace.Bases.Loners:FindFirstChild("Salvaged Flycopter")
		if not Minis then
			return Entries
		end
		for _, Mini in Minis:GetChildren() do
			if not Mini:IsA("Model") then
				continue
			end
			local BasePart = Mini.PrimaryPart or Mini:FindFirstChildWhichIsA("BasePart")
			if not BasePart then
				continue
			end
			table.insert(Entries, {
				Position = BasePart.Position + Vector3.new(0, 1, 0),
				Text = "Minicopter",
				Color = Flags.MinicopterColor,
				Alpha = Flags.MinicopterAlpha,
				MaxDistance = Flags.MiniEspDistance,
			})
		end
		return Entries
	end

	local RaidCache = {}
	local RAID_EXPIRE_TIME = 30

	local function CleanRaidCache()
		local Now = tick()
		for I = #RaidCache, 1, -1 do
			if Now - RaidCache[I].Time >= RAID_EXPIRE_TIME then
				table.remove(RaidCache, I)
			end
		end
	end

	local function UpdateRaidCache()
		local VFX = Workspace:FindFirstChild("VFX")
		if not VFX then
			return
		end
		local Now = tick()
		for _, Item in VFX:GetChildren() do
			if not Item.Name:find("Explosion") then
				continue
			end
			local BasePart
			if Item:IsA("BasePart") then
				BasePart = Item
			elseif Item:IsA("Model") then
				BasePart = Item.PrimaryPart or Item:FindFirstChildWhichIsA("BasePart")
			end
			if not BasePart then
				continue
			end
			local Ok, Pos = pcall(function()
				return BasePart.Position
			end)
			if not Ok or not Pos then
				continue
			end
			local AlreadyCached = false
			for _, Cached in RaidCache do
				if Cached.Position and (Cached.Position - Pos).Magnitude < 20 then
					Cached.Time = Now
					AlreadyCached = true
					break
				end
			end
			if not AlreadyCached then
				table.insert(RaidCache, { Position = Pos, Time = Now })
			end
		end
	end

	local function GetRaidEntries()
		local Entries = {}
		CleanRaidCache()
		UpdateRaidCache()
		local Now = tick()
		for _, Cached in RaidCache do
			local TimeLeft = math.ceil(RAID_EXPIRE_TIME - (Now - Cached.Time))
			table.insert(Entries, {
				Position = Cached.Position + Vector3.new(0, 1, 0),
				Text = "Raid (" .. TimeLeft .. "s)",
				Color = Flags.RaidColor,
				Alpha = Flags.RaidAlpha,
				MaxDistance = Flags.RaidEspDistance,
			})
		end
		return Entries
	end

	local EspCache = {}
	local EspCacheLastUpdate = 0
	local ESP_CACHE_INTERVAL = 2
	local EspDrawLastUpdate = 0
	local ESP_DRAW_INTERVAL = 0.015

	local function RebuildEspCache()
		local NewCache = {}
		if Flags.DropsEsp then
			for _, E in GetDropEntries() do
				table.insert(NewCache, E)
			end
		end
		if Flags.BodybagEsp then
			for _, E in GetBodybagEntries() do
				table.insert(NewCache, E)
			end
		end
		if Flags.StoneEsp or Flags.MetalEsp or Flags.PhosphateEsp then
			for _, E in GetNodeEntries() do
				table.insert(NewCache, E)
			end
		end
		if Flags.WoolEsp or Flags.TomatoEsp or Flags.PumpkinEsp or Flags.CornEsp then
			for _, E in GetPlantEntries() do
				table.insert(NewCache, E)
			end
		end
		if Flags.MiniEsp then
			for _, E in GetMiniEntries() do
				table.insert(NewCache, E)
			end
		end
		EspCache = NewCache
	end

	RunService.RenderStepped:Connect(function()
		local Now = tick()
		local Char = LocalPlayer.Character
		local Root = Char and Char:FindFirstChild("HumanoidRootPart")

		local AnyEnabled = Flags.DropsEsp
			or Flags.BodybagEsp
			or Flags.StoneEsp
			or Flags.MetalEsp
			or Flags.PhosphateEsp
			or Flags.MiniEsp
			or Flags.WoolEsp
			or Flags.TomatoEsp
			or Flags.PumpkinEsp
			or Flags.CornEsp
			or Flags.RaidEsp

		if not AnyEnabled then
			HideAllEspLabels()
			EspCache = {}
			return
		end

		if Now - EspCacheLastUpdate >= ESP_CACHE_INTERVAL then
			EspCacheLastUpdate = Now
			task.spawn(RebuildEspCache)
		end

		if Now - EspDrawLastUpdate < ESP_DRAW_INTERVAL then
			return
		end
		EspDrawLastUpdate = Now

		local AllEntries = {}
		for _, E in EspCache do
			table.insert(AllEntries, E)
		end
		if Flags.RaidEsp then
			for _, E in GetRaidEntries() do
				table.insert(AllEntries, E)
			end
		end

		local LabelIndex = 0
		for _, Entry in AllEntries do
			local Dist = Root and (Root.Position - Entry.Position).Magnitude
			if Dist and Dist > Entry.MaxDistance then
				continue
			end
			local ScreenPos, OnScreen = WorldToScreen(Entry.Position)
			if not OnScreen then
				continue
			end
			LabelIndex += 1
			local Label = GetOrCreateEspLabel(LabelIndex)
			Label.Text = Entry.Text .. " (" .. math.floor(Dist) .. "m)"
			Label.Color = Entry.Color
			Label.Transparency = Entry.Alpha
			Label.Position = Vector2.new(ScreenPos.X, ScreenPos.Y)
			Label.Visible = true
		end

		for I = LabelIndex + 1, #EspPool do
			if EspPool[I] then
				EspPool[I].Visible = false
			end
		end
	end)
end

do
	local ModCheckerLastCheck = 0
	local MOD_CHECKER_INTERVAL = 3
	local SeenMods = {}

	RunService.Heartbeat:Connect(function()
		local Now = tick()
		if Flags.ModChecker then
			if Now - ModCheckerLastCheck >= MOD_CHECKER_INTERVAL then
				ModCheckerLastCheck = Now
				for _, Player in Players:GetPlayers() do
					if not Player or Player.Name == LocalPlayer.Name then
						continue
					end
					local Success, UserId = pcall(function()
						return memory_read("uintptr_t", Player.Address + Offsets.Player.UserId)
					end)
					if not Success then
						warn("fuck failed to load userid for mod checker")
					end
					if not ModeratorIDs[UserId] or SeenMods[UserId] then
						continue
					end
					if Flags.ModCheckerBehavior == "Notify" then
						Lib:Notify(
							"Mod Checker",
							ModeratorIDs[UserId] .. " (" .. Player.Name .. ") joined your game!",
							5,
							"warning"
						)
						SeenMods[UserId] = true
					elseif Flags.ModCheckerBehavior == "Kick" then
						memory_write("string", game.Workspace.Address, "BLAH")
					end
				end
			end
		end
	end)
end
local Window = Library:Window({Name = "niggerscript"})
local ModuleList = Library:ModuleList()
local Indicator = Library:Indicator()

local CombatTab = Window:Page({Name = "Combat", Columns = 2})
local VisualsTab = Window:Page({Name = "Visuals", Columns = 2})
local WorldTab = Window:Page({Name = "World", Columns = 2})
local MiscTab = Window:Page({Name = "Misc", Columns = 2})

-- Combat Tab
do
    -- Side 1
    local aimbot = CombatTab:Section({Name = "Aimbot", Side = 1})
    aimbot:Toggle({Name = "Enabled", Flag = "AimbotEnabled", Default = false})
    aimbot:Dropdown({Name = "Mode", Flag = "AimbotMode", Items = {"Memory", "Silent"}, Default = "Memory"})
    aimbot:Dropdown({Name = "Target Parts", Flag = "AimbotTargetParts", Items = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftHand", "RightHand"}, Default = "Head", Multi = true})
    aimbot:Slider({Name = "Hit Chance", Flag = "AimbotHitChance", Min = 0, Max = 100, Default = 100, Suffix = "%", Decimals = 0})
    aimbot:Toggle({Name = "Force Penetration", Flag = "AimbotForcePen", Default = false})
    aimbot:Toggle({Name = "Manipulation", Flag = "AimbotManipulation", Default = false})
    do
        local label = aimbot:Label("Manipulation Distance")
        label:Colorpicker({Flag = "AimbotManipColor", Default = Color3.fromRGB(255, 0, 0), Alpha = 1})
    end
    aimbot:Slider({Name = "Manipulation Distance", Flag = "AimbotManipDist", Min = 1, Max = 10, Default = 5, Suffix = "", Decimals = 0})
    aimbot:Toggle({Name = "SmartPeak", Flag = "AimbotSmartPeak", Default = false})
    aimbot:Slider({Name = "SmartPeak Distance", Flag = "AimbotSmartPeakDist", Min = 1, Max = 30, Default = 5, Suffix = "", Decimals = 0})
    aimbot:Toggle({Name = "HitScan", Flag = "AimbotHitScan", Default = false})
    do
        local label = aimbot:Label("HitScan Color")
        label:Colorpicker({Flag = "AimbotHitScanColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    aimbot:Slider({Name = "HitScan Distance", Flag = "AimbotHitScanDist", Min = 1, Max = 9.5, Default = 5, Suffix = "", Decimals = 1})
    aimbot:Toggle({Name = "Desync Resolver", Flag = "AimbotDesyncResolver", Default = false})
    aimbot:Toggle({Name = "Visible Check", Flag = "AimbotVisibleCheck", Default = false})
    aimbot:Toggle({Name = "Down Check", Flag = "AimbotDownCheck", Default = false})
    aimbot:Toggle({Name = "Draw FOV", Flag = "AimbotDrawFOV", Default = false})
    do
        local label = aimbot:Label("FOV Color")
        label:Colorpicker({Flag = "AimbotFOVColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    aimbot:Slider({Name = "FOV Size", Flag = "AimbotFOVSize", Min = 0, Max = 500, Default = 200, Suffix = "", Decimals = 0})
    do
        local label = aimbot:Label("Aimbot Key")
        label:Keybind({Name = "Aimbot Key", Flag = "AimbotKey", Default = Enum.KeyCode.Q, Mode = "Toggle"})
    end

    -- Side 2
    local gunMods = CombatTab:Section({Name = "Gun Mods", Side = 2})
    gunMods:Toggle({Name = "No Recoil", Flag = "GunNoRecoil", Default = false})
    gunMods:Toggle({Name = "No Spread", Flag = "GunNoSpread", Default = false})
    gunMods:Toggle({Name = "No Sway", Flag = "GunNoSway", Default = false})
    gunMods:Toggle({Name = "Rapid Fire", Flag = "GunRapidFire", Default = false})
    gunMods:Slider({Name = "Rapid Fire Multiplier", Flag = "GunRapidFireMult", Min = 1, Max = 1.5, Default = 1, Suffix = "x", Decimals = 1})
    gunMods:Toggle({Name = "Auto Reload", Flag = "GunAutoReload", Default = false})
    gunMods:Toggle({Name = "Instant Equip", Flag = "GunInstantEquip", Default = false})
    gunMods:Toggle({Name = "Instant Aim", Flag = "GunInstantAim", Default = false})
    gunMods:Toggle({Name = "Force Automatic", Flag = "GunForceAuto", Default = false})
    gunMods:Toggle({Name = "Double Tap", Flag = "GunDoubleTap", Default = false})
    gunMods:Toggle({Name = "Instant Eoka", Flag = "GunInstantEoka", Default = false})
    gunMods:Toggle({Name = "Instant Bullet", Flag = "GunInstantBullet", Default = false})
    gunMods:Toggle({Name = "Remove Bobbing", Flag = "GunRemoveBobbing", Default = false})
    gunMods:Toggle({Name = "Teleport to Bullet", Flag = "GunTeleportBullet", Default = false})
    do
        local label = gunMods:Label("Teleport Key")
        label:Keybind({Name = "Teleport Key", Flag = "GunTeleportKey", Default = Enum.KeyCode.T, Mode = "Toggle"})
    end
    gunMods:Toggle({Name = "Lower Melee Cooldown", Flag = "GunLowerMeleeCD", Default = false})

    local crosshair = CombatTab:Section({Name = "Crosshair", Side = 2})
    crosshair:Toggle({Name = "Enabled", Flag = "CrosshairEnabled", Default = false})
    crosshair:Toggle({Name = "Rotation", Flag = "CrosshairRotation", Default = false})
    crosshair:Slider({Name = "Width", Flag = "CrosshairWidth", Min = 1, Max = 3, Default = 3, Suffix = "", Decimals = 0})
    crosshair:Slider({Name = "Length", Flag = "CrosshairLength", Min = 5, Max = 40, Default = 19, Suffix = "", Decimals = 0})
    crosshair:Slider({Name = "Gap", Flag = "CrosshairGap", Min = 1, Max = 40, Default = 20, Suffix = "", Decimals = 0})
    crosshair:Slider({Name = "Transparency", Flag = "CrosshairTransparency", Min = 0, Max = 1, Default = 0, Suffix = "", Decimals = 1})
    do
        local label = crosshair:Label("Crosshair Color")
        label:Colorpicker({Flag = "CrosshairColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end

    local triggerbot = CombatTab:Section({Name = "Triggerbot", Side = 2})
    triggerbot:Toggle({Name = "Enabled", Flag = "TriggerbotEnabled", Default = false})
    triggerbot:Slider({Name = "Delay", Flag = "TriggerbotDelay", Min = 0, Max = 1, Default = 0, Suffix = "s", Decimals = 2})
end

-- Visuals Tab
do
    -- Side 1
    local playerESP = VisualsTab:Section({Name = "Player ESP", Side = 1})
    playerESP:Toggle({Name = "Enabled", Flag = "PlayerESPEnabled", Default = false})
    playerESP:Toggle({Name = "Box", Flag = "PlayerESPBox", Default = false})
    playerESP:Toggle({Name = "Box Fill", Flag = "PlayerESPBoxFill", Default = false})
    playerESP:Toggle({Name = "Health Bar", Flag = "PlayerESPHealthBar", Default = false})
    playerESP:Toggle({Name = "Health Text", Flag = "PlayerESPHealthText", Default = false})
    playerESP:Toggle({Name = "Name", Flag = "PlayerESPName", Default = false})
    playerESP:Toggle({Name = "Distance", Flag = "PlayerESPDistance", Default = false})
    playerESP:Toggle({Name = "Weapon", Flag = "PlayerESPWeapon", Default = false})
    playerESP:Toggle({Name = "Skeleton", Flag = "PlayerESPSkeleton", Default = false})
    playerESP:Toggle({Name = "Chams", Flag = "PlayerESPChams", Default = false})
    playerESP:Toggle({Name = "Tracers", Flag = "PlayerESPTracers", Default = false})
    playerESP:Toggle({Name = "Glow", Flag = "PlayerESPGlow", Default = false})
    playerESP:Slider({Name = "Max Distance", Flag = "PlayerESPMaxDist", Min = 10, Max = 1000, Default = 300, Suffix = "", Decimals = 0})
    do
        local label = playerESP:Label("Box Color")
        label:Colorpicker({Flag = "PlayerESPBoxColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    do
        local label = playerESP:Label("Skeleton Color")
        label:Colorpicker({Flag = "PlayerESPSkeletonColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    do
        local label = playerESP:Label("Tracer Color")
        label:Colorpicker({Flag = "PlayerESPTracerColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    do
        local label = playerESP:Label("Team Color")
        label:Colorpicker({Flag = "PlayerESPTeamColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end

    local aiESP = VisualsTab:Section({Name = "AI ESP", Side = 1})
    aiESP:Toggle({Name = "Enabled", Flag = "AIESPEnabled", Default = false})
    aiESP:Toggle({Name = "Box", Flag = "AIESPBox", Default = false})
    aiESP:Toggle({Name = "Name", Flag = "AIESPName", Default = false})
    aiESP:Toggle({Name = "Health", Flag = "AIESPHealth", Default = false})
    aiESP:Toggle({Name = "Distance", Flag = "AIESPDistance", Default = false})
    aiESP:Toggle({Name = "Tracers", Flag = "AIESPTracers", Default = false})
    aiESP:Slider({Name = "Max Distance", Flag = "AIESPMaxDist", Min = 10, Max = 1000, Default = 300, Suffix = "", Decimals = 0})

    -- Side 2
    local oreESP = VisualsTab:Section({Name = "Ore/Hemp ESP", Side = 2})
    oreESP:Toggle({Name = "Enabled", Flag = "OreESPEnabled", Default = false})
    oreESP:Toggle({Name = "Best Path", Flag = "OreESPBestPath", Default = false})
    oreESP:Toggle({Name = "Tracers", Flag = "OreESPTracers", Default = false})
    oreESP:Toggle({Name = "Chams", Flag = "OreESPChams", Default = false})
    oreESP:Toggle({Name = "Highlight Nearest", Flag = "OreESPHighlight", Default = false})
    oreESP:Slider({Name = "Max Distance", Flag = "OreESPMaxDist", Min = 10, Max = 500, Default = 150, Suffix = "", Decimals = 0})
    oreESP:Dropdown({Name = "Ore Type", Flag = "OreESPType", Items = {"All", "Sulfur", "Metal", "Stone", "Hemp"}, Default = "All"})
    do
        local label = oreESP:Label("ESP Color")
        label:Colorpicker({Flag = "OreESPColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end

    local miscVis = VisualsTab:Section({Name = "Misc Visuals", Side = 2})
    miscVis:Toggle({Name = "FOV Circle", Flag = "MiscVisFOVCircle", Default = false})
    miscVis:Toggle({Name = "Crosshair", Flag = "MiscVisCrosshair", Default = false})
    miscVis:Toggle({Name = "Watermark", Flag = "MiscVisWatermark", Default = false})
    miscVis:Toggle({Name = "Hitmarker", Flag = "MiscVisHitmarker", Default = false})
    miscVis:Toggle({Name = "Bullet Tracers", Flag = "MiscVisBulletTracers", Default = false})
    miscVis:Slider({Name = "FOV Size", Flag = "MiscVisFOVSize", Min = 10, Max = 200, Default = 100, Suffix = "", Decimals = 0})

    local radar = VisualsTab:Section({Name = "Radar", Side = 2})
    radar:Toggle({Name = "Enabled", Flag = "RadarEnabled", Default = false})
    radar:Dropdown({Name = "Style", Flag = "RadarStyle", Items = {"Circle", "Rectangle"}, Default = "Circle"})
    radar:Slider({Name = "Radius", Flag = "RadarRadius", Min = 50, Max = 300, Default = 150, Suffix = "", Decimals = 0})
    radar:Slider({Name = "Scale", Flag = "RadarScale", Min = 0.5, Max = 5, Default = 1, Suffix = "", Decimals = 1})
    radar:Toggle({Name = "Rotate", Flag = "RadarRotate", Default = false})
    radar:Toggle({Name = "Show Team", Flag = "RadarShowTeam", Default = false})
    radar:Toggle({Name = "Show Name", Flag = "RadarShowName", Default = false})
    radar:Toggle({Name = "Show Distance", Flag = "RadarShowDistance", Default = false})
    radar:Toggle({Name = "Show Tool", Flag = "RadarShowTool", Default = false})
    radar:Dropdown({Name = "Tool Style", Flag = "RadarToolStyle", Items = {"Icons", "Text"}, Default = "Icons"})
    do
        local label = radar:Label("Visible Color")
        label:Colorpicker({Flag = "RadarVisibleColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    do
        local label = radar:Label("Hidden Color")
        label:Colorpicker({Flag = "RadarHiddenColor", Default = Color3.fromRGB(255, 0, 0), Alpha = 1})
    end

    local preview = VisualsTab:Section({Name = "Preview", Side = 2})
    preview:Toggle({Name = "Show Preview", Flag = "PreviewShow", Default = false})
end

-- World Tab
do
    -- Side 1
    local skybox = WorldTab:Section({Name = "Skybox", Side = 1})
    skybox:Toggle({Name = "Custom Skybox", Flag = "SkyboxEnabled", Default = false})
    skybox:Textbox({Name = "Skybox ID", Flag = "SkyboxID", Default = "", Placeholder = "Enter Skybox ID...", Numeric = false, Finished = true})

    local lighting = WorldTab:Section({Name = "Lighting", Side = 1})
    lighting:Toggle({Name = "Custom Lighting", Flag = "LightingEnabled", Default = false})
    do
        local label = lighting:Label("Ambient Color")
        label:Colorpicker({Flag = "LightingAmbientColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    do
        local label = lighting:Label("Fog Color")
        label:Colorpicker({Flag = "LightingFogColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    lighting:Slider({Name = "Fog Start", Flag = "LightingFogStart", Min = 0, Max = 1000, Default = 0, Suffix = "", Decimals = 0})
    lighting:Slider({Name = "Fog End", Flag = "LightingFogEnd", Min = 100, Max = 5000, Default = 1000, Suffix = "", Decimals = 0})

    -- Side 2
    local chams = WorldTab:Section({Name = "Chams", Side = 2})
    chams:Toggle({Name = "Enabled", Flag = "ChamsEnabled", Default = false})
    chams:Dropdown({Name = "Material", Flag = "ChamsMaterial", Items = {"ForceField", "Neon", "Glass", "SmoothPlastic"}, Default = "ForceField"})
    do
        local label = chams:Label("Color")
        label:Colorpicker({Flag = "ChamsColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end

    local gunVFX = WorldTab:Section({Name = "Gun VFX", Side = 2})
    gunVFX:Toggle({Name = "Bullet Tracers", Flag = "GunVFXTracers", Default = false})
    gunVFX:Toggle({Name = "Muzzle Flash", Flag = "GunVFXMuzzleFlash", Default = false})
    gunVFX:Toggle({Name = "Shells", Flag = "GunVFXShells", Default = false})
    do
        local label = gunVFX:Label("Tracer Color")
        label:Colorpicker({Flag = "GunVFXTracerColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end

    local skins = WorldTab:Section({Name = "Skins", Side = 2})
    skins:Toggle({Name = "Weapon Skins Enabled", Flag = "SkinsWeaponEnabled", Default = false})
    skins:Toggle({Name = "Armor Skins Enabled", Flag = "SkinsArmorEnabled", Default = false})
    skins:Toggle({Name = "Tool Skins Enabled", Flag = "SkinsToolEnabled", Default = false})
    skins:Dropdown({Name = "Weapon Skin Category", Flag = "SkinsWeaponCategory", Items = {"All", "Pistol", "Shotgun", "Rifle", "Bow", "Melee"}, Default = "All"})
    do
        local label = skins:Label("Skin Color")
        label:Colorpicker({Flag = "SkinsColor", Default = Color3.fromRGB(255, 255, 255), Alpha = 1})
    end
    skins:Dropdown({Name = "Skin Material", Flag = "SkinsMaterial", Items = {"ForceField", "Neon", "Glass", "SmoothPlastic", "Metal", "Ice", "CarbonFiber", "Wood", "Leather", "Fabric", "Sand", "Brick", "Granite", "Concrete", "CrackedLava", "Limestone", "Basalt", "Rock", "Glacier", "Snow", "Tile", "DiamondPlate", "Foil", "Plastic", "Neon"}, Default = "ForceField"})
    skins:Button({Name = "Refresh Skins"})
end

-- Misc Tab
do
    -- Side 1
    local movement = MiscTab:Section({Name = "Movement", Side = 1})
    movement:Toggle({Name = "Inf Jump", Flag = "MovementInfJump", Default = false})
    movement:Toggle({Name = "No Fall Damage", Flag = "MovementNoFallDamage", Default = false})
    movement:Toggle({Name = "Auto Jump", Flag = "MovementAutoJump", Default = false})
    movement:Slider({Name = "Walkspeed", Flag = "MovementWalkspeed", Min = 16, Max = 100, Default = 16, Suffix = "", Decimals = 0})

    local playerSec = MiscTab:Section({Name = "Player", Side = 1})
    playerSec:Toggle({Name = "No Clip", Flag = "PlayerNoClip", Default = false})
    playerSec:Toggle({Name = "Fly", Flag = "PlayerFly", Default = false})
    playerSec:Slider({Name = "Fly Speed", Flag = "PlayerFlySpeed", Min = 1, Max = 50, Default = 10, Suffix = "", Decimals = 0})
    playerSec:Toggle({Name = "Anti-Aim", Flag = "PlayerAntiAim", Default = false})
    playerSec:Toggle({Name = "Spinbot", Flag = "PlayerSpinbot", Default = false})

    -- Side 2
    local inventory = MiscTab:Section({Name = "Inventory", Side = 2})
    inventory:Toggle({Name = "Auto Loot", Flag = "InvAutoLoot", Default = false})
    inventory:Toggle({Name = "Auto Farm", Flag = "InvAutoFarm", Default = false})
    inventory:Toggle({Name = "Auto Gather", Flag = "InvAutoGather", Default = false})
    inventory:Slider({Name = "Gather Radius", Flag = "InvGatherRadius", Min = 5, Max = 50, Default = 15, Suffix = "", Decimals = 0})
    inventory:Toggle({Name = "Instant Loot", Flag = "InvInstantLoot", Default = false})
    inventory:Toggle({Name = "Auto Reload", Flag = "InvAutoReload", Default = false})

    local antiMisc = MiscTab:Section({Name = "Anti / Misc", Side = 2})
    antiMisc:Toggle({Name = "Safe Mode", Flag = "MiscSafeMode", Default = false})
    antiMisc:Toggle({Name = "Anti-Hack", Flag = "MiscAntiHack", Default = false})
    antiMisc:Button({Name = "Rejoin", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer) end})
    antiMisc:Button({Name = "Server Hop", Callback = function()
        local HttpService = game:GetService("HttpService")
        local apiUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        local success, response = pcall(function()
            return HttpService:JSONDecode(HttpService:GetAsync(apiUrl))
        end)
        if success and response and response.data then
            for _, server in ipairs(response.data) do
                if server.id ~= game.JobId then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, game:GetService("Players").LocalPlayer)
                    break
                end
            end
        end
    end})

end

local SettingsTab = Window:CreateSettingsPage(Window, ModuleList, Indicator)

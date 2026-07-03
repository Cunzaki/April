-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

if not LPH_OBFUSCATED then
    LPH_OBFUSCATED = false;

    function LPH_NO_VIRTUALIZE(...)
        return ...;
    end;

    function LPH_JIT_MAX(...)
        return ...;
    end;
end;

_ = math.random();
local Players = game:GetService("Players");
local ReplicatedFirst = game:GetService("ReplicatedFirst");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ContentProvider = game:GetService("ContentProvider");
local StarterGui = game:GetService("StarterGui");
local SoundService = game:GetService("SoundService");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
game:GetService("Stats");
local LocalPlayer = Players.LocalPlayer;
local v6 = LPH_JIT_MAX(function(p1, p2, p3) -- Line: 44
    local v4 = 0;

    while v4 < (p3 or (1 / 0)) do
        local v5 = p1:FindFirstChild(p2);

        if v5 then
            return v5;
        end;

        v4 = v4 + task.wait(0.1);
    end;
end);
local v7 = v6(script, "LoadingScreen");
local v8 = v6(LocalPlayer, "PlayerGui");
local v9 = v6(ReplicatedStorage, "Modules");
local u10 = v7:Clone();
u10.Parent = v8;
ReplicatedFirst:RemoveDefaultLoadingScreen();
local u11 = nil;
local u12 = nil;
local u13 = nil;
local v45, v46, v47 = pcall(function() -- Line: 67
    -- upvalues: u11 (ref), u12 (ref), u13 (ref)
    local v14, v15, v16, v17, v18, v19 = debug.info(0, "sfnal\0");
    local v20, v21 = string.match(`{v15}`, "(function: )(%w+)");

    if v14 ~= "[C]" or (v19 ~= -1 or (v16 ~= "info" or (v17 ~= 0 or (not v18 or (not v20 or #v21 ~= 18))))) then
        return 0, `{v14}/{v19}/{v15}/{v16}/{v17}/{v18}`;
    end;

    u11 = v21 / 2;
    local v22, v23, v24, v25, v26, v27 = debug.info(1, "sfnal\0");

    if v22 ~= "ReplicatedFirst.Preload" or (v24 ~= "" or (v25 ~= 0 or (v26 or not string.match(`{v23}`, "(function: )(%w+)")))) then
        return 1, `{v22}/{v27}/{v23}/{v24}/{v25}/{v26}`;
    end;

    local v28, v29, v30, v31, v32, v33 = debug.info(2, "sfnal\0");
    local v34, v35 = string.match(`{v29}`, "(function: )(%w+)");

    if v28 ~= "[C]" or (v33 ~= -1 or (v30 ~= "pcall" or (v31 ~= 0 or (not v32 or (not v34 or #v35 ~= 18))))) then
        return 2, `{v28}/{v33}/{v29}/{v30}/{v31}/{v32}`;
    end;

    u12 = v35 / 2;
    local v36, v37, v38, v39, v40, v41 = debug.info(3, "sfnal\0");
    local v42, v43 = string.match(`{v37}`, "(function: )(%w+)");

    if v36 ~= "ReplicatedFirst.Preload" or (v38 ~= "" or (v39 ~= 0 or (not v40 or (not v42 or #v43 ~= 18)))) then
        return 3, `{v36}/{v41}/{v37}/{v38}/{v39}/{v40}`;
    end;

    local v44 = debug.info(4, "s");

    if v44 then
        return 4, v44;
    end;

    u13 = v43 / 2;

    return "";
end);
local v48 = require(v6(v9, "AssetContainer"));
local success, result = pcall(v48, u11, u12, u13);
local v49 = success ~= true and true or type(result) ~= "function";

if v49 or (v45 ~= true or (v46 ~= "" or v47 ~= nil)) then
    local v50;

    while true do
        v50 = ReplicatedStorage:FindFirstChild("ClientSignals");

        if v50 then
            break;
        end;

        task.wait();
    end;

    local v51;

    while true do
        v51 = v50:FindFirstChild("Inventory");

        if v51 then
            break;
        end;

        task.wait();
    end;

    if v49 then
        v51:FireServer(12, success, (tostring(result)));
    else
        v51:FireServer(14, v45, v46, v47);
    end;

    return;
end;

result("Setup", "\230\140\24\0261\15\212\4\234|\1>T\134\170\"]\28\176\172", ".b\213u ]\204>\143\245\234$C\130\218\1\235_\155\1", function(p52) -- Line: 131
    -- upvalues: LocalPlayer (copy), result (copy)
    if p52 == LocalPlayer.UserId then
        result("Fire", "\230\140\24\0261\15\212\4\234|\1>T\134\170\"]\28\176\172", ".b\213u ]\204>\143\245\234$C\130\218\1\235_\155\1", tick(), os.clock(), p52);

        return;
    end;

    while true do

    end;
end);
task.wait(3);

if not game:IsLoaded() then
    game.Loaded:Wait();
end;

local u53 = v6(ReplicatedStorage, "VMs");
local u54 = v6(ReplicatedStorage, "Armors");
local u55 = v6(ReplicatedStorage, "Attachments");
local u56 = v6(ReplicatedStorage, "Benches");
local u57 = v6(ReplicatedStorage, "Sleeves");
local u58 = v6(ReplicatedStorage, "VFX");
local v59 = v6(ReplicatedStorage, "UIs");
local v60 = v6(ReplicatedStorage, "LoadedPlayerSounds");
local u61 = v6(u10, "Skip");
local u62 = { {
        Name = "UI",
        Assets = {}
    }, {
        Name = "Sounds",
        Assets = {}
    }, {
        Name = "Animations",
        Assets = {}
    }, {
        Name = "Textures",
        Assets = {}
    }, {
        Name = "Meshes",
        Assets = {}
    } };
local u65 = LPH_JIT_MAX(function(p63, p64) -- Line: 166
    -- upvalues: u62 (copy)
    for _, v in pairs(u62) do
        if v.Name == p63 then
            local Assets = v.Assets;

            if not p64 or (p64 == "" or table.find(Assets, p64)) then
                return;
            end;

            table.insert(Assets, p64);

            return;
        end;
    end;
end);

for _, descendant in pairs(v59:GetDescendants()) do
    if descendant:IsA("ImageButton") or descendant:IsA("ImageLabel") then
        u65("UI", descendant.Image);
    end;
end;

for _, descendant in pairs(StarterGui:GetDescendants()) do
    if descendant:IsA("ImageButton") or descendant:IsA("ImageLabel") then
        u65("UI", descendant.Image);
    end;
end;

local Footsteps = v60:FindFirstChild("Footsteps");

for _, v in pairs(Footsteps and Footsteps:GetChildren() or {}) do
    if v:IsA("Sound") then
        u65("Sounds", v.SoundId);
    end;
end;

u65("Sounds", v60:FindFirstChild("Equip"));
u65("Sounds", SoundService:FindFirstChild("Hit"));
u65("Sounds", SoundService:FindFirstChild("HitHead"));

for _, child in pairs(u53:GetChildren()) do
    local LocalAnims = child:FindFirstChild("LocalAnims");

    if LocalAnims then
        for _, child2 in pairs(LocalAnims:GetChildren()) do
            if child2:IsA("Animation") then
                u65("Animations", child2.AnimationId);
            end;
        end;
    end;
end;

LPH_JIT_MAX(function() -- Line: 204
    -- upvalues: u56 (copy), u53 (copy), u54 (copy), u57 (copy), u55 (copy), u58 (copy), u65 (copy)
    local v66 = 0;

    for _, v in {
        u56,
        u53,
        u54,
        u57,
        u55,
        u58
    } do
        for _, descendant in v:GetDescendants() do
            if descendant:IsA("MeshPart") then
                u65("Textures", descendant.TextureID);
                u65("Meshes", descendant.MeshId);
            end;

            v66 = v66 + 1;

            if v66 % 300 == 0 then
                task.wait();
            end;
        end;
    end;
end)();
local u67 = false;
local u71 = task.spawn(LPH_NO_VIRTUALIZE(function() -- Line: 221
    -- upvalues: u62 (copy), u10 (copy), ContentProvider (copy), u67 (ref)
    for _, v in u62 do
        local Name = v.Name;
        local Assets = v.Assets;
        local u68 = 0;
        u10.Load.Text = `Loading {Name} (0/{#Assets})`;
        ContentProvider:PreloadAsync(Assets, function(p69, p70) -- Line: 228
            -- upvalues: u10 (ref), u68 (ref), Name (copy), Assets (copy)
            if not u10.Parent then
                return;
            end;

            u68 = u68 + 1;
            u10.Load.Text = `Loading {Name} ({u68}/{#Assets})`;
        end);
    end;

    u67 = true;
end));
LPH_JIT_MAX(function() -- Line: 239
    -- upvalues: u67 (ref), RunService (copy), UserInputService (copy), u61 (copy), u71 (copy)
    local v72 = 0;

    while not u67 do
        v72 = v72 + task.wait();

        if v72 >= (RunService:IsStudio() and 0.1 or 60) then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService.MouseIconEnabled = true;

            if not u61.Visible then
                u61.Activated:Connect(function() -- Line: 248
                    -- upvalues: u71 (ref), u67 (ref)
                    task.cancel(u71);
                    u67 = true;
                end);
                u61.Visible = true;
            end;
        end;
    end;

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    print("FINISHED PRELOAD IN", v72, "SECONDS");
end)();
u10:Destroy();
result("Fire", "\230\140\24\0261\15\212\4\234|\1>T\134\170\"]\28\176\172", ".b\213u ]\204>\143\245\234$C\130\218\1\235_\155\1", tick(), os.clock());
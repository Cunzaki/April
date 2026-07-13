-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

if (not (LPH_OBFUSCATED)) then
    LPH_OBFUSCATED = false;
    function LPH_NO_VIRTUALIZE(...)
        --[[
          line: 22
        ]]
        return ...;
    end;
    function LPH_JIT_MAX(...)
        --[[
          line: 23
        ]]
        return ...;
    end;
end;
_ = math.random();
local Players_1 = game:GetService("Players");
local ReplicatedFirst_1 = game:GetService("ReplicatedFirst");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local ContentProvider_upv_1 = game:GetService("ContentProvider");
local StarterGui_1 = game:GetService("StarterGui");
local SoundService_1 = game:GetService("SoundService");
local RunService_upv_1 = game:GetService("RunService");
local UserInputService_upv_1 = game:GetService("UserInputService");
local _ = game:GetService("Stats");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local v1 = LPH_JIT_MAX(
    function(a1, a2, a3)
        --[[
          line: 44
        ]]
        local v2 = 0;
        while (true) do
            local v3;
            if (v2 >= (a3 or math.huge)) then
                break;
            end;
            v3 = a1:FindFirstChild(a2);
            if (not (v3)) then
                v2 = v2 + task.wait(0.1);
                continue;
            end;
            return v3;
        end;
    end
);
local v4 = v1(script, "LoadingScreen");
local v5 = v1(LocalPlayer_upv_1, "PlayerGui");
local v6 = v1(ReplicatedStorage_1, "Modules");
local u1 = v4:Clone();
u1.Parent = v5;
ReplicatedFirst_1:RemoveDefaultLoadingScreen();
local u2 = nil;
local u3 = nil;
local u4 = nil;
local success_1, v7, v8 = pcall(
    function()
        --[[
          line: 67
          upvalues:
            u2 (ref, index: 1)
            u3 (ref, index: 2)
            u4 (ref, index: 3)
        ]]
        local v9, v10, v11, v12, v13, v14 = debug.info(0, "sfnal\000");
        local v15, v16 = string.match(("%*"):format(v10), "(function: )(%w+)");
        if (v9 == "[C]" and v14 == -1 and v11 == "info" and v12 == 0 and v13 and v15) then
            local v17 = nil;
            if (#v16 == 18) then
                u2 = v16 / 2;
                local v17, v18, v19, v20, v21, v22 = debug.info(1, "sfnal\000");
                if (v17 == "ReplicatedFirst.Preload" and v19 == "" and v20 == 0 and not (v21) and string.match(("%*"):format(v18), "(function: )(%w+)")) then
                    local v17, v24, v25, v26, v27, v28 = debug.info(2, "sfnal\000");
                    local v17, v29 = string.match(("%*"):format(v24), "(function: )(%w+)");
                    if (v17 == "[C]" and v28 == -1 and v25 == "pcall" and v26 == 0 and v27 and v17 and #v29 == 18) then
                        u3 = v29 / 2;
                        v17, v18, v19, v20, v21, v22 = debug.info(3, "sfnal\000");
                        local v17, v31 = string.match(("%*"):format(v18), "(function: )(%w+)");
                        if (v17 == "ReplicatedFirst.Preload" and v19 == "" and v20 == 0 and v21 and v17 and #v31 == 18) then
                            v17 = debug.info(4, "s");
                            if (v17) then
                                return 4, v17;
                            end;
                            u4 = v31 / 2;
                            return "";
                        end;
                        return 3, (("%*/%*/%*/%*/%*/%*"):format(v17, v22, v18, v19, v20, v21));
                    end;
                    return 2, (("%*/%*/%*/%*/%*/%*"):format(v17, v28, v24, v25, v26, v27));
                end;
                return 1, (("%*/%*/%*/%*/%*/%*"):format(v17, v22, v18, v19, v20, v21));
            end;
        end;
        return 0, (("%*/%*/%*/%*/%*/%*"):format(v9, v14, v10, v11, v12, v13));
    end
);
local success_2, u5 = pcall(require(v1(v6, "AssetContainer")), u2, u3, u4);
local v32 = true;
if (success_2 == true) then
    v32 = type(u5) ~= "function";
end;
if (not v32 and success_1 == true and v7 == "" and v8 == nil) then
    u5(
        "Setup",
        "\230\140\024\0261\015\212\004\234|\001>T\134\170\"]\028\176\172",
        ".b\213u ]\204>\143\245\234$C\130\218\001\235_\155\001",
        function(a1)
            --[[
              line: 131
              upvalues:
                LocalPlayer_upv_1 (copy, index: 1)
                u5 (copy, index: 2)
            ]]
            if (a1 ~= LocalPlayer_upv_1.UserId) then
                --[[ goto label_2 ]]--
            end;
            u5("Fire", "\230\140\024\0261\015\212\004\234|\001>T\134\170\"]\028\176\172", ".b\213u ]\204>\143\245\234$C\130\218\001\235_\155\001", tick(), os.clock(), a1);
        end
    );
    task.wait(3);
    if (not (game:IsLoaded())) then
        game.Loaded:Wait();
    end;
    local u6 = v1(ReplicatedStorage_1, "VMs");
    local u7 = v1(ReplicatedStorage_1, "Armors");
    local u8 = v1(ReplicatedStorage_1, "Attachments");
    local u9 = v1(ReplicatedStorage_1, "Benches");
    local u10 = v1(ReplicatedStorage_1, "Sleeves");
    local u11 = v1(ReplicatedStorage_1, "VFX");
    local v33 = v1(ReplicatedStorage_1, "UIs");
    local v34 = v1(ReplicatedStorage_1, "LoadedPlayerSounds");
    local u12 = v1(u1, "Skip");
    local tbl_upv_1 = {{Assets = {}}, {Assets = {}}, {Assets = {}}, {Assets = {}}, {Assets = {}}};
    local u13 = LPH_JIT_MAX(
        function(a1, a2)
            --[[
              line: 166
              upvalues:
                tbl_upv_1 (copy, index: 1)
            ]]
            for _, value_1 in pairs(tbl_upv_1) do
                local v35 = nil;
                if (value_1.Name == a1) then
                    v35 = value_1.Assets;
                    if (a2 and a2 ~= "" and not (table.find(v35, a2))) then
                        table.insert(v35, a2);
                        return;
                    end;
                    return;
                end;
            end;
        end
    );
    for v43, value_2 in pairs(v33:GetDescendants()) do
        if (value_2:IsA("ImageButton") or value_2:IsA("ImageLabel")) then
            u13("UI", value_2.Image);
        end;
    end;
    for v44, value_3 in pairs(StarterGui_1:GetDescendants()) do
        if (value_3:IsA("ImageButton") or value_3:IsA("ImageLabel")) then
            u13("UI", value_3.Image);
        end;
    end;
    local Footsteps_1 = v34:FindFirstChild("Footsteps");
    local v36 = (Footsteps_1 and (Footsteps_1:GetChildren())) or {};
    for v45, value_4 in pairs(v36) do
        if (value_4:IsA("Sound")) then
            u13("Sounds", value_4.SoundId);
        end;
    end;
    u13("Sounds", v34:FindFirstChild("Equip"));
    u13("Sounds", SoundService_1:FindFirstChild("Hit"));
    u13("Sounds", SoundService_1:FindFirstChild("HitHead"));
    local v46 = nil;
    local v47 = nil;
    local v37 = nil;
    for v48, value_5 in pairs(u6:GetChildren()) do
        v37 = value_5:FindFirstChild("LocalAnims");
        if (not (v37)) then
            continue;
        end;
        for v49, value_6 in pairs(v37:GetChildren()) do
            if (value_6:IsA("Animation")) then
                u13("Animations", value_6.AnimationId);
            end;
        end;
    end;
    LPH_JIT_MAX(
        function()
            --[[
              line: 204
              upvalues:
                u9 (copy, index: 1)
                u6 (copy, index: 2)
                u7 (copy, index: 3)
                u10 (copy, index: 4)
                u8 (copy, index: 5)
                u11 (copy, index: 6)
                u13 (copy, index: 7)
            ]]
            local v38 = 0;
            for _, value_7 in {u9, u6, u7, u10, u8, u11} do
                for v39, value_8 in value_7:GetDescendants() do
                    if (value_8:IsA("MeshPart")) then
                        u13("Textures", value_8.TextureID);
                        u13("Meshes", value_8.MeshId);
                    end;
                    v38 = v38 + 1;
                    if (v38 % 300 == 0) then
                        task.wait();
                    end;
                end;
            end;
        end
    )();
    local u14 = false;
    local u15 = task.spawn(
        LPH_NO_VIRTUALIZE(
            function()
                --[[
                  line: 221
                  upvalues:
                    tbl_upv_1 (copy, index: 1)
                    u1 (copy, index: 2)
                    ContentProvider_upv_1 (copy, index: 3)
                    u14 (ref,  index: 4)
                ]]
                local Name_upv_1 = nil;
                local Assets_upv_1 = nil;
                local u16 = nil;
                for _, value_9 in tbl_upv_1 do
                    Name_upv_1 = value_9.Name;
                    Assets_upv_1 = value_9.Assets;
                    u16 = 0;
                    u1.Load.Text = ("Loading %* (0/%*)"):format(Name_upv_1, #Assets_upv_1);
                    ContentProvider_upv_1:PreloadAsync(
                        Assets_upv_1,
                        function(a1, a2)
                            --[[
                              line: 228
                              upvalues:
                                u1 (copy, index: 1)
                                u16 (ref,  index: 2)
                                Name_upv_1 (copy, index: 3)
                                Assets_upv_1 (copy, index: 4)
                            ]]
                            if (u1.Parent) then
                                u16 = u16 + 1;
                                u1.Load.Text = ("Loading %* (%*/%*)"):format(Name_upv_1, u16, #Assets_upv_1);
                            end;
                        end
                    );
                end;
                u14 = true;
            end
        )
    );
    LPH_JIT_MAX(
        function()
            --[[
              line: 239
              upvalues:
                u14 (ref,  index: 1)
                RunService_upv_1 (copy, index: 2)
                UserInputService_upv_1 (copy, index: 3)
                u12 (copy, index: 4)
                u15 (copy, index: 5)
            ]]
            local v39 = 0;
            while (not u14) do
                v39 = v39 + task.wait();
                local v40 = ((RunService_upv_1:IsStudio()) and 0.1) or 60;
                if (v39 < v40) then
                    continue;
                end;
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService_upv_1.MouseIconEnabled = true;
                if (not (u12.Visible)) then
                    u12.Activated:Connect(
                        function()
                            --[[
                              line: 248
                              upvalues:
                                u15 (copy, index: 1)
                                u14 (ref,  index: 2)
                            ]]
                            task.cancel(u15);
                            u14 = true;
                        end
                    );
                    u12.Visible = true;
                end;
            end;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
            print("FINISHED PRELOAD IN", v39, "SECONDS");
        end
    )();
    u1:Destroy();
    u5("Fire", "\230\140\024\0261\015\212\004\234|\001>T\134\170\"]\028\176\172", ".b\213u ]\204>\143\245\234$C\130\218\001\235_\155\001", tick(), os.clock());
else
    while (true) do
        local v41;
        v41 = ReplicatedStorage_1:FindFirstChild("ClientSignals");
        if (v41) then
            break;
        end;
        task.wait();
    end;
    while (true) do
        local v42;
        v42 = v41:FindFirstChild("Inventory");
        if (v42) then
            break;
        end;
        task.wait();
    end;
    if (v32) then
        v42:FireServer(12, success_2, (tostring(u5)));
    else
        v42:FireServer(14, success_1, v7, v8);
    end;
end;
-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ServerBuild = game:GetService("ReplicatedStorage"):WaitForChild("Values"):WaitForChild("ServerBuild");

local function _() -- Line: 13
    -- upvalues: ServerBuild (copy)
    return `Fallen Build {ServerBuild.Value}`;
end;

local Parent = script.Parent;
Parent.Text = `Fallen Build {ServerBuild.Value}`;
ServerBuild:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 19
    -- upvalues: Parent (copy), ServerBuild (copy)
    Parent.Text = `Fallen Build {ServerBuild.Value}`;
end);
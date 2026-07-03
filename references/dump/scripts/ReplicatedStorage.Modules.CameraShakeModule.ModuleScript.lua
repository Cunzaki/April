-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local u1 = {};
u1.__index = u1;
local profilebegin = debug.profilebegin;
local profileend = debug.profileend;
local new = CFrame.new;
local Angles = CFrame.Angles;
local rad = math.rad;
local u2 = Vector3.new();
local CameraShakeInstance = require(script.CameraShakeInstance);
local CameraShakeState = CameraShakeInstance.CameraShakeState;
u1.CameraShakeInstance = CameraShakeInstance;
u1.Presets = require(script.CameraShakePresets);

function u1.new(p3, p4) -- Line: 75
    -- upvalues: u2 (copy), u1 (copy)
    local v5 = type(p3) == "number";
    assert(v5, "RenderPriority must be a number (e.g.: Enum.RenderPriority.Camera.Value)");
    local v6 = type(p4) == "function";
    assert(v6, "Callback must be a function");

    return setmetatable({
        _running = false,
        _renderName = "CameraShaker",
        _renderPriority = p3,
        _posAddShake = u2,
        _rotAddShake = u2,
        _camShakeInstances = {},
        _removeInstances = {},
        _callback = p4
    }, u1);
end;

function u1.Start(u7) -- Line: 96
    -- upvalues: profilebegin (copy), profileend (copy)
    if u7._running then
        return;
    end;

    u7._running = true;
    local _callback = u7._callback;
    game:GetService("RunService"):BindToRenderStep(u7._renderName, u7._renderPriority, function(p8) -- Line: 100
        -- upvalues: profilebegin (ref), u7 (copy), profileend (ref), _callback (copy)
        profilebegin("CameraShakerUpdate");
        local v9 = u7:Update(p8);
        profileend();
        _callback(v9);
    end);
end;

function u1.Stop(p10) -- Line: 109
    if not p10._running then
        return;
    end;

    game:GetService("RunService"):UnbindFromRenderStep(p10._renderName);
    p10._running = false;
end;

function u1.Update(p11, p12) -- Line: 116
    -- upvalues: u2 (copy), CameraShakeState (copy), new (copy), Angles (copy), rad (copy)
    local v13 = u2;
    local v14 = u2;
    local _camShakeInstances = p11._camShakeInstances;

    for i = 1, #_camShakeInstances do
        local v15 = _camShakeInstances[i];
        local v16 = v15:GetState();

        if v16 == CameraShakeState.Inactive and v15.DeleteOnInactive then
            p11._removeInstances[#p11._removeInstances + 1] = i;
        elseif v16 ~= CameraShakeState.Inactive then
            v13 = v13 + v15:UpdateShake(p12) * v15.PositionInfluence;
            v14 = v14 + v15:UpdateShake(p12) * v15.RotationInfluence;
        end;
    end;

    for i = #p11._removeInstances, 1, -1 do
        table.remove(_camShakeInstances, p11._removeInstances[i]);
        p11._removeInstances[i] = nil;
    end;

    return new(v13) * Angles(0, rad(v14.Y), 0) * Angles(rad(v14.X), 0, (rad(v14.Z)));
end;

function u1.Shake(p17, p18) -- Line: 152
    local v19;

    if type(p18) == "table" then
        v19 = p18._camShakeInstance;
    else
        v19 = false;
    end;

    assert(v19, "ShakeInstance must be of type CameraShakeInstance");
    p17._camShakeInstances[#p17._camShakeInstances + 1] = p18;

    return p18;
end;

function u1.ShakeSustain(p20, p21) -- Line: 159
    local v22;

    if type(p21) == "table" then
        v22 = p21._camShakeInstance;
    else
        v22 = false;
    end;

    assert(v22, "ShakeInstance must be of type CameraShakeInstance");
    p20._camShakeInstances[#p20._camShakeInstances + 1] = p21;
    p21:StartFadeIn(p21.fadeInDuration);

    return p21;
end;

function u1.ShakeOnce(p23, p24, p25, p26, p27, p28, p29) -- Line: 167
    -- upvalues: CameraShakeInstance (copy)
    local v30 = CameraShakeInstance.new(p24, p25, p26, p27);
    v30.PositionInfluence = typeof(p28) == "Vector3" and p28 and p28 or Vector3.new(0.15, 0.15, 0.15);
    v30.RotationInfluence = typeof(p29) == "Vector3" and p29 and p29 or Vector3.new(1, 1, 1);
    p23._camShakeInstances[#p23._camShakeInstances + 1] = v30;

    return v30;
end;

function u1.StartShake(p31, p32, p33, p34, p35, p36) -- Line: 176
    -- upvalues: CameraShakeInstance (copy)
    local v37 = CameraShakeInstance.new(p32, p33, p34);
    v37.PositionInfluence = typeof(p35) == "Vector3" and p35 and p35 or Vector3.new(0.15, 0.15, 0.15);
    v37.RotationInfluence = typeof(p36) == "Vector3" and p36 and p36 or Vector3.new(1, 1, 1);
    v37:StartFadeIn(p34);
    p31._camShakeInstances[#p31._camShakeInstances + 1] = v37;

    return v37;
end;

return u1;
-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1.__index = tbl_upv_1;
local profilebegin_upv_1 = debug.profilebegin;
local profileend_upv_1 = debug.profileend;
local new_upv_1 = CFrame.new;
local Angles_upv_1 = CFrame.Angles;
local rad_upv_1 = math.rad;
local u1 = Vector3.new();
local CameraShakeInstance_upv_1 = require(script.CameraShakeInstance);
local CameraShakeState_upv_1 = CameraShakeInstance_upv_1.CameraShakeState;
tbl_upv_1.CameraShakeInstance = CameraShakeInstance_upv_1;
tbl_upv_1.Presets = require(script.CameraShakePresets);
tbl_upv_1.new = function(a1, a2)
    --[[
      name: new
      line: 75
      upvalues:
        u1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    local v1 = type(a1) == "number";
    assert(v1, "RenderPriority must be a number (e.g.: Enum.RenderPriority.Camera.Value)");
    local v2 = type(a2) == "function";
    assert(v2, "Callback must be a function");
    return (setmetatable({_renderPriority = a1, _posAddShake = u1, _rotAddShake = u1, _camShakeInstances = {}, _removeInstances = {}, _callback = a2}, tbl_upv_1));
end;
tbl_upv_1.Start = function(a1)
    --[[
      name: Start
      line: 96
      upvalues:
        profilebegin_upv_1 (copy, index: 1)
        profileend_upv_1 (copy, index: 2)
    ]]
    if (not a1._running) then
        a1._running = true;
        local _callback_upv_1 = a1._callback;
        game:GetService("RunService"):BindToRenderStep(
            a1._renderName,
            a1._renderPriority,
            function(a2)
                --[[
                  line: 100
                  upvalues:
                    profilebegin_upv_1 (copy, index: 1)
                    a1 (copy, index: 2)
                    profileend_upv_1 (copy, index: 3)
                    _callback_upv_1 (copy, index: 4)
                ]]
                profilebegin_upv_1("CameraShakerUpdate");
                local v3 = a1:Update(a2);
                profileend_upv_1();
                _callback_upv_1(v3);
            end
        );
    end;
end;
tbl_upv_1.Stop = function(a1)
    --[[
      name: Stop
      line: 109
    ]]
    if (not a1._running) then
        return;
    end;
    game:GetService("RunService"):UnbindFromRenderStep(a1._renderName);
    a1._running = false;
end;
tbl_upv_1.Update = function(a1, a2)
    --[[
      name: Update
      line: 116
      upvalues:
        u1 (copy, index: 1)
        CameraShakeState_upv_1 (copy, index: 2)
        new_upv_1 (copy, index: 3)
        Angles_upv_1 (copy, index: 4)
        rad_upv_1 (copy, index: 5)
    ]]
    local _camShakeInstances_1 = a1._camShakeInstances;
    for n_1 = 1, #_camShakeInstances_1 do
        local v4 = _camShakeInstances_1[n_1];
        local v5;
        v5 = v4:GetState();
        if (v5 == CameraShakeState_upv_1.Inactive and (v4.DeleteOnInactive)) then
            a1._removeInstances[#a1._removeInstances + 1] = n_1;
        elseif (v5 ~= CameraShakeState_upv_1.Inactive) then
            local _ = v4:UpdateShake(a2);
            local v6 = v4:UpdateShake(a2);
        end;
    end;
    for n_2 = #a1._removeInstances, 1, -1 do
        table.remove(_camShakeInstances_1, a1._removeInstances[n_2]);
        a1._removeInstances[n_2] = nil;
    end;
    return new_upv_1(u1) * Angles_upv_1(0, rad_upv_1(u1.Y), 0) * Angles_upv_1(rad_upv_1(u1.X), 0, rad_upv_1(u1.Z));
end;
tbl_upv_1.Shake = function(a1, a2)
    --[[
      name: Shake
      line: 152
    ]]
    local v6 = false;
    if (type(a2) == "table") then
        v6 = a2._camShakeInstance;
    end;
    assert(v6, "ShakeInstance must be of type CameraShakeInstance");
    a1._camShakeInstances[#a1._camShakeInstances + 1] = a2;
    return a2;
end;
tbl_upv_1.ShakeSustain = function(a1, a2)
    --[[
      name: ShakeSustain
      line: 159
    ]]
    local v7 = false;
    if (type(a2) == "table") then
        v7 = a2._camShakeInstance;
    end;
    assert(v7, "ShakeInstance must be of type CameraShakeInstance");
    a1._camShakeInstances[#a1._camShakeInstances + 1] = a2;
    a2:StartFadeIn(a2.fadeInDuration);
    return a2;
end;
tbl_upv_1.ShakeOnce = function(a1, a2, a3, a4, a5, a6, a7)
    --[[
      name: ShakeOnce
      line: 167
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v8 = CameraShakeInstance_upv_1.new(a2, a3, a4, a5);
    v8.PositionInfluence = typeof(a6) == "Vector3" and a6 or Vector3.new(0.15000000596046448, 0.15000000596046448, 0.15000000596046448);
    v8.RotationInfluence = typeof(a7) == "Vector3" and a7 or Vector3.new(1, 1, 1);
    a1._camShakeInstances[#a1._camShakeInstances + 1] = v8;
    return v8;
end;
tbl_upv_1.StartShake = function(a1, a2, a3, a4, a5, a6)
    --[[
      name: StartShake
      line: 176
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v11 = CameraShakeInstance_upv_1.new(a2, a3, a4);
    v11.PositionInfluence = typeof(a5) == "Vector3" and a5 or Vector3.new(0.15000000596046448, 0.15000000596046448, 0.15000000596046448);
    v11.RotationInfluence = typeof(a6) == "Vector3" and a6 or Vector3.new(1, 1, 1);
    v11:StartFadeIn(a4);
    a1._camShakeInstances[#a1._camShakeInstances + 1] = v11;
    return v11;
end;
return tbl_upv_1;
-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local CameraShakeInstance_upv_1 = require(script.Parent.CameraShakeInstance);
local tbl_upv_1 = {};
tbl_upv_1.Bump = function()
    --[[
      name: Bump
      line: 28
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v1 = CameraShakeInstance_upv_1.new(2.5, 4, 0.1, 0.75);
    v1.PositionInfluence = Vector3.new(0.15000000596046448, 0.15000000596046448, 0.15000000596046448);
    v1.RotationInfluence = Vector3.new(1, 1, 1);
    return v1;
end;
tbl_upv_1.Explosion = function()
    --[[
      name: Explosion
      line: 38
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v2 = CameraShakeInstance_upv_1.new(5, 10, 0, 1.5);
    v2.PositionInfluence = Vector3.new(0.25, 0.25, 0.25);
    v2.RotationInfluence = Vector3.new(4, 1, 1);
    return v2;
end;
tbl_upv_1.Earthquake = function()
    --[[
      name: Earthquake
      line: 48
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v3 = CameraShakeInstance_upv_1.new(0.6, 3.5, 2, 10);
    v3.PositionInfluence = Vector3.new(0.25, 0.25, 0.25);
    v3.RotationInfluence = Vector3.new(1, 1, 4);
    return v3;
end;
tbl_upv_1.BadTrip = function()
    --[[
      name: BadTrip
      line: 58
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v4 = CameraShakeInstance_upv_1.new(10, 0.15, 5, 10);
    v4.PositionInfluence = Vector3.new(0, 0, 0.15000000596046448);
    v4.RotationInfluence = Vector3.new(2, 1, 4);
    return v4;
end;
tbl_upv_1.HandheldCamera = function()
    --[[
      name: HandheldCamera
      line: 68
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v5 = CameraShakeInstance_upv_1.new(1, 0.25, 5, 10);
    v5.PositionInfluence = Vector3.new(0, 0, 0);
    v5.RotationInfluence = Vector3.new(1, 0.5, 0.5);
    return v5;
end;
tbl_upv_1.Vibration = function()
    --[[
      name: Vibration
      line: 78
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v6 = CameraShakeInstance_upv_1.new(0.4, 20, 2, 2);
    v6.PositionInfluence = Vector3.new(0, 0.15000000596046448, 0);
    v6.RotationInfluence = Vector3.new(1.25, 0, 4);
    return v6;
end;
tbl_upv_1.RoughDriving = function()
    --[[
      name: RoughDriving
      line: 88
      upvalues:
        CameraShakeInstance_upv_1 (copy, index: 1)
    ]]
    local v7 = CameraShakeInstance_upv_1.new(1, 2, 1, 1);
    v7.PositionInfluence = Vector3.new(0, 0, 0);
    v7.RotationInfluence = Vector3.new(1, 1, 1);
    return v7;
end;
local tbl_2 = {};
local tbl_3 = {};
tbl_3.__index = function(a1, a2)
    --[[
      name: __index
      line: 100
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v8 = tbl_upv_1[a2];
    if (type(v8) ~= "function") then
        error("No preset found with index \"" .. a2 .. "\"");
    else
        return v8();
    end;
end;
return (setmetatable(tbl_2, tbl_3));
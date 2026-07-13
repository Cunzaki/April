-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1.__index = tbl_upv_1;
local new_upv_1 = Vector3.new;
local noise_upv_1 = math.noise;
tbl_upv_1.CameraShakeState = {};
tbl_upv_1.new = function(a1, a2, a3, a4)
    --[[
      name: new
      line: 30
      upvalues:
        new_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    if (a3 == nil) then
        a3 = 0;
    end;
    if (a4 == nil) then
        a4 = 0;
    end;
    local v1 = type(a1) == "number";
    assert(v1, "Magnitude must be a number");
    local v2 = type(a2) == "number";
    assert(v2, "Roughness must be a number");
    local v3 = type(a3) == "number";
    assert(v3, "FadeInTime must be a number");
    local v4 = type(a4) == "number";
    assert(v4, "FadeOutTime must be a number");
    local tbl_2 = {};
    tbl_2.Magnitude = a1;
    tbl_2.Roughness = a2;
    tbl_2.PositionInfluence = new_upv_1();
    tbl_2.RotationInfluence = new_upv_1();
    tbl_2.fadeOutDuration = a4;
    tbl_2.fadeInDuration = a3;
    tbl_2.sustain = a3 > 0;
    tbl_2.currentFadeTime = ((a3 <= 0) and 1) or 0;
    tbl_2.tick = Random.new():NextNumber(-100, 100);
    return (setmetatable(tbl_2, tbl_upv_1));
end;
tbl_upv_1.UpdateShake = function(a1, a2)
    --[[
      name: UpdateShake
      line: 61
      upvalues:
        noise_upv_1 (copy, index: 1)
        new_upv_1 (copy, index: 2)
    ]]
    local tick_1 = a1.tick;
    local currentFadeTime_1 = a1.currentFadeTime;
    local v5 = new_upv_1(noise_upv_1(tick_1, 0) * 0.5, noise_upv_1(0, tick_1) * 0.5, noise_upv_1(tick_1, tick_1) * 0.5);
    if (a1.fadeInDuration > 0 and a1.sustain) then
        if (currentFadeTime_1 >= 1) then
            if (a1.fadeOutDuration > 0) then
                a1.sustain = false;
            end;
        else
            currentFadeTime_1 = currentFadeTime_1 + a2 / a1.fadeInDuration;
        end;
    end;
    if (not (a1.sustain)) then
        currentFadeTime_1 = currentFadeTime_1 - a2 / a1.fadeOutDuration;
    end;
    if (a1.sustain) then
        a1.tick = tick_1 + ((a2 * a1.Roughness) * a1.roughMod);
    else
        a1.tick = tick_1 + (((a2 * a1.Roughness) * a1.roughMod) * currentFadeTime_1);
    end;
    a1.currentFadeTime = currentFadeTime_1;
    return ((v5 * a1.Magnitude) * a1.magnMod) * currentFadeTime_1;
end;
tbl_upv_1.StartFadeOut = function(a1, a2)
    --[[
      name: StartFadeOut
      line: 97
    ]]
    if (a2 == 0) then
        a1.currentFadeTime = 0;
    end;
    a1.fadeOutDuration = a2;
    a1.fadeInDuration = 0;
    a1.sustain = false;
end;
tbl_upv_1.StartFadeIn = function(a1, a2)
    --[[
      name: StartFadeIn
      line: 107
    ]]
    if (a2 == 0) then
        a1.currentFadeTime = 1;
    end;
    a1.fadeInDuration = a2 or (a1.fadeInDuration);
    a1.fadeOutDuration = 0;
    a1.sustain = true;
end;
tbl_upv_1.GetScaleRoughness = function(a1)
    --[[
      name: GetScaleRoughness
      line: 117
    ]]
    return a1.roughMod;
end;
tbl_upv_1.SetScaleRoughness = function(a1, a2)
    --[[
      name: SetScaleRoughness
      line: 122
    ]]
    a1.roughMod = a2;
end;
tbl_upv_1.GetScaleMagnitude = function(a1)
    --[[
      name: GetScaleMagnitude
      line: 127
    ]]
    return a1.magnMod;
end;
tbl_upv_1.SetScaleMagnitude = function(a1, a2)
    --[[
      name: SetScaleMagnitude
      line: 132
    ]]
    a1.magnMod = a2;
end;
tbl_upv_1.GetNormalizedFadeTime = function(a1)
    --[[
      name: GetNormalizedFadeTime
      line: 137
    ]]
    return a1.currentFadeTime;
end;
tbl_upv_1.IsShaking = function(a1)
    --[[
      name: IsShaking
      line: 142
    ]]
    local v6 = true;
    if (a1.currentFadeTime <= 0) then
        v6 = a1.sustain;
    end;
    return v6;
end;
tbl_upv_1.IsFadingOut = function(a1)
    --[[
      name: IsFadingOut
      line: 147
    ]]
    return not a1.sustain and (a1.currentFadeTime > 0);
end;
tbl_upv_1.IsFadingIn = function(a1)
    --[[
      name: IsFadingIn
      line: 152
    ]]
    local v7 = false;
    if (a1.currentFadeTime < 1) then
        v7 = a1.sustain and (a1.fadeInDuration > 0);
    end;
    return v7;
end;
tbl_upv_1.GetState = function(a1)
    --[[
      name: GetState
      line: 157
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    if (a1:IsFadingIn()) then
        return tbl_upv_1.CameraShakeState.FadingIn;
    end;
    if (a1:IsFadingOut()) then
        return tbl_upv_1.CameraShakeState.FadingOut;
    elseif (a1:IsShaking()) then
        return tbl_upv_1.CameraShakeState.Sustained;
    else
        return tbl_upv_1.CameraShakeState.Inactive;
    end;
end;
return tbl_upv_1;
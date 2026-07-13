-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1.new = function(a1)
    --[[
      name: new
      line: 42
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v1 = a1 or 0;
    return (setmetatable({_time0 = tick(), _position0 = v1, _velocity0 = 0 * v1, _target = v1}, tbl_upv_1));
end;
tbl_upv_1.Impulse = function(a1, a2)
    --[[
      name: Impulse
      line: 57
    ]]
    a1.Velocity = a1.Velocity + a2;
end;
tbl_upv_1.TimeSkip = function(a1, a2)
    --[[
      name: TimeSkip
      line: 63
    ]]
    local time_1 = tick();
    local v2, v3 = a1:_positionVelocity(time_1 + a2);
    a1._position0 = v2;
    a1._velocity0 = v3;
    a1._time0 = time_1;
end;
tbl_upv_1.__index = function(a1, a2)
    --[[
      name: __index
      line: 71
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    if (tbl_upv_1[a2]) then
        return tbl_upv_1[a2];
    else
        if (a2 ~= "Value" and a2 ~= "Position" and a2 ~= "p") then
            if (a2 ~= "Velocity" and a2 ~= "v") then
                if (a2 ~= "Target" and a2 ~= "t") then
                    if (a2 ~= "Damper" and a2 ~= "d") then
                        if (a2 ~= "Speed" and a2 ~= "s") then
                            error(("%q is not a valid member of Spring"):format(tostring(a2)), 2);
                            return;
                        end;
                        return a1._speed;
                    end;
                    return a1._damper;
                end;
                return a1._target;
            end;
            local _, v4 = a1:_positionVelocity(tick());
            return v4;
        end;
        local v5, _ = a1:_positionVelocity(tick());
        return v5;
    end;
end;
tbl_upv_1.__newindex = function(a1, a2, a3)
    --[[
      name: __newindex
      line: 91
    ]]
    local time_2 = tick();
    if (a2 == "Value" or a2 == "Position" or a2 == "p") then
        local _, v6 = a1:_positionVelocity(time_2);
        a1._position0 = a3;
        a1._velocity0 = v6;
    elseif (a2 == "Velocity" or a2 == "v") then
        local v7, _ = a1:_positionVelocity(time_2);
        a1._position0 = v7;
        a1._velocity0 = a3;
    elseif (a2 == "Target" or a2 == "t") then
        local v8, v9 = a1:_positionVelocity(time_2);
        a1._position0 = v8;
        a1._velocity0 = v9;
        a1._target = a3;
    elseif (a2 == "Damper" or a2 == "d") then
        local v10, v11 = a1:_positionVelocity(time_2);
        a1._position0 = v10;
        a1._velocity0 = v11;
        a1._damper = math.clamp(a3, 0, 1);
    elseif (a2 == "Speed" or a2 == "s") then
        local v12, v13 = a1:_positionVelocity(time_2);
        a1._position0 = v12;
        a1._velocity0 = v13;
        a1._speed = math.max(a3, 0);
    else
        error(("%q is not a valid member of Spring"):format(tostring(a2)), 2);
    end;
    a1._time0 = time_2;
end;
tbl_upv_1._positionVelocity = function(a1, a2)
    --[[
      name: _positionVelocity
      line: 124
    ]]
    local _position0_1 = a1._position0;
    local _velocity0_1 = a1._velocity0;
    local _target_1 = a1._target;
    local _damper_1 = a1._damper;
    local _speed_1 = a1._speed;
    local v14 = _speed_1 * (a2 - a1._time0);
    local v15 = _damper_1 * _damper_1;
    local v16, v17, v18 = nil, nil, nil;
    if (v15 >= 1) then
        if (v15 ~= 1) then
            v16 = math.sqrt(v15 - 1);
            local v19 = math.exp((-_damper_1 + v16) * v14) / (2 * v16);
            local v20 = math.exp((-_damper_1 - v16) * v14) / (2 * v16);
            v17, v18 = v19 + v20, v19 - v20;
        else
            v16 = 1;
            local v21 = math.exp(-_damper_1 * v14) / v16;
            v17, v18 = v21, v21 * v14;
        end;
    else
        v16 = math.sqrt(1 - v15);
        local v22 = math.exp(-_damper_1 * v14) / v16;
        v17 = v22 * math.cos(v16 * v14);
        v18 = v22 * math.sin(v16 * v14);
    end;
    return ((((v16 * v17) + (_damper_1 * v18)) * _position0_1) + ((1 - ((v16 * v17) + (_damper_1 * v18))) * _target_1)) + ((v18 / _speed_1) * _velocity0_1), (((-_speed_1 * v18) * _position0_1) + ((_speed_1 * v18) * _target_1)) + (((v16 * v17) - (_damper_1 * v18)) * _velocity0_1);
end;
return tbl_upv_1;
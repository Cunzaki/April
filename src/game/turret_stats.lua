--[[ Fallen turret ranges — from dump/ReplicatedStorage.Modules.BenchInfo + RayParts layout. ]]

local M = {}

-- Activation / targeting range (what the ring should represent).
M.ACTIVATION_RANGE = {
    ["Auto Turret"] = 100,      -- BenchInfo TypeArguments.TargetRange
    ["Shotgun Turret"] = 110,   -- longest RayPart offset in Benches.Shotgun Turret.Default
}

-- Projectile travel (for reference / future use).
M.BULLET_RANGE = {
    ["Auto Turret"] = 150,      -- BenchInfo TypeArguments.BulletRange
    ["Shotgun Turret"] = 14.25, -- BenchInfo TypeArguments.BulletRange
}

M.DAMAGE_RANGE = {
    ["Auto Turret"] = { 85, 150 },
    ["Shotgun Turret"] = { 9, 25 },
}

function M.activation_range(name)
    return M.ACTIVATION_RANGE[name]
end

return M

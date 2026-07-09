local M = {}

M.ACTIVATION_RANGE = {
    ["Auto Turret"] = 100,
    ["Shotgun Turret"] = 110,
}

M.BULLET_RANGE = {
    ["Auto Turret"] = 150,
    ["Shotgun Turret"] = 14.25,
}

M.DAMAGE_RANGE = {
    ["Auto Turret"] = { 85, 150 },
    ["Shotgun Turret"] = { 9, 25 },
}

function M.activation_range(name)
    return M.ACTIVATION_RANGE[name]
end

return M

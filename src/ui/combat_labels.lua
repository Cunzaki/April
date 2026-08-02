-- Label lists shared by the custom UI catalog (no feature / menu deps).
local M = {}

M.TP_METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

-- Aim At multicombo: Players + per-NPC kinds (matches NPC ESP type list).
M.AIM_AT_OPTIONS = {
    "Players",
    "Soldier",
    "Bruno",
    "Boris",
    "Brutus",
    "Attack Heli",
    "BTR",
    "Diver Dave",
    "Pilot Pete",
}

-- Defaults: players on, NPC types off.
M.AIM_AT_DEFAULTS = { true, false, false, false, false, false, false, false, false }

return M

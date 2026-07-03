local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_recoil_enabled"

-- Mouse pull per frame at 100% (legacy Fallen used 0–10 sliders)
local MAX_PULL = 5.0

local RECOIL_GUNS = {
    { name = "Salvaged Pump Action" },
    { name = "Salvaged Skorpion" },
    { name = "Salvaged SMG" },
    { name = "Salvaged AK74u" },
    { name = "Salvaged AK47" },
    { name = "Salvaged AK4" },
    { name = "Salvaged M14" },
    { name = "Military M4A1" },
    { name = "Military MP7" },
    { name = "Military PKM" },
    { name = "Military Barrett" },
    { name = "Bruno's M4A1" },
}

local lookup = {}
for _, gun in ipairs(RECOIL_GUNS) do
    lookup[gun.name] = gun
end

local acc_y = 0
local acc_x = 0

local function pct_to_pull(pct)
    return (math.max(0, math.min(100, pct or 0)) / 100) * MAX_PULL
end

local function is_firing()
    if not input or not input.is_key_down then return false end
    -- Legacy Fallen: compensate while ADS (RMB) + firing (LMB)
    return input.is_key_down(0x01) and input.is_key_down(0x02)
end

local function reset_accumulators()
    acc_y = 0
    acc_x = 0
end

local function get_strength(weapon_name)
    if not weapon_name or not lookup[weapon_name] then return 0, 0 end

    local use_global = settings.bool("april_recoil_use_global", false)
    local pct
    if use_global then
        pct = settings.num("april_recoil_global", 0)
    else
        pct = settings.num(weapons.slug(weapon_name), 0)
    end

    local pull = pct_to_pull(pct)
    return pull, 0
end

function M.register_menu()
    local T, G = menu_util.group("Recoil Control")

    menu.add_checkbox(T, G, P, "Enable Recoil Control", false, { key = 0 })
    menu.add_label(T, G, "Mouse compensation while ADS + firing (safe — does not patch ToolInfo).")
    menu.add_label(T, G, "Hold RMB + LMB. 100% = max pull down per frame.")
    menu.add_slider_int(T, G, "april_recoil_global", "Global Strength %", 0, 100, 0, { parent = P })
    menu.add_checkbox(T, G, "april_recoil_use_global", "Use Global For All Guns", true, { parent = P })
    menu.add_separator(T, G)

    for _, gun in ipairs(RECOIL_GUNS) do
        local id = weapons.slug(gun.name)
        menu.add_slider_int(T, G, id, gun.name .. " %", 0, 100, 0, { parent = P })
    end
end

function M.update(dt)
    if not settings.bool(P, false) then
        reset_accumulators()
        return
    end

    if not is_firing() then
        reset_accumulators()
        return
    end

    local held = weapons.get_held_weapon_name()
    if not held then
        reset_accumulators()
        return
    end

    local amount_y, amount_x = get_strength(held)
    if amount_y <= 0 and amount_x <= 0 then
        reset_accumulators()
        return
    end

    if not input or not input.move_mouse then return end

    acc_y = acc_y + amount_y
    local move_y = math.floor(acc_y)
    if move_y > 0 then
        acc_y = acc_y - move_y
    end

    local sign_x = amount_x >= 0 and 1 or -1
    acc_x = acc_x + math.abs(amount_x)
    local move_x = math.floor(acc_x) * sign_x
    if math.abs(move_x) > 0 then
        acc_x = acc_x - math.abs(move_x)
    end

    if move_x ~= 0 or move_y ~= 0 then
        input.move_mouse(move_x, move_y)
    end
end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw or not draw.text then return end

    local held = weapons.get_held_weapon_name()
    if not held then return end

    local y, _ = get_strength(held)
    local pct = settings.bool("april_recoil_use_global", false)
        and settings.num("april_recoil_global", 0)
        or settings.num(weapons.slug(held), 0)

    draw.text(10, 24, string.format("RC: %s  %d%%  (%.1f px/f)", held, pct, y), { 0.5, 1, 0.7, 0.9 }, 12)
end

return M

local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_recoil_enabled"
local last_apply = 0

function M.register_menu()
    local T, G = menu_util.bind("recoil")
    weapons.load()

    menu.add_checkbox(T, G, P, "Enable Recoil Reduction", false, { key = 0 })
    menu.add_label(T, G, "Scales ToolInfo recoil client-side (same table the game uses).")
    menu.add_label(T, G, "0% = stock  |  100% = no kick. Server spread unchanged.")
    menu.add_slider_int(T, G, "april_recoil_global", "Global Reduction %", 0, 100, 0, { parent = P })
    menu.add_checkbox(T, G, "april_recoil_use_global", "Apply Global To All Guns", false, { parent = P })
    menu.add_separator(T, G)

    local names = weapons.recoil_weapon_names()
    for _, name in ipairs(names) do
        local id = weapons.slug(name)
        menu.add_slider_int(T, G, id, name .. " %", 0, 100, 0, { parent = P })
        if menu.set_callback then
            menu.set_callback(id, function()
                M.sync_patches()
            end)
        end
    end

    if menu.set_callback then
        menu.set_callback("april_recoil_global", function() M.sync_patches() end)
        menu.set_callback("april_recoil_use_global", function() M.sync_patches() end)
        menu.set_callback(P, function() M.sync_patches() end)
    end
end

function M.sync_patches()
    if not settings.bool(P, false) then
        for _, name in ipairs(weapons.recoil_weapon_names()) do
            weapons.set_recoil_reduction(name, 0)
        end
        return
    end

    local global_pct = settings.num("april_recoil_global", 0)
    local use_global = settings.bool("april_recoil_use_global", false)

    for _, name in ipairs(weapons.recoil_weapon_names()) do
        local pct = global_pct
        if not use_global then
            local id = weapons.slug(name)
            pct = settings.num(id, 0)
        end
        weapons.set_recoil_reduction(name, pct)
    end
end

function M.update(dt)
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - last_apply > 500 then
        last_apply = now
        M.sync_patches()
    end
end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw or not draw.text then return end
    local held = weapons.get_held_weapon_name()
    if held then
        local id = weapons.slug(held)
        local pct = settings.bool("april_recoil_use_global", false)
            and settings.num("april_recoil_global", 0)
            or settings.num(id, 0)
        draw.text(10, 24, "Weapon: " .. held .. "  RC: " .. pct .. "%", { 0.5, 1, 0.7, 0.9 }, 12)
    end
end

return M

local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local env = April.require("core.env")

local M = {}

function M.register_menu()
    menu.add_group("Radar", "Map")
    menu.add_checkbox("Radar", "Map", "april_map_enabled", "Minimap Shell", false)
    menu.add_slider_int("Radar", "Map", "april_map_size", "Size", 120, 500, 220)
    menu.add_hotkey("Radar", "Map", "april_map_key", "Toggle Key", 0x28)
end

local function map_open()
    if not settings.bool("april_map_enabled", false) then return false end
    local vk = settings.num("april_map_key", 0x28)
    return input and input.is_key_down and input.is_key_down(vk)
end

function M.update(dt) end

function M.draw()
    if not map_open() then return end
    local size = settings.num("april_map_size", 220)
    local sw, sh = draw_util.screen_size()
    local x, y = sw - size - 20, 20

    if draw and draw.rect then
        draw.rect(x, y, size, size, { 0.1, 0.1, 0.1, 0.85 }, 4, 1)
    end
    if draw and draw.rect_filled then
        draw.rect_filled(x + 2, y + 2, size - 4, size - 4, { 0.05, 0.12, 0.08, 0.9 }, 2)
    end

    local cx, cy = x + size * 0.5, y + size * 0.5
    draw_util.circle(cx, cy, 4, { 0.2, 1, 0.4, 1 }, true)
    draw_util.text_centered(x + size * 0.5, y + size - 14, "Tactical Map (WIP)", { 1, 1, 1, 0.7 }, 11)

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if not p.is_local and p.is_alive and p.position then
                local lp = env.get_local_player()
                if lp and lp.position then
                    local dx = (p.position.x - lp.position.x) * 0.15
                    local dz = (p.position.z - lp.position.z) * 0.15
                    local px = math_util.clamp(cx + dx, x + 6, x + size - 6)
                    local py = math_util.clamp(cy + dz, y + 6, y + size - 6)
                    draw_util.circle(px, py, 3, { 1, 0.3, 0.3, 1 }, true)
                end
            end
        end
    end
end

return M

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")

local M = {}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

function M.save_slot(slot)
    slot = slot or 1
    local keys = {}
    -- collect known april_ ids from menu if possible; fallback list
    local CONFIG_KEYS = {
        "april_aimbot_enabled", "april_aimbot_fov", "april_aimbot_smooth",
        "april_esp_enabled", "april_world_enabled", "april_loot_enabled",
        "april_npc_enabled", "april_base_enabled", "april_noclip_enabled",
        "april_crosshair_enabled", "april_map_enabled",
    }
    local lines = {}
    for _, id in ipairs(CONFIG_KEYS) do
        if menu and menu.get then
            local v = menu.get(id)
            if v ~= nil then table.insert(lines, id .. "=" .. tostring(v)) end
        end
    end
    local path = M.get_config_path("April_Slot_" .. slot .. ".txt")
    local f = io.open(path, "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    print("[April] Config saved slot " .. slot)
    return true
end

function M.load_slot(slot)
    slot = slot or 1
    local path = M.get_config_path("April_Slot_" .. slot .. ".txt")
    local f = io.open(path, "r")
    if not f then return false end
    for line in f:lines() do
        local id, val = line:match("^([^=]+)=(.+)$")
        if id and val and menu and menu.set then
            if val == "true" then menu.set(id, true)
            elseif val == "false" then menu.set(id, false)
            else
                local n = tonumber(val)
                menu.set(id, n or val)
            end
            April.require("core.settings").invalidate()
        end
    end
    f:close()
    print("[April] Config loaded slot " .. slot)
    return true
end

function M.register_menu()
    local T, G = menu_util.bind("config")
    menu.add_label(T, G, "April v3 — Fallen Survival")
    menu.add_button(T, G, "april_cfg_save_1", "Save Config Slot 1", function() M.save_slot(1) end)
    menu.add_button(T, G, "april_cfg_load_1", "Load Config Slot 1", function() M.load_slot(1) end)
    menu.add_button(T, G, "april_cfg_save_2", "Save Config Slot 2", function() M.save_slot(2) end)
    menu.add_button(T, G, "april_cfg_load_2", "Load Config Slot 2", function() M.load_slot(2) end)
    menu.add_separator(T, G)
    menu.add_checkbox(T, G, "april_debug_overlay", "Debug Overlay", false)
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_debug_overlay", false) then return end
    if not draw or not draw.text then return end
    local cache = April.require("core.cache")
    local y = 40
    draw.text(10, y, "April v3 " .. (April.version or "?"), { 0.4, 1, 0.6, 1 }, 14)
    y = y + 16
    draw.text(10, y, "Players: " .. #cache.players, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "World: " .. #cache.world .. "  Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "NPCs: " .. #(cache.npcs or {}) .. "  Base: " .. #(cache.base or {}), { 1, 1, 1, 0.9 }, 12)
end

return M

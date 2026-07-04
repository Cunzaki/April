local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")

local M = {}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

local function base_config_keys()
    return {
        "april_aimbot_enabled", "april_aimbot_fov", "april_aimbot_smooth",
        "april_esp_enabled", "april_world_enabled", "april_loot_enabled",
        "april_npc_enabled", "april_base_enabled", "april_noclip_enabled",
        "april_crosshair_enabled", "april_map_enabled", "april_gunmods_enabled",
        "april_gm_auto_detect", "april_gm_per_weapon", "april_gm_profile",
        "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult", "april_gm_range", "april_gm_range_mult",
    }
end

function M.save_slot(slot)
    slot = slot or 1
    local lines = {}

    for _, id in ipairs(base_config_keys()) do
        if menu and menu.get then
            local v = menu.get(id)
            if v ~= nil then table.insert(lines, id .. "=" .. tostring(v)) end
        end
    end

    for _, pair in ipairs(profiles.export_config_values()) do
        table.insert(lines, pair[1] .. "=" .. pair[2])
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
        if id and val then
            if profiles.import_config_value(id, val) then
                -- stored in profile table
            elseif menu and menu.set then
                if val == "true" then menu.set(id, true)
                elseif val == "false" then menu.set(id, false)
                else
                    local n = tonumber(val)
                    menu.set(id, n or val)
                end
                April.require("core.settings").invalidate()
            end
        end
    end

    f:close()

    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        local weapons = April.require("game.weapons")
        local idx = settings.num("april_gm_profile", 0)
        gun_mods._editing = profiles.name_at_index(idx)
        profiles.sync_profile_to_editor(gun_mods._editing)
        gun_mods._apply_dirty = true
        if gun_mods.on_weapon_changed then
            gun_mods.on_weapon_changed(weapons._last_held)
        end
    end)

    print("[April] Config loaded slot " .. slot)
    return true
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.CONFIG)
    menu.add_label(T, G.CONFIG, "April v3 — Fallen Survival")
    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_separator(T, G.CONFIG)
    menu.add_button(T, G.CONFIG, "april_cfg_save_1", "Save Config Slot 1", function() M.save_slot(1) end)
    menu.add_button(T, G.CONFIG, "april_cfg_load_1", "Load Config Slot 1", function() M.load_slot(1) end)
    menu.add_separator(T, G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_debug_overlay", "Debug Overlay", false)
    menu.add_button(T, G.CONFIG, "april_debug_clear", "Clear Error Log", function()
        April.require("core.debug").reset_errors()
        print("[April] Error log cleared")
    end)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        local ok = April.require("game.bootstrap").force_reload()
        print("[April] Module reload: " .. (ok and "OK" or "waiting"))
    end)
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_debug_overlay", false) then return end
    if not draw or not draw.text then return end
    local cache = April.require("core.cache")
    local dbg = April.require("core.debug")
    local bootstrap = April.require("game.bootstrap")
    local gc = April.require("game.gc_weapon_mods")
    local stats = dbg.stats()
    local y = 40
    draw.text(10, y, "April v3 " .. (April.version or "?"), { 0.4, 1, 0.6, 1 }, 14)
    y = y + 16
    draw.text(10, y, "ToolInfo: " .. (bootstrap.is_ready() and "OK" or "waiting...") ..
        "  " .. gc.status_text(), { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    if bootstrap.get_status then
        draw.text(10, y, bootstrap.get_status(), { 0.85, 0.85, 0.85, 0.85 }, 11)
        y = y + 14
    end
    draw.text(10, y, "Frames: " .. stats.frames, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "Players: " .. #cache.players, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "World: " .. #cache.world .. "  Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    local caps = April.require("core.capabilities")
    draw.text(10, y, caps.summary(), { 0.6, 0.85, 1, 0.85 }, 10)
end

return M

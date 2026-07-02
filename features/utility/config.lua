local settings = April.require("core.settings")

local M = {}
local CONFIG_KEYS = {
    "april_aimbot_enabled", "april_aimbot_fov", "april_esp_enabled",
    "april_world_enabled", "april_loot_enabled", "april_noclip_enabled",
}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

function M.save_slot(slot)
    slot = slot or 1
    local lines = {}
    for _, id in ipairs(CONFIG_KEYS) do
        local v = menu.get(id)
        table.insert(lines, id .. "=" .. tostring(v))
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
    menu.add_group("Settings", "Config")
    menu.add_label("Settings", "Config", "April v3 — modular rewrite")
    menu.add_button("Settings", "Config", "april_cfg_save", "Save Slot 1", function()
        M.save_slot(1)
    end)
    menu.add_button("Settings", "Config", "april_cfg_load", "Load Slot 1", function()
        M.load_slot(1)
    end)
    menu.add_group("Settings", "Debug")
    menu.add_checkbox("Settings", "Debug", "april_debug_overlay", "Debug Overlay", false)
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
    draw.text(10, y, "World: " .. #cache.world .. " Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    local st = settings.stats()
    draw.text(10, y, "Settings reads: " .. (st.reads or 0), { 1, 1, 1, 0.9 }, 12)
end

return M

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local store = April.require("core.config_store")
local notify = April.require("core.notify")

local M = {}

local function invalidate_config_catalog()
    local ok, catalog = pcall(April.require, "ui.catalog")
    if ok and catalog and catalog.invalidate then catalog.invalidate("config") end
end

local function profile_label()
    return settings.str("april_cfg_profile_name", "Default")
end

local function selected_stem()
    return store.active_stem()
end

function M.get_config_path(name)
    return store.get_config_path(name)
end

function M.save_config(name)
    store.migrate_legacy()
    local ok, stem, path = store.save_config(name or profile_label())
    if ok then
        store.save_meta()
        invalidate_config_catalog()
        local file = path and path:match("([^\\]+)$") or (tostring(stem) .. ".cfg")
        local folder = (path and path:find("April_configs", 1, true)) and "April_configs\\" or ""
        notify.success(string.format('Saved "%s" -> %s%s', profile_label(), folder, file), 3500)
        return true
    end
    notify.error("Failed to save config (could not write file)", 4000)
    return false
end

function M.load_config(name)
    store.migrate_legacy()
    local stem = name or selected_stem()
    local ok = store.load_config(stem)
    if ok then
        store.save_meta()
        invalidate_config_catalog()
        notify.success(string.format('Loaded "%s"', store.display_name(stem)), 3500)
        return true
    end
    notify.error(string.format('Config "%s" not found', store.display_name(stem)), 3500)
    return false
end

function M.delete_config(name)
    store.migrate_legacy()
    local stem = name or selected_stem()
    local ok = store.delete_config(stem)
    if ok then
        store.save_meta()
        invalidate_config_catalog()
        notify.warning(string.format('Deleted "%s"', store.display_name(stem)), 3500)
        return true
    end
    notify.error(string.format('Could not delete "%s"', store.display_name(stem)), 3500)
    return false
end

-- Back-compat for anything still calling slot helpers.
function M.save_slot(_slot)
    return M.save_config(profile_label())
end

function M.load_slot(_slot)
    return M.load_config(selected_stem())
end

function M.delete_slot(_slot)
    return M.delete_config(selected_stem())
end

function M.try_autoload()
    return store.try_autoload()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.CONFIG)

    store.migrate_legacy()
    store.load_meta()

    menu.add_checkbox(T, G.CONFIG, "april_ui_startup_intro", "Startup Animation", true)
    menu_util.input(T, G.CONFIG, "april_cfg_profile_name", "Config Name", "Default")

    local labels = store.list_config_labels()
    if #labels == 0 then labels = { "(no configs)" } end
    menu.add_combo(T, G.CONFIG, "april_cfg_selected", "Saved Configs", labels, 0)

    menu_util.button(T, G.CONFIG, "april_cfg_save", "Save Config", function()
        M.save_config(profile_label())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_load", "Load Config", function()
        M.load_config(selected_stem())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_delete", "Delete Config", function()
        M.delete_config(selected_stem())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_refresh", "Refresh List", function()
        store.migrate_legacy()
        store.refresh_index()
        invalidate_config_catalog()
        notify.info("Config list refreshed", 2000)
    end)

    menu_util.gap(T, G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_cfg_autoload", "Autoload on Start", false)
    menu_util.input(T, G.CONFIG, "april_cfg_autoload_config", "Autoload Config Name", "")

    menu_util.gap(T, G.CONFIG)
    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        April.require("game.bootstrap").force_reload()
        notify.info("Reloading game modules...", 2500)
    end)

    settings.on_change("april_cfg_selected", function()
        local _, stems = store.list_config_labels()
        local idx = math.floor(tonumber(settings.num("april_cfg_selected", 0)) or 0)
        local stem = stems[idx + 1]
        if stem and menu and menu.set then
            menu.set("april_cfg_profile_name", store.display_name(stem))
        end
        store.save_meta()
    end)
    settings.on_change("april_cfg_autoload", function()
        store.save_meta()
    end)
    settings.on_change("april_cfg_autoload_config", function()
        store.save_meta()
    end)
    settings.on_change("april_cfg_profile_name", function()
        store.save_meta()
    end)

    menu_util.bind_master("april_cfg_autoload", { "april_cfg_autoload_config" })
end

function M.update(_dt) end

function M.draw() end

return M

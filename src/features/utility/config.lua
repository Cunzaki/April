local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local store = April.require("core.config_store")

local M = {}

local function active_slot()
    local slot = settings.num("april_cfg_slot", 1)
    if slot < store.SLOT_MIN then slot = store.SLOT_MIN end
    if slot > store.SLOT_MAX then slot = store.SLOT_MAX end
    return slot
end

function M.get_config_path(name)
    return store.get_config_path(name)
end

function M.save_slot(slot)
    slot = slot or active_slot()
    if store.save_slot(slot) then
        store.save_meta()
        return true
    end
    return false
end

function M.load_slot(slot)
    slot = slot or active_slot()
    if store.load_slot(slot) then
        store.save_meta()
        return true
    end
    return false
end

function M.delete_slot(slot)
    slot = slot or active_slot()
    if store.delete_slot(slot) then
        store.save_meta()
        return true
    end
    return false
end

function M.try_autoload()
    return store.try_autoload()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.CONFIG)

    menu_util.section(T, G.CONFIG, "Config Profiles")
    menu.add_slider_int(T, G.CONFIG, "april_cfg_slot", "Config Active Slot", store.SLOT_MIN, store.SLOT_MAX, 1)
    menu.add_button(T, G.CONFIG, "april_cfg_save", "Save Active Config", function()
        M.save_slot(active_slot())
    end)
    menu.add_button(T, G.CONFIG, "april_cfg_load", "Load Active Config", function()
        M.load_slot(active_slot())
    end)
    menu.add_button(T, G.CONFIG, "april_cfg_delete", "Delete Active Config", function()
        M.delete_slot(active_slot())
    end)

    menu.add_separator(T, G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_cfg_autoload", "Autoload Config on Start", false)
    menu.add_slider_int(
        T, G.CONFIG, "april_cfg_autoload_slot", "Autoload Slot",
        store.SLOT_MIN, store.SLOT_MAX, 1,
        menu_util.parent("april_cfg_autoload")
    )

    settings.on_change("april_cfg_autoload", function() store.save_meta() end)
    settings.on_change("april_cfg_autoload_slot", function() store.save_meta() end)
    settings.on_change("april_cfg_slot", function() store.save_meta() end)

    menu.add_separator(T, G.CONFIG)
    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        April.require("game.bootstrap").force_reload()
    end)
end

function M.update(dt) end

function M.draw()
end

return M

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local store = April.require("core.config_store")
local notify = April.require("core.notify")

local M = {}

local function active_slot()
    local slot = settings.num("april_cfg_slot", 1)
    if slot < store.SLOT_MIN then slot = store.SLOT_MIN end
    if slot > store.SLOT_MAX then slot = store.SLOT_MAX end
    return slot
end

local function profile_label()
    return settings.str("april_cfg_profile_name", "Default")
end

function M.get_config_path(name)
    return store.get_config_path(name)
end

function M.save_slot(slot)
    slot = slot or active_slot()
    if store.save_slot(slot) then
        store.save_meta()
        notify.success(string.format('Saved "%s" → Slot %d', profile_label(), slot), 3500)
        return true
    end
    notify.error("Failed to save config", 3500)
    return false
end

function M.load_slot(slot)
    slot = slot or active_slot()
    if store.load_slot(slot) then
        store.save_meta()
        notify.success(string.format('Loaded "%s" from Slot %d', profile_label(), slot), 3500)
        return true
    end
    notify.error(string.format("Slot %d is empty or unreadable", slot), 3500)
    return false
end

function M.delete_slot(slot)
    slot = slot or active_slot()
    if store.delete_slot(slot) then
        store.save_meta()
        notify.warning(string.format("Deleted Slot %d", slot), 3500)
        return true
    end
    notify.error(string.format("Could not delete Slot %d", slot), 3500)
    return false
end

function M.try_autoload()
    return store.try_autoload()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.CONFIG)

    menu_util.section(T, G.CONFIG, "Config Profiles")

    menu_util.input(T, G.CONFIG, "april_cfg_profile_name", "Profile Name", "Default")

    menu.add_slider_int(T, G.CONFIG, "april_cfg_slot", "Active Slot (1–5)", store.SLOT_MIN, store.SLOT_MAX, 1)

    menu_util.button(T, G.CONFIG, "april_cfg_save", "Save to Active Slot", function()
        M.save_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_load", "Load Active Slot", function()
        M.load_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_delete", "Delete Active Slot", function()
        M.delete_slot(active_slot())
    end)

    menu.add_separator(T, G.CONFIG)
    menu_util.label(T, G.CONFIG, "Autoload on script start")

    menu.add_checkbox(T, G.CONFIG, "april_cfg_autoload", "Enable Autoload", false)
    menu_util.input(T, G.CONFIG, "april_cfg_autoload_profile", "Autoload Profile Name", "")
    menu.add_slider_int(
        T, G.CONFIG, "april_cfg_autoload_slot", "Autoload Slot (fallback)",
        store.SLOT_MIN, store.SLOT_MAX, 1,
        menu_util.parent("april_cfg_autoload")
    )

    menu.add_separator(T, G.CONFIG)
    menu_util.label(T, G.CONFIG, "Display & modules")

    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        April.require("game.bootstrap").force_reload()
        notify.info("Reloading game modules…", 2500)
    end)

    settings.on_change("april_cfg_autoload", function()
        store.save_meta()
    end)
    settings.on_change("april_cfg_autoload_slot", function() store.save_meta() end)
    settings.on_change("april_cfg_autoload_profile", function() store.save_meta() end)
    settings.on_change("april_cfg_slot", function() store.save_meta() end)
    settings.on_change("april_cfg_profile_name", function() store.save_meta() end)

    menu_util.bind_master("april_cfg_autoload", { "april_cfg_autoload_profile", "april_cfg_autoload_slot" })
end

function M.update(_dt) end

function M.draw() end

return M

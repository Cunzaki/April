--[[
  April UI template entry.

  This file boots the Gamesense draw menu with the TEMPLATE catalog only.
  There are no game features here — copy groups from template_catalog.lua
  and hook gs_state reads in on_frame() (examples below).
]]

local custom_menu = April.require("ui.custom_menu")
local state = April.require("ui.gs_state")

local M = {}

local function wire_demo_callbacks()
    -- Buttons: catalog type "button" calls state.fire_button(id).
    state.set_button("demo_misc_reload", function()
        print("[April UI] demo_misc_reload clicked")
    end)
    state.set_button("demo_misc_panic", function()
        state.set("demo_aim_enabled", false)
        state.set("demo_silent_enabled", false)
        state.set("demo_esp_enabled", false)
        state.set("demo_world_enabled", false)
        state.set("demo_speed_enabled", false)
        state.set("demo_fly_enabled", false)
        print("[April UI] panic — demo masters cleared")
    end)
    state.set_button("demo_config_reset", function()
        for id, def in pairs(state.defaults) do
            if type(id) == "string" and id:sub(1, 5) == "demo_" then
                state.set(id, def)
            end
        end
        print("[April UI] demo values reset to defaults")
    end)

    -- Optional: react when a checkbox changes.
    state.on_change("demo_aim_enabled", function(on)
        print("[April UI] aim enabled =", on and "true" or "false")
    end)
end

function M.init()
    if not draw then
        print("[April UI] draw API missing — cannot render menu")
        return false
    end
    if not (utility and utility.get_mouse_pos) and not (input and input.is_key_down) then
        print("[April UI] mouse APIs missing — UI may not be interactive")
    end

    custom_menu.init()
    wire_demo_callbacks()

    print("[April UI] template ready — INSERT toggles the menu")
    print("[April UI] edit template_catalog.lua (bundled as ui.catalog) then rebuild:")
    print("[April UI]   node scripts/bundle-april-ui.mjs")
    return true
end

function M.on_frame()
    custom_menu.draw()

    -- Example feature tick (replace with your logic):
    -- if state.get("demo_esp_enabled", false) then
    --     local range = state.get("demo_esp_range", 500)
    --     local col = state.get_color("demo_esp_box_color", { 1, 0.3, 0.3, 1 })
    --     ...
    -- end
end

return M

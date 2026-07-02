local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local NPC_PATTERNS = {
    "Soldier", "Bruno", "Boris", "Brutus", "BTR", "NPC", "Zombie",
}

function M.register_menu()
    menu.add_group(April.TAB, "NPCs")
    menu.add_checkbox(April.TAB, "NPCs", "april_npc_enabled", "NPC ESP", true)
    menu.add_slider_int(April.TAB, "NPCs", "april_npc_range", "Range", 50, 2000, 1000)
    menu.add_colorpicker(April.TAB, "NPCs", "april_npc_color", "Color", { 1, 0.2, 0.2, 1 })
end

function M.scan()
    cache.npcs = {}
    folders.iter_workspace_folders({ "military", "events", "animals" }, function(key, folder)
        local found = folders.scan_descendants(folder, NPC_PATTERNS, 200)
        for _, inst in ipairs(found) do
            local hum = env.safe_call(function() return inst:find_first_child_of_class("Humanoid") end)
            if hum or inst.ClassName == "Model" then
                table.insert(cache.npcs, { inst = inst, name = inst.Name, category = key })
            end
        end
    end)

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_workspace_entity then
                table.insert(cache.npcs, {
                    entity = p,
                    name = p.name,
                    category = "workspace_entity",
                })
            end
        end
    end
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_npc_enabled", true) then return end
    local range = settings.num("april_npc_range", 1000)
    local col = settings.color("april_npc_color", { 1, 0.2, 0.2, 1 })

    for _, entry in ipairs(cache.npcs) do
        if entry.entity then
            local p = entry.entity
            if p.is_alive then
                local b = p:get_bounds()
                if b and b.valid then
                    draw_util.box_esp(b.x, b.y, b.w, b.h, col, 1)
                    draw_util.text_centered(b.x + b.w * 0.5, b.y - 12, entry.name or "NPC", { 1, 1, 1, 1 }, 12)
                end
            end
        elseif env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "NPC", col, range)
        end
    end
end

return M

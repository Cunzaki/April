local settings = April.require("core.settings")

local M = {}

-- Vector-style order: Always / Hold / Toggle
M.MODES = { "Always", "Hold", "Toggle" }

local registry = {}
local last_down = {}
local migrated = {}

local function migrate_mode(mode_id)
    if not mode_id or migrated[mode_id] then return end
    migrated[mode_id] = true
    -- Legacy 2-mode storage: 0 = Toggle, 1 = Hold
    -- New: 0 = Always, 1 = Hold, 2 = Toggle
    -- One-shot per mode id so a later Always (0) choice is kept.
    local flag = mode_id .. "_v3m"
    local state = nil
    pcall(function()
        state = April.require("ui.gs_state")
    end)
    if state and state.get(flag) then return end

    local raw = tonumber(settings.get(mode_id, nil))
    if raw == 0 then
        if menu and menu.set then
            pcall(menu.set, mode_id, 2)
        end
        if state then state.set(mode_id, 2) end
    end
    if state then
        state.define(flag, true)
        state.set(flag, true)
    elseif menu and menu.set then
        pcall(menu.set, flag, true)
    end
end

function M.register(spec)
    if not spec or not spec.id then return end
    local mode_id = spec.mode_id or (spec.id .. "_mode")
    registry[spec.id] = {
        id = spec.id,
        label = spec.label or spec.id,
        mode_id = mode_id,
        key_id = spec.key_id or spec.id,
    }
    migrate_mode(mode_id)
end

function M.is_registered(id)
    return registry[id] ~= nil
end

function M.get_label(id)
    local e = registry[id]
    return e and e.label or id
end

function M.list_ids()
    local out = {}
    for id in pairs(registry) do
        out[#out + 1] = id
    end
    table.sort(out)
    return out
end

function M.list_entries()
    local out = {}
    for id, e in pairs(registry) do
        out[#out + 1] = e
    end
    table.sort(out, function(a, b)
        return (a.label or a.id) < (b.label or b.id)
    end)
    return out
end

function M.get_key(id)
    local e = registry[id]
    local key_id = e and e.key_id or id
    if menu and menu.get_key then
        local k = menu.get_key(key_id)
        if k and k > 0 then return k end
    end
    local ok, gs = pcall(function()
        return April.require("ui.gs_state")
    end)
    if ok and gs then
        local k = gs.get_key(key_id)
        if k and k > 0 then return k end
    end
    return 0
end

function M.mode_index(id)
    local e = registry[id]
    if not e then return 2 end
    migrate_mode(e.mode_id)
    return settings.combo_index(e.mode_id, M.MODES, 2)
end

function M.mode_name(id)
    return M.MODES[M.mode_index(id) + 1] or "Toggle"
end

function M.is_always(id)
    return M.mode_index(id) == 0
end

function M.is_hold(id)
    return M.mode_index(id) == 1
end

function M.is_toggle(id)
    return M.mode_index(id) == 2
end

function M.armed(id)
    return settings.bool(id, false)
end

function M.active(id)
    if not registry[id] then
        return settings.bool(id, false)
    end

    local mode = M.mode_index(id)
    if mode == 1 then -- Hold
        if not M.armed(id) then return false end
        local key = M.get_key(id)
        if key <= 0 then return false end
        return input and input.is_key_down and input.is_key_down(key)
    end

    -- Always + Toggle: checkbox/armed state is the feature on-state
    return M.armed(id)
end

function M.tick()
    if not input or not input.is_key_down then return end

    for id in pairs(registry) do
        local mode = M.mode_index(id)
        local key = M.get_key(id)

        if mode == 0 then -- Always: ignore key edge
            if key > 0 then
                last_down[id] = input.is_key_down(key)
            end
            goto continue
        end

        if mode == 1 then -- Hold: no edge toggle
            if key > 0 then
                last_down[id] = input.is_key_down(key)
            end
            goto continue
        end

        -- Toggle
        if key <= 0 then goto continue end

        local down = input.is_key_down(key)
        if down and not last_down[id] then
            local cur = settings.bool(id, false)
            if menu and menu.set then
                pcall(menu.set, id, not cur)
            else
                pcall(function()
                    April.require("ui.gs_state").set(id, not cur)
                end)
            end
            pcall(function()
                April.require("core.menu_util").sync_master(id)
            end)
        end
        last_down[id] = down

        ::continue::
    end
end

return M

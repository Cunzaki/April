local M = {}

M.TAB = "April"

M.G = {
    SILENT_AIM = "Silent Aim",
    GUN_MODS = "Gun Mods",
    VISUALS = "Visuals",
    WORLD = "World",
    RADAR = "Radar",
    MISC = "Misc",
    CONFIG = "Config",
}

M.G_SIDE = {
    [M.G.SILENT_AIM] = "left",
    [M.G.GUN_MODS] = "right",
    [M.G.VISUALS] = "left",
    [M.G.WORLD] = "right",
    [M.G.RADAR] = "left",
    [M.G.MISC] = "right",
    [M.G.CONFIG] = "left",
}

M._tab_ready = false
M._groups = {}
M._groups_ready = false
M._master_children = {}
M._master_hooked = {}
M._when_rules = {}

local function settings_mod()
    return April.require("core.settings")
end

function M.ensure_tab()
    if M._tab_ready then return end
    if not (April and April._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

function M.ensure_groups()
    if M._groups_ready then return end
    M.ensure_tab()

    local rows = {
        { M.G.SILENT_AIM, M.G.GUN_MODS },
        { M.G.VISUALS, M.G.WORLD },
        { M.G.RADAR, M.G.MISC },
        { M.G.CONFIG },
    }

    for _, row in ipairs(rows) do
        M.group(row[1], "left")
        if row[2] then
            M.group(row[2], "right")
        end
    end

    M._groups_ready = true
end

function M.group(name, side)
    M.ensure_tab()
    if M._groups[name] then
        return M.TAB, name
    end

    side = side or M.G_SIDE[name] or "left"

    if menu and menu.add_group then
        if side == "right" then
            menu.add_group(M.TAB, name, 0, true)
        else
            menu.add_group(M.TAB, name)
        end
        M._groups[name] = true
    end

    return M.TAB, name
end

function M.gap(T, G)
    menu.add_separator(T, G)
end

function M.section(T, G, title)
    menu.add_separator(T, G)
    if title and title ~= "" and menu.add_label then
        menu.add_label(T, G, title)
    end
end

function M.label(T, G, text)
    if menu and menu.add_label then
        menu.add_label(T, G, text)
    end
end

function M.input(T, G, id, label, default)
    if menu and menu.add_input then
        menu.add_input(T, G, id, label, default or "")
    end
end

function M.parent(main_id, extra)
    local opts = { parent = main_id }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            opts[k] = v
        end
    end
    return opts
end

local function add_child_ids(bucket, ids)
    bucket = bucket or {}
    local seen = {}
    for _, id in ipairs(bucket) do
        seen[id] = true
    end
    for _, id in ipairs(ids or {}) do
        if id and not seen[id] then
            seen[id] = true
            bucket[#bucket + 1] = id
        end
    end
    return bucket
end

local function set_visible(id, show)
    if menu and menu.set_visible and id then
        pcall(menu.set_visible, id, show)
    end
end

local function master_visible(master_id)
    local ok, fb = pcall(function()
        return April.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(master_id) then
        return fb.armed(master_id)
    end
    return settings_mod().bool(master_id, false)
end

function M.sync_masters()
    for master_id in pairs(M._master_hooked) do
        local show = master_visible(master_id)
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end
    for i = 1, #M._when_rules do
        local rule = M._when_rules[i]
        if rule.sync then rule.sync() end
    end
end

function M.sync_master(master_id)
    if not master_id or not M._master_hooked[master_id] then return end
    local show = master_visible(master_id)
    for _, id in ipairs(M._master_children[master_id] or {}) do
        set_visible(id, show)
    end
end

function M.bind_master(master_id, child_ids)
    if not master_id or not child_ids then return end
    M._master_children[master_id] = add_child_ids(M._master_children[master_id], child_ids)

    if M._master_hooked[master_id] then return end
    M._master_hooked[master_id] = true

    local function sync(new_val)
        local show
        if new_val == nil then
            show = master_visible(master_id)
        else
            show = new_val == true or new_val == 1
        end
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end

    settings_mod().on_change(master_id, sync)
    sync()
end

function M.bind_when(when_fn, child_ids, watch_ids)
    if not when_fn or not child_ids then return end

    local rule = {
        fn = when_fn,
        ids = {},
    }
    rule.ids = add_child_ids(rule.ids, child_ids)

    local watch = {}
    for _, id in ipairs(watch_ids or {}) do
        watch[id] = true
    end
    rule.watch = watch

    M._when_rules[#M._when_rules + 1] = rule

    local function sync()
        local show = when_fn()
        for _, id in ipairs(rule.ids) do
            set_visible(id, show)
        end
    end

    rule.sync = sync
    sync()

    for id in pairs(watch) do
        settings_mod().on_change(id, sync)
    end
end

function M.button(T, G, id, label, callback, master_id)
    if menu and menu.add_button then
        menu.add_button(T, G, id, label, callback)
    end
    if master_id then
        M.bind_master(master_id, { id })
    end
end

function M.keybind_children(_id)
    return {}
end

function M.bind_children(master_id, extra_ids)
    M.bind_master(master_id, extra_ids or {})
end

-- Custom Toggle / Hold bind (Vector's built-in Always/Hold/Toggle is unreliable).
-- Checkbox key is for display + our listener; Bind Mode combo is Toggle|Hold.
-- Gate features with settings.enabled(id).
function M.register_keybind(T, G, id, label, default, extra)
    extra = extra or {}
    local cb_opts = { show_mode = false, key = extra.key or 0 }
    if extra.parent then cb_opts.parent = extra.parent end
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, id, label, default or false, cb_opts)

    local mode_id = id .. "_mode"
    local mode_label = label .. " Bind Mode"
    menu.add_combo(T, G, mode_id, mode_label, { "Toggle", "Hold" }, 0, M.parent(id))

    April.require("core.feature_bind").register({
        id = id,
        mode_id = mode_id,
        key_id = id,
    })

    M.bind_master(id, { mode_id })
    return mode_id
end

return M

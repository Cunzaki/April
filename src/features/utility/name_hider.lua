local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local env = April.require("core.env")
local mem = April.require("core.memory_string")

local M = {}
local P = "april_hide_local_name"
local APPLY_DELAY_MS = 1500

M._aliases = {}
M._patched = {}
M._source_key = ""
M._applied_for = nil
M._scheduled_for = nil
M._apply_after = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return pid .. ":" .. ws_addr
end

local function real_names()
    local lp = env.get_local_player()
    if not lp then return nil end

    local names = {}
    local seen = {}

    local function add(name)
        if not name or name == "" or seen[name] then return end
        if #name < 2 then return end
        seen[name] = true
        names[#names + 1] = name
    end

    add(lp.name)
    add(lp.display_name)

    if game and game.local_player then
        local inst = game.local_player
        if env.is_valid(inst) then
            add(inst.Name or inst.name)
        end
    end

    if #names == 0 then return nil end
    return names
end

local function alias_for(real)
    if M._aliases[real] then return M._aliases[real] end
    math.randomseed(tick_ms() + #real * 9973)
    local alias = mem.random_alias(#real)
    M._aliases[real] = mem.pad_alias(alias, #real)
    return M._aliases[real]
end

local function alias_for_at(real)
    local key = "@" .. real
    if M._aliases[key] then return M._aliases[key] end
    local base = alias_for(real)
    M._aliases[key] = "@" .. base
    return M._aliases[key]
end

local function patch_hit(real, hit)
    local enc = hit.enc or "ascii"
    local addr = hit.addr
    if not addr or addr <= 0 then return false end

    local current = mem.read_at(addr, #real + 8, enc)
    local alias

    if current:sub(1, 1) == "@" then
        alias = alias_for_at(real)
    else
        alias = alias_for(real)
    end

    if #alias > #current and enc == "ascii" then
        alias = alias:sub(1, #current)
    end
    if enc == "utf16" then
        alias = mem.pad_alias(alias, #real)
    end

    if current ~= real and current ~= ("@" .. real) and current:sub(1, #real) ~= real then
        return false
    end

    if mem.write_at(addr, alias, #alias + 1, enc) then
        M._patched[addr] = { real = real, alias = alias, enc = enc }
        return true
    end
    return false
end

local function patch_name(real)
    local hits = mem.find_string_variants(real, 128)
    local patched = 0

    for i = 1, #hits do
        if patch_hit(real, hits[i]) then
            patched = patched + 1
        end
    end

    return patched
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    menu.add_checkbox(T, G.MISC, P, "Hide Local Name", false, menu_util.parent("april_mod_checker_enabled"))

    settings.on_change(P, function()
        M._aliases = {}
        M._patched = {}
        M._applied_for = nil
        M._scheduled_for = nil
        if settings.enabled(P) then
            M.schedule_apply()
        end
    end)

    menu_util.bind_master("april_mod_checker_enabled", { P })
end

function M.schedule_apply()
    M._scheduled_for = session_id()
    M._apply_after = tick_ms() + APPLY_DELAY_MS
end

function M.apply()
    if not settings.enabled(P) then return end
    if not mem.available() then return end

    local names = real_names()
    if not names then return end

    for i = 1, #names do
        patch_name(names[i])
    end
end

function M.reset()
    M._aliases = {}
    M._patched = {}
    M._source_key = ""
    M._applied_for = nil
    M._scheduled_for = nil
    M._apply_after = 0
end

function M.update(_dt)
    if not settings.enabled(P) then
        if M._applied_for or M._scheduled_for or M._source_key ~= "" then
            M.reset()
        end
        return
    end

    if not mem.available() then return end

    local sid = session_id()
    local names = real_names()
    if not names then return end

    local key = table.concat(names, "|")
    if key ~= M._source_key then
        M._aliases = {}
        M._patched = {}
        M._source_key = key
        M._applied_for = nil
        M._scheduled_for = nil
    end

    if M._applied_for == sid then return end

    if M._scheduled_for ~= sid then
        M.schedule_apply()
    end

    if tick_ms() >= M._apply_after then
        M.apply()
        M._applied_for = sid
        M._scheduled_for = nil
    end
end

function M.draw() end

return M

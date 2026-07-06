local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local env = April.require("core.env")
local mem = April.require("core.memory_string")

local M = {}
local P = "april_hide_local_name"
local APPLY_DELAY_MS = 2500
local REPATCH_MS = 200

M._alias = nil
M._apply_after = 0
M._last_patch = 0
M._mem_done = false
M._session = ""

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

local function random_alias(len)
    len = math.max(4, math.min(len or 10, 20))
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local n = #chars
    math.randomseed(tick_ms() + len * 7919)
    local out = {}
    for i = 1, len do
        out[i] = chars:sub(math.random(1, n), math.random(1, n))
    end
    return table.concat(out)
end

local function get_primary_name()
    local lp = env.get_local_player()
    if not lp then return nil end
    local username = lp.name
    if username and #username >= 2 then return username, lp.display_name end
    if game and game.local_player and env.is_valid(game.local_player) then
        username = game.local_player.Name or game.local_player.name
        local display = game.local_player.DisplayName or game.local_player.display_name
        if username and #username >= 2 then return username, display end
    end
    return nil
end

local function set_text(inst, text)
    if not inst or not text then return false end
    return env.safe_call(function()
        if inst.Text ~= nil then
            inst.Text = text
            return true
        end
        if inst.text ~= nil then
            inst.text = text
            return true
        end
    end) == true
end

local function set_instance_name(inst, alias)
    if not inst or not alias then return false end
    local ok = env.safe_call(function()
        if inst.DisplayName ~= nil then
            inst.DisplayName = alias
            return true
        end
        if inst.display_name ~= nil then
            inst.display_name = alias
            return true
        end
        if inst.Name ~= nil then
            inst.Name = alias
            return true
        end
        if inst.name ~= nil then
            inst.name = alias
            return true
        end
    end)
    return ok == true
end

local function patch_player_instances(alias)
    if game and game.local_player and env.is_valid(game.local_player) then
        set_instance_name(game.local_player, alias)
    end
    local lp = env.get_local_player()
    if lp and lp.player and env.is_valid(lp.player) then
        set_instance_name(lp.player, alias)
    end
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.find_first_child then return parent:find_first_child(name) end
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
    end)
end

local function patch_humanoid(hum, alias)
    if not hum then return end
    env.safe_call(function()
        if hum.name_display_distance ~= nil then hum.name_display_distance = 0 end
        if hum.NameDisplayDistance ~= nil then hum.NameDisplayDistance = 0 end
        if hum.display_distance_type ~= nil then hum.display_distance_type = 2 end
        if hum.DisplayDistanceType ~= nil then hum.DisplayDistanceType = 2 end
    end)
end

local function patch_name_tag(char, alias, real)
    if not char or not env.is_valid(char) then return end
    local name_tag = find_child(char, "NameTag")
    if not name_tag or not env.is_valid(name_tag) then return end

    env.safe_call(function()
        if name_tag.Enabled ~= nil then name_tag.Enabled = false end
        if name_tag.enabled ~= nil then name_tag.enabled = false end
        if name_tag.MaxDistance ~= nil then name_tag.MaxDistance = 0 end
        if name_tag.max_distance ~= nil then name_tag.max_distance = 0 end
    end)

    local label = find_child(name_tag, "Label")
    if label then
        local txt = env.safe_call(function() return label.Text or label.text end)
        if not txt or txt == "" or (real and txt:find(real, 1, true)) then
            set_text(label, alias)
        end
    end
end

local function patch_gui(alias, real)
    if not game or not game.local_player then return end
    local pg = find_child(game.local_player, "PlayerGui")
    if not pg or not env.is_valid(pg) then return end

    local main = find_child(pg, "Main")
    if main and env.is_valid(main) then
        local map = find_child(main, "Map")
        if map and env.is_valid(map) then
            local outer = find_child(map, "Frame")
            local inner = outer and find_child(outer, "Map")
            if inner and env.is_valid(inner) then
                local cursor = find_child(inner, "PlayerCursor")
                if cursor then
                    local player_name = find_child(cursor, "PlayerName")
                    if player_name then
                        local txt = env.safe_call(function() return player_name.Text or player_name.text end)
                        if not txt or txt == "" or (real and txt:find(real, 1, true)) then
                            set_text(player_name, alias)
                        end
                    end
                end
            end
        end
    end

    local custom_chat = find_child(pg, "CustomChat")
    if custom_chat and env.is_valid(custom_chat) then
        local chat_frame = find_child(custom_chat, "ChatFrame")
        local messages = chat_frame and find_child(chat_frame, "MessagesFrame")
        if messages and env.is_valid(messages) then
            local children = env.safe_call(function()
                if messages.get_children then return messages:get_children() end
            end) or {}
            for _, msg in ipairs(children) do
                if not env.is_valid(msg) then goto continue_msg end
                local txt = env.safe_call(function()
                    return msg.Text or msg.text
                end)
                if txt and real and txt:find(real, 1, true) then
                    set_text(msg, txt:gsub(real, alias))
                end
                ::continue_msg::
            end
        end
    end
end

local function patch_engine_strings_once(real, alias)
    if M._mem_done or not mem.available() or not real or real == alias then return end

    local variants = {
        { needle = real, enc = "ascii" },
        { needle = mem.utf16_bytes(real), enc = "utf16" },
        { needle = "@" .. real, enc = "ascii" },
    }

    local at_alias = "@" .. alias

    for _, v in ipairs(variants) do
        local hits = mem.try_engine_scan(v.needle, 24)
        for i = 1, #hits do
            local hit = hits[i]
            local addr = hit.addr
            if addr and addr > 0 then
                local current = mem.read_at(addr, #real + 4, v.enc)
                local replacement = v.enc == "utf16" and mem.pad_alias(alias, #real) or alias
                if current:sub(1, 1) == "@" then
                    replacement = v.enc == "utf16" and mem.pad_alias(at_alias, #real + 1) or at_alias
                end
                if #replacement <= #current + 2 then
                    mem.write_at(addr, replacement, #replacement + 1, v.enc)
                end
            end
        end
    end

    M._mem_done = true
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    menu.add_checkbox(T, G.MISC, P, "Hide Local Name", false, menu_util.parent("april_mod_checker_enabled"))

    settings.on_change(P, function()
        M.reset()
        if settings.enabled(P) then
            M._apply_after = tick_ms() + APPLY_DELAY_MS
        end
    end)

    menu_util.bind_master("april_mod_checker_enabled", { P })
end

function M.patch_now()
    if not settings.enabled(P) then return end

    local real = get_primary_name()
    if not real then return end

    if not M._alias then
        M._alias = random_alias(#real)
    end
    local alias = M._alias

    patch_player_instances(alias)

    local lp = env.get_local_player()
    if lp and lp.character and env.is_valid(lp.character) then
        patch_name_tag(lp.character, alias, real)
    end
    if lp and lp.humanoid and env.is_valid(lp.humanoid) then
        patch_humanoid(lp.humanoid, alias)
    end

    patch_gui(alias, real)
    patch_engine_strings_once(real, alias)
end

function M.reset()
    M._alias = nil
    M._apply_after = 0
    M._last_patch = 0
    M._mem_done = false
    M._session = ""
end

function M.update(_dt)
    if not settings.enabled(P) then
        if M._alias or M._apply_after > 0 or M._mem_done then
            M.reset()
        end
        return
    end

    local sid = session_id()
    if sid ~= M._session then
        M._session = sid
        M._alias = nil
        M._mem_done = false
        M._apply_after = tick_ms() + APPLY_DELAY_MS
        M._last_patch = 0
    end

    if not get_primary_name() then return end

    if M._apply_after == 0 then
        M._apply_after = tick_ms() + APPLY_DELAY_MS
    end

    if tick_ms() < M._apply_after then return end

    if M._last_patch > 0 and tick_ms() - M._last_patch < REPATCH_MS then return end
    M._last_patch = tick_ms()
    M.patch_now()
end

function M.draw() end

return M

-- Player ESP state from DataModel.Players.<Name> attributes.
-- Vector: inst:get_attribute / get_attributes
--   string  → string
--   bool    → boolean
--   Color3  → table { r, g, b }  (0-1, sometimes 0-255)
-- ClanTag string can also appear on Character.NameTag — that is NOT enough for
-- VIP/SafeZone/ClanColor; those only exist on the Player instance.

local env = April.require("core.env")
local team_state = April.require("game.team_state")

local M = {}

local SNAP_TTL_MS = 200
local snaps = {}
local pl_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function cache_key(player)
    local uid = tonumber(player and player.user_id)
    if uid and uid ~= 0 then return "u:" .. tostring(uid) end
    return "n:" .. tostring(player and (player.name or player.display_name) or "?")
end

local function players_service()
    if game and game.players then
        return game.players
    end
    return env.safe_call(function()
        if game.get_service then return game.get_service("Players") end
        if game.GetService then return game:GetService("Players") end
        return nil
    end)
end

local function find_child(parent, name)
    if not parent or not name or name == "" then return nil end
    local ok, child = pcall(function()
        if parent.find_first_child then return parent:find_first_child(name) end
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        return nil
    end)
    if ok and child then return child end
    return nil
end

local function find_humanoid(char)
    if not char then return nil end
    local ok, hum = pcall(function()
        if char.find_first_child_of_class then
            return char:find_first_child_of_class("Humanoid")
        end
        if char.FindFirstChildOfClass then
            return char:FindFirstChildOfClass("Humanoid")
        end
        return find_child(char, "Humanoid")
    end)
    if ok then return hum end
    return nil
end

-- Do NOT gate on utility.is_valid — it can reject valid Players instances
-- while find_first_child still returns a usable handle for get_attribute.
local function read_attr(inst, key)
    if not inst or not key then return nil end

    local ok, v = pcall(function()
        if inst.get_attribute then return inst:get_attribute(key) end
        return nil
    end)
    if ok and v ~= nil then return v end

    ok, v = pcall(function()
        if inst.GetAttribute then return inst:GetAttribute(key) end
        return nil
    end)
    if ok and v ~= nil then return v end

    return nil
end

local function read_all_attrs(inst)
    if not inst then return nil end
    local ok, bag = pcall(function()
        if inst.get_attributes then return inst:get_attributes() end
        if inst.GetAttributes then return inst:GetAttributes() end
        return nil
    end)
    if ok and type(bag) == "table" then return bag end
    return nil
end

local function bag_get(bag, key)
    if type(bag) ~= "table" or not key then return nil end
    local v = bag[key]
    if v ~= nil then return v end
    local want = key:lower()
    for k, val in pairs(bag) do
        if type(k) == "string" and k:lower() == want then
            return val
        end
    end
    return nil
end

local function as_bool(v)
    if v == true then return true end
    if v == false or v == nil then return false end
    if type(v) == "boolean" then return v end
    if v == 1 or v == 1.0 then return true end
    if v == 0 or v == 0.0 then return false end
    if type(v) == "string" then
        local s = v:lower():match("^%s*(.-)%s*$") or ""
        if s == "true" or s == "1" or s == "yes" then return true end
        return false
    end
    if type(v) == "number" then return v ~= 0 end
    return false
end

local function normalize_rgb(r, g, b)
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r == nil or g == nil or b == nil then return nil end
    if r > 1 or g > 1 or b > 1 then
        r, g, b = r / 255, g / 255, b / 255
    end
    if r < 0 then r = 0 elseif r > 1 then r = 1 end
    if g < 0 then g = 0 elseif g > 1 then g = 1 end
    if b < 0 then b = 0 elseif b > 1 then b = 1 end
    return { r, g, b, 1 }
end

-- Vector docs: Color3 attrs → {r,g,b}; GuiObject TextColor3 → {R,G,B} (often 0-255).
local function parse_color3(c)
    if c == nil or c == false then return nil end

    if type(c) == "table" then
        local r = c.r or c.R or c.red or c.Red
        local g = c.g or c.G or c.green or c.Green
        local b = c.b or c.B or c.blue or c.Blue
        if r == nil then r = c.x or c.X end
        if g == nil then g = c.y or c.Y end
        if b == nil then b = c.z or c.Z end
        if r == nil then r = c[1] end
        if g == nil then g = c[2] end
        if b == nil then b = c[3] end
        -- Some Vector builds use 0-based RGB arrays.
        if r == nil and c[0] ~= nil and c[1] ~= nil and c[2] ~= nil then
            r, g, b = c[0], c[1], c[2]
        end

        if r == nil and (c.value or c.Value or c.color or c.Color) then
            return parse_color3(c.value or c.Value or c.color or c.Color)
        end

        if r == nil then
            local nums = {}
            for _, val in pairs(c) do
                if type(val) == "number" then
                    nums[#nums + 1] = val
                end
            end
            if #nums >= 3 then
                r, g, b = nums[1], nums[2], nums[3]
            end
        end

        return normalize_rgb(r, g, b)
    end

    if type(c) == "string" then
        local r = c:match("<R>([%d%.]+)</R>")
        local g = c:match("<G>([%d%.]+)</G>")
        local b = c:match("<B>([%d%.]+)</B>")
        if r then return normalize_rgb(r, g, b) end
        r, g, b = c:match("([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)")
        return normalize_rgb(r, g, b)
    end

    if type(c) == "number" then
        local n = math.floor(c)
        return normalize_rgb(
            math.floor(n / 65536) % 256,
            math.floor(n / 256) % 256,
            n % 256
        )
    end

    local ok, r, g, b = pcall(function()
        return c.r or c.R or c.x or c.X, c.g or c.G or c.y or c.Y, c.b or c.B or c.z or c.Z
    end)
    if ok then
        local parsed = normalize_rgb(r, g, b)
        if parsed then return parsed end
    end

    r, g, b = nil, nil, nil
    ok = pcall(function()
        if c.GetComponents then
            r, g, b = c:GetComponents()
        elseif c.get_components then
            r, g, b = c:get_components()
        end
    end)
    if ok then
        local parsed = normalize_rgb(r, g, b)
        if parsed then return parsed end
    end

    local s = env.safe_call(function() return tostring(c) end)
    if type(s) == "string" and not s:lower():find("userdata", 1, true) then
        return parse_color3(s)
    end

    return nil
end

local function read_color3_attr(inst, key)
    if not inst or not key then return nil end

    local parsed = parse_color3(read_attr(inst, key))
    if parsed then return parsed end

    local bag = read_all_attrs(inst)
    if bag then
        parsed = parse_color3(bag_get(bag, key))
        if parsed then return parsed end
    end

    return nil
end

local function read_gui_color3(inst)
    if not inst then return nil end
    local v = env.safe_call(function()
        return inst.TextColor3 or inst.text_color3
            or inst.BackgroundColor3 or inst.background_color3
            or inst.ImageColor3 or inst.image_color3
    end)
    return parse_color3(v)
end

local function parse_rgb_from_text(text)
    if type(text) ~= "string" then return nil end
    local r, g, b = text:match('rgb%(([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)%)')
    if not r then
        r, g, b = text:match('color="rgb%(([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)%)"')
    end
    return normalize_rgb(r, g, b)
end

local function is_near_white(col)
    if not col then return true end
    local r = col[1] or col.r or col.R or 1
    local g = col[2] or col.g or col.G or 1
    local b = col[3] or col.b or col.B or 1
    return r > 0.95 and g > 0.95 and b > 0.95
end

local function normalize_clan_tag(tag)
    if tag == nil or tag == false then return nil end
    if type(tag) == "string" then
        tag = tag:match("^%[(.-)%]$") or tag
        tag = tag:match("^%s*(.-)%s*$") or tag
        if tag == "" then return nil end
        return tag
    end
    if type(tag) == "number" then return tostring(tag) end
    local s = tostring(tag)
    if s == "" or s == "nil" or s == "false" or s == "true" then return nil end
    return s
end

function M.resolve_player_inst(player)
    if not player then return nil end

    local key = cache_key(player)
    local now = tick_ms()
    local cached = pl_cache[key]
    if cached and cached.inst and (now - cached.t) < 1500 then
        -- Soft re-check: try a cheap name read
        local still = env.safe_call(function()
            return cached.inst.Name or cached.inst.name
        end)
        if still then return cached.inst end
    end

    local players = players_service()
    local found = nil

    if players then
        local names = { player.name, player.display_name }
        for i = 1, #names do
            local want = names[i]
            if want and want ~= "" then
                found = find_child(players, want)
                if found then break end
            end
        end

        if not found then
            local uid = tonumber(player.user_id)
            local kids = env.safe_call(function()
                if players.get_children then return players:get_children() end
                if players.GetChildren then return players:GetChildren() end
                return nil
            end) or {}
            for i = 1, #kids do
                local pl = kids[i]
                local id = tonumber(env.safe_call(function()
                    return pl.UserId or pl.user_id
                end))
                if uid and id and id == uid then
                    found = pl
                    break
                end
                local n = env.safe_call(function() return pl.Name or pl.name end)
                local dn = env.safe_call(function() return pl.DisplayName or pl.display_name end)
                if (player.name and (n == player.name or dn == player.name))
                    or (player.display_name and (n == player.display_name or dn == player.display_name)) then
                    found = pl
                    break
                end
            end
        end
    end

    -- Last resort: entity wrapper (strings may work; bools/Color3 often don't).
    if not found and player.player then
        found = player.player
    end

    if found then
        pl_cache[key] = { t = now, inst = found }
    end
    return found
end

function M.resolve_character(player)
    if not player then return nil end
    if player.character then
        local ok = env.safe_call(function()
            return utility and utility.is_valid(player.character)
        end)
        if ok ~= false and player.character then
            return player.character
        end
    end
    local pl = M.resolve_player_inst(player)
    if not pl then return nil end
    return env.safe_call(function()
        return pl.Character or pl.character
    end)
end

function M.resolve_humanoid(player)
    if not player then return nil end
    if player.humanoid then return player.humanoid end
    return find_humanoid(M.resolve_character(player))
end

local function read_player_attrs(pl)
    local out = {
        vip = false,
        safezone = false,
        hide = false,
        owner = false,
        admin = false,
        mod = false,
        clan_tag = nil,
        clan_color = nil,
        from_player = false,
    }
    if not pl then return out end

    -- Primary: full attribute bag (most reliable for mixed types on Vector).
    local bag = read_all_attrs(pl)
    if bag then
        out.from_player = true
        out.vip = as_bool(bag_get(bag, "VIP"))
        out.safezone = as_bool(bag_get(bag, "SafeZone"))
        out.hide = as_bool(bag_get(bag, "HideTag"))
        out.owner = as_bool(bag_get(bag, "Owner"))
        out.admin = as_bool(bag_get(bag, "Admin"))
        out.mod = as_bool(bag_get(bag, "Mod"))
        out.clan_tag = normalize_clan_tag(bag_get(bag, "ClanTag"))
        out.clan_color = read_color3_attr(pl, "ClanColor")
    end

    -- Per-key fill for anything still missing.
    if not out.clan_tag then
        local v = read_attr(pl, "ClanTag")
        if v ~= nil then
            out.from_player = true
            out.clan_tag = normalize_clan_tag(v)
        end
    end
    if not out.clan_color then
        out.clan_color = read_color3_attr(pl, "ClanColor")
    end
    if not out.vip then
        local v = read_attr(pl, "VIP")
        if v ~= nil then
            out.from_player = true
            out.vip = as_bool(v)
        end
    end
    if not out.safezone then
        local v = read_attr(pl, "SafeZone")
        if v ~= nil then
            out.from_player = true
            out.safezone = as_bool(v)
        end
    end
    if not out.mod then
        local v = read_attr(pl, "Mod")
        if v ~= nil then
            out.from_player = true
            out.mod = as_bool(v)
        end
    end
    if not out.owner then
        local v = read_attr(pl, "Owner")
        if v ~= nil then out.owner = as_bool(v) end
    end
    if not out.admin then
        local v = read_attr(pl, "Admin")
        if v ~= nil then out.admin = as_bool(v) end
    end
    if not out.hide then
        local v = read_attr(pl, "HideTag")
        if v ~= nil then out.hide = as_bool(v) end
    end

    return out
end

local function nametag_clan_tag_only(char)
    if not char then return nil end
    local nt = find_child(char, "NameTag")
    if not nt then return nil end
    local label = find_child(nt, "Label")
    if not label then return nil end
    local text = env.safe_call(function()
        return label.Text or label.text
    end)
    if type(text) ~= "string" then return nil end
    local tag = normalize_clan_tag(text:match("%[([^%]]+)%]"))
    if not tag then return nil end
    local upper = tag:upper()
    if upper == "MOD" or upper == "ADMIN" or upper == "OWNER" or upper == "VIP" then
        return nil
    end
    return tag
end

local function nametag_clan_color(char)
    if not char then return nil end
    local nt = find_child(char, "NameTag")
    if not nt then return nil end
    local label = find_child(nt, "Label")
    if not label then return nil end

    local text = env.safe_call(function()
        return label.Text or label.text
    end)
    local from_text = parse_rgb_from_text(text)
    if from_text then return from_text end

    local tc = read_gui_color3(label)
    if tc and not is_near_white(tc) then
        return tc
    end

    local clan_lbl = find_child(nt, "ClanTag")
    if clan_lbl then
        from_text = parse_rgb_from_text(env.safe_call(function()
            return clan_lbl.Text or clan_lbl.text
        end))
        if from_text then return from_text end
        tc = read_gui_color3(clan_lbl)
        if tc and not is_near_white(tc) then
            return tc
        end
    end

    return nil
end

local function resolve_clan_color(pl, char, entity_player)
    if pl then
        local c = read_color3_attr(pl, "ClanColor")
        if c then return c end
    end

    if entity_player and entity_player.player and entity_player.player ~= pl then
        local c = read_color3_attr(entity_player.player, "ClanColor")
        if c then return c end
    end

    if entity_player then
        local c = read_color3_attr(entity_player, "ClanColor")
        if c then return c end
    end

    return nametag_clan_color(char)
end

local function build_snap(player)
    local pl = M.resolve_player_inst(player)
    local char = M.resolve_character(player)
    local hum = M.resolve_humanoid(player)
    if not hum and char then hum = find_humanoid(char) end
    local ic = char and find_child(char, "InteractController") or nil

    local pa = read_player_attrs(pl)

    -- NameTag only fills missing ClanTag string — never invents VIP/color.
    if not pa.clan_tag then
        pa.clan_tag = nametag_clan_tag_only(char)
    end

    pa.clan_color = pa.clan_color or resolve_clan_color(pl, char, player)

    local staff = nil
    if not pa.hide then
        if pa.owner then
            staff = "OWNER"
        elseif pa.admin then
            staff = "ADMIN"
        elseif pa.mod then
            staff = "MOD"
        end
    end

    return {
        t = tick_ms(),
        vip = pa.vip,
        safezone = pa.safezone,
        downed = as_bool(read_attr(hum, "Downed")),
        reviving = as_bool(read_attr(ic, "Reviving")),
        staff = staff,
        clan_tag = pa.clan_tag,
        clan_color = pa.clan_color,
        resolved = pl ~= nil,
        from_player = pa.from_player,
    }
end

local function get_snap(player)
    if not player then return nil end
    local key = cache_key(player)
    local now = tick_ms()
    local s = snaps[key]
    if s and (now - s.t) < SNAP_TTL_MS then
        return s
    end
    s = build_snap(player)
    snaps[key] = s
    return s
end

function M.invalidate(player)
    if not player then
        snaps = {}
        pl_cache = {}
        return
    end
    local key = cache_key(player)
    snaps[key] = nil
    pl_cache[key] = nil
end

function M.esp_state(player)
    return get_snap(player)
end

function M.player_attr(player, key)
    return read_attr(M.resolve_player_inst(player), key)
end

function M.char_attr(player, key)
    return read_attr(M.resolve_character(player), key)
end

function M.humanoid_attr(player, key)
    return read_attr(M.resolve_humanoid(player), key)
end

function M.is_safezone(player)
    local s = get_snap(player)
    return s and s.safezone or false
end

function M.is_vip(player)
    local s = get_snap(player)
    return s and s.vip or false
end

function M.staff_tag(player)
    local s = get_snap(player)
    return s and s.staff or nil
end

function M.is_reviving(player)
    local s = get_snap(player)
    return s and s.reviving or false
end

function M.clan_tag(player)
    local s = get_snap(player)
    return s and s.clan_tag or nil
end

function M.clan_color(player)
    local s = get_snap(player)
    return s and s.clan_color or nil
end

function M.is_downed(player)
    local s = get_snap(player)
    return s and s.downed or false
end

function M.is_alive_body(player)
    if not player then return false end
    if player.is_alive == false then return false end
    local char = player.character
    if not char then return false end
    if utility and utility.is_valid and not utility.is_valid(char) then return false end
    if player.health ~= nil and player.health <= 0 then return false end
    return true
end

function M.is_combat_target(player)
    if not player or player.is_local then return false end
    if player.is_alive ~= false then return true end
    if M.is_downed(player) then return true end
    if player.health and player.health > 0 then return true end
    return false
end

function M.passes_health_check(player)
    if not player then return false end
    if player.is_alive then
        if player.health and player.health <= 0 then return false end
        return true
    end
    return M.is_downed(player)
end

function M.passes_team_check(player)
    if not player then return false end
    return not team_state.is_teammate(player)
end

function M.passes_downed_check(player, mode)
    if not player then return false end
    mode = tonumber(mode) or 0
    if mode == 1 then return true end
    local downed = M.is_downed(player)
    if mode == 2 then return downed end
    return not downed
end

function M.passes_safezone_check(player, skip_safezone)
    if not player then return false end
    if not skip_safezone then return true end
    return not M.is_safezone(player)
end

return M

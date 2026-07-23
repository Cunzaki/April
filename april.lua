--[[
    April Fallen — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-07-23T14:02:41.529Z
    UI: custom Gamesense menu (INSERT) — Vector menu tabs disabled
]]

April = {
    version = "3.95.4",
    debug = false,
    _mods = {},
    bundled = true,
    custom_ui = true,
}

April._menu_tab_ready = true

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April] bundled module missing: " .. path)
    end
    return mod
end


-- ── core/env.lua ──
April._mods["core.env"] = (function()
local M = {}

function M.has_api(name)
    return _G[name] ~= nil
end

function M.require_apis(names)
    for _, name in ipairs(names) do
        if not M.has_api(name) then
            return false, name
        end
    end
    return true
end

function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

function M.is_valid(inst)
    if not inst or not utility then return false end
    return utility.is_valid(inst)
end

function M.get_workspace()
    if game and game.workspace then return game.workspace end
    return M.safe_call(function() return workspace end)
end

function M.get_local_player()
    if entity and entity.get_local_player then
        return entity.get_local_player()
    end
    if game and game.local_player then return game.local_player end
    return nil
end

function M.get_replicated_storage()
    return M.safe_call(function() return game.get_service("ReplicatedStorage") end)
end

return M

end)()

-- ── core/math_util.lua ──
April._mods["core.math_util"] = (function()
local M = {}

function M.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function M.distance3(dx, dy, dz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.distance2(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

function M.dot(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end

function M.screen_fov_dist(sx, sy, cx, cy)
    local dx, dy = sx - cx, sy - cy
    return math.sqrt(dx * dx + dy * dy)
end

function M.vec3_str(v)
    if not v or v.x == nil then return "?" end
    return string.format("%.0f, %.0f, %.0f", v.x, v.y, v.z)
end

return M

end)()

-- ── core/text_util.lua ──
April._mods["core.text_util"] = (function()
local M = {}

local REPLACEMENTS = {
    ["\194\160"] = " ",
    ["\226\128\166"] = "...",
    ["\226\128\147"] = "-",
    ["\226\128\148"] = "-",
    ["\226\128\162"] = "*",
    ["\194\183"] = "|",
    ["\226\134\146"] = "->",
    ["\226\134\144"] = "<-",
    ["\226\128\153"] = "'",
    ["\226\128\156"] = '"',
    ["\226\128\157"] = '"',
}

function M.sanitize(text)
    if text == nil then return "" end
    text = tostring(text)
    for bad, good in pairs(REPLACEMENTS) do
        text = text:gsub(bad, good)
    end
    if text:find("[^\32-\126]") then
        text = text:gsub("[^\32-\126]", "")
    end
    return text
end

return M

end)()

-- ── core/cache.lua ──
April._mods["core.cache"] = (function()
local M = {}

M.players = {}
M.world = {}
M.loot = {}
M.base = {}
M.npcs = {}
M.waypoints = {}
M.stats = {
    last_player_scan = 0,
    last_world_scan = 0,
    last_loot_scan = 0,
    last_base_scan = 0,
    last_npc_scan = 0,
}

M.WORKSPACE_SCAN_MS = 1000
M.POS_CACHE_MS = 1000
M._last_pos_cache = 0

function M.should_refresh_positions()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - M._last_pos_cache >= M.POS_CACHE_MS then
        M._last_pos_cache = now
        return true
    end
    return false
end

function M.clear_bucket(bucket)
    for k in pairs(bucket) do bucket[k] = nil end
end

-- Compact an array of ESP entries, dropping invalid instances. Keeps draw loops tight
-- between workspace rescans without changing scan interval.
function M.prune_invalid(list)
    if not list or #list == 0 then return 0 end
    local env = April.require("core.env")
    local write = 1
    for read = 1, #list do
        local entry = list[read]
        if entry and entry.inst and env.is_valid(entry.inst) then
            if write ~= read then
                list[write] = entry
            end
            write = write + 1
        end
    end
    for i = write, #list do
        list[i] = nil
    end
    return write - 1
end

return M

end)()

-- ── core/capabilities.lua ──
April._mods["core.capabilities"] = (function()
local M = {}

function M.probe()
    return {
        menu = _G.menu ~= nil,
        draw = _G.draw ~= nil,
        entity = _G.entity ~= nil,
        game = _G.game ~= nil,
        camera = _G.camera ~= nil,
        input = _G.input ~= nil,
        utility = _G.utility ~= nil,
        thread = _G.thread ~= nil,
        raycast = _G.raycast ~= nil,
        fflag = _G.fflag ~= nil,
        memory = _G.memory ~= nil,
        exploits_chams = _G.exploits ~= nil
            and type(exploits.ApplyChamsToInstance) == "function"
            and type(exploits.RevertChams) == "function",
        fallen_gc = type(refreshgc) == "function"
            and type(applygc) == "function"
            and type(getgc) == "function",
        getgc = type(getgc) == "function",
    }
end

function M.summary(c)
    c = c or M.probe()
    local parts = {}
    if c.menu then table.insert(parts, "menu") end
    if c.draw then table.insert(parts, "draw") end
    if c.fallen_gc then table.insert(parts, "gc-mods") end
    if c.exploits_chams then table.insert(parts, "gpu-chams") end
    if c.getgc then table.insert(parts, "getgc") end
    return #parts > 0 and table.concat(parts, ", ") or "minimal"
end

return M

end)()

-- ── core/debug.lua ──
April._mods["core.debug"] = (function()
local M = {}

local seen_errors = {}
local frame_count = 0

function M.enabled()
    return April and April.debug == true
end

function M.verbose()
    return April and April.debug_verbose == true
end

function M.log(msg)
    if not M.enabled() then return end
    print("[April] " .. tostring(msg))
end

function M.warn(msg)
    if not M.enabled() then return end
    print("[April WARN] " .. tostring(msg))
end

function M.warn_once(key, msg)
    M.error_once("warn:" .. key, msg)
end

function M.error_once(key, err)
    key = tostring(key)
    if seen_errors[key] and not M.verbose() then return end
    seen_errors[key] = (seen_errors[key] or 0) + 1
    local count = seen_errors[key]
    local suffix = count > 1 and (" (x" .. count .. ")") or ""
    print("[April ERROR][" .. key .. "] " .. tostring(err) .. suffix)
    if debug and debug.traceback then
        print(debug.traceback(err, 2))
    end
end

function M.guard(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        M.error_once(key, a)
        return nil
    end
    return a, b, c
end

function M.guard_bool(key, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        M.error_once(key, result)
        return false
    end
    return true, result
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    _G.on_frame = fn

    if callbacks and callbacks.add then
        callbacks.add("on_frame", fn)
    end

    if draw then
        draw.callback = fn
    end

    return true
end

function M.tick_frame()
    frame_count = frame_count + 1
end

function M.reset_errors()
    seen_errors = {}
end

function M.stats()
    return { frames = frame_count, errors = seen_errors }
end

return M

end)()

-- ── game/mod_ids.lua ──
April._mods["game.mod_ids"] = (function()
local M = {}

M.GROUP_ID = 1154360
M.MIN_STAFF_RANK = 6 -- above Fan (rank 5)

-- Chunk Studios (1154360) staff ranks above Fan.
-- Roles: OG, Game Tester, Game Moderator, Contribution, Developers,
-- Lead Developer, Co-Founder, Founder. Excludes Guest / Member / Fan.
-- Static fallback synced from groups.roblox.com; live roster via game.mod_group.
M.ROLES = {

    -- Founder
    [16681869] = "Founder", -- neddleduck

    -- Co-Founder
    [47983795] = "Co-Founder", -- ChickenBagelz

    -- Lead Developer
    [25548179] = "Lead Developer", -- AsianAbrex
    [363101315] = "Lead Developer", -- Warm_Vibes

    -- Contribution
    [174212818] = "Contribution", -- YTGonzo

    -- Game Moderator
    [584370127] = "Game Moderator", -- 1Newy1
    [4243907215] = "Game Moderator", -- AaronElagant
    [81993536] = "Game Moderator", -- aidenas2011
    [979624578] = "Game Moderator", -- B_BEAMO
    [602009251] = "Game Moderator", -- Bajoogies_XD
    [2525997354] = "Game Moderator", -- BlackWhiteYT11
    [1383415614] = "Game Moderator", -- Bryponfx
    [2276999095] = "Game Moderator", -- CelebredKillerq
    [3122439095] = "Game Moderator", -- chancerocke
    [836836349] = "Game Moderator", -- didusha123
    [1190967808] = "Game Moderator", -- djvdhshscshs
    [2732967856] = "Game Moderator", -- DontTouchZGrass
    [113179883] = "Game Moderator", -- DopeIlI
    [3034930770] = "Game Moderator", -- Fan_hellrider
    [1478885961] = "Game Moderator", -- fordjdj12
    [833946684] = "Game Moderator", -- GamerGubbi
    [4553863490] = "Game Moderator", -- giovannirv2
    [1116486172] = "Game Moderator", -- Hakob_8w8
    [8593140875] = "Game Moderator", -- HurbertTheP3r73rt
    [2364950171] = "Game Moderator", -- ilovetowerbattle_9
    [1374319325] = "Game Moderator", -- jostjohnyca
    [3470393585] = "Game Moderator", -- k6ppo
    [41482597] = "Game Moderator", -- kerub131
    [51281722] = "Game Moderator", -- KittenBagelz
    [1058831985] = "Game Moderator", -- krisidisi23
    [510349404] = "Game Moderator", -- Kristian4209
    [991290934] = "Game Moderator", -- Lexi34567812
    [122915793] = "Game Moderator", -- LionTooth99999
    [202751467] = "Game Moderator", -- lumbers2
    [1937516999] = "Game Moderator", -- matheu09173
    [839333692] = "Game Moderator", -- Matheus06532
    [1004214871] = "Game Moderator", -- owner12310
    [3968854760] = "Game Moderator", -- puferyba
    [353983652] = "Game Moderator", -- Puhgee
    [2924549627] = "Game Moderator", -- rashhhh2
    [7178750309] = "Game Moderator", -- Rikumah
    [399754916] = "Game Moderator", -- sirfluf
    [7278178099] = "Game Moderator", -- thecarrotman513
    [4225513035] = "Game Moderator", -- Waitwhatb40
    [1193091081] = "Game Moderator", -- Weerdeeg
    [1290522339] = "Game Moderator", -- Xonnik921

    -- Game Tester
    [3328476579] = "Game Tester", -- 657rikgf7t6r_deleted
    [4751004788] = "Game Tester", -- Adopt_me21893
    [405807238] = "Game Tester", -- AgentSwitchblade
    [75983689] = "Game Tester", -- Agustinxd1
    [566258203] = "Game Tester", -- aidaidaiai
    [1783760731] = "Game Tester", -- AlcaponeRP1
    [3122661168] = "Game Tester", -- anomic552
    [187378148] = "Game Tester", -- AP600
    [32819957] = "Game Tester", -- asthecar
    [2270254503] = "Game Tester", -- AYOPEPOCHECK
    [3307992031] = "Game Tester", -- BaconEater171
    [4323168809] = "Game Tester", -- Bacspas3
    [1679965910] = "Game Tester", -- banana_rama0man
    [4129018777] = "Game Tester", -- BEAMEDBYU6
    [388477413] = "Game Tester", -- belucka6
    [71123508] = "Game Tester", -- BerserkerPhoenix
    [272328715] = "Game Tester", -- blueduck6
    [111282064] = "Game Tester", -- booboobooty310
    [330341352] = "Game Tester", -- breezyytsub
    [358770591] = "Game Tester", -- bude1134
    [1423307474] = "Game Tester", -- bXxlegendxXd
    [253299193] = "Game Tester", -- C4DooMB4
    [3098351403] = "Game Tester", -- Ch3et000
    [3629511297] = "Game Tester", -- Cheesyhub
    [1062012113] = "Game Tester", -- CheNyooo
    [149351059] = "Game Tester", -- ChrisKunoi
    [528878616] = "Game Tester", -- christopher_mil
    [39754447] = "Game Tester", -- convictvince
    [1166315368] = "Game Tester", -- crevette2053
    [92376478] = "Game Tester", -- dabossuSA
    [81904325] = "Game Tester", -- danailg77
    [47960346] = "Game Tester", -- darthcx
    [1740725288] = "Game Tester", -- dayrampage
    [88004813] = "Game Tester", -- dip348
    [777957956] = "Game Tester", -- Dispure
    [401977043] = "Game Tester", -- DrAgOnHeArTeD211
    [66673673] = "Game Tester", -- DrippxyMichael
    [319964782] = "Game Tester", -- duztrr
    [1843191406] = "Game Tester", -- dzixjhs
    [859559655] = "Game Tester", -- EggPlantWithSoup
    [544673905] = "Game Tester", -- Emmanuel30_05
    [964786827] = "Game Tester", -- erendu5454
    [120558923] = "Game Tester", -- Excelinq
    [528689869] = "Game Tester", -- FakeIsNotAllowed
    [1988542987] = "Game Tester", -- FatBoi8901
    [1112958760] = "Game Tester", -- fgteevsean12321
    [30925626] = "Game Tester", -- FortisAegis
    [209024298] = "Game Tester", -- freemonys
    [296957574] = "Game Tester", -- gabito224
    [4112832247] = "Game Tester", -- GAMMINGPRO9876
    [1211266317] = "Game Tester", -- GirlsAreConfusing
    [158711542] = "Game Tester", -- goochoo22
    [2908991078] = "Game Tester", -- Graydog_111
    [1369925187] = "Game Tester", -- HARIS21927
    [30420315] = "Game Tester", -- Hawj915
    [2411276967] = "Game Tester", -- hexxedVA
    [596842880] = "Game Tester", -- heybebey
    [369096190] = "Game Tester", -- hhhhhsha
    [294520324] = "Game Tester", -- hi1343344
    [354616370] = "Game Tester", -- hmmRaze
    [152602534] = "Game Tester", -- Huys_ThePvpNoob
    [5155592767] = "Game Tester", -- Iam2proud
    [2736604977] = "Game Tester", -- IamGreat400
    [744002430] = "Game Tester", -- il_rest
    [1003354757] = "Game Tester", -- ilikemuffins143
    [476384450] = "Game Tester", -- IlliteritWarden
    [89357392] = "Game Tester", -- Inferno3745
    [839169788] = "Game Tester", -- Itslettuce58976
    [125119895] = "Game Tester", -- jamesblast07
    [81244502] = "Game Tester", -- jhanix1
    [19572046] = "Game Tester", -- jockinjack
    [4818964581] = "Game Tester", -- Joex0fficial
    [266587090] = "Game Tester", -- judgemylove
    [113864715] = "Game Tester", -- justingamer20007
    [1825000373] = "Game Tester", -- Jxrvo
    [3129484805] = "Game Tester", -- kitcatIover
    [147963748] = "Game Tester", -- kkmoney225
    [943493706] = "Game Tester", -- knightgaming40
    [720369995] = "Game Tester", -- kondraccky_805
    [589240045] = "Game Tester", -- kyecooper199
    [110703379] = "Game Tester", -- lavalthelion101
    [121539737] = "Game Tester", -- ldryantran
    [2793699387] = "Game Tester", -- LilSaltines
    [462735927] = "Game Tester", -- ljh142
    [207850384] = "Game Tester", -- LonelyDwayne
    [54187785] = "Game Tester", -- LordVolta
    [93490819] = "Game Tester", -- madwolfman567
    [107643044] = "Game Tester", -- MaloniPepperoni
    [4178829350] = "Game Tester", -- maniatako922
    [1467807563] = "Game Tester", -- McJerry09
    [15068817] = "Game Tester", -- millesy98
    [1682565633] = "Game Tester", -- MXTHXIS
    [1739291317] = "Game Tester", -- N1sshoku
    [4169625678] = "Game Tester", -- Nag_Fatality
    [3336944186] = "Game Tester", -- namcygd
    [104802564] = "Game Tester", -- NoProfits
    [471184676] = "Game Tester", -- NotReallyTeal
    [1435261209] = "Game Tester", -- occss
    [36681613] = "Game Tester", -- OofyBloxx
    [173703440] = "Game Tester", -- pablothemix
    [53147489] = "Game Tester", -- pickleman703
    [105326410] = "Game Tester", -- PilotClassic
    [1903573421] = "Game Tester", -- PointMelon
    [1196539159] = "Game Tester", -- PrettylBoi
    [32511642] = "Game Tester", -- PurpleWildcat_TV
    [495196468] = "Game Tester", -- Q_rt0254
    [47600679] = "Game Tester", -- qasd5234
    [2007113987] = "Game Tester", -- Railzeur123
    [651067419] = "Game Tester", -- RainZero14
    [1430722279] = "Game Tester", -- Rand0m_dudd
    [199995959] = "Game Tester", -- Rblizzard2
    [53123109] = "Game Tester", -- ReggieMysticKush
    [3144275918] = "Game Tester", -- rek_tf
    [68032793] = "Game Tester", -- RetakeX
    [701681929] = "Game Tester", -- ricepowertograin
    [1487454844] = "Game Tester", -- RipperExistence
    [136244389] = "Game Tester", -- rmfoshocmd
    [2325994781] = "Game Tester", -- roblox_user_2325994781
    [1651300462] = "Game Tester", -- RobyNeT212006
    [769361337] = "Game Tester", -- Rovive_Academy
    [2402742033] = "Game Tester", -- s4nt1ms_kruc
    [92269758] = "Game Tester", -- Salad_Time
    [1238641965] = "Game Tester", -- segantionelton
    [2024926585] = "Game Tester", -- shadows_rin
    [2618080172] = "Game Tester", -- shoetermcgavinn
    [58895799] = "Game Tester", -- shorty8838
    [129861303] = "Game Tester", -- Slightly_Vexed
    [885074899] = "Game Tester", -- snooppuppy100
    [506132522] = "Game Tester", -- soggoni0124
    [601480881] = "Game Tester", -- solderdamon2
    [51256414] = "Game Tester", -- Sovrigh
    [2216129561] = "Game Tester", -- StEpSiS546
    [111275810] = "Game Tester", -- SuddenBog2003
    [75094576] = "Game Tester", -- superspeedymillien
    [828629819] = "Game Tester", -- supremedisgrace
    [302699989] = "Game Tester", -- talktodoves
    [3156776755] = "Game Tester", -- tewibod123
    [636711290] = "Game Tester", -- theDfizzle
    [460894635] = "Game Tester", -- TheForgottenNoob665
    [186496434] = "Game Tester", -- TheWingedGuest
    [436367347] = "Game Tester", -- timascool
    [122885852] = "Game Tester", -- TjTheBandit
    [1854518141] = "Game Tester", -- ToeNae
    [1238384774] = "Game Tester", -- universe_slayer3
    [140188350] = "Game Tester", -- UTVoidDreemurr
    [880282497] = "Game Tester", -- wardog6543211
    [2774417571] = "Game Tester", -- wisn214
    [35408811] = "Game Tester", -- wookey12
    [865455244] = "Game Tester", -- xdkillers21
    [1074469795] = "Game Tester", -- xRavageures
    [143666227] = "Game Tester", -- xshadowb910
    [193244642] = "Game Tester", -- xToxi
    [370428947] = "Game Tester", -- XxAlphaSquadX
    [410533487] = "Game Tester", -- Xxdeathuserx
    [1919836380] = "Game Tester", -- xxxchrisbrofist
    [2961878034] = "Game Tester", -- xxxtr1plex
    [1317389983] = "Game Tester", -- Y0qh
    [4520170314] = "Game Tester", -- YET_YTY
    [385583913] = "Game Tester", -- yigido201
    [3960654237] = "Game Tester", -- YuhImHimN
    [25352140] = "Game Tester", -- Yumeissotuffandcute
    [2277409973] = "Game Tester", -- zh00on

    -- OG
    [436380269] = "OG", -- acount51
    [90699110] = "OG", -- Charlogo318
    [135830651] = "OG", -- CustomChance
    [519325044] = "OG", -- epicgamergup
    [729090464] = "OG", -- erikunasX
    [36681298] = "OG", -- ipatdress
    [91044471] = "OG", -- jacobplayer555
    [75090191] = "OG", -- Militarysoup98533
    [97246381] = "OG", -- nimb1e
    [227286903] = "OG", -- OnlySoap
    [80659656] = "OG", -- pixxleatedderp
    [676856598] = "OG", -- Spoopy_Birb
    [41053073] = "OG", -- Ultramahsuperman102
    [164058661] = "OG", -- Zeus24X
}

function M.short_label(role)
    if not role then return "STAFF" end
    if role == "Game Moderator" then return "MOD" end
    if role == "Game Tester" then return "TESTER" end
    if role == "Lead Developer" or role == "Developers" then return "DEV" end
    if role == "Co-Founder" then return "CO-FOUNDER" end
    if role == "Founder" then return "FOUNDER" end
    if role == "OG" then return "OG" end
    if role == "Contribution" then return "CONTRIB" end
    return role:upper()
end

function M.glyph_kind(role)
    if not role then return "staff" end
    local r = role:lower()
    if r:find("moderator", 1, true) then return "mod" end
    if r:find("tester", 1, true) then return "tester" end
    if r:find("developer", 1, true) or r:find("founder", 1, true) then return "dev" end
    if r == "og" then return "og" end
    if r:find("contribution", 1, true) then return "contrib" end
    return "staff"
end

local function normalize_uid(user_id)
    local uid = tonumber(user_id)
    if not uid or uid == 0 then return nil end
    return uid
end

M._player_roles = {}

local function mod_group()
    return April.require("game.mod_group")
end

local function player_state()
    return April.require("game.player_state")
end

function M.reset_session()
    M._player_roles = {}
    local group = mod_group()
    if group.reset_session then
        group.reset_session()
    end
end

function M.clear_role_cache()
    M._player_roles = {}
end

function M.invalidate_uid(user_id)
    local uid = normalize_uid(user_id)
    if uid then
        M._player_roles[uid] = nil
    end
end

local function cache_key(player)
    local uid = normalize_uid(player.user_id)
    if uid then return uid end
    return player.name or player.display_name
end

local function read_cached_role(key)
    if key == nil then return nil, false end
    if M._player_roles[key] == nil then
        return nil, false
    end
    local cached = M._player_roles[key]
    if cached == false then return nil, true end
    return cached, true
end

local function write_cached_role(key, role)
    if key == nil then return end
    M._player_roles[key] = role or false
end

local function role_from_game_tag(player)
    local tag = player_state().staff_tag(player)
    if tag == "OWNER" then return "Founder" end
    if tag == "ADMIN" then return "Developers" end
    if tag == "MOD" then return "Game Moderator" end
    return nil
end

function M.role_for(user_id)
    local uid = normalize_uid(user_id)
    if not uid then return nil end

    local group = mod_group()
    if group.available() then
        group.ensure_started()
        local live = group.role_for(uid)
        if live then return live end
    end

    return M.ROLES[uid]
end

function M.role_for_player(player, opts)
    if not player or player.is_local then return nil end
    opts = opts or {}

    local key = cache_key(player)
    local cached, hit = read_cached_role(key)
    if hit then
        return cached
    end

    local tag_role = role_from_game_tag(player)
    if tag_role then
        local uid = normalize_uid(player.user_id)
        if uid then
            local precise = M.role_for(uid)
            if precise then
                write_cached_role(key, precise)
                return precise
            end
        end
        write_cached_role(key, tag_role)
        return tag_role
    end

    local uid = normalize_uid(player.user_id)
    if not uid then
        write_cached_role(key, false)
        return nil
    end

    local group = mod_group()
    if group.available() then
        group.ensure_started()
        local live = group.role_for(uid)
        if live then
            write_cached_role(key, live)
            return live
        end
        if opts.queue_lookup then
            group.queue_lookup(uid)
        end
    end

    local static_role = M.ROLES[uid]
    if static_role then
        write_cached_role(key, static_role)
        return static_role
    end

    if opts.mark_unknown then
        write_cached_role(key, false)
    end

    return nil
end

function M.is_mod(user_id)
    return M.role_for(user_id) ~= nil
end

function M.is_staff_player(player)
    return M.role_for_player(player) ~= nil
end

function M.ensure_started()
    local group = mod_group()
    if group.available() then
        group.ensure_started()
    end
end

function M.tick()
    M.ensure_started()
end

function M.invalidate_player(player)
    if not player then return end
    local key = cache_key(player)
    if key ~= nil then
        M._player_roles[key] = nil
    end
end

return M

end)()

-- ── game/mod_group.lua ──
April._mods["game.mod_group"] = (function()
local debug = April.require("core.debug")

local M = {}

M.GROUP_ID = 1154360
M.MIN_STAFF_RANK = 6 -- above Fan (rank 5)

M._cache = {}
M._cache_ready = false
M._cache_at = 0
M._refresh_ms = 30 * 60 * 1000
M._refreshing = false
M._started = false
M._thread_id = nil

M._lookup_queue = {}
M._lookup_seen = {}
M._lookup_pending = {}
M._lookup_interval_ms = 1500
M._lookup_thread_id = nil

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function http_ready()
    return utility and type(utility.http_get) == "function"
end

local function http_ok(body, status)
    if not body or body == "" then return false end
    if status == nil then return true end
    return status >= 200 and status < 300
end

local function normalize_uid(user_id)
    local uid = tonumber(user_id)
    if not uid or uid == 0 then return nil end
    return uid
end

function M.available()
    return http_ready()
end

function M.role_for(user_id)
    local uid = normalize_uid(user_id)
    if not uid then return nil end
    return M._cache[uid]
end

function M.is_ready()
    return M._cache_ready
end

function M.reset_session()
    M._lookup_queue = {}
    M._lookup_pending = {}
    M._lookup_seen = {}
    M._cache_at = 0
end

local function parse_next_cursor(body)
    if not body then return nil end
    local cursor = body:match('"nextPageCursor":"([^"]+)"')
    if not cursor or cursor == "" or cursor == "null" then return nil end
    return cursor
end

local function parse_role_users(body, role_name, out)
    if not body or not role_name or not out then return out end
    for user_id in body:gmatch('"userId":%s*(%d+)') do
        local uid = tonumber(user_id)
        if uid then out[uid] = role_name end
    end
    return out
end

local function parse_staff_roles(body)
    local roles = {}
    if not body then return roles end

    for id, name, rank in body:gmatch('"id":%s*(%d+)%s*,%s*"name":%s*"([^"]+)"%s*,%s*"rank":%s*(%d+)') do
        local r = tonumber(rank)
        if r and r >= M.MIN_STAFF_RANK then
            roles[tonumber(id)] = name
        end
    end

    return roles
end

local function fetch_role_page(role_id, role_name, cursor, out)
    local url = string.format(
        "https://groups.roblox.com/v1/groups/%d/roles/%d/users?limit=100&sortOrder=Asc",
        M.GROUP_ID,
        role_id
    )
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. cursor
    end

    local body, status = utility.http_get(url)
    if not http_ok(body, status) then
        return false, out, nil
    end

    parse_role_users(body, role_name, out)
    return true, out, parse_next_cursor(body)
end

local function fetch_all_role_users(role_id, role_name, out)
    local cursor = nil
    repeat
        local ok
        ok, out, cursor = fetch_role_page(role_id, role_name, cursor, out)
        if not ok then return false end
    until not cursor
    return true
end

function M.refresh_all()
    if not http_ready() then return false end
    if M._refreshing then return false end

    M._refreshing = true
    local ok, err = pcall(function()
        local body, status = utility.http_get(string.format(
            "https://groups.roblox.com/v1/groups/%d/roles",
            M.GROUP_ID
        ))
        if not http_ok(body, status) then
            error("roles request failed: " .. tostring(status))
        end

        local staff_roles = parse_staff_roles(body)
        local merged = {}
        local role_count = 0

        for role_id, role_name in pairs(staff_roles) do
            role_count = role_count + 1
            if not fetch_all_role_users(role_id, role_name, merged) then
                error("role users request failed for " .. tostring(role_name))
            end
        end

        M._cache = merged
        M._cache_ready = true
        M._cache_at = tick_ms()

        pcall(function()
            local ids = April.require("game.mod_ids")
            if ids.clear_role_cache then ids.clear_role_cache() end
        end)

        if April and April.debug then
            local n = 0
            for _ in pairs(merged) do n = n + 1 end
            debug.log(string.format("Mod group cache refreshed (%d staff, %d roles)", n, role_count))
        end
    end)

    M._refreshing = false

    if not ok then
        debug.error_once("mod_group:refresh", err)
        return false
    end

    return true
end

local function parse_user_group_role(body)
    if not body or body == "" then return nil end

    local gid = tostring(M.GROUP_ID)
    local pos = 1

    while true do
        local gs = body:find('"group"', pos, true)
        if not gs then break end

        local chunk = body:sub(gs, math.min(#body, gs + 420))
        local group_id = chunk:match('"id":%s*(%d+)')
        if group_id == gid then
            local role_chunk = chunk:match('"role":%s*{(.-)%}')
            if role_chunk then
                local rank = tonumber(role_chunk:match('"rank":%s*(%d+)'))
                local name = role_chunk:match('"name":%s*"([^"]+)"')
                if rank and name then
                    if rank >= M.MIN_STAFF_RANK then
                        return name
                    end
                    return false
                end
            end
            return nil
        end

        pos = gs + 7
    end

    return nil
end

function M.lookup_user(user_id)
    local uid = normalize_uid(user_id)
    if not uid or not http_ready() then return nil end

    if M._cache[uid] then return M._cache[uid] end

    local body, status = utility.http_get(string.format(
        "https://groups.roblox.com/v2/users/%d/groups/roles",
        uid
    ))
    if not http_ok(body, status) then return nil end

    local role = parse_user_group_role(body)
    if role == false then
        M._lookup_seen[uid] = true
        return nil
    end
    if role then
        M._cache[uid] = role
        M._cache_ready = true
        M._lookup_seen[uid] = true
        pcall(function()
            local ids = April.require("game.mod_ids")
            if ids.invalidate_uid then ids.invalidate_uid(uid) end
        end)
        return role
    end

    M._lookup_seen[uid] = true
    return nil
end

function M.queue_lookup(user_id)
    local uid = normalize_uid(user_id)
    if not uid then return end
    if M._cache[uid] or M._lookup_seen[uid] or M._lookup_pending[uid] then return end

    M._lookup_pending[uid] = true
    M._lookup_queue[#M._lookup_queue + 1] = uid
end

local function process_lookup_queue()
    if #M._lookup_queue == 0 then return end

    local uid = table.remove(M._lookup_queue, 1)
    M._lookup_pending[uid] = nil
    local ok, err = pcall(M.lookup_user, uid)
    if not ok then
        debug.error_once("mod_group:lookup", err)
    end
end

function M.ensure_started()
    if M._started then return end
    M._started = true

    if not http_ready() then return end

    if thread and thread.create then
        M._thread_id = thread.create(function()
            local now = tick_ms()
            if not M._cache_ready or (now - M._cache_at) >= M._refresh_ms then
                M.refresh_all()
            end
        end, 5000)

        M._lookup_thread_id = thread.create(function()
            process_lookup_queue()
        end, M._lookup_interval_ms)
    else
        M.refresh_all()
    end
end

function M.tick()
    M.ensure_started()
end

function M.force_refresh()
    M._cache_at = 0
    return M.refresh_all()
end

return M

end)()

-- ── core/settings.lua ──
April._mods["core.settings"] = (function()
local M = {}

local _callbacks = {}

function M.invalidate() end

function M.get(id, default)
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    return default
end

function M.bool(id, default)
    local v = M.get(id, default)
    if v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.enabled(id)
    local ok, fb = pcall(function()
        return April.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(id) then
        return fb.active(id)
    end

    return M.bool(id, false)
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

local function as_bool(v, default)
    if v == nil then
        return default == true
    end
    if v == true or v == 1 or v == "1" or v == "true" or v == "True" then
        return true
    end
    if v == false or v == 0 or v == "0" or v == "false" or v == "False" then
        return false
    end
    return default == true
end

-- Multicombo slot (1-based). Accepts bool / 0|1 / "0"|"1"|"true"|"false".
function M.multi(id, index, default)
    local t = M.get(id)
    if type(t) ~= "table" then
        return default == true
    end
    -- Prefer 1-based. Only fall back to 0-based when the 1-based slot is absent.
    if t[index] ~= nil then
        return as_bool(t[index], default)
    end
    if index >= 1 and t[index - 1] ~= nil then
        return as_bool(t[index - 1], default)
    end
    return default == true
end

function M.combo_index(id, labels, default)
    default = default or 0
    local v = M.get(id, default)
    if type(v) == "string" then
        local lower = v:lower()
        for i, label in ipairs(labels or {}) do
            if label:lower() == lower then return i - 1 end
        end
        return default
    end
    local n = tonumber(v)
    if n == nil then return default end
    return n
end

function M.str(id, default)
    local v = M.get(id, default)
    if v == nil then return default or "" end
    return tostring(v)
end

function M.color(id, default)
    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then return c end
    end
    return default or { 1, 1, 1, 1 }
end

function M.on_change(id, fn)
    if not id or not fn then return end

    _callbacks[id] = _callbacks[id] or {}
    _callbacks[id][#_callbacks[id] + 1] = fn

    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            for _, cb in ipairs(_callbacks[id] or {}) do
                pcall(cb, new_val)
            end
        end)
    end
end

function M.flush() end
function M.mark_dirty() end

return M

end)()

-- ── core/feature_bind.lua ──
April._mods["core.feature_bind"] = (function()
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

function M.hide_key_id(id)
    return id .. "_hide_kb"
end

function M.is_hidden_from_list(id)
    return settings.bool(M.hide_key_id(id), false)
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

end)()

-- ── core/aim_key.lua ──
April._mods["core.aim_key"] = (function()
-- Aim-key state (Always / Hold / Toggle) separate from feature master toggle.
local settings = April.require("core.settings")

local M = {}

M.MODES = { "Always", "Hold", "Toggle" }

local toggled = {}
local last_down = {}

local function key_store()
    return April.require("ui.gs_state")
end

function M.mode_index(mode_id)
    return settings.combo_index(mode_id, M.MODES, 0)
end

function M.tick(key_id, mode_id)
    if not input or not input.is_key_down then return end
    local mode = M.mode_index(mode_id)
    local vk = key_store().get_key(key_id)
    if mode == 0 then
        if vk > 0 then last_down[key_id] = input.is_key_down(vk) end
        return
    end
    if vk <= 0 then return end
    local down = input.is_key_down(vk)
    if mode == 1 then
        last_down[key_id] = down
        return
    end
    -- Toggle
    if down and not last_down[key_id] then
        toggled[key_id] = not (toggled[key_id] == true)
    end
    last_down[key_id] = down
end

function M.active(key_id, mode_id)
    local mode = M.mode_index(mode_id)
    if mode == 0 then return true end
    local vk = key_store().get_key(key_id)
    if vk <= 0 then return mode == 0 end
    if mode == 1 then
        return input and input.is_key_down and input.is_key_down(vk)
    end
    return toggled[key_id] == true
end

function M.reset(key_id)
    toggled[key_id] = false
    last_down[key_id] = false
end

return M

end)()

-- ── core/draw_util.lua ──
April._mods["core.draw_util"] = (function()
local math_util = April.require("core.math_util")
local text_util = April.require("core.text_util")

local M = {}

function M.white(r, g, b, a)
    return { r or 1, g or 1, b or 1, a or 1 }
end

function M.text_centered(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    text = text_util.sanitize(text)
    local tw, th = draw.get_text_size(text, size or 14)
    draw.text(x - tw * 0.5, y, text, col, size or 14)
end

-- Stronger silhouette for far ESP (extra soft shadow under auto outline).
function M.text_centered_strong(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    text = text_util.sanitize(text)
    size = size or 14
    local tw = draw.get_text_size(text, size)
    local tx = x - tw * 0.5
    local a = (col and col[4]) or 1
    local shadow = { 0, 0, 0, a * 0.55 }
    draw.text(tx + 1, y + 1, text, shadow, size)
    draw.text(tx, y, text, col, size)
end

function M.text_outlined(x, y, text, col, size)
    if not draw or not draw.text then return end
    draw.text(x, y, text_util.sanitize(text), col, size or 14)
end

function M.text(x, y, text, col, size)
    M.text_outlined(x, y, text, col, size)
end

function M.box_esp(x, y, w, h, col, style)
    if not draw then return end
    if style == 1 and draw.corner_box then
        draw.corner_box(x, y, w, h, col)
        return
    end
    if draw.box then
        draw.box(x, y, w, h, col, 0, style or 0)
    end
end

-- Soft outer box + crisp inner for readability at any range.
function M.box_esp_nice(x, y, w, h, col, style)
    if not draw then return end
    local a = (col and col[4]) or 1
    local outer = { 0, 0, 0, a * 0.7 }
    if style == 1 and draw.corner_box then
        draw.corner_box(x - 1, y - 1, w + 2, h + 2, outer)
        draw.corner_box(x, y, w, h, col)
        return
    end
    if draw.box then
        draw.box(x - 1, y - 1, w + 2, h + 2, outer, 0, 0)
        draw.box(x, y, w, h, col, 0, style or 0)
    end
end

function M.health_bar(x, y, h, hp, max_hp)
    if not draw or not draw.health_bar then return end
    draw.health_bar(x, y, h, hp, max_hp)
end

-- Pixel-precise HP bar. Native draw.health_bar has built-in left padding so it
-- always leaves a gap next to our box — do not use it for ESP.
function M.health_bar_nice(x, y, h, hp, max_hp, bar_w)
    if not draw or not draw.rect_filled then return end
    if not hp or not max_hp or max_hp <= 0 then return end

    h = math.max(4, h)
    bar_w = math.max(2, math.min(4, bar_w or 3))
    local pct = math_util.clamp(hp / max_hp, 0, 1)
    local fill_h = math.max(0, math.floor(h * pct + 0.5))

    -- Empty track
    draw.rect_filled(x, y, bar_w, h, { 0.08, 0.08, 0.08, 0.85 })

    if fill_h > 0 then
        local r, g, b
        if pct > 0.5 then
            local t = (pct - 0.5) * 2
            r, g, b = (1 - t) * 0.95, 1, 0.15
        else
            local t = pct * 2
            r, g, b = 1, t * 0.9, 0.12
        end
        draw.rect_filled(x, y + (h - fill_h), bar_w, fill_h, { r, g, b, 1 })
    end

    return bar_w
end

-- HP bar flush to the left edge of the ESP box (0px gap, no overlap).
function M.health_bar_on_box(bounds, hp, max_hp)
    if not bounds or not bounds.valid or not hp or not max_hp or max_hp <= 0 then
        return
    end
    local h = bounds.h or 0
    if h < 4 then return end

    local bar_w = 3
    if h >= 40 then
        bar_w = 4
    elseif h <= 14 then
        bar_w = 2
    end
    -- 1px gap so the bar sits next to the box without overlapping.
    M.health_bar_nice(bounds.x - bar_w - 1, bounds.y, h, hp, max_hp, bar_w)
end

function M.line(x1, y1, x2, y2, col, thick)
    if not draw or not draw.line then return end
    draw.line(x1, y1, x2, y2, col, thick or 1)
end

--- Screen snapline from bottom-center to target (classic ESP style).
function M.snapline(tx, ty, col, thick, sw, sh)
    if not draw or not draw.line then return end
    if not sw or not sh then
        local dw, dh = M.screen_size()
        sw = sw or dw
        sh = sh or dh
    end
    col = col or { 1, 1, 1, 1 }
    thick = thick or 1.5
    local sx = sw * 0.5
    local sy = sh - 1
    local a = col[4] or 1
    M.line(sx, sy, tx, ty, { 0, 0, 0, a * 0.9 }, thick + 1.5)
    M.line(sx, sy, tx, ty, col, thick)
end

function M.circle(x, y, r, col, filled)
    if not draw then return end
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, 24)
    elseif draw.circle then
        draw.circle(x, y, r, col, 24, 1)
    end
end

function M.screen_size()
    local w, h
    if draw and draw.get_screen_size then
        w, h = draw.get_screen_size()
    elseif utility and utility.get_screen_size then
        w, h = utility.get_screen_size()
    end
    if not w or w <= 0 then w = 1920 end
    if not h or h <= 0 then h = 1080 end
    return w, h
end

function M.world_label(inst, text, col, max_dist)
    if not utility or not utility.world_to_screen then return end
    local env = April.require("core.env")
    if not env.is_valid(inst) then return end
    local pos = inst.Position
    if not pos or pos.x == nil then return end

    local me = env.get_local_player()
    if me and me.position and max_dist then
        local dx = pos.x - me.position.x
        local dy = pos.y - me.position.y
        local dz = pos.z - me.position.z
        local dist = math_util.distance3(dx, dy, dz)
        if dist > max_dist then return end
        text = string.format("%s [%dm]", text, math.floor(dist))
    end

    local sx, sy, vis = utility.world_to_screen(pos.x, pos.y, pos.z)
    if vis then
        M.text_centered(sx, sy, text, col, 13)
    end
end

return M

end)()

-- ── core/vk_names.lua ──
April._mods["core.vk_names"] = (function()
-- Shared VK -> label map (matches custom UI keybind chips).
local M = {}

M.NAMES = {
    [0x01] = "M1", [0x02] = "M2", [0x04] = "M3",
    [0x08] = "BS", [0x09] = "TAB", [0x0D] = "ENT",
    [0x10] = "SHI", [0x11] = "CTL", [0x12] = "ALT",
    [0x14] = "CAP", [0x1B] = "ESC", [0x20] = "SPC",
    [0x25] = "LEFT", [0x26] = "UP", [0x27] = "RIGHT", [0x28] = "DOWN",
    [0x2D] = "INS", [0x2E] = "DEL",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
    [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
    [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
    [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
    [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y",
    [0x5A] = "Z",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
    [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8",
    [0x78] = "F9", [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12",
}

function M.label(vk)
    vk = tonumber(vk) or 0
    if vk <= 0 then return "none" end
    return M.NAMES[vk] or string.format("%02X", vk)
end

function M.chip(vk)
    return "[" .. M.label(vk) .. "]"
end

return M

end)()

-- ── core/panel_drag.lua ──
April._mods["core.panel_drag"] = (function()
-- Draggable overlay panels (mod checker, keybind viewer). Position persists via menu/gs_state.
local settings = April.require("core.settings")

local M = {}

local state = {}

local function mouse_pos()
    local mx, my = 0, 0
    if utility and utility.get_mouse_pos then
        mx, my = utility.get_mouse_pos()
    elseif input and input.get_mouse_pos then
        mx, my = input.get_mouse_pos()
    end
    return tonumber(mx) or 0, tonumber(my) or 0
end

local function lmb_down()
    return input and input.is_key_down and input.is_key_down(0x01)
end

local function persist_num(id, value)
    value = math.floor(tonumber(value) or 0)
    if menu and menu.set then
        pcall(menu.set, id, value)
    end
    pcall(function()
        April.require("ui.gs_state").set(id, value)
    end)
end

local function blocked()
    local ok, widgets = pcall(function()
        return April.require("ui.gs_widgets")
    end)
    if ok and widgets then
        if widgets.listening_key then return true end
        if widgets.dragging_window then return true end
        if widgets.interacted then return true end
    end
    return false
end

function M.clamp(x, y, w, panel_h, sw, sh, x_id, y_id)
    local old_x, old_y = x, y
    w = math.max(160, math.min(420, math.floor(w or 260)))
    panel_h = math.max(40, math.floor(panel_h or 80))
    x = math.max(0, math.min(math.max(0, sw - w), math.floor(x or 0)))
    y = math.max(0, math.min(math.max(0, sh - panel_h), math.floor(y or 0)))
    if x_id and x ~= old_x then persist_num(x_id, x) end
    if y_id and y ~= old_y then persist_num(y_id, y) end
    return x, y, w
end

--- Drag by title bar; returns clamped x, y after handling input this frame.
function M.update(id, x_id, y_id, title_w, title_h, sw, sh, default_x, default_y)
    local st = state[id]
    if not st then
        st = { was_lmb = false, dragging = false, off_x = 0, off_y = 0 }
        state[id] = st
    end

    local x = settings.num(x_id, default_x)
    local y = settings.num(y_id, default_y)
    local mx, my = mouse_pos()
    local lmb = lmb_down()
    local over_title = mx >= x and my >= y
        and mx <= x + title_w and my <= y + title_h

    if lmb and not st.was_lmb and over_title and not blocked() then
        st.dragging = true
        st.off_x = mx - x
        st.off_y = my - y
    end

    if st.dragging then
        if lmb then
            x = mx - st.off_x
            y = my - st.off_y
            persist_num(x_id, x)
            persist_num(y_id, y)
        else
            st.dragging = false
        end
    end

    st.was_lmb = lmb
    return x, y
end

return M

end)()

-- ── core/ui_theme.lua ──
April._mods["core.ui_theme"] = (function()
local draw_util = April.require("core.draw_util")
local text_util = April.require("core.text_util")
local mod_ids = April.require("game.mod_ids")

local M = {}

M.BG          = { 13 / 255, 13 / 255, 13 / 255, 0.94 }
M.PANEL       = { 18 / 255, 18 / 255, 20 / 255, 0.92 }
M.PANEL_DEEP  = { 10 / 255, 10 / 255, 12 / 255, 0.90 }
M.SLOT        = { 22 / 255, 22 / 255, 24 / 255, 0.82 }
M.SLOT_HELD   = { 28 / 255, 28 / 255, 30 / 255, 0.90 }
M.SLOT_EMPTY  = { 14 / 255, 14 / 255, 16 / 255, 0.55 }

M.CYAN        = { 0, 195 / 255, 227 / 255, 1 }
M.CYAN_SOFT   = { 0, 195 / 255, 227 / 255, 0.35 }
M.CYAN_GLOW   = { 0, 195 / 255, 227 / 255, 0.18 }

M.TEXT        = { 1, 1, 1, 0.96 }
M.TEXT_DIM    = { 128 / 255, 128 / 255, 128 / 255, 0.95 }
M.TEXT_MUTED  = { 0.62, 0.64, 0.68, 0.88 }

M.BORDER      = { 1, 1, 1, 0.08 }
M.BORDER_CYAN = { 0, 195 / 255, 227 / 255, 0.45 }

M.RED         = { 1, 0.35, 0.35, 1 }
M.ORANGE      = { 1, 0.55, 0.22, 1 }
M.PURPLE      = { 0.92, 0.45, 1, 1 }
M.GREEN       = { 0.35, 0.85, 0.55, 1 }

M.ROUND       = 4
M.MAP_BG      = { 13 / 255, 13 / 255, 13 / 255, 0.95 }
M.MAP_GRID    = { 0, 195 / 255, 227 / 255, 0.06 }
M.ACCENT      = M.CYAN
M.HEADER      = M.PANEL_DEEP
M.GLASS_HIGHLIGHT = { 1, 1, 1, 0.04 }

local function copy_alpha(col, alpha)
    return { col[1], col[2], col[3], alpha == nil and (col[4] or 1) or alpha }
end

local function mix(a, b, t, alpha)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        alpha == nil and 1 or alpha,
    }
end

-- Synchronize every draw HUD token with the active custom-menu theme.
-- Called before feature drawing, so it also works while the menu is closed.
function M.sync()
    local ok_anim, anim = pcall(function()
        return April.require("ui.gs_anim")
    end)
    if ok_anim and anim and anim.sync_theme then
        pcall(anim.sync_theme)
    end

    local ok, gs = pcall(function()
        return April.require("ui.gs_theme")
    end)
    if not ok or not gs then return false end

    local accent = gs.ACCENT or M.CYAN
    M.ACCENT = copy_alpha(accent, 1)
    M.CYAN = copy_alpha(accent, 1) -- compatibility: legacy chrome now follows accent
    M.CYAN_SOFT = copy_alpha(accent, 0.35)
    M.CYAN_GLOW = copy_alpha(accent, 0.18)

    M.BG = copy_alpha(gs.BG or M.BG, math.min(0.96, (gs.WINDOW_ALPHA or 0.86) + 0.04))
    M.PANEL = copy_alpha(gs.PANEL or M.PANEL, math.min(0.96, (gs.PANEL_ALPHA or 0.72) + 0.10))
    M.PANEL_DEEP = copy_alpha(gs.BG_INNER or M.PANEL_DEEP, math.min(0.94, (gs.PANEL_ALPHA or 0.72) + 0.08))
    M.HEADER = copy_alpha(gs.PANEL_ALT or M.PANEL_DEEP, math.min(0.98, (gs.PANEL_ALPHA or 0.72) + 0.16))
    M.SLOT = copy_alpha(gs.BUTTON or M.SLOT, math.min(0.92, (gs.PANEL_ALPHA or 0.72) + 0.08))
    M.SLOT_HELD = mix(M.SLOT, accent, 0.28, 0.94)
    M.SLOT_EMPTY = copy_alpha(gs.CHECK_OFF or M.SLOT_EMPTY, 0.58)

    M.TEXT = copy_alpha(gs.TEXT_ACTIVE or M.TEXT, 0.97)
    M.TEXT_DIM = copy_alpha(gs.TEXT_DIM or M.TEXT_DIM, 0.96)
    M.TEXT_MUTED = copy_alpha(gs.TEXT or M.TEXT_MUTED, 0.78)
    M.BORDER = copy_alpha(gs.BORDER_SOFT or M.BORDER, (gs.BORDER_SOFT and gs.BORDER_SOFT[4]) or 0.35)
    M.BORDER_CYAN = copy_alpha(gs.BORDER_HOT or accent, 0.72)
    M.GLASS_HIGHLIGHT = copy_alpha(gs.GLASS_HIGHLIGHT or M.GLASS_HIGHLIGHT)

    -- Panel chrome is always square; small semantic glyphs can remain circular.
    M.ROUND = 0
    M.MAP_BG = copy_alpha(gs.BG_INNER or M.BG, 0.90)
    M.MAP_GRID = copy_alpha(accent, 0.10)
    return true
end

function M.alpha(col, a)
    return { col[1], col[2], col[3], a }
end

function M.text_w(text, size)
    if draw and draw.get_text_size then
        return draw.get_text_size(text, size or 13)
    end
    return (#text * (size or 13) * 0.55), size or 13
end

function M.draw_panel(x, y, w, h, opts)
    if not draw then return end
    opts = opts or {}

    local bg = opts.bg or M.PANEL
    local border = opts.border or M.BORDER
    local rounding = opts.rounding ~= nil and opts.rounding or M.ROUND

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, rounding)
    end
    if draw.rect then
        draw.rect(x, y, w, h, border, rounding, opts.border_w or 1)
    end

    if opts.accent and draw.line then
        local ax = x + (rounding > 0 and 1 or 0)
        local aw = w - (rounding > 0 and 2 or 0)
        draw.line(ax, y, ax + aw, y, opts.accent, opts.accent_w or 2)
    end

    if opts.accent_left and draw.line then
        draw.line(x, y + 1, x, y + h - 1, opts.accent_left, opts.accent_w or 2)
    end
end

function M.draw_section_title(x, y, title, col)
    col = col or M.CYAN
    draw_util.text(x, y, title, col, 13)
end

function M.draw_tooltip_box(x, y, lines)
    if not draw or not lines or #lines == 0 then return end
    lines = type(lines) == "table" and lines or { tostring(lines) }

    local fs = 12
    local pad = 8
    local tw = 0
    for i = 1, #lines do
        local w = select(1, M.text_w(lines[i], fs))
        if w > tw then tw = w end
    end

    local box_w = tw + pad * 2
    local box_h = #lines * 14 + pad * 2
    local sw = select(1, draw_util.screen_size())
    x = math.min(x, sw - box_w - 12)
    y = math.max(y, 8)

    M.draw_panel(x, y, box_w, box_h, {
        bg = M.alpha(M.PANEL, 0.96),
        accent = M.CYAN,
        rounding = M.ROUND,
    })

    for i = 1, #lines do
        local col = (i == 1) and M.TEXT or M.TEXT_MUTED
        draw_util.text(x + pad, y + pad + (i - 1) * 14, lines[i], col, fs)
    end
end

function M.toast_accent(ntype)
    if ntype == "danger" then return M.RED end
    if ntype == "warning" then return M.ORANGE end
    if ntype == "success" then return M.CYAN end
    return M.CYAN
end

function M.role_accent(role)
    if not role then return M.CYAN end
    local r = role:lower()
    if r:find("founder") or r:find("developer") then return M.PURPLE end
    if r:find("moderator") then return M.RED end
    if r:find("tester") then return M.ORANGE end
    if r == "og" or r:find("contribution") then return M.CYAN end
    return M.CYAN
end

function M.draw_role_glyph(x, y, size, kind, accent)
    if not draw then return end
    local cx = x + size * 0.5
    local cy = y + size * 0.5
    local r, g, b, a = accent[1] or 1, accent[2] or 1, accent[3] or 1, accent[4] or 1

    if kind == "mod" then
        local h = size * 0.82
        local half = h * 0.46
        if draw.poly_filled then
            draw.poly_filled({
                { cx, y + 1 },
                { cx - half, y + h },
                { cx + half, y + h },
            }, r, g, b, a)
        end
        if draw.text then
            draw.text(cx - 2, y + size * 0.34, "!", { 1, 1, 1, 0.95 }, math.max(8, math.floor(size * 0.62)))
        end
    elseif kind == "tester" then
        if draw.rect_filled then
            draw.rect_filled(x + 1, y + 2, size - 2, size - 3, { r, g, b, a * 0.9 }, 3)
        end
        if draw.text then
            local fs = math.max(8, math.floor(size * 0.58))
            local tw = select(1, M.text_w("T", fs))
            draw.text(cx - tw * 0.5, y + size * 0.22, "T", { 1, 1, 1, 0.95 }, fs)
        end
    elseif kind == "dev" then
        if draw.rect_filled then
            draw.rect_filled(x + 1, y + 2, size - 2, size - 3, { r, g, b, a * 0.35 }, 3)
        end
        if draw.text then
            local fs = math.max(7, math.floor(size * 0.42))
            draw.text(x + 2, y + size * 0.18, "</>", { r, g, b, a }, fs)
        end
    elseif kind == "og" or kind == "contrib" then
        if draw.circle_filled then
            draw.circle_filled(cx, cy, size * 0.34, { r, g, b, a }, 12)
        end
        if draw.text then
            local ch = kind == "og" and "O" or "C"
            local fs = math.max(8, math.floor(size * 0.5))
            local tw = select(1, M.text_w(ch, fs))
            draw.text(cx - tw * 0.5, y + size * 0.24, ch, { 1, 1, 1, 0.95 }, fs)
        end
    else
        if draw.circle_filled then
            draw.circle_filled(cx, cy, size * 0.3, { r, g, b, a }, 10)
        end
    end
end

function M.draw_staff_badge(sx, sy, role)
    if not draw or not draw.text then return end

    local label = mod_ids.short_label(role)
    local accent = M.role_accent(role)
    local glyph = mod_ids.glyph_kind(role)
    local fs = 11
    local icon_size = 14
    local gap = 4
    local pad_x, pad_y = 6, 4
    local tw = select(1, M.text_w(label, fs))
    local w = pad_x * 2 + icon_size + gap + tw
    local h = pad_y * 2 + math.max(icon_size, fs + 2)
    local x = math.floor(sx - w * 0.5)
    local y = math.floor(sy - h - 8)

    M.draw_panel(x, y, w, h, {
        bg = M.alpha(M.BG, 0.86),
        border = M.alpha(M.BORDER, 0.35),
        accent = accent,
        accent_w = 2,
        rounding = 3,
    })

    M.draw_role_glyph(x + pad_x, y + pad_y, icon_size, glyph, accent)
    draw.text(x + pad_x + icon_size + gap, y + pad_y + 1, label, accent, fs)
end

function M.draw_mod_marker(sx, sy, _image_cache, _icon_key, role)
    M.draw_staff_badge(sx, sy, role or "Game Moderator")
end

function M.draw_staff_list(x, y, width, rows, max_rows)
    if not draw or not draw.text or not rows or #rows == 0 then return end

    max_rows = max_rows or 4
    local pad = 10
    local title_h = 24
    local row_h = 44
    local count = math.min(#rows, max_rows)
    local height = title_h + count * row_h + 6

    M.draw_panel(x, y, width, height, {
        bg = M.alpha(M.BG, 0.90),
        border = M.alpha(M.BORDER, 0.45),
        accent = M.RED,
        accent_w = 2,
        rounding = M.ROUND,
    })

    draw_util.text(x + pad, y + 6, "Staff In Lobby", M.TEXT, 12)

    local div_y = y + title_h
    if draw.line then
        draw.line(x + pad, div_y, x + width - pad, div_y, M.alpha(M.BORDER, 0.55), 1)
    end

    local ry = div_y + 6
    for i = 1, count do
        local row = rows[i]
        local accent = row.accent or M.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, M.alpha(M.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, accent, 8)
        end

        local name = text_util.sanitize(row.name or "?")
        if #name > 20 then name = name:sub(1, 18) .. ".." end
        draw.text(x + pad + 12, ry, name, M.TEXT, 13)

        local role = text_util.sanitize(row.role or "Staff")
        if #role > 24 then role = role:sub(1, 22) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, text_util.sanitize(row.meta), M.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end
end

return M

end)()

-- ── core/overlay_theme.lua ──
April._mods["core.overlay_theme"] = (function()
-- Theme helpers for draggable overlay panels (keybind viewer, mod checker).
local ui_theme = April.require("core.ui_theme")

local M = {}

local function gs_theme()
    local ok, theme = pcall(function()
        return April.require("ui.gs_theme")
    end)
    if ok then return theme end
    return nil
end

local function anim_mod()
    local ok, anim = pcall(function()
        return April.require("ui.gs_anim")
    end)
    if ok then return anim end
    return nil
end

function M.sync()
    if ui_theme.sync then pcall(ui_theme.sync) end
end

function M.accent()
    local anim = anim_mod()
    if anim and anim.colors_enabled and anim.colors_enabled() then
        return anim.element_color(7, anim.COL_OVERLAY)
    end
    local gs = gs_theme()
    if gs and gs.ACCENT then
        return gs.ACCENT
    end
    return ui_theme.CYAN
end

function M.panel_bg()
    return ui_theme.PANEL
end

function M.header_bg()
    return ui_theme.HEADER
end

function M.border(alpha)
    return ui_theme.alpha(ui_theme.BORDER, alpha or (ui_theme.BORDER[4] or 0.45))
end

function M.text()
    return ui_theme.TEXT
end

function M.text_muted()
    return ui_theme.TEXT_MUTED
end

function M.slot(kind)
    if kind == "held" then return ui_theme.SLOT_HELD end
    if kind == "empty" then return ui_theme.SLOT_EMPTY end
    return ui_theme.SLOT
end

function M.draw_accent_bar(x, y, w, h, alpha)
    h = h or 2
    alpha = alpha == nil and 1 or alpha
    local anim = anim_mod()
    if alpha >= 0.99 and anim and anim.anim_enabled and anim.anim_enabled()
        and anim.anim_target_enabled and anim.anim_target_enabled(anim.TARGET_OVERLAY) then
        anim.draw_bar_h(x, y, w, h, anim.phase and (anim.phase() * 0.1) or 0,
            anim.STYLE_OVERLAY, anim.COL_OVERLAY, anim.TARGET_OVERLAY)
        return
    end
    if draw and draw.line then
        local col = ui_theme.alpha(M.accent(), alpha)
        draw.line(x, y, x + w, y, col, h)
    end
end

function M.panel_opts()
    return {
        bg = M.panel_bg(),
        border = M.border(),
        rounding = 0,
        accent = nil,
        accent_w = 0,
    }
end

function M.draw_panel(x, y, w, h, title, opts)
    opts = opts or {}
    ui_theme.draw_panel(x, y, w, h, M.panel_opts())
    if draw and draw.rect_filled then
        draw.rect_filled(x + 1, y + 3, w - 2, 21, M.header_bg(), 0)
    end
    M.draw_accent_bar(x + 1, y, w - 2, 2)
    if title and draw and draw.text then
        if opts.title_center then
            local tw = ui_theme.text_w(title, 11)
            draw.text(x + (w - tw) * 0.5, y + 6, title, M.text(), 11)
        else
            draw.text(x + 9, y + 6, title, M.text(), 11)
        end
    end
end

return M

end)()

-- ── core/notify.lua ──
April._mods["core.notify"] = (function()
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local text_util = April.require("core.text_util")

local M = {}
local queue = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function M.show(msg, ntype, duration_ms)
    M.toast(msg, ntype, duration_ms, false)
end

function M.toast(msg, ntype, duration_ms, skip_dedupe)
    if not msg or msg == "" then return end
    msg = text_util.sanitize(msg)
    ntype = ntype or "warning"
    duration_ms = duration_ms or 5000

    if not skip_dedupe then
        for _, n in ipairs(queue) do
            if n.msg == msg and (tick() - n.time) < 3000 then return end
        end
    end

    if menu and menu.notify then
        pcall(function() menu.notify(msg) end)
    end

    table.insert(queue, {
        msg = msg,
        type = ntype,
        time = tick(),
        duration = duration_ms,
        alpha = 0,
        x_off = 80,
        y = 0,
    })

    while #queue > 6 do
        table.remove(queue, 1)
    end
end

function M.warning(msg, duration_ms)
    M.show(msg, "warning", duration_ms)
end

function M.success(msg, duration_ms)
    M.show(msg, "success", duration_ms)
end

function M.error(msg, duration_ms)
    M.show(msg, "danger", duration_ms)
end

function M.info(msg, duration_ms)
    M.show(msg, "info", duration_ms)
end

function M.draw()
    if #queue == 0 or not draw then return end

    overlay_theme.sync()
    local now = tick()
    local font = 13
    local pad = 12
    local gap = 8
    local target_y = 18

    for i = #queue, 1, -1 do
        local n = queue[i]
        local elapsed = now - n.time
        if elapsed > n.duration then
            table.remove(queue, i)
        else
            local fade = 350
            local target_alpha = 1
            if elapsed < fade then
                target_alpha = elapsed / fade
            elseif elapsed > n.duration - fade then
                target_alpha = (n.duration - elapsed) / fade
            end
            n.alpha = lerp(n.alpha or 0, target_alpha, 0.18)

            local slide = 0
            if elapsed > n.duration - fade then slide = 60 end
            n.x_off = lerp(n.x_off or 80, slide, 0.15)

            if n.y == 0 then n.y = target_y end
            n.y = lerp(n.y, target_y, 0.2)

            local accent = theme.toast_accent(n.type)
            local tw = select(1, theme.text_w(n.msg, font))
            local box_w = tw + pad * 2 + 4
            local box_h = font + pad * 2
            local sw = select(1, draw_util.screen_size())
            local x = sw - box_w - 16 + (n.x_off or 0)
            local y = n.y
            local a = n.alpha or 1

            theme.draw_panel(x, y, box_w, box_h, {
                bg = theme.alpha(overlay_theme.panel_bg(), 0.94 * a),
                border = theme.alpha(overlay_theme.border(), 0.58 * a),
                accent = theme.alpha(accent, a),
                accent_w = 2,
                rounding = 0,
            })
            overlay_theme.draw_accent_bar(x + 2, y, box_w - 3, 2, a)

            if draw.text then
                draw.text(x + pad, y + pad - 1, n.msg, theme.alpha(theme.TEXT, a), font)
            end

            target_y = target_y + box_h + gap
        end
    end
end

return M

end)()

-- ── game/asset_urls.lua ──
April._mods["game.asset_urls"] = (function()
local M = {}

M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.rbx_asset(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return "rbxassetid://" .. asset_id
end

function M.roblox_asset_http(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return "http://www.roblox.com/asset/?id=" .. asset_id
end

function M.roblox_thumb(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=%s",
        asset_id
    )
end

function M.asset_delivery(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("https://assetdelivery.roblox.com/v1/asset/?id=%s", asset_id)
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.mod_warning_png()
    return M.CDN_BASE .. "/mod_warning.png"
end

return M

end)()

-- ── core/image_cache.lua ──
April._mods["core.image_cache"] = (function()
--[[
    Vector on_frame pattern (stable v3.65-3.69):
      handle = draw.load_image(url) once
      draw.image(handle, x, y, w, h, 255, 255, 255, 255) every frame - no-ops until ready
    Do NOT gate on draw.image_loaded; that breaks gear icons on Vector.
]]

local asset_urls = April.require("game.asset_urls")
local debug = April.require("core.debug")

local M = {}

local keys = {}

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" then
        if asset_id_or_url:find("https://", 1, true)
            or asset_id_or_url:find("http://", 1, true)
            or asset_id_or_url:find("rbxassetid://", 1, true) then
            return asset_id_or_url
        end
    end
    return asset_urls.item_png(asset_id_or_url)
end

local function asset_digits(asset_id_or_url)
    if asset_id_or_url == nil then return nil end
    if type(asset_id_or_url) == "number" then return tostring(asset_id_or_url) end
    return tostring(asset_id_or_url):match("(%d+)$") or tostring(asset_id_or_url):match("^(%d+)$")
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then return keys[key] end
    local url = url_for(asset_id_or_url)
    if not url then return nil end
    keys[key] = {
        url = url,
        asset_id = asset_digits(asset_id_or_url),
        handle = nil,
        failed = false,
        fallback = false,
    }
    return keys[key]
end

function M.register(key, asset_id_or_url)
    return M.ensure(key, asset_id_or_url)
end

local function try_fallback(entry)
    if not entry.asset_id then return false end
    entry.fallback_idx = (entry.fallback_idx or 0) + 1
    local chain = {
        asset_urls.roblox_thumb(entry.asset_id),
        asset_urls.asset_delivery(entry.asset_id),
    }
    local fb = chain[entry.fallback_idx]
    if not fb or fb == entry.url then return false end
    entry.url = fb
    entry.handle = nil
    entry.failed = false
    return true
end

local function get_handle(key)
    local entry = keys[key]
    if not entry or entry.failed or not draw or not draw.load_image then
        return nil
    end

    if not entry.handle then
        entry.handle = draw.load_image(entry.url)
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return nil
        end
        debug.warn_once("img:" .. key, "load failed - " .. entry.url)
        entry.failed = true
        entry.handle = nil
        return nil
    end

    return entry.handle
end

local function draw_image(handle, x, y, w, h, col)
    if col and type(col) == "table" then
        local r = math.floor((col[1] or 1) * 255)
        local g = math.floor((col[2] or 1) * 255)
        local b = math.floor((col[3] or 1) * 255)
        local a = math.floor((col[4] or 1) * 255)
        draw.image(handle, x, y, w, h, r, g, b, a)
    else
        draw.image(handle, x, y, w, h, 255, 255, 255, 255)
    end
end

function M.draw_fit(key, x, y, w, h, col)
    if not draw or not draw.image then return false end

    local handle = get_handle(key)
    if not handle then return false end

    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)
    draw_image(handle, x, y, w, h, col)
    return true
end

function M.state(key)
    local entry = keys[key]
    if not entry then return "none" end
    if entry.failed then return "failed" end
    if not entry.handle then return "loading" end
    if draw and draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return "loading"
        end
        entry.failed = true
        entry.handle = nil
        return "failed"
    end
    return "ready"
end

function M.is_ready(key)
    return M.state(key) == "ready"
end

function M.preload(key, asset_id_or_url)
    M.ensure(key, asset_id_or_url)
    get_handle(key)
end

function M.begin_load(key)
    if not key then return end
    get_handle(key)
end

function M.draw_at_world(key, wx, wy, wz, size)
    if not draw or not draw.image or not utility or not utility.world_to_screen then
        return false
    end

    local handle = get_handle(key)
    if not handle then return false end

    local sx, sy, vis = utility.world_to_screen(wx, wy, wz)
    if not vis then return false end

    size = size or 64
    local hs = math.floor(size * 0.5)
    draw.image(handle, sx - hs, sy - hs, size, size, 255, 255, 255, 255)
    return true
end

return M

end)()

-- ── core/esp_util.lua ──
April._mods["core.esp_util"] = (function()
local draw_util = April.require("core.draw_util")
local settings = April.require("core.settings")

local M = {}

M.AIM_BONES = {
    "Closest",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftFoot",
    "RightFoot",
}

M.SKELETON_PAIRS = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "UpperTorso", "RightUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LowerTorso", "RightUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "RightLowerLeg", "RightFoot" },
}

function M.text_size()
    return settings.num("april_esp_text_size", 13)
end

function M.w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.draw_skeleton_bones(bones, col, thick)
    if not bones then return end
    thick = thick or 1.5

    local function pt(entry)
        if not entry then return end
        if entry.x and entry.y then return entry.x, entry.y end
        if entry[1] and entry[2] then return entry[1], entry[2] end
    end

    for i = 1, #M.SKELETON_PAIRS do
        local pair = M.SKELETON_PAIRS[i]
        local ax, ay = pt(bones[pair[1]])
        local bx, by = pt(bones[pair[2]])
        if ax and bx then
            draw_util.line(ax, ay, bx, by, col, thick)
        end
    end
end

function M.draw_player_skeleton(player, col, thick)
    if not player or not player.get_bones_screen then return end
    local bones = player:get_bones_screen()
    if not bones then return end
    M.draw_skeleton_bones(bones, col, thick)
end

function M.model_screen_bounds(model)
    if not model then return nil end
    local env = April.require("core.env")
    if not env.is_valid(model) then return nil end

    local part_names = {
        "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso",
        "LeftFoot", "RightFoot", "LeftHand", "RightHand",
        "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
    }

    local min_x, min_y, max_x, max_y
    local any = false

    for i = 1, #part_names do
        local name = part_names[i]
        local part = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if part and env.is_valid(part) then
            local pos = part.Position or part.position
            if pos and pos.x then
                local sx, sy, vis = M.w2s(pos.x, pos.y, pos.z)
                if vis then
                    any = true
                    min_x = min_x and math.min(min_x, sx) or sx
                    min_y = min_y and math.min(min_y, sy) or sy
                    max_x = max_x and math.max(max_x, sx) or sx
                    max_y = max_y and math.max(max_y, sy) or sy
                end
            end
        end
    end

    if not any then return nil end

    local w = math.max(4, max_x - min_x)
    local h = math.max(6, max_y - min_y)
    -- Same pad as bones_screen_bounds so player/NPC boxes match.
    local pad_x = math.max(2, w * 0.14)
    local pad_y = math.max(2, h * 0.06)
    return {
        x = min_x - pad_x,
        y = min_y - pad_y,
        w = w + pad_x * 2,
        h = h + pad_y * 2,
        valid = true,
    }
end

local function aabb_from_screen_points(min_x, min_y, max_x, max_y)
    local w = math.max(4, max_x - min_x)
    local h = math.max(6, max_y - min_y)
    local pad_x = math.max(2, w * 0.14)
    local pad_y = math.max(2, h * 0.06)
    return {
        x = min_x - pad_x,
        y = min_y - pad_y,
        w = w + pad_x * 2,
        h = h + pad_y * 2,
        valid = true,
    }
end

-- Build screen AABB from entity bone projections (same source as skeleton = stable).
function M.bones_screen_bounds(player)
    if not player or not player.get_bones_screen then return nil end
    local bones = player:get_bones_screen()
    if not bones then return nil end

    local min_x, min_y, max_x, max_y
    local any = false
    for _, pt in pairs(bones) do
        if pt then
            local x = pt.x or pt[1]
            local y = pt.y or pt[2]
            if x and y then
                any = true
                min_x = min_x and math.min(min_x, x) or x
                min_y = min_y and math.min(min_y, y) or y
                max_x = max_x and math.max(max_x, x) or x
                max_y = max_y and math.max(max_y, y) or y
            end
        end
    end
    if not any then return nil end
    return aabb_from_screen_points(min_x, min_y, max_x, max_y)
end

-- Keep far targets readable: only expand collapsed specks, never inflate real bounds.
function M.ensure_min_bounds(b, min_w, min_h)
    if not b or not b.valid then return b end
    min_w = min_w or 22
    min_h = min_h or 40
    local cx = b.x + b.w * 0.5
    local cy = b.y + b.h * 0.5
    if b.w < min_w then
        b.w = min_w
        b.x = cx - min_w * 0.5
    end
    if b.h < min_h then
        b.h = min_h
        b.y = cy - min_h * 0.5
    end
    return b
end

function M.dist_min_bounds(dist)
    dist = math.max(1, tonumber(dist) or 80)
    local h = math.max(8, math.min(40, 2400 / (dist + 35)))
    local w = math.max(5, math.min(24, h * 0.55))
    return w, h
end

function M.dist_point_size(dist)
    dist = math.max(1, tonumber(dist) or 80)
    return math.max(8, math.min(36, 2200 / (dist + 30)))
end

function M.guard_tiny_bounds(b, dist)
    if not b or not b.valid then return b end
    local min_w, min_h = M.dist_min_bounds(dist)
    -- Expand only when smaller than the distance floor (keeps close boxes natural).
    if b.w >= min_w and b.h >= min_h then return b end
    return M.ensure_min_bounds(b, min_w, min_h)
end

function M.bounds_usable(b)
    return b and b.valid and (b.w or 0) >= 3 and (b.h or 0) >= 5
end

-- Hold last good box across flaky get_bounds / w2s frames (anti-flicker).
function M.hold_bounds(store, key, fresh, now, ttl_ms)
    if not store or not key then return fresh end
    ttl_ms = ttl_ms or 1000
    now = now or 0
    local ent = store[key]

    if M.bounds_usable(fresh) then
        store[key] = { bounds = fresh, t = now }
        return fresh
    end

    if ent and M.bounds_usable(ent.bounds) and (now - (ent.t or 0)) < ttl_ms then
        return ent.bounds
    end

    return nil
end

local function vec3_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    return v[1], v[2], v[3]
end

local function head_feet_from_model(model, opts)
    if not model then return nil end
    opts = opts or {}
    local env = April.require("core.env")
    if not env.is_valid(model) then return nil end

    local head = env.safe_call(function()
        return model:find_first_child("Head") or model:FindFirstChild("Head")
    end)
    local hx, hy, hz = head and env.is_valid(head) and vec3_pos(head.Position or head.position) or nil
    if not hx then return nil end

    local sx, sy, vis = M.w2s(hx, hy, hz)
    if not vis then return nil end

    local fx, fy, fz
    for _, name in ipairs({ "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "HumanoidRootPart" }) do
        local foot = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if foot and env.is_valid(foot) then
            fx, fy, fz = vec3_pos(foot.Position or foot.position)
            if fx then
                if name == "HumanoidRootPart" then
                    fy = fy - 2.5
                end
                break
            end
        end
    end
    if not fx then
        fx, fy, fz = hx, hy - 3, hz
    end

    local bx, by, bvis = M.w2s(fx, fy, fz)
    if not bvis then
        local size = opts.point_size or M.dist_point_size(opts.dist)
        return M.point_screen_bounds(hx, hy, hz, size)
    end

    return aabb_from_screen_points(
        math.min(sx, bx), math.min(sy, by),
        math.max(sx, bx), math.max(sy, by)
    )
end

-- Head + feet projection when bone AABB APIs fail for a frame.
function M.head_feet_screen_bounds(player, opts)
    if not player then return nil end
    opts = opts or {}
    local env = April.require("core.env")

    local hx, hy, hz = vec3_pos(player.head_position)
    if not hx then
        local char = player.character
        if char and env.is_valid(char) then
            local head = env.safe_call(function()
                return char:find_first_child("Head") or char:FindFirstChild("Head")
            end)
            if head and env.is_valid(head) then
                hx, hy, hz = vec3_pos(head.Position or head.position)
            end
        end
    end
    if not hx then
        if player.character then
            return head_feet_from_model(player.character, opts)
        end
        return nil
    end

    local sx, sy, vis = M.w2s(hx, hy, hz)
    if not vis then return nil end

    local fx, fy, fz
    local char = player.character
    if char and env.is_valid(char) then
        for _, name in ipairs({ "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg" }) do
            local foot = env.safe_call(function()
                return char:find_first_child(name) or char:FindFirstChild(name)
            end)
            if foot and env.is_valid(foot) then
                fx, fy, fz = vec3_pos(foot.Position or foot.position)
                if fx then break end
            end
        end
    end
    if not fx then
        fx, fy, fz = vec3_pos(player.position)
        if fx then fy = fy - 2.8 end
    end
    if not fx then
        fx, fy, fz = hx, hy - 3, hz
    end

    local bx, by, bvis = M.w2s(fx, fy, fz)
    if not bvis then
        local size = opts.point_size or M.dist_point_size(opts.dist)
        return M.point_screen_bounds(hx, hy, hz, size)
    end

    return aabb_from_screen_points(
        math.min(sx, bx), math.min(sy, by),
        math.max(sx, bx), math.max(sy, by)
    )
end

-- Stable character box: bones (skeleton source) -> model -> head/feet -> get_bounds last.
-- Preferring bones avoids far-range get_bounds flicker that skips box/name/health.
function M.player_screen_bounds(player, opts)
    if not player then return nil end
    opts = opts or {}
    local dist = opts.dist

    local b = M.bones_screen_bounds(player)
    if M.bounds_usable(b) then
        return M.guard_tiny_bounds(b, dist)
    end

    local model = player.character
    if model then
        b = M.model_screen_bounds(model)
        if M.bounds_usable(b) then
            return M.guard_tiny_bounds(b, dist)
        end
    end

    b = M.head_feet_screen_bounds(player, opts)
    if M.bounds_usable(b) then
        return M.guard_tiny_bounds(b, dist)
    end

    if player.get_bounds then
        local gb = player:get_bounds()
        if M.bounds_usable(gb) then
            return M.guard_tiny_bounds(gb, dist)
        end
    end

    return nil
end

-- Same scaling path for NPCs (entity players or scanned models).
function M.npc_screen_bounds(entry, opts)
    if not entry then return nil end
    opts = opts or {}
    local dist = opts.dist

    if entry.entity then
        return M.player_screen_bounds(entry.entity, opts)
    end

    local model = entry.inst
    if not model then return nil end

    local b = M.model_screen_bounds(model)
    if M.bounds_usable(b) then
        return M.guard_tiny_bounds(b, dist)
    end

    b = head_feet_from_model(model, opts)
    if M.bounds_usable(b) then
        return M.guard_tiny_bounds(b, dist)
    end

    if entry.lx then
        local size = opts.point_size or M.dist_point_size(dist)
        b = M.point_screen_bounds(entry.lx, entry.ly, entry.lz, size)
        if M.bounds_usable(b) then
            return M.guard_tiny_bounds(b, dist)
        end
    end

    return nil
end

function M.draw_model_skeleton(model, col, thick)
    if not model then return end
    local env = April.require("core.env")
    if not env.is_valid(model) then return end

    local screen = {}
    local function part_pos(name)
        local part = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if not part or not env.is_valid(part) then return end
        local pos = part.Position or part.position
        if not pos or pos.x == nil then return end
        local sx, sy, vis = M.w2s(pos.x, pos.y, pos.z)
        if vis then screen[name] = { x = sx, y = sy } end
    end

    for _, pair in ipairs(M.SKELETON_PAIRS) do
        part_pos(pair[1])
        part_pos(pair[2])
    end
    M.draw_skeleton_bones(screen, col, thick)
end

function M.draw_vertical_beacon(wx, wy, wz, col, opts)
    opts = opts or {}
    local height = opts.height or 90
    local steps = opts.steps or 10
    local prev_sx, prev_sy, prev_vis

    for i = 0, steps do
        local py = wy + (height * i / steps)
        local sx, sy, vis = M.w2s(wx, py, wz)
        if i > 0 and vis and prev_vis and draw and draw.line then
            local alpha = (col[4] or 1) * (0.35 + 0.65 * (i / steps))
            draw.line(prev_sx, prev_sy, sx, sy, { col[1], col[2], col[3], alpha }, opts.thickness or 2)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end

    if prev_vis and draw and draw.circle_filled then
        draw.circle_filled(prev_sx, prev_sy, opts.marker_r or 4, col, 12)
    end
end

function M.draw_beacon(sx, sy, col, opts)
    opts = opts or {}
    local sw, sh = draw_util.screen_size()
    local origin_x = opts.origin_x or sw * 0.5
    local origin_y = opts.origin_y or sh
    local steps = opts.steps or 5

    for i = 1, steps do
        local t = i / steps
        local alpha = (col[4] or 1) * (0.08 + t * 0.22)
        local c = { col[1], col[2], col[3], alpha }
        local ox = origin_x + (sx - origin_x) * t
        local oy = origin_y + (sy - origin_y) * t
        draw_util.line(ox, oy, sx, sy, c, 1 + t)
    end

    if draw and draw.circle_filled then
        draw.circle_filled(sx, sy, opts.marker_r or 5, col, 16)
        draw.circle(sx, sy, opts.marker_r or 5 + 2, { col[1], col[2], col[3], 0.35 }, 16, 1)
    else
        draw_util.circle(sx, sy, opts.marker_r or 5, col, true)
    end
end

function M.draw_offscreen_arrow(cx, cy, tx, ty, col, size, style)
    size = size or 14
    style = style or 0 -- 0 triangle, 1 chevron, 2 diamond
    local dx, dy = tx - cx, ty - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    dx, dy = dx / len, dy / len
    local px, py = cx + dx * (size + 8), cy + dy * (size + 8)
    local lx, ly = -dy, dx

    if style == 1 then
        -- Chevron / open arrow
        local thick = math.max(1.5, size * 0.18)
        draw_util.line(px - dx * size + lx * size * 0.55, py - dy * size + ly * size * 0.55,
            px + dx * size * 0.15, py + dy * size * 0.15, col, thick)
        draw_util.line(px - dx * size - lx * size * 0.55, py - dy * size - ly * size * 0.55,
            px + dx * size * 0.15, py + dy * size * 0.15, col, thick)
        return
    end

    if style == 2 then
        local tip = { px + dx * size, py + dy * size }
        local back = { px - dx * size * 0.55, py - dy * size * 0.55 }
        local left = { px + lx * size * 0.45, py + ly * size * 0.45 }
        local right = { px - lx * size * 0.45, py - ly * size * 0.45 }
        if draw and draw.poly_filled then
            draw.poly_filled({ tip, left, back, right }, col)
        else
            draw_util.line(tip[1], tip[2], left[1], left[2], col, 2)
            draw_util.line(left[1], left[2], back[1], back[2], col, 2)
            draw_util.line(back[1], back[2], right[1], right[2], col, 2)
            draw_util.line(right[1], right[2], tip[1], tip[2], col, 2)
        end
        return
    end

    if draw and draw.poly_filled then
        draw.poly_filled({
            { px + dx * size, py + dy * size },
            { px - dx * 4 + lx * size * 0.55, py - dy * 4 + ly * size * 0.55 },
            { px - dx * 4 - lx * size * 0.55, py - dy * 4 - ly * size * 0.55 },
        }, col)
    else
        draw_util.line(px, py, px - dx * 8 + lx * 6, py - dy * 8 + ly * 6, col, 2)
        draw_util.line(px, py, px - dx * 8 - lx * 6, py - dy * 8 - ly * 6, col, 2)
    end
end

-- Clamp a world point to the screen edge and draw an arrow pointing at it.
-- opts: size, margin, style, label, label_col, outline
-- Returns true if an arrow was drawn (target off-screen / outside margin).
function M.draw_offscreen_to(wx, wy, wz, col, size, margin, opts)
    opts = opts or {}
    if type(size) == "table" then
        opts = size
        size = opts.size
        margin = opts.margin
    end

    local sw, sh = draw_util.screen_size()
    if not sw or sw < 1 or not sh or sh < 1 then return false end

    local cx, cy = sw * 0.5, sh * 0.5
    margin = margin or opts.margin or 36
    size = size or opts.size or 14
    local style = opts.style or 0

    local sx, sy, on = M.w2s(wx, wy, wz)
    sx = tonumber(sx) or cx
    sy = tonumber(sy) or cy

    if on and sx >= margin and sy >= margin and sx <= (sw - margin) and sy <= (sh - margin) then
        return false
    end

    local dx, dy = sx - cx, sy - cy
    if (dx * dx + dy * dy) < 1 then
        if camera and camera.get_look_vector then
            local look = camera.get_look_vector()
            if look then
                dx = look.x or look.X or 0
                dy = -(look.y or look.Y or 0)
            end
        end
        if (dx * dx + dy * dy) < 0.0001 then
            dx, dy = 0, -1
        end
    end

    local len = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / len, dy / len

    local hw = (sw * 0.5) - margin
    local hh = (sh * 0.5) - margin
    local scale_x = (math.abs(dx) > 1e-6) and (hw / math.abs(dx)) or 1e9
    local scale_y = (math.abs(dy) > 1e-6) and (hh / math.abs(dy)) or 1e9
    local scale = math.min(scale_x, scale_y)
    local ex = cx + dx * scale
    local ey = cy + dy * scale

    if opts.outline then
        local oc = { 0, 0, 0, (col[4] or 1) * 0.85 }
        M.draw_offscreen_arrow(cx, cy, ex, ey, oc, size + 2, style)
    end
    M.draw_offscreen_arrow(cx, cy, ex, ey, col, size, style)

    if opts.label then
        local lx = ex - dx * (size + 10)
        local ly = ey - dy * (size + 10)
        draw_util.text_centered(lx, ly - 6, tostring(opts.label), opts.label_col or col, opts.label_size or 11)
    end
    return true
end

local BOX_EDGES = {
    { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 },
    { 5, 6 }, { 5, 7 }, { 6, 8 }, { 7, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local BOX_SIGNS = {
    { -1, -1, -1 }, { 1, -1, -1 }, { -1, 1, -1 }, { 1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 }, { -1, 1, 1 }, { 1, 1, 1 },
}

function M.draw_world_line(x1, y1, z1, x2, y2, z2, col, thick)
    if not draw then return false end
    local sx1, sy1, v1 = M.w2s(x1, y1, z1)
    local sx2, sy2, v2 = M.w2s(x2, y2, z2)
    if v1 or v2 then
        draw_util.line(sx1, sy1, sx2, sy2, col, thick or 2)
        return true
    end
    return false
end

function M.draw_world_cross(wx, wy, wz, size, col, thick)
    if not camera or not camera.get_look_vector then return end

    local look = camera.get_look_vector()
    if not look then return end

    local lx = look.x or look.X or 0
    local ly = look.y or look.Y or 0
    local lz = look.z or look.Z or 0
    local mag = math.sqrt(lx * lx + ly * ly + lz * lz)
    if mag < 0.001 then return end
    lx, ly, lz = lx / mag, ly / mag, lz / mag

    local ux, uy, uz = 0, 1, 0
    local rx = uy * lz - uz * ly
    local ry = uz * lx - ux * lz
    local rz = ux * ly - uy * lx
    local rm = math.sqrt(rx * rx + ry * ry + rz * rz)
    if rm < 0.001 then
        ux, uy, uz = 0, 0, 1
        rx = uy * lz - uz * ly
        ry = uz * lx - ux * lz
        rz = ux * ly - uy * lx
        rm = math.sqrt(rx * rx + ry * ry + rz * rz)
    end
    if rm < 0.001 then return end
    rx, ry, rz = rx / rm, ry / rm, rz / rm

    ux = ly * rz - lz * ry
    uy = lz * rx - lx * rz
    uz = lx * ry - ly * rx
    local um = math.sqrt(ux * ux + uy * uy + uz * uz)
    if um < 0.001 then return end
    ux, uy, uz = ux / um, uy / um, uz / um

    size = size or 0.35
    thick = thick or 2
    local s = size * 0.5

    M.draw_world_line(
        wx - rx * s - ux * s, wy - ry * s - uy * s, wz - rz * s - uz * s,
        wx + rx * s + ux * s, wy + ry * s + uy * s, wz + rz * s + uz * s,
        col, thick
    )
    M.draw_world_line(
        wx - rx * s + ux * s, wy - ry * s + uy * s, wz - rz * s + uz * s,
        wx + rx * s - ux * s, wy + ry * s - uy * s, wz + rz * s - uz * s,
        col, thick
    )
end

function M.draw_oriented_box(box, col, thick)
    if not box or not draw or not draw.line then return end
    thick = thick or 1

    local corners = {}
    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        corners[i] = { wx, wy, wz }
    end

    local screen = {}
    for i = 1, 8 do
        local c = corners[i]
        local sx, sy, vis = M.w2s(c[1], c[2], c[3])
        if vis then screen[i] = { x = sx, y = sy } end
    end

    for _, edge in ipairs(BOX_EDGES) do
        local a, b = screen[edge[1]], screen[edge[2]]
        if a and b then
            draw_util.line(a.x, a.y, b.x, b.y, col, thick)
        end
    end
end

function M.draw_entry_boxes(entry, col, thick)
    if not entry or not entry.inst then return end
    if entry.box then
        M.draw_oriented_box(entry.box, col, thick)
        return
    end
    local scan = April.require("game.esp_scan")
    local main = entry.main_part or scan.find_main_part(entry.inst)
    local box = scan.read_part_box(main)
    if box then
        entry.box = box
        M.draw_oriented_box(box, col, thick)
    end
end

function M.oriented_box_screen_bounds(box)
    if not box then return nil end

    local min_x, min_y, max_x, max_y
    local any = false

    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        local px, py, vis = M.w2s(wx, wy, wz)
        if vis then
            any = true
            min_x = min_x and math.min(min_x, px) or px
            min_y = min_y and math.min(min_y, py) or py
            max_x = max_x and math.max(max_x, px) or px
            max_y = max_y and math.max(max_y, py) or py
        end
    end

    if not any then return nil end

    return {
        x = min_x,
        y = min_y,
        w = math.max(12, max_x - min_x),
        h = math.max(12, max_y - min_y),
        valid = true,
    }
end

function M.point_screen_bounds(wx, wy, wz, size)
    local sx, sy, vis = M.w2s(wx, wy, wz)
    if not vis then return nil end
    size = size or 48
    return {
        x = sx - size * 0.5,
        y = sy - size * 0.5,
        w = size,
        h = size,
        valid = true,
    }
end

function M.entry_screen_bounds(entry)
    if not entry then return nil end

    if entry.box then
        local bounds = M.oriented_box_screen_bounds(entry.box)
        if bounds then return bounds end
    end

    if entry.inst then
        local scan = April.require("game.esp_scan")
        local main = entry.main_part or scan.find_main_part(entry.inst)
        if main then
            local box = scan.read_part_box(main)
            if box then
                entry.box = box
                local bounds = M.oriented_box_screen_bounds(box)
                if bounds then return bounds end
            end
        end
    end

    local esp_scan = April.require("game.esp_scan")
    local lx, ly, lz = esp_scan.entry_coords(entry)
    if lx then
        return M.point_screen_bounds(lx, ly, lz, 52)
    end

    return nil
end

return M

end)()

-- ── core/gpu_chams.lua ──
April._mods["core.gpu_chams"] = (function()
-- GPU instance chams with a double-buffer applied set.
--
-- front (owner.applied) = addresses currently stamped by the engine
-- back  (fresh collect) = addresses that SHOULD be chammed this tick (in-range only)
--
-- If back == front -> no work (or only apply brand-new addrs).
-- If any addr left back -> RevertChams + re-apply ONLY back (all active owners).
-- That is the "double buffer": never leave stale out-of-range instances chammed.
--
-- Range is fail-closed: without a local player position, collect applies nothing.

local settings = April.require("core.settings")
local env = April.require("core.env")

local M = {}

M.MODE_LABELS = { "Fill", "Wireframe", "Fill Glow", "Wireframe Glow" }
M.COLOR_LABELS = { "Default", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan" }

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    WedgePart = true,
    CornerWedgePart = true,
    TrussPart = true,
    UnionOperation = true,
    NegateOperation = true,
}

local owners = {}
local owner_order = {}
local rebuild_busy = false
local last_global_rebuild = 0
local MIN_REBUILD_GAP_MS = 250

function M.available()
    return exploits ~= nil
        and type(exploits.ApplyChamsToInstance) == "function"
        and type(exploits.RevertChams) == "function"
        and type(exploits.SetChamsMode) == "function"
        and type(exploits.SetChamsColor) == "function"
end

function M.is_part(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    if PART_CLASSES[cn] then return true end
    return env.safe_call(function()
        if inst.is_a then return inst:is_a("BasePart") end
        if inst.IsA then return inst:IsA("BasePart") end
        return false
    end) == true
end

function M.instance_addr(inst)
    if not inst then return nil end
    return inst.Address or inst.address
end

function M.color_visible_for_mode(mode)
    mode = tonumber(mode) or 0
    return mode == 2 or mode == 3
end

function M.mode_index(id, default)
    return settings.combo_index(id, M.MODE_LABELS, default or 0)
end

function M.color_index(id, default)
    return settings.combo_index(id, M.COLOR_LABELS, default or 0)
end

function M.multicombo_selected(id, index)
    return settings.multi(id, index, false)
end

function M.multicombo_defaults(count)
    local out = {}
    for i = 1, count do
        out[i] = false
    end
    return out
end

local function now_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function push_style(mode, color)
    pcall(function() exploits.SetChamsMode(mode or 0) end)
    pcall(function() exploits.SetChamsColor(color or 0) end)
end

local function any_other_active(except_id)
    for _, oid in ipairs(owner_order) do
        local o = owners[oid]
        if o and oid ~= except_id and o.is_active() then
            return true
        end
    end
    return false
end

local function sets_equal(a, b)
    for k in pairs(a) do
        if not b[k] then return false end
    end
    for k in pairs(b) do
        if not a[k] then return false end
    end
    return true
end

local function has_removed(prev, fresh)
    for addr in pairs(prev) do
        if not fresh[addr] then return true end
    end
    return false
end

local function apply_one(inst, applied)
    if not M.available() or not inst then return false end
    if not M.is_part(inst) then return false end
    local addr = M.instance_addr(inst)
    if not addr then return false end
    if applied[addr] then return true end
    local ok, result = pcall(exploits.ApplyChamsToInstance, inst)
    -- Some builds return nil on success; only treat explicit false as failure.
    if ok and result ~= false then
        applied[addr] = true
        return true
    end
    return false
end

function M.cham_part(inst, applied)
    return apply_one(inst, applied or {})
end

-- Fallen R15: body MeshParts + nested armor copies under skin Models (dump).
local PLAYER_CHAM_NAMES = {
    Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
    LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true,
    LeftHand = true, RightHand = true,
    LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true,
    LeftFoot = true, RightFoot = true,
    Armor = true, -- clothing layer MeshParts under Default/Abibas models
}

local PLAYER_CHAM_SKIP = {
    HumanoidRootPart = true,
    CollisionPart = true,
}

function M.cham_player_character(char, applied)
    if not char or not env.is_valid(char) then return 0 end
    applied = applied or {}

    local list = env.safe_call(function()
        if char.get_descendants then return char:get_descendants() end
        return char:GetDescendants()
    end) or {}

    local n = 0
    for i = 1, #list do
        local inst = list[i]
        local name = inst and (inst.Name or inst.name)
        if name and PLAYER_CHAM_NAMES[name] and not PLAYER_CHAM_SKIP[name] then
            if apply_one(inst, applied) then
                n = n + 1
            end
        end
    end

    -- Fallback: direct children only (some builds omit nested descendants).
    if n == 0 then
        local kids = env.safe_call(function()
            if char.get_children then return char:get_children() end
            return char:GetChildren()
        end) or {}
        for i = 1, #kids do
            local inst = kids[i]
            local name = inst and (inst.Name or inst.name)
            if name and PLAYER_CHAM_NAMES[name] and not PLAYER_CHAM_SKIP[name] then
                if apply_one(inst, applied) then
                    n = n + 1
                end
            end
        end
    end

    return n
end

-- Prefer a single visual part per ESP entry (Main / HRP / first MeshPart).
-- Cham'ing every descendant was heavy and made shared-mesh bleed worse.
function M.cham_entry_part(entry, applied)
    if not entry then return false end
    local part = entry.main_part
    if part and env.is_valid(part) and M.is_part(part) then
        return apply_one(part, applied)
    end
    if entry.inst and env.is_valid(entry.inst) then
        local esp_scan = April.require("game.esp_scan")
        local main = esp_scan.find_main_part(entry.inst)
        if main then
            entry.main_part = main
            return apply_one(main, applied)
        end
        -- Animals / odd models: first MeshPart descendant
        local desc = env.safe_call(function()
            if entry.inst.get_descendants then return entry.inst:get_descendants() end
            return entry.inst:GetDescendants()
        end) or {}
        for _, d in ipairs(desc) do
            if M.is_part(d) then
                entry.main_part = d
                return apply_one(d, applied)
            end
        end
    end
    return false
end

function M.cham_model_main(model, applied)
    if not model then return false end
    local esp_scan = April.require("game.esp_scan")
    local main = esp_scan.find_main_part(model)
    if main then return apply_one(main, applied) end
    return apply_one(model, applied)
end

function M.cham_container_parts(container, applied, max_parts)
    -- Kept for compatibility; prefer cham_entry_part for ESP.
    max_parts = max_parts or 8
    if not container then return 0 end
    local n = 0
    local main = April.require("game.esp_scan").find_main_part(container)
    if main and apply_one(main, applied) then
        n = n + 1
    end
    if n > 0 then return n end

    local list = env.safe_call(function()
        if container.get_descendants then return container:get_descendants() end
        return container:GetDescendants()
    end) or {}
    for _, d in ipairs(list) do
        if n >= max_parts then break end
        if apply_one(d, applied) then n = n + 1 end
    end
    return n
end

function M.register_owner(id, opts)
    opts = opts or {}
    if not owners[id] then
        owner_order[#owner_order + 1] = id
    end
    owners[id] = {
        id = id,
        applied = {}, -- front buffer
        was_active = false,
        is_active = opts.is_active or function() return false end,
        style = opts.style or function() return 0, 0 end,
        collect = opts.collect or function(_back) end,
        last_rescan = 0,
        rescan_ms = opts.rescan_ms or 500,
    }
    return owners[id]
end

function M.get_owner(id)
    return owners[id]
end

local function apply_owner_into(owner, into)
    if not owner or not owner.is_active() then return end
    local mode, color = owner.style()
    push_style(mode, color)
    pcall(owner.collect, into)
end

function M.rebuild_all()
    if not M.available() or rebuild_busy then return false end
    local now = now_ms()
    if last_global_rebuild ~= 0 and (now - last_global_rebuild) < MIN_REBUILD_GAP_MS then
        return false
    end
    last_global_rebuild = now
    rebuild_busy = true

    pcall(function() exploits.RevertChams() end)

    for _, id in ipairs(owner_order) do
        local owner = owners[id]
        if owner then
            owner.applied = {}
            owner.last_rescan = 0
        end
    end

    for _, id in ipairs(owner_order) do
        local owner = owners[id]
        if owner and owner.is_active() then
            local back = {}
            apply_owner_into(owner, back)
            owner.applied = back
            owner.was_active = true
        elseif owner then
            owner.was_active = false
        end
    end

    rebuild_busy = false
    return true
end

function M.revert_all()
    if not M.available() then return end
    pcall(function() exploits.RevertChams() end)
    last_global_rebuild = now_ms()
    for _, id in ipairs(owner_order) do
        local owner = owners[id]
        if owner then
            owner.applied = {}
            owner.was_active = false
            owner.last_rescan = 0
        end
    end
end

function M.clear_owner(id, rebuild_others)
    local owner = owners[id]
    if not owner then return end
    local had = owner.was_active or next(owner.applied) ~= nil
    owner.applied = {}
    owner.was_active = false
    owner.last_rescan = 0
    if not had or rebuild_others == false then return end
    if any_other_active(id) then
        M.rebuild_all()
    else
        M.revert_all()
    end
end

function M.refresh_owner_style(id)
    local owner = owners[id]
    if not owner then return end
    if not owner.is_active() then
        M.clear_owner(id)
        return
    end
    -- Style change: must re-stamp; safest is full rebuild of active set.
    M.rebuild_all()
end

function M.sync_owner(id, force)
    if not M.available() or rebuild_busy then return end
    local owner = owners[id]
    if not owner then return end

    if not owner.is_active() then
        if owner.was_active or next(owner.applied) ~= nil then
            M.clear_owner(id)
        end
        return
    end

    local now = now_ms()
    if not force and owner.last_rescan ~= 0 and (now - owner.last_rescan) < owner.rescan_ms then
        owner.was_active = true
        return
    end
    owner.last_rescan = now
    owner.was_active = true

    -- Back buffer: what should be chammed right now (collectors must range-filter).
    local back = {}
    local mode, color = owner.style()
    push_style(mode, color)
    local ok = pcall(owner.collect, back)
    if not ok then return end

    local front = owner.applied

    if sets_equal(front, back) then
        return
    end

    if has_removed(front, back) or next(front) == nil then
        -- Something left range / first populate after clear -> swap buffers via rebuild.
        -- Rebuild reapplies ALL active owners from scratch (correct multi-owner state).
        owner.applied = {}
        if not M.rebuild_all() then
            -- Rate-limited: still track desired set; next tick will rebuild.
            owner.applied = back
        end
        return
    end

    -- Only additions: stamp new addresses, no Revert needed.
    for addr, _ in pairs(back) do
        if not front[addr] then
            pcall(exploits.ApplyChamsToInstance, addr)
            front[addr] = true
        end
    end
    owner.applied = front
end

function M.wire_style_controls(owner_id, mode_id, color_id)
    if not menu or not menu.set_visible then return end

    local function sync_color_vis()
        local mode = M.mode_index(mode_id, 0)
        pcall(menu.set_visible, color_id, M.color_visible_for_mode(mode))
    end

    settings.on_change(mode_id, function()
        sync_color_vis()
        M.refresh_owner_style(owner_id)
    end)
    settings.on_change(color_id, function()
        M.refresh_owner_style(owner_id)
    end)
    sync_color_vis()
end

function M.add_mode_color_menu(T, G, parent_id, mode_id, color_id, mode_label, color_label)
    local root = { parent = parent_id }
    menu.add_combo(T, G, mode_id, mode_label or "Chams Mode", M.MODE_LABELS, 0, root)
    menu.add_combo(T, G, color_id, color_label or "Chams Color", M.COLOR_LABELS, 0, root)
    return mode_id, color_id
end

return M

end)()

-- ── core/incremental_scan.lua ──
April._mods["core.incremental_scan"] = (function()
local debug = April.require("core.debug")

local M = {}

local jobs = {}
local BUDGET_MS = 5
local ITEMS_PER_STEP = 16
local MAX_STARTS_PER_TICK = 1
local starts_this_tick = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.configure(opts)
    if not opts then return end
    if opts.budget_ms then BUDGET_MS = opts.budget_ms end
    if opts.items_per_step then ITEMS_PER_STEP = opts.items_per_step end
end

function M.register(id, interval_ms, when_fn, create_state_fn, step_fn, complete_fn, phase_ms)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        last_done = tick_ms() - (interval_ms - (phase_ms or 0)),
        when = when_fn,
        create_state = create_state_fn,
        step = step_fn,
        complete = complete_fn,
        active = false,
        state = nil,
    }
end

function M.is_active(id)
    local job = jobs[id]
    return job and job.active == true
end

function M.force(id)
    local job = jobs[id]
    if not job then return end
    job.last_done = 0
    job.active = false
    job.state = nil
end

function M.tick()
    starts_this_tick = 0
    local budget_left = BUDGET_MS
    local now = tick_ms()

    for id, job in pairs(jobs) do
        if budget_left <= 0 then break end

        if job.when then
            local ok, pass = pcall(job.when)
            if not ok or not pass then
                job.active = false
                job.state = nil
                goto continue
            end
        end

        if job.active and job.state then
            while budget_left > 0 do
                local t0 = tick_ms()
                local ok, done = pcall(job.step, job.state, ITEMS_PER_STEP)
                if not ok then
                    debug.error_once("iscan:" .. id, done)
                    job.active = false
                    job.state = nil
                    job.last_done = now
                    break
                end

                budget_left = budget_left - (tick_ms() - t0)

                if done then
                    pcall(job.complete, job.state)
                    job.active = false
                    job.state = nil
                    job.last_done = now
                    break
                end

                if budget_left <= 0 then break end
            end
        elseif now - job.last_done >= job.interval and starts_this_tick < MAX_STARTS_PER_TICK then
            job.state = job.create_state and job.create_state() or {}
            job.active = true
            starts_this_tick = starts_this_tick + 1
        end

        ::continue::
    end
end

return M

end)()

-- ── core/menu_util.lua ──
April._mods["core.menu_util"] = (function()
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
    -- Custom UI mode: never create Vector menu tabs.
    if April and April.custom_ui then
        M._tab_ready = true
        return
    end
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
    if type(G) ~= "string" then
        error("[April] menu_util.section: pass group name string (e.g. menu_util.G.VISUALS), not the G table")
    end
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

-- Child is visible only if every hooked master that lists it is on.
local function effective_visible(id)
    local any = false
    for master_id, hooked in pairs(M._master_hooked) do
        if hooked then
            local kids = M._master_children[master_id]
            if kids then
                for i = 1, #kids do
                    if kids[i] == id then
                        any = true
                        if not master_visible(master_id) then
                            return false
                        end
                        break
                    end
                end
            end
        end
    end
    return true
end

local function apply_master_tree()
    -- Collect every child id once, then apply AND of all parent masters
    local seen = {}
    for master_id in pairs(M._master_hooked) do
        for _, id in ipairs(M._master_children[master_id] or {}) do
            if not seen[id] then
                seen[id] = true
                set_visible(id, effective_visible(id))
            end
        end
    end
end

function M.sync_masters()
    apply_master_tree()
    for i = 1, #M._when_rules do
        local rule = M._when_rules[i]
        if rule.sync then rule.sync() end
    end
end

function M.sync_master(master_id)
    if not master_id or not M._master_hooked[master_id] then return end
    apply_master_tree()
    for i = 1, #M._when_rules do
        local rule = M._when_rules[i]
        if rule.sync and rule.watch and rule.watch[master_id] then
            rule.sync()
        end
    end
end

function M.bind_master(master_id, child_ids)
    if not master_id or not child_ids then return end
    M._master_children[master_id] = add_child_ids(M._master_children[master_id], child_ids)

    if M._master_hooked[master_id] then
        apply_master_tree()
        return
    end
    M._master_hooked[master_id] = true

    local function sync()
        apply_master_tree()
        for i = 1, #M._when_rules do
            local rule = M._when_rules[i]
            if rule.sync and rule.watch and rule.watch[master_id] then
                rule.sync()
            end
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

-- Custom Always / Hold / Toggle bind (mode set via RMB on key chip in custom UI).
-- Gate features with settings.enabled(id).
function M.register_keybind(T, G, id, label, default, extra)
    extra = extra or {}
    local cb_opts = { show_mode = false, key = extra.key or 0 }
    if extra.parent then cb_opts.parent = extra.parent end
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, id, label, default or false, cb_opts)

    local mode_id = id .. "_mode"
    local mode_label = label .. " Bind Mode"
    menu.add_combo(T, G, mode_id, mode_label, { "Always", "Hold", "Toggle" }, 2, M.parent(id))

    April.require("core.feature_bind").register({
        id = id,
        label = label,
        mode_id = mode_id,
        key_id = id,
    })

    M.bind_master(id, { mode_id })
    return mode_id
end

return M

end)()

-- ── core/ballistic.lua ──
April._mods["core.ballistic"] = (function()
local math_util = April.require("core.math_util")

local M = {}

local ROBLOX_GRAV = 196.2

local function vec3(v)
    if not v then return 0, 0, 0 end
    return v.x or v.X or 0, v.y or v.Y or 0, v.z or v.Z or 0
end

local function combat_stats_mod()
    return April.require("game.combat_stats")
end

function M.gravity_accel(gravity_mult)
    -- Fallen CreateProjectile: v -= (0, 196.2 * Gravity, 0) * dt
    if not gravity_mult or gravity_mult <= 0 then
        return ROBLOX_GRAV * 0.55
    end
    if gravity_mult <= 2 then
        return ROBLOX_GRAV * gravity_mult
    end
    return gravity_mult
end

function M.calculate_drop(bullet_speed, bullet_gravity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local speed = math.max(bullet_speed or 950, 1)
    local dist = math_util.distance3(px - ox, py - oy, pz - oz)
    local time = dist / speed
    local g = M.gravity_accel(bullet_gravity)
    return 0.5 * g * time * time
end

-- Movement lead + bullet drop (Fallen / legacy aimbot formula).
-- MovePred = Velocity * (|Origin - Position| / BulletSpeed)
-- Drop = 0.5 * g * t^2 on Y only (automatic from weapon stats).
function M.calculate_target_position(bullet_speed, bullet_gravity, velocity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local vx, vy, vz = vec3(velocity)

    local speed = math.max(bullet_speed or 950, 1)
    local dist = math_util.distance3(ox - px, oy - py, oz - pz)
    local time = dist / speed

    local drop = M.calculate_drop(bullet_speed, bullet_gravity, position, origin)

    return {
        x = px + vx * time,
        y = py + vy * time + drop,
        z = pz + vz * time,
    }
end

function M.predict_for_weapon(origin, position, velocity, weapon_name)
    local stats = combat_stats_mod().get_effective_stats(weapon_name)
    return M.calculate_target_position(stats.speed, stats.gravity, velocity, position, origin)
end

-- Solve flight time so |v0| == speed with v0 = (hit - origin + 0.5*g*t^2*up) / t.
-- Matches CreateProjectile: Direction.Unit * Speed, then gravity 196.2*Gravity per second.
local function solve_flight_time(dx, dy, dz, speed, g)
    local dist = math_util.distance3(dx, dy, dz)
    if dist < 0.05 then return 0.001 end

    local s2 = speed * speed
    local horiz2 = dx * dx + dz * dz

    -- |offset/t + (0, 0.5*g*t, 0)|^2 = s^2
    -- -> (g^2/4)*t^4 + (g*dy - s^2)*t^2 + (horiz2+dy^2) = 0
    local a = (g * g) * 0.25
    local b = g * dy - s2
    local c = horiz2 + dy * dy

    local t = nil
    if a > 1e-8 then
        local disc = b * b - 4 * a * c
        if disc >= 0 then
            local sq = math.sqrt(disc)
            local u1 = (-b - sq) / (2 * a)
            local u2 = (-b + sq) / (2 * a)
            local best = nil
            for _, u in ipairs({ u1, u2 }) do
                if u and u > 1e-6 then
                    local cand = math.sqrt(u)
                    if not best or cand < best then
                        best = cand
                    end
                end
            end
            t = best
        end
    end

    -- Fallback: flat-time iterate (always works, slightly less exact |v0|).
    if not t then
        t = dist / speed
        for _ = 1, 10 do
            local vx = dx / t
            local vy = (dy + 0.5 * g * t * t) / t
            local vz = dz / t
            local sp = math.sqrt(vx * vx + vy * vy + vz * vz)
            if sp < 1e-6 then break end
            t = t * (sp / speed)
            if t < 0.001 then t = 0.001 end
        end
    end

    return math.max(t, 0.001)
end

-- Ballistic arc that lands exactly on hitpart (visual / debug path).
-- launch_dir / aim_far describe the physical launch under gravity - do NOT feed
-- aim_far into silent track_silent_target (hook projectiles are near-hitscan).
function M.curve_to_hit(origin, hit, bullet_speed, bullet_gravity, steps)
    if not origin or not hit then return nil end
    steps = steps or 24

    local ox, oy, oz = vec3(origin)
    local hx, hy, hz = vec3(hit)
    local dx, dy, dz = hx - ox, hy - oy, hz - oz
    local dist = math_util.distance3(dx, dy, dz)
    if dist < 0.05 then
        return {
            path = { { x = ox, y = oy, z = oz }, { x = hx, y = hy, z = hz } },
            aim = { x = hx, y = hy, z = hz },
            aim_far = { x = hx, y = hy, z = hz },
            hit = { x = hx, y = hy, z = hz },
            launch_dir = { x = 0, y = 1, z = 0 },
            flight = 0,
        }
    end

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)
    local flight = solve_flight_time(dx, dy, dz, speed, g)

    local vx = dx / flight
    local vy = (dy + 0.5 * g * flight * flight) / flight
    local vz = dz / flight

    -- Game clamps to Direction.Unit * Speed - normalize then scale.
    local lm = math.sqrt(vx * vx + vy * vy + vz * vz)
    local launch_dir
    if lm > 0.001 then
        launch_dir = { x = vx / lm, y = vy / lm, z = vz / lm }
        vx, vy, vz = launch_dir.x * speed, launch_dir.y * speed, launch_dir.z * speed
    else
        launch_dir = { x = dx / dist, y = dy / dist, z = dz / dist }
        vx, vy, vz = launch_dir.x * speed, launch_dir.y * speed, launch_dir.z * speed
    end

    -- Re-solve flight with exact |v0|=speed so path endpoint stays on hitpart.
    flight = solve_flight_time(dx, dy, dz, speed, g)
    vx = dx / flight
    vy = (dy + 0.5 * g * flight * flight) / flight
    vz = dz / flight
    lm = math.sqrt(vx * vx + vy * vy + vz * vz)
    if lm > 0.001 then
        launch_dir = { x = vx / lm, y = vy / lm, z = vz / lm }
        vx, vy, vz = launch_dir.x * speed, launch_dir.y * speed, launch_dir.z * speed
    end

    local path = {}
    for i = 0, steps do
        local t = (i / steps) * flight
        path[#path + 1] = {
            x = ox + vx * t,
            y = oy + vy * t - 0.5 * g * t * t,
            z = oz + vz * t,
        }
    end
    path[#path + 1] = { x = hx, y = hy, z = hz }

    local far = math.max(dist * 2, 800)
    local aim_far = {
        x = ox + launch_dir.x * far,
        y = oy + launch_dir.y * far,
        z = oz + launch_dir.z * far,
    }

    return {
        path = path,
        aim = { x = hx, y = hy, z = hz },
        aim_far = aim_far,
        hit = { x = hx, y = hy, z = hz },
        launch_dir = launch_dir,
        flight = flight,
        speed = speed,
        gravity = g,
    }
end

function M.curve_for_weapon(origin, hit, weapon_name, steps)
    local stats = combat_stats_mod().get_effective_stats(weapon_name)
    return M.curve_to_hit(origin, hit, stats.speed, stats.gravity, steps)
end

return M

end)()

-- ── core/silent_ray.lua ──
April._mods["core.silent_ray"] = (function()
local ballistic = April.require("core.ballistic")

local M = {}

local hook_ready = false
local tracking = false

local MOUSE_RAY_LEN = 1024

M._last_origin = nil
M._last_target = nil
M._last_ok = false
M._last_curve = nil

local function unpack_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    if v.X ~= nil then return v.X, v.Y, v.Z end
    return nil
end

local function make_vec3(x, y, z)
    if Vector3 and Vector3.new then
        return Vector3.new(x, y, z)
    end
    return { x = x, y = y, z = z }
end

function M.available()
    return raycast
        and (raycast.track_silent_target or raycast.set_silent_target)
        and raycast.stop_silent_tracking
end

function M.ensure_hook()
    if not M.available() then return false end
    if hook_ready or (raycast.is_silent_hook_active and raycast.is_silent_hook_active()) then
        hook_ready = true
        return true
    end
    if not raycast.enable_silent_hook then
        hook_ready = true
        return true
    end
    local ok = raycast.enable_silent_hook()
    hook_ready = ok == true
    return hook_ready
end

function M.is_tracking()
    return tracking
end

function M.last_ok()
    return M._last_ok
end

function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if not ok or not pos then return nil end
    local x, y, z = unpack_pos(pos)
    if not x then return nil end
    return { x = x, y = y, z = z }
end

function M.stop()
    M._last_origin = nil
    M._last_target = nil
    M._last_curve = nil

    local was_active = tracking or M._last_ok
    M._last_ok = false
    tracking = false

    -- Avoid spamming native stop while already idle (hitchance miss / no target).
    if not was_active then return end
    if not M.available() then return end
    pcall(raycast.stop_silent_tracking)
    if raycast.clear_silent_target then
        pcall(raycast.clear_silent_target)
    end
end

function M.last_segment()
    return M._last_origin, M._last_target
end

function M.last_curve()
    return M._last_curve
end

local function build_dir(origin, aim_point)
    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    if not ox or not ax then
        return nil, nil
    end

    local dx, dy, dz = ax - ox, ay - oy, az - oz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local dir

    if dist < 0.001 then
        local cam = M.get_camera_origin()
        if cam then
            dx, dy, dz = cam.x - ox, cam.y - oy, cam.z - oz
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        end
        if not dist or dist < 0.001 then
            dir = make_vec3(0, 1, 0)
        else
            dir = make_vec3(dx, dy, dz)
        end
    else
        dir = make_vec3(dx, dy, dz)
    end

    return make_vec3(ox, oy, oz), dir
end

-- Per-frame silent override (no key hold). Used by ragebot autofire.
function M.set_target(origin, aim_point, hitpart)
    M._last_ok = false
    M._last_curve = nil

    if not aim_point then
        return false
    end

    origin = origin or M.get_camera_origin()
    if not origin then
        return false
    end

    if not M.ensure_hook() then
        return false
    end

    if not raycast.set_silent_target then
        return false
    end

    local origin_v, dir = build_dir(origin, aim_point)
    if not origin_v or not dir then
        return false
    end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    M._last_origin = { x = ox, y = oy, z = oz }
    if hitpart and hitpart.x then
        M._last_target = { x = hitpart.x, y = hitpart.y, z = hitpart.z }
    else
        M._last_target = { x = ax, y = ay, z = az }
    end

    local ok_call, ok = pcall(raycast.set_silent_target, origin_v, dir)
    ok = ok_call and (ok == true or ok == nil)
    M._last_ok = ok
    tracking = ok
    return ok
end

-- Direct ray to aim (legacy / bullet TP). Key-held track for silent aim.
function M.track(origin, aim_point, shoot_vk, hitpart)
    M._last_ok = false
    M._last_curve = nil

    if not aim_point then
        return false
    end

    origin = origin or M.get_camera_origin()
    if not origin then
        return false
    end

    if not M.ensure_hook() then
        return false
    end

    if not raycast.track_silent_target then
        return M.set_target(origin, aim_point, hitpart)
    end

    local origin_v, dir = build_dir(origin, aim_point)
    if not origin_v or not dir then
        return false
    end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    local key = shoot_vk or 0x01

    M._last_origin = { x = ox, y = oy, z = oz }
    if hitpart and hitpart.x then
        M._last_target = { x = hitpart.x, y = hitpart.y, z = hitpart.z }
    else
        M._last_target = { x = ax, y = ay, z = az }
    end

    local ok_call, ok = pcall(raycast.track_silent_target, origin_v, dir, key)
    ok = ok_call and ok == true
    M._last_ok = ok
    tracking = ok
    return ok
end

-- Silent track straight to hitpart (API projectiles are near-hitscan speed).
-- Still builds a muzzle->hitpart drop curve for visuals / target line.
function M.track_curve(origin, aim_point, weapon_name, shoot_vk, hitpart)
    origin = origin or M.get_camera_origin()
    if not origin or not aim_point then
        M._last_ok = false
        M._last_curve = nil
        return false
    end

    local hit = hitpart or aim_point
    local curve = ballistic.curve_for_weapon(origin, hit, weapon_name, 24)

    -- Never aim above the hitpart - direction is always origin -> selected hitpart.
    local ok = M.track(origin, hit, shoot_vk, hit)
    M._last_curve = curve
    M._last_target = { x = hit.x, y = hit.y, z = hit.z }
    return ok
end

return M

end)()

-- ── core/fflag_mem.lua ──
April._mods["core.fflag_mem"] = (function()
local M = {}

local cache = {}
local ready = false

local FLAG_DEFAULTS = {
    PhysicsSenderMaxBandwidthBps = 38760,
    DataSenderRate = 60,
    S2PhysicsSenderRate = 15,
}

local function can_mem()
    return memory and type(memory.write) == "function"
end

local function can_fflag()
    return fflag and type(fflag.set_value) == "function"
end

function M.available()
    return can_mem() or can_fflag()
end

function M.refresh()
    cache = {}
    ready = false
    if not fflag or not fflag.is_scanned or not fflag.is_scanned() then return end

    local ok, all = pcall(fflag.get_all)
    if ok and type(all) == "table" then
        for i = 1, #all do
            local e = all[i]
            if e and e.name and e.address and e.address > 0 then
                cache[e.name] = {
                    addr = e.address,
                    original = e.original or e.value,
                }
            end
        end
    end
    ready = next(cache) ~= nil
end

local function lookup(name)
    if cache[name] then return cache[name] end
    if not fflag or not fflag.find then return nil end
    local ok, hits = pcall(fflag.find, name)
    if ok and type(hits) == "table" and hits[1] and hits[1].address then
        local e = { addr = hits[1].address, original = hits[1].original or hits[1].value }
        cache[name] = e
        return e
    end
    return nil
end

function M.set_int(name, value)
    if not name then return false end
    if not ready then M.refresh() end

    local num = tonumber(value)
    if num == nil then return false end

    local e = lookup(name)
    if e and e.addr and can_mem() then
        local ok = pcall(memory.write, e.addr, "int32", num)
        if ok then return true end
    end

    if can_fflag() then
        return pcall(fflag.set_value, name, num) == true
    end
    return false
end

function M.reset(name)
    if not name then return false end
    local e = lookup(name)
    local orig = (e and e.original) or FLAG_DEFAULTS[name]
    if orig == nil then
        if fflag and fflag.reset_value then
            return pcall(fflag.reset_value, name)
        end
        return false
    end
    return M.set_int(name, orig)
end

function M.reset_defaults()
    M.set_int("PhysicsSenderMaxBandwidthBps", FLAG_DEFAULTS.PhysicsSenderMaxBandwidthBps)
    M.set_int("DataSenderRate", FLAG_DEFAULTS.DataSenderRate)
    M.set_int("S2PhysicsSenderRate", FLAG_DEFAULTS.S2PhysicsSenderRate)
end

return M

end)()

-- ── core/manip_math.lua ──
April._mods["core.manip_math"] = (function()
local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 24
local MIN_RADIUS = 0.1
local MAX_RADIUS = 1
local MAX_EXTEND_EXTRA = 7
local CACHE_TTL_MS = 180
local MAX_Y_OFFSET = 2.5

-- Vertical samples around the body (full 3D peek search, not horizontal-only).
local Y_OFFSETS = { 0, 0.5, 1.0, 1.5, 2.0, 2.5, -0.5, -1.0, -1.5 }

local _peek_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function cache_key(origin, target_pos)
    if not origin or not target_pos then return nil end
    return string.format(
        "%.1f:%.1f:%.1f>%.1f:%.1f:%.1f",
        origin.x, origin.y, origin.z,
        target_pos.x, target_pos.y, target_pos.z
    )
end

function M.eye_offset_y()
    return EYE_OFFSET_Y
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_RADIUS then return MAX_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
end

function M.clamp_extend_extra(extra)
    extra = tonumber(extra) or 0
    if extra < 0 then return 0 end
    if extra > MAX_EXTEND_EXTRA then return MAX_EXTEND_EXTRA end
    return math.floor(extra * 100 + 0.5) / 100
end

function M.max_y_offset()
    return MAX_Y_OFFSET
end

local function clamp_peek_y(peek, origin)
    if not peek or not origin then return peek end
    local dy = peek.y - origin.y
    if dy > MAX_Y_OFFSET then
        peek.y = origin.y + MAX_Y_OFFSET
    elseif dy < -MAX_Y_OFFSET then
        peek.y = origin.y - MAX_Y_OFFSET
    end
    return peek
end

local function peek_y_ok(peek, origin)
    if not peek or not origin then return false end
    local dy = peek.y - origin.y
    return dy >= -MAX_Y_OFFSET - 0.02 and dy <= MAX_Y_OFFSET + 0.02
end

function M.is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast or not raycast.is_visible then
        return true
    end
    local ex, ey, ez = ox, oy + EYE_OFFSET_Y, oz
    return raycast.is_visible(ex, ey, ez, tx, ty, tz) == true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return M.is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

local function steps_for_radius(radius, base_steps)
    base_steps = base_steps or DEFAULT_STEPS
    if radius <= 0.35 then
        return math.max(base_steps, 32)
    end
    if radius <= 0.7 then
        return math.max(base_steps, 26)
    end
    if radius <= 1.5 then
        return math.max(base_steps, 22)
    end
    return base_steps
end

local function yaw_to_target(origin, target_pos)
    local dx = target_pos.x - origin.x
    local dz = target_pos.z - origin.z
    if math.abs(dx) < 1e-6 and math.abs(dz) < 1e-6 then
        return 0
    end
    return math.atan2(dz, dx)
end

local function try_peek_at(cx, oy, cz, origin, target_pos)
    if M.is_visible_from(cx, oy, cz, target_pos.x, target_pos.y, target_pos.z) then
        return clamp_peek_y({ x = cx, y = oy, z = cz }, origin)
    end
    return nil
end

-- Ring + slight vertical jitter at each Y sample for fuller 3D coverage.
function M.search_peek_at_radius(origin, target_pos, radius, steps)
    if not origin or not target_pos then return nil end
    steps = steps_for_radius(radius, steps or DEFAULT_STEPS)

    local facing = yaw_to_target(origin, target_pos)
    local sector = math.pi * 0.65

    for _, yoff in ipairs(Y_OFFSETS) do
        local oy = origin.y + yoff

        local sector_steps = math.max(10, math.floor(steps * 0.6))
        for i = 0, sector_steps - 1 do
            local t = (i / math.max(1, sector_steps - 1)) * 2 - 1
            local angle = facing + t * sector
            local cx = origin.x + math.cos(angle) * radius
            local cz = origin.z + math.sin(angle) * radius
            local hit = try_peek_at(cx, oy, cz, origin, target_pos)
            if hit then return hit end
        end

        for i = 0, steps - 1 do
            local angle = (i / steps) * math.pi * 2
            local cx = origin.x + math.cos(angle) * radius
            local cz = origin.z + math.sin(angle) * radius
            local hit = try_peek_at(cx, oy, cz, origin, target_pos)
            if hit then return hit end
        end

        -- Diagonal samples on the ring (helps corner peeks).
        local diag = math.max(8, math.floor(steps * 0.35))
        for i = 0, diag - 1 do
            local angle = facing + (i / diag) * math.pi * 2
            local r2 = radius * 0.72
            local cx = origin.x + math.cos(angle) * r2
            local cz = origin.z + math.sin(angle) * r2
            local hit = try_peek_at(cx, oy, cz, origin, target_pos)
            if hit then return hit end
        end
    end

    return nil
end

local function build_radii(base, max_r)
    local radii = {}
    local r = base
    local step = r < 0.5 and 0.08 or (r < 1 and 0.12 or 0.35)
    while r < max_r - 0.03 do
        radii[#radii + 1] = r
        r = r + step
        step = r < 1 and 0.12 or 0.35
    end
    radii[#radii + 1] = max_r
    return radii
end

local function search_peek(origin, target_pos, base_r, max_r, steps, extend)
    steps = steps or DEFAULT_STEPS
    base_r = M.clamp_radius(base_r)

    local radii
    if extend and max_r > base_r + 0.04 then
        max_r = base_r + M.clamp_extend_extra(max_r - base_r)
        radii = build_radii(base_r, max_r)
    else
        radii = { base_r }
        max_r = base_r
    end

    local total = #radii
    for idx, radius in ipairs(radii) do
        local peek = M.search_peek_at_radius(origin, target_pos, radius, steps)
        if peek then
            return peek, radius, idx / total
        end
    end
    return nil, max_r, 1
end

function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}
    local base_r = M.clamp_radius(opts.base_radius or opts.max_radius or 1)
    local extra = M.clamp_extend_extra(opts.extend_extra or 0)
    local extend = opts.extend == true or extra > 0.04
    local max_r = extend and (base_r + extra) or base_r

    if not origin or not target_pos then
        return {
            state = "blocked", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = extend, scan_progress = 0,
        }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return {
            state = "direct", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 1,
        }
    end

    local key = cache_key(origin, target_pos)
    local now = tick_ms()
    if key and _peek_cache[key] then
        local ent = _peek_cache[key]
        if ent.peek and (now - (ent.t or 0)) < CACHE_TTL_MS then
            clamp_peek_y(ent.peek, origin)
            if peek_y_ok(ent.peek, origin) and M.is_visible_from_pos(ent.peek, target_pos) then
                local extended = extend and (ent.radius or base_r) > base_r + 0.05
                return {
                    state = "ready", peek = ent.peek, radius = ent.radius or base_r,
                    base_radius = base_r, extend_active = extended,
                    scan_progress = 1, cached = true,
                }
            end
        end
    end

    local peek, radius, progress = search_peek(origin, target_pos, base_r, max_r, opts.steps, extend)
    if peek then
        clamp_peek_y(peek, origin)
        local extended = extend and radius > base_r + 0.05
        if key then
            _peek_cache[key] = { peek = peek, radius = radius, t = now }
        end
        return {
            state = "ready", peek = peek, radius = radius,
            base_radius = base_r, extend_active = extended,
            scan_progress = progress or 1,
        }
    end

    return {
        state = extend and "scanning" or "blocked",
        peek = nil, radius = max_r,
        base_radius = base_r, extend_active = extend, scan_progress = 1,
    }
end

function M.find_manipulation_position(origin, target_pos, opts)
    local ev = M.evaluate_manipulation(origin, target_pos, opts)
    if ev.state == "direct" then
        return { x = origin.x, y = origin.y, z = origin.z }
    end
    return ev.peek
end

function M.peek_track_origin(peek, muzzle, body)
    if not peek then return nil end
    local base = body or peek
    local yoff = peek.y - base.y
    if yoff > MAX_Y_OFFSET then
        yoff = MAX_Y_OFFSET
    elseif yoff < -MAX_Y_OFFSET then
        yoff = -MAX_Y_OFFSET
    end

    local y
    if muzzle and body then
        y = muzzle.y + yoff
    else
        y = body and (body.y + yoff) or peek.y
    end
    return { x = peek.x, y = y, z = peek.z }
end

function M.ring_y(origin)
    if not origin then return 0 end
    return origin.y
end

function M.dist_sq(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

function M.clear_peek_cache()
    _peek_cache = {}
end

return M

end)()

-- ── core/desync_vis.lua ──
April._mods["core.desync_vis"] = (function()
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")

local M = {}

function M.draw_box(wx, wy, wz, size, col, thick)
    if not wx then return end
    size = size or 1.2
    thick = thick or 2
    local s = size

    esp_util.draw_world_line(wx - s, wy - s, wz - s, wx + s, wy - s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz - s, wx + s, wy - s, wz + s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz + s, wx - s, wy - s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz + s, wx - s, wy - s, wz - s, col, thick)
    esp_util.draw_world_line(wx - s, wy + s, wz - s, wx + s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy + s, wz - s, wx + s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx + s, wy + s, wz + s, wx - s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy + s, wz + s, wx - s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz - s, wx - s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz - s, wx + s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz + s, wx + s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz + s, wx - s, wy + s, wz + s, col, thick)
end

function M.draw_cross(wx, wy, wz, size, col, thick)
    if not wx then return end
    size = size or 1.5
    thick = thick or 2
    esp_util.draw_world_line(wx - size, wy, wz, wx + size, wy, wz, col, thick)
    esp_util.draw_world_line(wx, wy - size, wz, wx, wy + size, wz, col, thick)
    esp_util.draw_world_line(wx, wy, wz - size, wx, wy, wz + size, col, thick)
end

function M.draw_sphere_ring(wx, wy, wz, radius, col, thick)
    if not wx then return end
    radius = radius or 1.5
    thick = thick or 2
    local steps = 16
    local prev_sx, prev_sy, prev_vis
    for i = 0, steps do
        local a = (i / steps) * math.pi * 2
        local px = wx + math.cos(a) * radius
        local pz = wz + math.sin(a) * radius
        local sx, sy, vis = esp_util.w2s(px, wy, pz)
        if vis and prev_vis then
            draw_util.line(prev_sx, prev_sy, sx, sy, col, thick)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end
end

function M.draw_link(a, b, col, thick)
    if not a or not b then return end
    esp_util.draw_world_line(a.x, a.y, a.z, b.x, b.y, b.z, col, thick or 2)
end

function M.draw_labeled(wx, wy, wz, label, col, size)
    if not wx or not label then return end
    local sx, sy, vis = esp_util.w2s(wx, wy + 2, wz)
    if vis then
        draw_util.text_centered(sx, sy, label, col, size or 13)
    end
end

function M.draw_mode(mode, wx, wy, wz, size, col, thick)
    mode = mode or 0
    if mode == 1 then
        M.draw_cross(wx, wy, wz, size, col, thick)
    elseif mode == 2 then
        M.draw_sphere_ring(wx, wy, wz, size, col, thick)
    else
        M.draw_box(wx, wy, wz, size, col, thick)
    end
end

function M.draw_server_local(server, local_pos, opts)
    if not server or not local_pos then return end
    opts = opts or {}

    local mode = opts.mode or 0
    local size = opts.size or 1.2
    local col_server = opts.col_server or { 0.2, 0.85, 1, 0.9 }
    local col_local = opts.col_local or { 1, 0.35, 0.35, 0.9 }
    local col_link = opts.col_link or { 1, 1, 1, 0.4 }
    local server_label = opts.server_label or "SERVER"
    local local_label = opts.local_label or "LOCAL"

    M.draw_mode(mode, server.x, server.y, server.z, size, col_server, 2)
    M.draw_mode(mode, local_pos.x, local_pos.y, local_pos.z, size * 0.85, col_local, 2)

    if opts.link ~= false then
        M.draw_link(server, local_pos, col_link, 2)
    end

    if opts.labels then
        M.draw_labeled(server.x, server.y, server.z, server_label, col_server, 12)
        M.draw_labeled(local_pos.x, local_pos.y, local_pos.z, local_label, col_local, 12)
    end
end

return M

end)()

-- ── core/angle_util.lua ──
April._mods["core.angle_util"] = (function()
-- Shared yaw / flat-direction helpers for movement features.

local env = April.require("core.env")

local M = {}

function M.normalize_yaw(y)
    while y > math.pi do y = y - math.pi * 2 end
    while y < -math.pi do y = y + math.pi * 2 end
    return y
end

function M.yaw_delta(from_yaw, to_yaw)
    return M.normalize_yaw((to_yaw or 0) - (from_yaw or 0))
end

function M.yaw_from_vector(lx, lz)
    if not lx and not lz then return 0 end
    lx, lz = lx or 0, lz or 0
    if math.abs(lx) < 1e-5 and math.abs(lz) < 1e-5 then return 0 end
    return math.atan2(lx, lz)
end

function M.flat_forward(yaw)
    return math.sin(yaw or 0), math.cos(yaw or 0)
end

function M.camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, _, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            return M.yaw_from_vector(lv.x or lv.X, lv.z or lv.Z)
        end
    end
    return 0
end

function M.normalize_pitch(p)
    local lim = math.rad(89)
    if p > lim then return lim end
    if p < -lim then return -lim end
    return p or 0
end

function M.camera_pitch()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.X or a.x
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, pitch = pcall(utility.get_camera_angles)
        if ok and pitch then return math.rad(pitch) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            local ly = lv.y or lv.Y or 0
            return M.normalize_pitch(math.asin(math.max(-1, math.min(1, -ly))))
        end
    end
    return 0
end

function M.body_pitch(lp, root)
    if lp and lp.LookVector then
        local lv = lp.LookVector
        local ly = lv.y or lv.Y
        if ly then
            return M.normalize_pitch(math.asin(math.max(-1, math.min(1, -ly))))
        end
    end
    if root then
        local lv = env.safe_call(function()
            local cf = root.CFrame or root.cframe
            return cf and (cf.LookVector or cf.lookVector)
        end)
        if lv then
            local ly = lv.Y or lv.y or 0
            return M.normalize_pitch(math.asin(math.max(-1, math.min(1, -ly))))
        end
    end
    return M.camera_pitch()
end

function M.body_yaw(lp, root)
    if lp and lp.LookVector then
        local lv = lp.LookVector
        local yaw = M.yaw_from_vector(lv.x or lv.X, lv.z or lv.Z)
        if yaw then return yaw end
    end
    if root then
        local lv = env.safe_call(function()
            local cf = root.CFrame or root.cframe
            return cf and (cf.LookVector or cf.lookVector)
        end)
        if lv then
            return M.yaw_from_vector(lv.X or lv.x, lv.Z or lv.z)
        end
    end
    return M.camera_yaw()
end

function M.point_ahead(x, y, z, yaw, dist, lift)
    dist = dist or 4
    lift = lift or 0
    local fx, fz = M.flat_forward(yaw)
    return x + fx * dist, (y or 0) + lift, z + fz * dist
end

return M

end)()

-- ── core/cframe_move.lua ──
April._mods["core.cframe_move"] = (function()
-- Soft movement helpers. Prefer velocity writes on HRP only - avoid position
-- teleports, limb velocity spam, and insane pulse values (those ban).

local env = April.require("core.env")

local M = {}

local BASE_PARTS = {
    Part = true, MeshPart = true, UnionOperation = true,
    WedgePart = true, CornerWedgePart = true, TrussPart = true,
}

local NOCLIP_PARTS = {
    "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head",
}

local HIP_OFFSET = 3.0
local DEFAULT_GRAVITY = 196.2

function M.delta_time()
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 and dt <= 0.1 then return dt end
    end
    return 0.016
end

function M.key_down(code)
    return input and input.is_key_down and input.is_key_down(code)
end

function M.read_pos(inst)
    if not inst then return nil end
    local pos = inst.Position or inst.position
    if not pos then return nil end
    return {
        x = pos.X or pos.x or 0,
        y = pos.Y or pos.y or 0,
        z = pos.Z or pos.z or 0,
    }
end

function M.read_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.AssemblyLinearVelocity or inst.Velocity or inst.velocity
    if not vel then return 0, 0, 0 end
    return vel.X or vel.x or 0, vel.Y or vel.y or 0, vel.Z or vel.z or 0
end

function M.is_base_part(inst)
    if not inst then return false end
    if inst.is_a then
        local ok, yes = pcall(function() return inst:is_a("BasePart") end)
        if ok and yes then return true end
    end
    local cn = inst.ClassName or inst.class_name
    return BASE_PARTS[cn] == true
end

function M.find_part(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.iter_parts(char)
    local out = {}
    if not char then return out end

    local desc = env.safe_call(function() return char:get_descendants() end)
        or env.safe_call(function() return char:GetDescendants() end)
    if desc then
        for _, inst in ipairs(desc) do
            if M.is_base_part(inst) then
                out[#out + 1] = inst
            end
        end
    end

    return out
end

function M.set_character_noclip(char, _root, enabled)
    local collide = not enabled
    for _, inst in ipairs(M.iter_parts(char)) do
        M.set_part_collide(inst, collide)
    end
end

function M.set_velocity(inst, x, y, z)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, x, y, z)
    else
        pcall(function()
            if inst.set_velocity then
                inst:set_velocity(x, y, z)
            else
                inst.Velocity = Vector3.new(x, y, z)
            end
        end)
    end
end

function M.set_angular_velocity(inst, x, y, z)
    if not inst then return end
    x, y, z = x or 0, y or 0, z or 0
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, inst, x, y, z)
    else
        pcall(function()
            if inst.set_angular_velocity then
                inst:set_angular_velocity(x, y, z)
            else
                inst.AngularVelocity = Vector3.new(x, y, z)
            end
        end)
    end
end

function M.set_position_only(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function()
            if inst.set_position then
                inst:set_position(x, y, z)
            else
                inst.Position = Vector3.new(x, y, z)
            end
        end)
    end
end

function M.set_position(inst, x, y, z)
    M.set_position_only(inst, x, y, z)
end

function M.set_part_collide(inst, collide)
    if not inst then return end
    if part and part.set_can_collide then
        pcall(part.set_can_collide, inst, collide)
    else
        pcall(function() inst.CanCollide = collide end)
    end
end

function M.set_noclip_parts(char, enabled)
    if not char then return end
    local collide = not enabled
    for i = 1, #NOCLIP_PARTS do
        local p = M.find_part(char, NOCLIP_PARTS[i])
        if p and M.is_base_part(p) then
            M.set_part_collide(p, collide)
        end
    end
end

function M.humanoid_state(hum, state)
    if not hum or state == nil then return end
    pcall(function()
        if hum.set_state then hum:set_state(state)
        else hum.state = state
        end
    end)
end

function M.humanoid_suspend(hum)
    if not hum then return end
    pcall(function() hum.platform_stand = false end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
end

function M.humanoid_running(hum)
    M.humanoid_state(hum, 8)
end

function M.zero_part(inst)
    if not inst then return end
    M.set_velocity(inst, 0, 0, 0)
    M.set_angular_velocity(inst, 0, 0, 0)
end

function M.zero_character(char, root)
    if root then M.zero_part(root) end
    for i = 1, #NOCLIP_PARTS do
        local p = char and M.find_part(char, NOCLIP_PARTS[i])
        if p and p ~= root then
            M.zero_part(p)
        end
    end
end

function M.workspace_gravity()
    local ws = env.get_workspace and env.get_workspace() or (game and game.workspace)
    if ws then
        local g = ws.Gravity or ws.gravity
        if type(g) == "number" and g > 0 then return g end
    end
    return DEFAULT_GRAVITY
end

function M.camera_flat_axes()
    if not camera or not camera.get_look_vector then return nil end
    local ok, look = pcall(camera.get_look_vector)
    if not ok or not look then return nil end

    local lx = look.x or look.X or 0
    local lz = look.z or look.Z or 0
    local lm = math.sqrt(lx * lx + lz * lz)
    if lm < 0.001 then return nil end
    lx, lz = lx / lm, lz / lm

    return lx, lz, -lz, lx
end

function M.read_flat_input()
    local lx, lz, rx, rz = M.camera_flat_axes()
    if not lx then return 0, 0 end

    local mx, mz = 0, 0
    if M.key_down(0x57) then mx, mz = mx + lx, mz + lz end
    if M.key_down(0x53) then mx, mz = mx - lx, mz - lz end
    if M.key_down(0x41) then mx, mz = mx - rx, mz - rz end
    if M.key_down(0x44) then mx, mz = mx + rx, mz + rz end

    local mag = math.sqrt(mx * mx + mz * mz)
    if mag < 0.001 then return 0, 0 end
    return mx / mag, mz / mag
end

function M.read_fly_input()
    local mx, mz = M.read_flat_input()
    local my = 0
    if M.key_down(0x20) then my = 1 end
    if M.key_down(0x11) then my = -1 end
    return mx, my, mz
end

function M.ground_distance(x, y, z)
    if not raycast or not raycast.cast then return nil end
    if raycast.is_ready and not raycast.is_ready() then return nil end

    local hit, _, dist = raycast.cast(x, y + 2, z, x, y - 512, z)
    if not hit then return nil end
    return dist
end

function M.floor_y_at(x, y, z)
    local dist = M.ground_distance(x, y, z)
    if not dist then return nil end
    return y + 2 - dist + HIP_OFFSET
end

function M.clamp_above_floor(x, y, z)
    local floor_y = M.floor_y_at(x, y, z)
    if floor_y and y < floor_y then return floor_y end
    return y
end

-- Legacy position+velocity drive (teleports). Prefer drive_root_velocity.
function M.drive_root(root, pos, dx, dy, dz, speed, dt)
    if not root or not pos then return pos end

    dt = dt or M.delta_time()
    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)

    if mag < 0.001 then
        M.set_velocity(root, 0, 0, 0)
        return pos
    end

    dx, dy, dz = dx / mag, dy / mag, dz / mag
    local step = speed * dt
    local nx = pos.x + dx * step
    local ny = pos.y + dy * step
    local nz = pos.z + dz * step

    M.set_position_only(root, nx, ny, nz)
    M.set_velocity(root, dx * speed, dy * speed, dz * speed)

    return { x = nx, y = ny, z = nz }
end

-- Velocity-only HRP drive: no position writes. Smooth lerp toward target vel.
function M.drive_root_velocity(root, dx, dy, dz, speed, dt, opts)
    if not root then return end
    opts = opts or {}
    dt = dt or M.delta_time()

    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
    local tx, ty, tz = 0, 0, 0
    if mag >= 0.001 then
        dx, dy, dz = dx / mag, dy / mag, dz / mag
        tx, ty, tz = dx * speed, dy * speed, dz * speed
    end

    -- Soft gravity cancel when hovering / moving so we don't need PlatformStand.
    if opts.cancel_gravity ~= false and math.abs(ty) < 0.01 and mag < 0.001 then
        -- idle hover: hold altitude with near-zero vertical (server still sees freefall-ish)
        ty = 0
    elseif opts.cancel_gravity ~= false and math.abs(dy) < 0.01 and mag >= 0.001 then
        -- horizontal move: keep Y stable
        ty = 0
    end

    local cx, cy, cz = M.read_velocity(root)
    local blend = opts.blend or 0.35
    blend = math.max(0.05, math.min(1, blend))

    local nx = cx + (tx - cx) * blend
    local ny = cy + (ty - cy) * blend
    local nz = cz + (tz - cz) * blend

    local max_speed = opts.max_speed or (speed * 1.15)
    local sm = math.sqrt(nx * nx + ny * ny + nz * nz)
    if sm > max_speed and sm > 0.001 then
        local s = max_speed / sm
        nx, ny, nz = nx * s, ny * s, nz * s
    end

    M.set_velocity(root, nx, ny, nz)
    M.set_angular_velocity(root, 0, 0, 0)
end

return M

end)()

-- ── core/runservice.lua ──
April._mods["core.runservice"] = (function()
-- RunService sim hooks. Prefer Heartbeat:Connect; fall back to on_frame dispatch.
local env = April.require("core.env")

local M = {}

local _svc = nil
local _svc_checked = false
local _sim_hooks = {}
local _render_hooks = {}
local _heartbeat_conn = nil
local _render_conn = nil
local _uses_heartbeat = false
local _last_hb_ms = 0
local _dispatched_this_frame = false

local function delta_time(fallback)
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 then return math.min(dt, 0.1) end
    end
    return fallback or 0.016
end

local function run_sim_hooks(dt)
    for i = 1, #_sim_hooks do
        local hook = _sim_hooks[i]
        if hook then
            env.safe_call(hook, dt)
        end
    end
end

local function run_render_hooks(dt)
    for i = 1, #_render_hooks do
        local hook = _render_hooks[i]
        if hook then
            env.safe_call(hook, dt)
        end
    end
end

local function try_connect_render_stepped(svc)
    if not svc then return false end

    local rs = svc.RenderStepped or svc.renderStepped
    if not rs then return false end

    local connect = rs.Connect or rs.connect
    if type(connect) ~= "function" then return false end

    local ok, conn = pcall(function()
        return connect(rs, function(dt)
            run_render_hooks(tonumber(dt) or delta_time())
        end)
    end)
    if ok and conn then
        _render_conn = conn
        return true
    end
    return false
end

local function try_connect_heartbeat(svc)
    if not svc then return false end

    local hb = svc.Heartbeat or svc.heartbeat
    if not hb then return false end

    local connect = hb.Connect or hb.connect
    if type(connect) ~= "function" then
        -- Some mirrors expose the signal as callable / method on service
        connect = svc.Heartbeat and (svc.Heartbeat.Connect or svc.Heartbeat.connect)
    end
    if type(connect) ~= "function" then return false end

    local ok, conn = pcall(function()
        return connect(hb, function(dt)
            _uses_heartbeat = true
            _last_hb_ms = utility and utility.get_tick_count and utility.get_tick_count() or 0
            run_sim_hooks(tonumber(dt) or delta_time())
        end)
    end)
    if ok and conn then
        _heartbeat_conn = conn
        _uses_heartbeat = true
        return true
    end
    return false
end

function M.get()
    if _svc_checked then return _svc end
    _svc_checked = true

    if not game or not game.get_service then return nil end

    local ok, svc = pcall(function()
        return game.get_service("RunService")
    end)

    if ok and svc then
        _svc = svc
        try_connect_heartbeat(svc)
        try_connect_render_stepped(svc)
    end
    return _svc
end

function M.available()
    return M.get() ~= nil
end

function M.uses_heartbeat()
    M.get()
    return _uses_heartbeat == true
end

function M.movement_allowed()
    if not game then return false end
    return env.get_local_player() ~= nil
end

function M.on_sim(fn)
    if type(fn) ~= "function" then return false end
    _sim_hooks[#_sim_hooks + 1] = fn
    M.get()
    return true
end

function M.on_render(fn)
    if type(fn) ~= "function" then return false end
    _render_hooks[#_render_hooks + 1] = fn
    M.get()
    return true
end

local _bind_names = {}

-- priority_offset: number added to Camera, or "Last" for RenderPriority.Last.
local function render_priority(priority_offset)
    if priority_offset == "Last" or priority_offset == "last" then
        if Enum and Enum.RenderPriority and Enum.RenderPriority.Last then
            local last = Enum.RenderPriority.Last.Value or Enum.RenderPriority.Last
            if type(last) == "number" then return last end
        end
        return 2000
    end

    local offset = tonumber(priority_offset) or 3
    if Enum and Enum.RenderPriority and Enum.RenderPriority.Camera then
        local base = Enum.RenderPriority.Camera.Value or Enum.RenderPriority.Camera
        if type(base) == "number" then return base + offset end
    end
    -- Roblox Camera priority is 200.
    return 200 + offset
end

function M.on_bind_render(name, fn, priority_offset)
    if type(fn) ~= "function" or not name then return false end
    local svc = M.get()
    if not svc then return false end

    local bind = svc.BindToRenderStep or svc.bind_to_render_step
    if type(bind) ~= "function" then return false end

    local prio = render_priority(priority_offset)

    local unbind = svc.UnbindFromRenderStep or svc.unbind_from_render_step
    if type(unbind) == "function" then
        pcall(unbind, svc, name)
    end

    local ok = pcall(function()
        bind(svc, name, prio, function(dt)
            env.safe_call(fn, tonumber(dt) or delta_time())
        end)
    end)

    if ok then _bind_names[name] = true end
    return ok
end

function M.unbind_render(name)
    if not name then return end
    local svc = M.get()
    if not svc then return end
    local unbind = svc.UnbindFromRenderStep or svc.unbind_from_render_step
    if type(unbind) == "function" then
        env.safe_call(unbind, svc, name)
    end
    _bind_names[name] = nil
end

function M.dispatch(dt)
    if _uses_heartbeat then
        local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
        if _last_hb_ms > 0 and (now - _last_hb_ms) < 40 then
            run_render_hooks(dt or delta_time())
            return
        end
    end
    run_sim_hooks(dt or delta_time())
    run_render_hooks(dt or delta_time())
end

return M

end)()

-- ── core/misc_gate.lua ──
April._mods["core.misc_gate"] = (function()
local runservice = April.require("core.runservice")

local M = {}

function M.movement_allowed()
    return runservice.movement_allowed()
end

return M

end)()

-- ── core/movement_ctrl.lua ──
April._mods["core.movement_ctrl"] = (function()
-- Fly / Slowfall - HRP velocity on RunService Heartbeat (falls back to on_frame).

local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local P_FLY = "april_noclip_enabled"
local P_SPEED = "april_noclip_speed"
local P_SLOWFALL = "april_slowfall_enabled"

local _installed = false
local fly_active = false
local fly_noclip = false
local tracked_char_id = nil
local last_fly_zero_ms = 0

-- Slider 1-20 studs/s
local MIN_FLY_SPEED = 1
local MAX_FLY_SPEED = 20
local GROUND_DIST = 4.5

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function char_id(char)
    if not char then return nil end
    return char.Address or char.address or tostring(char)
end

local function get_character(lp)
    if lp and lp.character then return lp.character end
    if game and game.local_player and game.local_player.character then
        return game.local_player.character
    end
    return nil
end

local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return move.find_part(char, "HumanoidRootPart")
end

local function get_humanoid(lp)
    if lp and lp.humanoid and env.is_valid(lp.humanoid) then
        return lp.humanoid
    end
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
        return char:FindFirstChildOfClass("Humanoid")
    end)
end

local function hum_alive(hum)
    if not hum then return false end
    local hp = hum.Health or hum.health
    if hp == nil then return true end
    return hp > 0
end

local function fly_speed()
    local spd = settings.num(P_SPEED, 5)
    if spd < MIN_FLY_SPEED then spd = MIN_FLY_SPEED end
    if spd > MAX_FLY_SPEED then spd = MAX_FLY_SPEED end
    return spd
end

local function is_on_ground(root)
    local pos = move.read_pos(root)
    if not pos then return false end
    local dist = move.ground_distance(pos.x, pos.y, pos.z)
    if dist == nil then return false end
    return dist <= GROUND_DIST
end

local function has_move_input(mx, my, mz)
    return mx ~= 0 or my ~= 0 or mz ~= 0
end

local function set_fly_noclip(char, enabled)
    fly_noclip = enabled
    if not char then return end
    move.set_noclip_parts(char, enabled)
end

local function clear_swim_block()
    local lp = env.get_local_player()
    local char = get_character(lp)
    if not char then return end
    local water = env.safe_call(function()
        return char:FindFirstChild("WaterController")
            or (char.find_first_child and char:find_first_child("WaterController"))
    end)
    if not water then return end
    pcall(function()
        if water.set_attribute then water:set_attribute("IsSwim", false)
        elseif water.SetAttribute then water:SetAttribute("IsSwim", false)
        end
    end)
end

local function apply_fly_velocity(root, mx, my, mz, speed)
    local tx, ty, tz = 0, 0, 0
    local mag = math.sqrt(mx * mx + my * my + mz * mz)
    if mag >= 0.001 then
        tx = mx / mag * speed
        ty = my / mag * speed
        tz = mz / mag * speed
    end
    move.set_velocity(root, tx, ty, tz)
    move.set_angular_velocity(root, 0, 0, 0)
end

local function tick_fly(root, hum, char)
    if not hum_alive(hum) then return end

    local mx, my, mz = move.read_fly_input()
    local on_ground = is_on_ground(root)
    local moving = has_move_input(mx, my, mz)

    -- On ground with no input: normal walk/jump.
    if on_ground and not moving then
        set_fly_noclip(char, false)
        return
    end

    local speed = fly_speed()
    apply_fly_velocity(root, mx, my, mz, speed)
    set_fly_noclip(char, not on_ground or moving)
    clear_swim_block()
end

local function tick_slowfall(root, hum, _dt)
    local raw = settings.num("april_slowfall_speed", 5)
    if raw < 1 then raw = 1 end
    local cap = -(0.8 + (raw * 0.22))

    local vx, vy, vz = move.read_velocity(root)
    if vy < cap then
        move.set_velocity(root, vx, cap, vz)
    end

    clear_swim_block()
end

local function abort_active(root, char)
    set_fly_noclip(char, false)
    if fly_active and root then
        local now = tick_ms()
        if now - last_fly_zero_ms > 80 then
            local vx, _, vz = move.read_velocity(root)
            move.set_velocity(root, vx, 0, vz)
            last_fly_zero_ms = now
        end
    end
    fly_active = false
end

function M.tick(_dt)
    local misc_gate = April.require("core.misc_gate")
    if not misc_gate.movement_allowed() then
        abort_active(nil, nil)
        return
    end

    local fling = April.require("features.movement.fling")
    if fling.is_active and fling.is_active() then
        abort_active(nil, nil)
        return
    end

    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    if not char or not env.is_valid(char) then return end

    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root or not hum then return end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        fly_active = false
        fly_noclip = false
        tracked_char_id = cid
    end

    local want_fly = settings.enabled(P_FLY)

    if want_fly then
        fly_active = true
        tick_fly(root, hum, char)
    else
        if fly_active then
            abort_active(root, char)
        else
            set_fly_noclip(char, false)
        end
        if settings.enabled(P_SLOWFALL) then
            tick_slowfall(root, hum, _dt)
        end
    end
end

function M.install()
    if _installed then return end
    _installed = true
    April.require("core.runservice").on_sim(function(dt)
        M.tick(dt)
    end)
end

return M

end)()

-- ── core/config_store.lua ──
April._mods["core.config_store"] = (function()
local cache = April.require("core.cache")

local M = {}

M.SLOT_MIN = 1
M.SLOT_MAX = 5
M.FILE_VERSION = 2

local META_FILE = "April_meta.txt"

local EXCLUDE = {
    april_cfg_slot = true,
    april_cfg_profile_name = true,
    april_cfg_autoload = true,
    april_cfg_autoload_slot = true,
    april_cfg_autoload_profile = true,
    april_debug_overlay = true,
}

local MENU_KEYS = {
    "april_ui_theme_preset", "april_ui_window_opacity", "april_ui_panel_opacity",
    "april_ui_border_strength", "april_ui_corner_style", "april_ui_scale", "april_ui_density",
    "april_ui_bg_dim", "april_ui_motion_profile", "april_ui_reduce_motion",
    "april_ui_custom_colors", "april_ui_custom_anim", "april_ui_show_cursor_dot",
    "april_ui_accent_anim", "april_ui_anim_speed", "april_ui_menu_fade",
    "april_ui_anim_targets", "april_ui_color_overrides", "april_ui_per_element",
    "april_ui_style_title", "april_ui_style_section", "april_ui_style_slider",
    "april_ui_style_scroll", "april_ui_style_sidebar", "april_ui_style_checkbox",
    "april_ui_style_overlay", "april_ui_window_x", "april_ui_window_y",
    "april_esp_text_size",
    "april_player_enabled", "april_player_enabled_mode",
    "april_player_box_mode",
    "april_player_health", "april_player_skeleton",
    "april_player_show_name", "april_player_show_distance",
    "april_player_show_weapon",
    "april_player_clan_tag",
    "april_player_flag_downed", "april_player_flag_safezone",
    "april_player_flag_staff", "april_player_flag_reviving",
    "april_player_esp_filters", "april_player_esp_flags",
    "april_player_range",
        "april_target_overlay", "april_target_overlay_gear_size", "april_target_overlay_top",
    "april_crosshair_source", "april_target_gear_source",
    "april_crosshair_enabled", "april_crosshair_type", "april_crosshair_size", "april_crosshair_gap",
    "april_crosshair_thickness", "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
    "april_crosshair_follow", "april_crosshair_follow_smooth",
    "april_crosshair_spin", "april_crosshair_spin_speed",
    "april_crosshair_pulse", "april_crosshair_pulse_speed",
    "april_aimbot", "april_aim_key", "april_aim_key_mode",
    "april_aim_target_type", "april_aim_bone",
    "april_aim_filters", "april_aim_whitelist_ids",
    "april_aim_targets", "april_aim_options",
    "april_aim_draw_fov", "april_aim_fov_style", "april_aim_target_line",
    "april_aim_max_dist", "april_aim_fov", "april_aim_smooth",
    "april_silent_aim", "april_silent_aim_mode",
    "april_silent_target_type", "april_silent_bone",
    "april_silent_filters", "april_silent_whitelist_ids",
    "april_silent_targets", "april_silent_options",
    "april_bullet_enabled", "april_bullet_body_peek",
    "april_silent_bullet_tp",
    "april_silent_bullet_manip",
    "april_silent_manip_dist", "april_silent_manip_extend", "april_silent_manip_extend_dist",
    "april_silent_manip_status", "april_silent_manip_peek_vis",
    "april_silent_draw_fov", "april_silent_fov_style", "april_silent_target_line",
    "april_silent_hit_chance", "april_silent_max_dist", "april_silent_fov", "april_silent_hitscan",
    "april_rage_enabled", "april_rage_enabled_mode",
    "april_rage_target_type", "april_rage_bone",
    "april_rage_filters", "april_rage_whitelist_ids",
    "april_rage_targets", "april_rage_options",
    "april_rage_max_dist", "april_rage_autofire", "april_rage_fire_delay",
    "april_gunmods_enabled", "april_gunmods_enabled_mode",
    "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult",
    "april_gm_range", "april_gm_range_mult",
    "april_gm_double_tap",
    "april_farm_helper", "april_farm_helper_mode", "april_farm_radius", "april_farm_smooth",
    "april_farm_silent",
    "april_world_enabled", "april_world_enabled_mode", "april_stone_node", "april_metal_node", "april_phosphate_node",
    "april_corn_plant", "april_tomato_plant", "april_pumpkin_plant", "april_lemon_plant",
    "april_raspberry_plant", "april_blueberry_plant", "april_wool_plant", "april_hemp_plant",
    "april_deer", "april_boar", "april_wolf",
    "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range",
    "april_world_chams", "april_world_chams_mode", "april_world_chams_color",
    "april_loot_enabled", "april_loot_enabled_mode", "april_dropped_item", "april_wooden_crate", "april_metal_crate",
    "april_steel_crate", "april_food_crate", "april_timed_crate", "april_care_package", "april_btr_crate",
    "april_body_bag", "april_sleeper", "april_trash_can", "april_oil_barrel",
    "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range",
    "april_loot_chams", "april_loot_chams_mode", "april_loot_chams_color",
    "april_npc_enabled", "april_npc_enabled_mode", "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode",
    "april_npc_health", "april_npc_skeleton",
    "april_npc_show_name", "april_npc_show_distance", "april_npc_show_weapon", "april_npc_range",
    "april_anti_afk",
    "april_base_enabled", "april_base_enabled_mode", "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring",
    "april_wooden_door", "april_wooden_double_door", "april_salvaged_door", "april_metal_door",
    "april_metal_double_door", "april_steel_door", "april_steel_double_door",
    "april_garage_door", "april_trap_door", "april_triangle_trap_door",
    "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range",
    "april_base_chams", "april_base_chams_mode", "april_base_chams_color",
    "april_waypoints_enabled", "april_waypoints_enabled_mode", "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h",
    "april_wp_draw", "april_wp_slot",
    "april_map_enabled", "april_map_enabled_mode", "april_map_zoom", "april_map_size", "april_map_icon_scale",
    "april_map_show_players", "april_map_show_npcs", "april_map_show_loot", "april_map_show_world",
    "april_map_show_base", "april_map_show_waypoints",
    "april_map_labels", "april_map_x", "april_map_y",
    "april_noclip_enabled", "april_noclip_enabled_mode", "april_noclip_speed",
    "april_slowfall_enabled", "april_slowfall_enabled_mode", "april_slowfall_speed",
    "april_fling_enabled", "april_fling_enabled_mode", "april_fling_fov", "april_fling_duration",
    "april_desync_enabled", "april_desync_enabled_mode",
    "april_desync_visualizer",
    "april_antiaim_enabled", "april_antiaim_enabled_mode",
    "april_antiaim_yaw_mode",
    "april_antiaim_yaw_manual",
    "april_antiaim_spin_speed",
    "april_antiaim_jitter_step", "april_antiaim_jitter_ms",
    "april_fakeduck_enabled", "april_fakeduck_enabled_mode",
    "april_fakeduck_height",
    "april_fakeduck_spam", "april_fakeduck_spam_mode",
    "april_fakeduck_spam_min", "april_fakeduck_spam_max", "april_fakeduck_spam_ms",
    "april_keybinds_enabled", "april_keybinds_active_only", "april_keybinds_show_unbound", "april_keybinds_show_mode",
    "april_keybinds_x", "april_keybinds_y",
    "april_mod_checker_enabled", "april_mod_checker_interval",
    "april_mod_checker_x", "april_mod_checker_y",
}

local COLOR_KEYS = {
    "april_ui_accent", "april_ui_col_title", "april_ui_col_section",
    "april_ui_col_slider", "april_ui_col_scroll", "april_ui_col_sidebar",
    "april_ui_col_checkbox", "april_ui_col_overlay",
    "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_aimbot", "april_aim_draw_fov", "april_aim_target_line",
    "april_silent_aim", "april_silent_draw_fov", "april_silent_target_line",
    "april_player_enabled", "april_player_skeleton", "april_player_show_name", "april_player_clan_tag",
    "april_player_show_distance", "april_player_show_weapon",
    "april_player_flag_downed", "april_player_flag_safezone",
    "april_player_flag_staff", "april_player_flag_reviving",
    "april_stone_node", "april_metal_node", "april_phosphate_node", "april_corn_plant", "april_tomato_plant",
    "april_pumpkin_plant", "april_lemon_plant", "april_raspberry_plant", "april_blueberry_plant",
    "april_wool_plant", "april_hemp_plant", "april_deer", "april_boar", "april_wolf",
    "april_dropped_item", "april_wooden_crate", "april_metal_crate", "april_steel_crate", "april_food_crate",
    "april_timed_crate", "april_care_package", "april_btr_crate", "april_body_bag", "april_sleeper",
    "april_trash_can", "april_oil_barrel", "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_npc_soldiers", "april_npc_bosses", "april_npc_skeleton",
    "april_npc_show_name", "april_npc_show_distance", "april_npc_show_weapon",
    "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring", "april_wooden_door",
    "april_wooden_double_door", "april_salvaged_door", "april_metal_door", "april_metal_double_door",
    "april_steel_door", "april_steel_double_door", "april_garage_door", "april_trap_door",
    "april_triangle_trap_door", "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_wp_draw", "april_map_player_col", "april_map_npc_col", "april_map_loot_col",
    "april_map_world_col", "april_map_base_col", "april_map_wp_col",
    "april_desync_visualizer",
}

local LEGACY_HOTKEY_TO_CHECKBOX = {
    april_crosshair_enabled_key = "april_crosshair_enabled",
    april_gunmods_enabled_key = "april_gunmods_enabled",
    april_farm_helper_key = "april_farm_helper",
    april_world_enabled_key = "april_world_enabled",
    april_loot_enabled_key = "april_loot_enabled",
    april_npc_enabled_key = "april_npc_enabled",
    april_base_enabled_key = "april_base_enabled",
    april_waypoints_enabled_key = "april_waypoints_enabled",
    april_map_enabled_key = "april_map_enabled",
    april_noclip_enabled_key = "april_noclip_enabled",
    april_slowfall_enabled_key = "april_slowfall_enabled",
    april_desync_enabled_key = "april_desync_enabled",
    april_mod_checker_enabled_key = "april_mod_checker_enabled",
}

local HOTKEY_KEYS = {
    "april_gunmods_enabled",
    "april_farm_helper",
    "april_world_enabled",
    "april_loot_enabled",
    "april_npc_enabled",
    "april_base_enabled",
    "april_waypoints_enabled",
    "april_map_enabled",
    "april_noclip_enabled",
    "april_slowfall_enabled",
    "april_fling_enabled",
    "april_desync_enabled",
    "april_antiaim_enabled",
    "april_fakeduck_enabled",
    "april_silent_aim",
    "april_rage_enabled",
    "april_player_enabled",
    "april_ui_menu_key",
}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

local function slot_path(slot)
    return M.get_config_path("April_Slot_" .. tostring(slot) .. ".txt")
end

local function serialize_value(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then return tostring(v) end
    if t == "string" then return v end
    if t == "table" then
        local parts = {}
        local n = #v
        -- 0-based arrays from some menu builds
        if n == 0 and v[0] ~= nil then
            local i = 0
            while v[i] ~= nil do
                local item = v[i]
                if type(item) == "boolean" then
                    parts[#parts + 1] = item and "1" or "0"
                elseif item == 1 or item == "1" or item == true then
                    parts[#parts + 1] = "1"
                else
                    parts[#parts + 1] = "0"
                end
                i = i + 1
            end
            return table.concat(parts, ",")
        end
        for i = 1, n do
            local item = v[i]
            if type(item) == "boolean" then
                parts[i] = item and "1" or "0"
            elseif item == 1 or item == "1" or item == true or item == "true" then
                parts[i] = "1"
            elseif type(item) == "number" then
                parts[i] = tostring(item)
            else
                parts[i] = "0"
            end
        end
        return table.concat(parts, ",")
    end
    return nil
end

local function parse_value(raw)
    if raw == "true" then return true end
    if raw == "false" then return false end
    local n = tonumber(raw)
    if n and not raw:find(",") then return n end
    if raw:find(",") then
        local out = {}
        for part in raw:gmatch("[^,]+") do
            part = part:match("^%s*(.-)%s*$") or part
            if part == "true" or part == "1" then
                out[#out + 1] = true
            elseif part == "false" or part == "0" then
                out[#out + 1] = false
            else
                out[#out + 1] = tonumber(part) or part
            end
        end
        return out
    end
    return raw
end

local function color_line(id, c)
    if not c then return nil end
    return string.format("@color:%s=%s,%s,%s,%s", id, c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
end

local function collect_menu_keys()
    local seen = {}
    local out = {}

    local function add(id)
        if not id or EXCLUDE[id] or seen[id] then return end
        seen[id] = true
        table.insert(out, id)
    end

    for _, id in ipairs(MENU_KEYS) do add(id) end

    pcall(function()
        local weapons = April.require("game.weapons")
        for _, name in ipairs(weapons.recoil_weapon_names()) do
            add(weapons.slug(name))
        end
    end)

    pcall(function()
        local fb = April.require("core.feature_bind")
        for _, entry in ipairs(fb.list_entries()) do
            add(fb.hide_key_id(entry.id))
        end
    end)

    return out
end

local function write_waypoints(lines)
    for i = M.SLOT_MIN, M.SLOT_MAX do
        local wp = cache.waypoints[i]
        if wp and wp.pos then
            table.insert(lines, string.format("wp:%d:name=%s", i, wp.name or ("Waypoint " .. i)))
            table.insert(lines, string.format("wp:%d:x=%s", i, wp.pos.x))
            table.insert(lines, string.format("wp:%d:y=%s", i, wp.pos.y))
            table.insert(lines, string.format("wp:%d:z=%s", i, wp.pos.z))
        end
    end
end

local function read_waypoints(id, field, val)
    local slot = tonumber(id)
    if not slot then return end
    cache.waypoints[slot] = cache.waypoints[slot] or { name = "Waypoint " .. slot, pos = {} }
    local wp = cache.waypoints[slot]
    if field == "name" then
        wp.name = val
    elseif field == "x" or field == "y" or field == "z" then
        wp.pos = wp.pos or {}
        wp.pos[field] = tonumber(val) or 0
    end
end

local function profile_name_from_menu()
    if not menu or not menu.get then return "Default" end
    local name = menu.get("april_cfg_profile_name")
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        return "Default"
    end
    return name:gsub("[\r\n=]", " "):sub(1, 48)
end

local function read_slot_meta(slot)
    local path = slot_path(slot)
    local f = io.open(path, "r")
    if not f then return nil end

    local meta = {}
    for line in f:lines() do
        if line:sub(1, 1) == "#" then goto continue end
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "profile_name" then
            meta.profile_name = val
        end
        ::continue::
    end
    f:close()
    return meta
end

function M.find_slot_by_profile_name(name)
    if not name or name == "" then return nil end
    local target = name:lower()
    for slot = M.SLOT_MIN, M.SLOT_MAX do
        local meta = read_slot_meta(slot)
        if meta and meta.profile_name and meta.profile_name:lower() == target then
            return slot
        end
    end
    return nil
end

function M.get_slot_profile_name(slot)
    local meta = read_slot_meta(slot)
    return meta and meta.profile_name or nil
end

function M.slot_exists(slot)
    local f = io.open(slot_path(slot), "r")
    if not f then return false end
    f:close()
    return true
end

function M.save_slot(slot)
    slot = math.floor(tonumber(slot) or 1)
    if slot < M.SLOT_MIN or slot > M.SLOT_MAX then return false end
    if not menu or not menu.get then return false end

    local lines = {
        "# April config v" .. M.FILE_VERSION,
        "version=" .. M.FILE_VERSION,
        "profile_name=" .. profile_name_from_menu(),
    }

    for _, id in ipairs(collect_menu_keys()) do
        local v = menu.get(id)
        local s = serialize_value(v)
        if s ~= nil then
            table.insert(lines, id .. "=" .. s)
        end
    end

    for _, id in ipairs(COLOR_KEYS) do
        if menu.get_color then
            local line = color_line(id, menu.get_color(id))
            if line then table.insert(lines, line) end
        end
    end

    for _, id in ipairs(HOTKEY_KEYS) do
        if menu.get_key then
            local vk = menu.get_key(id)
            if vk and vk > 0 then
                table.insert(lines, string.format("@key:%s=%d", id, vk))
            end
        end
    end

    write_waypoints(lines)

    local f = io.open(slot_path(slot), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load_slot(slot, opts)
    opts = opts or {}
    slot = math.floor(tonumber(slot) or 1)
    if slot < M.SLOT_MIN or slot > M.SLOT_MAX then return false end
    if not menu or not menu.set then return false end

    local path = slot_path(slot)
    local f = io.open(path, "r")
    if not f then return false end

    for i = M.SLOT_MIN, M.SLOT_MAX do
        cache.waypoints[i] = nil
    end

    for line in f:lines() do
        if line:sub(1, 1) ~= "#" and line:find("=") then
            local key, val = line:match("^([^=]+)=(.+)$")
            if key and val then
                if key == "profile_name" then
                    if menu.set then menu.set("april_cfg_profile_name", val) end
                elseif key:sub(1, 7) == "@color:" then
                    local id = key:sub(8)
                    local r, g, b, a = val:match("([^,]+),([^,]+),([^,]+),([^,]+)")
                    if id and menu.set_color then
                        menu.set_color(id, {
                            tonumber(r) or 0,
                            tonumber(g) or 0,
                            tonumber(b) or 0,
                            tonumber(a) or 1,
                        })
                    end
                elseif key:sub(1, 5) == "@key:" then
                    local id = key:sub(6)
                    local vk = tonumber(val)
                    if id and vk and menu.set_key then
                        local target = LEGACY_HOTKEY_TO_CHECKBOX[id] or id
                        menu.set_key(target, vk)
                    end
                elseif key:sub(1, 3) == "wp:" then
                    local slot_id, field = key:match("^wp:(%d+):(%w+)$")
                    read_waypoints(slot_id, field, val)
                elseif not EXCLUDE[key] then
                    menu.set(key, parse_value(val))
                end
            end
        end
    end

    f:close()
    April.require("core.settings").invalidate()
    April.require("core.menu_util").sync_masters()

    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        if gun_mods.schedule_apply then
            gun_mods.schedule_apply(1500)
        else
            gun_mods._apply_dirty = true
            gun_mods._defer_until = (utility and utility.get_tick_count and utility.get_tick_count() or 0) + 1500
        end
    end)

    return true
end

function M.delete_slot(slot)
    slot = math.floor(tonumber(slot) or 1)
    local path = slot_path(slot)
    if os.remove then
        return os.remove(path) == true
    end
    return false
end

function M.save_meta()
    if not menu or not menu.get then return false end
    local lines = {
        "version=" .. M.FILE_VERSION,
        "autoload=" .. (menu.get("april_cfg_autoload") and "true" or "false"),
        "autoload_slot=" .. tostring(menu.get("april_cfg_autoload_slot") or 1),
        "autoload_profile=" .. tostring(menu.get("april_cfg_autoload_profile") or ""),
        "active_slot=" .. tostring(menu.get("april_cfg_slot") or 1),
    }
    local f = io.open(M.get_config_path(META_FILE), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load_meta()
    local f = io.open(M.get_config_path(META_FILE), "r")
    if not f or not menu or not menu.set then return false end

    for line in f:lines() do
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "autoload" then
            menu.set("april_cfg_autoload", val == "true")
        elseif key == "autoload_slot" then
            menu.set("april_cfg_autoload_slot", tonumber(val) or 1)
        elseif key == "autoload_profile" then
            menu.set("april_cfg_autoload_profile", val or "")
        elseif key == "active_slot" then
            menu.set("april_cfg_slot", tonumber(val) or 1)
        end
    end

    f:close()
    April.require("core.settings").invalidate()
    return true
end

function M.try_autoload()
    M.load_meta()
    if not menu or not menu.get then return false end

    local autoload = menu.get("april_cfg_autoload")
    if autoload ~= true and autoload ~= 1 then return false end

    local profile = menu.get("april_cfg_autoload_profile")
    local slot

    if type(profile) == "string" and profile:gsub("%s", "") ~= "" then
        slot = M.find_slot_by_profile_name(profile)
    end

    if not slot then
        slot = math.floor(tonumber(menu.get("april_cfg_autoload_slot")) or 1)
    end

    if slot < M.SLOT_MIN then slot = M.SLOT_MIN end
    if slot > M.SLOT_MAX then slot = M.SLOT_MAX end

    if not M.slot_exists(slot) then
        return false
    end

    if M.load_slot(slot, { silent = true }) then
        return true
    end
    return false
end

return M

end)()

-- ── game/module_scan.lua ──
April._mods["game.module_scan"] = (function()
local M = {}

M._table_cache = nil
M._cache_at = 0
M._cache_ttl = 30000

function M.has_gc()
    return type(getgc) == "function"
end

function M.uses_fallen_weapon_gc()
    return type(refreshgc) == "function" and type(applygc) == "function"
end

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function add_tables(from, out, seen)
    if type(from) ~= "table" then return end
    for _, v in pairs(from) do
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(out, v)
        end
    end
end

function M.invalidate_cache()
    M._table_cache = nil
    M._cache_at = 0
end

function M.collect_tables(force)
    local now = tick_ms()
    if not force and M._table_cache and now - M._cache_at < M._cache_ttl then
        return M._table_cache
    end

    local list = {}
    local seen = {}

    local function add(v)
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(list, v)
        end
    end

    if type(filtergc) == "function" then
        local ok = pcall(function()
            filtergc("table", true, function(v)
                add(v)
                return false
            end)
        end)
        if ok and #list > 0 then
            M._table_cache = list
            M._cache_at = now
            return list
        end
        list = {}
        seen = {}
    end

    if M.has_gc() and not M.uses_fallen_weapon_gc() then
        local ok, all = pcall(getgc, true)
        if ok and type(all) == "table" then
            for _, v in ipairs(all) do add(v) end
        end
    end

    if package and type(package.loaded) == "table" then
        add_tables(package.loaded, list, seen)
    end
    if type(shared) == "table" then
        add_tables(shared, list, seen)
    end

    M._table_cache = list
    M._cache_at = now
    return list
end

function M.each_table(fn, force)
    local list = M.collect_tables(force)
    for i = 1, #list do
        fn(list[i])
    end
end

function M.find_toolinfo()
    local best, best_n = nil, 0
    M.each_table(function(v)
        local n = 0
        for k, entry in pairs(v) do
            if type(k) == "string" and type(entry) == "table" then
                if entry.Recoil or entry.Bullet or entry.Weapon or entry.Spread then
                    n = n + 1
                end
            end
        end
        if n > best_n and n >= 3 then
            best_n = n
            best = v
        end
    end)
    return best, best_n
end

function M.find_items()
    local best, best_n = nil, 0
    M.each_table(function(v)
        local n = 0
        if type(v[1]) == "table" and v[1].Name and v[1].Image then
            for i = 1, #v do
                local entry = v[i]
                if type(entry) == "table" and entry.Name and entry.Image then
                    n = n + 1
                end
            end
        else
            for _, entry in pairs(v) do
                if type(entry) == "table" and entry.Name and entry.Image then
                    n = n + 1
                end
            end
        end
        if n > best_n and n >= 100 then
            best_n = n
            best = v
        end
    end)
    return best, best_n
end

return M

end)()

-- ── game/bootstrap.lua ──
April._mods["game.bootstrap"] = (function()
local env = April.require("core.env")
local debug = April.require("core.debug")
local module_scan = April.require("game.module_scan")

local M = {}

M._toolinfo = nil
M._ready = false
M._attempts = 0
M._last_try = 0
M._try_interval = 5000
M._logged_ready = false
M._scan_after = 0
M._defer_ms = 2500

local function in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

local function try_load_toolinfo()
    local data, n = module_scan.find_toolinfo()
    if data then
        M._toolinfo = data
        M._ready = true
        return true, n or 0
    end
    return false, 0
end

function M.get_module(name)
    if name == "ToolInfo" then
        return M._toolinfo
    end
    return nil
end

function M.is_ready()
    return M._ready
end

local function on_toolinfo_ready(count)
    if M._logged_ready then return end
    M._logged_ready = true
    if April and April.debug then
        debug.log(string.format("ToolInfo ready (%d weapons)", count or 0))
    end

    local weapons = April.require("game.weapons")
    if weapons.on_modules_ready then
        weapons.on_modules_ready()
    else
        weapons.load()
    end

    local items = April.require("game.items")
    items.load()
end

function M.try_load_all()
    if M._ready then return true end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0

    if not in_game_ready() then
        M._scan_after = 0
        return false
    end

    if M._scan_after == 0 then
        M._scan_after = now + M._defer_ms
    end
    if now < M._scan_after then
        return false
    end

    if M._attempts > 0 and now - M._last_try < M._try_interval then
        return false
    end
    M._last_try = now
    M._attempts = M._attempts + 1

    local ok, count = try_load_toolinfo()
    if ok then
        on_toolinfo_ready(count)
    end

    return M._ready
end

function M.get_status()
    if M._ready then
        return "ToolInfo+scan"
    end
    return "ToolInfo-wait"
end

function M.force_reload()
    M._toolinfo = nil
    M._ready = false
    M._last_try = 0
    M._attempts = 0
    M._logged_ready = false
    M._scan_after = 0
    module_scan.invalidate_cache()
    April.require("game.weapons").invalidate()
    April.require("game.items").invalidate()
    return M.try_load_all()
end

function M.tick()
    if not M._ready then
        M.try_load_all()
    end
end

function M.start_background_retry()

end

return M

end)()

-- ── game/folders.lua ──
April._mods["game.folders"] = (function()
local env = April.require("core.env")

local M = {}

M.PATHS = {
    drops = { "Drops" },
    bases = { "Bases" },
    animals = { "Animals" },
    plants = { "Plants" },
    vegetation = { "Vegetation" },
    military = { "Military" },
    events = { "Events" },
    monuments = { "Monuments" },
    nodes = { "Nodes" },
    loners = { "Bases", "Loners" },
}

function M.get_folder(...)
    local ws = env.get_workspace()
    if not ws then return nil end
    local cur = ws
    for _, name in ipairs({ ... }) do
        if not cur then return nil end
        cur = env.safe_call(function()
            return cur:find_first_child(name)
                or cur:FindFirstChild(name)
        end)
        if not env.is_valid(cur) then return nil end
    end
    return cur
end

function M.from_key(key)
    local path = M.PATHS[key]
    if not path then return nil end
    return M.get_folder(unpack(path))
end

function M.scan_children(folder, class_filter, max_count)
    local out = {}
    if not env.is_valid(folder) then return out end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, child in ipairs(children) do
        if #out >= (max_count or 500) then break end
        if env.is_valid(child) then
            if not class_filter or child.ClassName == class_filter or env.safe_call(function() return child:is_a(class_filter) end) then
                table.insert(out, child)
            end
        end
    end
    return out
end

function M.scan_descendants(folder, name_filters, max_count)
    local out = {}
    if not env.is_valid(folder) then return out end
    local desc = env.safe_call(function() return folder:get_descendants() end) or {}
    for _, inst in ipairs(desc) do
        if #out >= (max_count or 800) then break end
        if env.is_valid(inst) then
            local n = inst.Name or ""
            for _, pattern in ipairs(name_filters or {}) do
                if n:find(pattern, 1, true) then
                    table.insert(out, inst)
                    break
                end
            end
        end
    end
    return out
end

function M.iter_workspace_folders(keys, fn, max_per)
    for _, key in ipairs(keys) do
        local path = M.PATHS[key]
        if path then
            local folder = M.get_folder(unpack(path))
            if folder then fn(key, folder, max_per) end
        end
    end
end

return M

end)()

-- ── game/item_images.lua ──
April._mods["game.item_images"] = (function()
-- AUTO-GENERATED by scripts/sync-assets.mjs - do not edit by hand
-- Sources: Items module Image + SkinsModule (inventory icons only)

local M = {}

M.by_name = {
    ["Balaclava"] = { default = "14654791788", variants = { ["Default"] = "14654791788", ["Jester"] = "15344534842", ["Frankenstein"] = "15883389666", ["Independence"] = "18341880885", ["Digital"] = "18965910197", ["Jolly"] = "129387971218495", ["Skull"] = "139941774966045", ["Monkey"] = "74568523494874", ["Crimson Bunny"] = "16912319678", } },
    ["Base Cabinet"] = { default = "14653876852", variants = { ["Default"] = "14653876852", ["Server"] = "109131187101243", ["Winter Wrap"] = "79186461116233", } },
    ["Baseball Cap"] = { default = "14654795325", variants = { ["Default"] = "14654795325", ["Quack"] = "16208669800", ["Independence"] = "18341880766", ["Propeller"] = "115535550124192", ["Pilgrim"] = "132977576727336", } },
    ["Bed"] = { default = "15368539842", variants = { ["Default"] = "15368539842", ["Pixel"] = "125567129432156", } },
    ["Blast Furnace"] = { default = "15876671239", variants = { ["Default"] = "15876671239", ["Robot"] = "18149216269", ["Steampunk"] = "113856439034974", } },
    ["Bone Armor"] = { default = "119847143620647", variants = { ["Default"] = "119847143620647", } },
    ["Bone Tool"] = { default = "15510368323", variants = { ["Default"] = "15510368323", } },
    ["Boots"] = { default = "14654795457", variants = { ["Default"] = "14654795457", ["Black"] = "15283152697", ["Abibas"] = "15305690697", ["Valentine"] = "16293022275", ["Woodland"] = "16473066174", ["Correctional"] = "92577755087375", ["Nutcracker"] = "102533866187536", ["Brutus"] = "124559624944530", ["Tundra"] = "75185734630840", ["Pilot"] = "134265072222654", ["Medal"] = "107412050354842", ["Forest Camo"] = "15283152517", ["Hot Rod"] = "17768833072", ["Elite Bunny"] = "98142715632310", } },
    ["Boss Chestplate"] = { default = "16652581317", variants = { ["Default"] = "16652581317", ["Cryo"] = "106187507956822", ["Boris"] = "18354053691", ["Brutus"] = "120699966211693", ["Boris Abibas"] = "137740231154465", ["Bruno Tundra"] = "92200143576210", } },
    ["Boss Helmet"] = { default = "16652579167", variants = { ["Default"] = "16652579167", ["Cryo"] = "102872157681930", ["Boris"] = "18312187080", ["Brutus"] = "134265072222654", ["Boris Sky"] = "140423012958795", ["Boris Carbon"] = "106169002653059", ["Boris Abibas"] = "18450404634", ["Bruno Tundra"] = "106377950808399", } },
    ["Boulder"] = { default = "15304806846", variants = { ["Default"] = "15304806846", ["Bubblegum"] = "15304805303", ["Frosty"] = "15304805239", ["Tester"] = "15304805180", ["Voxel"] = "15574223076", ["Wrapped"] = "15712360641", ["Pixskull"] = "17766619061", ["Stellark"] = "97313343547804", ["Cursed"] = "92913832321996", ["Sushi"] = "78426403974796", ["Chocolate"] = "139716602333201", ["Moai"] = "115978938918724", ["Ducky"] = "124674000707337", ["Pumpkin"] = "126349162347833", ["Mosaic"] = "74510585736689", ["ERROR 404"] = "16031055626", ["Jack-O-Lantern"] = "86358241058177", ["Fish Tank"] = "15792001129", } },
    ["Bruno's M4A1"] = { default = "15574295393", variants = { ["Default"] = "15574295393", } },
    ["Bunny Ears"] = { default = "16916795577", variants = { ["Default"] = "16916795577", } },
    ["Campfire"] = { default = "15128008159", variants = { ["Default"] = "15128008159", ["Skulls"] = "133107732568884", } },
    ["Candy Cane"] = { default = "15633196493", variants = { ["Default"] = "15633196493", } },
    ["Carrot Blade"] = { default = "16916703095", variants = { ["Default"] = "16916703095", } },
    ["Chainsaw"] = { default = "17201657737", variants = { ["Default"] = "17201657737", ["Recycle"] = "17357130465", } },
    ["Christmas Lights"] = { default = "134491722995587", variants = { ["Default"] = "134491722995587", } },
    ["Christmas Tree"] = { default = "15634564093", variants = { ["Default"] = "15634564093", } },
    ["Cloth Footwraps"] = { default = "14654794730", variants = { ["Default"] = "14654794730", ["Ninja"] = "132892877448790", } },
    ["Cloth Handwraps"] = { default = "14654831164", variants = { ["Default"] = "14654831164", ["Ninja"] = "114878511497747", } },
    ["Cloth Headwrap"] = { default = "14654795058", variants = { ["Default"] = "14654795058", ["Ninja"] = "120080222783269", } },
    ["Cloth Pants"] = { default = "14654794952", variants = { ["Default"] = "14654794952", ["Ninja"] = "88014133756226", } },
    ["Cloth Shirt"] = { default = "14654794835", variants = { ["Default"] = "14654794835", ["Ninja"] = "107568365412229", } },
    ["Collared Shirt"] = { default = "14654793432", variants = { ["Default"] = "14654793432", ["Business"] = "15444462393", ["Correctional"] = "140110401401547", ["Flannel"] = "97292443788852", } },
    ["Cooking Pot"] = { default = "15127562373", variants = { ["Default"] = "15127562373", } },
    ["Crossbow"] = { default = "15305596532", variants = { ["Default"] = "15305596532", ["Crossbones"] = "15305756728", ["HotDog"] = "15877969435", ["Emerald"] = "16751858634", ["Rose"] = "80803215254174", ["Toy"] = "102956782968040", ["Chief"] = "137062431435688", ["Candy Whale"] = "16114353256", } },
    ["Crude Fuel Generator"] = { default = "117457710807147", variants = { ["Default"] = "117457710807147", } },
    ["Electric Furnace"] = { default = "71536889851799", variants = { ["Default"] = "71536889851799", ["ICBM"] = "115876027631434", } },
    ["Electric Heater"] = { default = "117015755787407", variants = { ["Default"] = "117015755787407", } },
    ["Fireplace"] = { default = "134438626724268", variants = { ["Default"] = "134438626724268", } },
    ["Flannel Jacket"] = { default = "14654794281", variants = { ["Default"] = "14654794281", ["Biker"] = "15877516070", ["Correctional"] = "100006176575349", ["Abibas"] = "138547747231782", ["Snow White"] = "15283151729", } },
    ["Furnace"] = { default = "15074084708", variants = { ["Default"] = "15074084708", ["Banana"] = "15344532656", ["Glyphs"] = "15630767150", ["Gorilla"] = "16484587298", ["Burger"] = "84948985557474", ["Penguin"] = "122396159441498", ["Pumpkin"] = "81542845446759", ["Chinese New Year"] = "137256732968955", ["Sweet Gingerbread"] = "15622165066", ["Blue Steel"] = "18761542136", ["Winter Wrap"] = "82920100728899", } },
    ["Garage Door"] = { default = "16574547137", variants = { ["Default"] = "16574547137", ["Blob"] = "15509791543", ["Cryo"] = "113706556350765", ["Witch"] = "85491019952546", ["King Raid"] = "15344456682", ["Surprise Meow"] = "16574535811", ["King of the street"] = "17193053474", ["Grand Prix"] = "88541547537698", } },
    ["Hammer"] = { default = "15318044673", variants = { ["Default"] = "15318044673", ["Toy"] = "15509809013", ["ERROR 404"] = "15305728235", ["Building Blocks"] = "15953856112", } },
    ["Hard Hat"] = { default = "14654794545", variants = { ["Default"] = "14654794545", ["Slurpee"] = "15950562586", } },
    ["Hazmat Suit"] = { default = "15046441717", variants = { ["Default"] = "15046441717", ["Snowman"] = "15712521421", ["Spark"] = "18965466357", ["Stellark"] = "123693400858947", ["Classified"] = "78801273340050", ["Front"] = "109185322610878", ["Guard"] = "113617571174399", ["Ducky"] = "116234383398695", ["Ghoul"] = "102977931837887", ["Specialist"] = "99406105774604", ["Blue Fissure"] = "16822398564", ["Digital Red"] = "17366071573", ["Digital Camo"] = "106956792584318", } },
    ["Hoodie"] = { default = "14654794392", variants = { ["Default"] = "14654794392", ["Boris"] = "18312277063", ["Red"] = "15283152304", ["Purple"] = "15283152380", ["Green"] = "15283152598", ["Abibas"] = "15305689057", ["Wool"] = "15877516276", ["Valentine"] = "16293021303", ["Woodland"] = "16448119412", ["Tyrant"] = "130901964742021", ["Nutcracker"] = "72418266986929", ["Puffer"] = "71855339887230", ["Brutus"] = "116605401922894", ["Tundra"] = "94852483691948", ["Pilot"] = "134265072222654", ["Player"] = "72323540553042", ["Bee"] = "106663686372311", ["Night"] = "104718096945503", ["Forest Camo"] = "15283152783", ["Hot Rod"] = "17768833509", ["Elite Bunny"] = "77892644977802", } },
    ["Iron Shard Hatchet"] = { default = "15073617640", variants = { ["Default"] = "15073617640", ["Fade"] = "16663953399", ["Sawblade"] = "18963884209", ["Leather"] = "82373698320243", } },
    ["Iron Shard Pickaxe"] = { default = "15073617491", variants = { ["Default"] = "15073617491", ["Fade"] = "16663949312", ["Leather"] = "99659875069484", } },
    ["Jukebox"] = { default = "17343466496", variants = { ["Default"] = "17343466496", } },
    ["Ladder"] = { default = "15127607098", variants = { ["Default"] = "15127607098", } },
    ["Large Battery"] = { default = "78253036378845", variants = { ["Default"] = "78253036378845", } },
    ["Large Furnace"] = { default = "15133678858", variants = { ["Default"] = "15133678858", } },
    ["Large Storage Box"] = { default = "15094083403", variants = { ["Default"] = "15094083403", ["Canvas"] = "15283200485", ["Festive"] = "15709683124", ["Forged"] = "17758887216", ["Coffin"] = "112688458744179", ["Ouja"] = "102172335761498", ["Egg Sketch"] = "16916931642", ["Game Buddy"] = "139299560912717", ["Industrial Guns"] = "15305708083", ["Industrial Resources"] = "15305708823", ["Industrial Medical"] = "15305709566", ["Industrial Components"] = "15305710817", ["Industrial Armor"] = "15305711681", } },
    ["Leather Boots"] = { default = "14654794176", variants = { ["Default"] = "14654794176", ["Correctional"] = "95515905374532", } },
    ["Leather Gloves"] = { default = "14654794097", variants = { ["Default"] = "14654794097", ["Correctional"] = "92980178755471", ["Noir"] = "107804982630320", } },
    ["Leather Pants"] = { default = "14654793993", variants = { ["Default"] = "14654793993", ["Correctional"] = "108412621160578", } },
    ["Leather Poncho"] = { default = "14654793821", variants = { ["Default"] = "14654793821", ["Viva"] = "16208668209", ["Pilgrim"] = "98358561085174", } },
    ["Leather Shirt"] = { default = "14654793568", variants = { ["Default"] = "14654793568", ["Correctional"] = "109168692318343", } },
    ["Lighter"] = { default = "15128007580", variants = { ["Default"] = "15128007580", ["Lantern"] = "123377357974589", } },
    ["Machete"] = { default = "16249771824", variants = { ["Default"] = "16249771824", ["Rainbow"] = "16823202004", ["Crimson"] = "16912320468", ["Foam"] = "18761536955", ["Oni"] = "84793810931259", } },
    ["Medium Battery"] = { default = "129552454538184", variants = { ["Default"] = "129552454538184", } },
    ["Metal Door"] = { default = "15132832907", variants = { ["Default"] = "15132832907", ["Pixel"] = "15310965325", ["Frosty"] = "15304875360", ["Independence"] = "18341881259", ["Comic"] = "18444379748", ["Industrial"] = "78073516430678", ["Demon"] = "137869636615146", ["Bayou"] = "88981731583061", ["PLZ NO RAID"] = "15310983705", ["Angry Bunny"] = "16924356510", ["Elite Bunny"] = "77825470317254", } },
    ["Metal Double Door"] = { default = "15132833297", variants = { ["Default"] = "15132833297", ["Pixel"] = "15310966370", ["Tropical"] = "16483738322", ["Nightwave"] = "119789304012674", ["Hells Gate"] = "90897641914339", } },
    ["Military AA12"] = { default = "15068791139", variants = { ["Default"] = "15068791139", ["Zombie"] = "17199281354", ["Monster"] = "136853604493538", ["Red Tiger"] = "16485447561", } },
    ["Military Backpack"] = { default = "117242081838466", variants = { ["Default"] = "117242081838466", ["Tundra"] = "98126095773472", ["Abibas"] = "82640089227507", ["Digital Red"] = "113943759309035", } },
    ["Military Barrett"] = { default = "15346280030", variants = { ["Default"] = "15346280030", ["Surge"] = "15876918136", ["Leprechaun"] = "16751857511", ["Mystra"] = "98792148092190", ["Fade"] = "73907766386158", ["Molten"] = "103075738835660", ["Cryo"] = "124741300378620", } },
    ["Military Chestplate"] = { default = "14654793303", variants = { ["Default"] = "14654793303", ["Nutcracker"] = "70853333750344", ["Pilot"] = "134265072222654", ["Medal"] = "81188910996008", } },
    ["Military Gloves"] = { default = "14654794652", variants = { ["Default"] = "14654794652", ["Nutcracker"] = "118158228480821", ["Arctic"] = "76148467345468", ["Pilot"] = "134265072222654", ["Grim"] = "123472167772965", ["Medal"] = "137375914230135", } },
    ["Military Grenade Launcher"] = { default = "136030704871223", variants = { ["Default"] = "136030704871223", } },
    ["Military Helmet"] = { default = "14654793165", variants = { ["Default"] = "14654793165", ["Nutcracker"] = "80633563389909", ["Pilot"] = "134265072222654", ["Medal"] = "108938282129584", } },
    ["Military Leggings"] = { default = "14654792938", variants = { ["Default"] = "14654792938", ["Nutcracker"] = "84566720271674", ["Brutus"] = "75512320758936", ["Tundra"] = "86308809791688", ["Cryo"] = "88056077715569", ["Medal"] = "136956516639652", } },
    ["Military M39"] = { default = "74435081612082", variants = { ["Default"] = "74435081612082", ["Medusa"] = "117342321001432", ["Turkey"] = "111197339750272", } },
    ["Military M4A1"] = { default = "15346201415", variants = { ["Default"] = "15346201415", ["Syntax"] = "15951831122", ["Monster"] = "16663261126", ["Toy"] = "17521734560", ["Independence"] = "18341881006", ["Phantom"] = "139190777075295", ["Nutcracker"] = "136729540441664", ["Medusa"] = "101267874762837", ["Cryo"] = "94745687589547", ["CyberPop"] = "101893225757265", ["Spring Lily"] = "117935810694220", ["Cherry Blossom"] = "15509842541", } },
    ["Military MP7"] = { default = "17607841424", variants = { ["Default"] = "17607841424", ["Fade"] = "18764670728", ["Whiteout"] = "112724849582854", ["Tyrant"] = "88901653074832", ["Wave"] = "108003941053496", ["Animeaster"] = "137259300477168", ["Solitare"] = "128296099845816", ["Grunge"] = "96361565266502", ["Zap"] = "126949129741030", ["Dark Matter"] = "17768541905", ["Digital Tiger"] = "109024303396384", ["Pink Plasm"] = "74447782460391", } },
    ["Military PKM"] = { default = "16471125314", variants = { ["Default"] = "16471125314", ["Woodland"] = "16471122135", ["Resistance"] = "18149212335", ["Turbo"] = "18950918343", ["Digital Red"] = "16828755578", ["Anime Sketch"] = "90293792623916", ["Anime Waifu"] = "102634442832437", } },
    ["Military USP"] = { default = "85577075764668", variants = { ["Default"] = "85577075764668", ["Fade"] = "89094430760827", ["Azure"] = "74032961902891", ["Bright Water"] = "110809910409468", ["Crimson Scale"] = "85217509353028", ["Cherry Blossom"] = "133722249630533", } },
    ["Mining Drill"] = { default = "17287978593", variants = { ["Default"] = "17287978593", ["Recycle"] = "17357129069", ["Brick"] = "111424776562874", } },
    ["Nail Gun"] = { default = "15305104734", variants = { ["Default"] = "15305104734", ["Striker"] = "15305729695", ["Magma"] = "15946260536", ["Wintrane"] = "114731373088561", } },
    ["Pants"] = { default = "14654792590", variants = { ["Default"] = "14654792590", ["Boris"] = "18312279038", ["Khaki"] = "15283151856", ["Abibas"] = "15305689962", ["Valentine"] = "16293019822", ["Woodland"] = "16448121262", ["Correctional"] = "135793344308303", ["Tyrant"] = "136885851029799", ["Nutcracker"] = "71901466636387", ["Brutus"] = "85540429494017", ["Tundra"] = "90847059484754", ["Pilot"] = "134265072222654", ["Player"] = "129572575838612", ["Bee"] = "136553486453775", ["Forest Camo"] = "15283152437", ["Hot Rod"] = "17768833305", ["Elite Bunny"] = "89074393808133", } },
    ["Petroleum Refinery"] = { default = "15304104065", variants = { ["Default"] = "15304104065", } },
    ["Repair Table"] = { default = "15283452092", variants = { ["Default"] = "15283452092", } },
    ["Rug"] = { default = "17205250687", variants = { ["Default"] = "17205250687", ["Kraken"] = "17518134457", ["Independence"] = "18341881393", ["Chinese Dragon"] = "71202563952285", ["Christmas Knit"] = "90714037219162", ["Jolly Rogers"] = "104276123436561", } },
    ["Salvaged AK47"] = { default = "14882620172", variants = { ["Default"] = "14882620172", ["Frosty"] = "15304886302", ["Vaporwave"] = "15574230457", ["Diablo"] = "16021791118", ["Fade"] = "79444477121964", ["Tyrant"] = "124312637758997", ["Gingerbread"] = "85687142665622", ["Ghillie"] = "132083989873001", ["Anodized"] = "80710562596890", ["CyberPop"] = "128785004285267", ["Oni"] = "105854184847862", ["Medal"] = "102460072725837", ["Dune"] = "83484244695308", ["Anodized Blue"] = "15792000837", ["Anodized Red"] = "15291340361", ["North Pole"] = "105407359855835", ["Cyber Hunter"] = "17199281165", ["Gold Sky"] = "106035094504671", ["Blue Gem"] = "16577230239", ["Phantom Rider"] = "85810076023854", ["Hot Rod"] = "17768697376", ["Red Relic"] = "132874855148397", } },
    ["Salvaged AK74u"] = { default = "15073408197", variants = { ["Default"] = "15073408197", ["Beast"] = "15305755800", ["Splash"] = "15509741616", ["VIP"] = "16014753591", ["Comic"] = "16114228051", ["Clover"] = "16748171046", ["Nebula"] = "17518135139", ["Tundra"] = "114982197234346", ["MP5"] = "78960618674854", ["Flarette"] = "125113179502352", ["Zombie"] = "101630769388124", ["Pink Ripple"] = "122346171773813", ["Black Ice"] = "128242163135902", ["Phantom Rider"] = "140329577619010", ["Stellark Dragon"] = "116297510128388", } },
    ["Salvaged Backpack"] = { default = "80978101846806", variants = { ["Default"] = "80978101846806", ["Ducky"] = "84777906931514", ["Elite Bunny"] = "130786989208457", } },
    ["Salvaged Break Action"] = { default = "15305085935", variants = { ["Default"] = "15305085935", ["Splat"] = "15305729191", ["HotDog"] = "15632163269", ["Boom"] = "16823202171", ["Carrot"] = "16917852163", ["Surf"] = "17766587211", ["Easter Wood"] = "16917852163", } },
    ["Salvaged Chestplate"] = { default = "14654792418", variants = { ["Default"] = "14654792418", ["Cupid"] = "16261611092", ["Burnout"] = "18557168052", ["Tempest"] = "18966646034", ["Digital Snow"] = "15283152111", ["Elite Bunny"] = "71496524358663", } },
    ["Salvaged Double Barrel"] = { default = "132642766917853", variants = { ["Default"] = "132642766917853", ["Ducky"] = "140296796147704", ["HotDog"] = "86842880761011", } },
    ["Salvaged Gloves"] = { default = "14654792260", variants = { ["Default"] = "14654792260", ["Cupid"] = "16261613114", ["Tempest"] = "18971460487", ["Digital Snow"] = "15283152030", } },
    ["Salvaged Grenade Launcher"] = { default = "122319440938090", variants = { ["Default"] = "122319440938090", } },
    ["Salvaged Helmet"] = { default = "14654792150", variants = { ["Default"] = "14654792150", ["Cupid"] = "16261611838", ["Tempest"] = "18966646232", ["Cardboard"] = "71323845635099", ["Kill to Survive"] = "15792001031", ["Digital Snow"] = "15283152199", ["Elite Bunny"] = "119864001362604", } },
    ["Salvaged Leggings"] = { default = "14654792046", variants = { ["Default"] = "14654792046", ["Cupid"] = "16261614321", ["Tempest"] = "18966645952", ["Digital Snow"] = "15283153195", ["Elite Bunny"] = "99275929303588", } },
    ["Salvaged M14"] = { default = "14882876522", variants = { ["Default"] = "14882876522", ["Paintball"] = "15305730875", ["Splat"] = "16031054728", ["Arcane"] = "17507702118", ["Stellark"] = "77123726699368", ["Huntsman"] = "121372881282577", ["Glitch"] = "82715807510122", ["Frog14"] = "133627766691157", ["Jingle Bell"] = "78927394340869", ["Candy Dragon"] = "15346320769", ["High Tide"] = "16483734949", ["Anime Bloss"] = "91134373735199", } },
    ["Salvaged Metal Door"] = { default = "15132658803", variants = { ["Default"] = "15132658803", ["Visions"] = "15444463543", ["Graffiti"] = "16664082484", } },
    ["Salvaged P250"] = { default = "15305065991", variants = { ["Default"] = "15305065991", ["Splat"] = "15305728596", ["Fade"] = "15631601051", ["Peppermint"] = "15712513595", ["Sketch"] = "16208668754", ["Tempest"] = "18966645823", ["Festive"] = "101842524476750", ["Drift"] = "94234232543243", ["Egg Sketch"] = "16916693041", ["Blue Gem"] = "18149208414", ["Blue Terror"] = "17366305322", ["Elite Bunny"] = "138989649466976", } },
    ["Salvaged Pipe Rifle"] = { default = "15073408081", variants = { ["Default"] = "15073408081", ["Surge"] = "15509721163", ["Gingerbread"] = "15638252851", ["Frost"] = "16208668377", ["Skyline"] = "18557168359", } },
    ["Salvaged Pump Action"] = { default = "15092313032", variants = { ["Default"] = "15092313032", ["Cyber"] = "91058444899439", ["Flurry"] = "138789905852084", ["Gold Ripple"] = "15444464740", ["Red Tiger"] = "15792000933", ["Joe Skeleton"] = "16828401186", } },
    ["Salvaged Python"] = { default = "15188995729", variants = { ["Default"] = "15188995729", ["Canvas"] = "15283200809", ["Hazard"] = "15305731383", ["Saku"] = "16029067988", ["Inferno"] = "16283806768", ["Shockwave"] = "17366304773", ["Independence"] = "18341881121", ["Stellark"] = "124497972716738", ["Hyper"] = "85697748071844", ["Smudge"] = "76952866923184", ["Medal"] = "128419932789140", ["Blue Prey"] = "15574225312", ["Pink Canvas"] = "16663261806", ["Crimson Glitched"] = "16912320052", ["Black Ice"] = "138482014642051", } },
    ["Salvaged RPG"] = { default = "15132772506", variants = { ["Default"] = "15132772506", ["Blast"] = "15305772236", ["Boomstick"] = "18965877488", ["Festive"] = "81287503464820", } },
    ["Salvaged SMG"] = { default = "15132874040", variants = { ["Default"] = "15132874040", ["Splat"] = "15313314715", ["Inferno"] = "15883391466", ["Checkmate"] = "16114277804", ["Valentine"] = "16281529715", ["Knight"] = "17366143384", ["Tempest"] = "18966646387", ["Joker"] = "104734469891887", ["Ducky"] = "119924390182546", ["Fire and Ice"] = "15312330570", ["Red Urban"] = "15574233065", ["Evil Easter"] = "16916946492", ["Digital Candy"] = "18557168240", ["Game Buddy"] = "75480260862201", ["Black Ice"] = "109856083708178", ["Elite Bunny"] = "138479957487119", } },
    ["Salvaged Shotgun"] = { default = "128621428767531", variants = { ["Default"] = "128621428767531", ["Banana"] = "90420924851404", ["HotDog"] = "94732589170018", ["Camo"] = "85391407055752", } },
    ["Salvaged Skorpion"] = { default = "15369212859", variants = { ["Default"] = "15369212859", ["Gingerbread"] = "15637191692", ["Superior"] = "15950161435", ["Pegasus"] = "16577230942", ["Surge"] = "18149214997", ["Rusty"] = "87710451691684", ["Comic"] = "103323135308928", ["Celestial"] = "102882157920367", ["Cyber Revenge"] = "112592127248445", } },
    ["Salvaged Sniper"] = { default = "74470836610605", variants = { ["Default"] = "74470836610605", ["Valentine"] = "134067753909583", ["Radioactive"] = "128500957974672", } },
    ["Santa Hat"] = { default = "15636087096", variants = { ["Default"] = "15636087096", } },
    ["Shop Machine"] = { default = "16769451135", variants = { ["Default"] = "16769451135", } },
    ["Shorts"] = { default = "14654791921", variants = { ["Default"] = "14654791921", ["Beach Day"] = "106157418298863", } },
    ["Sleeping Bag"] = { default = "15313154200", variants = { ["Default"] = "15313154200", ["Prismatic"] = "15574227229", ["Santa"] = "15715978392", ["Shark"] = "16117442613", ["Voxel"] = "18147427074", ["Spooky"] = "85015559308510", ["Fruit"] = "81952434018281", ["UwU"] = "96904970768142", ["Chocolate"] = "108416357231982", ["Cucumber John"] = "15313175563", ["Big Pillow"] = "128662593449303", } },
    ["Small Battery"] = { default = "88959343384498", variants = { ["Default"] = "88959343384498", } },
    ["Small Storage Box"] = { default = "15094083341", variants = { ["Default"] = "15094083341", ["Monster"] = "15883290696", ["Comic"] = "16577230729", ["Gremlin"] = "16748563435", ["Burger"] = "95806776502625", ["Medical"] = "97915388339168", } },
    ["Solar Panel"] = { default = "81539973869850", variants = { ["Default"] = "81539973869850", } },
    ["Steel Axe"] = { default = "13206734202", variants = { ["Default"] = "13206734202", ["Ruby"] = "15444465626", ["Freeze"] = "15712516834", ["Lava"] = "81357829552245", ["Fire Axe"] = "17199281023", } },
    ["Steel Chestplate"] = { default = "14654791689", variants = { ["Default"] = "14654791689", ["Frosty"] = "15305683641", ["OBEY"] = "15305695517", ["Woodland"] = "16447572145", ["Tyrant"] = "140168023066476", ["Oni"] = "126974041982300", ["Dune"] = "105836010915280", ["OH Deer"] = "15630407338", ["Hot Rod"] = "17768833992", ["Phantom Rider"] = "116301304304192", } },
    ["Steel Door"] = { default = "15132554218", variants = { ["Default"] = "15132554218", ["Galactic"] = "16483736587", ["Tyrant"] = "90255972475887", ["Duck"] = "132207599970757", ["Christmas Tree"] = "15638295051", } },
    ["Steel Double Door"] = { default = "15132553963", variants = { ["Default"] = "15132553963", ["Vaporwave"] = "17199280862", ["Red Lotus"] = "130069862861998", ["Elven Gate"] = "95946321412209", } },
    ["Steel Helmet"] = { default = "14654791532", variants = { ["Default"] = "14654791532", ["Golden"] = "15305714913", ["Frosty"] = "15305683226", ["OBEY"] = "15305695029", ["VIP"] = "16014684244", ["Cardboard"] = "15627624994", ["Woodland"] = "16447574211", ["Tyrant"] = "109539796004549", ["Bomo"] = "80249585885084", ["Hockey"] = "97015125505963", ["Fear"] = "81724456402833", ["Oni"] = "114978122703010", ["Dune"] = "72849082443137", ["OH Deer"] = "15630406001", ["Hot Rod"] = "17768832901", ["Phantom Rider"] = "122478227429676", } },
    ["Steel Leggings"] = { default = "14654791387", variants = { ["Default"] = "14654791387", ["Frosty"] = "15305684250", ["OBEY"] = "15311675719", ["Woodland"] = "16447575529", ["Tyrant"] = "79519920346999", ["Oni"] = "98478307520733", ["Dune"] = "76898574981463", ["OH Deer"] = "15630408363", ["Hot Rod"] = "17768833765", ["Phantom Rider"] = "85294785312442", } },
    ["Steel Pickaxe"] = { default = "13206733920", variants = { ["Default"] = "13206733920", ["Cross"] = "15444466662", ["Freeze"] = "15712518908", ["Molten"] = "18762535576", ["Ice Pick"] = "17750836356", } },
    ["Steel Shovel"] = { default = "15074351964", variants = { ["Default"] = "15074351964", ["Heart of Spades"] = "113366819252362", } },
    ["Stone Hatchet"] = { default = "15073617325", variants = { ["Default"] = "15073617325", ["Molten"] = "15305732445", ["Shark"] = "16208668072", ["VIP"] = "16014755281", ["Valentine"] = "16281532811", ["Slime"] = "80657230310751", ["Candy Cane"] = "113420518729636", ["Love Trip"] = "106301749629689", } },
    ["Stone Pickaxe"] = { default = "15073617163", variants = { ["Default"] = "15073617163", ["Molten"] = "15305731898", ["VIP"] = "16014754516", ["Valentine"] = "16281531919", ["Love Trip"] = "120075663072035", } },
    ["Storage Cabinet"] = { default = "15572100650", variants = { ["Default"] = "15572100650", ["Monster"] = "15631715604", ["Hades"] = "16293483340", ["Tyrant"] = "125396135034194", ["Server"] = "83936574533516", ["Gift Wrap"] = "118868800240580", ["Winter Wrap"] = "91326939040045", } },
    ["Tank Top"] = { default = "14654791246", variants = { ["Default"] = "14654791246", } },
    ["Trap Door"] = { default = "13143032792", variants = { ["Default"] = "13143032792", } },
    ["Triangle Trap Door"] = { default = "13724822281", variants = { ["Default"] = "13724822281", } },
    ["Water Turbine"] = { default = "118840048689367", variants = { ["Default"] = "118840048689367", } },
    ["Wetsuit"] = { default = "15304093679", variants = { ["Default"] = "15304093679", ["Pink"] = "17363544575", ["Frog"] = "80603678790020", } },
    ["Windmill"] = { default = "84509705966195", variants = { ["Default"] = "84509705966195", } },
    ["Wooden Bow"] = { default = "15313266356", variants = { ["Default"] = "15313266356", ["Cupid"] = "16260403928", ["Crimson"] = "16912320324", ["Dragon"] = "119198626388204", ["Blue Fissure"] = "15313269139", ["Sweet Gingerbread"] = "15623006255", ["Ancient Bone"] = "136557779662161", } },
    ["Wooden Chestplate"] = { default = "14776135830", variants = { ["Default"] = "14776135830", ["Crimson Bunny"] = "16912321117", } },
    ["Wooden Door"] = { default = "15132568626", variants = { ["Default"] = "15132568626", ["Beware"] = "15305026376", ["Chocolate"] = "15712523927", ["Cardboard"] = "132805078818983", ["Pixel"] = "106378082611103", ["Wise"] = "101629446511815", ["Pot of Gold"] = "16748559894", ["Summer Time"] = "18762630774", ["Christmas Tree"] = "111412634443690", } },
    ["Wooden Double Door"] = { default = "15132568988", variants = { ["Default"] = "15132568988", ["Rainbow"] = "15344501592", ["Cherry Blossom"] = "16577230495", ["Barn Doors"] = "17497777892", } },
    ["Wooden Helmet"] = { default = "14776135648", variants = { ["Default"] = "14776135648", ["Crimson Bunny"] = "16912320885", } },
    ["Wooden Leggings"] = { default = "14776135514", variants = { ["Default"] = "14776135514", ["Crimson Bunny"] = "16912320687", } },
    ["Wreath"] = { default = "125156247966096", variants = { ["Default"] = "125156247966096", } },
}

function M.get_asset_id(name, variant)
    local row = name and M.by_name[name]
    if not row then return nil end
    if variant and row.variants and row.variants[variant] then
        return row.variants[variant]
    end
    return row.default
end

return M

end)()

-- ── game/attachment_images.lua ──
April._mods["game.attachment_images"] = (function()
-- MeshId thumbnails from dump: ReplicatedStorage.Attachments (mesh_assets.tsv)
local M = {}

M.by_name = {
    ["Bruno's ACOG Sight"] = "15426865503",
    ["Compensator"] = "15347030703",
    ["Holo Sight"] = "14162017273",
    ["Military ACOG Sight"] = "15426865503",
    ["Military Lasersight"] = "15376726516",
    ["Military Sniper Scope"] = "14764545466",
    ["Muzzle Boost"] = "15347030553",
    ["Salvaged Lasersight"] = "15347030437",
    ["Salvaged Sight"] = "13816428922",
    ["Salvaged Sniper Scope"] = "14623616888",
    ["Silencer"] = "15347030257",
    ["Weapon Flashlight"] = "15360516663",
}

function M.get_asset_id(name)
    return name and M.by_name[name]
end

return M

end)()

-- ── game/item_catalog.lua ──
April._mods["game.item_catalog"] = (function()
local M = {}

M.by_id = {
    [1] = { name = "Wood Log", type = "Resource" },
    [2] = { name = "Bandage", type = "Tool" },
    [3] = { name = "Stone Hatchet", type = "Tool" },
    [4] = { name = "Heavy Ammo", type = "Ammo" },
    [5] = { name = "Salvaged AK47", type = "Gun" },
    [6] = { name = "Bottle Caps", type = "Resource" },
    [7] = { name = "Holo Sight", type = "Attachment" },
    [8] = { name = "Silencer", type = "Attachment" },
    [9] = { name = "Salvaged M14", type = "Gun" },
    [10] = { name = "Lighter", type = "Tool" },
    [11] = { name = "Swift Heavy Ammo", type = "Ammo" },
    [12] = { name = "Salvaged Sight", type = "Attachment" },
    [13] = { name = "Muzzle Boost", type = "Attachment" },
    [14] = { name = "Compensator", type = "Attachment" },
    [15] = { name = "Salvaged Lasersight", type = "Attachment" },
    [16] = { name = "Weapon Flashlight", type = "Attachment" },
    [17] = { name = "Salvaged Sniper Scope", type = "Attachment" },
    [18] = { name = "Military Sniper Scope", type = "Attachment" },
    [19] = { name = "Wooden Spear", type = "Tool" },
    [20] = { name = "Stone Spear", type = "Tool" },
    [21] = { name = "Stone Pickaxe", type = "Tool" },
    [22] = { name = "Crossbow", type = "Gun" },
    [23] = { name = "Wooden Bow", type = "Gun" },
    [24] = { name = "Cloth", type = "Resource" },
    [25] = { name = "Cactus Flesh", type = "Consumable" },
    [26] = { name = "Stone", type = "Resource" },
    [27] = { name = "Iron Ore", type = "Resource" },
    [28] = { name = "Quality Iron Ore", type = "Resource" },
    [29] = { name = "Campfire", type = "Bench" },
    [30] = { name = "Blueprint", type = "Tool" },
    [31] = { name = "Hammer", type = "Tool" },
    [32] = { name = "Raw Pork", type = "Consumable" },
    [33] = { name = "Cooked Pork", type = "Consumable" },
    [34] = { name = "Charcoal", type = "Resource" },
    [35] = { name = "Salvaged P250", type = "Gun" },
    [36] = { name = "Light Ammo", type = "Ammo" },
    [37] = { name = "Boulder", type = "Tool" },
    [38] = { name = "Salvaged SMG", type = "Gun" },
    [39] = { name = "Salvaged Python", type = "Gun" },
    [40] = { name = "Combustive Heavy Ammo", type = "Ammo" },
    [41] = { name = "Animal Fat", type = "Resource" },
    [42] = { name = "Small Storage Box", type = "Bench" },
    [43] = { name = "Raw Venison", type = "Consumable" },
    [44] = { name = "Cooked Venison", type = "Consumable" },
    [45] = { name = "Iron Shards", type = "Resource" },
    [46] = { name = "Steel Metal", type = "Resource" },
    [47] = { name = "Wooden Door", type = "Bench" },
    [48] = { name = "Wooden Lock", type = "Lock" },
    [49] = { name = "Combination Lock", type = "Lock" },
    [50] = { name = "Salvaged Metal Door", type = "Bench" },
    [51] = { name = "Base Cabinet", type = "Bench" },
    [52] = { name = "Wooden Double Door", type = "Bench" },
    [53] = { name = "Wooden Window Bars", type = "Bench" },
    [54] = { name = "Metal Window Bars", type = "Bench" },
    [55] = { name = "Glass Window", type = "Bench" },
    [56] = { name = "Steel Glass Window", type = "Bench" },
    [57] = { name = "Trap Door", type = "Bench" },
    [58] = { name = "Radiation Vitamins", type = "Consumable" },
    [59] = { name = "Hoodie", type = "Armor", armor_type = "Shirt" },
    [60] = { name = "Hazmat Suit", type = "Armor", armor_type = "All", attribute = "ResistWet" },
    [61] = { name = "Chicken MRE", type = "Consumable" },
    [62] = { name = "Beef MRE", type = "Consumable" },
    [63] = { name = "Pants", type = "Armor", armor_type = "Pants" },
    [64] = { name = "Phosphate Ore", type = "Resource" },
    [65] = { name = "Phosphate Dust", type = "Resource" },
    [66] = { name = "Leather", type = "Resource" },
    [67] = { name = "Furnace", type = "Bench" },
    [68] = { name = "Crude Fuel", type = "Resource" },
    [69] = { name = "Gunpowder", type = "Resource" },
    [70] = { name = "Bone Shards", type = "Resource" },
    [71] = { name = "Metal Door", type = "Bench" },
    [72] = { name = "Metal Double Door", type = "Bench" },
    [73] = { name = "Steel Door", type = "Bench" },
    [74] = { name = "Steel Double Door", type = "Bench" },
    [75] = { name = "Nail Gun", type = "Gun" },
    [76] = { name = "Steel Axe", type = "Tool" },
    [77] = { name = "Steel Pickaxe", type = "Tool" },
    [78] = { name = "Power Cell", type = "Misc" },
    [79] = { name = "Copper Cogs", type = "Misc" },
    [80] = { name = "Pipe", type = "Misc" },
    [81] = { name = "Propane Tank", type = "Misc" },
    [82] = { name = "Rope", type = "Misc" },
    [83] = { name = "Blade", type = "Misc" },
    [84] = { name = "Thread", type = "Misc" },
    [85] = { name = "Metal Plating", type = "Misc" },
    [86] = { name = "Spring", type = "Misc" },
    [87] = { name = "Tarp", type = "Misc" },
    [88] = { name = "Circuit Boards", type = "Misc" },
    [89] = { name = "Metal Scraps", type = "Misc" },
    [90] = { name = "Swift Light Ammo", type = "Ammo" },
    [91] = { name = "Sleeping Bag", type = "Bench" },
    [92] = { name = "Timed Charge", type = "Tool" },
    [93] = { name = "Nails", type = "Ammo" },
    [94] = { name = "Garage Door", type = "Bench" },
    [95] = { name = "Dynamite Bundle", type = "Tool" },
    [96] = { name = "Dynamite Stick", type = "Tool" },
    [97] = { name = "Salvaged RPG", type = "Gun" },
    [98] = { name = "Rocket", type = "Ammo" },
    [99] = { name = "Swift Rocket", type = "Ammo" },
    [100] = { name = "Combustive Rocket", type = "Ammo" },
    [101] = { name = "External Wooden Wall", type = "Bench" },
    [102] = { name = "External Wooden Gate", type = "Bench" },
    [103] = { name = "Vertical Window Cover", type = "Bench" },
    [104] = { name = "Horizontal Window Cover", type = "Bench" },
    [105] = { name = "Jail Wall", type = "Bench" },
    [106] = { name = "Jail Door", type = "Bench" },
    [107] = { name = "%s's Trophy", type = "Bench" },
    [108] = { name = "Salvaged AK74u", type = "Gun" },
    [109] = { name = "Salvaged Pipe Rifle", type = "Gun" },
    [110] = { name = "Petroleum", type = "Resource" },
    [111] = { name = "Boots", type = "Armor", armor_type = "Boots" },
    [112] = { name = "Collared Shirt", type = "Armor", armor_type = "Shirt" },
    [113] = { name = "Shorts", type = "Armor", armor_type = "Pants" },
    [114] = { name = "Tank Top", type = "Armor", armor_type = "Shirt" },
    [115] = { name = "Cloth Shirt", type = "Armor", armor_type = "Shirt" },
    [116] = { name = "Cloth Pants", type = "Armor", armor_type = "Pants" },
    [117] = { name = "Cloth Footwraps", type = "Armor", armor_type = "Boots" },
    [118] = { name = "Leather Poncho", type = "Armor", armor_type = "Chestplate" },
    [119] = { name = "Leather Pants", type = "Armor", armor_type = "Pants" },
    [120] = { name = "Leather Shirt", type = "Armor", armor_type = "Shirt" },
    [121] = { name = "Leather Boots", type = "Armor", armor_type = "Boots" },
    [122] = { name = "Flannel Jacket", type = "Armor", armor_type = "Chestplate" },
    [123] = { name = "Wooden Helmet", type = "Armor", armor_type = "Hat" },
    [124] = { name = "Wooden Chestplate", type = "Armor", armor_type = "Chestplate" },
    [125] = { name = "Wooden Leggings", type = "Armor", armor_type = "Kilt" },
    [126] = { name = "Wooden Arrow", type = "Ammo" },
    [127] = { name = "Swift Arrow", type = "Ammo" },
    [128] = { name = "Bone Arrow", type = "Ammo" },
    [129] = { name = "Combustive Arrow", type = "Ammo" },
    [130] = { name = "Iron Shard Hatchet", type = "Tool" },
    [131] = { name = "Iron Shard Pickaxe", type = "Tool" },
    [132] = { name = "Large Furnace", type = "Bench" },
    [133] = { name = "Yellow Keycard", type = "Tool" },
    [134] = { name = "Purple Keycard", type = "Tool" },
    [135] = { name = "Pink Keycard", type = "Tool" },
    [136] = { name = "Small Medkit", type = "Tool" },
    [137] = { name = "Salvaged Break Action", type = "Gun" },
    [138] = { name = "Buckshot", type = "Ammo" },
    [139] = { name = "Slug", type = "Ammo" },
    [140] = { name = "Combustive Buckshot", type = "Ammo" },
    [141] = { name = "Steel Helmet", type = "Armor", armor_type = "Helmet" },
    [142] = { name = "Steel Chestplate", type = "Armor", armor_type = "Chestplate" },
    [143] = { name = "Steel Leggings", type = "Armor", armor_type = "Kilt" },
    [144] = { name = "Large Storage Box", type = "Bench" },
    [145] = { name = "Salvaged Helmet", type = "Armor", armor_type = "Helmet" },
    [146] = { name = "Salvaged Chestplate", type = "Armor", armor_type = "Chestplate" },
    [147] = { name = "Salvaged Leggings", type = "Armor", armor_type = "Kilt" },
    [148] = { name = "Military Helmet", type = "Armor", armor_type = "Helmet" },
    [149] = { name = "Military Chestplate", type = "Armor", armor_type = "Chestplate" },
    [150] = { name = "Military Leggings", type = "Armor", armor_type = "Kilt" },
    [151] = { name = "Hard Hat", type = "Armor", armor_type = "Hat" },
    [152] = { name = "Balaclava", type = "Armor", armor_type = "Face" },
    [153] = { name = "Cloth Headwrap", type = "Armor", armor_type = "Helmet" },
    [154] = { name = "Baseball Cap", type = "Armor", armor_type = "Hat" },
    [155] = { name = "Salvaged Gloves", type = "Armor", armor_type = "Gloves" },
    [156] = { name = "Cloth Handwraps", type = "Armor", armor_type = "Gloves" },
    [157] = { name = "Military Gloves", type = "Armor", armor_type = "Gloves" },
    [158] = { name = "Leather Gloves", type = "Armor", armor_type = "Gloves" },
    [159] = { name = "Wetsuit", type = "Armor", armor_type = "Wetsuit", attribute = "ResistWet" },
    [160] = { name = "Flippers", type = "Armor", armor_type = "Boots", attribute = "HasFlippers" },
    [161] = { name = "Diving Tank", type = "Armor", armor_type = "Chestplate", attribute = "HasTank" },
    [162] = { name = "Diving Goggles", type = "Armor", armor_type = "Helmet", attribute = "HasGoggles" },
    [163] = { name = "Cooking Pot", type = "Bench" },
    [164] = { name = "Ladder", type = "Bench" },
    [165] = { name = "Chocolate Bar", type = "Consumable" },
    [166] = { name = "Bean Can", type = "Consumable" },
    [167] = { name = "Meatball Can", type = "Consumable" },
    [168] = { name = "Fish Can", type = "Consumable" },
    [169] = { name = "Water Bottle", type = "Consumable" },
    [170] = { name = "Piercing Heavy Ammo", type = "Ammo" },
    [171] = { name = "Piercing Light Ammo", type = "Ammo" },
    [172] = { name = "Semi Receiver", type = "Misc" },
    [173] = { name = "SMG Receiver", type = "Misc" },
    [174] = { name = "Rifle Receiver", type = "Misc" },
    [175] = { name = "Steel Shovel", type = "Tool" },
    [176] = { name = "Empty Can", type = "Misc" },
    [177] = { name = "Care Package Signal", type = "Tool" },
    [178] = { name = "Duct Tape", type = "Misc" },
    [179] = { name = "Glue", type = "Misc" },
    [180] = { name = "Pistol Receiver", type = "Misc" },
    [181] = { name = "Salvaged Shovel", type = "Tool" },
    [182] = { name = "ez shovel", type = "Tool" },
    [183] = { name = "Anvil", type = "Bench" },
    [184] = { name = "Chemistry Lab", type = "Bench" },
    [185] = { name = "Carpentry Table", type = "Bench" },
    [186] = { name = "Sewing Table", type = "Bench" },
    [187] = { name = "Ammo Press", type = "Bench" },
    [188] = { name = "Culinary Table", type = "Bench" },
    [189] = { name = "Petroleum Refinery", type = "Bench" },
    [190] = { name = "Triangle Trap Door", type = "Bench" },
    [191] = { name = "Military AA12", type = "Gun" },
    [192] = { name = "Repair Table", type = "Bench" },
    [193] = { name = "Salvaged Pump Action", type = "Gun" },
    [194] = { name = "Bed", type = "Bench" },
    [195] = { name = "Wooden Spikes", type = "Bench" },
    [196] = { name = "Military ACOG Sight", type = "Attachment" },
    [197] = { name = "Metal Barricade", type = "Bench" },
    [198] = { name = "Military M4A1", type = "Gun" },
    [199] = { name = "Small Wooden Sign", type = "Bench" },
    [200] = { name = "Large Wooden Sign", type = "Bench" },
    [201] = { name = "Storage Cabinet", type = "Bench" },
    [202] = { name = "External Stone Gate", type = "Bench" },
    [203] = { name = "Bone Tool", type = "Tool" },
    [204] = { name = "Salvaged Skorpion", type = "Gun" },
    [205] = { name = "Candy Cane", type = "Tool" },
    [206] = { name = "Christmas Tree", type = "Bench" },
    [207] = { name = "Santa Hat", type = "Armor", armor_type = "Hat" },
    [208] = { name = "External Stone Wall", type = "Bench" },
    [209] = { name = "Blast Furnace", type = "Bench" },
    [210] = { name = "Military Barrett", type = "Gun" },
    [211] = { name = "Shotgun Turret", type = "Bench" },
    [212] = { name = "Military Grenade", type = "Tool" },
    [213] = { name = "Floor Grill", type = "Bench" },
    [214] = { name = "Bear Trap", type = "Bench" },
    [215] = { name = "Landmine Trap", type = "Bench" },
    [216] = { name = "Saw Bat", type = "Tool" },
    [217] = { name = "Machete", type = "Tool" },
    [218] = { name = "Military PKM", type = "Gun" },
    [219] = { name = "Bruno's ACOG Sight", type = "Attachment" },
    [220] = { name = "Military Lasersight", type = "Attachment" },
    [221] = { name = "Bruno's M4A1", type = "Gun" },
    [222] = { name = "Boss Chestplate", type = "Armor", armor_type = "Chestplate" },
    [223] = { name = "Boss Helmet", type = "Armor", armor_type = "Helmet" },
    [224] = { name = "Bunny Ears", type = "Armor", armor_type = "Hat" },
    [225] = { name = "Carrot Blade", type = "Tool" },
    [226] = { name = "Metal Spikes", type = "Bench" },
    [227] = { name = "Rug", type = "Bench" },
    [228] = { name = "Shop Machine", type = "Bench" },
    [229] = { name = "Chainsaw", type = "Tool" },
    [230] = { name = "Mining Drill", type = "Tool" },
    [231] = { name = "Extended Mag", type = "Attachment" },
    [232] = { name = "Jukebox", type = "Bench" },
    [233] = { name = "Wool Plant Seed", type = "Bench" },
    [234] = { name = "Wool", type = "Resource" },
    [235] = { name = "Loom", type = "Bench" },
    [236] = { name = "Small Planter Box", type = "Bench" },
    [237] = { name = "Large Planter Box", type = "Bench" },
    [238] = { name = "Tomato Plant Seed", type = "Bench" },
    [239] = { name = "Corn Plant Seed", type = "Bench" },
    [240] = { name = "Tomato", type = "Consumable" },
    [241] = { name = "Corn", type = "Consumable" },
    [242] = { name = "Chicken Egg", type = "Consumable" },
    [243] = { name = "Milk", type = "Consumable" },
    [244] = { name = "Raspberry Pie I", type = "Consumable" },
    [245] = { name = "Raspberry Pie II", type = "Consumable" },
    [246] = { name = "Raspberry Pie III", type = "Consumable" },
    [247] = { name = "Raspberry Pie IV", type = "Consumable" },
    [248] = { name = "Blueberry Pie I", type = "Consumable" },
    [249] = { name = "Blueberry Pie II", type = "Consumable" },
    [250] = { name = "Blueberry Pie III", type = "Consumable" },
    [251] = { name = "Blueberry Pie IV", type = "Consumable" },
    [252] = { name = "Lemon Cake I", type = "Consumable" },
    [253] = { name = "Lemon Cake II", type = "Consumable" },
    [254] = { name = "Lemon Cake III", type = "Consumable" },
    [255] = { name = "Lemon Cake IV", type = "Consumable" },
    [256] = { name = "Corn Bread I", type = "Consumable" },
    [257] = { name = "Corn Bread II", type = "Consumable" },
    [258] = { name = "Corn Bread III", type = "Consumable" },
    [259] = { name = "Corn Bread IV", type = "Consumable" },
    [260] = { name = "Cow Pasture", type = "Bench" },
    [261] = { name = "Chicken House", type = "Bench" },
    [262] = { name = "Barrel Light", type = "Bench" },
    [263] = { name = "Raspberries", type = "Consumable" },
    [264] = { name = "Blueberries", type = "Consumable" },
    [265] = { name = "Lemon", type = "Consumable" },
    [266] = { name = "Lemon Plant Seed", type = "Bench" },
    [267] = { name = "Raspberry Plant Seed", type = "Bench" },
    [268] = { name = "Blueberry Plant Seed", type = "Bench" },
    [269] = { name = "Military MP7", type = "Gun" },
    [270] = { name = "Red Keycard", type = "Tool" },
    [271] = { name = "Salvaged Double Barrel", type = "Gun" },
    [272] = { name = "Military Boat", type = "Resource" },
    [273] = { name = "Clan Table", type = "Bench" },
    [274] = { name = "Wooden Boat", type = "Resource" },
    [275] = { name = "Military USP", type = "Gun" },
    [276] = { name = "Common Goodie Bag", type = "Misc" },
    [277] = { name = "Rare Goodie Bag", type = "Misc" },
    [278] = { name = "Epic Goodie Bag", type = "Misc" },
    [279] = { name = "Candle", type = "Bench" },
    [280] = { name = "Armor Stand", type = "Bench" },
    [281] = { name = "Jack-O-Lantern", type = "Bench" },
    [282] = { name = "Small Cobweb", type = "Bench" },
    [283] = { name = "Large Cobweb", type = "Bench" },
    [284] = { name = "Pumpkin Plant Seed", type = "Bench" },
    [285] = { name = "Pumpkin", type = "ConsumableAmmoArmor", armor_type = "Helmet" },
    [286] = { name = "Halloween Scythe", type = "Tool" },
    [287] = { name = "Pumpkin Launcher", type = "Gun" },
    [288] = { name = "Raw Wolf", type = "Consumable" },
    [289] = { name = "Cooked Wolf", type = "Consumable" },
    [290] = { name = "Pumpkin Pie", type = "Consumable" },
    [291] = { name = "Cursed Pumpkin", type = "Ammo" },
    [292] = { name = "Marsh Bar", type = "Consumable" },
    [293] = { name = "Peanut Butter Cup", type = "Consumable" },
    [294] = { name = "Candy Roll", type = "Consumable" },
    [295] = { name = "Scarecrow", type = "Bench" },
    [296] = { name = "Salvaged Shotgun", type = "Gun" },
    [297] = { name = "Salvaged Shell", type = "Ammo" },
    [298] = { name = "Bone Armor", type = "Armor", armor_type = "All" },
    [299] = { name = "Armor Plate", type = "Attachment" },
    [300] = { name = "Heavy Padding", type = "Attachment" },
    [301] = { name = "Night Vision Goggles", type = "Attachment", attribute = "NVG" },
    [302] = { name = "Lightweight Padding", type = "Attachment", attribute = "SilentSteps" },
    [303] = { name = "Resistant Rubber", type = "Attachment" },
    [304] = { name = "Armor Polish", type = "Attachment" },
    [305] = { name = "Water Filter", type = "Attachment", attribute = "WaterFilter" },
    [306] = { name = "Steel Toes", type = "Attachment", attribute = "SteelToes" },
    [307] = { name = "Snorkle", type = "Attachment", attribute = "Snorkle" },
    [308] = { name = "Military Backpack", type = "Backpack" },
    [309] = { name = "Salvaged Backpack", type = "Backpack" },
    [310] = { name = "Salvaged Sniper", type = "Gun" },
    [311] = { name = "Military Grenade Launcher", type = "Gun" },
    [312] = { name = "Explosive Shell", type = "Ammo" },
    [313] = { name = "Salvaged Flycopter", type = "Resource" },
    [314] = { name = "Fireplace", type = "Bench" },
    [315] = { name = "Black Keycard", type = "Tool" },
    [316] = { name = "Salvaged Grenade Launcher", type = "Gun" },
    [317] = { name = "Salvaged Explosive Shell", type = "Ammo" },
    [318] = { name = "Shotgun Shell", type = "Ammo" },
    [319] = { name = "Large Medkit", type = "Consumable" },
    [320] = { name = "Small Battery", type = "Bench" },
    [321] = { name = "Medium Battery", type = "Bench" },
    [322] = { name = "Large Battery", type = "Bench" },
    [323] = { name = "Crude Fuel Generator", type = "Bench" },
    [324] = { name = "Solar Panel", type = "Bench" },
    [325] = { name = "Water Turbine", type = "Bench" },
    [326] = { name = "Wire Cutters", type = "Tool" },
    [327] = { name = "Button", type = "Bench" },
    [328] = { name = "Electric Furnace", type = "Bench" },
    [329] = { name = "Electric Heater", type = "Bench" },
    [330] = { name = "Switch", type = "Bench" },
    [331] = { name = "Windmill", type = "Bench" },
    [332] = { name = "Splitter", type = "Bench" },
    [333] = { name = "Military Boat", type = "Resource" },
    [334] = { name = "Auto Turret", type = "Bench" },
    [335] = { name = "Military M39", type = "Gun" },
    [336] = { name = "White Ornament", type = "Resource" },
    [337] = { name = "Red Ornament", type = "Resource" },
    [338] = { name = "Purple Ornament", type = "Resource" },
    [339] = { name = "Wreath", type = "Bench" },
    [340] = { name = "Christmas Lights", type = "Bench" },
    [341] = { name = "Admin Tool", type = "Tool" },
}

M.by_attribute = {
    ["HasFlippers"] = "Flippers",
    ["HasGoggles"] = "Diving Goggles",
    ["HasTank"] = "Diving Tank",
    ["NVG"] = "Night Vision Goggles",
    ["ResistWet"] = "Wetsuit",
    ["SilentSteps"] = "Lightweight Padding",
    ["Snorkle"] = "Snorkle",
    ["SteelToes"] = "Steel Toes",
    ["WaterFilter"] = "Water Filter",
}

M.by_name = {
    ["Wood Log"] = { id = 1, type = "Resource" },
    ["Bandage"] = { id = 2, type = "Tool" },
    ["Stone Hatchet"] = { id = 3, type = "Tool" },
    ["Heavy Ammo"] = { id = 4, type = "Ammo" },
    ["Salvaged AK47"] = { id = 5, type = "Gun" },
    ["Bottle Caps"] = { id = 6, type = "Resource" },
    ["Holo Sight"] = { id = 7, type = "Attachment" },
    ["Silencer"] = { id = 8, type = "Attachment" },
    ["Salvaged M14"] = { id = 9, type = "Gun" },
    ["Lighter"] = { id = 10, type = "Tool" },
    ["Swift Heavy Ammo"] = { id = 11, type = "Ammo" },
    ["Salvaged Sight"] = { id = 12, type = "Attachment" },
    ["Muzzle Boost"] = { id = 13, type = "Attachment" },
    ["Compensator"] = { id = 14, type = "Attachment" },
    ["Salvaged Lasersight"] = { id = 15, type = "Attachment" },
    ["Weapon Flashlight"] = { id = 16, type = "Attachment" },
    ["Salvaged Sniper Scope"] = { id = 17, type = "Attachment" },
    ["Military Sniper Scope"] = { id = 18, type = "Attachment" },
    ["Wooden Spear"] = { id = 19, type = "Tool" },
    ["Stone Spear"] = { id = 20, type = "Tool" },
    ["Stone Pickaxe"] = { id = 21, type = "Tool" },
    ["Crossbow"] = { id = 22, type = "Gun" },
    ["Wooden Bow"] = { id = 23, type = "Gun" },
    ["Cloth"] = { id = 24, type = "Resource" },
    ["Cactus Flesh"] = { id = 25, type = "Consumable" },
    ["Stone"] = { id = 26, type = "Resource" },
    ["Iron Ore"] = { id = 27, type = "Resource" },
    ["Quality Iron Ore"] = { id = 28, type = "Resource" },
    ["Campfire"] = { id = 29, type = "Bench" },
    ["Blueprint"] = { id = 30, type = "Tool" },
    ["Hammer"] = { id = 31, type = "Tool" },
    ["Raw Pork"] = { id = 32, type = "Consumable" },
    ["Cooked Pork"] = { id = 33, type = "Consumable" },
    ["Charcoal"] = { id = 34, type = "Resource" },
    ["Salvaged P250"] = { id = 35, type = "Gun" },
    ["Light Ammo"] = { id = 36, type = "Ammo" },
    ["Boulder"] = { id = 37, type = "Tool" },
    ["Salvaged SMG"] = { id = 38, type = "Gun" },
    ["Salvaged Python"] = { id = 39, type = "Gun" },
    ["Combustive Heavy Ammo"] = { id = 40, type = "Ammo" },
    ["Animal Fat"] = { id = 41, type = "Resource" },
    ["Small Storage Box"] = { id = 42, type = "Bench" },
    ["Raw Venison"] = { id = 43, type = "Consumable" },
    ["Cooked Venison"] = { id = 44, type = "Consumable" },
    ["Iron Shards"] = { id = 45, type = "Resource" },
    ["Steel Metal"] = { id = 46, type = "Resource" },
    ["Wooden Door"] = { id = 47, type = "Bench" },
    ["Wooden Lock"] = { id = 48, type = "Lock" },
    ["Combination Lock"] = { id = 49, type = "Lock" },
    ["Salvaged Metal Door"] = { id = 50, type = "Bench" },
    ["Base Cabinet"] = { id = 51, type = "Bench" },
    ["Wooden Double Door"] = { id = 52, type = "Bench" },
    ["Wooden Window Bars"] = { id = 53, type = "Bench" },
    ["Metal Window Bars"] = { id = 54, type = "Bench" },
    ["Glass Window"] = { id = 55, type = "Bench" },
    ["Steel Glass Window"] = { id = 56, type = "Bench" },
    ["Trap Door"] = { id = 57, type = "Bench" },
    ["Radiation Vitamins"] = { id = 58, type = "Consumable" },
    ["Hoodie"] = { id = 59, type = "Armor", armor_type = "Shirt" },
    ["Hazmat Suit"] = { id = 60, type = "Armor", armor_type = "All", attribute = "ResistWet" },
    ["Chicken MRE"] = { id = 61, type = "Consumable" },
    ["Beef MRE"] = { id = 62, type = "Consumable" },
    ["Pants"] = { id = 63, type = "Armor", armor_type = "Pants" },
    ["Phosphate Ore"] = { id = 64, type = "Resource" },
    ["Phosphate Dust"] = { id = 65, type = "Resource" },
    ["Leather"] = { id = 66, type = "Resource" },
    ["Furnace"] = { id = 67, type = "Bench" },
    ["Crude Fuel"] = { id = 68, type = "Resource" },
    ["Gunpowder"] = { id = 69, type = "Resource" },
    ["Bone Shards"] = { id = 70, type = "Resource" },
    ["Metal Door"] = { id = 71, type = "Bench" },
    ["Metal Double Door"] = { id = 72, type = "Bench" },
    ["Steel Door"] = { id = 73, type = "Bench" },
    ["Steel Double Door"] = { id = 74, type = "Bench" },
    ["Nail Gun"] = { id = 75, type = "Gun" },
    ["Steel Axe"] = { id = 76, type = "Tool" },
    ["Steel Pickaxe"] = { id = 77, type = "Tool" },
    ["Power Cell"] = { id = 78, type = "Misc" },
    ["Copper Cogs"] = { id = 79, type = "Misc" },
    ["Pipe"] = { id = 80, type = "Misc" },
    ["Propane Tank"] = { id = 81, type = "Misc" },
    ["Rope"] = { id = 82, type = "Misc" },
    ["Blade"] = { id = 83, type = "Misc" },
    ["Thread"] = { id = 84, type = "Misc" },
    ["Metal Plating"] = { id = 85, type = "Misc" },
    ["Spring"] = { id = 86, type = "Misc" },
    ["Tarp"] = { id = 87, type = "Misc" },
    ["Circuit Boards"] = { id = 88, type = "Misc" },
    ["Metal Scraps"] = { id = 89, type = "Misc" },
    ["Swift Light Ammo"] = { id = 90, type = "Ammo" },
    ["Sleeping Bag"] = { id = 91, type = "Bench" },
    ["Timed Charge"] = { id = 92, type = "Tool" },
    ["Nails"] = { id = 93, type = "Ammo" },
    ["Garage Door"] = { id = 94, type = "Bench" },
    ["Dynamite Bundle"] = { id = 95, type = "Tool" },
    ["Dynamite Stick"] = { id = 96, type = "Tool" },
    ["Salvaged RPG"] = { id = 97, type = "Gun" },
    ["Rocket"] = { id = 98, type = "Ammo" },
    ["Swift Rocket"] = { id = 99, type = "Ammo" },
    ["Combustive Rocket"] = { id = 100, type = "Ammo" },
    ["External Wooden Wall"] = { id = 101, type = "Bench" },
    ["External Wooden Gate"] = { id = 102, type = "Bench" },
    ["Vertical Window Cover"] = { id = 103, type = "Bench" },
    ["Horizontal Window Cover"] = { id = 104, type = "Bench" },
    ["Jail Wall"] = { id = 105, type = "Bench" },
    ["Jail Door"] = { id = 106, type = "Bench" },
    ["%s's Trophy"] = { id = 107, type = "Bench" },
    ["Salvaged AK74u"] = { id = 108, type = "Gun" },
    ["Salvaged Pipe Rifle"] = { id = 109, type = "Gun" },
    ["Petroleum"] = { id = 110, type = "Resource" },
    ["Boots"] = { id = 111, type = "Armor", armor_type = "Boots" },
    ["Collared Shirt"] = { id = 112, type = "Armor", armor_type = "Shirt" },
    ["Shorts"] = { id = 113, type = "Armor", armor_type = "Pants" },
    ["Tank Top"] = { id = 114, type = "Armor", armor_type = "Shirt" },
    ["Cloth Shirt"] = { id = 115, type = "Armor", armor_type = "Shirt" },
    ["Cloth Pants"] = { id = 116, type = "Armor", armor_type = "Pants" },
    ["Cloth Footwraps"] = { id = 117, type = "Armor", armor_type = "Boots" },
    ["Leather Poncho"] = { id = 118, type = "Armor", armor_type = "Chestplate" },
    ["Leather Pants"] = { id = 119, type = "Armor", armor_type = "Pants" },
    ["Leather Shirt"] = { id = 120, type = "Armor", armor_type = "Shirt" },
    ["Leather Boots"] = { id = 121, type = "Armor", armor_type = "Boots" },
    ["Flannel Jacket"] = { id = 122, type = "Armor", armor_type = "Chestplate" },
    ["Wooden Helmet"] = { id = 123, type = "Armor", armor_type = "Hat" },
    ["Wooden Chestplate"] = { id = 124, type = "Armor", armor_type = "Chestplate" },
    ["Wooden Leggings"] = { id = 125, type = "Armor", armor_type = "Kilt" },
    ["Wooden Arrow"] = { id = 126, type = "Ammo" },
    ["Swift Arrow"] = { id = 127, type = "Ammo" },
    ["Bone Arrow"] = { id = 128, type = "Ammo" },
    ["Combustive Arrow"] = { id = 129, type = "Ammo" },
    ["Iron Shard Hatchet"] = { id = 130, type = "Tool" },
    ["Iron Shard Pickaxe"] = { id = 131, type = "Tool" },
    ["Large Furnace"] = { id = 132, type = "Bench" },
    ["Yellow Keycard"] = { id = 133, type = "Tool" },
    ["Purple Keycard"] = { id = 134, type = "Tool" },
    ["Pink Keycard"] = { id = 135, type = "Tool" },
    ["Small Medkit"] = { id = 136, type = "Tool" },
    ["Salvaged Break Action"] = { id = 137, type = "Gun" },
    ["Buckshot"] = { id = 138, type = "Ammo" },
    ["Slug"] = { id = 139, type = "Ammo" },
    ["Combustive Buckshot"] = { id = 140, type = "Ammo" },
    ["Steel Helmet"] = { id = 141, type = "Armor", armor_type = "Helmet" },
    ["Steel Chestplate"] = { id = 142, type = "Armor", armor_type = "Chestplate" },
    ["Steel Leggings"] = { id = 143, type = "Armor", armor_type = "Kilt" },
    ["Large Storage Box"] = { id = 144, type = "Bench" },
    ["Salvaged Helmet"] = { id = 145, type = "Armor", armor_type = "Helmet" },
    ["Salvaged Chestplate"] = { id = 146, type = "Armor", armor_type = "Chestplate" },
    ["Salvaged Leggings"] = { id = 147, type = "Armor", armor_type = "Kilt" },
    ["Military Helmet"] = { id = 148, type = "Armor", armor_type = "Helmet" },
    ["Military Chestplate"] = { id = 149, type = "Armor", armor_type = "Chestplate" },
    ["Military Leggings"] = { id = 150, type = "Armor", armor_type = "Kilt" },
    ["Hard Hat"] = { id = 151, type = "Armor", armor_type = "Hat" },
    ["Balaclava"] = { id = 152, type = "Armor", armor_type = "Face" },
    ["Cloth Headwrap"] = { id = 153, type = "Armor", armor_type = "Helmet" },
    ["Baseball Cap"] = { id = 154, type = "Armor", armor_type = "Hat" },
    ["Salvaged Gloves"] = { id = 155, type = "Armor", armor_type = "Gloves" },
    ["Cloth Handwraps"] = { id = 156, type = "Armor", armor_type = "Gloves" },
    ["Military Gloves"] = { id = 157, type = "Armor", armor_type = "Gloves" },
    ["Leather Gloves"] = { id = 158, type = "Armor", armor_type = "Gloves" },
    ["Wetsuit"] = { id = 159, type = "Armor", armor_type = "Wetsuit", attribute = "ResistWet" },
    ["Flippers"] = { id = 160, type = "Armor", armor_type = "Boots", attribute = "HasFlippers" },
    ["Diving Tank"] = { id = 161, type = "Armor", armor_type = "Chestplate", attribute = "HasTank" },
    ["Diving Goggles"] = { id = 162, type = "Armor", armor_type = "Helmet", attribute = "HasGoggles" },
    ["Cooking Pot"] = { id = 163, type = "Bench" },
    ["Ladder"] = { id = 164, type = "Bench" },
    ["Chocolate Bar"] = { id = 165, type = "Consumable" },
    ["Bean Can"] = { id = 166, type = "Consumable" },
    ["Meatball Can"] = { id = 167, type = "Consumable" },
    ["Fish Can"] = { id = 168, type = "Consumable" },
    ["Water Bottle"] = { id = 169, type = "Consumable" },
    ["Piercing Heavy Ammo"] = { id = 170, type = "Ammo" },
    ["Piercing Light Ammo"] = { id = 171, type = "Ammo" },
    ["Semi Receiver"] = { id = 172, type = "Misc" },
    ["SMG Receiver"] = { id = 173, type = "Misc" },
    ["Rifle Receiver"] = { id = 174, type = "Misc" },
    ["Steel Shovel"] = { id = 175, type = "Tool" },
    ["Empty Can"] = { id = 176, type = "Misc" },
    ["Care Package Signal"] = { id = 177, type = "Tool" },
    ["Duct Tape"] = { id = 178, type = "Misc" },
    ["Glue"] = { id = 179, type = "Misc" },
    ["Pistol Receiver"] = { id = 180, type = "Misc" },
    ["Salvaged Shovel"] = { id = 181, type = "Tool" },
    ["ez shovel"] = { id = 182, type = "Tool" },
    ["Anvil"] = { id = 183, type = "Bench" },
    ["Chemistry Lab"] = { id = 184, type = "Bench" },
    ["Carpentry Table"] = { id = 185, type = "Bench" },
    ["Sewing Table"] = { id = 186, type = "Bench" },
    ["Ammo Press"] = { id = 187, type = "Bench" },
    ["Culinary Table"] = { id = 188, type = "Bench" },
    ["Petroleum Refinery"] = { id = 189, type = "Bench" },
    ["Triangle Trap Door"] = { id = 190, type = "Bench" },
    ["Military AA12"] = { id = 191, type = "Gun" },
    ["Repair Table"] = { id = 192, type = "Bench" },
    ["Salvaged Pump Action"] = { id = 193, type = "Gun" },
    ["Bed"] = { id = 194, type = "Bench" },
    ["Wooden Spikes"] = { id = 195, type = "Bench" },
    ["Military ACOG Sight"] = { id = 196, type = "Attachment" },
    ["Metal Barricade"] = { id = 197, type = "Bench" },
    ["Military M4A1"] = { id = 198, type = "Gun" },
    ["Small Wooden Sign"] = { id = 199, type = "Bench" },
    ["Large Wooden Sign"] = { id = 200, type = "Bench" },
    ["Storage Cabinet"] = { id = 201, type = "Bench" },
    ["External Stone Gate"] = { id = 202, type = "Bench" },
    ["Bone Tool"] = { id = 203, type = "Tool" },
    ["Salvaged Skorpion"] = { id = 204, type = "Gun" },
    ["Candy Cane"] = { id = 205, type = "Tool" },
    ["Christmas Tree"] = { id = 206, type = "Bench" },
    ["Santa Hat"] = { id = 207, type = "Armor", armor_type = "Hat" },
    ["External Stone Wall"] = { id = 208, type = "Bench" },
    ["Blast Furnace"] = { id = 209, type = "Bench" },
    ["Military Barrett"] = { id = 210, type = "Gun" },
    ["Shotgun Turret"] = { id = 211, type = "Bench" },
    ["Military Grenade"] = { id = 212, type = "Tool" },
    ["Floor Grill"] = { id = 213, type = "Bench" },
    ["Bear Trap"] = { id = 214, type = "Bench" },
    ["Landmine Trap"] = { id = 215, type = "Bench" },
    ["Saw Bat"] = { id = 216, type = "Tool" },
    ["Machete"] = { id = 217, type = "Tool" },
    ["Military PKM"] = { id = 218, type = "Gun" },
    ["Bruno's ACOG Sight"] = { id = 219, type = "Attachment" },
    ["Military Lasersight"] = { id = 220, type = "Attachment" },
    ["Bruno's M4A1"] = { id = 221, type = "Gun" },
    ["Boss Chestplate"] = { id = 222, type = "Armor", armor_type = "Chestplate" },
    ["Boss Helmet"] = { id = 223, type = "Armor", armor_type = "Helmet" },
    ["Bunny Ears"] = { id = 224, type = "Armor", armor_type = "Hat" },
    ["Carrot Blade"] = { id = 225, type = "Tool" },
    ["Metal Spikes"] = { id = 226, type = "Bench" },
    ["Rug"] = { id = 227, type = "Bench" },
    ["Shop Machine"] = { id = 228, type = "Bench" },
    ["Chainsaw"] = { id = 229, type = "Tool" },
    ["Mining Drill"] = { id = 230, type = "Tool" },
    ["Extended Mag"] = { id = 231, type = "Attachment" },
    ["Jukebox"] = { id = 232, type = "Bench" },
    ["Wool Plant Seed"] = { id = 233, type = "Bench" },
    ["Wool"] = { id = 234, type = "Resource" },
    ["Loom"] = { id = 235, type = "Bench" },
    ["Small Planter Box"] = { id = 236, type = "Bench" },
    ["Large Planter Box"] = { id = 237, type = "Bench" },
    ["Tomato Plant Seed"] = { id = 238, type = "Bench" },
    ["Corn Plant Seed"] = { id = 239, type = "Bench" },
    ["Tomato"] = { id = 240, type = "Consumable" },
    ["Corn"] = { id = 241, type = "Consumable" },
    ["Chicken Egg"] = { id = 242, type = "Consumable" },
    ["Milk"] = { id = 243, type = "Consumable" },
    ["Raspberry Pie I"] = { id = 244, type = "Consumable" },
    ["Raspberry Pie II"] = { id = 245, type = "Consumable" },
    ["Raspberry Pie III"] = { id = 246, type = "Consumable" },
    ["Raspberry Pie IV"] = { id = 247, type = "Consumable" },
    ["Blueberry Pie I"] = { id = 248, type = "Consumable" },
    ["Blueberry Pie II"] = { id = 249, type = "Consumable" },
    ["Blueberry Pie III"] = { id = 250, type = "Consumable" },
    ["Blueberry Pie IV"] = { id = 251, type = "Consumable" },
    ["Lemon Cake I"] = { id = 252, type = "Consumable" },
    ["Lemon Cake II"] = { id = 253, type = "Consumable" },
    ["Lemon Cake III"] = { id = 254, type = "Consumable" },
    ["Lemon Cake IV"] = { id = 255, type = "Consumable" },
    ["Corn Bread I"] = { id = 256, type = "Consumable" },
    ["Corn Bread II"] = { id = 257, type = "Consumable" },
    ["Corn Bread III"] = { id = 258, type = "Consumable" },
    ["Corn Bread IV"] = { id = 259, type = "Consumable" },
    ["Cow Pasture"] = { id = 260, type = "Bench" },
    ["Chicken House"] = { id = 261, type = "Bench" },
    ["Barrel Light"] = { id = 262, type = "Bench" },
    ["Raspberries"] = { id = 263, type = "Consumable" },
    ["Blueberries"] = { id = 264, type = "Consumable" },
    ["Lemon"] = { id = 265, type = "Consumable" },
    ["Lemon Plant Seed"] = { id = 266, type = "Bench" },
    ["Raspberry Plant Seed"] = { id = 267, type = "Bench" },
    ["Blueberry Plant Seed"] = { id = 268, type = "Bench" },
    ["Military MP7"] = { id = 269, type = "Gun" },
    ["Red Keycard"] = { id = 270, type = "Tool" },
    ["Salvaged Double Barrel"] = { id = 271, type = "Gun" },
    ["Military Boat"] = { id = 272, type = "Resource" },
    ["Clan Table"] = { id = 273, type = "Bench" },
    ["Wooden Boat"] = { id = 274, type = "Resource" },
    ["Military USP"] = { id = 275, type = "Gun" },
    ["Common Goodie Bag"] = { id = 276, type = "Misc" },
    ["Rare Goodie Bag"] = { id = 277, type = "Misc" },
    ["Epic Goodie Bag"] = { id = 278, type = "Misc" },
    ["Candle"] = { id = 279, type = "Bench" },
    ["Armor Stand"] = { id = 280, type = "Bench" },
    ["Jack-O-Lantern"] = { id = 281, type = "Bench" },
    ["Small Cobweb"] = { id = 282, type = "Bench" },
    ["Large Cobweb"] = { id = 283, type = "Bench" },
    ["Pumpkin Plant Seed"] = { id = 284, type = "Bench" },
    ["Pumpkin"] = { id = 285, type = "ConsumableAmmoArmor", armor_type = "Helmet" },
    ["Halloween Scythe"] = { id = 286, type = "Tool" },
    ["Pumpkin Launcher"] = { id = 287, type = "Gun" },
    ["Raw Wolf"] = { id = 288, type = "Consumable" },
    ["Cooked Wolf"] = { id = 289, type = "Consumable" },
    ["Pumpkin Pie"] = { id = 290, type = "Consumable" },
    ["Cursed Pumpkin"] = { id = 291, type = "Ammo" },
    ["Marsh Bar"] = { id = 292, type = "Consumable" },
    ["Peanut Butter Cup"] = { id = 293, type = "Consumable" },
    ["Candy Roll"] = { id = 294, type = "Consumable" },
    ["Scarecrow"] = { id = 295, type = "Bench" },
    ["Salvaged Shotgun"] = { id = 296, type = "Gun" },
    ["Salvaged Shell"] = { id = 297, type = "Ammo" },
    ["Bone Armor"] = { id = 298, type = "Armor", armor_type = "All" },
    ["Armor Plate"] = { id = 299, type = "Attachment" },
    ["Heavy Padding"] = { id = 300, type = "Attachment" },
    ["Night Vision Goggles"] = { id = 301, type = "Attachment", attribute = "NVG" },
    ["Lightweight Padding"] = { id = 302, type = "Attachment", attribute = "SilentSteps" },
    ["Resistant Rubber"] = { id = 303, type = "Attachment" },
    ["Armor Polish"] = { id = 304, type = "Attachment" },
    ["Water Filter"] = { id = 305, type = "Attachment", attribute = "WaterFilter" },
    ["Steel Toes"] = { id = 306, type = "Attachment", attribute = "SteelToes" },
    ["Snorkle"] = { id = 307, type = "Attachment", attribute = "Snorkle" },
    ["Military Backpack"] = { id = 308, type = "Backpack" },
    ["Salvaged Backpack"] = { id = 309, type = "Backpack" },
    ["Salvaged Sniper"] = { id = 310, type = "Gun" },
    ["Military Grenade Launcher"] = { id = 311, type = "Gun" },
    ["Explosive Shell"] = { id = 312, type = "Ammo" },
    ["Salvaged Flycopter"] = { id = 313, type = "Resource" },
    ["Fireplace"] = { id = 314, type = "Bench" },
    ["Black Keycard"] = { id = 315, type = "Tool" },
    ["Salvaged Grenade Launcher"] = { id = 316, type = "Gun" },
    ["Salvaged Explosive Shell"] = { id = 317, type = "Ammo" },
    ["Shotgun Shell"] = { id = 318, type = "Ammo" },
    ["Large Medkit"] = { id = 319, type = "Consumable" },
    ["Small Battery"] = { id = 320, type = "Bench" },
    ["Medium Battery"] = { id = 321, type = "Bench" },
    ["Large Battery"] = { id = 322, type = "Bench" },
    ["Crude Fuel Generator"] = { id = 323, type = "Bench" },
    ["Solar Panel"] = { id = 324, type = "Bench" },
    ["Water Turbine"] = { id = 325, type = "Bench" },
    ["Wire Cutters"] = { id = 326, type = "Tool" },
    ["Button"] = { id = 327, type = "Bench" },
    ["Electric Furnace"] = { id = 328, type = "Bench" },
    ["Electric Heater"] = { id = 329, type = "Bench" },
    ["Switch"] = { id = 330, type = "Bench" },
    ["Windmill"] = { id = 331, type = "Bench" },
    ["Splitter"] = { id = 332, type = "Bench" },
    ["Military Boat"] = { id = 333, type = "Resource" },
    ["Auto Turret"] = { id = 334, type = "Bench" },
    ["Military M39"] = { id = 335, type = "Gun" },
    ["White Ornament"] = { id = 336, type = "Resource" },
    ["Red Ornament"] = { id = 337, type = "Resource" },
    ["Purple Ornament"] = { id = 338, type = "Resource" },
    ["Wreath"] = { id = 339, type = "Bench" },
    ["Christmas Lights"] = { id = 340, type = "Bench" },
    ["Admin Tool"] = { id = 341, type = "Tool" },
}

function M.get_by_name(name)
    return name and M.by_name[name] or nil
end

function M.get(id)
    return id and M.by_id[id] or nil
end

function M.get_by_attribute(attr)
    local name = attr and M.by_attribute[attr]
    if not name then return nil end
    return { name = name }
end

function M.name_for_armor_model(model_name)
    if not model_name or model_name:sub(1, 6) ~= "Armor_" then return nil end
    local id, skin = model_name:match("^Armor_(%d+)/(.+)$")
    if not id then
        id = model_name:match("^Armor_(%d+)$")
        skin = nil
    end
    if id then
        local row = M.by_id[tonumber(id)]
        if row then return row.name, skin end
    end
    local key = model_name:match("^(.-)/") or model_name
    key = key:gsub(" ", "_")
    local num = key:match("^Armor_(%d+)$")
    if num then
        local row = M.by_id[tonumber(num)]
        if row then return row.name, model_name:match("^.-/(.+)$") end
    end
    local attr = key:match("^Armor_(.+)$")
    if attr then
        local row = M.get_by_attribute(attr)
        if row then return row.name, model_name:match("^.-/(.+)$") end
    end
    return nil
end

return M

end)()

-- ── game/items.lua ──
April._mods["game.items"] = (function()
local env = April.require("core.env")
local item_images = April.require("game.item_images")
local attachment_images = April.require("game.attachment_images")
local item_catalog = April.require("game.item_catalog")
local asset_urls = April.require("game.asset_urls")

local M = {}
local loaded = false
local by_name = {}

local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}

local NAME_ALIASES = {
    ["Cloth Head Wrap"] = "Cloth Headwrap",
}

local HELD_TYPES = {
    Gun = true,
    Tool = true,
    Bench = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end

local function rbx_asset_digits(value)
    if value == nil then return nil end
    return tostring(value):match("(%d+)$")
end

local function image_id_from_table(img, variant)
    if type(img) == "string" then
        return rbx_asset_digits(img)
    end
    if type(img) ~= "table" then return nil end
    local pick = (variant and img[variant]) or img.Default or img.default
    if pick then return rbx_asset_digits(pick) end
    return nil
end

local function index_data(data)
    if data[1] and type(data[1]) == "table" then
        for id, entry in ipairs(data) do
            if type(entry) == "table" then
                local cat = item_catalog.get(id)
                if cat and cat.name then
                    entry.Name = cat.name
                    by_name[cat.name] = entry
                end
                by_name[id] = entry
            end
        end
        return
    end
    for key, entry in pairs(data) do
        if type(entry) == "table" then
            if type(key) == "number" then
                local cat = item_catalog.get(key)
                if cat and cat.name then
                    entry.Name = cat.name
                    by_name[cat.name] = entry
                end
                by_name[key] = entry
            else
                entry.Name = entry.Name or key
                by_name[entry.Name] = entry
            end
        end
    end
end

function M.normalize_name(name)
    if not name then return nil end
    return NAME_ALIASES[name] or name
end

function M.load()
    if loaded then return true end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and type(data) == "table" then
                index_data(data)
                loaded = true
                return true
            end
        end
    end

    local module_scan = April.require("game.module_scan")
    local data = module_scan.find_items()
    if data then
        index_data(data)
        loaded = true
        return true
    end

    return false
end

function M.invalidate()
    loaded = false
    by_name = {}
end

function M.get(name)
    if not loaded then M.load() end
    return by_name[name] or FALLBACK[name]
end

function M.get_catalog(name)
    return item_catalog.get_by_name(M.normalize_name(name))
end

function M.get_type(name)
    local row = M.get_catalog(name)
    if row then return row.type end

    local item = M.get(name)
    return item and item.Type or "Unknown"
end

function M.is_held_display(name)
    if not name or name == "" then return false end

    local base = select(1, parse_variant_name(name))
    local row = M.get_catalog(base)
    if row and HELD_TYPES[row.type] then return true end

    local t = M.get_type(base)
    return HELD_TYPES[t] == true
end

function M.get_by_id(id)
    if type(id) ~= "number" then return nil end
    if not loaded then M.load() end

    local cat = item_catalog.get(id)
    if cat and cat.name then
        local row = by_name[cat.name]
        if row then return row end
    end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[id] then return data[id] end
        end
    end

    return nil
end

function M.get_image_asset_id(name, variant)
    if not name then return nil end

    name = M.normalize_name(name)

    local cat = item_catalog.get_by_name(name)

    local id = item_images.get_asset_id(name, variant)
    if id then return id end

    id = attachment_images.get_asset_id(name)
    if id then return id end

    if cat and cat.id then
        local item = M.get_by_id(cat.id)
        if item and item.Image then
            id = image_id_from_table(item.Image, variant)
            if id then return id end
        end
    end

    if variant and variant ~= "" and variant ~= "Default" then
        id = item_images.get_asset_id(name, "Default")
        if id then return id end
        if cat and cat.id then
            local item = M.get_by_id(cat.id)
            if item and item.Image then
                id = image_id_from_table(item.Image, "Default")
                if id then return id end
            end
        end
    end

    if not loaded then M.load() end
    local item = by_name[name]
    if item and item.Image then
        return image_id_from_table(item.Image, variant)
    end

    return nil
end

function M.make_piece(name, variant)
    name = M.normalize_name(name)
    if not name or name == "" then return nil end
    return {
        name = name,
        variant = variant,
        asset_id = M.get_image_asset_id(name, variant),
    }
end

function M.resolve_armor_model(model_name)
    if not model_name then return nil end
    local item_name, variant = item_catalog.name_for_armor_model(model_name)
    if not item_name then return nil end
    return M.make_piece(item_name, variant)
end

function M.resolve_item_label(label)
    if not label or label == "" then return nil end

    local base, variant = parse_variant_name(label)
    base = M.normalize_name(base)

    local numeric = tonumber(base)
    if numeric then
        local row = item_catalog.get(numeric)
        if row then
            return M.make_piece(row.name, variant)
        end
    end

    if item_catalog.get_by_name(base) or item_images.get_asset_id(base, variant)
        or attachment_images.get_asset_id(base) then
        return M.make_piece(base, variant)
    end

    if not loaded then M.load() end
    if by_name[base] then
        return M.make_piece(base, variant)
    end

    return nil
end

function M.get_image_url(name, variant)
    local id = M.get_image_asset_id(name, variant)
    if id then return asset_urls.item_png(id) end
    return nil
end

return M

end)()

-- ── game/weapons.lua ──
April._mods["game.weapons"] = (function()
local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}
local loaded = false
local toolinfo = {}
local recoil_weapons = {}
local weapon_names = {}

local ROBLOX_GRAV = 196.2

local FALLBACK_STATS = {
    ["Military Barret"] = { speed = 2500, gravity = 0.55 },
    ["Military Barrett"] = { speed = 2500, gravity = 0.55 },
    ["Military M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Military M39"] = { speed = 2400, gravity = 0.52 },
    ["Military MP7"] = { speed = 1900, gravity = 0.6 },
    ["Military PKM"] = { speed = 2400, gravity = 0.55 },
    ["Military USP"] = { speed = 1800, gravity = 0.6 },
    ["Military AA12"] = { speed = 400, gravity = 0.6 },
    ["Bruno's M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK47"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK74u"] = { speed = 1900, gravity = 0.6 },
    ["Salvaged AK4"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged Sniper"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged M14"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged SMG"] = { speed = 1600, gravity = 0.6 },
    ["Salvaged Skorpion"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Python"] = { speed = 1500, gravity = 0.6 },
    ["Salvaged P250"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Pipe Rifle"] = { speed = 800, gravity = 0.55 },
    ["Salvaged Pump Action"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Shotgun"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Double Barrel"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Break Action"] = { speed = 400, gravity = 0.6 },
    ["Crossbow"] = { speed = 420, gravity = 0.2 },
    ["Wooden Bow"] = { speed = 280, gravity = 0.2 },
    ["Nail Gun"] = { speed = 165, gravity = 0.25 },
    ["Pumpkin Launcher"] = { speed = 100, gravity = 0.12 },
    ["Salvaged RPG"] = { speed = 100, gravity = 0.12 },
    ["Military Grenade Launcher"] = { speed = 350, gravity = 0.55 },
    ["Salvaged Grenade Launcher"] = { speed = 350, gravity = 0.55 },
    ["Wooden Spear"] = { speed = 130, gravity = 0.35 },
    ["Stone Spear"] = { speed = 150, gravity = 0.35 },
}

M._last_held = nil
M._last_held_ranged = nil
M._was_in_game = false
M._weapon_changed_at = 0

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end

local function rebuild_weapon_names()
    weapon_names = {}
    for name in pairs(FALLBACK_STATS) do
        weapon_names[name] = true
    end
    for name in pairs(toolinfo) do
        if type(name) == "string" then
            weapon_names[name] = true
        end
    end
end

function M.slug(name)
    return "april_rc_" .. (name or ""):gsub("[^%w]", "_")
end

function M.is_weapon_name(name)
    return name and weapon_names[name] == true
end

local MELEE_NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "spear", "machete", "knife", "sword",
    "bone tool", "hammer", "crowbar",
    "chainsaw", "mining drill", "shovel", "scythe",
    "candy cane", "carrot blade", "boulder", "saw bat",
}

local function is_spear_name(name)
    if not name or name == "" then return false end
    return name:lower():find("spear", 1, true) ~= nil
end

local function name_looks_melee(name)
    if is_spear_name(name) then return false end
    local n = (name or ""):lower()
    for _, hint in ipairs(MELEE_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

function M.is_ranged_weapon_name(name)
    if not name or name == "" then return false end
    local lower = name:lower()
    if lower:find("bow", 1, true) or lower:find("crossbow", 1, true) then return true end
    if is_spear_name(name) then return true end
    if name_looks_melee(name) then return false end

    if not loaded then M.load() end

    local entry = toolinfo[name]
    if entry then
        if entry.Bullet then return true end
        if entry.Melee and not entry.Bullet then return false end
        if entry.Weapon and (entry.Weapon.RPM or entry.Weapon.ActualRPM) then
            return true
        end
        if entry.Melee then return false end
    end

    if FALLBACK_STATS[name] then
        return true
    end

    return false
end

local function children_of(inst)
    if not inst then return {} end
    return env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        return inst:GetChildren()
    end) or {}
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function pick_weapon_from_model(model)
    if not model then return nil, nil end
    local n = inst_name(model)
    if n and M.is_weapon_name(n) then
        return n, model
    end
    for _, child in ipairs(children_of(model)) do
        local cn = inst_name(child)
        if cn and M.is_weapon_name(cn) then
            return cn, child
        end
        local class = child.ClassName or child.class_name
        if class == "Model" and cn and M.is_ranged_weapon_name(cn) then
            return cn, child
        end
    end
    return nil, nil
end

local function find_held_in_viewmodels()
    local ws = env.get_workspace()
    if not ws then return nil end

    -- Live VM under CurrentCamera (ViewmodelController)
    local cam = env.safe_call(function()
        return ws.CurrentCamera or ws.currentCamera
            or (ws.FindFirstChild and ws:FindFirstChild("CurrentCamera"))
    end)
    if cam then
        for _, child in ipairs(children_of(cam)) do
            local class = child.ClassName or child.class_name
            if class == "Model" then
                local n, inst = pick_weapon_from_model(child)
                if n then return n, inst end
            end
        end
    end

    -- Workspace.VFX.VMs.<Weapon>
    local vfx = find_child(ws, "VFX")
    local vms_live = vfx and find_child(vfx, "VMs")
    if vms_live then
        for _, child in ipairs(children_of(vms_live)) do
            local n, inst = pick_weapon_from_model(child)
            if n then return n, inst end
        end
    end

    -- Legacy Workspace.Viewmodels.Viewmodel.<Weapon>
    local vms = find_child(ws, "Viewmodels")
    if vms then
        for _, vm in ipairs(children_of(vms)) do
            if inst_name(vm) == "Viewmodel" then
                local n, inst = pick_weapon_from_model(vm)
                if n then return n, inst end
            end
        end
    end
    return nil, nil
end

local function find_held_in_character(lp)
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil, nil end

    local fallback_tool = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local n = inst_name(child)
        if n and M.is_weapon_name(n) then
            return n, child
        end
        if is_tool(child) and n then
            fallback_tool = fallback_tool or { name = n, inst = child }
        end
    end

    if fallback_tool then
        return fallback_tool.name, fallback_tool.inst
    end
    return nil, nil
end

local function read_tool_attributes(inst)
    if not inst then return nil end
    local speed, gravity
    pcall(function()
        if inst.GetAttribute then
            speed = inst:GetAttribute("BulletSpeed") or inst:GetAttribute("MuzzleVelocity")
            gravity = inst:GetAttribute("BulletGravity") or inst:GetAttribute("ProjectileGravity")
        elseif inst.get_attribute then
            speed = inst:get_attribute("BulletSpeed") or inst:get_attribute("MuzzleVelocity")
            gravity = inst:get_attribute("BulletGravity") or inst:get_attribute("ProjectileGravity")
        end
    end)
    if speed then
        local grav = gravity
        if not grav or grav <= 0 or grav > 2 then
            grav = 0.55
        end
        return {
            speed = speed,
            gravity = grav,
            name = inst_name(inst),
            from_attributes = true,
        }
    end
    return nil
end

function M.get_held_ranged_weapon_name()
    if not loaded then M.load() end

    local lp = env.get_local_player()
    if not lp then return nil end

    local function pick(name)
        if name and M.is_ranged_weapon_name(name) then return name end
    end

    local char = lp.character
    if char and env.is_valid(char) then
        for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            local hit = pick(inst_name(child))
            if hit then return hit end
        end
    end

    local name = find_held_in_viewmodels()
    if name then
        local hit = pick(name)
        if hit then return hit end
    end

    return pick(lp.tool_name)
end

function M.holding_ranged_weapon()
    return M._last_held_ranged ~= nil
end

function M.cached_held_ranged()
    return M._last_held_ranged
end

function M.is_bow_weapon_name(name)
    if not name then return false end
    if not loaded then M.load() end
    local entry = toolinfo[name]
    if entry and entry.Weapon and entry.Weapon.IsBow then
        return true
    end
    -- Fallen projectile bows that aim torso for ballistics (arrows still headshot).
    local n = name:lower()
    if n:find("crossbow", 1, true) then return true end
    if n:find("wooden bow", 1, true) then return true end
    if n == "bow" or n:sub(-4) == " bow" then return true end
    return false
end

function M.invalidate()
    loaded = false
    toolinfo = {}
    recoil_weapons = {}
    weapon_names = {}
    M._last_held = nil
    M._last_held_ranged = nil
    M._weapon_changed_at = 0
    pcall(function()
        local origin = April.require("game.combat_origin")
        if origin.invalidate then origin.invalidate() end
    end)
end

function M.in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

function M.load()
    if loaded then return true end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) ~= "table" then
        rebuild_weapon_names()
        return false
    end

    toolinfo = data
    recoil_weapons = {}
    for name, entry in pairs(data) do
        if type(entry) == "table" and (entry.Bullet or entry.Recoil or entry.Weapon) then
            table.insert(recoil_weapons, name)
        end
    end
    table.sort(recoil_weapons)
    rebuild_weapon_names()
    loaded = #recoil_weapons > 0
    return loaded
end

function M.get(name)
    if not loaded then M.load() end
    return toolinfo[name]
end

function M.recoil_weapon_names()
    if not loaded then M.load() end
    return recoil_weapons
end

function M.profile_weapon_names()
    if not loaded then M.load() end

    local farm = nil
    pcall(function()
        farm = April.require("game.farm_tools")
        if farm and farm.load then farm.load() end
    end)

    local seen = {}
    local list = {}

    local function add(name)
        if not name or name == "" or seen[name] then return end
        if not M.is_ranged_weapon_name(name) then return end
        if farm and farm.is_farm_tool_name and farm.is_farm_tool_name(name) then return end
        seen[name] = true
        list[#list + 1] = name
    end

    for name in pairs(toolinfo) do
        add(name)
    end
    for name in pairs(FALLBACK_STATS) do
        add(name)
    end

    table.sort(list)
    return list
end

function M.get_held_weapon_name()
    rebuild_weapon_names()

    local lp = env.get_local_player()
    if not lp then return nil end

    local name, inst = find_held_in_character(lp)
    if name then return name end

    name = find_held_in_viewmodels()
    if name then return name end

    if lp.tool_name and lp.tool_name ~= "" then
        if M.is_weapon_name(lp.tool_name) or loaded then
            return lp.tool_name
        end
    end

    return nil
end

function M.get_held_tool()
    local lp = env.get_local_player()
    if not lp then return nil, nil end
    local name, inst = find_held_in_character(lp)
    if name then return name, inst end
    name = find_held_in_viewmodels()
    return name, nil
end

function M.drop_gravity(grav)
    if not grav or grav <= 0 then return ROBLOX_GRAV * 0.55 end
    if grav <= 2 then return grav * ROBLOX_GRAV end
    return grav
end

function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end

    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 950,
            gravity = entry.Bullet.Gravity or 0.55,
            name = name,
            from_toolinfo = true,
            is_bow = M.is_bow_weapon_name(name),
        }
    end

    local fb = FALLBACK_STATS[name]
    if fb then
        return {
            speed = fb.speed,
            gravity = fb.gravity,
            name = name,
            from_fallback = true,
            is_bow = M.is_bow_weapon_name(name),
        }
    end

    local _, tool_inst = M.get_held_tool()
    if tool_inst then
        local from_attrs = read_tool_attributes(tool_inst)
        if from_attrs then
            from_attrs.name = name
            return from_attrs
        end
    end

    return { speed = 950, gravity = 0.55, name = name }
end

function M.tick()
    local in_game = M.in_game_ready()

    if not in_game then
        if M._was_in_game then
            M._last_held = nil
            M._last_held_ranged = nil
            M._weapon_changed_at = 0
        end
        M._was_in_game = false
        return nil
    end

    if not M._was_in_game then
        M._was_in_game = true
        M.load()
    end

    if not loaded and bootstrap.is_ready and bootstrap.is_ready() then
        M.load()
    end

    local held = M.get_held_ranged_weapon_name()
    if held ~= M._last_held_ranged then
        M._last_held = held
        M._last_held_ranged = held
        M._weapon_changed_at = utility and utility.get_tick_count and utility.get_tick_count() or 0
        pcall(function()
            local origin = April.require("game.combat_origin")
            if origin.invalidate then origin.invalidate() end
        end)
        pcall(function()
            local gun_mods = April.require("features.combat.gun_mods")
            if gun_mods.on_weapon_changed then
                gun_mods.on_weapon_changed(held)
            end
        end)
    end

    return held
end

function M.on_modules_ready()
    M.load()
    pcall(function()
        farm_tools = April.require("game.farm_tools")
        if farm_tools.invalidate then farm_tools.invalidate() end
        if farm_tools.load then farm_tools.load() end
    end)
    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        if gun_mods.on_modules_ready then
            gun_mods.on_modules_ready()
        end
    end)
end

return M

end)()

-- ── game/gc_weapon_mods.lua ──
April._mods["game.gc_weapon_mods"] = (function()
-- GC weapon multipliers. Skip refreshgc when warm; rate-limit applygc.
local debug = April.require("core.debug")
local env = April.require("core.env")

local M = {}

M.WEAPON_FIND_KEYS = {
    "RecoilMult",
    "RangeMult",
    "SpeedMult",
    "AimSpreadMult",
    "HipSpreadMult",
    "SwayMult",
    "FireRateMult",
}

M.ALLOWED = {
    RecoilMult = true,
    RangeMult = true,
    SpeedMult = true,
    AimSpreadMult = true,
    HipSpreadMult = true,
    SwayMult = true,
    FireRateMult = true,
}

M._last_node_count = 0
M._last_apply_ms = 0
M._last_refresh_ms = 0
M._fail_streak = 0
M._session_token = nil
M._disabled_until = 0

local MIN_APPLY_GAP_MS = 450
local MIN_REFRESH_GAP_MS = 5000
local FAIL_BACKOFF_MS = 1500
local MAX_FAIL_STREAK = 8
local COOLDOWN_MS = 15000

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
end

local function session_token()
    if not game then return "none" end
    local pid = game.place_id or 0
    local gid = game.game_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return tostring(pid) .. ":" .. tostring(gid) .. ":" .. tostring(ws_addr)
end

function M.available()
    return has_api()
end

function M.last_node_count()
    return M._last_node_count
end

function M.in_game()
    return env.get_local_player() ~= nil
end

function M.cooldown_remaining_ms()
    local now = tick_ms()
    if M._disabled_until <= now then return 0 end
    return M._disabled_until - now
end

local function note_failure(reason)
    M._fail_streak = M._fail_streak + 1
    if M._fail_streak >= MAX_FAIL_STREAK then
        M._disabled_until = tick_ms() + COOLDOWN_MS
        M._fail_streak = 0
        M._last_node_count = 0
        debug.warn_once("gun_mods:cooldown", "Gun mods paused after repeated GC failures: " .. tostring(reason))
    end
end

local function note_success(patched)
    M._fail_streak = 0
    M._disabled_until = 0
    if patched and patched > 0 then
        M._last_node_count = math.max(M._last_node_count, patched)
    end
end

local function sanitize_payload(mods)
    local out = {}
    for k, v in pairs(mods) do
        if M.ALLOWED[k] and v ~= nil then
            out[k] = tonumber(v) or v
        end
    end
    return out
end

local function keys_for_payload(payload)
    local keys = {}
    for k in pairs(payload) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function warm_nodes(keys)
    local count = 0
    local ok, result = pcall(getgc, keys)
    if ok and type(result) == "number" then
        count = result
    end
    return count
end

local function maybe_refresh(force)
    local now = tick_ms()
    local tok = session_token()
    if tok ~= M._session_token then
        M._session_token = tok
        M._last_node_count = 0
        force = true
    end

    if not force and M._last_node_count > 0 then
        return
    end
    if not force and (now - M._last_refresh_ms) < MIN_REFRESH_GAP_MS then
        return
    end

    pcall(refreshgc)
    M._last_refresh_ms = now
end

function M.apply_weapon(mods, opts)
    opts = opts or {}
    if not has_api() then
        return false, 0, "GC API unavailable"
    end

    local now = tick_ms()
    if M._disabled_until > now then
        return false, 0, "GC cooling down"
    end

    local payload = sanitize_payload(mods)
    if not next(payload) then
        return false, 0, "No modifiers selected"
    end

    if not M.in_game() then
        return false, 0, "Enter a match first"
    end

    local gap = MIN_APPLY_GAP_MS
    if M._fail_streak > 2 then
        gap = FAIL_BACKOFF_MS
    end
    if not opts.force and (now - M._last_apply_ms) < gap then
        return false, 0, "throttled"
    end

    maybe_refresh(opts.force_refresh == true or M._last_node_count <= 0)

    local patch_keys = keys_for_payload(payload)
    local warm = warm_nodes(patch_keys)
    M._last_node_count = math.max(M._last_node_count, warm)

    if warm <= 0 then
        note_failure("no nodes")
        debug.warn_once("gun_mods:nodes", "GC still warming - equip a gun, enable a mod option, keep master on")
        return false, 0, "GC warming - equip gun and wait a moment"
    end

    local patched = 0
    local ok, result = pcall(applygc, patch_keys, payload)
    if ok and type(result) == "number" then
        patched = result
    elseif not ok then
        note_failure(result)
        return false, 0, "GC apply failed"
    end

    M._last_apply_ms = tick_ms()

    if patched > 0 then
        note_success(patched)
        return true, patched, string.format("%d node(s) patched", patched)
    end

    note_failure("zero patch")
    if M._fail_streak == 1 then
        M._last_node_count = 0
    end
    return false, 0, "GC warming - equip gun and wait a moment"
end

function M.apply(mods)
    return M.apply_weapon(mods)
end

function M.apply_once(mods)
    return M.apply_weapon(mods, { force = true })
end

function M.apply_cached(mods)
    return M.apply_weapon(mods)
end

function M.refresh_cache()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end

    maybe_refresh(true)
    local count = warm_nodes(M.WEAPON_FIND_KEYS)
    M._last_node_count = count
    return count
end

function M.probe_on_load()
    if not has_api() then return 0 end
    if not M.in_game() then return 0 end
    return M.refresh_cache()
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    local cd = M.cooldown_remaining_ms()
    if cd > 0 then
        return string.format("GC cooling down (%ds)", math.ceil(cd / 1000))
    end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M

end)()

-- ── game/gun_mod_profiles.lua ──
April._mods["game.gun_mod_profiles"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")

local M = {}

local DEFAULT = {
    recoil = false,
    recoil_pct = 100,
    spread = false,
    spread_pct = 100,
    sway = false,
    fire_rate = false,
    fire_rate_mult = 1.5,
    speed = false,
    speed_mult = 100,
    range = false,
    range_mult = 10,
    double_tap = false,
}

local SETTING_KEYS = {
    recoil = "april_gm_recoil",
    recoil_pct = "april_gm_recoil_pct",
    spread = "april_gm_spread",
    spread_pct = "april_gm_spread_pct",
    sway = "april_gm_sway",
    fire_rate = "april_gm_fire_rate",
    fire_rate_mult = "april_gm_fire_rate_mult",
    speed = "april_gm_speed",
    speed_mult = "april_gm_speed_mult",
    range = "april_gm_range",
    range_mult = "april_gm_range_mult",
    double_tap = "april_gm_double_tap",
}

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.fire_rate_mult(slider)
    slider = math.max(1, math.min(3, tonumber(slider) or 1.5))
    local t = (slider - 1) / 2
    return 0.12 + t * (0.99 - 0.12)
end

function M.read_settings()
    local profile = {}
    for field, default in pairs(DEFAULT) do
        profile[field] = default
    end
    for field, id in pairs(SETTING_KEYS) do
        local default = DEFAULT[field]
        if type(default) == "boolean" then
            profile[field] = settings.bool(id, default)
        elseif type(default) == "number" and math.floor(default) == default then
            profile[field] = settings.num(id, default)
        else
            profile[field] = tonumber(settings.get(id, default)) or default
        end
    end
    return profile
end

function M.profile_has_active_mods(profile)
    if not profile then return false end
    return profile.recoil or profile.spread or profile.sway
        or profile.fire_rate or profile.speed or profile.range
        or profile.double_tap
end

function M.editor_has_active_mods()
    return M.profile_has_active_mods(M.read_settings())
end

function M.build_mods_from_profile(profile)
    local mods = {}
    if not profile then return mods end

    if profile.recoil then
        mods.RecoilMult = pct_to_neg_mult(profile.recoil_pct)
    end
    if profile.spread then
        local m = pct_to_neg_mult(profile.spread_pct)
        mods.AimSpreadMult = m
        mods.HipSpreadMult = m
    end
    if profile.sway then
        mods.SwayMult = -1
    end
    if profile.fire_rate then
        mods.FireRateMult = M.fire_rate_mult(profile.fire_rate_mult)
    end
    if profile.speed then
        mods.SpeedMult = profile.speed_mult or 100
    end
    if profile.range then
        mods.RangeMult = profile.range_mult or 10
    end

    return mods
end

function M.build_toolinfo_opts(profile)
    if not profile then
        return { double_tap = false }
    end
    return { double_tap = profile.double_tap == true }
end

function M.build_reset_mods()
    return {
        RecoilMult = 0,
        AimSpreadMult = 0,
        HipSpreadMult = 0,
        SwayMult = 0,
        FireRateMult = 0,
        SpeedMult = 0,
        RangeMult = 0,
    }
end

function M.held_weapon_name()
    return weapons.get_held_ranged_weapon_name()
end

function M.build_mods_for_apply(_held)
    if not M.editor_has_active_mods() then return nil end
    return M.build_mods_from_profile(M.read_settings())
end

function M.build_toolinfo_for_apply(held)
    if not M.editor_has_active_mods() then return nil, nil end
    return M.build_toolinfo_opts(M.read_settings()), held
end

function M.should_apply_for_held(held)
    if not held then return false end
    return M.editor_has_active_mods()
end

return M

end)()

-- ── game/combat_stats.lua ──
April._mods["game.combat_stats"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")

local M = {}

local function inventory_mod()
    return April.require("game.inventory")
end

local function profile_speed_mult()
    if not settings.enabled("april_gunmods_enabled") then return 0 end
    if not settings.enabled("april_gm_speed") then return 0 end
    return settings.num("april_gm_speed_mult", 100)
end

local function ammo_modifiers()
    local inv = inventory_mod()
    if not inv or not inv.get_equipped_ammo_stats then
        return 1, 1
    end
    local ammo = inv.get_equipped_ammo_stats()
    if not ammo then return 1, 1 end
    return ammo.speed_mult or 1, ammo.gravity_mult or 1
end

function M.get_effective_stats(weapon_name)
    weapon_name = weapon_name or weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local base = weapons.get_weapon_stats(weapon_name)
    if not base then
        base = { speed = 950, gravity = 0.55, name = weapon_name or "Unknown" }
    end

    local speed = base.speed or 950
    local gravity = base.gravity or 0.55
    local is_bow = base.is_bow
        or (weapon_name and (weapon_name:find("Bow", 1, true) or weapon_name:find("Crossbow", 1, true)))

    local sm = profile_speed_mult()
    if sm ~= 0 then
        speed = speed * (1 + sm)
    end

    local ammo_speed, ammo_grav = ammo_modifiers()
    speed = speed * ammo_speed
    gravity = gravity * ammo_grav

    return {
        speed = speed,
        gravity = gravity,
        name = weapon_name or base.name,
        is_bow = is_bow == true,
        base_speed = base.speed,
        speed_mult = sm,
        ammo_speed_mult = ammo_speed,
        ammo_gravity_mult = ammo_grav,
    }
end

return M

end)()

-- ── game/combat_origin.lua ──
April._mods["game.combat_origin"] = (function()
local env = April.require("core.env")
local weapons = April.require("game.weapons")

local M = {}

local frame = { t = 0, weapon = nil, muzzle = nil, server = nil }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if p and p.x ~= nil then
        return { x = p.x, y = p.y, z = p.z }
    end
    return nil
end

local function vec3_from_cf(cf)
    if not cf then return nil end
    local pos = cf.Position or cf.position
    if pos and pos.x ~= nil then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

local function camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

local function viewmodel_cframe_origin()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end

    local cc = find_child(char, "CameraController")
    if not cc then return nil end

    local cf = env.safe_call(function() return cc:GetAttribute("ViewmodelCFrame") end)
    if not cf then return nil end

    local pos = vec3_from_cf(cf)
    if not pos then return nil end

    local look = cf.LookVector or cf.lookVector
    if look and look.x then
        return {
            x = pos.x + look.x * 0.5,
            y = pos.y + look.y * 0.5,
            z = pos.z + look.z * 0.5,
        }
    end
    return pos
end

local function find_flash_in(model)
    if not model then return nil end
    local flash = find_child(model, "FlashPart") or find_child(model, "Flash")
    if flash then return part_pos(flash) end
    local weapon = find_child(model, "Weapon")
    if weapon then
        flash = find_child(weapon, "FlashPart") or find_child(weapon, "Flash")
        if flash then return part_pos(flash) end
    end
    local desc = env.safe_call(function()
        if model.get_descendants then return model:get_descendants() end
        return model:GetDescendants()
    end) or {}
    for _, d in ipairs(desc) do
        local n = d.Name or d.name
        if n == "FlashPart" or n == "Flash" then
            return part_pos(d)
        end
    end
    return nil
end

local function camera_viewmodel()
    local ws = env.get_workspace()
    if not ws then return nil end
    local cam = env.safe_call(function()
        return ws.CurrentCamera or ws.currentCamera
            or (ws.FindFirstChild and ws:FindFirstChild("CurrentCamera"))
    end)
    if not cam then return nil end
    local kids = env.safe_call(function()
        if cam.get_children then return cam:get_children() end
        return cam:GetChildren()
    end) or {}
    for _, child in ipairs(kids) do
        local cn = child.ClassName or child.class_name
        if cn == "Model" then
            if find_child(child, "Weapon") or find_child(child, "Arms") then
                return child
            end
        end
    end
    return nil
end

local function flashpart_origin()
    -- Live VM is parented to CurrentCamera (ViewmodelController), not workspace.Viewmodels
    local live = camera_viewmodel()
    local pos = find_flash_in(live)
    if pos then return pos end

    local ws = env.get_workspace()
    if not ws then return nil end

    local vfx = find_child(ws, "VFX")
    local vms = vfx and find_child(vfx, "VMs")
    if vms then
        local kids = env.safe_call(function()
            if vms.get_children then return vms:get_children() end
            return vms:GetChildren()
        end) or {}
        for _, child in ipairs(kids) do
            pos = find_flash_in(child)
            if pos then return pos end
        end
    end

    -- Legacy fallback
    local legacy = find_child(ws, "Viewmodels")
    if legacy then
        local vm = find_child(legacy, "Viewmodel") or find_child(legacy, "ViewModel")
        pos = find_flash_in(vm)
        if pos then return pos end
    end

    return nil
end

local function compute_muzzle(weapon)
    local flash = flashpart_origin()
    if flash then return flash end

    local cframe = viewmodel_cframe_origin()
    if cframe then return cframe end

    if weapon and weapons.is_bow_weapon_name(weapon) then
        return camera_origin()
    end

    return camera_origin()
end

local function compute_server()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.position then
        return { x = lp.position.x, y = lp.position.y, z = lp.position.z }
    end

    local char = lp.character
    if char and env.is_valid(char) then
        return part_pos(find_child(char, "HumanoidRootPart"))
    end

    return nil
end

function M.invalidate()
    frame.t = 0
    frame.weapon = nil
    frame.muzzle = nil
    frame.server = nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held_ranged()
    local now = tick_ms()
    if frame.t == now and frame.weapon == weapon and frame.muzzle then
        return
    end
    frame.t = now
    frame.weapon = weapon
    frame.muzzle = compute_muzzle(weapon)
    frame.server = compute_server()
end

function M.get_muzzle_origin()
    M.sync_weapon()
    return frame.muzzle
end

function M.get_server_origin()
    M.sync_weapon()
    return frame.server
end

function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

function M.get_fire_origin()
    M.sync_weapon()
    return frame.muzzle or frame.server
end

-- HumanoidRootPart is above the feet; drop to just under the feet for terrain-valid rays.
local HRP_TO_FEET = 2.85
local BELOW_FEET = 0.45

function M.get_feet_below_origin()
    local body = M.get_server_origin()
    if not body then return nil end
    return {
        x = body.x,
        y = body.y - HRP_TO_FEET - BELOW_FEET,
        z = body.z,
    }
end

return M

end)()

-- ── game/team_state.lua ──
April._mods["game.team_state"] = (function()
-- Official Fallen party teams (TeamNavigationController) + Roblox Team fallback.
-- Dump: CharacterScripts.TeamNavigationController - InTeam / CanInvite attrs,
-- FetchTeam returns userId list, teammates get TeamHighlight on character.

local env = April.require("core.env")

local M = {}

local CACHE_MS = 250
local cache = {
    t = -1,
    in_team = false,
    members = {}, -- [userId] = true
    member_list = {},
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end

local function local_character()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character
    if char and env.is_valid(char) then return char end
    return nil
end

local function team_nav()
    local char = local_character()
    if not char then return nil end
    local tnc = find_child(char, "TeamNavigationController")
    if tnc and env.is_valid(tnc) then return tnc end
    return nil
end

local function add_member(set, list, uid)
    uid = tonumber(uid)
    if not uid or uid == 0 or set[uid] then return end
    set[uid] = true
    list[#list + 1] = uid
end

local function members_from_fetch(tnc)
    local fetch = find_child(tnc, "FetchTeam")
    if not fetch then return nil end

    local result = env.safe_call(function()
        if fetch.Invoke then return fetch:Invoke() end
        if fetch.invoke then return fetch:invoke() end
        return nil
    end)
    if type(result) ~= "table" then return nil end

    local set, list = {}, {}
    for _, v in pairs(result) do
        if v ~= "CantLeave" then
            add_member(set, list, v)
        end
    end
    return set, list
end

local function members_from_teamlist()
    local lp = env.get_local_player()
    if not lp then return nil end

    local player = env.safe_call(function()
        return game and game.local_player
    end)
    local pgui = player and find_child(player, "PlayerGui")
    local main = pgui and find_child(pgui, "Main")
    local team = main and find_child(main, "Team")
    local list_frame = team and find_child(team, "TeamList")
    if not list_frame then return nil end

    -- Resolve Member* TextLabels -> userIds via entity name match.
    local labels = {}
    for _, child in ipairs(env.safe_call(function()
        if list_frame.get_children then return list_frame:get_children() end
        return list_frame:GetChildren()
    end) or {}) do
        local n = child.Name or child.name
        if n and tostring(n):find("Member", 1, true) then
            local text = env.safe_call(function()
                return child.Text or child.text
            end)
            if text and text ~= "" and text ~= "..." then
                labels[#labels + 1] = text
            end
        end
    end
    if #labels == 0 then return nil end

    local set, list = {}, {}
    if not entity or not entity.get_players then return set, list end
    for _, p in ipairs(entity.get_players()) do
        local name = p.name
        local disp = p.display_name
        for i = 1, #labels do
            local lab = labels[i]
            if name == lab or disp == lab then
                add_member(set, list, p.user_id)
                break
            end
        end
    end
    return set, list
end

local function refresh()
    local now = tick_ms()
    if cache.t >= 0 and (now - cache.t) < CACHE_MS then
        return
    end
    cache.t = now
    cache.in_team = false
    cache.members = {}
    cache.member_list = {}

    local tnc = team_nav()
    if not tnc then return end

    local in_team = attr(tnc, "InTeam")
    cache.in_team = in_team == true

    local set, list = members_from_fetch(tnc)
    if not set then
        set, list = members_from_teamlist()
    end
    if set then
        cache.members = set
        cache.member_list = list or {}
        if next(set) then
            cache.in_team = true
        end
    end
end

function M.invalidate()
    cache.t = -1
end

function M.in_party()
    refresh()
    return cache.in_team == true
end

function M.party_members()
    refresh()
    return cache.members
end

function M.has_team_highlight(player)
    if not player or not player.character then return false end
    local char = player.character
    if not env.is_valid(char) then return false end
    local hl = find_child(char, "TeamHighlight")
    return hl ~= nil and env.is_valid(hl)
end

function M.is_party_teammate(player)
    if not player or player.is_local then return false end
    refresh()

    local uid = tonumber(player.user_id)
    if uid and cache.members[uid] then
        return true
    end

    -- Highlight is only cloned onto party mates by TeamNavigationController.
    if cache.in_team and M.has_team_highlight(player) then
        return true
    end

    return false
end

function M.same_roblox_team(player)
    if not player then return false end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if not lp then return false end
    if not lp.has_team or not player.has_team then return false end
    if not lp.team or not player.team or lp.team == "" or player.team == "" then
        return false
    end
    return lp.team == player.team
end

-- True if target should be skipped by team check (is ally).
function M.is_teammate(player)
    if not player or player.is_local then return true end
    if M.is_party_teammate(player) then return true end
    if M.same_roblox_team(player) then return true end
    return false
end

return M

end)()

-- ── game/player_state.lua ──
April._mods["game.player_state"] = (function()
-- Player ESP state from DataModel.Players.<Name> attributes.
-- Vector: inst:get_attribute / get_attributes
--   string  -> string
--   bool    -> boolean
--   Color3  -> table { r, g, b }  (0-1, sometimes 0-255)
-- ClanTag string can also appear on Character.NameTag - that is NOT enough for
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

-- Do NOT gate on utility.is_valid - it can reject valid Players instances
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

-- Vector docs: Color3 attrs -> {r,g,b}; GuiObject TextColor3 -> {R,G,B} (often 0-255).
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

    -- NameTag only fills missing ClanTag string - never invents VIP/color.
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

end)()

-- ── game/farm_tools.lua ──
April._mods["game.farm_tools"] = (function()
local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}

local loaded = false
local farm_tools = {}

local FALLBACK_GATHER_TOOLS = {
    ["Stone Hatchet"] = true,
    ["Iron Shard Hatchet"] = true,
    ["Steel Axe"] = true,
    Chainsaw = true,
    ["Stone Pickaxe"] = true,
    ["Iron Shard Pickaxe"] = true,
    ["Steel Pickaxe"] = true,
    ["Mining Drill"] = true,
    ["Bone Tool"] = true,
    ["Candy Cane"] = true,
    ["Carrot Blade"] = true,
    ["Halloween Scythe"] = true,
    Boulder = true,
}

local NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "chainsaw", "mining drill", "bone tool",
    "candy cane", "carrot blade", "halloween scythe", "boulder",
}

-- MeleeChecks reach from ToolInfo dump (RaycastUtil MouseRaycast / HitMelee).
local MELEE_RANGE = {
    ["Stone Hatchet"] = 5,
    ["Iron Shard Hatchet"] = 5,
    ["Steel Axe"] = 5.5,
    Chainsaw = 6.5,
    ["Stone Pickaxe"] = 5,
    ["Iron Shard Pickaxe"] = 5,
    ["Steel Pickaxe"] = 5.5,
    ["Mining Drill"] = 6.5,
    ["Bone Tool"] = 5,
    ["Candy Cane"] = 5,
    ["Carrot Blade"] = 5,
    ["Halloween Scythe"] = 5.5,
    Boulder = 4.5,
}

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function entry_can_gather(entry)
    if not entry or not entry.Melee then return false end
    local od = entry.ObjectDamages
    if not od then return false end
    return od.Trees ~= nil or od.Nodes ~= nil
end

local function normalize(name)
    if not name or name == "" then return nil end
    return name
end

local function name_hint_match(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

function M.load()
    if loaded then return true end

    farm_tools = {}
    for name in pairs(FALLBACK_GATHER_TOOLS) do
        farm_tools[name] = true
    end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) == "table" then
        for name, entry in pairs(data) do
            if type(name) == "string" and entry_can_gather(entry) then
                farm_tools[name] = true
            end
        end
    end

    loaded = true
    return next(farm_tools) ~= nil
end

function M.invalidate()
    loaded = false
    farm_tools = {}
end

function M.is_farm_tool_name(name)
    name = normalize(name)
    if not name then return false end
    if not loaded then M.load() end
    if farm_tools[name] then return true end
    return name_hint_match(name)
end

local function pick_farm_name(name)
    if M.is_farm_tool_name(name) then return name end
    return nil
end

local function scan_children(list)
    if not list then return nil end
    for _, child in ipairs(list) do
        local hit = pick_farm_name(inst_name(child))
        if hit then return hit end
    end
    return nil
end

function M.get_held_farm_tool_name()
    if not loaded then M.load() end

    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.character
    if char and env.is_valid(char) then
        local hit = scan_children(env.safe_call(function() return char:get_children() end))
        if hit then return hit end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
            or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if inst_name(vm) == "Viewmodel" then
                    local hit = scan_children(env.safe_call(function() return vm:get_children() end))
                    if hit then return hit end
                end
            end
        end
    end

    return pick_farm_name(lp.tool_name)
end

function M.holding_farm_tool()
    return M.get_held_farm_tool_name() ~= nil
end

local function box_reach(box)
    if not box then return nil end
    local sz = box.Size or box.size
    if sz then
        local r = sz.X or sz.x
        if r and r > 0 then return r end
    end
    local mag = box.Magnitude
    if type(mag) == "number" and mag > 0 then
        return mag
    end
    return nil
end

function M.melee_range(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return 5 end

    local cached = MELEE_RANGE[tool_name]
    if cached then return cached end

    local data = bootstrap.get_module("ToolInfo")
    local entry = data and data[tool_name]
    local checks = entry and entry.Melee and entry.Melee.MeleeChecks
    if type(checks) == "table" then
        local best = 0
        for i = 1, #checks do
            local row = checks[i]
            local reach = row and box_reach(row[2])
            if reach and reach > best then
                best = reach
            end
        end
        if best > 0 then
            return best
        end
    end

    return 5
end

function M.all_names()
    if not loaded then M.load() end
    local out = {}
    for name in pairs(farm_tools) do
        out[#out + 1] = name
    end
    table.sort(out)
    return out
end

return M

end)()

-- ── game/farm_targets.lua ──
April._mods["game.farm_targets"] = (function()
--[[
  Gather hit parts near the player - dump hierarchy:
  Nodes: NodeSpark.Main | Trees: TreeX.Main | Plants: Main+Item | Cactus: CactusPart
]]

local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if not p or p.x == nil then return nil end
    return p
end

local function dist2(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function main_from(container)
    if not container or not env.is_valid(container) then return nil end
    local main = env.safe_call(function() return container.PrimaryPart end)
    if main and env.is_valid(main) then return main end
    return find_child(container, "Main")
end

function M.hit_part_from_model(model)
    if not env.is_valid(model) then return nil end

    local spark = find_child(model, "NodeSpark")
    if spark and env.is_valid(spark) then
        return main_from(spark)
    end

    local tree_x = find_child(model, "TreeX")
    if tree_x and env.is_valid(tree_x) then
        return main_from(tree_x)
    end

    if find_child(model, "Item") then
        return main_from(model)
    end

    return find_child(model, "CactusPart")
end

local FOLDER_SPECS = {
    { key = "nodes", max = 120 },
    { key = "plants", max = 80 },
    { trees = true, max = 120 },
}

local function folder_for(spec)
    if spec.trees then
        return folders.get_folder("Trees")
    end
    return folders.from_key(spec.key)
end

-- Only return harvest parts within range of origin (avoids scanning the whole map into RAM).
function M.collect_near(origin, radius, out, max_out)
    out = out or {}
    max_out = max_out or 32
    if not origin or radius <= 0 then return out end

    local limit2 = (radius + 8) * (radius + 8)

    for s = 1, #FOLDER_SPECS do
        if #out >= max_out then break end
        local spec = FOLDER_SPECS[s]
        local folder = folder_for(spec)
        if env.is_valid(folder) then
            for _, model in ipairs(folders.scan_children(folder, "Model", spec.max)) do
                if #out >= max_out then break end
                local part = M.hit_part_from_model(model)
                local pos = part_pos(part)
                if pos and dist2(pos, origin) <= limit2 then
                    out[#out + 1] = part
                end
            end
        end
    end

    return out
end

return M

end)()

-- ── game/inventory.lua ──
April._mods["game.inventory"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")

local M = {}

function M.get_local_inventory()
    local lp = env.get_local_player()
    if not lp or not lp.character then return nil end
    local char = lp.character
    if not env.is_valid(char) then return nil end
    local ic = env.safe_call(function() return char:find_first_child("InventoryController") end)
    if not ic then return nil end
    local fetch = env.safe_call(function() return ic:find_first_child("Fetch") end)
    if not fetch or not fetch.Invoke then return nil end
    local ok, inv, toolbar, armor = pcall(function() return fetch:Invoke() end)
    if not ok or not inv then return nil end
    return { inventory = inv, toolbar = toolbar, armor = armor }
end

function M.resolve_item_name(id)
    if type(id) ~= "number" then return tostring(id) end

    local row = item_catalog.get(id)
    if row and row.name then return row.name end

    local rep = env.get_replicated_storage()
    if not rep then return "Item#" .. id end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
    if items_mod then
        local ok, data = pcall(function() return require(items_mod) end)
        if ok and data and data[id] and data[id].Name then
            return data[id].Name
        end
    end
    return "Item#" .. id
end

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then return inst:GetAttribute(key) end
    if inst.get_attribute then return inst:get_attribute(key) end
    return nil
end

local function find_child(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.get_toolbar_entry(char)
    if not char or not env.is_valid(char) then return nil, nil end

    local ic = find_child(char, "InventoryController")
    if not ic then return nil, nil end

    local fetch = env.safe_call(function()
        if ic.find_first_child then return ic:find_first_child("Fetch") end
        return ic:FindFirstChild("Fetch")
    end)
    if not fetch or not fetch.Invoke then return nil, nil end

    local slot = read_attribute(find_child(char, "EquipController"), "Equipped")
    if type(slot) ~= "number" or slot <= 0 then
        slot = read_attribute(find_child(char, "ViewmodelController"), "Equipped")
    end
    if type(slot) ~= "number" or slot <= 0 then return nil, nil end

    local ok, data = pcall(function() return fetch:Invoke() end)
    if not ok or type(data) ~= "table" then return nil, nil end

    local toolbar = data.Toolbar or data.toolbar
    if type(toolbar) ~= "table" then return nil, nil end

    local entry = toolbar[slot]
    if not entry or entry == 0 then return nil, nil end
    if type(entry) == "table" and entry.Amount and entry.Amount <= 0 then return nil, nil end

    return entry, slot
end

function M.get_equipped_ammo_stats()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end

    local entry = M.get_toolbar_entry(char)
    if not entry or type(entry) ~= "table" then return nil end

    local ammo = entry.Ammo
    if not ammo or type(ammo) ~= "table" then return nil end

    local ammo_id = ammo.ID
    if type(ammo_id) ~= "number" then return nil end

    items.load()
    local row = items.get_by_id and items.get_by_id(ammo_id)
    if row and row.AmmoStats then return row.AmmoStats end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[ammo_id] and data[ammo_id].AmmoStats then
                return data[ammo_id].AmmoStats
            end
        end
    end

    return nil
end

function M.get_toolbar_held_name(char)
    local entry = M.get_toolbar_entry(char)
    if not entry then return nil end

    local id = type(entry) == "table" and entry.ID or entry
    if type(id) ~= "number" then return nil end

    return M.resolve_item_name(id)
end

function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end
    if lp.tool_name and lp.tool_name ~= "" then return lp.tool_name end

    local char = lp.character
    if not char or not env.is_valid(char) then return nil end

    local toolbar_name = M.get_toolbar_held_name(char)
    if toolbar_name and toolbar_name ~= "" then return toolbar_name end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if child.ClassName == "Tool" then return child.Name end
    end
    return nil
end

return M

end)()

-- ── game/player_gear.lua ──
April._mods["game.player_gear"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
local inventory = April.require("game.inventory")
local weapons = April.require("game.weapons")
local attachment_images = April.require("game.attachment_images")

local M = {}

local ARMOR_ATTRIBUTES = {
    "ResistWet",
    "HasFlippers",
    "HasTank",
    "HasGoggles",
    "NVG",
    "SilentSteps",
    "WaterFilter",
    "SteelToes",
    "Snorkle",
}

local ATTACHMENT_SLOT_HINTS = {
    ["p1"] = true, ["p2"] = true, ["p3"] = true, ["p4"] = true,
    ["slot1"] = true, ["slot2"] = true, ["slot3"] = true,
    ["sight"] = true, ["muzzle"] = true, ["underbarrel"] = true,
    ["barrel"] = true, ["magazine"] = true,
}

local EMPTY_HELD_NAMES = {
    ["hand"] = true, ["hands"] = true, ["fist"] = true, ["fists"] = true,
    ["unarmed"] = true, ["nothing"] = true, ["none"] = true, ["empty"] = true,
    ["hair"] = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then
        return inst:GetAttribute(key)
    end
    if inst.get_attribute then
        return inst:get_attribute(key)
    end
    return nil
end

local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end

local function is_empty_held_name(name)
    if not name or name == "" then return true end
    return EMPTY_HELD_NAMES[name:lower()] == true
end

local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
end

local function is_armor_child_name(name)
    if not name or name == "" then return true end
    if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then return true end
    if name:find("Armor", 1, true) and name:find("/", 1, true) then return true end
    return false
end

local function is_attachment_name(name)
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end

    local base = select(1, parse_variant_name(name))
    local row = item_catalog.get_by_name(base)
    if row and row.type == "Attachment" then return true end

    local t = items.get_type(base)
    return t == "Attachment"
end

local function is_valid_held_label(name)
    if is_empty_held_name(name) then return false end
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end
    if is_armor_child_name(name) then return false end
    if is_attachment_name(name) then return false end
    return true
end

local function looks_like_held_item(name)
    if not is_valid_held_label(name) then return false end
    if weapons.is_weapon_name(name) then return true end
    if items.is_held_display(name) then return true end
    return true
end

local function add_armor_piece(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    table.insert(out.armor, piece)
end

local function add_held_piece(out, label)
    if is_empty_held_name(label) then
        out.held = nil
        return false
    end
    if not is_valid_held_label(label) then return false end

    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end

    out.held = piece
    return true
end

local function add_attachment_piece(out, seen, label)
    if not label or label == "" then return end
    if is_attachment_slot_name(label) then return end
    if not is_attachment_name(label) then return end
    if seen[label] then return end

    seen[label] = true
    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end
    table.insert(out.attachments, piece)
end

local function try_armor_model(out, seen, name)
    if not name then return end

    if name:sub(1, 6) == "Armor_" then
        add_armor_piece(out, seen, items.resolve_armor_model(name))
        return
    end

    if name:sub(1, 6) == "Armor:" then
        add_armor_piece(out, seen, items.resolve_item_label(name:sub(7)))
    end
end

local function try_armor_attribute(out, seen, attr_key)
    if not attr_key or attr_key:sub(1, 6) ~= "Armor_" then return end

    local tail = attr_key:match("^Armor_(.+)$")
    if not tail then return end

    local piece = items.resolve_armor_model(attr_key)
    if piece then
        add_armor_piece(out, seen, piece)
        return
    end

    local row = item_catalog.get_by_attribute(tail)
    if row and row.name then
        if tail == "ResistWet" and (seen["Hazmat Suit"] or seen["Wetsuit"]) then
            return
        end
        add_armor_piece(out, seen, items.make_piece(row.name, nil))
    end
end

local function scan_armor_attributes(inst, out, seen)
    for _, attr in ipairs(ARMOR_ATTRIBUTES) do
        local key = "Armor_" .. attr
        if read_attribute(inst, key) then
            try_armor_attribute(out, seen, key)
        end
    end

    local attrs = env.safe_call(function()
        if inst.get_attributes then return inst:get_attributes() end
        if inst.GetAttributes then return inst:GetAttributes() end
    end)

    if type(attrs) == "table" then
        for key in pairs(attrs) do
            if type(key) == "string" then
                try_armor_attribute(out, seen, key)
            end
        end
    end
end

local function scan_sleeves_string(out, seen, sleeves)
    if not sleeves or sleeves == "" then return end
    for entry in sleeves:gmatch("[^%^]+") do
        entry = entry:match("^%s*(.-)%s*$")
        if entry and entry ~= "" then
            add_armor_piece(out, seen, items.resolve_item_label(entry))
        end
    end
end

local function resolve_character(player)
    if player.character and env.is_valid(player.character) then
        return player.character
    end

    if player.player and env.is_valid(player.player) then
        local char = env.safe_call(function()
            local pl = player.player
            if pl.Character then return pl.Character end
            if pl.character then return pl.character end
        end)
        if char and env.is_valid(char) then return char end
    end

    if player.name and game and game.workspace then
        local char = env.safe_call(function()
            if game.workspace.find_first_child then
                return game.workspace:find_first_child(player.name)
            end
        end)
        if char and env.is_valid(char) then return char end
    end

    return nil
end

local function resolve_player_inst(player)
    if player.player and env.is_valid(player.player) then
        return player.player
    end
    if not player.name or not game or not game.players then return nil end
    return env.safe_call(function()
        if game.players.find_first_child then
            return game.players:find_first_child(player.name)
        end
    end)
end

local function find_inst_by_name(char, name)
    if not char or not name then return nil end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local child_name = child.Name or child.name
        if child_name == name then
            return child
        end
    end

    return nil
end

local function find_held_on_character(char)
    if not char then return nil, nil end

    local fallback = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local name = child.Name or child.name
        if not name or name == "" or is_armor_child_name(name) then goto continue end
        if not is_valid_held_label(name) then goto continue end

        if is_tool(child) then
            return name, child
        end

        local cn = child.ClassName or child.class_name
        if cn == "Model" and looks_like_held_item(name) then
            if weapons.is_weapon_name(name) or items.is_held_display(name) then
                return name, child
            end
            fallback = fallback or { name = name, inst = child }
        end

        ::continue::
    end

    if fallback then
        return fallback.name, fallback.inst
    end

    return nil, nil
end

local function resolve_held_weapon(player, char)
    if player.tool_name and player.tool_name ~= "" and is_valid_held_label(player.tool_name) then
        local inst = char and find_inst_by_name(char, player.tool_name) or nil
        return player.tool_name, inst
    end

    if char then
        local toolbar_name = inventory.get_toolbar_held_name(char)
        if toolbar_name and is_valid_held_label(toolbar_name) then
            local inst = find_inst_by_name(char, toolbar_name) or select(2, find_held_on_character(char))
            return toolbar_name, inst
        end

        local name, inst = find_held_on_character(char)
        if name then
            return name, inst
        end
    end

    if player.is_local then
        local name = weapons.get_held_weapon_name()
        if name and is_valid_held_label(name) then
            local inst = char and (find_inst_by_name(char, name) or select(2, find_held_on_character(char))) or nil
            return name, inst
        end
    end

    return nil, nil
end

local function find_attachments_folder(parent)
    if not parent or not env.is_valid(parent) then return nil end
    return env.safe_call(function()
        if parent.find_first_child then
            return parent:find_first_child("Attachments") or parent:find_first_child("attachments")
        end
        return parent:FindFirstChild("Attachments") or parent:FindFirstChild("attachments")
    end)
end

-- Fallen Ultimate pattern: Attachments:GetChildren() -> attachment item names only.
-- Do not recurse into attachment model internals (Vignette, Sight mesh parts, etc.).
local function scan_weapon_attachments_folder(folder, out, seen, depth)
    depth = depth or 0
    if not folder or not env.is_valid(folder) or depth > 4 then return end

    local children = env.safe_call(function()
        if folder.get_children then return folder:get_children() end
        if folder.GetChildren then return folder:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        local name = child.Name or child.name
        if not name or name == "" then goto continue end

        local cn = child.ClassName or child.class_name
        if cn == "StringValue" or cn == "stringvalue" then
            local val = child.Value or child.value
            if val and val ~= "" then
                add_attachment_piece(out, seen, val)
            end
            goto continue
        end

        if is_attachment_slot_name(name) then
            scan_weapon_attachments_folder(child, out, seen, depth + 1)
            goto continue
        end

        add_attachment_piece(out, seen, name)

        ::continue::
    end
end

local function scan_weapon_attachments(char, tool_inst, out, seen)
    if tool_inst and env.is_valid(tool_inst) then
        scan_weapon_attachments_folder(find_attachments_folder(tool_inst), out, seen)

        local weapon = env.safe_call(function()
            if tool_inst.find_first_child then return tool_inst:find_first_child("Weapon") end
            return tool_inst:FindFirstChild("Weapon")
        end)
        if weapon and env.is_valid(weapon) then
            scan_weapon_attachments_folder(find_attachments_folder(weapon), out, seen)
        end
        return
    end

    if not char then return end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if is_tool(child) or (child.ClassName or child.class_name) == "Model" then
            scan_weapon_attachments(char, child, out, seen)
        end
    end
end

local function scan_armor_tree(inst, out, seen, depth)
    if not inst or not env.is_valid(inst) or depth > 8 then return end

    local name = inst.Name or inst.name
    if name and name ~= "" then
        if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
            try_armor_model(out, seen, name)
        end
    end

    local children = env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        if inst.GetChildren then return inst:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        scan_armor_tree(child, out, seen, depth + 1)
    end
end

function M.is_empty_held_name(name)
    return is_empty_held_name(name)
end

function M.held_name(player)
    if not player then return nil end
    local char = resolve_character(player)
    local name = select(1, resolve_held_weapon(player, char))
    if name and is_valid_held_label(name) then return name end
    return nil
end

function M.held_name_from_character(char)
    if not char or not env.is_valid(char) then return nil end
    local name = select(1, find_held_on_character(char))
    if name and is_valid_held_label(name) then return name end
    return nil
end

function M.scan_player(player)
    local out = {
        held = nil,
        attachments = {},
        armor = {},
    }

    if not player then return out end

    local char = resolve_character(player)
    local held_name, tool_inst = resolve_held_weapon(player, char)

    if held_name then
        add_held_piece(out, held_name)
    end

    local att_seen = {}
    scan_weapon_attachments(char, tool_inst, out, att_seen)

    local seen = {}
    if char then
        scan_armor_tree(char, out, seen, 0)
        scan_armor_attributes(char, out, seen)
    end

    local pl = resolve_player_inst(player)
    if pl then
        scan_armor_attributes(pl, out, seen)
        scan_sleeves_string(out, seen, read_attribute(pl, "ArmorSleeves"))
    end

    return out
end

return M

end)()

-- ── game/npcs.lua ──
April._mods["game.npcs"] = (function()
local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

M.HOSTILE_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
}

function M.is_hostile_name(name)
    return name and M.HOSTILE_NAMES[name] == true
end

function M.kind(name)
    if name == "Soldier" then return "soldier" end
    if name == "Bruno" or name == "Boris" or name == "Brutus" then return "boss" end
    return nil
end

local function read_health(model)
    local hum = env.safe_call(function()
        if model.find_first_child_of_class then
            return model:find_first_child_of_class("Humanoid")
        end
        for _, child in ipairs(model:get_children()) do
            if child.ClassName == "Humanoid" then return child end
        end
        return nil
    end)
    if not hum then return nil end
    local hp = hum.Health or hum.health
    if hp and hp <= 0 then return nil end
    return hum
end

local function try_add_npc(out, model, seen)
    if not env.is_valid(model) then return end
    local cn = model.ClassName or model.class_name
    if cn ~= "Model" then return end

    local name = model.Name or model.name
    if not M.is_hostile_name(name) then return end

    local addr = model.Address or model.address or tostring(model)
    if seen[addr] then return end

    if not read_health(model) then return end

    local head = env.safe_call(function()
        return model:find_first_child("Head") or model:FindFirstChild("Head")
    end)
    if not head or not env.is_valid(head) then return end

    seen[addr] = true

    local pos = head.Position or head.position
    local entry = {
        inst = model,
        name = name,
        kind = M.kind(name),
        head = head,
    }
    if pos and pos.x then
        entry.lx = pos.x
        entry.ly = pos.y
        entry.lz = pos.z
    end
    table.insert(out, entry)
end

function M.begin_scan()
    return {
        monuments = nil,
        mi = 1,
        queue = {},
        qi = 1,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
    if not state.monuments then
        state.monuments = env.safe_call(function()
            local military = folders.from_key("military")
            if not env.is_valid(military) then return {} end
            return military:get_children()
        end) or {}
        state.mi = 1
        state.queue = {}
        state.qi = 1
    end

    local processed = 0

    while processed < batch do
        if state.qi > #state.queue then
            if state.mi > #state.monuments then
                return true
            end

            local monument = state.monuments[state.mi]
            state.mi = state.mi + 1
            processed = processed + 1

            if env.is_valid(monument) then
                table.insert(state.queue, { inst = monument, depth = 0 })
            end
            goto continue
        end

        local item = state.queue[state.qi]
        state.qi = state.qi + 1
        processed = processed + 1

        local container = item.inst
        if not env.is_valid(container) or item.depth > 4 then goto continue end

        try_add_npc(state.out, container, state.seen)

        local children = env.safe_call(function() return container:get_children() end) or {}
        for _, child in ipairs(children) do
            try_add_npc(state.out, child, state.seen)
            if item.depth < 4 and env.is_valid(child) then
                table.insert(state.queue, { inst = child, depth = item.depth + 1 })
            end
        end

        ::continue::
    end

    return false
end

function M.complete_scan(state)
    return state.out or {}
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    return M.complete_scan(state)
end

return M

end)()

-- ── game/turret_stats.lua ──
April._mods["game.turret_stats"] = (function()
local M = {}

M.ACTIVATION_RANGE = {
    ["Auto Turret"] = 100,
    ["Shotgun Turret"] = 110,
}

M.BULLET_RANGE = {
    ["Auto Turret"] = 150,
    ["Shotgun Turret"] = 14.25,
}

M.DAMAGE_RANGE = {
    ["Auto Turret"] = { 85, 150 },
    ["Shotgun Turret"] = { 9, 25 },
}

function M.activation_range(name)
    return M.ACTIVATION_RANGE[name]
end

return M

end)()

-- ── game/esp_maps.lua ──
April._mods["game.esp_maps"] = (function()
local M = {}

M.NODE_MAP = {
    ["Stone_Node"] = "april_stone_node",
    ["Metal_Node"] = "april_metal_node",
    ["Phosphate_Node"] = "april_phosphate_node",
}

M.NODE_LABELS = {
    ["Stone_Node"] = "Stone Node",
    ["Metal_Node"] = "Metal Node",
    ["Phosphate_Node"] = "Phosphate Node",
}

M.NODE_FOLDERS = { "vegetation", "nodes" }

M.PLANT_MAP = {
    ["Corn Plant"] = "april_corn_plant",
    ["Tomato Plant"] = "april_tomato_plant",
    ["Pumpkin Plant"] = "april_pumpkin_plant",
    ["Lemon Plant"] = "april_lemon_plant",
    ["Raspberry Plant"] = "april_raspberry_plant",
    ["Blueberry Plant"] = "april_blueberry_plant",
    ["Wool Plant"] = "april_wool_plant",
    ["Hemp Plant"] = "april_hemp_plant",
    ["Hemp"] = "april_hemp_plant",
}

M.PLANT_LABELS = {
    ["Corn Plant"] = "Corn Plant",
    ["Tomato Plant"] = "Tomato Plant",
    ["Pumpkin Plant"] = "Pumpkin Plant",
    ["Lemon Plant"] = "Lemon Plant",
    ["Raspberry Plant"] = "Raspberry Plant",
    ["Blueberry Plant"] = "Blueberry Plant",
    ["Wool Plant"] = "Wool Plant",
    ["Hemp Plant"] = "Hemp Plant",
    ["Hemp"] = "Hemp",
}

M.PLANT_FOLDERS = { "plants", "vegetation" }

M.ANIMAL_MAP = {
    ["PREFAB_ANIMAL_DEER"] = "april_deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "april_boar",
    ["PREFAB_ANIMAL_WOLF"] = "april_wolf",
    ["Deer"] = "april_deer",
    ["Wild Boar"] = "april_boar",
    ["WildBoar"] = "april_boar",
    ["Boar"] = "april_boar",
    ["Wolf"] = "april_wolf",
}

M.ANIMAL_LABELS = {
    ["PREFAB_ANIMAL_DEER"] = "Deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "Wild Boar",
    ["PREFAB_ANIMAL_WOLF"] = "Wolf",
    ["Deer"] = "Deer",
    ["Wild Boar"] = "Wild Boar",
    ["WildBoar"] = "Wild Boar",
    ["Boar"] = "Boar",
    ["Wolf"] = "Wolf",
}

M.ANIMAL_FOLDERS = { "animals" }

M.WORLD_TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_lemon_plant", label = "Lemon Plant", color = { 1, 0.95, 0.2, 1 } },
    { id = "april_raspberry_plant", label = "Raspberry Plant", color = { 0.9, 0.2, 0.4, 1 } },
    { id = "april_blueberry_plant", label = "Blueberry Plant", color = { 0.3, 0.4, 0.9, 1 } },
    { id = "april_wool_plant", label = "Wool Plant", color = { 0.85, 0.85, 0.9, 1 } },
    { id = "april_hemp_plant", label = "Hemp Plant", color = { 0.3, 0.7, 0.25, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}

M.LOOT_MAP = {
    ["Wooden Crate"] = "april_wooden_crate",
    ["Locked Wooden Crate"] = "april_wooden_crate",
    ["Locked Metal Crate"] = "april_metal_crate",
    ["Locked Steel Crate"] = "april_steel_crate",
    ["Food Crate"] = "april_food_crate",
    ["Timed Crate"] = "april_timed_crate",
    ["Care Package"] = "april_care_package",
    ["BTR Crate"] = "april_btr_crate",
    ["Body Bag"] = "april_body_bag",
    ["Sleeper"] = "april_sleeper",
    ["Trash Can"] = "april_trash_can",
    ["Oil Barrel"] = "april_oil_barrel",
    ["Small Egg"] = "april_small_egg",
    ["Medium Egg"] = "april_medium_egg",
    ["Large Egg"] = "april_large_egg",
    ["Small Gift"] = "april_small_egg",
    ["Medium Gift"] = "april_medium_egg",
    ["Large Gift"] = "april_large_egg",
    ["Wooden Boat"] = "april_wooden_boat",
    ["Military Boat"] = "april_military_boat",
    ["Salvaged Flycopter"] = "april_flycopter",
}

M.LOOT_TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_btr_crate", label = "BTR Crate", color = { 0.8, 0.15, 0.15, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
    { id = "april_small_egg", label = "Small Egg / Gift", color = { 0.95, 0.85, 0.5, 1 } },
    { id = "april_medium_egg", label = "Medium Egg / Gift", color = { 0.9, 0.7, 0.4, 1 } },
    { id = "april_large_egg", label = "Large Egg / Gift", color = { 0.85, 0.55, 0.3, 1 } },
    { id = "april_wooden_boat", label = "Wooden Boat", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_military_boat", label = "Military Boat", color = { 0.35, 0.45, 0.35, 1 } },
    { id = "april_flycopter", label = "Salvaged Flycopter", color = { 0.6, 0.6, 0.65, 1 } },
}

M.LOOT_SCAN_FOLDERS = { "loners", "vegetation", "military", "events", "monuments" }

M.BASE_MAP = {
    ["Base Cabinet"] = "april_base_cabinet",
    ["Storage Cabinet"] = "april_storage_cabinet",
    ["Cabinet"] = "april_base_cabinet",
    ["Large Cabinet"] = "april_storage_cabinet",
    ["Small Storage Box"] = "april_small_box",
    ["Large Storage Box"] = "april_large_box",
    ["Small Box"] = "april_small_box",
    ["Large Box"] = "april_large_box",
    ["Wooden Door"] = "april_wooden_door",
    ["Wooden Double Door"] = "april_wooden_double_door",
    ["Salvaged Metal Door"] = "april_salvaged_door",
    ["Metal Door"] = "april_metal_door",
    ["Metal Double Door"] = "april_metal_double_door",
    ["Steel Door"] = "april_steel_door",
    ["Steel Double Door"] = "april_steel_double_door",
    ["Trap Door"] = "april_trap_door",
    ["Triangle Trap Door"] = "april_triangle_trap_door",
    ["Garage Door"] = "april_garage_door",
    ["Sleeping Bag"] = "april_sleeping_bag",
    ["Shotgun Turret"] = "april_shotgun_turret",
    ["Auto Turret"] = "april_auto_turret",
    ["Small Battery"] = "april_small_battery",
    ["Medium Battery"] = "april_medium_battery",
    ["Large Battery"] = "april_large_battery",
    ["Solar Panel"] = "april_solar_panel",
    ["Windmill"] = "april_windmill",
}

M.BASE_SKIP_AREAS = {
    Loners = true,
    VMs = true,
    BTRMonumentPaths = true,
    Benches = true,
    Wires = true,
    Ragdolls = true,
    Fire = true,
}

M.BASE_TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_small_box", label = "Small Storage Box", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_large_box", label = "Large Storage Box", color = { 0.45, 0.3, 0.12, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", color = { 1, 0.2, 0.2, 1 }, ring_id = "april_auto_turret_ring" },
    { id = "april_shotgun_turret", label = "Shotgun Turret", color = { 1, 0.35, 0.2, 1 }, ring_id = "april_shotgun_turret_ring" },
    { id = "april_wooden_door", label = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_wooden_double_door", label = "Wooden Double Door", color = { 0.55, 0.32, 0.12, 1 } },
    { id = "april_metal_door", label = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_salvaged_door", label = "Salvaged Metal Door", color = { 0.55, 0.52, 0.48, 1 } },
    { id = "april_metal_double_door", label = "Metal Double Door", color = { 0.52, 0.52, 0.58, 1 } },
    { id = "april_steel_door", label = "Steel Door", color = { 0.65, 0.65, 0.72, 1 } },
    { id = "april_steel_double_door", label = "Steel Double Door", color = { 0.62, 0.62, 0.7, 1 } },
    { id = "april_garage_door", label = "Garage Door", color = { 0.4, 0.4, 0.42, 1 } },
    { id = "april_trap_door", label = "Trap Door", color = { 0.48, 0.38, 0.22, 1 } },
    { id = "april_triangle_trap_door", label = "Triangle Trap Door", color = { 0.46, 0.36, 0.2, 1 } },
    { id = "april_small_battery", label = "Small Battery", color = { 0.2, 0.75, 0.35, 1 } },
    { id = "april_medium_battery", label = "Medium Battery", color = { 0.15, 0.65, 0.3, 1 } },
    { id = "april_large_battery", label = "Large Battery", color = { 0.1, 0.55, 0.25, 1 } },
    { id = "april_solar_panel", label = "Solar Panel", color = { 0.2, 0.4, 0.85, 1 } },
    { id = "april_windmill", label = "Windmill", color = { 0.75, 0.85, 0.95, 1 } },
}

function M.toggle_color(list, toggle_id, fallback)
    for _, t in ipairs(list or {}) do
        if t.id == toggle_id then
            return t.color
        end
    end
    return fallback or { 1, 1, 1, 1 }
end

function M.turret_ring_toggle(toggle_id)
    for _, t in ipairs(M.BASE_TOGGLES) do
        if t.id == toggle_id then
            return t.ring_id
        end
    end
    return nil
end

return M

end)()

-- ── game/esp_scan.lua ──
April._mods["game.esp_scan"] = (function()
local env = April.require("core.env")

local M = {}

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    UnionOperation = true,
    WedgePart = true,
    CornerWedgePart = true,
}

function M.is_part(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return PART_CLASSES[cn] == true
end

function M.find_main_part(model)
    if not env.is_valid(model) then return nil end

    local main = env.safe_call(function()
        if model.Main then return model.Main end
        return model:find_first_child("Main") or model:FindFirstChild("Main")
    end)
    if main and M.is_part(main) then return main end

    local hrp = env.safe_call(function()
        if model.HumanoidRootPart then return model.HumanoidRootPart end
        return model:find_first_child("HumanoidRootPart") or model:FindFirstChild("HumanoidRootPart")
    end)
    if hrp and M.is_part(hrp) then return hrp end

    local children = env.safe_call(function() return model:get_children() end) or {}
    for _, child in ipairs(children) do
        if M.is_part(child) then return child end
    end

    if M.is_part(model) then return model end
    return nil
end

local function vec3(v, axis)
    if not v then return 0 end
    if axis == "x" then return v.x or v.X or 0 end
    if axis == "y" then return v.y or v.Y or 0 end
    return v.z or v.Z or 0
end

function M.read_part_box(part)
    if not env.is_valid(part) or not M.is_part(part) then return nil end

    local pos, size, rv, uv, lv
    pcall(function()
        pos = part.Position or part.position
        size = part.Size or part.size
        rv = part.RightVector or part.right_vector
        uv = part.UpVector or part.up_vector
        lv = part.LookVector or part.look_vector
    end)

    if not pos or not size then return nil end

    return {
        x = vec3(pos, "x"),
        y = vec3(pos, "y"),
        z = vec3(pos, "z"),
        hx = vec3(size, "x") * 0.5,
        hy = vec3(size, "y") * 0.5,
        hz = vec3(size, "z") * 0.5,
        rx = rv and vec3(rv, "x") or 1,
        ry = rv and vec3(rv, "y") or 0,
        rz = rv and vec3(rv, "z") or 0,
        ux = uv and vec3(uv, "x") or 0,
        uy = uv and vec3(uv, "y") or 1,
        uz = uv and vec3(uv, "z") or 0,
        lx = lv and vec3(lv, "x") or 0,
        ly = lv and vec3(lv, "y") or 0,
        lz = lv and vec3(lv, "z") or 1,
    }
end

function M.collect_boxes(model, max_parts)
    max_parts = max_parts or 6
    local boxes = {}
    if not env.is_valid(model) then return boxes end

    local main = M.find_main_part(model)
    if main then
        local box = M.read_part_box(main)
        if box then table.insert(boxes, box) end
    end

    if #boxes >= max_parts then return boxes end

    local desc = env.safe_call(function() return model:get_descendants() end) or {}
    for _, inst in ipairs(desc) do
        if #boxes >= max_parts then break end
        if M.is_part(inst) and inst ~= main then
            local cn = inst.ClassName or inst.class_name
            if cn == "MeshPart" or cn == "Part" then
                local box = M.read_part_box(inst)
                if box then table.insert(boxes, box) end
            end
        end
    end

    return boxes
end

function M.label_position(entry)
    if not entry or not env.is_valid(entry.inst) then return nil end
    local main = M.find_main_part(entry.inst)
    if main then
        local box = M.read_part_box(main)
        if box then
            return box.x, box.y + box.hy + 0.25, box.z
        end
        local pos = main.Position or main.position
        if pos then
            return vec3(pos, "x"), vec3(pos, "y"), vec3(pos, "z")
        end
    end
    return nil
end

function M.make_entry(model, name, toggle_id, opts)
    opts = opts or {}
    local entry = {
        inst = model,
        name = name,
        toggle_id = toggle_id,
        dynamic = opts.dynamic == true,
    }
    if opts.hydrate ~= false then
        M.hydrate_entry(entry)
    end
    return entry
end

function M.hydrate_entry(entry)
    if not entry or not env.is_valid(entry.inst) then return entry end

    local main = M.find_main_part(entry.inst)
    entry.main_part = main

    if main then
        local box = M.read_part_box(main)
        entry.box = box
        if box then
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
        else
            local pos = main.Position or main.position
            if pos then
                entry.lx = vec3(pos, "x")
                entry.ly = vec3(pos, "y")
                entry.lz = vec3(pos, "z")
            end
        end
    end

    return entry
end

function M.refresh_entry_position(entry)
    if not entry or not env.is_valid(entry.inst) then return false end

    if entry.main_part and env.is_valid(entry.main_part) then
        local box = M.read_part_box(entry.main_part)
        if box then
            entry.box = box
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
            return true
        end
    end

    M.hydrate_entry(entry)
    return entry.lx ~= nil
end

function M.entry_coords(entry)
    if entry and entry.lx and entry.ly and entry.lz then
        return entry.lx, entry.ly, entry.lz
    end
    return M.label_position(entry)
end

function M.create_folder_scan(folder_keys, name_map, label_map, dynamic)
    return {
        folder_keys = folder_keys,
        name_map = name_map,
        label_map = label_map,
        dynamic = dynamic == true,
        fi = 1,
        ci = 1,
        children = nil,
        folder = nil,
        out = {},
        seen = {},
    }
end

function M.folder_scan_step(state, max_items)
    max_items = max_items or 16
    local processed = 0
    local folders_mod = April.require("game.folders")

    while processed < max_items do
        if state.fi > #state.folder_keys then
            return true, state.out
        end

        if not state.folder or not state.children then
            state.folder = folders_mod.from_key(state.folder_keys[state.fi])
            state.ci = 1
            if env.is_valid(state.folder) then
                state.children = env.safe_call(function() return state.folder:get_children() end) or {}
            else
                state.children = {}
            end
        end

        if state.ci > #state.children then
            state.fi = state.fi + 1
            state.folder = nil
            state.children = nil
            goto continue
        end

        local model = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1

        if not env.is_valid(model) then goto continue end

        local inst_name = model.Name or model.name
        if not inst_name then goto continue end

        local toggle_id = state.name_map[inst_name]
        if not toggle_id then goto continue end

        local key = tostring(model.Address or model) .. ":" .. toggle_id
        if state.seen[key] then goto continue end
        state.seen[key] = true

        local label = (state.label_map and state.label_map[inst_name]) or inst_name
        table.insert(state.out, M.make_entry(model, label, toggle_id, { dynamic = state.dynamic }))

        ::continue::
    end

    return false, state.out
end

function M.scan_folders(folder_keys, name_map, label_map, dynamic)
    local folders_mod = April.require("game.folders")
    local out = {}
    local seen = {}

    local function add_entry(model, inst_name)
        local toggle_id = name_map[inst_name]
        if not toggle_id then return end
        local key = tostring(model.Address or model) .. ":" .. toggle_id
        if seen[key] then return end
        seen[key] = true
        local label = (label_map and label_map[inst_name]) or inst_name
        table.insert(out, M.make_entry(model, label, toggle_id, { dynamic = dynamic }))
    end

    for _, folder_key in ipairs(folder_keys or {}) do
        local folder = folders_mod.from_key(folder_key)
        if not env.is_valid(folder) then goto next_folder end

        local children = env.safe_call(function() return folder:get_children() end) or {}
        for _, model in ipairs(children) do
            if not env.is_valid(model) then goto continue end
            local inst_name = model.Name or model.name
            if inst_name then add_entry(model, inst_name) end
            ::continue::
        end
        ::next_folder::
    end

    return out
end

return M

end)()

-- ── game/toolinfo_weapon_mods.lua ──
April._mods["game.toolinfo_weapon_mods"] = (function()
-- Patch live ToolInfo Weapon fields (Double Tap / Burst).
-- GC applygc only covers *Mult keys; Burst needs direct table writes.

local bootstrap = April.require("game.bootstrap")

local M = {}

M._baseline = nil
M._applied = false
M._last_sig = nil

local function deep_copy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}
    if seen[v] then return seen[v] end
    local out = {}
    seen[v] = out
    for k, val in pairs(v) do
        out[k] = deep_copy(val, seen)
    end
    return out
end

local function ensure_baseline(toolinfo)
    if M._baseline then return true end
    if type(toolinfo) ~= "table" then return false end
    M._baseline = deep_copy(toolinfo)
    return true
end

local function weapon_entry(toolinfo, name)
    local entry = toolinfo[name]
    if type(entry) ~= "table" then return nil end
    return entry.Weapon
end

local function baseline_weapon(name)
    if not M._baseline then return nil end
    local entry = M._baseline[name]
    if type(entry) ~= "table" then return nil end
    return entry.Weapon
end

local function restore_weapon(live_w, old_w)
    if not live_w or not old_w then return end
    pcall(function()
        if old_w.Burst ~= nil then
            live_w.Burst = old_w.Burst
        end
        if old_w.BurstRPM ~= nil then
            live_w.BurstRPM = old_w.BurstRPM
        end
    end)
end

local function apply_weapon(live_w, old_w, opts)
    if not live_w then return false end
    local changed = false

    if opts.double_tap then
        local ok = pcall(function()
            if live_w.Burst ~= nil or (old_w and old_w.Burst ~= nil) then
                live_w.Burst = 2
                live_w.BurstRPM = 10000
                changed = true
            end
        end)
        if not ok then return false end
    elseif old_w then
        restore_weapon(live_w, old_w)
    end

    return changed
end

function M.invalidate()
    M._baseline = nil
    M._applied = false
    M._last_sig = nil
end

function M.reset()
    local ok = pcall(function()
        local toolinfo = bootstrap.get_module("ToolInfo")
        if not toolinfo or not M._baseline then
            M._applied = false
            M._last_sig = nil
            return false
        end

        for name, entry in pairs(toolinfo) do
            if type(entry) == "table" and type(entry.Weapon) == "table" then
                restore_weapon(entry.Weapon, baseline_weapon(name))
            end
        end

        M._applied = false
        M._last_sig = nil
        return true
    end)
    if not ok then
        M._applied = false
        M._last_sig = nil
    end
    return ok
end

-- opts: { double_tap }
-- weapon_name: patch only the held weapon when provided
function M.apply(opts, weapon_name)
    opts = opts or {}

    local ok, success, count, msg = pcall(function()
        local toolinfo = bootstrap.get_module("ToolInfo")
        if not toolinfo then
            return false, 0, "ToolInfo not ready"
        end
        if not ensure_baseline(toolinfo) then
            return false, 0, "ToolInfo baseline failed"
        end

        local any = opts.double_tap == true
        if not any then
            if M._applied then
                M.reset()
            end
            return true, 0, "no toolinfo mods"
        end

        if not weapon_name or weapon_name == "" then
            return false, 0, "Equip a gun first"
        end

        local sig = table.concat({
            opts.double_tap and "1" or "0",
            tostring(weapon_name),
        }, ":")

        if sig == M._last_sig and M._applied then
            return true, 0, "unchanged"
        end

        for name, entry in pairs(toolinfo) do
            if type(entry) == "table" and type(entry.Weapon) == "table" then
                restore_weapon(entry.Weapon, baseline_weapon(name))
            end
        end

        local patched = 0
        local live_w = weapon_entry(toolinfo, weapon_name)
        if apply_weapon(live_w, baseline_weapon(weapon_name), opts) then
            patched = 1
        end

        M._applied = patched > 0
        M._last_sig = sig
        if patched > 0 then
            return true, patched, string.format("%d weapon(s) patched", patched)
        end
        return false, 0, "Weapon does not support burst"
    end)

    if not ok then
        return false, 0, tostring(success)
    end
    return success, count, msg
end

return M

end)()

-- ── features/combat/silent_whitelist.lua ──
April._mods["features.combat.silent_whitelist"] = (function()
-- Player whitelist for combat aim (middle-click toggle). Prefix-aware for silent + camera aim.

local settings = April.require("core.settings")
local notify = April.require("core.notify")

local M = {}

local FILTER_WHITELIST_IDX = 5
local MMB = 0x04
local DEFAULT_PREFIX = "april_silent_"

local was_down = {}
local cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function norm_prefix(prefix)
    return prefix or DEFAULT_PREFIX
end

local function ids_key(prefix)
    return norm_prefix(prefix) .. "whitelist_ids"
end

local function filters_key(prefix)
    return norm_prefix(prefix) .. "filters"
end

local function parse_ids(raw)
    local set = {}
    if type(raw) ~= "string" or raw == "" then return set end
    for part in raw:gmatch("[^,]+") do
        local id = tonumber((part:match("^%s*(.-)%s*$")))
        if id and id > 0 then
            set[id] = true
        end
    end
    return set
end

local function serialize_ids(set)
    local list = {}
    for id in pairs(set) do
        list[#list + 1] = id
    end
    table.sort(list)
    local parts = {}
    for i = 1, #list do
        parts[i] = tostring(list[i])
    end
    return table.concat(parts, ",")
end

local function read_set(prefix)
    local p = norm_prefix(prefix)
    local now = tick_ms()
    local c = cache[p]
    if c and c.t == now then return c.set end

    local raw = ""
    local key = ids_key(p)
    if menu and menu.get then
        local ok, v = pcall(menu.get, key)
        if ok and type(v) == "string" then raw = v end
    end
    if raw == "" then
        raw = tostring(settings.get(key) or "")
    end
    local set = parse_ids(raw)
    cache[p] = { t = now, set = set }
    return set
end

local function write_set(prefix, set)
    local p = norm_prefix(prefix)
    cache[p] = { t = tick_ms(), set = set }
    local s = serialize_ids(set)
    local key = ids_key(p)
    if menu and menu.set then
        pcall(menu.set, key, s)
    end
end

function M.count(prefix)
    local n = 0
    for _ in pairs(read_set(prefix)) do
        n = n + 1
    end
    return n
end

function M.is_whitelisted(player, prefix)
    if not player then return false end
    local uid = tonumber(player.user_id)
    if not uid or uid == 0 then return false end
    return read_set(prefix)[uid] == true
end

function M.toggle_player(player, prefix)
    if not player or player.is_local then return false, nil end
    local uid = tonumber(player.user_id)
    if not uid or uid == 0 then return false, nil end

    local set = read_set(prefix)
    local name = player.display_name or player.name or tostring(uid)
    local added
    if set[uid] then
        set[uid] = nil
        added = false
        notify.warning("WL - " .. name, 2500)
    else
        set[uid] = true
        added = true
        notify.success("WL + " .. name, 2500)
    end
    write_set(prefix, set)
    return true, added
end

function M.clear(prefix)
    write_set(prefix, {})
    notify.warning("Whitelist cleared", 2000)
end

function M.enabled(prefix)
    return settings.multi(filters_key(prefix), FILTER_WHITELIST_IDX, false)
end

function M.should_skip(player, prefix)
    if not M.enabled(prefix) then return false end
    return M.is_whitelisted(player, prefix)
end

function M.tick(current_target, prefix)
    prefix = norm_prefix(prefix)
    if not M.enabled(prefix) then
        was_down[prefix] = false
        return
    end

    local down = input and input.is_key_down and input.is_key_down(MMB) == true
    local pressed = down and not was_down[prefix]
    was_down[prefix] = down

    if not pressed then return end
    if not current_target then return end
    if current_target.is_npc or current_target._npc then return end

    M.toggle_player(current_target, prefix)
end

return M

end)()

-- ── features/combat/bullet_tp_ray.lua ──
April._mods["features.combat.bullet_tp_ray"] = (function()
local combat_origin = April.require("game.combat_origin")
local manip_math = April.require("core.manip_math")

local M = {}

local GRID_STEP = 0.22
local HEAD_RADIUS = 0.55
local SCAN_CACHE_MS = 160
local VISIBLE_BONUS = 2500
local PEEK_VISIBLE_BONUS = 1800

M.METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
    "Spam Cycle",
    "Target TP",
}

M.METHOD_SHUFFLE_VALID = 6
M.METHOD_DENSE_SHUFFLE = 7
M.METHOD_SPAM_CYCLE = 8
-- Bullet TP: scan head for best visible/near-visible point, spawn on target, aim through it.
M.METHOD_UNDER_TP = 9
M.METHOD_FEET_TP = M.METHOD_UNDER_TP

local BONE_SPAWN_Y = {
    Head = 0,
    UpperTorso = 0,
    LowerTorso = 0,
    HumanoidRootPart = 0,
    LeftUpperArm = 0,
    RightUpperArm = 0,
    LeftUpperLeg = 0,
    RightUpperLeg = 0,
}

local GRID_OFFS = {}
local SPAM_POOL = {}
local HEAD_SAMPLES = {}

local function push_off(list, x, y, z)
    list[#list + 1] = { x = x, y = y, z = z }
end

do
    for y = -0.66, 0.66, GRID_STEP do
        for x = -0.66, 0.66, GRID_STEP do
            for z = -0.66, 0.66, GRID_STEP do
                push_off(GRID_OFFS, x, y, z)
            end
        end
    end

    push_off(SPAM_POOL, 0, 0, 0)

    for _, off in ipairs(GRID_OFFS) do
        SPAM_POOL[#SPAM_POOL + 1] = off
    end

    for _, r in ipairs({ 0.04, 0.12, 0.22, 0.38, 0.55, 0.72, 0.95, 1.15 }) do
        for i = 0, 35 do
            local ang = (i / 36) * math.pi * 2
            push_off(SPAM_POOL, math.cos(ang) * r, math.sin(ang * 1.7) * r * 0.35, math.sin(ang) * r)
        end
    end

    for i = 0, 63 do
        local u = ((i * 17) % 100) / 100
        local v = ((i * 41) % 100) / 100
        local ang = u * math.pi * 2
        local r = 0.08 + v * 1.05
        push_off(SPAM_POOL, math.cos(ang) * r, (v - 0.5) * 0.8, math.sin(ang) * r)
    end

    push_off(HEAD_SAMPLES, 0, 0, 0)
    for _, y in ipairs({ -0.42, -0.22, -0.08, 0.08, 0.22, 0.42 }) do
        local slice = math.sqrt(math.max(0.01, HEAD_RADIUS * HEAD_RADIUS - y * y))
        for i = 0, 27 do
            local ang = (i / 28) * math.pi * 2
            push_off(HEAD_SAMPLES, math.cos(ang) * slice, y, math.sin(ang) * slice)
        end
    end
    for i = 0, 19 do
        local u = ((i * 11) % 100) / 100
        local v = ((i * 29) % 100) / 100
        local ang = u * math.pi * 2
        local pitch = (v - 0.5) * math.pi * 0.85
        local cr = math.cos(pitch)
        push_off(HEAD_SAMPLES, math.cos(ang) * cr * HEAD_RADIUS, math.sin(pitch) * HEAD_RADIUS, math.sin(ang) * cr * HEAD_RADIUS)
    end
end

local scan = { key = nil, idx = 0, spam_idx = 0 }
local head_scan_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function copy_pos(p)
    if not p then return nil end
    return { x = p.x, y = p.y, z = p.z }
end

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

local function add_off(base, off)
    return {
        x = base.x + (off.x or 0),
        y = base.y + (off.y or 0),
        z = base.z + (off.z or 0),
    }
end

function M.target_center(hitpart, bone)
    if not hitpart then return nil end
    local c = copy_pos(hitpart)
    local yoff = BONE_SPAWN_Y[bone or "Head"] or 0
    if yoff ~= 0 then
        c.y = c.y + yoff
    end
    return c
end

local function view_dir(camera_pos, focus)
    if _G.camera and _G.camera.get_look_vector then
        local ok, lv = pcall(_G.camera.get_look_vector)
        if ok and lv then
            local lx = lv.x or lv.X
            local ly = lv.y or lv.Y
            local lz = lv.z or lv.Z
            if lx then
                return unit(lx, ly or 0, lz or 0)
            end
        end
    end
    if focus and camera_pos then
        return unit(focus.x - camera_pos.x, focus.y - camera_pos.y, focus.z - camera_pos.z)
    end
    return 0, 0, 1, 1
end

local function toward_camera(origin, camera)
    if not camera then return 0, 0, 1, 1 end
    return unit(camera.x - origin.x, camera.y - origin.y, camera.z - origin.z)
end

local function aim_through(center, from, camera)
    local ux, uy, uz, len = unit(center.x - from.x, center.y - from.y, center.z - from.z)
    local extend = len < 0.35 and 0.55 or 0.08
    if len > 0.02 then
        return {
            x = center.x + ux * extend,
            y = center.y + uy * extend,
            z = center.z + uz * extend,
        }
    end
    local lx, ly, lz = toward_camera(center, camera)
    return {
        x = center.x + lx * extend,
        y = center.y + ly * extend,
        z = center.z + lz * extend,
    }
end

local function los_clear(from, to)
    if not from or not to then return false end
    if raycast and raycast.is_visible then
        return raycast.is_visible(from.x, from.y, from.z, to.x, to.y, to.z) == true
    end
    return true
end

local function head_sample_points(center, camera)
    local pts = {}
    for _, off in ipairs(HEAD_SAMPLES) do
        pts[#pts + 1] = add_off(center, off)
    end

    if camera then
        local lx, ly, lz = toward_camera(center, camera)
        for _, d in ipairs({ 0.12, 0.28, 0.45, 0.62 }) do
            pts[#pts + 1] = {
                x = center.x + lx * d,
                y = center.y + ly * d,
                z = center.z + lz * d,
            }
        end
    end

    return pts
end

local function score_head_point(from, view_x, view_y, view_z, point, ref_eye)
    if not from or not point then return -math.huge, false end

    local dx = point.x - from.x
    local dy = point.y - from.y
    local dz = point.z - from.z
    local ux, uy, uz, dist = unit(dx, dy, dz)
    if dist < 0.02 then
        return -math.huge, false
    end

    local align = ux * view_x + uy * view_y + uz * view_z
    local visible = manip_math.is_visible_from_pos(from, point)
    local score = align * 600 - dist * 0.05

    if visible then
        score = score + VISIBLE_BONUS
    end

    if ref_eye then
        local edx = point.x - ref_eye.x
        local edy = point.y - ref_eye.y
        local edz = point.z - ref_eye.z
        local eux, euy, euz, edist = unit(edx, edy, edz)
        if edist > 0.02 then
            local eye_align = eux * view_x + euy * view_y + euz * view_z
            score = score + eye_align * 120
            if manip_math.is_visible_from_pos(ref_eye, point) then
                score = score + VISIBLE_BONUS * 0.35
            end
        end
    end

    return score, visible
end

local function scan_cache_key(camera, center, body)
    if not center then return nil end
    local bx, by, bz = 0, 0, 0
    if body then
        bx, by, bz = body.x or 0, body.y or 0, body.z or 0
    end
    local cx, cy, cz = camera and camera.x or 0, camera and camera.y or 0, camera and camera.z or 0
    return string.format(
        "%.1f,%.1f,%.1f>%.1f,%.1f,%.1f@%.1f,%.1f,%.1f",
        cx, cy, cz, center.x, center.y, center.z, bx, by, bz
    )
end

local function find_best_head_aim(head_center, camera, body)
    if not head_center or not camera then
        return copy_pos(head_center), false, 0, 0
    end

    local key = scan_cache_key(camera, head_center, body)
    local now = tick_ms()
    if key and head_scan_cache[key] then
        local ent = head_scan_cache[key]
        if ent.point and (now - (ent.t or 0)) < SCAN_CACHE_MS then
            return copy_pos(ent.point), ent.visible == true, ent.score or 0, ent.progress or 1
        end
    end

    local view_x, view_y, view_z = view_dir(camera, head_center)
    local samples = head_sample_points(head_center, camera)
    local total = #samples
    if total < 1 then
        return copy_pos(head_center), false, 0, 0
    end

    local best_point = copy_pos(head_center)
    local best_score = -math.huge
    local best_visible = false
    local checked = 0

    local peek_origins = {}
    if body then
        peek_origins[#peek_origins + 1] = body
        local peek = manip_math.search_peek_at_radius(body, head_center, 1, 22)
        if peek then
            peek_origins[#peek_origins + 1] = peek
        end
    end
    peek_origins[#peek_origins + 1] = camera

    for si, point in ipairs(samples) do
        checked = si
        local score = -math.huge
        local visible = false

        for _, origin in ipairs(peek_origins) do
            local s, vis = score_head_point(origin, view_x, view_y, view_z, point, camera)
            if origin ~= camera and vis then
                s = s + PEEK_VISIBLE_BONUS
            end
            if s > score then
                score = s
                visible = vis or visible
            end
        end

        if score > best_score then
            best_score = score
            best_point = copy_pos(point)
            best_visible = visible
        end
    end

    local progress = total > 0 and (checked / total) or 1
    if key then
        head_scan_cache[key] = {
            point = copy_pos(best_point),
            visible = best_visible,
            score = best_score,
            progress = progress,
            t = now,
        }
    end

    return best_point, best_visible, best_score, progress
end

local function next_spam_offset()
    if scan.spam_idx < 1 or scan.spam_idx > #SPAM_POOL then
        scan.spam_idx = 1
    end
    local off = SPAM_POOL[scan.spam_idx]
    scan.spam_idx = scan.spam_idx + 1
    if scan.spam_idx > #SPAM_POOL then
        scan.spam_idx = 1
    end
    return off
end

local function scan_key(center, method_idx)
    return string.format("%d|%.2f,%.2f,%.2f", method_idx, center.x, center.y, center.z)
end

local function next_grid_offset(center, method_idx)
    local key = scan_key(center, method_idx)
    if scan.key ~= key then
        scan.key = key
        scan.idx = 1
    end
    local off = GRID_OFFS[scan.idx] or GRID_OFFS[1]
    scan.idx = scan.idx + 1
    if scan.idx > #GRID_OFFS then scan.idx = 1 end
    return off
end

local function rand_unit()
    local u = math.random() * 2 - 1
    local v = math.random() * 2 - 1
    local s = u * u + v * v
    while s >= 1 or s < 0.0001 do
        u = math.random() * 2 - 1
        v = math.random() * 2 - 1
        s = u * u + v * v
    end
    local w = math.sqrt((1 - s) / s)
    return u * w, v * w, math.sqrt(1 - s)
end

local function origin_center(center, _camera)
    return copy_pos(center)
end

local function origin_random_ring(center, _camera)
    local ang = math.random() * math.pi * 2
    local r = 0.18 + math.random() * 0.55
    return {
        x = center.x + math.cos(ang) * r,
        y = center.y + (math.random() - 0.5) * 0.35,
        z = center.z + math.sin(ang) * r,
    }
end

local function origin_random_sphere(center, _camera)
    local ux, uy, uz = rand_unit()
    local r = 0.12 + math.random() * 0.65
    return {
        x = center.x + ux * r,
        y = center.y + uy * r,
        z = center.z + uz * r,
    }
end

local function origin_offset_grid(center, camera, method_idx)
    return add_off(center, next_grid_offset(center, method_idx))
end

local function origin_camera_face(center, camera)
    local lx, ly, lz = toward_camera(center, camera)
    local d = 0.22 + math.random() * 0.75
    return {
        x = center.x + lx * d,
        y = center.y + ly * d,
        z = center.z + lz * d,
    }
end

local function origin_away_from_cam(center, camera)
    local lx, ly, lz = toward_camera(center, camera)
    local d = 0.22 + math.random() * 0.75
    return {
        x = center.x - lx * d,
        y = center.y - ly * d + (math.random() - 0.5) * 0.25,
        z = center.z - lz * d,
    }
end

local function origin_shuffle_valid(center, camera, tries)
    tries = tries or 14
    local best = copy_pos(center)
    for _ = 1, tries do
        local cand = origin_random_sphere(center, camera)
        if los_clear(cand, center) then
            return cand
        end
    end
    return best
end

local function aim_spam_cycle(center, camera)
    local off = next_spam_offset()
    local aim = add_off(center, off)

    if scan.spam_idx % 4 == 0 and camera then
        local lx, ly, lz = toward_camera(center, camera)
        local depth = 0.15 + ((scan.spam_idx * 13) % 80) / 100
        aim = {
            x = center.x - lx * depth + (off.x or 0) * 0.35,
            y = center.y - ly * depth + (off.y or 0) * 0.35,
            z = center.z - lz * depth + (off.z or 0) * 0.35,
        }
    end

    return aim
end

local function origin_spam_cycle(center, camera, _method_idx)
    return aim_spam_cycle(center, camera)
end

local function origin_under_tp(_center, _camera, _method_idx)
    return nil
end

local ORIGIN_FN = {
    origin_center,
    origin_random_ring,
    origin_random_sphere,
    origin_offset_grid,
    origin_camera_face,
    origin_away_from_cam,
    origin_shuffle_valid,
    function(c, cam) return origin_shuffle_valid(c, cam, 28) end,
    origin_spam_cycle,
    origin_under_tp,
}

local function resolve_target_tp(spawn, hitpart, camera, muzzle, body)
    local best_aim, scan_visible, _score, scan_progress = find_best_head_aim(spawn, camera, body)
    local off = next_spam_offset()
    local origin = add_off(best_aim, off)
    local aim_point = copy_pos(best_aim)
    local aim = aim_through(aim_point, origin, camera)

    return {
        origin = origin,
        aim = aim,
        hitpart = copy_pos(hitpart),
        method = "Target TP",
        tp_path = M.build_path(origin, aim_point, muzzle),
        tp_scan_visible = scan_visible,
        tp_scan_progress = scan_progress,
    }
end

function M.hitpart_aim(hit, bone)
    return M.target_center(hit, bone)
end

function M.resolve(opts)
    opts = opts or {}
    local camera = opts.camera or combat_origin.get_camera_origin()
    local hitpart = opts.hitpart
    if not hitpart or not camera then return nil end

    local method_idx = math.floor(tonumber(opts.method) or M.METHOD_UNDER_TP)
    if method_idx < 0 then method_idx = 0 end
    if method_idx >= #M.METHODS then method_idx = M.METHOD_UNDER_TP end

    local spawn = M.target_center(hitpart, opts.bone) or copy_pos(hitpart)
    if not spawn then return nil end

    local muzzle = opts.muzzle or combat_origin.get_muzzle_origin() or camera
    local body = opts.body

    if method_idx == M.METHOD_UNDER_TP then
        return resolve_target_tp(spawn, hitpart, camera, muzzle, body)
    end

    local pick = ORIGIN_FN[method_idx + 1] or origin_spam_cycle
    local origin = pick(spawn, camera, method_idx)
    if not origin then return nil end

    local aim_point
    if method_idx == M.METHOD_SPAM_CYCLE then
        origin = aim_spam_cycle(spawn, camera)
        aim_point = copy_pos(hitpart)
    else
        aim_point = copy_pos(hitpart)
    end

    local aim = aim_through(aim_point, origin, camera)

    return {
        origin = origin,
        aim = aim,
        hitpart = copy_pos(hitpart),
        method = M.METHODS[method_idx + 1],
        tp_path = M.build_path(origin, aim_point, muzzle),
    }
end

function M.build_under_path(origin, aim, muzzle, surface_y)
    local out = {}
    if muzzle then out[#out + 1] = copy_pos(muzzle) end
    if surface_y and origin then
        out[#out + 1] = { x = origin.x, y = surface_y, z = origin.z }
    end
    if origin then out[#out + 1] = copy_pos(origin) end
    if aim then out[#out + 1] = copy_pos(aim) end
    return out
end

function M.build_path(tp_origin, center, muzzle)
    if not tp_origin or not center then return {} end
    local out = {}
    if muzzle then out[#out + 1] = copy_pos(muzzle) end
    out[#out + 1] = copy_pos(tp_origin)
    out[#out + 1] = copy_pos(center)
    return out
end

function M.clear_scan_cache()
    head_scan_cache = {}
end

return M

end)()

-- ── features/combat/combat_menu.lua ──
April._mods["features.combat.combat_menu"] = (function()
local menu_util = April.require("core.menu_util")
local settings = April.require("core.settings")

local M = {}

M.TP_METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

M.BONE_MAP = {
    ["Head"] = "Head",
    ["Torso"] = "UpperTorso",
    ["Left Arm"] = "LeftUpperArm",
    ["Right Arm"] = "RightUpperArm",
    ["Left Leg"] = "LeftUpperLeg",
    ["Right Leg"] = "RightUpperLeg",
    ["Closest"] = "Closest",
}

-- april_silent_filters indices (1-based)
M.FILTER_HEALTH = 1
M.FILTER_VISIBLE = 2
M.FILTER_TEAM = 3
M.FILTER_SAFEZONE = 4
M.FILTER_WHITELIST = 5
M.FILTER_SKIP_DOWNED = 6

-- april_silent_targets / april_aim_targets (Players, NPCs)
M.TARGET_PLAYERS = 1
M.TARGET_NPCS = 2

-- april_silent_options / april_aim_options indices (1-based)
M.OPT_STICKY = 1

function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end

function M.downed_mode_from_filters(prefix)
    local filters = (prefix or "april_silent_") .. "filters"
    if settings.multi(filters, M.FILTER_SKIP_DOWNED, true) then
        return 0
    end
    return 1
end

function M.register_silent_aim(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix

    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", {
        "Players", "NPCs",
    }, { false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "targets", { true, false })
    end
    menu.add_multicombo(T, G, p .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { false, false, false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "filters", { true, false, true, true, false, true })
    end
    menu.add_input(T, G, p .. "whitelist_ids", "Whitelist IDs", "")
    if menu and menu.set_visible then
        pcall(menu.set_visible, p .. "whitelist_ids", false)
    end
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })

    menu_util.section(T, G, "Aim")
    menu.add_multicombo(T, G, p .. "options", "Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "hit_chance", "Hit Chance %", 1, 100, 100, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 150, { parent = parent_id })

    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))
end

-- Independent Bullet section (hitscan / TP / manip). Keys stay april_silent_* for config compat.
function M.register_bullet(T, G, prefix, parent_id)
    local p = prefix
    menu.add_checkbox(T, G, p .. "hitscan", "Hitscan", false, { parent = parent_id })

    menu.add_checkbox(T, G, p .. "bullet_tp", "Bullet TP", false, { parent = parent_id })

    local manip_root = menu_util.parent(p .. "bullet_manip")
    menu.add_checkbox(T, G, p .. "bullet_manip", "Silent Bullet Manip", false, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", manip_root)
    menu.add_checkbox(T, G, p .. "manip_extend", "Extend", false, manip_root)
    menu.add_slider_float(T, G, p .. "manip_extend_dist", "Extend Distance", 1, 7, 7, "%.1f",
        menu_util.parent(p .. "manip_extend"))
    menu.add_checkbox(T, G, "april_bullet_body_peek", "Body Peek (desync)", false, manip_root)

    local vis_root = menu_util.parent(parent_id)
    menu.add_checkbox(T, G, p .. "manip_status", "Status HUD", false, vis_root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Peek Visual", false, vis_root)
end

--- Camera aimbot: same targeting/filters as silent, without bullet TP/manip/hitscan.
function M.register_aimbot(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix

    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", {
        "Players", "NPCs",
    }, { false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "targets", { true, false })
    end
    menu.add_multicombo(T, G, p .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { false, false, false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "filters", { true, false, true, true, false, true })
    end
    menu.add_input(T, G, p .. "whitelist_ids", "Whitelist IDs", "")
    if menu and menu.set_visible then
        pcall(menu.set_visible, p .. "whitelist_ids", false)
    end
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })

    menu_util.section(T, G, "Aim")
    menu.add_multicombo(T, G, p .. "options", "Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "smooth", "Smoothness", 1, 25, 10, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 120, { parent = parent_id })

    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.2, 1, 0.45, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 0.2, 1, 0.45, 1 } }))
end

return M

end)()

-- ── features/combat/targeting.lua ──
April._mods["features.combat.targeting"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local combat_menu = April.require("features.combat.combat_menu")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local cache = April.require("core.cache")
local env = April.require("core.env")

local M = {}

M.BONES = esp_util.AIM_BONES

local function w2s(x, y, z)
    return esp_util.w2s(x, y, z)
end

function M.is_npc_target(target)
    return target and target.is_npc == true
end

local function npc_enabled(entry, prefix)
    if not entry then return false end
    return settings.multi(prefix .. "targets", 2, false)
end

local function same_npc_inst(a, b)
    if not a or not b then return false end
    if a == b then return true end
    local aa = a.Address or a.address
    local ba = b.Address or b.address
    return aa ~= nil and aa == ba
end

local function read_npc_health(model)
    if not model or not env.is_valid(model) then
        return nil
    end
    local hum = env.safe_call(function()
        if model.find_first_child_of_class then
            return model:find_first_child_of_class("Humanoid")
        end
        return model:FindFirstChild("Humanoid")
    end)
    if not hum then
        return nil
    end
    local hp = hum.Health or hum.health
    if not hp or hp <= 0 then
        return nil
    end
    return hum
end

function M.is_npc_alive(entry)
    if not entry or not entry.inst or not env.is_valid(entry.inst) then
        return false
    end
    return read_npc_health(entry.inst) ~= nil
end

function M.is_aim_target(target)
    if M.is_npc_target(target) then
        return M.is_npc_alive(target)
    end
    return player_state.is_combat_target(target)
end

-- Prefer live Head part; cached lx/ly/lz is only a fallback (stale coords glue camera aimbot).
local function npc_head_world(entry)
    if not entry then
        return nil
    end
    local head = entry.head
    if (not head or not env.is_valid(head)) and entry.inst and env.is_valid(entry.inst) then
        head = env.safe_call(function()
            return entry.inst:find_first_child("Head") or entry.inst:FindFirstChild("Head")
        end)
        if head then
            entry.head = head
        end
    end
    if head and env.is_valid(head) then
        local pos = head.Position or head.position
        if pos and pos.x then
            entry.lx, entry.ly, entry.lz = pos.x, pos.y, pos.z
            return { x = pos.x, y = pos.y, z = pos.z }
        end
    end
    if entry.lx then
        return { x = entry.lx, y = entry.ly, z = entry.lz }
    end
    return nil
end

-- Rebind a sticky NPC lock to the current cache entry + live head (or nil if gone).
function M.refresh_npc_target(target)
    if not M.is_npc_target(target) or not target.inst then
        return nil
    end
    if not env.is_valid(target.inst) then
        return nil
    end

    local found = nil
    if cache.npcs then
        for _, entry in ipairs(cache.npcs) do
            if same_npc_inst(entry.inst, target.inst) then
                found = entry
                break
            end
        end
    end

    if found then
        target.inst = found.inst
        target.head = found.head
        target.name = found.name or target.name
        target.kind = found.kind or target.kind
        target.lx = found.lx
        target.ly = found.ly
        target.lz = found.lz
    end

    if not M.is_npc_alive(target) then
        return nil
    end
    if not npc_head_world(target) then
        return nil
    end
    return target
end

local function npc_distance(entry, origin)
    if not origin or not entry then
        return nil
    end
    local pos = npc_head_world(entry)
    if not pos then
        return nil
    end
    return math_util.distance3(pos.x - origin.x, pos.y - origin.y, pos.z - origin.z)
end

local function passes_visibility(target, aim, origin)
    if not raycast then return true end
    if not origin or not aim then return true end

    if M.is_npc_target(target) then
        if raycast.is_visible then
            return raycast.is_visible(origin.x, origin.y, origin.z, aim.x, aim.y, aim.z)
        end
        return true
    end

    local char = target and target.character
    if char and utility and utility.is_valid(char) and raycast.is_player_visible then
        return raycast.is_player_visible(char.address)
    end

    if raycast.is_visible then
        return raycast.is_visible(origin.x, origin.y, origin.z, aim.x, aim.y, aim.z)
    end

    return true
end

function M.bone_name(prefix)
    local idx = settings.num(prefix .. "bone", 0)
    return combat_menu.bone_from_index(idx)
end

-- Camera aimbot only: bows use torso for prediction (head aim shoots too high).
-- Silent aim must NOT use this - it tracks the real selected hitpart.
-- Extra Y nudge only for Wooden Bow (not Crossbow).
local WOODEN_BOW_AIM_Y_NUDGE = -0.22

local function is_wooden_bow(weapon_name)
    if not weapon_name then return false end
    local n = weapon_name:lower()
    return n:find("wooden bow", 1, true) ~= nil
end

-- Bow torso remap applies only to camera aimbot (april_aim_*), not silent (april_silent_*).
function M.uses_bow_torso_aim(prefix)
    return type(prefix) == "string" and prefix:sub(1, 10) == "april_aim_"
end

function M.effective_aim_bone(bone, weapon_name)
    bone = bone or "Head"
    if bone == "Head" and weapons.is_bow_weapon_name(weapon_name) then
        return "UpperTorso"
    end
    return bone
end

function M.bow_aim_nudge(point, weapon_name)
    if not point or not is_wooden_bow(weapon_name) then
        return point
    end
    return {
        x = point.x,
        y = point.y + WOODEN_BOW_AIM_Y_NUDGE,
        z = point.z,
    }
end

function M.target_priority_crosshair(prefix)
    local idx = settings.num(prefix .. "target_type", 0)
    return idx == 0
end

function M.passes_filters(target, prefix, aim, origin, opts)
    if not target then return false end
    opts = opts or {}

    if M.is_npc_target(target) then
        if settings.multi(prefix .. "filters", 1, true) and not M.is_npc_alive(target) then
            return false
        end
        if settings.multi(prefix .. "filters", 2, false) and not passes_visibility(target, aim, origin) then
            return false
        end
        return true
    end

    if not opts.ignore_whitelist and silent_whitelist.should_skip(target, prefix) then
        return false
    end

    if settings.multi(prefix .. "filters", 1, true) then
        if not player_state.passes_health_check(target) then return false end
    end

    if not player_state.passes_downed_check(target, combat_menu.downed_mode_from_filters(prefix)) then
        return false
    end

    if settings.multi(prefix .. "filters", 3, true) then
        if not player_state.passes_team_check(target) then return false end
    end

    if settings.multi(prefix .. "filters", 4, true) then
        if not player_state.passes_safezone_check(target, true) then return false end
    end

    if not opts.ignore_visible and settings.multi(prefix .. "filters", 2, false) then
        if not passes_visibility(target, aim, origin) then return false end
    end

    return true
end

function M.within_max_distance(target, origin, prefix)
    local max_d = settings.num(prefix .. "max_dist", 500)
    if max_d <= 0 or not origin then return true end

    if M.is_npc_target(target) then
        local dist = npc_distance(target, origin)
        return dist == nil or dist <= max_d
    end

    local dist = target.distance_to and target:distance_to(origin) or nil
    if not dist and target.position and origin then
        local pos = target.position
        dist = math_util.distance3((pos.x or 0) - origin.x, (pos.y or 0) - origin.y, (pos.z or 0) - origin.z)
    end

    return dist == nil or dist <= max_d
end

function M.bone_world(target, bone)
    if not target then return nil end

    if M.is_npc_target(target) then
        if not M.refresh_npc_target(target) then
            return nil
        end
        return npc_head_world(target)
    end

    if not target.is_alive then return nil end
    if bone == "Closest" then return nil end

    if bone == "Head" and target.head_position then
        local pos = target.head_position
        return { x = pos.x, y = pos.y, z = pos.z }
    end

    if target.character then
        local part = env.safe_call(function()
            return target.character:find_first_child(bone) or target.character:FindFirstChild(bone)
        end)
        if part and env.is_valid(part) then
            local ppos = part.Position or part.position
            if ppos and ppos.x then
                return { x = ppos.x, y = ppos.y, z = ppos.z }
            end
        end
    end

    if target.position then
        local pos = target.position
        if bone == "Head" then
            return nil
        end
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

function M.closest_bone_world(target, cx, cy)
    cx = cx or 0
    cy = cy or 0
    if M.is_npc_target(target) then
        return npc_head_world(target)
    end
    if target and target.get_bones_screen then
        local ok, bones = pcall(function()
            return target:get_bones_screen()
        end)
        if ok and type(bones) == "table" then
            local best_name, best_dist = nil, math.huge
            for name, entry in pairs(bones) do
                if type(entry) == "table" and type(name) == "string" and name ~= "Closest" then
                    local bx = entry.x or entry[1]
                    local by = entry.y or entry[2]
                    if type(bx) == "number" and type(by) == "number" then
                        local d = math_util.screen_fov_dist(bx, by, cx, cy)
                        if d < best_dist then
                            best_dist = d
                            best_name = name
                        end
                    end
                end
            end
            if best_name then
                local world = M.bone_world(target, best_name)
                if world then return world end
            end
        end
    end
    return M.bone_world(target, "Head")
end

local function target_velocity(target)
    if M.is_npc_target(target) and target.inst and env.is_valid(target.inst) then
        local root = env.safe_call(function()
            return target.inst:find_first_child("HumanoidRootPart")
                or target.inst:FindFirstChild("HumanoidRootPart")
        end)
        if root and env.is_valid(root) then
            local vel = root.AssemblyLinearVelocity or root.Velocity or root.velocity
            if vel and vel.x then
                return {
                    x = vel.x,
                    y = math.max(-100, math.min(100, vel.y or 0)),
                    z = vel.z,
                }
            end
        end
        return { x = 0, y = 0, z = 0 }
    end

    if target.velocity then
        local v = target.velocity
        if v.x ~= nil then
            return {
                x = v.x,
                y = math.max(-100, math.min(100, v.y or 0)),
                z = v.z,
            }
        end
    end

    if target.character then
        local root = env.safe_call(function()
            return target.character:find_first_child("HumanoidRootPart")
                or target.character:FindFirstChild("HumanoidRootPart")
        end)
        if root and env.is_valid(root) then
            local vel = root.AssemblyLinearVelocity or root.Velocity or root.velocity
            if vel and vel.x then
                return {
                    x = vel.x,
                    y = math.max(-100, math.min(100, vel.y or 0)),
                    z = vel.z,
                }
            end
        end
    end

    return { x = 0, y = 0, z = 0 }
end

function M.predict_point(origin, point, target, weapon_name)
    if not origin or not point then return point end
    local vel = target_velocity(target)
    weapon_name = weapon_name or weapons.cached_held_ranged()
    return ballistic.predict_for_weapon(origin, point, vel, weapon_name)
end

function M.resolve_bone_world(target, bone, cx, cy)
    bone = bone or "Head"
    if bone == "Closest" then
        return M.closest_bone_world(target, cx, cy)
    end
    return M.bone_world(target, bone)
end

function M.get_aim_point(target, prefix, bone, origin, cx, cy, use_prediction)
    bone = bone or M.bone_name(prefix)
    local weapon = weapons.cached_held_ranged()
    if M.uses_bow_torso_aim(prefix) then
        bone = M.effective_aim_bone(bone, weapon)
    end
    local base = M.resolve_bone_world(target, bone, cx, cy)
    if not base then return nil end
    if M.uses_bow_torso_aim(prefix) then
        base = M.bow_aim_nudge(base, weapon)
    end

    if use_prediction == false then
        return base
    end

    origin = origin or combat_origin.get_fire_origin()
    if not origin then return base end

    return M.predict_point(origin, base, target, weapon)
end

function M.is_target_valid(target, prefix, cx, cy, fov_px, opts)
    opts = opts or {}
    if M.is_npc_target(target) then
        target = M.refresh_npc_target(target)
        if not target then return false end
    end

    if not M.is_aim_target(target) then return false end

    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    if not M.within_max_distance(target, origin, prefix) then return false end

    local bone = M.bone_name(prefix)
    if bone == "Closest" then bone = "Head" end
    if M.uses_bow_torso_aim(prefix) then
        bone = M.effective_aim_bone(bone, weapons.cached_held_ranged())
    end
    local base = M.resolve_bone_world(target, bone, cx, cy)
    if not base then return false end

    if not M.passes_filters(target, prefix, base, origin, opts) then return false end

    if opts.ignore_fov then
        return true
    end

    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    if not on_screen then return false end

    local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    return fov_dist <= fov_px
end

local function consider_target(target, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score, opts)
    opts = opts or {}
    if not M.within_max_distance(target, origin, prefix) then
        return best, best_score
    end

    local base = M.bone_world(target, screen_bone)
    if not base then
        return best, best_score
    end

    if filter_visible and not passes_visibility(target, base, origin) then
        return best, best_score
    end
    if not M.passes_filters(target, prefix, base, origin, opts) then
        return best, best_score
    end

    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    local fov_dist = math.huge
    if on_screen then
        fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    end

    if not opts.ignore_fov then
        if not on_screen then
            return best, best_score
        end
        if fov_dist > fov_px then
            return best, best_score
        end
    elseif not on_screen and use_fov then
        -- Rage / no-FOV: still prefer on-screen when scoring by crosshair.
        fov_dist = 1e6
    end

    local score
    if M.is_npc_target(target) then
        score = use_fov and fov_dist or (npc_distance(target, origin) or fov_dist)
    else
        score = use_fov and fov_dist or (target.distance_to and origin and target:distance_to(origin) or fov_dist)
    end

    if score < best_score then
        return target, score
    end
    return best, best_score
end

function M.find_target(cx, cy, fov_px, prefix, opts)
    opts = opts or {}
    local bone = M.bone_name(prefix)
    local screen_bone = bone == "Closest" and "Head" or bone
    if M.uses_bow_torso_aim(prefix) then
        screen_bone = M.effective_aim_bone(screen_bone, weapons.cached_held_ranged())
    end
    local use_fov = opts.force_crosshair_priority or M.target_priority_crosshair(prefix)
    -- ignore_fov skips the FOV clamp but still allows crosshair scoring when selected.
    local best, best_score = nil, use_fov and math.huge or math.huge
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local filter_visible = not opts.ignore_visible and settings.multi(prefix .. "filters", 2, false)
    local target_players = settings.multi(prefix .. "targets", 1, true)
    local target_npcs = not opts.players_only and settings.multi(prefix .. "targets", 2, false)

    if target_players and entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) then
                best, best_score = consider_target(
                    p, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score, opts
                )
            end
        end
    end

    if target_npcs and cache.npcs then
        for _, entry in ipairs(cache.npcs) do
            if npc_enabled(entry, prefix) and M.is_npc_alive(entry) then
                local npc_target = {
                    is_npc = true,
                    inst = entry.inst,
                    head = entry.head,
                    name = entry.name,
                    kind = entry.kind,
                    lx = entry.lx,
                    ly = entry.ly,
                    lz = entry.lz,
                }
                best, best_score = consider_target(
                    npc_target, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score, opts
                )
            end
        end
    end

    return best
end

function M.screen_center()
    local w, h = April.require("core.draw_util").screen_size()
    return w, h
end

return M

end)()

-- ── features/combat/active_target.lua ──
April._mods["features.combat.active_target"] = (function()
-- Resolve the active combat target + aim point from ragebot / silent / aimbot.
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local combat_origin = April.require("game.combat_origin")
local esp_util = April.require("core.esp_util")

local M = {}

M.SOURCE_NAMES = { "Auto", "Ragebot", "Silent Aim", "Aimbot" }
M.SOURCE_CROSSHAIR = "april_crosshair_source"
M.SOURCE_GEAR = "april_target_gear_source"

local MODULES = {
    { id = "april_rage_enabled", path = "features.combat.ragebot", prefix = "april_rage_" },
    { id = "april_silent_aim", path = "features.combat.aimbot", prefix = "april_silent_" },
    { id = "april_aimbot", path = "features.combat.camera_aimbot", prefix = "april_aim_" },
}

local function load_mod(entry)
    local ok, mod = pcall(function()
        return April.require(entry.path)
    end)
    if ok then return mod end
    return nil
end

function M.source_index(source_id)
    source_id = source_id or M.SOURCE_CROSSHAIR
    return math.floor(settings.num(source_id, 0) or 0)
end

function M.resolve_source_index(source_id)
    local idx = M.source_index(source_id)
    if idx >= 1 and idx <= #MODULES then
        if settings.enabled(MODULES[idx].id) then
            return idx
        end
        return nil
    end

    for i = 1, #MODULES do
        if settings.enabled(MODULES[i].id) then
            return i
        end
    end
    return nil
end

function M.get_entry(source_idx, source_id)
    source_idx = source_idx or M.resolve_source_index(source_id)
    if not source_idx then return nil end
    return MODULES[source_idx]
end

function M.get_target(source_idx, source_id)
    local entry = M.get_entry(source_idx, source_id)
    if not entry then return nil, nil end

    local mod = load_mod(entry)
    if not mod then return nil, entry.prefix end

    if mod.get_target then
        local t = mod.get_target()
        if t then return t, entry.prefix end
    end
    if mod.get_scoped_target then
        local t = mod.get_scoped_target()
        if t then return t, entry.prefix end
    end
    return nil, entry.prefix
end

function M.get_aim_world(source_idx, cx, cy, source_id)
    local target, prefix = M.get_target(source_idx, source_id)
    if not target or not prefix then return nil, target, prefix end

    local sw, sh = targeting.screen_center()
    cx = cx or sw * 0.5
    cy = cy or sh * 0.5
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local aim = targeting.get_aim_point(target, prefix, nil, origin, cx, cy, false)
    return aim, target, prefix
end

function M.get_aim_screen(source_idx, cx, cy, source_id)
    local aim, target, prefix = M.get_aim_world(source_idx, cx, cy, source_id)
    if not aim then return nil, target, prefix end

    local sx, sy, vis = esp_util.w2s(aim.x, aim.y, aim.z)
    if not vis then return nil, target, prefix end
    return { x = sx, y = sy }, target, prefix
end

return M

end)()

-- ── features/combat/silent_resolve.lua ──
April._mods["features.combat.silent_resolve"] = (function()
local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")
local bullet_tp_ray = April.require("features.combat.bullet_tp_ray")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")

local M = {}

local OFF_INFO = {
    state = "off",
    manip_state = "off",
    peek = nil,
    radius = 1,
    hitscan_on = false,
    tp_on = false,
    manip_on = false,
}
local BULLET_PREFIX = "april_silent_"

function M.bullet_enabled()
    return settings.bool("april_bullet_enabled", false)
end

local function bullet_flag(name, default)
    if not M.bullet_enabled() then
        return false
    end
    return settings.bool(BULLET_PREFIX .. name, default == true)
end

local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end

local function feature_flags()
    return {
        hitscan_on = bullet_flag("hitscan", false),
        tp_on = bullet_flag("bullet_tp", false),
        manip_on = bullet_flag("bullet_manip", false),
    }
end

local function merge_info(base, manip_extra, flags)
    local info = base or {}
    flags = flags or feature_flags()
    info.hitscan_on = flags.hitscan_on
    info.tp_on = flags.tp_on
    info.manip_on = flags.manip_on

    if manip_extra then
        info.manip_state = manip_extra.state or "off"
        info.peek = manip_extra.peek or info.peek
        info.radius = manip_extra.radius or info.radius
        info.base_radius = manip_extra.base_radius
        info.extend_active = manip_extra.extend_active
        info.scan_progress = manip_extra.scan_progress or info.scan_progress
        info.body_peek = manip_extra.body_peek
    else
        info.manip_state = info.manip_state or "off"
    end

    return info
end

local function body_peek_mod()
    local ok, mod = pcall(function()
        return April.require("features.combat.body_peek")
    end)
    if ok then return mod end
    return nil
end

local function resolve_manip(body, hitpart, muzzle, target)
    local extra = {
        state = "off",
        peek = nil,
        radius = 0,
        base_radius = 0,
        extend_active = false,
        scan_progress = 0,
        body_peek = false,
    }
    if not bullet_flag("bullet_manip", false) or not body then
        return nil, extra
    end

    local base_r = manip_math.clamp_radius(settings.num(BULLET_PREFIX .. "manip_dist", 1))
    local extend_on = settings.bool(BULLET_PREFIX .. "manip_extend", false)
    local ext_extra = extend_on
        and manip_math.clamp_extend_extra(settings.num(BULLET_PREFIX .. "manip_extend_dist", 7))
        or 0

    local ev = manip_math.evaluate_manipulation(body, hitpart, {
        base_radius = base_r,
        extend = extend_on,
        extend_extra = ext_extra,
    })

    extra.state = ev.state
    extra.peek = ev.peek
    extra.radius = ev.radius or base_r
    extra.base_radius = base_r
    extra.extend_active = ev.extend_active == true
    extra.scan_progress = ev.scan_progress or 0

    local max_r = extend_on and (base_r + ext_extra) or base_r
    local body_peek = body_peek_mod()
    local use_body_peek = settings.bool("april_bullet_body_peek", false) and body_peek

    if ev.state == "ready" and ev.peek then
        local peek = ev.peek
        if use_body_peek and body_peek.ensure_peek then
            local moved = body_peek.ensure_peek(peek, hitpart, target, max_r)
            if moved then
                extra.body_peek = true
                peek = moved
            end
        end
        return manip_math.peek_track_origin(peek, muzzle, body), extra
    end

    if ev.state == "blocked" and use_body_peek and body_peek.try_peek then
        local peek = body_peek.try_peek(body, hitpart, max_r, target)
        if peek then
            extra.state = "ready"
            extra.peek = peek
            extra.body_peek = true
            extra.scan_progress = 1
            local track = manip_math.peek_track_origin(peek, muzzle, body)
            return track, extra
        end
    end

    return nil, extra
end

local function apply_drop_aim(origin, hitpart, weapon, state, manip_extra, flags)
    local muzzle = origin or combat_origin.get_muzzle_origin()
    local curve = ballistic.curve_for_weapon(muzzle, hitpart, weapon, 24)
    local info = merge_info({
        state = state or "curve",
        peek = nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = true,
        weapon = weapon,
        hitpart = hitpart,
        curve_path = curve and curve.path or nil,
        launch_dir = curve and curve.launch_dir or nil,
    }, manip_extra, flags)
    return muzzle, hitpart, info
end

local function apply_ray_aim(origin, aim, hitpart, weapon, state, manip_extra, meta, flags)
    meta = meta or {}
    local info = merge_info({
        state = state,
        peek = manip_extra and manip_extra.peek or nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = false,
        weapon = weapon,
        hitpart = hitpart,
        tp_path = meta.tp_path,
        tp_method = meta.method,
        tp_scan_visible = meta.tp_scan_visible,
        tp_scan_progress = meta.tp_scan_progress,
    }, manip_extra, flags)
    return origin, aim, info
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local flags = feature_flags()
    local weapon = weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local bone = targeting.bone_name(prefix)
    local hitpart = targeting.resolve_bone_world(target, bone, cx, cy)
    if not hitpart then return nil, nil, OFF_INFO end
    local muzzle = fire_origin(camera)
    local body = combat_origin.get_server_origin()

    local manip_fire, manip_extra = resolve_manip(body, hitpart, muzzle, target)
    local fire = manip_fire or muzzle

    local hitscan_on = flags.hitscan_on
    local tp_on = flags.tp_on

    if tp_on then
        local head = targeting.resolve_bone_world(target, "Head", cx, cy) or hitpart
        local tp = bullet_tp_ray.resolve({
            method = bullet_tp_ray.METHOD_UNDER_TP,
            camera = camera,
            hitpart = head,
            bone = "Head",
            muzzle = muzzle,
            body = body,
        })
        if tp and tp.origin and tp.aim then
            local path = tp.tp_path or bullet_tp_ray.build_path(tp.origin, tp.aim, muzzle)
            if manip_extra.peek and manip_fire then
                path = bullet_tp_ray.build_path(manip_fire, head, muzzle) or path
            end
            return apply_ray_aim(tp.origin, tp.aim, tp.hitpart or head, weapon, "tp", manip_extra, {
                tp_path = path,
                method = tp.method,
                tp_scan_visible = tp.tp_scan_visible,
                tp_scan_progress = tp.tp_scan_progress,
            }, flags)
        end
    end

    if manip_extra.state == "ready" and manip_fire then
        return apply_ray_aim(manip_fire, hitpart, hitpart, weapon, "ready", manip_extra, {
            tp_path = bullet_tp_ray.build_path(manip_fire, hitpart, muzzle),
            method = "Manip",
        }, flags)
    end

    if hitscan_on then
        return apply_ray_aim(muzzle or fire, hitpart, hitpart, weapon, "hitscan", manip_extra, nil, flags)
    end

    if manip_extra.state == "direct" then
        return apply_drop_aim(muzzle, hitpart, weapon, "direct", manip_extra, flags)
    end

    return apply_drop_aim(muzzle, hitpart, weapon, "curve", manip_extra, flags)
end

function M.any_bullet_feature()
    return bullet_flag("hitscan", false)
        or bullet_flag("bullet_tp", false)
        or bullet_flag("bullet_manip", false)
end

function M.bypass_visibility()
    return bullet_flag("bullet_tp", false) or bullet_flag("hitscan", false)
end

return M

end)()

-- ── features/combat/bullet_hud.lua ──
April._mods["features.combat.bullet_hud"] = (function()
-- Themed on-screen HUD for bullet features (hitscan / TP / manip).
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local desync_vis = April.require("core.desync_vis")
local combat_origin = April.require("game.combat_origin")
local manip_math = April.require("core.manip_math")

local M = {}

local PREFIX = "april_silent_"
local P_BULLET = "april_bullet_enabled"

local scan_anim = 0

local FIRE_LABELS = {
    tp = "Bullet TP",
    hitscan = "Hitscan",
    ready = "Manip Peek",
    direct = "Clear LOS",
    curve = "Ballistic",
    blocked = "Blocked",
    scanning = "Scanning",
    off = "Idle",
}

local MANIP_LABELS = {
    direct = "Clear LOS",
    ready = "Peek Ready",
    scanning = "Scanning",
    blocked = "No Peek",
    off = "Off",
}

local function bullet_flag(name, default)
    if not settings.bool(P_BULLET, false) then
        return false
    end
    return settings.bool(PREFIX .. name, default == true)
end

function M.update(dt)
    scan_anim = scan_anim + (dt or 0.016) * 0.85
    if scan_anim > 1 then scan_anim = scan_anim - 1 end
end

local function row_color(active, ok, warn)
    if active and ok then return theme.GREEN end
    if active and warn then return theme.ORANGE end
    if active then return theme.RED end
    return overlay_theme.text_muted()
end

local function draw_status_panel(cx, cy, fov, info)
    if not settings.bool(PREFIX .. "manip_status", false) then return end
    if not info then return end

    overlay_theme.sync()

    local hitscan_on = info.hitscan_on == true
    local tp_on = info.tp_on == true
    local manip_on = info.manip_on == true
    if not hitscan_on and not tp_on and not manip_on then return end

    local manip_state = info.manip_state or "off"
    local fire_mode = info.state or "off"
    local fire_label = FIRE_LABELS[fire_mode] or fire_mode
    local manip_label = MANIP_LABELS[manip_state] or manip_state

    local pad_x, pad_y = 10, 6
    local row_h = 14
    local bar_h = 5
    local title = "BULLET STATUS"
    local title_w = theme.text_w(title, 11)
    local w1 = theme.text_w("Hitscan", 10) + theme.text_w("ON", 10) + 24
    local w2 = theme.text_w("Bullet TP", 10) + theme.text_w("ON", 10) + 24
    local w3 = theme.text_w("Manip", 10) + theme.text_w(manip_label, 10) + 24
    local w4 = theme.text_w("Fire", 10) + theme.text_w(fire_label, 10) + 24
    local panel_w = math.max(title_w, w1, w2, w3, w4) + pad_x * 2 + 8
    panel_w = math.max(panel_w, 168)

    local rows = 4
    local has_bar = manip_on and (manip_state == "scanning" or manip_state == "ready" or manip_state == "direct")
    local panel_h = 22 + rows * row_h + pad_y + (has_bar and (bar_h + 6) or 0)
    local x = cx - panel_w * 0.5
    local y = cy + fov + 10

    overlay_theme.draw_panel(x, y, panel_w, panel_h, title)

    local tx = x + pad_x
    local ry = y + 24

    local function draw_row(label, value, col)
        draw_util.text(tx, ry, label, overlay_theme.text_muted(), 10)
        local vw = theme.text_w(value, 10)
        draw_util.text(x + panel_w - pad_x - vw, ry, value, col, 10)
        ry = ry + row_h
    end

    draw_row("Hitscan", hitscan_on and "ON" or "OFF", row_color(hitscan_on, true, false))
    draw_row("Bullet TP", tp_on and "ON" or "OFF", row_color(tp_on, true, false))

    local manip_ok = manip_state == "ready" or manip_state == "direct"
    local manip_warn = manip_state == "scanning"
    draw_row("Manip", manip_on and manip_label or "OFF",
        row_color(manip_on, manip_ok, manip_warn))

    local fire_col = theme.CYAN
    if fire_mode == "tp" then
        fire_col = { 0.82, 0.5, 1, 1 }
    elseif fire_mode == "hitscan" then
        fire_col = theme.CYAN
    elseif fire_mode == "ready" or fire_mode == "direct" then
        fire_col = theme.GREEN
    elseif fire_mode == "scanning" or fire_mode == "blocked" then
        fire_col = theme.ORANGE
    end
    draw_row("Fire", fire_label, fire_col)

    if has_bar then
        local bar_w = panel_w - pad_x * 2
        local bar_x = x + pad_x
        local bar_y = ry + 2
        local ready = manip_state == "ready" or manip_state == "direct"
        local prog
        if ready then
            prog = 1
        elseif manip_state == "scanning" then
            prog = 0.25 + scan_anim * 0.65
        else
            prog = math.max(0, math.min(1, info.scan_progress or 0))
        end

        local bg = theme.alpha(overlay_theme.panel_bg(), 0.95)
        local border = overlay_theme.border(0.5)
        local fill = ready and theme.GREEN or theme.alpha(overlay_theme.accent(), 0.9)

        if draw and draw.rect_filled then
            draw.rect_filled(bar_x, bar_y, bar_w, bar_h, bg, 0)
            if prog > 0.01 then
                draw.rect_filled(bar_x, bar_y, bar_w * prog, bar_h, fill, 0)
            end
            if draw.rect then
                draw.rect(bar_x, bar_y, bar_w, bar_h, border, 0, 1)
            end
        end
    end
end

local function draw_peek_visual(info, track)
    if not settings.bool(PREFIX .. "manip_peek_vis", false) then return end
    if not info or not info.peek then return end
    if info.manip_state ~= "ready" and info.manip_state ~= "direct" and not info.body_peek then return end

    local body = combat_origin.get_server_origin()
    if not body then return end

    local peek = info.peek
    local col_peek = { 1, 0.85, 0.2, 0.95 }
    local eye_y = peek.y + manip_math.eye_offset_y()

    desync_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
    desync_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.35 }, 1)

    local aim = info.hitpart or (track and track.aim)
    local ray_from = manip_math.peek_track_origin(peek, track and track.origin, body)
    if ray_from and aim then
        desync_vis.draw_link(ray_from, aim, { 1, 0.45, 0.2, 0.55 }, 1.5)
        desync_vis.draw_cross(ray_from.x, ray_from.y, ray_from.z, 0.4, col_peek, 2)
    end
end

function M.draw(cx, cy, fov, track)
    if not settings.bool(P_BULLET, false) then return end
    if not draw then return end

    local info = track and track.manip
    if not info then return end

    local show_hud = settings.bool(PREFIX .. "manip_status", false)
    local show_peek = settings.bool(PREFIX .. "manip_peek_vis", false)
    if not show_hud and not show_peek then return end

    draw_peek_visual(info, track)
    draw_status_panel(cx, cy, fov, info)
end

return M

end)()

-- ── features/combat/camera_aimbot.lua ──
April._mods["features.combat.camera_aimbot"] = (function()
-- Camera aimbot: velocity + automatic bullet-drop prediction (weapon stats from dump/toolinfo).
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local aim_key = April.require("core.aim_key")
local theme = April.require("core.ui_theme")

local M = {}

local locked_target = nil
local PREFIX = "april_aim_"
local P_MASTER = "april_aimbot"
local P_AIM_KEY = "april_aim_key"
local P_AIM_KEY_MODE = "april_aim_key_mode"
local TARGET_SCAN_MS = 33

local cached_aim = nil
local smoothed_aim = nil
local last_target_scan = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if lp and lp.tool_name and lp.tool_name ~= "" then
        return weapons.is_ranged_weapon_name(lp.tool_name)
    end
    return false
end

local function enabled()
    return settings.bool(P_MASTER, false)
end

local function aiming()
    if not enabled() then return false end
    aim_key.tick(P_AIM_KEY, P_AIM_KEY_MODE)
    return aim_key.active(P_AIM_KEY, P_AIM_KEY_MODE)
end

local function smooth_alpha()
    local n = settings.num(PREFIX .. "smooth", 10)
    n = math.max(1, math.min(25, n))
    return math.max(0.08, math.min(0.95, 1.25 / n))
end

local function blend_aim(prev, nxt)
    if not nxt then return prev end
    if not prev then return { x = nxt.x, y = nxt.y, z = nxt.z } end
    local a = smooth_alpha()
    return {
        x = prev.x + (nxt.x - prev.x) * a,
        y = prev.y + (nxt.y - prev.y) * a,
        z = prev.z + (nxt.z - prev.z) * a,
    }
end

local function update_target(cx, cy, fov)
    local sticky = settings.multi(PREFIX .. "options", combat_menu.OPT_STICKY, false)
    local now = tick_ms()

    -- NPCs: refresh live head every frame (stale lx/ly/lz + look_at = glued lock).
    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end

    -- Always drop invalid locks (silent parity). Sticky only skips reacquire.
    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
        locked_target = nil
        smoothed_aim = nil
    end

    if locked_target and sticky then
        return
    end

    -- Non-sticky: rescan every frame so FOV pick matches where you look (like silent).
    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

local function resolve_aim_point(target, cx, cy)
    local predict_origin = combat_origin.get_muzzle_origin()
        or combat_origin.get_fire_origin()
        or combat_origin.get_camera_origin()
    return targeting.get_aim_point(target, PREFIX, nil, predict_origin, cx, cy, true)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu.add_checkbox(T, G, P_MASTER, "Enable Aimbot", false)

    menu.add_combo(T, G, P_AIM_KEY_MODE, "Aim Key Mode", { "Always", "Hold", "Toggle" }, 1,
        { parent = P_MASTER })
    if menu.add_hotkey then
        menu.add_hotkey(T, G, P_AIM_KEY, "Aim Key", 0, { parent = P_MASTER, default_mode = 1 })
    end
    if menu and menu.set_visible then
        pcall(menu.set_visible, P_AIM_KEY_MODE, false)
    end

    combat_menu.register_aimbot(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 120,
        fov_color = theme.GREEN or { 0.2, 1, 0.45, 1 },
        line_color = { 0.2, 1, 0.45, 1 },
    })

    menu_util.bind_children(P_MASTER, {
        P_AIM_KEY, P_AIM_KEY_MODE,
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "smooth",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "max_dist", PREFIX .. "fov",
    })

    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })
end

function M.update(_dt)
    cached_aim = nil

    if not enabled() then
        locked_target = nil
        smoothed_aim = nil
        return
    end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 120)

    update_target(cx, cy, fov)

    if holding_weapon() then
        combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

        local wl_target = locked_target
        if not wl_target or not targeting.is_aim_target(wl_target) then
            wl_target = targeting.find_target(cx, cy, fov, PREFIX, { ignore_whitelist = true })
        end
        silent_whitelist.tick(wl_target, PREFIX)
    end

    if not locked_target or not targeting.is_aim_target(locked_target) then
        smoothed_aim = nil
        return
    end

    local aim = resolve_aim_point(locked_target, cx, cy)
    if not aim then
        smoothed_aim = nil
        return
    end

    if aiming() and holding_weapon() then
        smoothed_aim = blend_aim(smoothed_aim, aim)
        cached_aim = smoothed_aim

        if camera and camera.look_at then
            local smooth_frames = math.max(1, math.floor(settings.num(PREFIX .. "smooth", 10)))
            pcall(camera.look_at, smoothed_aim.x, smoothed_aim.y, smoothed_aim.z, smooth_frames)
        end
    else
        -- Visuals (target line) use live aim point; camera only moves when aim key is active.
        cached_aim = aim
    end
end

function M.get_target()
    return locked_target
end

function M.get_scoped_target()
    if locked_target then return locked_target end
    if not enabled() then return nil end
    local sw, sh = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 120)
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, PREFIX)
end

function M.draw()
    if not enabled() then return end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 120)

    if settings.bool(PREFIX .. "draw_fov", false) then
        local col = settings.color(PREFIX .. "draw_fov", { 0.2, 1, 0.45, 1 })
        local filled = settings.num(PREFIX .. "fov_style", 1) == 1

        if filled and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "draw_fov", { 0.2, 1, 0.45, 0.12 })
            local c = { fill[1], fill[2], fill[3], (fill[4] or 1) * 0.25 }
            draw.circle_filled(cx, cy, fov, c, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if locked_target and settings.bool(PREFIX .. "target_line", false) then
        local aim = cached_aim or smoothed_aim or resolve_aim_point(locked_target, cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 0.2, 1, 0.45, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M

end)()

-- ── features/combat/body_peek.lua ──
April._mods["features.combat.body_peek"] = (function()
-- Micro HRP autopeek for bullet manip: desync, move to peek, undesync when target lost/hidden.
local settings = April.require("core.settings")
local env = April.require("core.env")
local cframe_move = April.require("core.cframe_move")
local manip_math = April.require("core.manip_math")
local misc_gate = April.require("core.misc_gate")
local targeting = April.require("features.combat.targeting")

local M = {}

local MAX_OFFSET = 7
local SAME_PEEK_EPS = 0.35
local TICK_TIMEOUT_MS = 180

local active = false
local peek_pos = nil
local ctx = nil
local last_tick_ms = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function desync_mod()
    local ok, mod = pcall(function()
        return April.require("features.movement.desync")
    end)
    if ok then return mod end
    return nil
end

local function hrp()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    return cframe_move.find_part(char, "HumanoidRootPart")
end

local function same_pos(a, b)
    if not a or not b then return false end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx + dy * dy + dz * dz) <= SAME_PEEK_EPS * SAME_PEEK_EPS
end

local function clamp_peek_to_body(peek, cur, max_radius)
    local max_y = manip_math.max_y_offset and manip_math.max_y_offset() or 2.5
    local dy = peek.y - cur.y
    if dy > max_y then
        peek.y = cur.y + max_y
    elseif dy < -max_y then
        peek.y = cur.y - max_y
    end

    local dx = peek.x - cur.x
    dy = peek.y - cur.y
    local dz = peek.z - cur.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    max_radius = math.min(MAX_OFFSET, tonumber(max_radius) or 1)
    if dist < 0.05 or dist > max_radius + 0.5 then
        return nil
    end
    return peek
end

function M.enabled()
    return settings.bool("april_bullet_enabled", false)
        and settings.bool("april_silent_bullet_manip", false)
        and settings.bool("april_bullet_body_peek", false)
end

function M.is_active()
    return active
end

function M.get_peek_pos()
    return peek_pos
end

function M.release()
    if not active then return end

    local desync = desync_mod()
    if desync and desync.peek_end then
        pcall(desync.peek_end)
    end

    active = false
    peek_pos = nil
    ctx = nil
end

local function begin_desync()
    local desync = desync_mod()
    if desync and desync.peek_begin then
        pcall(desync.peek_begin)
    end
end

local function move_to_peek(peek, target, hitpart)
    local root = hrp()
    if not root then return nil end

    local cur = cframe_move.read_pos(root)
    if not cur then return nil end

    if not manip_math.is_visible_from_pos(peek, hitpart) then
        return nil
    end

    if not same_pos(cur, peek) then
        begin_desync()
        cframe_move.set_position_only(root, peek.x, peek.y, peek.z)
    elseif not active then
        begin_desync()
    end

    peek_pos = { x = peek.x, y = peek.y, z = peek.z }
    ctx = { target = target, hitpart = hitpart }
    active = true
    last_tick_ms = tick_ms()
    return peek_pos
end

-- Apply a known manip peek: desync, move body, hold until tick() releases.
function M.ensure_peek(peek, hitpart, target, max_radius)
    if not M.enabled() then return nil end
    if not misc_gate.movement_allowed() then return nil end
    if not peek or not hitpart then return nil end

    local root = hrp()
    if not root then return nil end

    local cur = cframe_move.read_pos(root)
    if not cur then return nil end

    peek = clamp_peek_to_body({ x = peek.x, y = peek.y, z = peek.z }, cur, max_radius)
    if not peek then return nil end

    if active and peek_pos and same_pos(peek_pos, peek) then
        ctx = { target = target, hitpart = hitpart }
        last_tick_ms = tick_ms()
        return peek_pos
    end

    return move_to_peek(peek, target, hitpart)
end

-- Find a peek when silent ring fails, then desync + move.
function M.try_peek(body, hitpart, max_radius, target)
    if not M.enabled() then return nil end
    if not misc_gate.movement_allowed() then return nil end
    if not body or not hitpart then return nil end

    max_radius = math.min(MAX_OFFSET, tonumber(max_radius) or 1)
    if max_radius < 0.15 then return nil end

    local root = hrp()
    if not root then return nil end

    local cur = cframe_move.read_pos(root)
    if not cur then return nil end

    local peek = manip_math.find_manipulation_position(body, hitpart, {
        base_radius = math.min(1, max_radius),
        extend = max_radius > 1.05,
        extend_extra = math.max(0, max_radius - 1),
    })
    if not peek then return nil end

    peek = clamp_peek_to_body(peek, cur, max_radius)
    if not peek then return nil end

    return M.ensure_peek(peek, hitpart, target, max_radius)
end

local function target_alive(target)
    if not target then return false end
    if targeting.is_npc_target(target) then
        target = targeting.refresh_npc_target(target)
        return target ~= nil and targeting.is_aim_target(target)
    end
    return targeting.is_aim_target(target)
end

-- Called each combat frame with the current target + aim bone.
function M.tick(target, hitpart)
    last_tick_ms = tick_ms()

    if not active then return end

    if not M.enabled() then
        M.release()
        return
    end

    if hitpart then
        if ctx then ctx.hitpart = hitpart end
    end

    if target then
        if ctx then ctx.target = target end
    end

    if not ctx or not peek_pos or not ctx.hitpart then
        M.release()
        return
    end

    if not target_alive(ctx.target) then
        M.release()
        return
    end

    if not manip_math.is_visible_from_pos(peek_pos, ctx.hitpart) then
        M.release()
        return
    end
end

function M.update(_dt)
    if not active then return end
    if tick_ms() - last_tick_ms > TICK_TIMEOUT_MS then
        M.release()
    end
end

function M.register_menu()
end

function M.draw()
end

return M

end)()

-- ── features/combat/aimbot.lua ──
April._mods["features.combat.aimbot"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local bullet_hud = April.require("features.combat.bullet_hud")
local body_peek = April.require("features.combat.body_peek")
local theme = April.require("core.ui_theme")

local M = {}
local locked_target = nil
local PREFIX = "april_silent_"
local P_MASTER = "april_silent_aim"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 33

local cached_track = { origin = nil, aim = nil, manip = { state = "off" }, tracking = false }
local last_target_scan = 0
local fire_was_down = false
local shot_allowed = true

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if lp and lp.tool_name and lp.tool_name ~= "" then
        return weapons.is_ranged_weapon_name(lp.tool_name)
    end
    return false
end

local P_BULLET = "april_bullet_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Silent Aim", false)

    combat_menu.register_silent_aim(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 150,
        fov_color = theme.CYAN,
        line_color = theme.RED,
    })

    menu.add_checkbox(T, G.SILENT_AIM, P_BULLET, "Enable Bullet", false)
    combat_menu.register_bullet(T, G.SILENT_AIM, PREFIX, P_BULLET)

    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "hit_chance", PREFIX .. "max_dist", PREFIX .. "fov",
    })

    menu_util.bind_children(P_BULLET, {
        PREFIX .. "hitscan",
        PREFIX .. "bullet_tp",
        PREFIX .. "bullet_manip", PREFIX .. "manip_dist", PREFIX .. "manip_extend", PREFIX .. "manip_extend_dist",
        "april_bullet_body_peek",
        PREFIX .. "manip_status", PREFIX .. "manip_peek_vis",
    })

    menu_util.bind_children(PREFIX .. "bullet_manip", {
        PREFIX .. "manip_dist", PREFIX .. "manip_extend", PREFIX .. "manip_extend_dist",
        "april_bullet_body_peek",
    })

    menu_util.bind_children(PREFIX .. "manip_extend", {
        PREFIX .. "manip_extend_dist",
    })

    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })
end

local function silent_active()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

local function bullet_track_active()
    return settings.bool(P_BULLET, false)
        and silent_resolve.any_bullet_feature()
        and silent_ray.available()
end

local function active()
    return silent_active() or bullet_track_active()
end

local function update_target(cx, cy, fov, find_opts)
    local sticky = settings.multi(PREFIX .. "options", 1, false)
    local now = tick_ms()
    find_opts = find_opts or {}

    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end

    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov, find_opts) then
        locked_target = nil
    end

    if locked_target and sticky then
        return
    end

    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX, find_opts)
end

function M.update(dt)
    bullet_hud.update(dt)
    cached_track.origin = nil
    cached_track.aim = nil
    cached_track.manip = { state = "off" }
    cached_track.tracking = false

    -- Ragebot owns the silent hook while active.
    local rage_on = settings.enabled("april_rage_enabled")
    if rage_on then
        locked_target = nil
        fire_was_down = false
        shot_allowed = true
        body_peek.tick(nil, nil)
        return
    end

    if not active() then
        locked_target = nil
        fire_was_down = false
        shot_allowed = true
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end

    silent_ray.ensure_hook()

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local use_silent_fov = silent_active()
    local fov = use_silent_fov and settings.num(PREFIX .. "fov", 150) or 99999
    local find_opts = use_silent_fov and {} or { ignore_fov = true }
    if silent_resolve.bypass_visibility() then
        find_opts.ignore_visible = true
    end

    if not holding_weapon() then
        silent_ray.stop()
        if use_silent_fov then
            update_target(cx, cy, fov, find_opts)
        end
        return
    end

    combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

    update_target(cx, cy, fov, find_opts)

    local wl_target = locked_target
    if not wl_target or not targeting.is_aim_target(wl_target) then
        wl_target = targeting.find_target(cx, cy, fov, PREFIX, {
            ignore_whitelist = true,
            ignore_fov = find_opts.ignore_fov,
            ignore_visible = find_opts.ignore_visible,
        })
    end
    silent_whitelist.tick(wl_target, PREFIX)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end

    -- Hit chance only for silent aim mouse-fire (not bullet-only).
    if use_silent_fov then
        local firing = input and input.is_key_down and input.is_key_down(SHOOT_VK)
        if firing and not fire_was_down then
            local hit_chance = settings.num(PREFIX .. "hit_chance", 100)
            if hit_chance >= 100 then
                shot_allowed = true
            else
                local roll = math.random(1, 100)
                shot_allowed = roll <= hit_chance
            end
        elseif not firing then
            shot_allowed = true
        end
        fire_was_down = firing and true or false

        if not shot_allowed then
            silent_ray.stop()
            return
        end
    else
        shot_allowed = true
        fire_was_down = false
    end

    local ok_resolve, origin, aim, manip_info = pcall(silent_resolve.resolve_track, locked_target, PREFIX, cx, cy)
    if not ok_resolve or not aim or not origin then
        silent_ray.stop()
        if manip_info then
            cached_track.manip = manip_info
        end
        return
    end

    cached_track.origin = origin
    cached_track.aim = aim
    cached_track.manip = manip_info or { state = "off" }

    local info = cached_track.manip
    local ok_track = false
    local hit = info.hitpart or aim
    local track_aim = aim
    if use_silent_fov then
        if info.use_curve and silent_ray.track_curve then
            ok_track = silent_ray.track_curve(
                origin, hit, info.weapon, SHOOT_VK, hit
            ) == true
            if not info.curve_path and silent_ray.last_curve then
                local curve = silent_ray.last_curve()
                if curve and curve.path then
                    info.curve_path = curve.path
                end
            end
        else
            ok_track = silent_ray.track(origin, track_aim, SHOOT_VK, hit) == true
        end
    else
        -- Bullet-only: per-frame set (works without holding LMB).
        ok_track = silent_ray.set_target(origin, track_aim, hit) == true
    end
    cached_track.aim = track_aim
    cached_track.tracking = ok_track
    body_peek.tick(locked_target, hit)
end

function M.get_target()
    return locked_target
end

-- Gear / tracers: FOV target while silent aim is on (even without a gun out).
function M.get_scoped_target()
    if locked_target then return locked_target end
    if not settings.enabled(P_MASTER) then return nil end

    local sw, sh = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 150)
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, PREFIX)
end

local function snapline_aim_point(cx, cy)
    if cached_track.aim then
        return cached_track.aim
    end
    if not locked_target then
        return nil
    end
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    return targeting.get_aim_point(locked_target, PREFIX, nil, origin, cx, cy, false)
end

function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    if silent_active() and settings.bool(PREFIX .. "draw_fov", false) then
        local col = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 1 })
        local filled = settings.num(PREFIX .. "fov_style", 1) == 1

        if filled and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 0.12 })
            local c = { fill[1], fill[2], fill[3], (fill[4] or 1) * 0.25 }
            draw.circle_filled(cx, cy, fov, c, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if settings.bool(P_BULLET, false) then
        bullet_hud.draw(cx, cy, fov, cached_track)
    end

    if silent_active() and locked_target and settings.bool(PREFIX .. "target_line", false) then
        local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
        local aim = snapline_aim_point(cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                -- Same as camera aimbot: from screen center, not bottom.
                local a = col[4] or 1
                draw_util.line(cx, cy, tx, ty, { 0, 0, 0, a * 0.9 }, 3)
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M

end)()

-- ── features/combat/ragebot.lua ──
April._mods["features.combat.ragebot"] = (function()
-- Ragebot: no FOV, range + filters, autofire. Bullet hitscan/TP/manip come only from Bullet section.
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local bullet_hud = April.require("features.combat.bullet_hud")
local body_peek = April.require("features.combat.body_peek")
local silent_whitelist = April.require("features.combat.silent_whitelist")

local M = {}

local PREFIX = "april_rage_"
local P_MASTER = "april_rage_enabled"
local TARGET_SCAN_MS = 33

local locked_target = nil
local last_target_scan = 0
local last_fire_ms = 0
local cached = { origin = nil, aim = nil, manip = { state = "off" } }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if lp and lp.tool_name and lp.tool_name ~= "" then
        return weapons.is_ranged_weapon_name(lp.tool_name)
    end
    return false
end

local function enabled()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

local function update_target(cx, cy)
    local sticky = settings.multi(PREFIX .. "options", combat_menu.OPT_STICKY, false)
    local now = tick_ms()
    local opts = { ignore_fov = true }
    if silent_resolve.bypass_visibility() then
        opts.ignore_visible = true
    end

    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end

    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, 99999, opts) then
        locked_target = nil
    end

    if locked_target and sticky then
        return
    end

    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, 99999, PREFIX, opts)
end

-- When Bullet manip is on: only autofire wall peeks if a peek is ready.
-- Clear / direct / normal muzzle shots always allowed (same as silent).
local function ok_to_fire(info, aim)
    if not info then return false end

    if info.state == "ready" or info.state == "direct" or info.state == "hitscan" or info.state == "tp" or info.state == "curve" then
        return true
    end

    -- Manip scanning/blocked with no fallback aim should not click.
    if not aim then return false end
    return true
end

local function try_autofire()
    if not settings.bool(PREFIX .. "autofire", true) then return end
    local delay = math.max(20, settings.num(PREFIX .. "fire_delay", 80))
    local now = tick_ms()
    if now - last_fire_ms < delay then return end

    if utility and utility.mouse_click then
        pcall(utility.mouse_click, "left")
        last_fire_ms = now
    elseif input and input.key_press then
        pcall(input.key_press, 0x01)
        last_fire_ms = now
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Ragebot", false)

    menu_util.section(T, G.SILENT_AIM, "Ragebot Targeting")
    menu.add_combo(T, G.SILENT_AIM, PREFIX .. "target_type", "Target Type", { "Crosshair", "Distance" }, 1,
        { parent = P_MASTER })
    menu.add_combo(T, G.SILENT_AIM, PREFIX .. "bone", "Hitbox", combat_menu.SILENT_BONES, 0, { parent = P_MASTER })
    menu.add_multicombo(T, G.SILENT_AIM, PREFIX .. "targets", "Aim At", {
        "Players", "NPCs",
    }, { true, false }, { parent = P_MASTER })
    menu.add_multicombo(T, G.SILENT_AIM, PREFIX .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { true, false, true, true, false, true }, { parent = P_MASTER })
    menu.add_input(T, G.SILENT_AIM, PREFIX .. "whitelist_ids", "Whitelist IDs", "")
    if menu and menu.set_visible then
        pcall(menu.set_visible, PREFIX .. "whitelist_ids", false)
    end
    menu.add_button(T, G.SILENT_AIM, PREFIX .. "whitelist_clear", "Clear Whitelist", function()
        if silent_whitelist and silent_whitelist.clear then
            silent_whitelist.clear(PREFIX)
        end
    end)
    menu.add_slider_int(T, G.SILENT_AIM, PREFIX .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = P_MASTER })

    menu_util.section(T, G.SILENT_AIM, "Ragebot Fire")
    menu.add_multicombo(T, G.SILENT_AIM, PREFIX .. "options", "Options", { "Sticky Target" }, { false },
        { parent = P_MASTER })
    menu.add_checkbox(T, G.SILENT_AIM, PREFIX .. "autofire", "Autofire", true, { parent = P_MASTER })
    menu.add_slider_int(T, G.SILENT_AIM, PREFIX .. "fire_delay", "Fire Delay (ms)", 20, 400, 80,
        { parent = P_MASTER })

    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "max_dist",
        PREFIX .. "autofire", PREFIX .. "fire_delay",
    })
end

function M.update(dt)
    bullet_hud.update(dt)
    cached.origin = nil
    cached.aim = nil
    cached.manip = { state = "off" }

    if not enabled() then
        locked_target = nil
        body_peek.tick(nil, nil)
        return
    end

    silent_ray.ensure_hook()

    if not holding_weapon() then
        silent_ray.stop()
        return
    end

    combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    update_target(cx, cy)

    local wl_target = locked_target
    if not wl_target or not targeting.is_aim_target(wl_target) then
        wl_target = targeting.find_target(cx, cy, 99999, PREFIX, {
            ignore_fov = true,
            ignore_whitelist = true,
            ignore_visible = opts.ignore_visible,
        })
    end
    silent_whitelist.tick(wl_target, PREFIX)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end

    local ok_resolve, origin, aim, manip_info = pcall(
        silent_resolve.resolve_track, locked_target, PREFIX, cx, cy
    )
    if manip_info then
        cached.manip = manip_info
    end
    if not ok_resolve or not aim or not origin then
        silent_ray.stop()
        return
    end

    cached.origin = origin
    cached.aim = aim

    if not ok_to_fire(manip_info, aim) then
        silent_ray.stop()
        return
    end

    local hit = (manip_info and manip_info.hitpart) or aim
    local track_aim = aim
    -- Prefer key-track so engine fire path matches silent; also set for autofire frames.
    if silent_ray.track then
        silent_ray.track(origin, track_aim, 0x01, hit)
    end
    silent_ray.set_target(origin, track_aim, hit)

    try_autofire()
    body_peek.tick(locked_target, hit)
end

function M.get_target()
    return locked_target
end

function M.get_scoped_target()
    if locked_target then return locked_target end
    if not enabled() then return nil end
    local sw, sh = targeting.screen_center()
    return targeting.find_target(sw * 0.5, sh * 0.5, 99999, PREFIX, { ignore_fov = true })
end

function M.draw()
    if not settings.bool("april_bullet_enabled", false) then return end
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)
    bullet_hud.draw(cx, cy, fov, cached)
end

return M

end)()

-- ── features/combat/perfect_farm.lua ──
April._mods["features.combat.perfect_farm"] = (function()
--[[
  Farm helper - silent or camera aim at gather hit parts.
  Melee uses camera / mouse unit-ray origin (RaycastUtil.MouseRaycast).
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local debug = April.require("core.debug")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")
local esp_util = April.require("core.esp_util")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local P_SMOOTH = "april_farm_smooth"
local P_SILENT = "april_farm_silent"
local SHOOT_VK = 0x01

local gather_parts = {}
local locked_part = nil
local lock_grace_until = 0
local next_scan_ms = 0
local next_pick_ms = 0

local SCAN_MS = 1800
local PICK_MS = 66
local LOCK_GRACE_MS = 350
local PICK_FOV = 160
local MAX_NEAR = 28

M._tracking = false

local cx, cy = 960, 540
local cx_init = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function ensure_screen_center()
    if cx_init then return end
    if draw and draw.get_screen_size then
        cx, cy = draw.get_screen_size()
        cx, cy = cx * 0.5, cy * 0.5
    elseif utility and utility.get_screen_size then
        cx, cy = utility.get_screen_size()
        cx, cy = cx * 0.5, cy * 0.5
    end
    cx_init = true
end

local function part_position(part)
    if not part or not env.is_valid(part) then return nil end
    local pos = part.Position or part.position
    if not pos or pos.x == nil then return nil end
    return pos
end

local function dist2(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function refresh_near(origin, radius)
    local now = tick_ms()
    if now < next_scan_ms then return end
    next_scan_ms = now + SCAN_MS

    local out = {}
    farm_targets.collect_near(origin, radius, out, MAX_NEAR)
    gather_parts = out
end

local function ray_origin()
    return silent_ray.get_camera_origin()
end

local function effective_radius(tool_name)
    local tool_range = farm_tools.melee_range(tool_name)
    local slider = settings.num(P_RADIUS, 7)
    if slider <= 0 then return 0 end
    return math.min(slider, tool_range + 0.15)
end

local function target_valid(part, origin, radius, loose)
    if not env.is_valid(part) then return false end
    local pos = part_position(part)
    if not pos or not origin then return false end
    local limit = loose and (radius * 1.25) or radius
    return dist2(pos, origin) <= limit * limit
end

local function pick_target(origin, radius)
    ensure_screen_center()

    local best_part = nil
    local best_score = math.huge
    local best_fov = math.huge
    local nearest_part = nil
    local nearest_d2 = math.huge
    local r2 = radius * radius

    for i = 1, #gather_parts do
        local part = gather_parts[i]
        if env.is_valid(part) then
            local pos = part_position(part)
            if pos then
                local d2 = dist2(pos, origin)
                if d2 <= r2 then
                    if d2 < nearest_d2 then
                        nearest_d2 = d2
                        nearest_part = part
                    end

                    local sx, sy, on_screen = esp_util.w2s(pos.x, pos.y, pos.z)
                    if on_screen then
                        local fov = math_util.screen_fov_dist(sx, sy, cx, cy)
                        local score = fov + d2 * 1.5e-4
                        if score < best_score then
                            best_score = score
                            best_fov = fov
                            best_part = part
                        end
                    end
                end
            end
        end
    end

    if best_part and best_fov <= PICK_FOV then
        return best_part
    end
    return nearest_part
end

local function resolve_target(origin, radius, force_pick)
    local now = tick_ms()

    if locked_part and target_valid(locked_part, origin, radius, true) then
        lock_grace_until = now + LOCK_GRACE_MS
        return locked_part
    end

    if locked_part and now < lock_grace_until and env.is_valid(locked_part) and part_position(locked_part) then
        return locked_part
    end

    if not force_pick and now < next_pick_ms then
        return locked_part
    end
    next_pick_ms = now + PICK_MS

    local picked = pick_target(origin, radius)
    if picked then
        locked_part = picked
        lock_grace_until = now + LOCK_GRACE_MS
        return picked
    end

    locked_part = nil
    lock_grace_until = 0
    return nil
end

local function silent_mode()
    return settings.bool(P_SILENT, true) and silent_ray.available()
end

local function stop_silent()
    if not M._tracking then return end
    silent_ray.stop()
    M._tracking = false
end

local function clear_lock()
    locked_part = nil
    lock_grace_until = 0
    gather_parts = {}
    next_scan_ms = 0
    next_pick_ms = 0
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Farm")
    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_checkbox(T, G.MISC, P_SILENT, "Silent Farm", false, root)
    menu_util.gap(T, G.MISC)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 10, 7, root)
    menu.add_slider_int(T, G.MISC, P_SMOOTH, "Camera Smoothness", 1, 30, 8, root)
    menu_util.bind_children(P, { P_SILENT, P_RADIUS, P_SMOOTH })
end

function M.update(_dt)
    if not settings.enabled(P) then
        stop_silent()
        clear_lock()
        return
    end

    farm_tools.load()
    local tool_name = farm_tools.get_held_farm_tool_name()
    if not tool_name then
        stop_silent()
        clear_lock()
        return
    end

    local origin = ray_origin()
    if not origin then
        stop_silent()
        clear_lock()
        return
    end

    local radius = effective_radius(tool_name)
    if radius <= 0 then
        stop_silent()
        clear_lock()
        return
    end

    local locked_ok = locked_part and target_valid(locked_part, origin, radius, true)
    if not locked_ok then
        refresh_near(origin, radius)
    end

    local target = resolve_target(origin, radius, locked_ok ~= true)
    if not target then
        stop_silent()
        return
    end

    local aim = part_position(target)
    if not aim then
        stop_silent()
        return
    end

    if silent_mode() then
        silent_ray.ensure_hook()
        if silent_ray.track(origin, aim, SHOOT_VK, aim) then
            M._tracking = true
        else
            debug.error_once("farm:silent", "Silent farm hook unavailable - toggle Silent Farm off for camera aim")
            stop_silent()
        end
        return
    end

    stop_silent()
    if not camera or not camera.look_at then return end
    local smooth = math.max(1, settings.num(P_SMOOTH, 8))
    pcall(camera.look_at, aim.x, aim.y, aim.z, smooth)
end

return M

end)()

-- ── features/combat/gun_mods.lua ──
April._mods["features.combat.gun_mods"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")
local toolinfo_mods = April.require("game.toolinfo_weapon_mods")
local env = April.require("core.env")
local notify = April.require("core.notify")

local M = {}
local P = "april_gunmods_enabled"
local REJOIN_GC_DELAY_MS = 25000
local RETRY_MS = 1200
local RETRY_MAX_MS = 15000
local MIN_SCHEDULE_MS = 450
local STARTUP_DELAY_MS = 3500

M._apply_dirty = false
M._force_apply = false
M._defer_until = 0
M._retry_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0
M._notify_next = false
M._last_held_apply = nil
M._had_applied_mods = false
M._last_applied_keys = nil
M._boot_ms = nil

local MODIFIER_TOGGLES = {
    "april_gm_recoil",
    "april_gm_spread",
    "april_gm_sway",
    "april_gm_fire_rate",
    "april_gm_speed",
    "april_gm_range",
    "april_gm_double_tap",
}

local function tick_ms()
    if M._boot_ms == nil then
        M._boot_ms = utility and utility.get_tick_count and utility.get_tick_count() or 0
    end
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function in_match()
    return env.get_local_player() ~= nil
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local gid = game.game_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return pid .. ":" .. gid .. ":" .. ws_addr
end

local function startup_ready()
    local now = tick_ms()
    return M._boot_ms and (now - M._boot_ms) >= STARTUP_DELAY_MS
end

local function can_apply_now()
    if not settings.enabled(P) then return false end
    if not startup_ready() then return false end
    if not gc.available() then return false end
    if gc.cooldown_remaining_ms() > 0 then return false end
    if not in_match() then return false end
    if not profiles.held_weapon_name() then return false end
    return true
end

local function schedule_apply(delay_ms)
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    local now = tick_ms()
    local wait = math.max(MIN_SCHEDULE_MS, delay_ms or 500)
    local until_ms = now + wait
    if until_ms > M._defer_until then
        M._defer_until = until_ms
    end
    if M._retry_until <= now then
        M._retry_until = now + RETRY_MAX_MS
    end
end

local function clear_apply_state()
    M._apply_dirty = false
    M._force_apply = false
    M._defer_until = 0
    M._retry_until = 0
    M._gc_redo_at = 0
    M._last_held_apply = nil
    M._had_applied_mods = false
    M._last_applied_keys = nil
end

local function build_clear_payload()
    local keys = M._last_applied_keys
    if not keys or not next(keys) then
        return nil
    end
    local out = {}
    for k in pairs(keys) do
        out[k] = 0
    end
    return out
end

local function remember_applied(mods)
    local keys = {}
    if type(mods) == "table" then
        for k in pairs(mods) do
            keys[k] = true
        end
    end
    M._last_applied_keys = keys
end

local function schedule_session_gc_refresh()
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
    M._retry_until = tick_ms() + RETRY_MAX_MS
    M._defer_until = tick_ms() + REJOIN_GC_DELAY_MS
    toolinfo_mods.invalidate()
end

local function clear_all_mods()
    pcall(function()
        local clear = build_clear_payload()
        if clear then gc.apply_weapon(clear) end
    end)
    pcall(toolinfo_mods.reset)
    M._had_applied_mods = false
    M._last_applied_keys = nil
end

function M.schedule_apply(delay_ms)
    schedule_apply(delay_ms)
end

function M.on_session_changed()
    schedule_session_gc_refresh()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.GUN_MODS)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.GUN_MODS, P, "Enable Gun Mods", false)

    menu_util.section(T, G.GUN_MODS, "Modifiers")
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_recoil", "No Recoil", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100,
        menu_util.parent("april_gm_recoil"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_spread", "No Spread", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100,
        menu_util.parent("april_gm_spread"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_sway", "No Sway", false, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_fire_rate", "Fire Rate", false, root)
    menu.add_slider_float(T, G.GUN_MODS, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f",
        menu_util.parent("april_gm_fire_rate"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_speed", "Bullet Speed", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_speed_mult", "Speed Mult", 1, 100, 100,
        menu_util.parent("april_gm_speed"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_range", "Gun Range", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_range_mult", "Range Mult", 1, 20, 10,
        menu_util.parent("april_gm_range"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_double_tap", "Double Tap", false, root)

    menu_util.bind_children(P, {
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
        "april_gm_double_tap",
    })

    menu_util.bind_children("april_gm_recoil", { "april_gm_recoil_pct" })
    menu_util.bind_children("april_gm_spread", { "april_gm_spread_pct" })
    menu_util.bind_children("april_gm_fire_rate", { "april_gm_fire_rate_mult" })
    menu_util.bind_children("april_gm_speed", { "april_gm_speed_mult" })
    menu_util.bind_children("april_gm_range", { "april_gm_range_mult" })

    settings.on_change(P, function()
        if settings.enabled(P) then
            M._notify_next = true
            schedule_apply(800)
        else
            clear_apply_state()
            M.reset_mods()
        end
    end)

    for _, id in ipairs(MODIFIER_TOGGLES) do
        settings.on_change(id, function()
            if settings.enabled(P) then
                M._notify_next = true
                schedule_apply(500)
            end
        end)
    end

    local slider_ids = {
        "april_gm_recoil_pct", "april_gm_spread_pct",
        "april_gm_fire_rate_mult", "april_gm_speed_mult", "april_gm_range_mult",
    }
    for _, id in ipairs(slider_ids) do
        settings.on_change(id, function()
            if settings.enabled(P) then
                schedule_apply(1000)
            end
        end)
    end
end

function M.reset_mods()
    pcall(toolinfo_mods.reset)

    if not gc.available() then
        notify.info("Gun mods disabled", 3000)
        return true
    end

    local mods = build_clear_payload()
    if not mods then
        M._had_applied_mods = false
        notify.info("Gun mods cleared", 3000)
        return true
    end

    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = false
        M._last_applied_keys = nil
        notify.info("Gun mods reset (" .. tostring(count) .. " nodes)", 3500)
    else
        notify.warning("Gun mods reset: " .. tostring(msg or "failed"), 4000)
    end
    return ok
end

function M.try_apply(silent)
    if not settings.enabled(P) then
        return false
    end

    if not can_apply_now() then
        if M._had_applied_mods and not in_match() then
            clear_all_mods()
        end
        return false
    end

    local held = profiles.held_weapon_name()
    if not held then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    if not profiles.should_apply_for_held(held) then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    local mods = profiles.build_mods_for_apply(held)
    local ti_opts, ti_weapon = profiles.build_toolinfo_for_apply(held)
    local has_gc = mods and next(mods)
    local has_ti = ti_opts and ti_opts.double_tap == true

    if not has_gc and not has_ti then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    if not M._force_apply and not M._apply_dirty then
        return true
    end

    local ok_gc, count, msg = true, 0, nil
    if has_gc then
        ok_gc, count, msg = gc.apply_weapon(mods)
        if ok_gc then
            remember_applied(mods)
        end
    else
        local clear = build_clear_payload()
        if clear then
            pcall(gc.apply_weapon, clear)
        end
        M._last_applied_keys = nil
    end

    local ok_ti = true
    local ti_count, ti_msg
    if has_ti then
        ok_ti, ti_count, ti_msg = toolinfo_mods.apply(ti_opts, ti_weapon or held)
    else
        pcall(toolinfo_mods.reset)
    end

    local ok = (not has_gc or ok_gc) and ok_ti
    if ok then
        M._had_applied_mods = true
        M._apply_dirty = false
        M._force_apply = false
        M._retry_until = 0
        if M._notify_next or not silent then
            M._notify_next = false
            local parts = {}
            if has_gc then
                parts[#parts + 1] = tostring(msg or (tostring(count) .. " nodes"))
            end
            if has_ti and ti_count and ti_count > 0 then
                parts[#parts + 1] = tostring(ti_msg or (tostring(ti_count) .. " burst"))
            end
            notify.success("Gun mods applied: " .. table.concat(parts, ", "), 3500)
        end
    else
        M._apply_dirty = true
        M._force_apply = true
        M._defer_until = tick_ms() + RETRY_MS
        if gc.cooldown_remaining_ms() > 0 then
            M._apply_dirty = false
            M._force_apply = false
        end
    end

    return ok
end

function M.tick_session()
    local sid = session_id()
    local match = in_match()

    if M._session_id == nil then
        M._session_id = sid
        M._was_in_match = match
        return
    end

    if sid ~= M._session_id then
        M._session_id = sid
        M.on_session_changed()
    elseif not M._was_in_match and match then
        M.on_session_changed()
    end

    M._was_in_match = match
end

function M.on_weapon_equip_changed(held)
    if held == M._last_held_apply then return end
    M._last_held_apply = held
    if settings.enabled(P) then
        schedule_apply(600)
    end
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then return end

    local held = profiles.held_weapon_name()
    if held ~= M._last_held_apply then
        M.on_weapon_equip_changed(held)
    end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            pcall(gc.refresh_cache)
            toolinfo_mods.invalidate()
            M._apply_dirty = true
            M._force_apply = true
            M._defer_until = now + 800
            M._retry_until = now + RETRY_MAX_MS
            notify.info("Re-applying gun mods after session change...", 2500)
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end
    if not can_apply_now() then return end
    if M._retry_until > 0 and now > M._retry_until then
        M._apply_dirty = false
        M._force_apply = false
        notify.warning("Gun mods: equip a gun in match, then toggle a mod option", 5000)
        return
    end

    M.try_apply(true)
end

function M.on_weapon_changed(name)
    M.on_weapon_equip_changed(name)
end

function M.on_modules_ready()
    toolinfo_mods.invalidate()
    if settings.enabled(P) then
        schedule_apply(1200)
    end
end

function M.draw() end

return M

end)()

-- ── features/utility/mod_checker.lua ──
April._mods["features.utility.mod_checker"] = (function()
local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local theme = April.require("core.ui_theme")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")

local M = {}
local P = "april_mod_checker_enabled"
local X_ID = "april_mod_checker_x"
local Y_ID = "april_mod_checker_y"
local PANEL_W = 260
local HEAD_OFFSET = 3.5
local TITLE_H = 24
local SCAN_MS = 2500
local META_REFRESH_MS = 1000
local LOOKUP_BUDGET = 2

local seen = {}
local active = {}
local panel_rows = {}
local last_scan = -1
local last_meta_refresh = 0
M._session = nil
M._was_enabled = false
M._group_started = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    local job = (game.job_id or game.JobId or "")
    return tostring(pid) .. ":" .. tostring(ws_addr) .. ":" .. tostring(job)
end

local function player_uid(p)
    local uid = tonumber(p.user_id)
    if uid and uid ~= 0 then return uid end
    return p.name or p.display_name
end

function M.reset_state()
    seen = {}
    active = {}
    panel_rows = {}
    last_scan = -1
    last_meta_refresh = 0
end

function M.on_session_changed()
    M.reset_state()
    mod_ids.reset_session()
end

function M.tick_session()
    local sid = session_id()
    if M._session == nil then
        M._session = sid
        last_scan = -1
        return
    end
    if sid ~= M._session then
        M._session = sid
        M.on_session_changed()
    end
end

local function player_label(p)
    if not p then return "Unknown" end
    if p.display_name and p.display_name ~= "" then return p.display_name end
    return p.name or "Unknown"
end

local function format_duration(ms)
    ms = math.max(0, ms or 0)
    local sec = math.floor(ms / 1000)
    if sec < 60 then return sec .. "s" end
    local min = math.floor(sec / 60)
    sec = sec % 60
    if min < 60 then return string.format("%dm %02ds", min, sec) end
    local hr = math.floor(min / 60)
    min = min % 60
    return string.format("%dh %02dm", hr, min)
end

local function head_world_pos(p)
    if p.head_position then
        local hp = p.head_position
        if type(hp) == "table" then
            if hp.x then return hp.x, hp.y + HEAD_OFFSET, hp.z end
            return hp[1], (hp[2] or 0) + HEAD_OFFSET, hp[3]
        end
    end
    if p.position then
        local pos = p.position
        return pos.x, pos.y + HEAD_OFFSET + 1.5, pos.z
    end
    return nil
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Utility")
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false)

    menu_util.section(T, G.MISC, "Mod Checker Scan")
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500, root)

    menu_util.bind_master(P, { "april_mod_checker_interval" })
end

function M.init()
    M.on_session_changed()
    M._session = session_id()
    mod_ids.ensure_started()
    M._group_started = true
end

function M.track_player(p, role)
    local uid = player_uid(p)
    if not uid or uid == "" then return end

    local now = tick_ms()
    if not active[uid] then
        active[uid] = {
            uid = uid,
            label = player_label(p),
            username = p.name or "?",
            role = role,
            first_seen = now,
            player = p,
        }
    else
        local entry = active[uid]
        entry.label = player_label(p)
        entry.username = p.name or entry.username
        entry.role = role
        entry.player = p
    end
end

function M.check_player(p, lookup_budget)
    if not settings.enabled(P) then return lookup_budget end
    if not p or p.is_local then return lookup_budget end

    local queue = lookup_budget and lookup_budget > 0
    local role = mod_ids.role_for_player(p, {
        queue_lookup = queue,
        mark_unknown = not queue,
    })
    if queue and role == nil then
        local uid = tonumber(p.user_id)
        if uid and uid ~= 0 then
            lookup_budget = lookup_budget - 1
        end
    end
    if not role then return lookup_budget end

    local uid = player_uid(p)
    if not uid or uid == "" then return lookup_budget end

    M.track_player(p, role)

    if seen[uid] then return lookup_budget end
    seen[uid] = true
    notify.warning(string.format("%s: %s (%s)", mod_ids.short_label(role), player_label(p), p.name or "?"), 6000)
    return lookup_budget
end

local function rebuild_panel_rows(now)
    local rows = {}
    local me = env.get_local_player()

    for uid, entry in pairs(active) do
        local p = entry.player
        local dist = nil
        if p and me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
        end

        local meta = format_duration(now - (entry.first_seen or now))
        if dist then
            meta = meta .. "  |  " .. dist .. "m"
        end

        rows[#rows + 1] = {
            name = entry.label or entry.username or "Unknown",
            role = mod_ids.short_label(entry.role),
            meta = meta,
            first_seen = entry.first_seen or now,
            accent = theme.role_accent(entry.role),
        }
    end

    table.sort(rows, function(a, b)
        return (a.first_seen or 0) < (b.first_seen or 0)
    end)

    panel_rows = rows
end

local function player_body_alive(p)
    if not p or p.is_local then return false end
    -- Hide badge when dead / no character (stale head_position can linger).
    if p.is_alive == false then return false end
    local char = p.character
    if not char or not env.is_valid(char) then return false end
    local hum = p.humanoid
    if hum ~= nil and not env.is_valid(hum) then return false end
    if p.health ~= nil and p.health <= 0 then return false end
    return true
end

function M.reconcile_active(players)
    local present = {}

    for _, p in ipairs(players) do
        if p.is_local then goto continue end

        local role = mod_ids.role_for_player(p)
        if not role then goto continue end

        local uid = player_uid(p)
        if not uid or uid == "" then goto continue end

        -- Keep lobby list entry, but only attach live body for world badge.
        present[uid] = true
        if player_body_alive(p) then
            M.track_player(p, role)
        elseif active[uid] then
            active[uid].player = nil
            active[uid].role = role
        else
            M.track_player(p, role)
            if active[uid] then active[uid].player = nil end
        end

        ::continue::
    end

    for uid in pairs(active) do
        if not present[uid] then
            active[uid] = nil
            seen[uid] = nil
        end
    end
end

function M.scan_all()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    local players = entity.get_players()
    local lookup_budget = LOOKUP_BUDGET

    M.reconcile_active(players)

    for _, p in ipairs(players) do
        lookup_budget = M.check_player(p, lookup_budget)
    end

    rebuild_panel_rows(tick_ms())
    last_meta_refresh = tick_ms()
end

function M.on_player_added(p)
    M.check_player(p, LOOKUP_BUDGET)
    rebuild_panel_rows(tick_ms())
end

function M.on_player_removed(p)
    if not p then return end
    local uid = player_uid(p)
    if uid and uid ~= "" then
        seen[uid] = nil
        active[uid] = nil
        mod_ids.invalidate_player(p)
        rebuild_panel_rows(tick_ms())
    end
end

function M.staff_role(player)
    if not player then return nil end
    local uid = player_uid(player)
    if uid and active[uid] then
        return active[uid].role
    end
    return mod_ids.role_for_player(player)
end

function M.is_staff(player)
    return M.staff_role(player) ~= nil
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        if M._was_enabled then
            M.reset_state()
            M._group_started = false
        end
        M._was_enabled = false
        return
    end
    M._was_enabled = true

    if not M._group_started then
        mod_ids.ensure_started()
        M._group_started = true
    end

    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if last_scan < 0 or (now - last_scan) >= interval then
        last_scan = now
        M.scan_all()
    end
end

function M.draw_mod_markers()
    if not settings.enabled(P) then return end

    for uid, entry in pairs(active) do
        local p = entry.player
        if not player_body_alive(p) then
            -- Drop dead / despawned bodies from marker set (panel clears on next scan).
            if p and (p.is_alive == false or not p.character or not env.is_valid(p.character)) then
                entry.player = nil
            end
            goto continue
        end

        local wx, wy, wz = head_world_pos(p)
        if not wx then goto continue end

        local sx, sy, vis = esp_util.w2s(wx, wy, wz)
        if not vis then goto continue end

        theme.draw_staff_badge(sx, sy, entry.role)

        ::continue::
    end
end

local function draw_staff_panel(x, y, width, rows)
    if not draw or not draw.text then return end

    overlay_theme.sync()
    local pad = 10
    local row_h = 44
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 6

    local title = "STAFF IN LOBBY"
    if #rows > 1 then
        title = title .. " (" .. #rows .. ")"
    end
    overlay_theme.draw_panel(x, y, width, height, title)

    local div_y = y + TITLE_H
    if draw.line then
        draw.line(x + pad, div_y, x + width - pad, div_y, theme.alpha(theme.BORDER, 0.55), 1)
    end

    local ry = div_y + 6
    if #rows == 0 then
        draw.text(x + pad + 12, ry, "No staff detected", theme.TEXT_MUTED, 11)
        return height
    end

    local max_name = math.max(10, math.floor((width - pad * 2 - 12) / 7))

    for i = 1, #rows do
        local row = rows[i]
        local row_accent = row.accent or theme.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, theme.alpha(theme.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, row_accent, 8)
        end

        local name = row.name or "?"
        if #name > max_name then name = name:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad + 12, ry, name, theme.TEXT, 13)

        local role = row.role or "Staff"
        if #role > max_name then role = role:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, row_accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, row.meta, theme.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end

    return height
end

function M.draw()
    M.draw_mod_markers()

    if not settings.enabled(P) then return end

    local now = tick_ms()
    if now - last_meta_refresh >= META_REFRESH_MS then
        rebuild_panel_rows(now)
        last_meta_refresh = now
    end

    local sw, sh = draw_util.screen_size()
    local row_h = 44
    local count = math.max(#panel_rows, 1)
    local height = TITLE_H + count * row_h + 6

    local x, y = panel_drag.update(
        "mod_checker",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        sw - PANEL_W - 16, 72
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)

    draw_staff_panel(x, y, PANEL_W, panel_rows)
end

return M

end)()

-- ── features/visuals/player_esp.lua ──
April._mods["features.visuals.player_esp"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local player_state = April.require("game.player_state")
local player_gear = April.require("game.player_gear")
local npcs = April.require("game.npcs")
local mod_checker = April.require("features.utility.mod_checker")
local mod_ids = April.require("game.mod_ids")

local M = {}
local P = "april_player_enabled"
local FILTERS = "april_player_esp_filters"
local FLAGS = "april_player_esp_flags"

local ID_HEALTH = "april_player_health"
local ID_SKELETON = "april_player_skeleton"
local ID_NAME = "april_player_show_name"
local ID_DIST = "april_player_show_distance"
local ID_WEAPON = "april_player_show_weapon"
local ID_CLAN = "april_player_clan_tag"
local ID_BOX = "april_player_box_mode"
local ID_RANGE = "april_player_range"
local ID_FLAG_DOWN = "april_player_flag_downed"
local ID_FLAG_SZ = "april_player_flag_safezone"
local ID_FLAG_STAFF = "april_player_flag_staff"
local ID_FLAG_REVIVE = "april_player_flag_reviving"

local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local FL_DOWNED, FL_SAFEZONE, FL_STAFF, FL_REVIVING = 1, 2, 3, 4

local DEFAULT_BOX = { 1, 0.35, 0.35, 1 }
local DEFAULT_TEXT = { 1, 0.35, 0.35, 1 }
local DEFAULT_CLAN = { 0.84, 0.31, 0.80, 1 }
local DEFAULT_MUTED = { 0.82, 0.84, 0.88, 0.92 }
local DEFAULT_FLAG = {
    DOWN = { 1, 0.35, 0.35, 1 },
    SZ = { 0.35, 0.85, 1, 1 },
    STAFF = { 1, 0.33, 0.33, 1 },
    REVIVE = { 0.45, 1, 0.55, 1 },
}

local _wpn_cache = {}
local _bounds_cache = {}
local WPN_TTL_MS = 220
local BOUNDS_TTL_MS = 1200

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function cache_key(p)
    return tostring(p.user_id or 0) .. ":" .. tostring(p.name or "")
end

local function held_weapon_name(p)
    local key = cache_key(p)
    local now = tick_ms()
    local ent = _wpn_cache[key]
    if ent and (now - ent.t) < WPN_TTL_MS then
        return ent.name
    end
    local name = nil
    pcall(function()
        name = player_gear.held_name(p)
    end)
    if name and player_gear.is_empty_held_name and player_gear.is_empty_held_name(name) then
        name = nil
    end
    _wpn_cache[key] = { t = now, name = name }
    return name
end

local function box_color()
    return settings.color(P, DEFAULT_BOX)
end

local function resolve_color(_p)
    return box_color()
end

local function filter_opts()
    local downed = 1
    if settings.multi(FILTERS, F_SKIP_DOWNED, false) then
        downed = 0
    end
    return {
        team = settings.multi(FILTERS, F_TEAM, true),
        skip_sz = settings.multi(FILTERS, F_SAFEZONE, false),
        downed = downed,
    }
end

local function passes_player_filters(p, opts)
    if not p or p.is_local then return false end
    if p.is_workspace_entity or (p.user_id or 0) == 0 then return false end
    if npcs.kind(p.name) then return false end
    if not player_state.is_combat_target(p) then return false end
    if opts.team and not player_state.passes_team_check(p) then return false end
    if opts.downed ~= 1 and not player_state.passes_downed_check(p, opts.downed) then
        return false
    end
    if opts.skip_sz and not player_state.passes_safezone_check(p, true) then
        return false
    end
    return true
end

local function set_multi_defaults(id, values)
    if menu and menu.set then
        pcall(menu.set, id, values)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Player ESP")
    menu_util.register_keybind(T, G.VISUALS, P, "Player ESP", false, {
        colorpicker = DEFAULT_BOX,
    })

    menu.add_combo(T, G.VISUALS, ID_BOX, "Player Box", { "None", "2D", "Corner" }, 1, { parent = P })

    menu.add_checkbox(T, G.VISUALS, ID_HEALTH, "Player Health Bar", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_SKELETON, "Player Skeleton", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.92 } }))
    menu.add_checkbox(T, G.VISUALS, ID_NAME, "Player Name", true,
        menu_util.parent(P, { colorpicker = DEFAULT_TEXT }))
    menu.add_checkbox(T, G.VISUALS, ID_CLAN, "Player Clan Tag", true,
        menu_util.parent(P, { colorpicker = DEFAULT_CLAN }))
    menu.add_checkbox(T, G.VISUALS, ID_DIST, "Player Distance", true,
        menu_util.parent(P, { colorpicker = DEFAULT_MUTED }))
    menu.add_checkbox(T, G.VISUALS, ID_WEAPON, "Player Weapon", false,
        menu_util.parent(P, { colorpicker = DEFAULT_MUTED }))

    menu.add_multicombo(T, G.VISUALS, FILTERS, "ESP Filters", {
        "Team Check", "Skip Safezone", "Skip Downed",
    }, { false, false, false }, { parent = P })
    set_multi_defaults(FILTERS, { true, false, false })

    menu.add_multicombo(T, G.VISUALS, FLAGS, "ESP Flags", {
        "Downed", "Safezone", "Staff", "Reviving",
    }, { false, false, false, false }, { parent = P })
    set_multi_defaults(FLAGS, { true, true, true, true })

    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_DOWN, "Flag Downed Color", DEFAULT_FLAG.DOWN, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_SZ, "Flag Safezone Color", DEFAULT_FLAG.SZ, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_STAFF, "Flag Staff Color", DEFAULT_FLAG.STAFF, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_REVIVE, "Flag Reviving Color", DEFAULT_FLAG.REVIVE, { parent = P })

    menu.add_slider_int(T, G.VISUALS, ID_RANGE, "Player Range", 50, 2000, 500, { parent = P })
    menu_util.gap(T, G.VISUALS)

    local children = {
        ID_BOX, ID_HEALTH, ID_SKELETON,
        ID_NAME, ID_CLAN, ID_DIST, ID_WEAPON,
        FILTERS, FLAGS,
        ID_FLAG_DOWN, ID_FLAG_SZ, ID_FLAG_STAFF, ID_FLAG_REVIVE,
        ID_RANGE,
    }
    menu_util.bind_children(P, children)
end

local function clan_tag_color(snap, menu_col)
    local cc = snap and snap.clan_color
    if cc and cc[1] then return cc end
    return menu_col
end

local function flag_on(index)
    return settings.multi(FLAGS, index, true)
end

local function collect_side_tags(p, snap, show_clan, clan_menu_col, flag_cols)
    local out = {}
    snap = snap or player_state.esp_state(p)
    if not snap then return out end

    if show_clan and snap.clan_tag then
        out[#out + 1] = {
            text = "[" .. snap.clan_tag .. "]",
            col = clan_tag_color(snap, clan_menu_col),
        }
    end

    if flag_on(FL_SAFEZONE) and snap.safezone then
        out[#out + 1] = { text = "[SZ]", col = flag_cols.sz }
    end
    if flag_on(FL_DOWNED) and snap.downed then
        out[#out + 1] = { text = "[DOWN]", col = flag_cols.down }
    end
    if flag_on(FL_STAFF) then
        if snap.staff then
            out[#out + 1] = { text = "[" .. snap.staff .. "]", col = flag_cols.staff }
        else
            local role = mod_checker.staff_role(p)
            if role then
                out[#out + 1] = {
                    text = "[" .. mod_ids.short_label(role) .. "]",
                    col = flag_cols.staff,
                }
            end
        end
    end
    if flag_on(FL_REVIVING) and snap.reviving then
        out[#out + 1] = { text = "[REVIVE]", col = flag_cols.revive }
    end

    return out
end

local function prune_bounds_cache(now)
    for key, ent in pairs(_bounds_cache) do
        if not ent or (now - (ent.t or 0)) > BOUNDS_TTL_MS * 3 then
            _bounds_cache[key] = nil
        end
    end
end

local function resolve_bounds(p, pos, dist)
    local key = cache_key(p)
    local now = tick_ms()

    local fresh = esp_util.player_screen_bounds(p, {
        dist = dist,
        point_size = esp_util.dist_point_size(dist),
    })

    if not esp_util.bounds_usable(fresh) and pos then
        local size = esp_util.dist_point_size(dist)
        fresh = esp_util.point_screen_bounds(pos.x, pos.y, pos.z, size)
        if fresh then
            fresh = esp_util.guard_tiny_bounds(fresh, dist)
        end
    end

    return esp_util.hold_bounds(_bounds_cache, key, fresh, now, BOUNDS_TTL_MS)
end

local function is_on_screen(bounds, pos)
    if pos then
        local _, _, on = esp_util.w2s(pos.x, pos.y, pos.z)
        if on then return true end
    end
    if bounds and bounds.valid then
        local sw, sh = draw_util.screen_size()
        local cx = bounds.x + bounds.w * 0.5
        local cy = bounds.y + bounds.h * 0.5
        local margin = 120
        return cx > -margin and cy > -margin and cx < sw + margin and cy < sh + margin
    end
    return false
end

function M.update(_dt)
end

function M.draw()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    local now = tick_ms()
    prune_bounds_cache(now)

    local range = settings.num(ID_RANGE, 500)
    local range_sq = range * range
    local box_mode = settings.num(ID_BOX, 1)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local opts = filter_opts()

    local show_health = settings.bool(ID_HEALTH, true)
    local show_skel = settings.bool(ID_SKELETON, false)
    local show_name = settings.bool(ID_NAME, true)
    local show_clan = settings.bool(ID_CLAN, true)
    local show_dist = settings.bool(ID_DIST, true)
    local show_wpn = settings.bool(ID_WEAPON, false)

    local skel_col = settings.color(ID_SKELETON, { 1, 1, 1, 0.92 })
    local name_col = settings.color(ID_NAME, DEFAULT_TEXT)
    local clan_menu_col = settings.color(ID_CLAN, DEFAULT_CLAN)
    local dist_col = settings.color(ID_DIST, DEFAULT_MUTED)
    local wpn_col = settings.color(ID_WEAPON, DEFAULT_MUTED)
    local flag_cols = {
        down = settings.color(ID_FLAG_DOWN, DEFAULT_FLAG.DOWN),
        sz = settings.color(ID_FLAG_SZ, DEFAULT_FLAG.SZ),
        staff = settings.color(ID_FLAG_STAFF, DEFAULT_FLAG.STAFF),
        revive = settings.color(ID_FLAG_REVIVE, DEFAULT_FLAG.REVIVE),
    }

    for _, p in ipairs(entity.get_players()) do
        if not passes_player_filters(p, opts) then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local dist = 0
        if me_pos then
            local dx = (pos.x or 0) - me_pos.x
            local dy = (pos.y or 0) - me_pos.y
            local dz = (pos.z or 0) - me_pos.z
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end

        local snap = player_state.esp_state(p)
        local col = resolve_color(p)

        -- Skeleton uses bone projections directly (stable at range) — draw even if box fails.
        if show_skel then
            if p.get_bones_screen then
                esp_util.draw_player_skeleton(p, skel_col, 1)
            elseif p.character then
                esp_util.draw_model_skeleton(p.character, skel_col, 1)
            end
        end

        local bounds = resolve_bounds(p, pos, dist)
        if not is_on_screen(bounds, pos) then
            goto continue
        end
        if not esp_util.bounds_usable(bounds) then
            goto continue
        end

        local ts = esp_util.text_size()
        if dist > 250 then
            ts = math.max(11, ts - 1)
        end

        local cx = bounds.x + bounds.w * 0.5

        -- Top: name + weapon only (never clan - clan is on the right with tags)
        local top = {}
        if show_name then
            top[#top + 1] = { text = p.name or "?", col = name_col }
        end
        if show_wpn then
            local wpn = held_weapon_name(p)
            if wpn and wpn ~= "" then
                top[#top + 1] = { text = tostring(wpn), col = wpn_col }
            end
        end

        if #top > 0 then
            local ty = bounds.y - 4 - (#top * (ts + 1))
            for i = 1, #top do
                draw_util.text_centered(cx, ty + (i - 1) * (ts + 1), top[i].text, top[i].col, ts)
            end
        end

        -- Right: clan tag + attribute flags (SZ / DOWN / staff / revive)
        local side = collect_side_tags(p, snap, show_clan, clan_menu_col, flag_cols)
        if #side > 0 then
            local rx = bounds.x + bounds.w + 4
            local ry = bounds.y
            for i = 1, #side do
                draw_util.text(
                    rx,
                    ry + (i - 1) * (ts + 1),
                    side[i].text,
                    side[i].col,
                    ts
                )
            end
        end

        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 1)
        end

        if show_health then
            draw_util.health_bar_on_box(bounds, p.health, p.max_health)
        end

        if show_dist then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                dist_col,
                ts
            )
        end

        ::continue::
    end
end

return M

end)()

-- ── features/visuals/target_overlay.lua ──
April._mods["features.visuals.target_overlay"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local player_state = April.require("game.player_state")
local active_target = April.require("features.combat.active_target")
local text_util = April.require("core.text_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_target_overlay"
local GEAR_SLOTS = 7
local GEAR_TTL = 500
local TARGET_POLL_MS = 120
local MAX_ATTACHMENTS = 5

local gear_cache = {}
local last_poll_ms = 0

M._target = nil
M._layout = nil

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function img_key(prefix, id)
    return prefix .. tostring(id)
end

local function resolve_image_key(piece)
    if not piece then return nil end

    if type(piece) == "table" and piece.asset_id then
        local key = img_key("item_", piece.asset_id)
        image_cache.ensure(key, piece.asset_id)
        return key
    end

    if type(piece) == "table" and piece.name then
        local resolved = items.resolve_item_label(
            piece.variant and (piece.name .. "/" .. piece.variant) or piece.name
        )
        if resolved and resolved.asset_id then
            local key = img_key("item_", resolved.asset_id)
            image_cache.ensure(key, resolved.asset_id)
            return key
        end
        local asset_id = items.get_image_asset_id(piece.name, piece.variant)
        if asset_id then
            local key = img_key("item_", asset_id)
            image_cache.ensure(key, asset_id)
            return key
        end
    end

    return nil
end

local function find_overlay_target()
    local target = active_target.get_target(nil, active_target.SOURCE_GEAR)
    if target then return target end
    return nil
end

local function get_gear(player)
    if not player then return nil end
    local uid = player.user_id or player.name or "?"
    local now = tick_ms()
    local cached = gear_cache[uid]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end
    local data = player_gear.scan_player(player)
    gear_cache[uid] = { t = now, data = data }
    return data
end

local function armor_sort_key(piece)
    local n = (piece.name or ""):lower()
    if n:find("helmet", 1, true) or n:find("head", 1, true) or n:find("cap", 1, true)
        or n:find("wrap", 1, true) or n:find("balaclava", 1, true) or n:find("hood", 1, true) then
        return 1
    end
    if n:find("chest", 1, true) or n:find("plate", 1, true) or n:find("shirt", 1, true)
        or n:find("jacket", 1, true) or n:find("hoodie", 1, true) or n:find("vest", 1, true)
        or n:find("suit", 1, true) or n:find("torso", 1, true) then
        return 2
    end
    if n:find("legging", 1, true) or n:find("pants", 1, true) or n:find("shorts", 1, true) then
        return 3
    end
    if n:find("glove", 1, true) or n:find("handwrap", 1, true) then
        return 4
    end
    if n:find("boot", 1, true) or n:find("footwrap", 1, true) or n:find("shoe", 1, true) then
        return 5
    end
    if n:find("backpack", 1, true) or n:find("bag", 1, true) then
        return 6
    end
    return 7
end

local function pack_gear(armor_list)
    local sorted = {}
    for _, piece in ipairs(armor_list or {}) do
        table.insert(sorted, piece)
    end
    table.sort(sorted, function(a, b)
        return armor_sort_key(a) < armor_sort_key(b)
    end)

    local packed = {}
    for _, piece in ipairs(sorted) do
        table.insert(packed, piece)
        if #packed >= GEAR_SLOTS then break end
    end
    return packed
end

local function pack_attachments(list)
    local packed = {}
    for i = 1, math.min(#(list or {}), MAX_ATTACHMENTS) do
        packed[#packed + 1] = list[i]
    end
    return packed
end

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = pack_gear(gear and gear.armor)
    local attachments = pack_attachments(gear and gear.attachments)
    local held_sz = math.floor(gear_sz * 1.28)
    local att_sz = math.floor(gear_sz * 0.78)
    local gap = 5
    local att_gap = 4
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap
    local att_row_w = #attachments > 0 and (#attachments * att_sz + (#attachments - 1) * att_gap) or 0
    local held_row_w = held_sz + (#attachments > 0 and (10 + att_row_w) or 0)
    local panel_w = math.max(row_w, held_row_w)

    local layout = {
        held = held,
        attachments = attachments,
        packed = packed,
        filled = #packed,
        gear_sz = gear_sz,
        held_sz = held_sz,
        att_sz = att_sz,
        gap = gap,
        att_gap = att_gap,
        row_w = row_w,
        held_row_w = held_row_w,
        panel_w = panel_w,
        row_gap = 8,
        name_fs = 11,
        held_key = nil,
        att_keys = {},
        gear_keys = {},
    }

    layout.held_key = held and resolve_image_key(held) or nil
    for i = 1, layout.filled do
        layout.gear_keys[i] = resolve_image_key(packed[i])
        local key = layout.gear_keys[i]
        if key then image_cache.begin_load(key) end
    end
    for i = 1, #attachments do
        layout.att_keys[i] = resolve_image_key(attachments[i])
        local key = layout.att_keys[i]
        if key then image_cache.begin_load(key) end
    end
    if layout.held_key then
        image_cache.begin_load(layout.held_key)
    end

    return layout
end

local function held_piece(held)
    if not held then return nil end
    if type(held) == "table" then
        if held.name and player_gear.is_empty_held_name and player_gear.is_empty_held_name(held.name) then
            return nil
        end
        return held
    end
    if player_gear.is_empty_held_name and player_gear.is_empty_held_name(held) then
        return nil
    end
    return { name = held }
end

local function split_words(text)
    local words = {}
    for word in text:gmatch("%S+") do
        words[#words + 1] = word
    end
    return words
end

local function wrap_words(words, max_w, fs)
    local lines = {}
    local i = 1
    while i <= #words do
        local line = words[i]
        local j = i + 1
        while j <= #words do
            local try = line .. " " .. words[j]
            if select(1, draw.get_text_size(try, fs)) <= max_w then
                line = try
                j = j + 1
            else
                break
            end
        end
        lines[#lines + 1] = line
        i = j
    end
    return lines
end

local function words_fit(words, fs, max_w)
    for _, word in ipairs(words) do
        if select(1, draw.get_text_size(word, fs)) > max_w then
            return false
        end
    end
    return true
end

local function slot_label(piece)
    if type(piece) ~= "table" then return nil end
    local name = piece.name
    if not name or name == "" then return nil end

    name = text_util.sanitize(name)
    local base, slash_var = name:match("^([^/]+)/(.+)$")
    if base and slash_var then
        return base .. " " .. slash_var
    end

    local variant = piece.variant
    if variant and variant ~= "" and variant ~= "Default" then
        return name .. " " .. text_util.sanitize(variant)
    end
    return name
end

local function draw_fitted_label(x, y, size, text)
    if not draw or not draw.text or not draw.get_text_size then return end

    text = text_util.sanitize(text)
    if text == "" then return end

    local pad = 4
    local inner = size - pad * 2
    local words = split_words(text)
    if #words == 0 then return end

    local max_fs = math.max(8, math.floor(size * 0.26))
    local min_fs = 6
    local chosen_fs, chosen_lines

    for fs = max_fs, min_fs, -1 do
        if words_fit(words, fs, inner) then
            local lines = wrap_words(words, inner, fs)
            local line_h = fs + 1
            if #lines * line_h <= inner then
                chosen_fs = fs
                chosen_lines = lines
                break
            end
        end
    end

    if not chosen_lines then
        chosen_fs = min_fs
        chosen_lines = wrap_words(words, inner, min_fs)
    end

    local line_h = chosen_fs + 1
    local total_h = #chosen_lines * line_h
    local ty = y + pad + (inner - total_h) * 0.5

    for i, line in ipairs(chosen_lines) do
        local tw = select(1, draw.get_text_size(line, chosen_fs))
        draw.text(
            x + size * 0.5 - tw * 0.5,
            ty + (i - 1) * line_h,
            line,
            theme.TEXT_MUTED,
            chosen_fs
        )
    end
end

local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = overlay_theme.slot()
    local edge = overlay_theme.border()

    if style == "held" then
        bg = overlay_theme.slot("held")
        edge = theme.alpha(overlay_theme.accent(), 0.88)
    elseif style == "attachment" then
        bg = theme.alpha(overlay_theme.slot(), 0.82)
    elseif style == "empty" then
        bg = overlay_theme.slot("empty")
        edge = theme.alpha(theme.BORDER, 0.28)
    end

    draw.rect_filled(x, y, size, size, bg, 0)
    if draw.rect then
        draw.rect(x, y, size, size, edge, 0, style == "held" and 1.5 or 1)
    end
    if style == "held" and draw.rect_filled then
        draw.rect_filled(x + 1, y + 1, size - 2, 2, overlay_theme.accent(), 0)
    end

    if not piece then return end

    if key and image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
        return
    end
    if key and image_cache.state(key) ~= "failed" then
        return
    end

    local label = slot_label(piece)
    if label then
        draw_fitted_label(x, y, size, label)
    end
end

local function same_target(a, b)
    if a == b then return true end
    if not a or not b then return false end
    local aid = a.user_id or a.name
    local bid = b.user_id or b.name
    return aid and bid and aid == bid
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Target Gear")
    menu_util.register_keybind(T, G.VISUALS, P, "Target Gear Overlay", false)

    local root = menu_util.parent(P)
    menu.add_combo(T, G.VISUALS, "april_target_gear_source", "Target From",
        active_target.SOURCE_NAMES, 0, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_gear_size", "Gear Icon Size", 32, 64, 48, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_top", "Top Offset", 48, 160, 88, root)

    menu_util.bind_children(P, {
        "april_target_gear_source", P .. "_gear_size", P .. "_top",
    })
end

function M.refresh_target()
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end

    local gear_sz = settings.num(P .. "_gear_size", 48)

    local target = find_overlay_target()

    if not target or not player_state.is_combat_target(target) then
        M._target = nil
        M._layout = nil
        return
    end

    local target_changed = not same_target(M._target, target)
    local uid = target.user_id or target.name or "?"
    local cached = gear_cache[uid]
    local gear_stale = not cached or (tick_ms() - cached.t) >= GEAR_TTL

    M._target = target

    if target_changed or not M._layout or gear_stale then
        M._layout = build_layout(get_gear(target), gear_sz)
    end
end

function M.update(_dt)
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end

    local now = tick_ms()
    if now - last_poll_ms < TARGET_POLL_MS then return end
    last_poll_ms = now

    M.refresh_target()
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text or not draw.rect_filled then return end

    overlay_theme.sync()
    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = draw_util.screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5

    local name = text_util.sanitize(target.display_name or target.name or "Unknown")
    local content_w = math.max(layout.held_row_w, layout.row_w)
    local panel_w = math.max(220, content_w + 18)
    local panel_h = 24 + 8 + layout.held_sz + layout.row_gap + layout.gear_sz + 9
    if not held_piece(layout.held) and layout.filled == 0 then
        panel_h = panel_h + 16
    end
    local panel_x = cx - panel_w * 0.5
    overlay_theme.draw_panel(panel_x, top, panel_w, panel_h, "TARGET LOADOUT", { title_center = true })

    local max_name_w = panel_w - 114
    local header_name = name
    while #header_name > 1 and select(1, draw.get_text_size(header_name, 10)) > max_name_w do
        header_name = header_name:sub(1, -2)
    end
    if header_name ~= name then header_name = header_name .. ".." end
    local nw = select(1, draw.get_text_size(header_name, 10))
    draw.text(panel_x + panel_w - nw - 8, top + 7, header_name, overlay_theme.accent(), 10)

    local y = top + 32
    local held = held_piece(layout.held)
    local row_x = cx - layout.held_row_w * 0.5

    draw_slot(row_x, y, layout.held_sz, layout.held_key, held, held and "held" or "empty")

    if #layout.attachments > 0 then
        local ax = row_x + layout.held_sz + 10
        for i = 1, #layout.attachments do
            local sx = ax + (i - 1) * (layout.att_sz + layout.att_gap)
            draw_slot(sx, y + (layout.held_sz - layout.att_sz) * 0.5, layout.att_sz, layout.att_keys[i], layout.attachments[i], "attachment")
        end
    end

    y = y + layout.held_sz + layout.row_gap

    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= layout.filled and layout.packed[i] or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, layout.gear_keys[i], piece, piece and "gear" or "empty")
    end

    if not held and layout.filled == 0 then
        local hint = "No gear detected"
        local hw = select(1, draw.get_text_size(hint, 10))
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, theme.TEXT_DIM, 10)
    end
end

return M

end)()

-- ── features/visuals/target_visuals.lua ──
April._mods["features.visuals.target_visuals"] = (function()
-- Target visuals: custom crosshair, smooth follow-target, and motion effects.
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local active_target = April.require("features.combat.active_target")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_crosshair_enabled"

local CROSS_STYLES = { "Cross", "Circle", "Dot", "T-Shape", "Diamond", "Plus", "Brackets", "X" }

-- Smoothed follow position (screen space).
local follow = { x = nil, y = nil, ready = false }

local function tick_s()
    return (utility and utility.get_tick_count and utility.get_tick_count() or 0) * 0.001
end

local function screen_center()
    local sw, sh = draw_util.screen_size()
    return sw * 0.5, sh * 0.5
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function follow_alpha(dt)
    dt = dt or (1 / 60)
    -- Small lag — higher = snappier, lower = floatier.
    local rate = settings.num("april_crosshair_follow_smooth", 18) * 0.045
    return 1 - math.exp(-rate * dt * 60)
end

local function crosshair_color()
    if settings.bool("april_crosshair_rainbow", false) then
        local t = tick_s()
        local speed = settings.num("april_crosshair_rainbow_speed", 10) * 0.1
        return {
            (math.sin(t * speed) + 1) * 0.5,
            (math.sin(t * speed + 2) + 1) * 0.5,
            (math.sin(t * speed + 4) + 1) * 0.5,
            1,
        }
    end
    return settings.color("april_crosshair_color", { 0, 1, 0, 1 })
end

local function motion_scale(base_size)
    if not settings.bool("april_crosshair_pulse", false) then
        return base_size
    end
    local speed = settings.num("april_crosshair_pulse_speed", 40) * 0.05
    local wave = 0.82 + 0.18 * math.sin(tick_s() * speed * 3.2)
    return base_size * wave
end

local function spin_angle()
    if not settings.bool("april_crosshair_spin", false) then
        return 0
    end
    local speed = settings.num("april_crosshair_spin_speed", 35) * 0.04
    return tick_s() * speed * 6.283
end

local function rot_point(cx, cy, x, y, angle)
    local dx, dy = x - cx, y - cy
    local c, s = math.cos(angle), math.sin(angle)
    return cx + dx * c - dy * s, cy + dx * s + dy * c
end

local function draw_line(x1, y1, x2, y2, col, thick, outline)
    if outline and settings.bool("april_crosshair_outline", true) then
        local oc = settings.color("april_crosshair_outline", { 0, 0, 0, 1 })
        local oa = { oc[1], oc[2], oc[3], (col[4] or 1) * (oc[4] or 1) }
        draw_util.line(x1, y1, x2, y2, oa, (thick or 1) + 1.5)
    end
    draw_util.line(x1, y1, x2, y2, col, thick or 1)
end

local function draw_spoke(cx, cy, angle, inner, outer, col, thick, outline)
    local x1, y1 = rot_point(cx, cy, cx, cy - inner, angle)
    local x2, y2 = rot_point(cx, cy, cx, cy - outer, angle)
    draw_line(x1, y1, x2, y2, col, thick, outline)
end

local function draw_cross(cx, cy, size, gap, thick, col, outline, spin)
    spin = spin or 0
    for i = 0, 3 do
        local a = spin + i * 1.5707963
        draw_spoke(cx, cy, a, gap, gap + size, col, thick, outline)
    end
end

local function draw_plus(cx, cy, size, thick, col, outline, spin)
    spin = spin or 0
    for i = 0, 3 do
        local a = spin + i * 1.5707963
        draw_spoke(cx, cy, a, 0, size, col, thick, outline)
    end
end

local function draw_x(cx, cy, size, thick, col, outline, spin)
    spin = spin or 0
    for _, base in ipairs({ 0.785398, 2.35619 }) do
        draw_spoke(cx, cy, spin + base, 0, size, col, thick, outline)
    end
end

local function draw_brackets(cx, cy, size, thick, col, outline)
    local w = size * 0.55
    local h = size
    draw_line(cx - w, cy - h, cx - w * 0.35, cy - h, col, thick, outline)
    draw_line(cx - w, cy - h, cx - w, cy - h * 0.35, col, thick, outline)
    draw_line(cx - w, cy + h, cx - w * 0.35, cy + h, col, thick, outline)
    draw_line(cx - w, cy + h, cx - w, cy + h * 0.35, col, thick, outline)
    draw_line(cx + w, cy - h, cx + w * 0.35, cy - h, col, thick, outline)
    draw_line(cx + w, cy - h, cx + w, cy - h * 0.35, col, thick, outline)
    draw_line(cx + w, cy + h, cx + w * 0.35, cy + h, col, thick, outline)
    draw_line(cx + w, cy + h, cx + w, cy + h * 0.35, col, thick, outline)
end

local function draw_diamond(cx, cy, size, col)
    if draw and draw.line then
        draw.line(cx, cy - size, cx + size, cy, col, 2)
        draw.line(cx + size, cy, cx, cy + size, col, 2)
        draw.line(cx, cy + size, cx - size, cy, col, 2)
        draw.line(cx - size, cy, cx, cy - size, col, 2)
    else
        draw_util.line(cx, cy - size, cx + size, cy, col, 2)
        draw_util.line(cx + size, cy, cx, cy + size, col, 2)
        draw_util.line(cx, cy + size, cx - size, cy, col, 2)
        draw_util.line(cx - size, cy, cx, cy - size, col, 2)
    end
end

local function draw_crosshair(cx, cy)
    local size = motion_scale(settings.num("april_crosshair_size", 10))
    local gap = settings.num("april_crosshair_gap", 5)
    local thick = settings.num("april_crosshair_thickness", 2)
    local col = crosshair_color()
    local outline = settings.bool("april_crosshair_outline", true)
    local kind = math.floor(settings.num("april_crosshair_type", 0) or 0)
    local spin = spin_angle()

    if kind == 1 then
        draw_util.circle(cx, cy, size, col, false)
    elseif kind == 2 then
        draw_util.circle(cx, cy, size * 0.5, col, true)
    elseif kind == 3 then
        draw_line(cx - size, cy - size * 0.45, cx + size, cy - size * 0.45, col, thick, outline)
        draw_line(cx, cy - size * 0.45, cx, cy + size, col, thick, outline)
    elseif kind == 4 then
        draw_diamond(cx, cy, size * 0.75, col)
    elseif kind == 5 then
        draw_plus(cx, cy, size, thick, col, outline, spin)
    elseif kind == 6 then
        draw_brackets(cx, cy, size, thick, col, outline)
    elseif kind == 7 then
        draw_x(cx, cy, size, thick, col, outline, spin)
    else
        draw_cross(cx, cy, size, gap, thick, col, outline, spin)
    end

    if settings.bool("april_crosshair_dot", false) then
        local dc = settings.color("april_crosshair_dot", { 1, 1, 1, 1 })
        draw_util.circle(cx, cy, math.max(1.5, thick), dc, true)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu_util.section(T, G.VISUALS, "Crosshair")
    menu.add_checkbox(T, G.VISUALS, P, "Custom Crosshair", false)
    menu.add_combo(T, G.VISUALS, "april_crosshair_type", "Crosshair Style", CROSS_STYLES, 0, root)
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_follow", "Follow Target", false, root)
    menu.add_combo(T, G.VISUALS, active_target.SOURCE_CROSSHAIR, "Target From",
        active_target.SOURCE_NAMES, 0, menu_util.parent("april_crosshair_follow"))
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_follow_smooth", "Follow Smoothness", 4, 40, 18,
        menu_util.parent("april_crosshair_follow"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_spin", "Spin", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_spin_speed", "Spin Speed", 1, 100, 35,
        menu_util.parent("april_crosshair_spin"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_pulse", "Pulse Size", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_pulse_speed", "Pulse Speed", 1, 100, 40,
        menu_util.parent("april_crosshair_pulse"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_color", "Crosshair Color", true,
        menu_util.parent(P, { colorpicker = { 0, 1, 0, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_dot", "Center Dot", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_outline", "Outline", true,
        menu_util.parent(P, { colorpicker = { 0, 0, 0, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_rainbow", "Rainbow", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10,
        menu_util.parent("april_crosshair_rainbow"))
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_size", "Size", 1, 50, 10, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_gap", "Gap", 0, 20, 5, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_thickness", "Thickness", 1, 10, 2, root)

    menu_util.bind_children(P, {
        "april_crosshair_type", "april_crosshair_follow", "april_crosshair_spin", "april_crosshair_pulse",
        "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
        "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
        "april_crosshair_size", "april_crosshair_gap", "april_crosshair_thickness",
    })
    menu_util.bind_children("april_crosshair_follow", {
        active_target.SOURCE_CROSSHAIR, "april_crosshair_follow_smooth",
    })
    menu_util.bind_children("april_crosshair_spin", { "april_crosshair_spin_speed" })
    menu_util.bind_children("april_crosshair_pulse", { "april_crosshair_pulse_speed" })
    menu_util.bind_children("april_crosshair_rainbow", { "april_crosshair_rainbow_speed" })
end

function M.update(dt)
    local cx, cy = screen_center()
    if not follow.ready then
        follow.x, follow.y = cx, cy
        follow.ready = true
    end

    local goal_x, goal_y = cx, cy
    if settings.bool("april_crosshair_follow", false) then
        -- Pass smoothed position so "Closest" hitbox tracks from the crosshair, not hard center.
        local pt = active_target.get_aim_screen(nil, follow.x, follow.y, active_target.SOURCE_CROSSHAIR)
        if pt then
            goal_x, goal_y = pt.x, pt.y
        end
    end

    local alpha = follow_alpha(dt)
    follow.x = lerp(follow.x, goal_x, alpha)
    follow.y = lerp(follow.y, goal_y, alpha)
end

function M.draw()
    overlay_theme.sync()

    local cx, cy = screen_center()
    if settings.bool("april_crosshair_follow", false) and follow.ready then
        cx, cy = follow.x, follow.y
    end

    if settings.enabled(P) then
        draw_crosshair(cx, cy)
    end
end

return M

end)()

-- ── features/visuals/crosshair.lua ──
April._mods["features.visuals.crosshair"] = (function()
return April.require("features.visuals.target_visuals")

end)()

-- ── features/world/world_esp.lua ──
April._mods["features.world.world_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")

local M = {}
local P = "april_world_enabled"
local CHAMS_ID = "april_world_chams"
local CHAMS_MODE = "april_world_chams_mode"
local CHAMS_COLOR = "april_world_chams_color"

local function world_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.WORLD_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end

local function world_chams_index_for(toggle_id)
    for i, t in ipairs(maps.WORLD_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end

local function world_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.WORLD_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_world_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end

    local range = settings.num("april_world_range", 500)
    local range_sq = range * range

    for _, entry in ipairs(cache.world) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = world_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dx = lx - me_pos.x
        local dy = ly - me_pos.y
        local dz = lz - me_pos.z
        if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end

        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end

M._static = {}
M._dynamic = {}

local function rebuild_cache()
    cache.world = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.world, entry)
    end
    for _, entry in ipairs(M._dynamic) do
        table.insert(cache.world, entry)
    end
end

local function refresh_dynamic_positions(list)
    if not list or #list == 0 then return end
    for _, entry in ipairs(list) do
        if entry and env.is_valid(entry.inst) then
            esp_scan.refresh_entry_position(entry)
        end
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Resources")
    menu_util.register_keybind(T, G.WORLD, P, "Resource ESP", false)
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "Resource 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_name", "Resource Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_distance", "Resource Show Distance", true, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_world_range", "Resource Range", 50, 2000, 500, { parent = P })

    local child_ids = { "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range" }
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
    end

    if gpu_chams.available() then
        local labels = world_chams_labels()
        menu.add_multicombo(T, G.WORLD, CHAMS_ID, "Resource Chams", labels,
            gpu_chams.multicombo_defaults(#labels), { parent = P })
        gpu_chams.add_mode_color_menu(T, G.WORLD, P, CHAMS_MODE, CHAMS_COLOR,
            "Resource Chams Mode", "Resource Chams Color")
        child_ids[#child_ids + 1] = CHAMS_ID
        child_ids[#child_ids + 1] = CHAMS_MODE
        child_ids[#child_ids + 1] = CHAMS_COLOR

        gpu_chams.register_owner("world", {
            rescan_ms = 500,
            is_active = world_chams_active,
            style = function()
                return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
            end,
            collect = collect_world_chams,
        })
        gpu_chams.wire_style_controls("world", CHAMS_MODE, CHAMS_COLOR)
        settings.on_change(CHAMS_ID, function()
            gpu_chams.sync_owner("world", true)
        end)
        settings.on_change(P, function(v)
            if v == true or v == 1 then
                gpu_chams.sync_owner("world", true)
            else
                gpu_chams.clear_owner("world")
            end
        end)
        for _, t in ipairs(maps.WORLD_TOGGLES) do
            settings.on_change(t.id, function()
                gpu_chams.sync_owner("world", true)
            end)
        end
    end

    menu_util.bind_children(P, child_ids)
end

function M.begin_static_scan()
    return {
        phase = 1,
        node_state = esp_scan.create_folder_scan(maps.NODE_FOLDERS, maps.NODE_MAP, maps.NODE_LABELS, false),
        plant_state = esp_scan.create_folder_scan(maps.PLANT_FOLDERS, maps.PLANT_MAP, maps.PLANT_LABELS, false),
        out = {},
    }
end

function M.step_static_scan(state, batch)
    if state.phase == 1 then
        local done = esp_scan.folder_scan_step(state.node_state, batch)
        if done then
            state.phase = 2
        end
        return false
    end

    local done = esp_scan.folder_scan_step(state.plant_state, batch)
    if done then
        state.out = {}
        for _, entry in ipairs(state.node_state.out) do
            table.insert(state.out, entry)
        end
        for _, entry in ipairs(state.plant_state.out) do
            table.insert(state.out, entry)
        end
    end
    return done
end

function M.complete_static_scan(state)
    M._static = state.out or {}
    rebuild_cache()
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.begin_dynamic_scan()
    return esp_scan.create_folder_scan(maps.ANIMAL_FOLDERS, maps.ANIMAL_MAP, maps.ANIMAL_LABELS, true)
end

function M.step_dynamic_scan(state, batch)
    return esp_scan.folder_scan_step(state, batch)
end

function M.complete_dynamic_scan(state)
    M._dynamic = state.out or {}
    rebuild_cache()
end

function M.scan_static()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.scan_dynamic()
    local state = M.begin_dynamic_scan()
    while not M.step_dynamic_scan(state, 9999) do end
    M.complete_dynamic_scan(state)
end

function M.scan()
    M.scan_static()
    M.scan_dynamic()
end

function M.update(_dt)
    local world_on = settings.enabled(P)

    if world_on then
        if cache.should_refresh_positions() then
            cache.prune_invalid(M._static)
            cache.prune_invalid(M._dynamic)
            rebuild_cache()
            if #M._dynamic > 0 then
                refresh_dynamic_positions(M._dynamic)
            end
        end
    end

    if gpu_chams.available() then
        gpu_chams.sync_owner("world")
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_world_range", 500)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_world_boxes")
    local show_name = settings.bool("april_world_show_name", true)
    local show_dist = settings.bool("april_world_show_distance", true)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.world) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end

        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.WORLD_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "?") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end

        ::continue::
    end
end

return M

end)()

-- ── features/world/loot_esp.lua ──
April._mods["features.world.loot_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")

local M = {}
local P = "april_loot_enabled"
local CHAMS_ID = "april_loot_chams"
local CHAMS_MODE = "april_loot_chams_mode"
local CHAMS_COLOR = "april_loot_chams_color"

M._static = {}
M._drops = {}

local UNLIMITED_RANGE = {
    april_timed_crate = true,
    april_care_package = true,
    april_btr_crate = true,
}

local function loot_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.LOOT_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end

local function loot_chams_index_for(toggle_id)
    for i, t in ipairs(maps.LOOT_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end

local function loot_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.LOOT_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_loot_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    -- Fail closed: without local pos we must NOT cham the whole cache.
    if not me_pos then return end

    local range = settings.num("april_loot_range", 300)
    local range_sq = range * range

    for _, entry in ipairs(cache.loot) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = loot_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        if not UNLIMITED_RANGE[entry.toggle_id] then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end
        end

        -- One visual part per entry (instance Address) - not every MeshPart in the world.
        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end

local STATIC_SOURCES = {
    { kind = "root", key = "loners" },
    { kind = "root", key = "vegetation" },
    { kind = "root", key = "events" },
    { kind = "nested", key = "military" },
    { kind = "nested", key = "monuments" },
}

local function rebuild_cache()
    cache.loot = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.loot, entry)
    end
    for _, entry in ipairs(M._drops) do
        table.insert(cache.loot, entry)
    end
end

local function refresh_dynamic_positions(list)
    if not list or #list == 0 then return end
    for _, entry in ipairs(list) do
        if entry and env.is_valid(entry.inst) then
            esp_scan.refresh_entry_position(entry)
        end
    end
end

local function loot_display_name(model, base_name)
    if base_name == "Sleeper" then
        local label = env.safe_call(function()
            local desc = model:get_descendants()
            for _, d in ipairs(desc or {}) do
                if (d.ClassName or d.class_name) == "TextLabel" then
                    local text = d.Text or d.text
                    if text and text ~= "" then return text .. " (Sleeper)" end
                end
            end
            return nil
        end)
        if label then return label end
    elseif base_name == "Timed Crate" then
        local extra = env.safe_call(function()
            local desc = model:get_descendants()
            for _, d in ipairs(desc or {}) do
                if (d.ClassName or d.class_name) == "TextLabel" then
                    local text = d.Text or d.text
                    if text and text ~= "" then return text end
                end
            end
            return nil
        end)
        if extra then return base_name .. " (" .. extra .. ")" end
    end
    return base_name
end

local function append_loot_model(out, model, base_name, toggle_id, dynamic)
    if not env.is_valid(model) then return end
    local display = loot_display_name(model, base_name)
    table.insert(out, esp_scan.make_entry(model, display, toggle_id, { dynamic = dynamic }))
end

local function collect_loot_container(container, type_name, toggle_id, out, dynamic)
    if not env.is_valid(container) then return end
    local cn = container.ClassName or container.class_name
    if cn == "Model" then
        append_loot_model(out, container, type_name, toggle_id, dynamic)
        return
    end

    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, model in ipairs(subs) do
        append_loot_model(out, model, type_name, toggle_id, dynamic)
    end
end

function M.begin_static_scan()
    return {
        si = 1,
        phase = "top",
        ci = 1,
        sub_ci = 1,
        children = nil,
        subs = nil,
        current = nil,
        out = {},
    }
end

function M.step_static_scan(state, batch)
    local processed = 0

    while processed < batch do
        if state.si > #STATIC_SOURCES then
            return true
        end

        local source = STATIC_SOURCES[state.si]
        if not state.children then
            state.phase = "top"
            state.ci = 1
            state.sub_ci = 1
            state.subs = nil
            state.current = nil
            state.children = env.safe_call(function()
                local folder = folders.from_key(source.key)
                if not env.is_valid(folder) then return {} end
                return folder:get_children()
            end) or {}
        end

        if state.ci > #state.children then
            state.si = state.si + 1
            state.children = nil
            goto continue
        end

        local child = state.children[state.ci]

        if state.phase == "top" then
            if not env.is_valid(child) then
                state.ci = state.ci + 1
                processed = processed + 1
                goto continue
            end

            local name = child.Name or child.name
            local toggle_id = name and maps.LOOT_MAP[name]

            if toggle_id then
                collect_loot_container(child, name, toggle_id, state.out, false)
                state.ci = state.ci + 1
                processed = processed + 1
            elseif source.kind == "nested" then
                state.current = child
                state.subs = env.safe_call(function() return child:get_children() end) or {}
                state.sub_ci = 1
                state.phase = "nested"
            else
                state.ci = state.ci + 1
                processed = processed + 1
            end
        else
            if not state.subs or state.sub_ci > #state.subs then
                state.phase = "top"
                state.ci = state.ci + 1
                state.current = nil
                state.subs = nil
                goto continue
            end

            local sub = state.subs[state.sub_ci]
            state.sub_ci = state.sub_ci + 1
            processed = processed + 1

            if not env.is_valid(sub) then goto continue end

            local sub_name = sub.Name or sub.name
            local sub_tid = sub_name and maps.LOOT_MAP[sub_name]
            if sub_tid then
                collect_loot_container(sub, sub_name, sub_tid, state.out, false)
            end
        end

        ::continue::
    end

    return false
end

function M.complete_static_scan(state)
    M._static = state.out or {}
    rebuild_cache()
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.begin_drops_scan()
    return { ci = 1, children = nil, out = {} }
end

function M.step_drops_scan(state, batch)
    if not state.children then
        state.children = env.safe_call(function()
            local drops = folders.from_key("drops")
            if not env.is_valid(drops) then return {} end
            return drops:get_children()
        end) or {}
        state.ci = 1
    end

    local processed = 0
    while processed < batch and state.ci <= #state.children do
        local model = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1

        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        if name and name ~= "" then
            append_loot_model(state.out, model, name, "april_dropped_item", true)
        end

        ::continue::
    end

    return state.ci > #state.children
end

function M.complete_drops_scan(state)
    M._drops = state.out or {}
    rebuild_cache()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Loot")
    menu_util.register_keybind(T, G.WORLD, P, "Loot ESP", false)
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "Loot 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_name", "Loot Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_distance", "Loot Show Distance", true, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })

    local child_ids = { "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range" }
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
    end

    if gpu_chams.available() then
        local labels = loot_chams_labels()
        menu.add_multicombo(T, G.WORLD, CHAMS_ID, "Loot Chams", labels,
            gpu_chams.multicombo_defaults(#labels), { parent = P })
        gpu_chams.add_mode_color_menu(T, G.WORLD, P, CHAMS_MODE, CHAMS_COLOR,
            "Loot Chams Mode", "Loot Chams Color")
        child_ids[#child_ids + 1] = CHAMS_ID
        child_ids[#child_ids + 1] = CHAMS_MODE
        child_ids[#child_ids + 1] = CHAMS_COLOR

        gpu_chams.register_owner("loot", {
            rescan_ms = 500,
            is_active = loot_chams_active,
            style = function()
                return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
            end,
            collect = collect_loot_chams,
        })
        gpu_chams.wire_style_controls("loot", CHAMS_MODE, CHAMS_COLOR)
        settings.on_change(CHAMS_ID, function()
            gpu_chams.sync_owner("loot", true)
        end)
        settings.on_change(P, function(v)
            if v == true or v == 1 then
                gpu_chams.sync_owner("loot", true)
            else
                gpu_chams.clear_owner("loot")
            end
        end)
        for _, t in ipairs(maps.LOOT_TOGGLES) do
            settings.on_change(t.id, function()
                gpu_chams.sync_owner("loot", true)
            end)
        end
    end

    menu_util.bind_children(P, child_ids)
end

function M.scan_drops()
    local state = M.begin_drops_scan()
    while not M.step_drops_scan(state, 9999) do end
    M.complete_drops_scan(state)
end

function M.scan_static()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.scan()
    M.scan_static()
    M.scan_drops()
end

function M.update(_dt)
    local map_loot = settings.enabled("april_map_enabled") and settings.enabled("april_map_show_loot")
    local loot_on = settings.enabled(P)

    if loot_on or map_loot then
        if cache.should_refresh_positions() then
            cache.prune_invalid(M._static)
            cache.prune_invalid(M._drops)
            rebuild_cache()
            if #M._drops > 0 then
                refresh_dynamic_positions(M._drops)
            end
        end
    end

    -- Always sync so disable / empty multicombo actually RevertChams.
    if gpu_chams.available() then
        gpu_chams.sync_owner("loot")
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_loot_range", 300)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_loot_boxes")
    local show_name = settings.bool("april_loot_show_name", true)
    local show_dist = settings.bool("april_loot_show_distance", true)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.loot) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end

        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if not UNLIMITED_RANGE[entry.toggle_id] and dist_sq > range_sq then goto continue end
        end

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.LOOT_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Loot") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end

        ::continue::
    end
end

return M

end)()

-- ── features/world/base_esp.lua ──
April._mods["features.world.base_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local turret_stats = April.require("game.turret_stats")
local desync_vis = April.require("core.desync_vis")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")

local M = {}
local P = "april_base_enabled"
local CHAMS_ID = "april_base_chams"
local CHAMS_MODE = "april_base_chams_mode"
local CHAMS_COLOR = "april_base_chams_color"

local function base_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.BASE_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end

local function base_chams_index_for(toggle_id)
    for i, t in ipairs(maps.BASE_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end

local function base_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.BASE_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_base_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end

    local range = settings.num("april_base_range", 150)
    local range_sq = range * range

    for _, entry in ipairs(cache.base) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = base_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dx = lx - me_pos.x
        local dy = ly - me_pos.y
        local dz = lz - me_pos.z
        if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end

        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end

local function append_base_entry(state, model, type_name, toggle_id)
    if not model or not env.is_valid(model) then return end
    if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then return end

    state.seen = state.seen or {}
    local key = tostring(model.Address or model) .. ":" .. toggle_id
    if state.seen[key] then return end
    state.seen[key] = true

    table.insert(state.out, esp_scan.make_entry(model, type_name, toggle_id))
end

local function collect_base_container(state, container, type_name, toggle_id)
    if not env.is_valid(container) then return end

    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then
            append_base_entry(state, bag, type_name, toggle_id)
            return
        end
    end

    local cn = container.ClassName or container.class_name
    if cn == "Model" then
        append_base_entry(state, container, type_name, toggle_id)
        return
    end

    if esp_scan.find_main_part(container) or esp_scan.is_part(container) then
        append_base_entry(state, container, type_name, toggle_id)
    end

    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, child in ipairs(subs) do
        if not env.is_valid(child) then goto child_continue end
        local cc = child.ClassName or child.class_name
        if cc == "Model" then
            append_base_entry(state, child, type_name, toggle_id)
        elseif esp_scan.find_main_part(child) or esp_scan.is_part(child) then
            append_base_entry(state, child, type_name, toggle_id)
        end
        ::child_continue::
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Bases")
    menu_util.register_keybind(T, G.WORLD, P, "Base ESP", false)
    for _, t in ipairs(maps.BASE_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
        if t.ring_id then
            menu.add_checkbox(T, G.WORLD, t.ring_id, t.label .. " Range Ring", false, { parent = t.id })
        end
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "Base 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_name", "Base Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_distance", "Base Show Distance", false, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })

    local child_ids = { "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range" }
    for _, t in ipairs(maps.BASE_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        if t.ring_id then
            child_ids[#child_ids + 1] = t.ring_id
        end
    end

    if gpu_chams.available() then
        local labels = base_chams_labels()
        menu.add_multicombo(T, G.WORLD, CHAMS_ID, "Base Chams", labels,
            gpu_chams.multicombo_defaults(#labels), { parent = P })
        gpu_chams.add_mode_color_menu(T, G.WORLD, P, CHAMS_MODE, CHAMS_COLOR,
            "Base Chams Mode", "Base Chams Color")
        child_ids[#child_ids + 1] = CHAMS_ID
        child_ids[#child_ids + 1] = CHAMS_MODE
        child_ids[#child_ids + 1] = CHAMS_COLOR

        gpu_chams.register_owner("base", {
            rescan_ms = 500,
            is_active = base_chams_active,
            style = function()
                return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
            end,
            collect = collect_base_chams,
        })
        gpu_chams.wire_style_controls("base", CHAMS_MODE, CHAMS_COLOR)
        settings.on_change(CHAMS_ID, function()
            gpu_chams.sync_owner("base", true)
        end)
        settings.on_change(P, function(v)
            if v == true or v == 1 then
                gpu_chams.sync_owner("base", true)
            else
                gpu_chams.clear_owner("base")
            end
        end)
        for _, t in ipairs(maps.BASE_TOGGLES) do
            settings.on_change(t.id, function()
                gpu_chams.sync_owner("base", true)
            end)
        end
    end

    menu_util.bind_children(P, child_ids)
end

function M.begin_scan()
    return {
        areas = nil,
        ai = 1,
        items = nil,
        ii = 1,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
    if not state.areas then
        state.areas = env.safe_call(function()
            local bases = folders.from_key("bases")
            if not env.is_valid(bases) then return {} end
            return bases:get_children()
        end) or {}
        state.ai = 1
        state.items = nil
        state.ii = 1
    end

    local processed = 0

    while processed < batch do
        if state.ai > #state.areas then
            return true
        end

        if not state.items then
            local area = state.areas[state.ai]
            if not env.is_valid(area) then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end

            local area_name = area.Name or area.name or ""
            if maps.BASE_SKIP_AREAS[area_name] then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end

            if maps.BASE_MAP[area_name] then
                state.items = { area }
                local children = env.safe_call(function() return area:get_children() end) or {}
                for _, child in ipairs(children) do
                    state.items[#state.items + 1] = child
                end
            else
                state.items = env.safe_call(function() return area:get_children() end) or {}
            end
            state.ii = 1
        end

        if state.ii > #state.items then
            state.ai = state.ai + 1
            state.items = nil
            goto continue
        end

        local type_folder = state.items[state.ii]
        state.ii = state.ii + 1
        processed = processed + 1

        if not env.is_valid(type_folder) then goto continue end

        local type_name = type_folder.Name or type_folder.name or ""
        local toggle_id = maps.BASE_MAP[type_name]
        if not toggle_id then goto continue end

        collect_base_container(state, type_folder, type_name, toggle_id)

        ::continue::
    end

    return false
end

function M.complete_scan(state)
    cache.base = state.out or {}
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    M.complete_scan(state)
end

function M.update(_dt)
    if settings.enabled(P) and cache.should_refresh_positions() then
        cache.prune_invalid(cache.base)
    end

    if gpu_chams.available() then
        gpu_chams.sync_owner("base")
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_base_range", 150)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_base_boxes")
    local show_name = settings.bool("april_base_show_name", true)
    local show_dist = settings.bool("april_base_show_distance", false)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()
    local label_groups = {}

    for _, entry in ipairs(cache.base) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end

        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.BASE_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local ring_id = maps.turret_ring_toggle(entry.toggle_id)
        if ring_id and settings.enabled(ring_id) then
            local activation = turret_stats.activation_range(entry.name)
            if activation then
                local ring_col = { col[1], col[2], col[3], 0.35 }
                desync_vis.draw_sphere_ring(lx, ly, lz, activation, ring_col, 1.5)
            end
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Base") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    local gk = string.format("%d:%d:%d",
                        math.floor(lx * 2), math.floor(ly * 2), math.floor(lz * 2))
                    local group = label_groups[gk]
                    if not group then
                        group = { sx = sx, sy = sy, lines = {} }
                        label_groups[gk] = group
                    end
                    group.lines[#group.lines + 1] = { label = label, col = col }
                end
            end
        end

        ::continue::
    end

    for _, group in pairs(label_groups) do
        for i, line in ipairs(group.lines) do
            local offset = (i - 1) * (text_size + 2)
            draw_util.text_centered(group.sx, group.sy - offset, line.label, line.col, text_size)
        end
    end
end

return M

end)()

-- ── features/world/npc_esp.lua ──
April._mods["features.world.npc_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local npcs = April.require("game.npcs")
local player_gear = April.require("game.player_gear")

local M = {}
local P = "april_npc_enabled"
local POS_REFRESH_BATCH = 8
local BOUNDS_TTL_MS = 1200

M._pos_idx = 0
M._draw_targets = {}
M._draw_frame = -1
M._bounds_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function bounds_key(entry)
    if entry.entity then
        local p = entry.entity
        return "e:" .. tostring(p.user_id or 0) .. ":" .. tostring(p.name or "")
    end
    if entry.inst then
        return "i:" .. tostring(entry.inst.Address or entry.inst.address or entry.inst)
    end
    return "n:" .. tostring(entry.name or "?")
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPCs")
    menu_util.register_keybind(T, G.WORLD, P, "NPC ESP", false, { colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "NPC Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true,
        menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true,
        menu_util.parent(P, { colorpicker = { 0.82, 0.84, 0.88, 0.92 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_weapon", "NPC Weapon", false,
        menu_util.parent(P, { colorpicker = { 0.82, 0.84, 0.88, 0.92 } }))

    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)

    menu_util.bind_children(P, {
        "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode", "april_npc_health",
        "april_npc_skeleton", "april_npc_show_name", "april_npc_show_distance",
        "april_npc_show_weapon", "april_npc_range",
    })
end

function M.begin_scan()
    return npcs.begin_scan()
end

function M.step_scan(state, batch)
    return npcs.step_scan(state, batch)
end

function M.complete_scan(state)
    cache.npcs = npcs.complete_scan(state)
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    M.complete_scan(state)
end

local function kind_enabled(kind)
    if kind == "soldier" then return settings.bool("april_npc_soldiers", false) end
    if kind == "boss" then return settings.bool("april_npc_bosses", false) end
    return false
end

local function kind_color(kind)
    if kind == "boss" then return settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 }) end
    return settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 })
end

local function entity_addr(p)
    if not p then return nil end
    if p.character then
        local addr = p.character.Address or p.character.address
        if addr then return tostring(addr) end
    end
    return (p.name or "?") .. ":" .. tostring(p.user_id or 0)
end

local function instance_addr(entry)
    if not entry or not entry.inst then return nil end
    return tostring(entry.inst.Address or entry.inst.address or entry.inst)
end

local function refresh_npc_position(entry)
    if entry.entity then
        local p = entry.entity
        if not p.is_alive then return false end
        if p.head_position then
            local pos = p.head_position
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
        if p.position then
            local pos = p.position
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
        return false
    end

    if not entry or not env.is_valid(entry.inst) then return false end
    local head = entry.head
    if head and env.is_valid(head) then
        local pos = head.Position or head.position
        if pos and pos.x then
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
    end
    return false
end

local function collect_draw_targets(into)
    local out = into or {}
    for i = #out, 1, -1 do
        out[i] = nil
    end
    local seen = {}

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local or not p.is_alive then goto continue end

            local kind = npcs.kind(p.name)
            if not kind then goto continue end
            if not p.is_workspace_entity and p.user_id ~= 0 then goto continue end

            local addr = entity_addr(p)
            if addr and seen[addr] then goto continue end
            if addr then seen[addr] = true end

            out[#out + 1] = {
                entity = p,
                name = p.name,
                kind = kind,
            }

            ::continue::
        end
    end

    for _, entry in ipairs(cache.npcs or {}) do
        if not entry or not entry.inst or not env.is_valid(entry.inst) then goto continue_scan end
        local addr = instance_addr(entry)
        if addr and seen[addr] then goto continue_scan end
        if addr then seen[addr] = true end
        out[#out + 1] = entry
        ::continue_scan::
    end

    return out
end

local function frame_draw_targets()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if M._draw_frame == now then
        return M._draw_targets
    end
    M._draw_frame = now
    return collect_draw_targets(M._draw_targets)
end

local function resolve_npc_bounds(entry, dist)
    local key = bounds_key(entry)
    local now = tick_ms()
    local fresh = esp_util.npc_screen_bounds(entry, {
        dist = dist,
        point_size = esp_util.dist_point_size(dist),
    })
    return esp_util.hold_bounds(M._bounds_cache, key, fresh, now, BOUNDS_TTL_MS)
end

local function read_npc_hp(entry)
    if entry.entity then
        local hp = tonumber(entry.entity.health)
        local max_hp = tonumber(entry.entity.max_health)
        if hp and max_hp and max_hp > 0 then
            return hp, max_hp
        end
    end
    if entry.inst and env.is_valid(entry.inst) then
        local hum = env.safe_call(function()
            if entry.inst.find_first_child_of_class then
                return entry.inst:find_first_child_of_class("Humanoid")
            end
            return entry.inst:FindFirstChild("Humanoid")
        end)
        if hum then
            local hp = tonumber(hum.Health or hum.health)
            local max_hp = tonumber(hum.MaxHealth or hum.max_health)
            if hp and max_hp and max_hp > 0 then
                return hp, max_hp
            end
        end
    end
    return nil, nil
end

function M.update(_dt)
    if not settings.enabled(P) then
        M._draw_targets = {}
        M._draw_frame = -1
        M._bounds_cache = {}
        return
    end

    if cache.should_refresh_positions() then
        cache.prune_invalid(cache.npcs)
    end

    local list = frame_draw_targets()
    local n = #list
    if n == 0 then return end

    for _ = 1, POS_REFRESH_BATCH do
        M._pos_idx = (M._pos_idx % n) + 1
        refresh_npc_position(list[M._pos_idx])
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_npc_range", 500)
    local range_sq = range * range
    local box_mode = settings.num("april_npc_box_mode", 1)
    local show_health = settings.bool("april_npc_health", true)
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local me_pos = me and me.position
    local now = tick_ms()

    -- Prune stale hold cache
    for key, ent in pairs(M._bounds_cache) do
        if not ent or (now - (ent.t or 0)) > BOUNDS_TTL_MS * 3 then
            M._bounds_cache[key] = nil
        end
    end

    for _, entry in ipairs(frame_draw_targets()) do
        if not kind_enabled(entry.kind) then goto continue end

        if entry.entity then
            if not entry.entity.is_alive then goto continue end
        elseif not env.is_valid(entry.inst) then
            goto continue
        end

        local col = kind_color(entry.kind)

        local lx, ly, lz = entry.lx, entry.ly, entry.lz
        if not lx then
            refresh_npc_position(entry)
            lx, ly, lz = entry.lx, entry.ly, entry.lz
        end

        if not lx and entry.entity and entry.entity.position then
            local pos = entry.entity.position
            lx, ly, lz = pos.x, pos.y, pos.z
            entry.lx, entry.ly, entry.lz = lx, ly, lz
        end
        if not lx then goto continue end

        local dist = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end

        local _, _, head_vis = esp_util.w2s(lx, ly, lz)

        -- Skeleton is independent of box bounds (same as player ESP).
        if settings.bool("april_npc_skeleton", false) then
            local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
            if entry.entity and entry.entity.get_bones_screen then
                esp_util.draw_player_skeleton(entry.entity, sk, 1)
            elseif entry.inst then
                esp_util.draw_model_skeleton(entry.inst, sk, 1)
            end
        end

        local bounds = resolve_npc_bounds(entry, dist)
        if not esp_util.bounds_usable(bounds) then
            if not head_vis then goto continue end
            local size = esp_util.dist_point_size(dist)
            bounds = esp_util.guard_tiny_bounds(
                esp_util.point_screen_bounds(lx, ly, lz, size),
                dist
            )
            if not esp_util.bounds_usable(bounds) then goto continue end
        elseif not head_vis then
            local sw, sh = draw_util.screen_size()
            local cx = bounds.x + bounds.w * 0.5
            local cy = bounds.y + bounds.h * 0.5
            local margin = 120
            if cx < -margin or cy < -margin or cx > sw + margin or cy > sh + margin then
                goto continue
            end
        end

        local ts = text_size
        if dist > 250 then
            ts = math.max(11, ts - 1)
        end

        local cx = bounds.x + bounds.w * 0.5
        local label = entry.name or "NPC"
        local show_name = settings.bool("april_npc_show_name", true)
        local show_dist = settings.bool("april_npc_show_distance", true)
        local show_wpn = settings.bool("april_npc_show_weapon", false)

        -- Top labels match player ESP (name / weapon above, distance below).
        local top = {}
        if show_name then
            top[#top + 1] = {
                text = label,
                col = settings.color("april_npc_show_name", col),
            }
        end
        if show_wpn then
            local wpn = nil
            if entry.entity then
                pcall(function() wpn = player_gear.held_name(entry.entity) end)
            end
            if (not wpn or wpn == "") and entry.inst then
                pcall(function() wpn = player_gear.held_name_from_character(entry.inst) end)
            end
            if wpn and wpn ~= "" then
                top[#top + 1] = {
                    text = tostring(wpn),
                    col = settings.color("april_npc_show_weapon", { 0.82, 0.84, 0.88, 0.92 }),
                }
            end
        end

        if #top > 0 then
            local ty = bounds.y - 4 - (#top * (ts + 1))
            for i = 1, #top do
                draw_util.text_centered(cx, ty + (i - 1) * (ts + 1), top[i].text, top[i].col, ts)
            end
        end

        -- Same box + health path as player ESP (1px-gap custom bar via health_bar_on_box).
        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 1)
        end

        if show_health then
            local hp, max_hp = read_npc_hp(entry)
            if hp and max_hp then
                draw_util.health_bar_on_box(bounds, hp, max_hp)
            end
        end

        if show_dist and me_pos then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                settings.color("april_npc_show_distance", { 0.82, 0.84, 0.88, 0.92 }),
                ts
            )
        end

        ::continue::
    end
end

return M

end)()

-- ── features/movement/exploits.lua ──
April._mods["features.movement.exploits"] = (function()
local menu_util = April.require("core.menu_util")

local M = {}

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)

    menu_util.section(T, G.MISC, "Movement")

    -- Id kept as april_noclip_enabled for config compatibility; label is Fly.
    menu_util.register_keybind(T, G.MISC, "april_noclip_enabled", "Fly", false)
    menu.add_slider_int(
        T,
        G.MISC,
        "april_noclip_speed",
        "Fly Speed",
        1,
        20,
        5,
        menu_util.parent("april_noclip_enabled")
    )

    menu_util.register_keybind(T, G.MISC, "april_slowfall_enabled", "Slowfall", false)
    menu.add_slider_int(
        T,
        G.MISC,
        "april_slowfall_speed",
        "Fall Speed",
        1,
        50,
        5,
        menu_util.parent("april_slowfall_enabled")
    )

    menu_util.bind_children("april_noclip_enabled", { "april_noclip_speed" })
    menu_util.bind_children("april_slowfall_enabled", { "april_slowfall_speed" })
end

function M.update(_dt) end

function M.draw() end

return M

end)()

-- ── features/movement/fling.lua ──
April._mods["features.movement.fling"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_fling_enabled"
local P_FOV = "april_fling_fov"
local P_DURATION = "april_fling_duration"

local MAX_DIST = 300.0
local FAR_RANGE = 40.0
local SPIN_Y_START = 48000.0
local SPIN_Y_MAX = 70000.0
local SPIN_RAMP_SEC = 0.35
local BASE_PREDICT = 0.05
local MAX_SNAP_PASSES = 10

local FLING_HIT_PARTS = { "HumanoidRootPart" }

local function fling_duration()
    return settings.num(P_DURATION, 2)
end

local STATE_IDLE = 0
local STATE_APPROACH = 1
local STATE_FLING = 2
local STATE_RETURN = 3

local RETURN_TICKS = 15
local MAX_ATTACH_DRIFT = 6.0

local _installed = false
local state = STATE_IDLE
local fling_t0 = 0
local approach_left = 0
local return_left = 0
local start_range = 0
local saved_pos = nil
local target_root = nil
local target_player = nil
local last_attach = nil

local function now()
    if utility and utility.get_time then return utility.get_time() end
    return os.clock()
end

local function screen_center()
    if input and input.get_screen_center then
        local cx, cy = input.get_screen_center()
        if cx and cy then return cx, cy end
    end
    if draw and draw.get_screen_size then
        local w, h = draw.get_screen_size()
        return w * 0.5, h * 0.5
    end
    return 960, 540
end

local function get_character(lp)
    if lp and lp.character then return lp.character end
    if game and game.local_player and game.local_player.character then
        return game.local_player.character
    end
    return nil
end

local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function get_humanoid(lp)
    if lp and lp.humanoid and env.is_valid(lp.humanoid) then
        return lp.humanoid
    end
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
        return char:FindFirstChildOfClass("Humanoid")
    end)
end

local function player_root(p)
    if not p or not p.character then return nil end
    local char = p.character
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function refresh_target_root()
    if not target_player then return false end
    local root = player_root(target_player)
    if root and env.is_valid(root) then
        target_root = root
        return true
    end
    return target_root ~= nil and env.is_valid(target_root)
end

local function target_still_valid()
    if not target_player then return false end
    if target_player.character and env.is_valid(target_player.character) then
        return true
    end
    if target_player.position then
        return true
    end
    return refresh_target_root()
end

local function player_aim_pos(p)
    if p.position then
        return p.position.x, p.position.y, p.position.z
    end
    if p.head_position then
        local h = p.head_position
        return h.x, h.y, h.z
    end
    local root = player_root(p)
    if root then
        local pos = move.read_pos(root)
        if pos then
            return pos.x, pos.y, pos.z
        end
    end
    return nil
end

local function world_dist_to_player(p, from)
    if not p or not from then return math.huge end
    if p.distance_to then
        return p:distance_to(from)
    end
    local ax, ay, az = player_aim_pos(p)
    if not ax or not from.x then return math.huge end
    return math_util.distance3(ax - from.x, ay - from.y, az - from.z)
end

local function find_target(fov_px)
    if not entity or not entity.get_players then return nil, nil end

    local cx, cy = screen_center()
    local cam = camera and camera.get_position and camera.get_position()
    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end
        if cam and world_dist_to_player(p, cam) > MAX_DIST then goto continue end

        local ax, ay, az = player_aim_pos(p)
        if not ax then goto continue end

        local sx, sy, on_screen = esp_util.w2s(ax, ay, az)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px or fov_dist >= best_dist then goto continue end

        local root = player_root(p)
        if not root or not env.is_valid(root) then goto continue end

        best_dist = fov_dist
        best = p
        ::continue::
    end

    if not best then return nil, nil end
    return best, player_root(best)
end

local function read_part_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.Velocity or inst.velocity
    if vel then
        return vel.x or vel.X or 0, vel.y or vel.Y or 0, vel.z or vel.Z or 0
    end
    local assembly = inst.AssemblyLinearVelocity
    if assembly then
        return assembly.x or assembly.X or 0, assembly.y or assembly.Y or 0, assembly.z or assembly.Z or 0
    end
    return 0, 0, 0
end

local function read_target_velocity(tgt_root, far_lock)
    local ex, ey, ez = 0, 0, 0
    local px, py, pz = 0, 0, 0
    local has_entity = false
    local has_part = false

    if target_player and target_player.velocity then
        local v = target_player.velocity
        ex, ey, ez = v.x or 0, v.y or 0, v.z or 0
        has_entity = true
    end

    if tgt_root and env.is_valid(tgt_root) then
        px, py, pz = read_part_velocity(tgt_root)
        has_part = true
    end

    if far_lock and has_entity then
        return ex, ey, ez
    end
    if has_entity and has_part then
        local entity_speed = math_util.distance3(ex, ey, ez)
        local part_speed = math_util.distance3(px, py, pz)
        if part_speed > entity_speed then
            return px, py, pz
        end
        return ex, ey, ez
    end
    if has_entity then return ex, ey, ez end
    if has_part then return px, py, pz end
    return 0, 0, 0
end

local function read_attach_pos_raw(tgt_root)
    local entity_x, entity_y, entity_z
    local has_entity = false

    if target_player and target_player.position then
        local p = target_player.position
        entity_x, entity_y, entity_z = p.x, p.y, p.z
        has_entity = true
    end

    local part_x, part_y, part_z
    local has_part = false
    if tgt_root and env.is_valid(tgt_root) then
        local tpos = move.read_pos(tgt_root)
        if tpos then
            part_x, part_y, part_z = tpos.x, tpos.y, tpos.z
            has_part = true
        end
    end

    if has_entity and has_part then
        local spread = math_util.distance3(part_x - entity_x, part_y - entity_y, part_z - entity_z)
        if spread > FAR_RANGE or start_range > FAR_RANGE or spread > 8 then
            return entity_x, entity_y, entity_z
        end
        return part_x, part_y, part_z
    end
    if has_entity then return entity_x, entity_y, entity_z end
    if has_part then return part_x, part_y, part_z end
    if last_attach then
        return last_attach.x, last_attach.y, last_attach.z
    end
    return nil
end

local function read_attach_pos(tgt_root, lpos)
    local tx, ty, tz = read_attach_pos_raw(tgt_root)
    if not tx then return nil end

    local far_lock = start_range > FAR_RANGE
    if lpos then
        local live_range = math_util.distance3(tx - lpos.x, ty - lpos.y, tz - lpos.z)
        if live_range > FAR_RANGE then
            far_lock = true
        end
    end

    local vx, vy, vz = read_target_velocity(tgt_root, far_lock)
    local horiz_speed = math_util.distance3(vx, 0, vz)
    local predict = BASE_PREDICT + horiz_speed * 0.003
    if far_lock then
        predict = predict + 0.02
    end

    tx = tx + vx * predict
    ty = ty + vy * predict * 0.12
    tz = tz + vz * predict

    last_attach = { x = tx, y = ty, z = tz }
    return tx, ty, tz
end

local function snap_passes(range, drift)
    local base = 4
    if range > 220 then base = 10
    elseif range > 150 then base = 8
    elseif range > 100 then base = 7
    elseif range > 60 then base = 6
    elseif range > 30 then base = 5
    end

    if drift > 12 then base = base + 3
    elseif drift > 6 then base = base + 2
    elseif drift > 2 then base = base + 1
    end

    return math.min(MAX_SNAP_PASSES, base)
end

local function approach_ticks_for(dist)
    if dist <= FAR_RANGE then return 0 end
    return math.min(12, math.floor(dist / 22) + 3)
end

local function set_fling_collision(char, active)
    if not char then return end
    for _, inst in ipairs(move.iter_parts(char)) do
        move.set_part_collide(inst, false)
    end
    if not active then
        move.set_character_noclip(char, nil, false)
        return
    end
    for i = 1, #FLING_HIT_PARTS do
        local hit = move.find_part(char, FLING_HIT_PARTS[i])
        if hit and move.is_base_part(hit) then
            move.set_part_collide(hit, true)
        end
    end
end

local function prep_fling(char, root, hum)
    set_fling_collision(char, true)
    move.humanoid_suspend(hum)
    pcall(function() hum.platform_stand = true end)
    pcall(function() hum.sit = false end)
    move.humanoid_state(hum, 13)
end

local function release_fling(char, root, hum)
    if root then
        move.zero_part(root)
    end
    move.zero_character(char, root)
    set_fling_collision(char, false)
    if hum then
        pcall(function() hum.platform_stand = false end)
        pcall(function() hum.sit = false end)
        pcall(function() hum.auto_rotate = true end)
        pcall(function() hum.evaluate_state_machine = true end)
        move.humanoid_running(hum)
    end
end

local function write_pos(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
end

local function zero_linear(char, root)
    if root then
        move.set_velocity(root, 0, 0, 0)
    end
    for _, inst in ipairs(move.iter_parts(char)) do
        move.set_velocity(inst, 0, 0, 0)
    end
end

local function lock_at(root, char, x, y, z, passes)
    passes = passes or 3
    for _ = 1, passes do
        write_pos(root, x, y, z)
    end
    zero_linear(char, root)
end

local function clear_session()
    state = STATE_IDLE
    fling_t0 = 0
    approach_left = 0
    return_left = 0
    start_range = 0
    saved_pos = nil
    target_root = nil
    target_player = nil
    last_attach = nil
end

local function pin_to_target(root, tgt_root, from_pos)
    local lpos = move.read_pos(root)
    local tx, ty, tz = read_attach_pos(tgt_root, lpos)
    if not tx then return false end

    local drift = 0
    local range = start_range
    if lpos then
        drift = math_util.distance3(tx - lpos.x, ty - lpos.y, tz - lpos.z)
        range = math.max(range, drift)
    elseif from_pos then
        drift = math_util.distance3(tx - from_pos.x, ty - from_pos.y, tz - from_pos.z)
        range = math.max(range, drift)
    end

    local passes = snap_passes(range, drift)
    for _ = 1, passes do
        write_pos(root, tx, ty, tz)
    end

    zero_linear(nil, root)
    return true, tx, ty, tz
end

local function spin_strength(elapsed)
    local t = math.min(1, elapsed / SPIN_RAMP_SEC)
    return SPIN_Y_START + (SPIN_Y_MAX - SPIN_Y_START) * t
end

local function apply_spin(root, elapsed)
    if not root then return end
    move.set_velocity(root, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, root, 0, spin_strength(elapsed), 0)
    end
end

local function begin_return(root, char, hum)
    state = STATE_RETURN
    return_left = RETURN_TICKS
    target_root = nil
    target_player = nil
    last_attach = nil

    set_fling_collision(char, false)
    if root and part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, root, 0, 0, 0)
    end
    move.zero_character(char, root)
    if hum then
        pcall(function() hum.platform_stand = true end)
        move.humanoid_suspend(hum)
    end
end

local function finish_fling(root, char, hum)
    if saved_pos and root then
        lock_at(root, char, saved_pos.x, saved_pos.y, saved_pos.z, 6)
        move.zero_part(root)
    end
    release_fling(char, root, hum)
    clear_session()
end

local function stop_fling(root, char, hum)
    begin_return(root, char, hum)
end

local function tick_return(root, char, hum)
    if not saved_pos or not root then
        finish_fling(root, char, hum)
        return
    end

    lock_at(root, char, saved_pos.x, saved_pos.y, saved_pos.z, 4)
    move.zero_character(char, root)

    local pos = move.read_pos(root)
    local settled = pos and math_util.distance3(
        pos.x - saved_pos.x, pos.y - saved_pos.y, pos.z - saved_pos.z
    ) < 1.5

    return_left = return_left - 1
    if settled or return_left <= 0 then
        finish_fling(root, char, hum)
    end
end

local function begin_fling(root, char, hum, tgt_player, tgt_root)
    local pos = move.read_pos(root)
    if not pos then return false end

    target_player = tgt_player
    target_root = tgt_root
    last_attach = nil

    local raw_x, raw_y, raw_z = read_attach_pos_raw(tgt_root)
    if not raw_x then return false end

    start_range = math_util.distance3(raw_x - pos.x, raw_y - pos.y, raw_z - pos.z)

    local tx, ty, tz = read_attach_pos(tgt_root, pos)
    if not tx then return false end
    saved_pos = { x = pos.x, y = pos.y, z = pos.z }
    fling_t0 = now()
    approach_left = approach_ticks_for(start_range)

    if approach_left > 0 then
        state = STATE_APPROACH
    else
        state = STATE_FLING
    end

    prep_fling(char, root, hum)
    pin_to_target(root, tgt_root, pos)

    if state == STATE_FLING then
        apply_spin(root, 0)
    end

    return true
end

local function tick_approach(root, char, hum)
    prep_fling(char, root, hum)

    if not pin_to_target(root, target_root, nil) then
        stop_fling(root, char, hum)
        return
    end

    approach_left = approach_left - 1
    if approach_left <= 0 then
        state = STATE_FLING
        apply_spin(root, now() - fling_t0)
    end
end

local function tick_fling(root, char, hum)
    local elapsed = now() - fling_t0
    if elapsed >= fling_duration() then
        stop_fling(root, char, hum)
        return
    end

    if not target_still_valid() then
        stop_fling(root, char, hum)
        return
    end

    refresh_target_root()
    prep_fling(char, root, hum)

    local ok, tx, ty, tz = pin_to_target(root, target_root, nil)
    if not ok then
        stop_fling(root, char, hum)
        return
    end

    apply_spin(root, elapsed)
    lock_at(root, char, tx, ty, tz, 3)

    local pos = move.read_pos(root)
    if pos and math_util.distance3(pos.x - tx, pos.y - ty, pos.z - tz) > MAX_ATTACH_DRIFT then
        lock_at(root, char, tx, ty, tz, 5)
    end
end

local function tick_active(root, char, hum)
    if state == STATE_APPROACH then
        tick_approach(root, char, hum)
        return
    end
    if state == STATE_RETURN then
        tick_return(root, char, hum)
        return
    end
    tick_fling(root, char, hum)
end

local function try_trigger()
    if state ~= STATE_IDLE then return end
    if not settings.enabled(P) then return end

    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then return end

    local fov = settings.num(P_FOV, 150)
    local tgt_player, tgt_root = find_target(fov)
    if not tgt_root then return end

    begin_fling(root, char, hum, tgt_player, tgt_root)
end

-- Rising-edge trigger so Hold mode fires once per press, Toggle/Always once when enabled.
local was_enabled = false

local function poll_enable()
    local on = settings.enabled(P)
    if on and not was_enabled then
        try_trigger()
    end
    was_enabled = on
end

local function tick(_dt)
    if state == STATE_IDLE then
        if not misc_gate.movement_allowed() then
            was_enabled = settings.enabled(P)
            return
        end
        poll_enable()
        return
    end

    if state ~= STATE_RETURN and not misc_gate.movement_allowed() then
        return
    end

    local lp = env.get_local_player()
    if not lp then
        if state == STATE_RETURN and saved_pos then
            return_left = RETURN_TICKS
        else
            clear_session()
        end
        return
    end

    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then
        stop_fling(root, char, hum)
        return
    end

    tick_active(root, char, hum)
end

function M.is_active()
    return state == STATE_APPROACH or state == STATE_FLING or state == STATE_RETURN
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Combat")
    menu_util.register_keybind(T, G.MISC, P, "Fling", false)
    menu.add_slider_int(T, G.MISC, P_FOV, "Fling FOV", 20, 600, 150, root)
    menu.add_slider_int(T, G.MISC, P_DURATION, "Fling Duration", 2, 10, 2, root)
    menu_util.bind_children(P, { P_FOV, P_DURATION })
end

function M.install()
    if _installed then return end
    _installed = true
    local runservice = April.require("core.runservice")
    runservice.on_sim(function(dt)
        tick(dt)
    end)
end

function M.update(_dt) end

function M.draw() end

return M

end)()

-- ── features/movement/desync.lua ──
April._mods["features.movement.desync"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local fflag_mem = April.require("core.fflag_mem")
local desync_vis = April.require("core.desync_vis")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_desync_enabled"
local P_VIS = "april_desync_visualizer"

local RANGE_RADIUS = 8

local LOOP_MS = 30
local last_tick = 0
local last_flag_apply = 0
local old_phys, old_send = nil, nil
local was_active = false
local anchor_pos = nil

local peek_hold = false

local function now()
    if utility and utility.get_time then return utility.get_time() end
    return os.clock()
end

local function get_root()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function capture_pos(root)
    if not root then return nil end
    local pos = root.Position or root.position
    if not pos then return nil end
    return {
        x = pos.X or pos.x or 0,
        y = pos.Y or pos.y or 0,
        z = pos.Z or pos.z or 0,
    }
end

local function dist_from_anchor(pos)
    if not anchor_pos or not pos then return 0 end
    local dx = pos.x - anchor_pos.x
    local dy = pos.y - anchor_pos.y
    local dz = pos.z - anchor_pos.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function apply_rates(physics_rate, sender_rate)
    local phys = tonumber(physics_rate) or 0
    local send = tonumber(sender_rate) or 60
    local bw = phys == 0 and 0 or 38760

    fflag_mem.set_int("S2PhysicsSenderRate", phys)
    fflag_mem.set_int("PhysicsSenderMaxBandwidthBps", bw)
    fflag_mem.set_int("DataSenderRate", send)
end

local function restore_rates()
    fflag_mem.reset_defaults()
    old_phys, old_send = nil, nil
    last_flag_apply = 0
end

local function active()
    return settings.enabled(P)
end

function M.peek_begin()
    if peek_hold then return end
    peek_hold = true
    pcall(fflag_mem.refresh)
    if not active() then
        apply_rates(0, 60)
        old_phys, old_send = 0, 60
        last_flag_apply = now()
    end
end

function M.peek_end()
    if not peek_hold then return end
    peek_hold = false
    if not active() then
        restore_rates()
        anchor_pos = nil
        was_active = false
    end
end

function M.peek_held()
    return peek_hold
end

local function disable_desync()
    if menu and menu.set then
        pcall(menu.set, P, false)
    end
end

local function compute_rates(_t)
    return 0, 60
end

local function draw_center_dot(wx, wy, wz, col)
    local sx, sy, vis = esp_util.w2s(wx, wy, wz)
    if vis then
        draw_util.circle(sx, sy, 5, col, true)
        draw_util.circle(sx, sy, 5, { 0, 0, 0, col[4] or 1 }, false)
    end
end

local function draw_visualizer()
    if not anchor_pos then return end

    local col = settings.color(P_VIS, { 0.2, 0.85, 1, 0.9 })
    local ring_col = { col[1], col[2], col[3], 0.55 }
    desync_vis.draw_sphere_ring(anchor_pos.x, anchor_pos.y, anchor_pos.z, RANGE_RADIUS, ring_col, 2)

    if settings.bool(P_VIS, false) then
        draw_center_dot(anchor_pos.x, anchor_pos.y, anchor_pos.z, col)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Network")
    menu_util.register_keybind(T, G.MISC, P, "Desync", false)
    menu.add_checkbox(T, G.MISC, P_VIS, "Desync Visualize", false, menu_util.parent(P, {
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))

    menu_util.bind_children(P, { P_VIS })
end

function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    local user_on = active()
    local held = peek_hold
    local on = user_on or held
    local t = now()

    if was_active and not on then
        restore_rates()
        anchor_pos = nil
    end

    if user_on and not was_active then
        pcall(fflag_mem.refresh)
        local root = get_root()
        anchor_pos = capture_pos(root)
    end

    was_active = on
    if not on then return end

    if (t - last_tick) * 1000 < LOOP_MS then return end
    last_tick = t

    local phys, send = compute_rates(t)
    local root = get_root()

    if user_on and root and anchor_pos then
        local pos = capture_pos(root)
        if pos and dist_from_anchor(pos) > RANGE_RADIUS then
            restore_rates()
            anchor_pos = nil
            was_active = false
            disable_desync()
            return
        end
    end

    if phys ~= old_phys or send ~= old_send or (t - last_flag_apply) > 0.35 then
        apply_rates(phys, send)
        old_phys, old_send = phys, send
        last_flag_apply = t
    end
end

function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not active() and not peek_hold then return end
    draw_visualizer()
end

return M

end)()

-- ── features/movement/anti_aim.lua ──
April._mods["features.movement.anti_aim"] = (function()
--[[
  Anti-Aim - continuous body yaw (AutoRotate off + CFrame / angular velocity).

  Same drive as the working yaw AA; pauses while firing (LMB) and snaps
  back to camera yaw so flashpoint / shots stay valid.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local angle_util = April.require("core.angle_util")

local M = {}

local P = "april_antiaim_enabled"
local P_YAW = "april_antiaim_yaw_mode"
local P_YAW_MANUAL = "april_antiaim_yaw_manual"
local P_SPIN = "april_antiaim_spin_speed"
local P_JITTER = "april_antiaim_jitter_step"
local P_JITTER_MS = "april_antiaim_jitter_ms"

local YAW_LABELS = {
    "None", "Backwards", "Spin", "Jitter", "Random Jitter",
    "Sideways Left", "Sideways Right", "Manual",
}
local YAW_MANUAL_IDX = 7
local YAW_SPIN, YAW_JITTER, YAW_RAND = 2, 3, 4

local YAW_GAIN = 22
local YAW_AV_MAX = 40
local YAW_SNAP_EPS = 0.02
local SHOOT_VK = 0x01

local state = {
    fake_yaw = 0,
    yaw_jitter_idx = 0,
    jitter_t = 0,
    random_yaw = 0,
    spin_yaw = 0,
    was_active = false,
    was_firing = false,
}

M.YAW_LABELS = YAW_LABELS

local function active()
    return settings.enabled(P)
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function get_character(lp)
    if not lp then lp = env.get_local_player() end
    if lp then
        local char = lp.Character or lp.character
        if char then return char end
    end
    local rp = game and (game.LocalPlayer or game.local_player)
    if rp then return rp.Character or rp.character end
    return nil
end

local function get_humanoid(lp)
    if lp then
        local hum = lp.Humanoid or lp.humanoid
        if hum then return hum end
    end
    local char = get_character(lp)
    return char and (move.find_part(char, "Humanoid") or find_child(char, "Humanoid"))
end

local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return move.find_part(char, "HumanoidRootPart")
        or find_child(char, "HumanoidRootPart")
        or env.safe_call(function() return char.PrimaryPart or char.primary_part end)
end

local function get_attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end

-- LMB or Fallen ViewmodelController Using / Aiming fire path.
local function is_firing(char)
    if input and input.is_key_down and input.is_key_down(SHOOT_VK) then
        return true
    end
    local vm = char and find_child(char, "ViewmodelController")
    if vm then
        if get_attr(vm, "Using") == true then return true end
    end
    return false
end

local function compute_fake_yaw(real_yaw, dt)
    local mode = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if mode == 0 then return nil end
    dt = dt or 0.016
    if mode == 1 then return angle_util.normalize_yaw(real_yaw + math.pi) end
    if mode == 2 then
        state.spin_yaw = angle_util.normalize_yaw(state.spin_yaw + math.rad(settings.num(P_SPIN, 180)) * dt)
        return angle_util.normalize_yaw(real_yaw + state.spin_yaw)
    end
    if mode == 3 then
        local step = math.max(15, settings.num(P_JITTER, 90))
        return angle_util.normalize_yaw(real_yaw + math.rad(state.yaw_jitter_idx * step))
    end
    if mode == 4 then return angle_util.normalize_yaw(real_yaw + state.random_yaw) end
    if mode == 5 then return angle_util.normalize_yaw(real_yaw + math.pi * 0.5) end
    if mode == 6 then return angle_util.normalize_yaw(real_yaw - math.pi * 0.5) end
    return angle_util.normalize_yaw(real_yaw + math.rad(settings.num(P_YAW_MANUAL, 90)))
end

local function advance_jitter(dt)
    local yaw_m = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if yaw_m ~= YAW_JITTER and yaw_m ~= YAW_RAND then return end

    local interval = math.max(0.04, settings.num(P_JITTER_MS, 120) / 1000)
    state.jitter_t = state.jitter_t + dt
    if state.jitter_t < interval then return end
    state.jitter_t = 0

    local step = math.max(15, settings.num(P_JITTER, 90))
    if yaw_m == YAW_JITTER then
        state.yaw_jitter_idx = (state.yaw_jitter_idx + 1) % math.max(1, math.floor(360 / step))
    end
    if yaw_m == YAW_RAND then
        state.random_yaw = math.random() * math.pi * 2
    end
end

local function disable_auto_rotate(lp, hum)
    if lp then pcall(function() lp.AutoRotate = false end) end
    if hum then
        pcall(function() hum.AutoRotate = false end)
        pcall(function() hum.auto_rotate = false end)
    end
end

local function restore_auto_rotate(lp, hum)
    if lp then pcall(function() lp.AutoRotate = true end) end
    if hum then
        pcall(function() hum.AutoRotate = true end)
        pcall(function() hum.auto_rotate = true end)
    end
end

local function write_yaw(char, root, yaw)
    if yaw == nil or not root or not CFrame then return end
    local pos = move.read_pos(root)
    if not pos then return end
    local cf = CFrame.new(pos.x, pos.y, pos.z) * CFrame.Angles(0, yaw, 0)
    pcall(function() root.CFrame = cf end)
    if char then
        pcall(function()
            if char.PivotTo then char:PivotTo(cf) end
        end)
    end
end

local function steer_yaw(root, body_yaw, target_yaw)
    if target_yaw == nil or not root then return end
    local mode = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if mode == YAW_SPIN then
        move.set_angular_velocity(root, 0, math.rad(settings.num(P_SPIN, 180)), 0)
        return
    end
    local diff = angle_util.yaw_delta(body_yaw, target_yaw)
    if math.abs(diff) < YAW_SNAP_EPS then
        move.set_angular_velocity(root, 0, 0, 0)
        return
    end
    local av = diff * YAW_GAIN
    if av > YAW_AV_MAX then av = YAW_AV_MAX elseif av < -YAW_AV_MAX then av = -YAW_AV_MAX end
    move.set_angular_velocity(root, 0, av, 0)
end

local function face_camera(lp, char, root, hum)
    local yaw = angle_util.camera_yaw()
    write_yaw(char, root, yaw)
    if root then move.set_angular_velocity(root, 0, 0, 0) end
    restore_auto_rotate(lp, hum)
end

local function tick_aa(dt)
    local lp = env.get_local_player()
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root then return end

    disable_auto_rotate(lp, hum)
    advance_jitter(dt)

    local real_yaw = angle_util.camera_yaw()
    local fake_yaw = compute_fake_yaw(real_yaw, dt)
    if fake_yaw == nil then
        move.set_angular_velocity(root, 0, 0, 0)
        return
    end

    state.fake_yaw = fake_yaw
    local body_yaw = angle_util.body_yaw(lp, root)
    write_yaw(char, root, fake_yaw)
    steer_yaw(root, body_yaw, fake_yaw)
end

local function sync_option_visibility()
    if not menu or not menu.set_visible then return end
    local on = active()
    local yaw_m = settings.combo_index(P_YAW, YAW_LABELS, 0)
    pcall(menu.set_visible, P_YAW_MANUAL, on and yaw_m == YAW_MANUAL_IDX)
    pcall(menu.set_visible, P_SPIN, on and yaw_m == YAW_SPIN)
    pcall(menu.set_visible, P_JITTER, on and (yaw_m == YAW_JITTER or yaw_m == YAW_RAND))
    pcall(menu.set_visible, P_JITTER_MS, on and (yaw_m == YAW_JITTER or yaw_m == YAW_RAND))
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, P, "Anti-Aim", false)
    menu.add_combo(T, G.MISC, P_YAW, "Yaw Mode", YAW_LABELS, 1, root)
    menu.add_slider_int(T, G.MISC, P_YAW_MANUAL, "Manual Yaw", -180, 180, 90,
        menu_util.parent(P_YAW, { parent_value = YAW_MANUAL_IDX }))
    menu.add_slider_int(T, G.MISC, P_SPIN, "Spin Speed", 30, 720, 180, root)
    menu.add_slider_int(T, G.MISC, P_JITTER, "Jitter Step", 15, 180, 90, root)
    menu.add_slider_int(T, G.MISC, P_JITTER_MS, "Jitter Interval (ms)", 40, 500, 120, root)

    menu_util.bind_children(P, {
        P_YAW, P_YAW_MANUAL, P_SPIN, P_JITTER, P_JITTER_MS,
    })

    if menu and menu.set_callback then
        pcall(menu.set_callback, P, sync_option_visibility)
        pcall(menu.set_callback, P_YAW, sync_option_visibility)
    end
    sync_option_visibility()
end

function M.install() end

function M.update(dt)
    sync_option_visibility()
    dt = dt or 0.016

    local lp = env.get_local_player()
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    local on = active() and misc_gate.movement_allowed()
    local firing = on and is_firing(char)

    if state.was_active and (not on or firing) then
        if root then move.set_angular_velocity(root, 0, 0, 0) end
        if firing and on then
            face_camera(lp, char, root, hum)
        else
            restore_auto_rotate(lp, hum)
            state.spin_yaw = 0
            state.jitter_t = 0
        end
    end

    -- Leaving fire: re-engage AA next tick.
    if state.was_firing and on and not firing then
        disable_auto_rotate(lp, hum)
    end

    state.was_active = on and not firing
    state.was_firing = firing

    if not on or firing then return end
    if settings.combo_index(P_YAW, YAW_LABELS, 0) == 0 then return end
    tick_aa(dt)
end

function M.draw() end

return M

end)()

-- ── features/movement/fake_duck.lua ──
April._mods["features.movement.fake_duck"] = (function()
--[[
  Fake Duck - look crouched (IsCrouch / hip) while moving at stand/sprint speed.

  Fallen StateController sets WalkSpeed=6.5 when crouched. Writing WalkSpeed
  kicks - so we leave WalkSpeed alone and boost HRP velocity to walk(11)/sprint(18).

  Optional height spam: flip HipHeight between min/max on an interval.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local runservice = April.require("core.runservice")

local M = {}

local P = "april_fakeduck_enabled"
local P_HEIGHT = "april_fakeduck_height"
local P_SPAM = "april_fakeduck_spam"
local P_SPAM_MIN = "april_fakeduck_spam_min"
local P_SPAM_MAX = "april_fakeduck_spam_max"
local P_SPAM_MS = "april_fakeduck_spam_ms"
local P_SPAM_MODE = "april_fakeduck_spam_mode"

local SPAM_MODES = { "Alternating", "Random" }

-- Fallen stand hip = 1.6, normal crouch = 1.1. Lower values push further down.
local DEFAULT_DUCK_HIP = 1.1
local STAND_HIP = 1.6
local HIP_MIN = 0.01
local HIP_MAX = 1.5
local SPEED_WALK = 11
local SPEED_SPRINT = 18
local SPEED_AIM_MUL = 0.8
local SPEED_SLOW_MUL = 0.3
local MOVE_EPS = 0.05

local state = {
    was_active = false,
    hooks_installed = false,
    state_ctrl = nil,
    viewmodel = nil,
    root = nil,
    hum = nil,
    spam_t = 0,
    spam_hi = false,
    spam_val = DEFAULT_DUCK_HIP,
}

local function active()
    return settings.enabled(P)
end

local function clamp_hip(h)
    h = tonumber(h) or DEFAULT_DUCK_HIP
    if h > HIP_MAX then h = HIP_MAX end
    if h < HIP_MIN then h = HIP_MIN end
    return h
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function get_character(lp)
    if not lp then lp = env.get_local_player() end
    if lp then
        local char = lp.Character or lp.character
        if char then return char end
    end
    local rp = game and (game.LocalPlayer or game.local_player)
    if rp then return rp.Character or rp.character end
    return nil
end

local function get_attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end

local function set_attr(inst, name, value)
    if not inst then return end
    pcall(function()
        if inst.SetAttribute then
            inst:SetAttribute(name, value)
        elseif inst.set_attribute then
            inst:set_attribute(name, value)
        end
    end)
end

local function set_hip_height(hum, value)
    if not hum then return end
    pcall(function() hum.HipHeight = value end)
    local lp = env.get_local_player()
    if lp then
        pcall(function() lp.HipHeight = value end)
    end
end

local function static_duck_hip()
    return clamp_hip(settings.num(P_HEIGHT, DEFAULT_DUCK_HIP))
end

local function spam_range()
    local lo = clamp_hip(settings.num(P_SPAM_MIN, HIP_MIN))
    local hi = clamp_hip(settings.num(P_SPAM_MAX, HIP_MAX))
    if lo > hi then
        lo, hi = hi, lo
    end
    return lo, hi
end

local function duck_hip(dt)
    if not settings.bool(P_SPAM, false) then
        state.spam_t = 0
        return static_duck_hip()
    end

    local lo, hi = spam_range()
    local interval = math.max(0.02, settings.num(P_SPAM_MS, 80) / 1000)
    local mode = settings.combo_index(P_SPAM_MODE, SPAM_MODES, 0)

    state.spam_t = (state.spam_t or 0) + (dt or 0.016)
    if state.spam_t >= interval then
        state.spam_t = 0
        if mode == 1 then
            -- Random value in [lo, hi]
            state.spam_val = lo + math.random() * (hi - lo)
        else
            -- Alternating endpoints
            state.spam_hi = not state.spam_hi
            state.spam_val = state.spam_hi and hi or lo
        end
    end

    return clamp_hip(state.spam_val or lo)
end

-- Slightly squash HRP as we go lower than normal crouch.
local function set_root_size(root, crouch, hip)
    if not root or not Vector3 then return end
    local y = 2.5
    if crouch then
        hip = hip or DEFAULT_DUCK_HIP
        y = 2.1 - (DEFAULT_DUCK_HIP - hip) * 0.35
        if y < 1.4 then y = 1.4 end
        if y > 2.4 then y = 2.4 end
    end
    pcall(function()
        root.Size = Vector3.new(2, y, 2)
    end)
end

local function resolve_parts()
    local lp = env.get_local_player()
    local char = get_character(lp)
    if not char then
        state.state_ctrl, state.viewmodel, state.root, state.hum = nil, nil, nil, nil
        return false
    end

    state.state_ctrl = find_child(char, "StateController")
    state.viewmodel = find_child(char, "ViewmodelController")
    state.root = move.find_part(char, "HumanoidRootPart") or find_child(char, "HumanoidRootPart")
    state.hum = (lp and (lp.Humanoid or lp.humanoid))
        or move.find_part(char, "Humanoid")
        or find_child(char, "Humanoid")
    return state.root ~= nil
end

local function desired_speed()
    local sc = state.state_ctrl
    local vm = state.viewmodel
    local hum = state.hum

    local sprint = get_attr(sc, "IsSprint") == true
    local aiming = get_attr(vm, "Aiming") == true
    local slowed = false
    if hum then
        local dc = get_attr(hum, "DamageConnections")
        slowed = type(dc) == "number" and dc > 0
    end
    if get_attr(hum, "Downed") == true then return 0 end

    local base = sprint and SPEED_SPRINT or SPEED_WALK
    if aiming then base = base * SPEED_AIM_MUL end
    if slowed then base = base * SPEED_SLOW_MUL end
    return base
end

local function boost_velocity(root, target)
    if not root or not target or target <= 0 then return end

    local mx, mz = move.read_flat_input()
    local vx, vy, vz = move.read_velocity(root)
    local input_mag = math.sqrt(mx * mx + mz * mz)

    if input_mag >= MOVE_EPS then
        move.set_velocity(root, mx * target, vy, mz * target)
        return
    end

    local hmag = math.sqrt(vx * vx + vz * vz)
    if hmag < 1.0 then return end
    if hmag >= target * 0.95 then return end
    local s = target / hmag
    move.set_velocity(root, vx * s, vy, vz * s)
end

local function apply_duck(dt)
    if not resolve_parts() then return end

    if state.state_ctrl then
        set_attr(state.state_ctrl, "IsCrouch", true)
    end

    local hip = duck_hip(dt)
    set_hip_height(state.hum, hip)
    set_root_size(state.root, true, hip)

    boost_velocity(state.root, desired_speed())
end

local function restore_duck()
    resolve_parts()
    if state.state_ctrl then
        set_attr(state.state_ctrl, "IsCrouch", false)
    end
    set_hip_height(state.hum, STAND_HIP)
    set_root_size(state.root, false)
    state.spam_t = 0
    state.spam_hi = false
end

local function on_sim(dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()

    if state.was_active and not on then
        restore_duck()
    end
    state.was_active = on

    if not on then return end
    apply_duck(dt or 0.016)
end

local function ensure_hooks()
    if state.hooks_installed then return end
    state.hooks_installed = true
    runservice.on_sim(on_sim)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    local spam_root = menu_util.parent(P_SPAM)

    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, P, "Fake Duck", false)
    menu.add_slider_float(T, G.MISC, P_HEIGHT, "Duck Height", HIP_MIN, HIP_MAX, DEFAULT_DUCK_HIP, "%.2f", root)
    menu.add_checkbox(T, G.MISC, P_SPAM, "Spam Height", false, root)
    menu.add_combo(T, G.MISC, P_SPAM_MODE, "Spam Mode", SPAM_MODES, 0, spam_root)
    menu.add_slider_float(T, G.MISC, P_SPAM_MIN, "Spam Min", HIP_MIN, HIP_MAX, HIP_MIN, "%.2f", spam_root)
    menu.add_slider_float(T, G.MISC, P_SPAM_MAX, "Spam Max", HIP_MIN, HIP_MAX, HIP_MAX, "%.2f", spam_root)
    menu.add_slider_int(T, G.MISC, P_SPAM_MS, "Spam Interval (ms)", 20, 400, 80, spam_root)

    menu_util.bind_children(P, {
        P_HEIGHT, P_SPAM, P_SPAM_MODE, P_SPAM_MIN, P_SPAM_MAX, P_SPAM_MS,
    })
    menu_util.bind_children(P_SPAM, {
        P_SPAM_MODE, P_SPAM_MIN, P_SPAM_MAX, P_SPAM_MS,
    })
end

function M.install()
    ensure_hooks()
end

function M.update(dt)
    ensure_hooks()
    if not runservice.uses_heartbeat() and misc_gate.movement_allowed() then
        on_sim(dt)
    elseif state.was_active and not active() then
        restore_duck()
        state.was_active = false
    end
end

function M.draw() end

return M

end)()

-- ── features/radar/waypoints.lua ──
April._mods["features.radar.waypoints"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_waypoints_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.section(T, G.RADAR, "Waypoints")
    menu_util.register_keybind(T, G.RADAR, P, "Enable Waypoints", false)
    menu.add_checkbox(T, G.RADAR, "april_wp_dist", "Waypoint Show Distance", false, root)
    menu.add_checkbox(T, G.RADAR, "april_wp_beacon", "Beacon Pillar", false, root)
    menu.add_slider_int(T, G.RADAR, "april_wp_beacon_h", "Beacon Height", 20, 200, 90, menu_util.parent("april_wp_beacon"))
    menu.add_checkbox(T, G.RADAR, "april_wp_draw", "Draw Markers", false, menu_util.parent(P, { colorpicker = { 0.2, 1, 0.8, 1 } }))
    menu.add_slider_int(T, G.RADAR, "april_wp_slot", "Waypoint Active Slot", 1, 5, 1, root)

    menu_util.button(T, G.RADAR, "april_wp_set", "Set Active Waypoint", function()
        local slot = settings.num("april_wp_slot", 1)
        local lp = env.get_local_player()
        if lp and lp.position then
            cache.waypoints[slot] = {
                name = "Waypoint " .. slot,
                pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z },
            }
        end
    end, P)

    menu_util.button(T, G.RADAR, "april_wp_clear", "Clear Active Waypoint", function()
        local slot = settings.num("april_wp_slot", 1)
        cache.waypoints[slot] = nil
    end, P)

    menu_util.button(T, G.RADAR, "april_wp_clear_all", "Clear All Waypoints", function()
        cache.waypoints = {}
    end, P)

    menu_util.bind_children(P, {
        "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h", "april_wp_draw",
        "april_wp_slot", "april_wp_set", "april_wp_clear", "april_wp_clear_all",
    })
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not settings.bool("april_wp_draw", false) and not settings.bool("april_wp_beacon", false) then return end

    local col = settings.color("april_wp_draw", { 0.2, 1, 0.8, 1 })
    local beacon_h = settings.num("april_wp_beacon_h", 90)
    local me = env.get_local_player()

    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local wx, wy, wz = wp.pos.x, wp.pos.y, wp.pos.z

            if settings.bool("april_wp_beacon", false) then
                esp_util.draw_vertical_beacon(wx, wy, wz, col, { height = beacon_h })
            end

            local sx, sy, vis = esp_util.w2s(wx, wy, wz)
            if not vis then goto continue end

            local label = wp.name or ("WP" .. tostring(i))
            if settings.bool("april_wp_dist", false) and me and me.position then
                local dx = wx - me.position.x
                local dy = wy - me.position.y
                local dz = wz - me.position.z
                label = label .. string.format(" [%.0fm]", math.sqrt(dx * dx + dy * dy + dz * dz))
            end

            if settings.bool("april_wp_draw", false) then
                draw_util.text_centered(sx, sy - 18, label, col, esp_util.text_size())
            end

            ::continue::
        end
    end
end

return M

end)()

-- ── features/radar/tactical_map.lua ──
April._mods["features.radar.tactical_map"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local panel_drag = April.require("core.panel_drag")

local M = {}
local P = "april_map_enabled"
local X_ID = "april_map_x"
local Y_ID = "april_map_y"
local TITLE_H = 24

local function get_camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, _, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            local lx, lz = lv.x or lv.X or 0, lv.z or lv.Z or 0
            if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
                return math.atan2(lx, lz)
            end
        end
    end
    return 0
end

local function get_view_origin()
    local cx, cy, cz = nil, nil, nil
    if camera and camera.get_position then
        local ok, pos = pcall(camera.get_position)
        if ok and pos and (pos.x or pos.X) then
            cx = pos.x or pos.X
            cy = pos.y or pos.Y
            cz = pos.z or pos.Z
        end
    end

    local lp = env.get_local_player()
    local px, py, pz = nil, nil, nil
    if lp and lp.position then
        px = lp.position.x
        py = lp.position.y
        pz = lp.position.z
    end

    if not cx then cx, cy, cz = px, py, pz end
    return cx or 0, cy or 0, cz or 0, px, py, pz
end

local function map_basis(yaw)
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = -math.cos(yaw), math.sin(yaw)
    return fx, fz, rx, rz
end

local function world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local wdx = wx - view_x
    local wdz = wz - view_z
    local fx, fz, rx, rz = map_basis(yaw)
    local local_fwd = wdx * fx + wdz * fz
    local local_right = wdx * rx + wdz * rz
    return map_cx + local_right * zoom, map_cy - local_fwd * zoom
end

local function clamp_to_disc(mx, my, cx, cy, radius)
    local dx, dy = mx - cx, my - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= radius or dist < 0.001 then
        return mx, my, false
    end
    local s = radius / dist
    return cx + dx * s, cy + dy * s, true
end

local function entry_world_xz(entry)
    if not entry then return nil, nil end
    local lx, _, lz = esp_scan.entry_coords(entry)
    if lx and lz then return lx, lz end
    if entry.lx and entry.lz then return entry.lx, entry.lz end
    if entry.pos then return entry.pos.x, entry.pos.z end
    local inst = entry.inst
    if inst and env.is_valid(inst) then
        local pos = inst.Position or inst.position
        if pos and pos.x then return pos.x, pos.z end
    end
    return nil, nil
end

local function short_label(text)
    if not text or text == "" then return "" end
    text = text:gsub("%s*%(Sleeper%)", "")
    if #text > 10 then
        return text:sub(1, 9) .. ".."
    end
    return text
end

local function draw_radar_label(lx, ly, text, col, x, y, w, h, fs)
    if not text or text == "" or not draw or not draw.get_text_size then return end
    fs = fs or 9
    local tw = select(1, draw.get_text_size(text, fs))
    local th = fs + 2
    lx = lx - tw * 0.5
    ly = ly + 5
    if lx < x + 4 then lx = x + 4 end
    if lx + tw > x + w - 4 then lx = x + w - 4 - tw end
    if ly + th > y + h - 4 then ly = ly - th - 8 end
    if ly < y + 4 then return end

    if draw.rect_filled then
        draw.rect_filled(lx - 3, ly - 2, tw + 6, th + 2, theme.PANEL_DEEP, 0)
    end
    if draw.rect then
        draw.rect(lx - 3, ly - 2, tw + 6, th + 2, theme.BORDER, 0, 1)
    end
    draw_util.text(lx, ly, text, col, fs)
end

local function draw_blip(mx, my, scale, col, clamped, shape)
    local alpha = clamped and 0.72 or 1
    local c = { col[1], col[2], col[3], (col[4] or 1) * alpha }
    local r = math.max(2, scale - (clamped and 1 or 0))
    local edge = theme.alpha(theme.PANEL_DEEP, math.min(0.95, c[4]))
    shape = shape or "circle"

    if shape == "square" and draw and draw.rect_filled then
        draw.rect_filled(mx - r - 1, my - r - 1, (r + 1) * 2, (r + 1) * 2, edge, 0)
        draw.rect_filled(mx - r, my - r, r * 2, r * 2, c, 0)
    elseif shape == "diamond" and draw and draw.poly_filled then
        draw.poly_filled({
            { mx, my - r - 1 }, { mx + r + 1, my },
            { mx, my + r + 1 }, { mx - r - 1, my },
        }, edge)
        draw.poly_filled({
            { mx, my - r }, { mx + r, my },
            { mx, my + r }, { mx - r, my },
        }, c)
    elseif shape == "waypoint" and draw and draw.circle_filled then
        draw.circle_filled(mx, my, r + 2, edge, 12)
        draw.circle_filled(mx, my, r + 1, c, 12)
        draw.circle_filled(mx, my, math.max(1, r - 1), theme.PANEL_DEEP, 10)
    elseif draw and draw.circle_filled then
        draw.circle_filled(mx, my, r + 1, edge, 10)
        draw.circle_filled(mx, my, r, c, 10)
    else
        draw_util.circle(mx, my, r, c, true)
    end
end

local function draw_map_item(wx, wz, col, label, shape, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, layout)
    if not wx or not wz then return end

    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local clamped
    mx, my, clamped = clamp_to_disc(mx, my, map_cx, map_cy, layout.radius)

    draw_blip(mx, my, scale, col, clamped, shape)

    if settings.bool("april_map_labels", false) and not clamped then
        draw_radar_label(mx, my, short_label(label), col, layout.x, layout.y, layout.w, layout.h, 9)
    end
end

local function draw_radar_frame(layout, bg, grid, zoom)
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local cx, cy = layout.cx, layout.cy

    overlay_theme.draw_panel(x, y, w, h, "TACTICAL RADAR")

    if draw.rect_filled then
        draw.rect_filled(x + 7, y + TITLE_H + 5, w - 14, h - TITLE_H - 12, bg, 0)
    end
    if draw.rect then
        draw.rect(x + 7, y + TITLE_H + 5, w - 14, h - TITLE_H - 12, theme.BORDER, 0, 1)
    end

    local zoom_text = string.format("x%.2f", zoom)
    local zoom_w = theme.text_w(zoom_text, 9)
    draw_util.text(x + w - zoom_w - 8, y + 7, zoom_text, theme.TEXT_DIM, 9)

    if draw and draw.circle then
        draw.circle(cx, cy, layout.radius, theme.alpha(grid, 0.42), 24, 1)
        draw.circle(cx, cy, layout.radius * 0.66, grid, 24, 1)
        draw.circle(cx, cy, layout.radius * 0.33, grid, 24, 1)
    end
    if draw and draw.line then
        draw.line(cx - layout.radius, cy, cx + layout.radius, cy, theme.alpha(grid, 0.72), 1)
        draw.line(cx, cy - layout.radius, cx, cy + layout.radius, theme.alpha(grid, 0.72), 1)
    end

    local card = theme.alpha(overlay_theme.accent(), 0.92)
    draw_util.text(cx - 3, cy - layout.radius + 5, "N", card, 9)
    draw_util.text(cx + layout.radius - 10, cy - 5, "E", theme.TEXT_DIM, 9)
    draw_util.text(cx - 3, cy + layout.radius - 14, "S", theme.TEXT_DIM, 9)
    draw_util.text(cx - layout.radius + 5, cy - 5, "W", theme.TEXT_DIM, 9)
end

local function draw_local_blip(layout, col, body_x, body_z, view_x, view_z, zoom, yaw)
    local cx, cy = layout.cx, layout.cy
    local mx, my = cx, cy
    if body_x and body_z then
        mx, my = world_to_map(body_x, body_z, view_x, view_z, cx, cy, zoom, yaw)
        mx, my = clamp_to_disc(mx, my, cx, cy, layout.radius)
    end

    local r = layout.scale + 2
    if draw and draw.poly_filled then
        draw.poly_filled({
            { mx, my - r - 2 },
            { mx + r, my + r },
            { mx, my + math.max(1, r - 2) },
            { mx - r, my + r },
        }, col)
    elseif draw and draw.line then
        draw.line(mx, my - r, mx - r, my + r, col, 2)
        draw.line(mx - r, my + r, mx + r, my + r, col, 2)
        draw.line(mx + r, my + r, mx, my - r, col, 2)
    end
    if draw and draw.circle then
        draw.circle(mx, my, r + 2, theme.alpha(col, 0.32), 16, 1)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.section(T, G.RADAR, "Tactical Map")
    menu_util.register_keybind(T, G.RADAR, P, "Enable Radar", false, { key = 0x28 })

    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Radar Show Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "Radar Show NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Radar Show Loot", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "Radar Show Resources", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Radar Show Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Radar Show Waypoints", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Radar Show Labels", false, root)

    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Radar Players Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "Radar NPCs Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "Radar Resources Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Radar Waypoints Color", theme.CYAN, root)

    menu_util.gap(T, G.RADAR)
    menu.add_slider_int(T, G.RADAR, "april_map_zoom", "Radar Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Radar Size", 140, 420, 240, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Radar Blip Size", 2, 6, 3, root)
    menu_util.button(T, G.RADAR, "april_map_reset_position", "Reset Radar Position", function()
        local sw = select(1, draw_util.screen_size())
        local size = settings.num("april_map_size", 240)
        local rx, ry = sw - size - 16, 16
        if menu and menu.set then
            pcall(menu.set, X_ID, rx)
            pcall(menu.set, Y_ID, ry)
        end
        pcall(function()
            local state = April.require("ui.gs_state")
            state.set(X_ID, rx)
            state.set(Y_ID, ry)
        end)
    end)

    menu_util.bind_children(P, {
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_labels",
        "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col",
        "april_map_zoom", "april_map_size", "april_map_icon_scale", "april_map_reset_position",
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end

    overlay_theme.sync()
    local sw, sh = draw_util.screen_size()
    local size = settings.num("april_map_size", 240)
    local default_x, default_y = sw - size - 16, 16
    local x, y = panel_drag.update(
        "tactical_radar", X_ID, Y_ID, size, TITLE_H, sw, sh, default_x, default_y
    )
    x, y = panel_drag.clamp(x, y, size, size, sw, sh, X_ID, Y_ID)
    local w, h = size, size
    local body_y, body_h = y + TITLE_H, h - TITLE_H
    local cx, cy = x + w * 0.5, body_y + body_h * 0.5
    local radius = math.min(w, body_h) * 0.5 - 12
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)

    local layout = {
        x = x, y = y, w = w, h = h, cx = cx, cy = cy,
        radius = radius, label_radius = math.max(24, radius - 28), scale = scale,
    }

    local bg = theme.MAP_BG
    local grid = theme.MAP_GRID

    local cam_x, _, cam_z, body_x, _, body_z = get_view_origin()
    local yaw = get_camera_yaw()
    local view_x, view_z = cam_x, cam_z

    draw_radar_frame(layout, bg, grid, zoom)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", theme.GREEN)
        for _, item in ipairs(cache.world) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.35, 1 })
        for _, item in ipairs(cache.loot) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "square", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.55, 0.55, 1, 1 })
        for _, item in ipairs(cache.base) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", theme.ORANGE)
        for _, entry in ipairs(cache.npcs) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if wx then
                    draw_map_item(wx, wz, col, entry.name, "circle", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", theme.CYAN)
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), "waypoint", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", theme.RED)
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) and p.position then
                local label = (p.display_name and p.display_name ~= "" and p.display_name) or p.name
                draw_map_item(p.position.x, p.position.z, col, label, "circle", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    local local_col = overlay_theme.accent()
    draw_local_blip(layout, local_col, body_x, body_z, view_x, view_z, zoom, yaw)
end

return M

end)()

-- ── features/utility/keybind_viewer.lua ──
April._mods["features.utility.keybind_viewer"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local feature_bind = April.require("core.feature_bind")
local vk_names = April.require("core.vk_names")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_keybinds_enabled"
local X_ID = "april_keybinds_x"
local Y_ID = "april_keybinds_y"
local PANEL_W = 260
local TITLE_H = 24

local function strip_enable_prefix(label)
    if type(label) ~= "string" then return tostring(label or "?") end
    label = label:gsub("^Enable%s+", "")
    return label
end

local function collect_rows()
    local rows = {}
    local only_active = settings.bool("april_keybinds_active_only", false)
    local show_unbound = settings.bool("april_keybinds_show_unbound", true)
    local show_mode = settings.bool("april_keybinds_show_mode", true)

    for _, entry in ipairs(feature_bind.list_entries()) do
        local id = entry.id
        local key = feature_bind.get_key(id)
        local active = feature_bind.active(id)
        if key <= 0 and not show_unbound then
            goto continue
        end
        if only_active and not active then
            goto continue
        end
        if feature_bind.is_hidden_from_list(id) then
            goto continue
        end

        rows[#rows + 1] = {
            id = id,
            label = strip_enable_prefix(entry.label or id),
            key = vk_names.chip(key),
            mode = feature_bind.mode_name(id),
            active = active,
            show_mode = show_mode,
        }

        ::continue::
    end

    table.sort(rows, function(a, b)
        if a.active ~= b.active then return a.active end
        return a.label < b.label
    end)

    return rows
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.MISC, P, "Keybind Viewer", false)

    menu_util.section(T, G.MISC, "Keybinds Display")
    menu.add_checkbox(T, G.MISC, "april_keybinds_active_only", "Only Show Active", false, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_unbound", "Show Unbound", true, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_mode", "Show Bind Mode", true, root)

    menu_util.bind_children(P, {
        "april_keybinds_active_only", "april_keybinds_show_unbound", "april_keybinds_show_mode",
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end

    overlay_theme.sync()
    local accent = overlay_theme.accent()

    local sw, sh = draw_util.screen_size()
    local rows = collect_rows()
    local pad = 10
    local row_h = 18
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 10

    local x, y = panel_drag.update(
        "keybind_viewer",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        16, 280
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)

    overlay_theme.draw_panel(x, y, PANEL_W, height, "KEYBINDS")

    local ry = y + TITLE_H
    if #rows == 0 then
        draw_util.text(x + pad, ry, "No binds", theme.TEXT_MUTED, 11)
        return
    end

    local max_label = math.max(8, math.floor((PANEL_W - pad * 2) * 0.55 / 7))

    for i = 1, #rows do
        local row = rows[i]
        local name_col = row.active and theme.TEXT or theme.TEXT_MUTED
        local key_col = row.active and accent or theme.TEXT_DIM

        local label = row.label
        if #label > max_label then label = label:sub(1, math.max(1, max_label - 2)) .. ".." end
        if row.active and draw and draw.rect_filled then
            draw.rect_filled(x + 3, ry + 2, 2, row_h - 5, theme.alpha(accent, 0.82), 0)
        end
        draw_util.text(x + pad, ry, label, name_col, 11)

        local right = row.key
        if row.show_mode then
            right = right .. " - " .. row.mode
        end
        local tw = theme.text_w(right, 11)
        draw_util.text(x + PANEL_W - pad - tw, ry, right, key_col, 11)

        ry = ry + row_h
    end
end

return M

end)()

-- ── features/utility/anti_afk.lua ──
April._mods["features.utility.anti_afk"] = (function()
-- Anti-AFK: Roblox kicks ~20m idle. Nudge input every 14m while enabled.

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_anti_afk"

-- Stay under Roblox's ~20 minute idle kick.
local INTERVAL_MS = 14 * 60 * 1000

M._last_nudge = 0

local function now_ms()
    if utility and utility.get_tick_count then
        return utility.get_tick_count()
    end
    return math.floor(os.clock() * 1000)
end

local function nudge()
    -- Prefer a tiny mouse wiggle (doesn't fire weapons). Fall back to space tap.
    if input and input.move_mouse then
        pcall(input.move_mouse, 1, 0)
        pcall(input.move_mouse, -1, 0)
        return true
    end
    if utility and utility.key_press then
        pcall(utility.key_press, 0x20) -- space
        return true
    end
    if utility and utility.mouse_click then
        -- Last resort; avoid if possible (can shoot).
        return false
    end
    return false
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    menu.add_checkbox(T, G.MISC, P, "Anti AFK", false)
end

function M.update(_dt)
    if not settings.bool(P, false) then
        M._last_nudge = 0
        return
    end

    local now = now_ms()
    if M._last_nudge == 0 then
        M._last_nudge = now
        return
    end
    if (now - M._last_nudge) < INTERVAL_MS then
        return
    end
    M._last_nudge = now
    nudge()
end

function M.draw() end

return M

end)()

-- ── features/utility/config.lua ──
April._mods["features.utility.config"] = (function()
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
        notify.success(string.format('Saved "%s" -> Slot %d', profile_label(), slot), 3500)
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

    menu_util.input(T, G.CONFIG, "april_cfg_profile_name", "Profile Name", "Default")

    menu.add_slider_int(T, G.CONFIG, "april_cfg_slot", "Active Slot (1-5)", store.SLOT_MIN, store.SLOT_MAX, 1)

    menu_util.button(T, G.CONFIG, "april_cfg_save", "Save to Active Slot", function()
        M.save_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_load", "Load Active Slot", function()
        M.load_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_delete", "Delete Active Slot", function()
        M.delete_slot(active_slot())
    end)

    menu_util.gap(T, G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_cfg_autoload", "Autoload on Start", false)
    menu_util.input(T, G.CONFIG, "april_cfg_autoload_profile", "Autoload Profile Name", "")
    menu.add_slider_int(
        T, G.CONFIG, "april_cfg_autoload_slot", "Autoload Slot (fallback)",
        store.SLOT_MIN, store.SLOT_MAX, 1,
        menu_util.parent("april_cfg_autoload")
    )

    menu_util.gap(T, G.CONFIG)
    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        April.require("game.bootstrap").force_reload()
        notify.info("Reloading game modules...", 2500)
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

end)()

-- ── ui/gs_theme.lua ──
April._mods["ui.gs_theme"] = (function()
-- Runtime dark-glass palette for April's draw-only UI.
-- Vector exposes alpha + rounded primitives, but no backdrop blur or custom fonts.
local M = {}

M.PRESET_NAMES = { "Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass" }
M.DENSITY_NAMES = { "Compact", "Balanced", "Comfortable" }
M.CORNER_NAMES = { "Sharp", "Soft", "Rounded" }

local PRESETS = {
    {
        bg = { 0.030, 0.032, 0.045 }, panel = { 0.070, 0.065, 0.095 },
        raised = { 0.105, 0.090, 0.135 }, accent = { 0.78, 0.20, 0.92 },
    },
    {
        bg = { 0.025, 0.040, 0.060 }, panel = { 0.055, 0.085, 0.120 },
        raised = { 0.075, 0.120, 0.165 }, accent = { 0.20, 0.68, 1.00 },
    },
    {
        bg = { 0.035, 0.037, 0.043 }, panel = { 0.075, 0.078, 0.088 },
        raised = { 0.115, 0.118, 0.130 }, accent = { 0.73, 0.76, 0.84 },
    },
    {
        bg = { 0.020, 0.045, 0.040 }, panel = { 0.045, 0.095, 0.080 },
        raised = { 0.065, 0.135, 0.110 }, accent = { 0.20, 0.92, 0.62 },
    },
}

local function clamp(v, a, b)
    v = tonumber(v) or a
    if v < a then return a end
    if v > b then return b end
    return v
end

local function rgb(c, alpha)
    return { c[1], c[2], c[3], alpha == nil and 1 or alpha }
end

local function mix_rgb(a, b, t, alpha)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        alpha == nil and 1 or alpha,
    }
end

local function setting(id, fallback)
    local ok, value = pcall(function()
        return April.require("core.settings").get(id, fallback)
    end)
    if ok and value ~= nil then return value end
    return fallback
end

local function scaled(v, scale)
    return math.max(1, math.floor(v * scale + 0.5))
end

M.RAINBOW = {
    { 0.20, 0.90, 0.95, 1 },
    { 0.55, 0.35, 0.95, 1 },
    { 0.95, 0.85, 0.20, 1 },
    { 0.95, 0.35, 0.55, 1 },
    { 0.35, 0.95, 0.45, 1 },
}

function M.sync()
    local preset_idx = math.floor(clamp(setting("april_ui_theme_preset", 0), 0, #PRESETS - 1)) + 1
    local p = PRESETS[preset_idx] or PRESETS[1]
    local scale = clamp(setting("april_ui_scale", 100), 80, 125) * 0.01
    local density = math.floor(clamp(setting("april_ui_density", 1), 0, 2))
    local density_mul = ({ 0.88, 1.0, 1.12 })[density + 1]
    local window_alpha = clamp(setting("april_ui_window_opacity", 86), 45, 100) * 0.01
    local panel_alpha = clamp(setting("april_ui_panel_opacity", 72), 35, 100) * 0.01
    local border_alpha = clamp(setting("april_ui_border_strength", 58), 10, 100) * 0.01
    local corner_style = math.floor(clamp(setting("april_ui_corner_style", 2), 0, 2))
    local corner_base = ({ 2, 6, 10 })[corner_style + 1]

    M.SCALE = scale
    M.DENSITY = density
    M.GLOBAL_ALPHA = 1
    M.WINDOW_ALPHA = window_alpha
    M.PANEL_ALPHA = panel_alpha
    M.PRESET_ACCENT = rgb(p.accent, 1)

    M.BG = rgb(p.bg, window_alpha)
    M.BG_INNER = mix_rgb(p.bg, p.panel, 0.28, math.min(1, window_alpha + 0.04))
    M.PANEL = rgb(p.panel, panel_alpha)
    M.PANEL_ALT = mix_rgb(p.panel, p.raised, 0.35, math.min(1, panel_alpha + 0.06))
    M.PANEL_RAISED = rgb(p.raised, math.min(1, panel_alpha + 0.12))
    M.OVERLAY = mix_rgb(p.panel, p.raised, 0.50, math.min(1, panel_alpha + 0.17))
    M.SHADOW = { 0, 0, 0, 0.32 * window_alpha }
    M.SHADOW_DEEP = { 0, 0, 0, 0.20 * window_alpha }
    M.GLASS_HIGHLIGHT = { 1, 1, 1, 0.045 * border_alpha }
    M.BORDER = { 0.34, 0.35, 0.42, 0.60 * border_alpha }
    M.BORDER_SOFT = { 0.28, 0.29, 0.36, 0.40 * border_alpha }
    M.BORDER_HOT = mix_rgb(p.raised, p.accent, 0.55, 0.72 * border_alpha)
    M.SIDEBAR = mix_rgb(p.bg, p.panel, 0.18, math.min(1, window_alpha + 0.02))
    M.SIDEBAR_ACTIVE = mix_rgb(p.panel, p.accent, 0.20, math.min(1, panel_alpha + 0.08))

    M.TEXT = { 0.78, 0.80, 0.87, 1 }
    M.TEXT_DIM = { 0.47, 0.49, 0.57, 1 }
    M.TEXT_ACTIVE = { 0.96, 0.97, 1.00, 1 }
    M.TEXT_TITLE = { 0.84, 0.86, 0.92, 1 }

    M.ACCENT = M.ACCENT or rgb(p.accent, 1)
    M.ACCENT_DIM = mix_rgb(p.bg, p.accent, 0.42, 0.85)
    M.CHECK_OFF = mix_rgb(p.bg, p.panel, 0.55, math.min(1, panel_alpha + 0.10))
    M.SLIDER_BG = mix_rgb(p.bg, p.panel, 0.62, math.min(1, panel_alpha + 0.06))
    M.BUTTON = mix_rgb(p.bg, p.panel, 0.72, math.min(1, panel_alpha + 0.10))
    M.BUTTON_HOVER = mix_rgb(p.panel, p.raised, 0.68, math.min(1, panel_alpha + 0.14))
    M.HOVER = mix_rgb(p.panel, p.raised, 0.48, 0.68)
    M.FOCUS = rgb(p.accent, 0.72)

    M.FONT = scaled(13, scale)
    M.FONT_SMALL = scaled(12, scale)
    M.FONT_TITLE = scaled(12, scale)
    M.FONT_CAPTION = scaled(11, scale)

    M.WINDOW_W = scaled(820, scale)
    M.WINDOW_H = scaled(560, scale)
    M.SIDEBAR_W = scaled(58, scale)
    M.TAB_H = scaled(48 * density_mul, scale)
    M.GROUP_PAD = scaled(12, scale)
    M.GROUP_GAP = scaled(12 * density_mul, scale)
    M.GROUP_HEADER_H = scaled(30 * density_mul, scale)
    M.ROW_H = scaled(26 * density_mul, scale)
    M.ITEM_GAP = scaled(8 * density_mul, scale)
    M.LABEL_H = scaled(16 * density_mul, scale)
    M.LABEL_GAP = scaled(8 * density_mul, scale)
    M.CTRL_H = scaled(20 * density_mul, scale)
    M.CTRL_PAD = scaled(4, scale)
    M.CHECK_SIZE = scaled(13, scale)
    M.SLIDER_H = scaled(6, scale)
    M.STACKED_ROW_H = M.LABEL_H + M.LABEL_GAP + M.CTRL_H + M.CTRL_PAD
    M.SLIDER_ROW_H = M.LABEL_H + M.LABEL_GAP + M.SLIDER_H + scaled(10, scale) + M.CTRL_PAD
    M.CORNER = scaled(corner_base, scale)
    M.CORNER_SMALL = math.max(2, scaled(corner_base * 0.60, scale))
end

function M.alpha(col, a)
    return { col[1], col[2], col[3], a }
end

function M.lerp_color(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        a[4] + (b[4] - a[4]) * t,
    }
end

function M.rainbow_at(t)
    local n = #M.RAINBOW
    local x = (t % 1) * n
    local i = math.floor(x) + 1
    local j = (i % n) + 1
    local f = x - math.floor(x)
    return M.lerp_color(M.RAINBOW[i], M.RAINBOW[j], f)
end

function M.apply_global_alpha(a)
    a = clamp(a, 0, 1)
    M.GLOBAL_ALPHA = a
    local keys = {
        "BG", "BG_INNER", "PANEL", "PANEL_ALT", "PANEL_RAISED", "OVERLAY",
        "SHADOW", "SHADOW_DEEP", "GLASS_HIGHLIGHT", "BORDER", "BORDER_SOFT",
        "BORDER_HOT", "SIDEBAR", "SIDEBAR_ACTIVE", "TEXT", "TEXT_DIM",
        "TEXT_ACTIVE", "TEXT_TITLE", "ACCENT", "ACCENT_DIM", "CHECK_OFF",
        "SLIDER_BG", "BUTTON", "BUTTON_HOVER", "HOVER", "FOCUS",
    }
    for _, key in ipairs(keys) do
        local c = M[key]
        if c then
            M[key] = { c[1], c[2], c[3], (c[4] or 1) * a }
        end
    end
end

M.sync()

return M

end)()

-- ── ui/gs_input.lua ──
April._mods["ui.gs_input"] = (function()
-- Mouse / key helpers. Raw cursor only - no windowed offset correction.
--
-- Wheel: Vector docs only expose utility.mouse_scroll() (inject). There is no
-- documented reader. We probe every known path and accumulate into M.wheel;
-- if none work, the menu keeps edge-hover scroll as fallback.

local M = {}

local prev_keys = {}
local prev_lmb = false
local prev_rmb = false
local prev_mmb = false

M.mx = 0
M.my = 0
M.raw_mx = 0
M.raw_my = 0
M.lmb = false
M.rmb = false
M.mmb = false
M.lmb_click = false
M.rmb_click = false
M.mmb_click = false
M.lmb_release = false
M.wheel = 0
M.wheel_source = nil -- "api" | "uis" | "mouse" | nil
M._wheel_accum = 0
M._scroll_ready = false
M._scroll_hook_tries = 0
M._api_readers = nil
M._game_cursor_hidden = false
M._menu_open = false
M.ui_x, M.ui_y, M.ui_w, M.ui_h = 0, 0, 0, 0

function M.set_ui_rect(x, y, w, h)
    M.ui_x, M.ui_y, M.ui_w, M.ui_h = x, y, w, h
end

function M.set_menu_open(open)
    M._menu_open = open == true
    M.set_game_cursor_visible(not M._menu_open)
end

local function pcall_get_service(name)
    local svc = nil
    if not game then return nil end
    pcall(function()
        if game.GetService then svc = game:GetService(name) end
    end)
    if not svc then
        pcall(function()
            if game.get_service then svc = game:get_service(name) end
        end)
    end
    return svc
end

local function on_wheel(dir, source)
    dir = tonumber(dir) or 0
    if dir == 0 then return end
    -- Normalize to ±1 notches (UIS Position.Z is often ±1).
    if dir > 0 then dir = 1 elseif dir < 0 then dir = -1 end
    M._wheel_accum = (M._wheel_accum or 0) + dir
    if source then M.wheel_source = source end
end

local function connect_signal(signal, fn)
    if not signal then return false end
    local connect = signal.Connect or signal.connect
    if type(connect) ~= "function" then return false end
    local ok = pcall(function()
        connect(signal, fn)
    end)
    return ok == true
end

local function collect_api_readers()
    if M._api_readers then return M._api_readers end
    local readers = {}
    local skip = {
        mouse_scroll = true,
        MouseScroll = true,
        mouseScroll = true,
    }
    local function scan(tbl, label)
        if type(tbl) ~= "table" then return end
        for k, v in pairs(tbl) do
            if type(v) == "function" and type(k) == "string" then
                local name = k:lower()
                if (name:find("wheel", 1, true) or name:find("scroll", 1, true))
                    and not skip[k]
                    and not name:find("set", 1, true)
                    and not name:find("mouse_scroll", 1, true)
                then
                    readers[#readers + 1] = { fn = v, label = label .. "." .. k }
                end
            end
        end
    end
    pcall(scan, input, "input")
    pcall(scan, utility, "utility")
    M._api_readers = readers
    return readers
end

local function poll_api_readers()
    local readers = collect_api_readers()
    for i = 1, #readers do
        local ok, a, b = pcall(readers[i].fn)
        if ok then
            local v = tonumber(a)
            if (not v or v == 0) and b ~= nil then v = tonumber(b) end
            if v and v ~= 0 then
                on_wheel(v, "api")
                return
            end
        end
    end
end

local function try_hook_uis()
    local uis = pcall_get_service("UserInputService")
    if not uis then return false end

    local function handle(input_obj, _game_processed)
        if not input_obj then return end
        local type_name = nil
        pcall(function()
            local t = input_obj.UserInputType or input_obj.user_input_type
            if type(t) == "userdata" or type(t) == "table" then
                type_name = tostring(t.Name or t.name or t)
            else
                type_name = tostring(t)
            end
        end)
        if not type_name then return end
        local lower = type_name:lower()
        if not lower:find("mousewheel", 1, true) and lower ~= "mousewheel" then
            return
        end
        local z = 0
        pcall(function()
            local pos = input_obj.Position or input_obj.position
            if pos then z = pos.Z or pos.z or 0 end
        end)
        if z == 0 then
            pcall(function()
                z = input_obj.Delta and (input_obj.Delta.Z or input_obj.Delta.z) or 0
            end)
        end
        if z == 0 then z = 1 end
        on_wheel(z, "uis")
    end

    local hooked = false
    if connect_signal(uis.InputChanged or uis.input_changed, handle) then
        hooked = true
    end
    if connect_signal(uis.InputBegan or uis.input_began, handle) then
        hooked = true
    end
    return hooked
end

local function try_hook_player_mouse()
    local lp = nil
    pcall(function()
        if entity and entity.get_local_player then
            lp = entity.get_local_player()
        end
    end)
    if not lp then
        pcall(function()
            lp = game and (game.LocalPlayer or game.local_player)
        end)
    end
    if not lp then return false end

    local mouse = nil
    pcall(function()
        if lp.GetMouse then mouse = lp:GetMouse()
        elseif lp.get_mouse then mouse = lp:get_mouse()
        else mouse = lp.Mouse or lp.mouse
        end
    end)
    if not mouse then return false end

    local hooked = false
    if connect_signal(mouse.WheelForward or mouse.wheel_forward, function()
        on_wheel(1, "mouse")
    end) then
        hooked = true
    end
    if connect_signal(mouse.WheelBackward or mouse.wheel_backward, function()
        on_wheel(-1, "mouse")
    end) then
        hooked = true
    end
    return hooked
end

local function ensure_scroll_hooks()
    if M._scroll_ready then return end
    -- Retry a few frames - LocalPlayer / services may not exist at load.
    M._scroll_hook_tries = (M._scroll_hook_tries or 0) + 1
    if M._scroll_hook_tries > 120 then
        M._scroll_ready = true
        return
    end

    local ok_uis = try_hook_uis()
    local ok_mouse = try_hook_player_mouse()
    collect_api_readers()
    if ok_uis or ok_mouse or M._scroll_hook_tries >= 30 then
        M._scroll_ready = true
    end
end

function M.set_game_cursor_visible(visible)
    local sg = pcall_get_service("StarterGui")
    if sg then
        pcall(function()
            if sg.SetCore then sg:SetCore("MouseIconEnabled", visible) end
        end)
        pcall(function()
            if sg.set_core then sg:set_core("MouseIconEnabled", visible) end
        end)
    end

    local uis = pcall_get_service("UserInputService")
    if uis then
        pcall(function() uis.MouseIconEnabled = visible end)
        pcall(function() uis.mouse_icon_enabled = visible end)
    end

    pcall(function()
        local lp = game and game.local_player
        if not lp then return end
        local mouse = lp.GetMouse and lp:GetMouse() or (lp.get_mouse and lp:get_mouse())
        if not mouse then return end
        if not visible then
            mouse.Icon = "rbxassetid://0"
            if mouse.icon ~= nil then mouse.icon = "rbxassetid://0" end
        else
            mouse.Icon = ""
        end
    end)

    M._game_cursor_hidden = not visible
end

function M.mouse()
    return M.mx, M.my
end

function M.key_down(vk)
    return input and input.is_key_down and input.is_key_down(vk) or false
end

function M.key_pressed(vk)
    local down = M.key_down(vk)
    local was = prev_keys[vk] == true
    prev_keys[vk] = down
    return down and not was
end

function M.begin_frame()
    ensure_scroll_hooks()

    local amx, amy = 0, 0
    if utility and utility.get_mouse_pos then
        amx, amy = utility.get_mouse_pos()
    elseif input and input.get_mouse_pos then
        amx, amy = input.get_mouse_pos()
    elseif input and input.get_mouse_position then
        amx, amy = input.get_mouse_position()
    end
    amx = tonumber(amx) or 0
    amy = tonumber(amy) or 0
    M.raw_mx, M.raw_my = amx, amy
    M.mx, M.my = amx, amy

    M.lmb = M.key_down(0x01)
    M.rmb = M.key_down(0x02)
    M.mmb = M.key_down(0x04)
    M.lmb_click = M.lmb and not prev_lmb
    M.rmb_click = M.rmb and not prev_rmb
    M.mmb_click = M.mmb and not prev_mmb
    M.lmb_release = (not M.lmb) and prev_lmb
    prev_lmb = M.lmb
    prev_rmb = M.rmb
    prev_mmb = M.mmb

    -- Poll any getter-style APIs each frame, then drain event accumulators.
    poll_api_readers()
    M.wheel = M._wheel_accum or 0
    M._wheel_accum = 0
end

function M.hover(x, y, w, h)
    return M.mx >= x and M.my >= y and M.mx <= x + w and M.my <= y + h
end

function M.clicked(x, y, w, h)
    return M.lmb_click and M.hover(x, y, w, h)
end

function M.draw_cursor()
    if not draw then return end
    local show = true
    pcall(function()
        show = April.require("core.settings").bool("april_ui_show_cursor_dot", true)
    end)
    if not show then return end
    local x, y = M.mx, M.my
    local theme = April.require("ui.gs_theme")
    local anim = April.require("ui.gs_anim")
    local col = theme.ACCENT or { 0.75, 0.15, 0.83, 1 }
    local press = anim.transition("cursor:press", M.lmb, anim.motion_rate(26))
    local inner = 3.5 + press * 1.5
    if draw.circle_filled then
        draw.circle_filled(x, y, inner, col, 14)
    end
    if draw.circle then
        draw.circle(x, y, 5.5 + press, theme.TEXT_ACTIVE, 16, 1.2)
    end
end

return M

end)()

-- ── ui/gs_state.lua ──
April._mods["ui.gs_state"] = (function()
-- Shared settings store for the custom UI (backs menu shim + settings reads).
local M = {}

M.values = {}
M.defaults = {}
M.colors = {}
M.keys = {}
M.callbacks = {}
M.menu_callback = {} -- id -> single fn (menu.set_callback replaces)
M.buttons = {}
M.visible = {} -- id -> bool (parent gating); nil means visible

local function copy_table(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = v
    end
    return out
end

function M.define(id, default)
    if id == nil then return end
    if M.defaults[id] == nil then
        M.defaults[id] = copy_table(default)
    end
    if M.values[id] == nil then
        M.values[id] = copy_table(default)
    end
end

function M.get(id, fallback)
    local v = M.values[id]
    if v == nil then
        return fallback
    end
    return v
end

local function fire_change(id, value)
    local menu_cb = M.menu_callback[id]
    if menu_cb then
        pcall(menu_cb, value)
    end
    local cbs = M.callbacks[id]
    if cbs then
        for i = 1, #cbs do
            pcall(cbs[i], value)
        end
    end
end

function M.set(id, value)
    if id == nil then return end
    M.values[id] = value
    fire_change(id, value)
end

function M.toggle(id)
    local v = not M.get(id, false)
    M.set(id, v)
    return v
end

function M.define_color(id, color)
    if id == nil then return end
    if M.colors[id] == nil then
        M.colors[id] = copy_table(color or { 1, 1, 1, 1 })
    end
end

function M.get_color(id, fallback)
    return M.colors[id] or fallback or { 1, 1, 1, 1 }
end

function M.set_color(id, color)
    if id == nil or type(color) ~= "table" then return end
    M.colors[id] = copy_table(color)
    fire_change(id, color)
end

function M.get_key(id)
    return tonumber(M.keys[id]) or 0
end

function M.set_key(id, vk)
    if id == nil then return end
    M.keys[id] = tonumber(vk) or 0
end

function M.on_change(id, fn)
    if not id or not fn then return end
    M.callbacks[id] = M.callbacks[id] or {}
    M.callbacks[id][#M.callbacks[id] + 1] = fn
end

function M.set_menu_callback(id, fn)
    if id then
        M.menu_callback[id] = fn
    end
end

function M.set_button(id, fn)
    if id then
        M.buttons[id] = fn
    end
end

function M.fire_button(id)
    local fn = M.buttons[id]
    if fn then
        pcall(fn)
        return true
    end
    return false
end

function M.set_visible(id, show)
    if id then
        M.visible[id] = show and true or false
    end
end

function M.is_visible(id)
    local v = M.visible[id]
    if v == nil then return true end
    return v
end

function M.reset(id)
    local d = M.defaults[id]
    if d == nil then return end
    M.set(id, copy_table(d))
end

return M

end)()

-- ── ui/gs_anim.lua ──
April._mods["ui.gs_anim"] = (function()
-- Animated accent bars + per-element theme sync for the custom UI.
local theme = April.require("ui.gs_theme")

local M = {}

M.MODES = { "Static", "Rainbow", "Pulse", "Wave", "Flow" }
M.MODES_UI = { "Default", "Static", "Rainbow", "Pulse", "Wave", "Flow" }

M.TARGET_TITLE = 1
M.TARGET_SECTION = 2
M.TARGET_SLIDER = 3
M.TARGET_SCROLL = 4
M.TARGET_SIDEBAR = 5
M.TARGET_CHECKBOX = 6
M.TARGET_HOVER = 7
M.TARGET_OVERLAY = 8

M.STYLE_TITLE = "april_ui_style_title"
M.STYLE_SECTION = "april_ui_style_section"
M.STYLE_SLIDER = "april_ui_style_slider"
M.STYLE_SCROLL = "april_ui_style_scroll"
M.STYLE_SIDEBAR = "april_ui_style_sidebar"
M.STYLE_CHECKBOX = "april_ui_style_checkbox"
M.STYLE_OVERLAY = "april_ui_style_overlay"

M.COL_TITLE = "april_ui_col_title"
M.COL_SECTION = "april_ui_col_section"
M.COL_SLIDER = "april_ui_col_slider"
M.COL_SCROLL = "april_ui_col_scroll"
M.COL_SIDEBAR = "april_ui_col_sidebar"
M.COL_CHECKBOX = "april_ui_col_checkbox"
M.COL_OVERLAY = "april_ui_col_overlay"

local transitions = {}

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

function M.lerp(a, b, t)
    t = clamp(t or 0, 0, 1)
    return a + (b - a) * t
end

function M.ease_out_cubic(t)
    t = clamp(t or 0, 0, 1)
    local q = 1 - t
    return 1 - q * q * q
end

-- Persistent transition value for hover/active UI elements.
function M.transition(id, target, rate)
    if M.reduce_motion() then
        transitions[id] = { value = target and 1 or 0, at = M.now() }
        return target and 1 or 0
    end
    local now = M.now()
    local entry = transitions[id]
    if not entry then
        entry = { value = target and 1 or 0, at = now }
        transitions[id] = entry
        return entry.value
    end
    local dt = math.min(math.max(now - (entry.at or now), 0), 0.1)
    entry.at = now
    local goal = target and 1 or 0
    local speed = rate or 12
    local alpha = 1 - math.exp(-speed * dt)
    entry.value = M.lerp(entry.value or 0, goal, alpha)
    return entry.value
end

-- Numeric exponential smoothing for scroll positions and other continuous values.
function M.smooth(id, target, rate)
    if M.reduce_motion() then
        transitions[id] = { value = target, at = M.now() }
        return target
    end
    local now = M.now()
    local entry = transitions[id]
    if not entry then
        entry = { value = target, at = now }
        transitions[id] = entry
        return target
    end
    local dt = math.min(math.max(now - (entry.at or now), 0), 0.1)
    entry.at = now
    local alpha = 1 - math.exp(-(rate or 14) * dt)
    entry.value = M.lerp(entry.value or target, target, alpha)
    return entry.value
end

function M.mix(a, b, t)
    return theme.lerp_color(a, b, clamp(t or 0, 0, 1))
end

local function settings()
    return April.require("core.settings")
end

local function hsv_to_rgb(h, s, v)
    h = (h % 1) * 6
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p end
    if i == 1 then return q, v, p end
    if i == 2 then return p, v, t end
    if i == 3 then return p, q, v end
    if i == 4 then return t, p, v end
    return v, p, q
end

function M.now()
    if utility and utility.get_time then
        return utility.get_time()
    end
    return 0
end

function M.speed()
    local n = settings().num("april_ui_anim_speed", 40)
    return clamp(n, 1, 100) * 0.028
end

function M.reduce_motion()
    return settings().bool("april_ui_reduce_motion", false)
end

function M.motion_profile()
    return clamp(math.floor(settings().num("april_ui_motion_profile", 1) + 0.5), 0, 2)
end

function M.motion_rate(base)
    if M.reduce_motion() then return 1000 end
    local mul = ({ 0.72, 1.0, 1.28 })[M.motion_profile() + 1]
    return (base or 12) * mul
end

function M.phase()
    return M.now() * M.speed()
end

function M.colors_enabled()
    return settings().bool("april_ui_custom_colors", false)
end

function M.anim_enabled()
    return settings().bool("april_ui_custom_anim", false)
end

function M.global_mode()
    local n = tonumber(settings().get("april_ui_accent_anim", 1)) or 1
    return clamp(math.floor(n + 0.5), 0, #M.MODES - 1)
end

function M.resolve_mode(style_id)
    if not M.anim_enabled() then
        return 0
    end
    local pick = settings().combo_index(style_id, M.MODES_UI, 0)
    if pick == 0 then
        return M.global_mode()
    end
    return pick - 1
end

function M.base_accent()
    if not M.colors_enabled() then
        return theme.PRESET_ACCENT or { 0.78, 0.20, 0.92, 1 }
    end
    return settings().color("april_ui_accent", theme.PRESET_ACCENT or { 0.78, 0.20, 0.92, 1 })
end

function M.color_override_enabled(target_index)
    if not M.colors_enabled() then
        return false
    end
    return settings().multi("april_ui_color_overrides", target_index, false)
end

function M.element_color(target_index, color_id)
    if M.color_override_enabled(target_index) then
        return settings().color(color_id, M.base_accent())
    end
    return M.base_accent()
end

function M.anim_target_enabled(target_index)
    if not M.anim_enabled() then
        return false
    end
    return settings().multi("april_ui_anim_targets", target_index, true)
end

function M.sync_theme()
    theme.sync()
    local col = M.base_accent()
    theme.ACCENT = { col[1], col[2], col[3], col[4] or 1 }
    local pulse = 0.62 + 0.38 * math.sin(M.phase() * 2.2)
    theme.ACCENT_DIM = {
        col[1] * pulse * 0.55,
        col[2] * pulse * 0.55,
        col[3] * pulse * 0.55,
        1,
    }
end

function M.accent_at_mode(mode, base, t, alpha)
    alpha = alpha or 1
    local phase = M.phase()
    t = (t or 0) % 1

    if mode == 0 then
        return { base[1], base[2], base[3], alpha }
    end
    if mode == 1 then
        local hue = (t + phase * 0.14) % 1
        local r, g, b = hsv_to_rgb(hue, 1, 1)
        return { r, g, b, alpha }
    end
    if mode == 2 then
        local p = 0.5 + 0.5 * math.sin(phase * 2.4 + t * 6.28318)
        return { base[1] * p, base[2] * p, base[3] * p, alpha }
    end
    if mode == 3 then
        local w = 0.45 + 0.55 * math.sin((t * 10 - phase * 2.8) * 6.28318)
        return {
            base[1] * (0.55 + 0.45 * w),
            base[2] * (0.55 + 0.45 * w),
            base[3] * (0.55 + 0.45 * w),
            alpha,
        }
    end
    local sweep_h = (t + phase * 0.18) % 1
    local sr, sg, sb = hsv_to_rgb(sweep_h, 1, 1)
    local mix = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 6.28318 + phase * 1.6))
    local c = theme.lerp_color(base, { sr, sg, sb, 1 }, mix)
    return { c[1], c[2], c[3], alpha }
end

function M.accent_at(t, alpha)
    return M.accent_at_mode(M.global_mode(), M.base_accent(), t, alpha)
end

local function widget_clip()
    local clip = nil
    pcall(function()
        clip = April.require("ui.gs_widgets").clip
    end)
    return clip
end

function M.rect(x, y, w, h, col, filled)
    if not draw then return end
    local c = widget_clip()
    if c then
        local x2, y2 = x + w, y + h
        local cx, cy = c.x, c.y
        local cx2, cy2 = c.x + c.w, c.y + c.h
        if x2 <= cx or y2 <= cy or x >= cx2 or y >= cy2 then return end
        if x < cx then w = w - (cx - x); x = cx end
        if y < cy then h = h - (cy - y); y = cy end
        if x + w > cx2 then w = cx2 - x end
        if y + h > cy2 then h = cy2 - y end
        if w <= 0 or h <= 0 then return end
    end
    if filled then
        draw.rect_filled(x, y, w, h, col, 0)
    else
        draw.rect(x, y, w, h, col, 0, 1)
    end
end

function M.draw_bar_h(x, y, w, h, scroll_t, style_id, color_id, color_target)
    if w <= 0 or h <= 0 then return end
    scroll_t = scroll_t or 0
    local base = M.element_color(color_target, color_id)
    local alpha = (base[4] or 1) * (theme.GLOBAL_ALPHA or 1)
    local mode = M.resolve_mode(style_id)
    if mode == 0 then
        M.rect(x, y, w, h, theme.alpha(base, alpha), true)
        return
    end
    local segs = math.min(64, math.max(12, math.floor(w / 8)))
    local sw = w / segs
    for i = 0, segs - 1 do
        local t = (i / segs + scroll_t) % 1
        M.rect(x + i * sw, y, sw + 0.75, h, M.accent_at_mode(mode, base, t, alpha), true)
    end
end

function M.draw_bar_v(x, y, w, h, scroll_t, style_id, color_id, color_target)
    if w <= 0 or h <= 0 then return end
    scroll_t = scroll_t or 0
    local base = M.element_color(color_target, color_id)
    local alpha = (base[4] or 1) * (theme.GLOBAL_ALPHA or 1)
    local mode = M.resolve_mode(style_id)
    if mode == 0 then
        M.rect(x, y, w, h, theme.alpha(base, alpha), true)
        return
    end
    local segs = math.min(48, math.max(8, math.floor(h / 8)))
    local sh = h / segs
    for i = 0, segs - 1 do
        local t = (i / segs + scroll_t) % 1
        M.rect(x, y + i * sh, w, sh + 0.75, M.accent_at_mode(mode, base, t, alpha), true)
    end
end

function M.draw_flat(x, y, w, h, style_id, color_id, color_target)
    local base = M.element_color(color_target, color_id)
    M.rect(x, y, w, h, theme.alpha(base, (base[4] or 1) * (theme.GLOBAL_ALPHA or 1)), true)
end

function M.section_scroll()
    return M.phase() * 0.09
end

function M.draw_section_top(x, y, w)
    if not M.anim_target_enabled(M.TARGET_SECTION) then
        M.draw_flat(x, y, w, 2, M.STYLE_SECTION, M.COL_SECTION, M.TARGET_SECTION)
        return
    end
    M.draw_bar_h(x, y, w, 2, M.section_scroll(), M.STYLE_SECTION, M.COL_SECTION, M.TARGET_SECTION)
end

function M.draw_title_bar(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_TITLE) then
        M.draw_flat(x, y, w, h, M.STYLE_TITLE, M.COL_TITLE, M.TARGET_TITLE)
        return
    end
    M.draw_bar_h(x, y, w, h, M.phase() * 0.12, M.STYLE_TITLE, M.COL_TITLE, M.TARGET_TITLE)
end

function M.draw_slider_fill(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SLIDER) then
        M.draw_flat(x, y, w, h, M.STYLE_SLIDER, M.COL_SLIDER, M.TARGET_SLIDER)
        return
    end
    M.draw_bar_h(x, y, w, h, M.phase() * 0.06, M.STYLE_SLIDER, M.COL_SLIDER, M.TARGET_SLIDER)
end

function M.draw_scroll_thumb(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SCROLL) then
        M.draw_flat(x, y, w, h, M.STYLE_SCROLL, M.COL_SCROLL, M.TARGET_SCROLL)
        return
    end
    M.draw_bar_v(x, y, w, h, M.phase() * 0.05, M.STYLE_SCROLL, M.COL_SCROLL, M.TARGET_SCROLL)
end

function M.draw_tab_indicator(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SIDEBAR) then
        M.draw_flat(x, y, w, h, M.STYLE_SIDEBAR, M.COL_SIDEBAR, M.TARGET_SIDEBAR)
        return
    end
    M.draw_bar_v(x, y, w, h, M.phase() * 0.07, M.STYLE_SIDEBAR, M.COL_SIDEBAR, M.TARGET_SIDEBAR)
end

function M.tab_icon_color()
    local base = M.element_color(M.TARGET_SIDEBAR, M.COL_SIDEBAR)
    if not M.anim_target_enabled(M.TARGET_SIDEBAR) then
        return base
    end
    return M.accent_at_mode(M.resolve_mode(M.STYLE_SIDEBAR), base, M.phase() * 0.03,
        (base[4] or 1) * (theme.GLOBAL_ALPHA or 1))
end

function M.hover_tint(base, hot)
    if not hot then return base end
    if not M.anim_target_enabled(M.TARGET_HOVER) then
        return base
    end
    local pulse = 0.88 + 0.12 * math.sin(M.phase() * 6)
    return {
        base[1] * pulse,
        base[2] * pulse,
        base[3] * pulse,
        base[4] or 1,
    }
end

function M.interactive_fill(id, base, hover, active)
    local h = M.transition("hover:" .. tostring(id), hover, M.motion_rate(15))
    local a = M.transition("active:" .. tostring(id), active, M.motion_rate(20))
    local col = M.mix(base, hover and theme.BUTTON_HOVER or theme.HOVER, M.ease_out_cubic(h))
    return M.mix(col, M.element_color(M.TARGET_CHECKBOX, M.COL_CHECKBOX), a * 0.16)
end

function M.checkbox_fill()
    local base = M.element_color(M.TARGET_CHECKBOX, M.COL_CHECKBOX)
    if not M.anim_target_enabled(M.TARGET_CHECKBOX) then
        return base
    end
    return M.accent_at_mode(M.resolve_mode(M.STYLE_CHECKBOX), base, M.phase() * 0.04,
        (base[4] or 1) * (theme.GLOBAL_ALPHA or 1))
end

function M.menu_fade()
    if M.reduce_motion() then return 1 end
    if not settings().bool("april_ui_menu_fade", false) then return 1 end
    return clamp(0.93 + math.sin(M.now() * 1.5) * 0.035, 0.88, 0.98)
end

function M.panel_bg()
    if not M.colors_enabled() then
        return theme.BG
    end
    local dim = settings().num("april_ui_bg_dim", 0)
    dim = clamp(dim, 0, 40) * 0.01
    local bg = theme.BG
    return {
        bg[1] - dim * 0.04,
        bg[2] - dim * 0.04,
        bg[3] - dim * 0.04,
        bg[4] or 1,
    }
end

function M.menu_open_progress(want_open)
    return M.transition("menu:open", want_open, M.motion_rate(15))
end

function M.tab_progress(tab_id)
    return M.transition("tab-content:" .. tostring(tab_id), true, M.motion_rate(18))
end

function M.clear_tab_progress(tab_id)
    transitions["tab-content:" .. tostring(tab_id)] = { value = 0, at = M.now() }
end

return M

end)()

-- ── game/esp_maps.lua ──
April._mods["game.esp_maps"] = (function()
local M = {}

M.NODE_MAP = {
    ["Stone_Node"] = "april_stone_node",
    ["Metal_Node"] = "april_metal_node",
    ["Phosphate_Node"] = "april_phosphate_node",
}

M.NODE_LABELS = {
    ["Stone_Node"] = "Stone Node",
    ["Metal_Node"] = "Metal Node",
    ["Phosphate_Node"] = "Phosphate Node",
}

M.NODE_FOLDERS = { "vegetation", "nodes" }

M.PLANT_MAP = {
    ["Corn Plant"] = "april_corn_plant",
    ["Tomato Plant"] = "april_tomato_plant",
    ["Pumpkin Plant"] = "april_pumpkin_plant",
    ["Lemon Plant"] = "april_lemon_plant",
    ["Raspberry Plant"] = "april_raspberry_plant",
    ["Blueberry Plant"] = "april_blueberry_plant",
    ["Wool Plant"] = "april_wool_plant",
    ["Hemp Plant"] = "april_hemp_plant",
    ["Hemp"] = "april_hemp_plant",
}

M.PLANT_LABELS = {
    ["Corn Plant"] = "Corn Plant",
    ["Tomato Plant"] = "Tomato Plant",
    ["Pumpkin Plant"] = "Pumpkin Plant",
    ["Lemon Plant"] = "Lemon Plant",
    ["Raspberry Plant"] = "Raspberry Plant",
    ["Blueberry Plant"] = "Blueberry Plant",
    ["Wool Plant"] = "Wool Plant",
    ["Hemp Plant"] = "Hemp Plant",
    ["Hemp"] = "Hemp",
}

M.PLANT_FOLDERS = { "plants", "vegetation" }

M.ANIMAL_MAP = {
    ["PREFAB_ANIMAL_DEER"] = "april_deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "april_boar",
    ["PREFAB_ANIMAL_WOLF"] = "april_wolf",
    ["Deer"] = "april_deer",
    ["Wild Boar"] = "april_boar",
    ["WildBoar"] = "april_boar",
    ["Boar"] = "april_boar",
    ["Wolf"] = "april_wolf",
}

M.ANIMAL_LABELS = {
    ["PREFAB_ANIMAL_DEER"] = "Deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "Wild Boar",
    ["PREFAB_ANIMAL_WOLF"] = "Wolf",
    ["Deer"] = "Deer",
    ["Wild Boar"] = "Wild Boar",
    ["WildBoar"] = "Wild Boar",
    ["Boar"] = "Boar",
    ["Wolf"] = "Wolf",
}

M.ANIMAL_FOLDERS = { "animals" }

M.WORLD_TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_lemon_plant", label = "Lemon Plant", color = { 1, 0.95, 0.2, 1 } },
    { id = "april_raspberry_plant", label = "Raspberry Plant", color = { 0.9, 0.2, 0.4, 1 } },
    { id = "april_blueberry_plant", label = "Blueberry Plant", color = { 0.3, 0.4, 0.9, 1 } },
    { id = "april_wool_plant", label = "Wool Plant", color = { 0.85, 0.85, 0.9, 1 } },
    { id = "april_hemp_plant", label = "Hemp Plant", color = { 0.3, 0.7, 0.25, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}

M.LOOT_MAP = {
    ["Wooden Crate"] = "april_wooden_crate",
    ["Locked Wooden Crate"] = "april_wooden_crate",
    ["Locked Metal Crate"] = "april_metal_crate",
    ["Locked Steel Crate"] = "april_steel_crate",
    ["Food Crate"] = "april_food_crate",
    ["Timed Crate"] = "april_timed_crate",
    ["Care Package"] = "april_care_package",
    ["BTR Crate"] = "april_btr_crate",
    ["Body Bag"] = "april_body_bag",
    ["Sleeper"] = "april_sleeper",
    ["Trash Can"] = "april_trash_can",
    ["Oil Barrel"] = "april_oil_barrel",
    ["Small Egg"] = "april_small_egg",
    ["Medium Egg"] = "april_medium_egg",
    ["Large Egg"] = "april_large_egg",
    ["Small Gift"] = "april_small_egg",
    ["Medium Gift"] = "april_medium_egg",
    ["Large Gift"] = "april_large_egg",
    ["Wooden Boat"] = "april_wooden_boat",
    ["Military Boat"] = "april_military_boat",
    ["Salvaged Flycopter"] = "april_flycopter",
}

M.LOOT_TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_btr_crate", label = "BTR Crate", color = { 0.8, 0.15, 0.15, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
    { id = "april_small_egg", label = "Small Egg / Gift", color = { 0.95, 0.85, 0.5, 1 } },
    { id = "april_medium_egg", label = "Medium Egg / Gift", color = { 0.9, 0.7, 0.4, 1 } },
    { id = "april_large_egg", label = "Large Egg / Gift", color = { 0.85, 0.55, 0.3, 1 } },
    { id = "april_wooden_boat", label = "Wooden Boat", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_military_boat", label = "Military Boat", color = { 0.35, 0.45, 0.35, 1 } },
    { id = "april_flycopter", label = "Salvaged Flycopter", color = { 0.6, 0.6, 0.65, 1 } },
}

M.LOOT_SCAN_FOLDERS = { "loners", "vegetation", "military", "events", "monuments" }

M.BASE_MAP = {
    ["Base Cabinet"] = "april_base_cabinet",
    ["Storage Cabinet"] = "april_storage_cabinet",
    ["Cabinet"] = "april_base_cabinet",
    ["Large Cabinet"] = "april_storage_cabinet",
    ["Small Storage Box"] = "april_small_box",
    ["Large Storage Box"] = "april_large_box",
    ["Small Box"] = "april_small_box",
    ["Large Box"] = "april_large_box",
    ["Wooden Door"] = "april_wooden_door",
    ["Wooden Double Door"] = "april_wooden_double_door",
    ["Salvaged Metal Door"] = "april_salvaged_door",
    ["Metal Door"] = "april_metal_door",
    ["Metal Double Door"] = "april_metal_double_door",
    ["Steel Door"] = "april_steel_door",
    ["Steel Double Door"] = "april_steel_double_door",
    ["Trap Door"] = "april_trap_door",
    ["Triangle Trap Door"] = "april_triangle_trap_door",
    ["Garage Door"] = "april_garage_door",
    ["Sleeping Bag"] = "april_sleeping_bag",
    ["Shotgun Turret"] = "april_shotgun_turret",
    ["Auto Turret"] = "april_auto_turret",
    ["Small Battery"] = "april_small_battery",
    ["Medium Battery"] = "april_medium_battery",
    ["Large Battery"] = "april_large_battery",
    ["Solar Panel"] = "april_solar_panel",
    ["Windmill"] = "april_windmill",
}

M.BASE_SKIP_AREAS = {
    Loners = true,
    VMs = true,
    BTRMonumentPaths = true,
    Benches = true,
    Wires = true,
    Ragdolls = true,
    Fire = true,
}

M.BASE_TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_small_box", label = "Small Storage Box", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_large_box", label = "Large Storage Box", color = { 0.45, 0.3, 0.12, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", color = { 1, 0.2, 0.2, 1 }, ring_id = "april_auto_turret_ring" },
    { id = "april_shotgun_turret", label = "Shotgun Turret", color = { 1, 0.35, 0.2, 1 }, ring_id = "april_shotgun_turret_ring" },
    { id = "april_wooden_door", label = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_wooden_double_door", label = "Wooden Double Door", color = { 0.55, 0.32, 0.12, 1 } },
    { id = "april_metal_door", label = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_salvaged_door", label = "Salvaged Metal Door", color = { 0.55, 0.52, 0.48, 1 } },
    { id = "april_metal_double_door", label = "Metal Double Door", color = { 0.52, 0.52, 0.58, 1 } },
    { id = "april_steel_door", label = "Steel Door", color = { 0.65, 0.65, 0.72, 1 } },
    { id = "april_steel_double_door", label = "Steel Double Door", color = { 0.62, 0.62, 0.7, 1 } },
    { id = "april_garage_door", label = "Garage Door", color = { 0.4, 0.4, 0.42, 1 } },
    { id = "april_trap_door", label = "Trap Door", color = { 0.48, 0.38, 0.22, 1 } },
    { id = "april_triangle_trap_door", label = "Triangle Trap Door", color = { 0.46, 0.36, 0.2, 1 } },
    { id = "april_small_battery", label = "Small Battery", color = { 0.2, 0.75, 0.35, 1 } },
    { id = "april_medium_battery", label = "Medium Battery", color = { 0.15, 0.65, 0.3, 1 } },
    { id = "april_large_battery", label = "Large Battery", color = { 0.1, 0.55, 0.25, 1 } },
    { id = "april_solar_panel", label = "Solar Panel", color = { 0.2, 0.4, 0.85, 1 } },
    { id = "april_windmill", label = "Windmill", color = { 0.75, 0.85, 0.95, 1 } },
}

function M.toggle_color(list, toggle_id, fallback)
    for _, t in ipairs(list or {}) do
        if t.id == toggle_id then
            return t.color
        end
    end
    return fallback or { 1, 1, 1, 1 }
end

function M.turret_ring_toggle(toggle_id)
    for _, t in ipairs(M.BASE_TOGGLES) do
        if t.id == toggle_id then
            return t.ring_id
        end
    end
    return nil
end

return M

end)()

-- ── ui/tooltips.lua ──
April._mods["ui.tooltips"] = (function()
-- Hover tooltip copy keyed by setting id (what it does, not how).
local esp_maps = April.require("game.esp_maps")

local M = {}

M.ALLOW_TYPES = {
    checkbox = true,
    keybind = true,
    aim_key = true,
    hotkey = true,
    button = true,
    multi = true,
}

-- Visual / tuning controls — no hover tips.
M.SKIP_IDS = {
    april_aim_draw_fov = true,
    april_aim_fov_style = true,
    april_aim_target_line = true,
    april_silent_draw_fov = true,
    april_silent_fov_style = true,
    april_silent_target_line = true,
    april_silent_tp_ray_vis = true,
    april_silent_tp_method = true,
    april_silent_manip_status = true,
    april_silent_manip_peek_vis = true,
    april_desync_visualizer = true,
    april_keybinds_active_only = true,
    april_keybinds_show_unbound = true,
    april_keybinds_show_mode = true,
    april_wp_dist = true,
    april_wp_beacon = true,
    april_wp_draw = true,
    april_ui_show_cursor_dot = true,
    april_ui_custom_colors = true,
    april_ui_custom_anim = true,
    april_ui_reduce_motion = true,
    april_ui_menu_fade = true,
    april_ui_per_element = true,
    april_fakeduck_spam = true,
}

M.BY_ID = {
    -- Aimbot
    april_aimbot = "Smooth camera aim assist on your current target.",
    april_aim_key = "Hold or toggle this key to activate aimbot.",
    april_rage_enabled = "Aggressive no-FOV aim with autofire on valid targets.",
    april_silent_aim = "Redirects shots to your locked target without moving the camera.",
    april_rage_autofire = "Automatically clicks when ragebot has a valid shot.",

    -- Bullet
    april_bullet_enabled = "Turns on advanced bullet routing for silent aim.",
    april_silent_hitscan = "Registers hits instantly on your locked target. Server may reject invalid shots.",
    april_silent_bullet_tp = "Scans the head for the closest visible point to your crosshair (manip-style math), spawns the ray on the target, and shoots through that point. Cycles offsets every frame.",
    april_silent_bullet_manip = "Finds a shootable angle around cover. Server may reject invalid shots.",
    april_silent_manip_extend = "Searches farther from your body when no close peek is found.",
    april_bullet_body_peek = "Moves you to the peek with desync for server-valid shots. Can cause invalids or kicks.",

    -- Aimbot options
    april_aim_targets = "Choose whether aimbot targets players, NPCs, or both.",
    april_aim_filters = "Filters which targets aimbot will consider.",
    april_aim_options = "Extra aimbot behavior options.",

    -- Ragebot options
    april_rage_targets = "Choose whether ragebot targets players, NPCs, or both.",
    april_rage_filters = "Filters which targets ragebot will consider.",
    april_rage_options = "Extra ragebot behavior options.",

    -- Silent aim options
    april_silent_targets = "Choose whether silent aim targets players, NPCs, or both.",
    april_silent_filters = "Filters which targets silent aim will consider.",
    april_silent_options = "Extra silent aim behavior options.",

    -- Visuals
    april_player_enabled = "Shows boxes and info on other players.",
    april_ui_player_elements = "Choose which info to show on player ESP.",
    april_player_esp_filters = "Filter which players appear on ESP.",
    april_player_esp_flags = "Show status flags on player ESP.",
    april_target_overlay = "Shows your target's held weapon and gear loadout.",
    april_crosshair_enabled = "Draws a custom crosshair on screen.",
    april_crosshair_follow = "Moves the crosshair toward your active combat target.",
    april_ui_crosshair_motion = "Adds spin or pulse animation to the crosshair.",
    april_ui_crosshair_options = "Extra crosshair drawing options.",

    -- World masters
    april_world_enabled = "Highlights harvestable resources and animals in the world.",
    april_loot_enabled = "Highlights crates, bags, and other loot in the world.",
    april_base_enabled = "Highlights base parts like doors, turrets, and storage.",
    april_npc_enabled = "Highlights NPC soldiers and bosses.",
    april_ui_npc_types = "Choose which NPC types appear on ESP.",
    april_ui_npc_elements = "Choose which info to show on NPC ESP.",

    april_world_boxes = "Draws 3D boxes around visible resources.",
    april_world_show_name = "Shows names on resource ESP.",
    april_world_show_distance = "Shows distance on resource ESP.",
    april_loot_boxes = "Draws 3D boxes around visible loot.",
    april_loot_show_name = "Shows names on loot ESP.",
    april_loot_show_distance = "Shows distance on loot ESP.",
    april_base_boxes = "Draws 3D boxes around visible base parts.",
    april_base_show_name = "Shows names on base ESP.",
    april_base_show_distance = "Shows distance on base ESP.",
    april_npc_soldiers = "Shows soldier NPCs on ESP.",
    april_npc_bosses = "Shows boss NPCs on ESP.",

    -- Gun mods
    april_gunmods_enabled = "Applies weapon stat changes globally to your held gun.",
    april_gm_recoil = "Lowers recoil. Works on any gun — no attachment required.",
    april_gm_spread = "Tightens aim and hip spread. Sights (Holo, ACOG, scopes) also add spread mults that this stacks with.",
    april_gm_sway = "Removes scope sway while aiming. Only affects guns with a scope or sight equipped.",
    april_gm_fire_rate = "Boosts RPM via FireRateMult. Usually needs Muzzle Boost on the gun — without it the game often ignores fire-rate mults.",
    april_gm_speed = "Boosts bullet speed via SpeedMult on live weapon tables. Not an attachment stat — Swift Heavy Ammo also adds speed; equip a gun before enabling.",
    april_gm_range = "Extends max range via RangeMult. Silencer and Compensator reduce range; this patches whatever range mults exist on your gun.",
    april_gm_double_tap = "Forces a 2-round burst on your held gun. Patches ToolInfo directly — does not use GC mults.",

    -- Movement
    april_noclip_enabled = "Lets you fly through the world.",
    april_slowfall_enabled = "Slows your fall speed.",
    april_desync_enabled = "Desyncs your network position from where you appear.",
    april_antiaim_enabled = "Spoofs your look direction to other players.",
    april_fakeduck_enabled = "Rapidly ducks your hitbox height.",
    april_fling_enabled = "Launches nearby entities upward.",

    -- Utility
    april_farm_helper = "Automatically farms nearby nodes and plants.",
    april_farm_silent = "Uses silent aim while farm helper is active.",
    april_anti_afk = "Prevents idle kick by simulating activity.",
    april_mod_checker_enabled = "Alerts you when staff or mods join the server.",
    april_keybinds_enabled = "Shows an on-screen list of your keybinds.",

    -- Radar
    april_map_enabled = "Shows a draggable tactical minimap overlay.",
    april_ui_radar_layers = "Choose what appears on the tactical map.",
    april_waypoints_enabled = "Place and navigate to saved world waypoints.",

    -- Config / actions
    april_ui_menu_key = "Key used to open and close this menu.",
    april_cfg_autoload = "Loads your saved profile automatically on inject.",
    april_aim_whitelist_clear = "Clears the aim whitelist player list.",
    april_rage_whitelist_clear = "Clears the ragebot whitelist player list.",
    april_silent_whitelist_clear = "Clears the silent aim whitelist player list.",
    april_map_reset_position = "Moves the tactical map back to its default spot.",
    april_wp_set = "Saves your current position to the active waypoint slot.",
    april_wp_clear = "Clears the active waypoint slot.",
    april_wp_clear_all = "Clears every saved waypoint.",
    april_cfg_save = "Saves your settings to the active config slot.",
    april_cfg_load = "Loads settings from the active config slot.",
    april_cfg_delete = "Deletes the active config slot.",
    april_reload_modules = "Reloads game module offsets and caches.",
}

local function register_esp_toggles(list, scope)
    for _, t in ipairs(list or {}) do
        if t.id and not M.BY_ID[t.id] then
            M.BY_ID[t.id] = "Highlights " .. t.label .. " on " .. scope .. "."
        end
        if t.ring_id and not M.BY_ID[t.ring_id] then
            M.BY_ID[t.ring_id] = "Shows a range ring around nearby " .. t.label .. "."
        end
    end
end

register_esp_toggles(esp_maps.WORLD_TOGGLES, "resource ESP")
register_esp_toggles(esp_maps.LOOT_TOGGLES, "loot ESP")
register_esp_toggles(esp_maps.BASE_TOGGLES, "base ESP")

local function clean_label(label)
    label = tostring(label or "")
    label = label:gsub("^Enable ", "")
    return label
end

local function fallback_tip(item)
    local label = clean_label(item.label)
    if label == "" then return nil end

    if item.type == "button" then
        return label .. "."
    end
    if item.type == "aim_key" or item.type == "hotkey" then
        return "Keybind for " .. label:lower() .. "."
    end
    if item.type == "keybind" then
        return "Toggle " .. label:lower() .. "."
    end
    if item.type == "checkbox" or item.type == "multi" then
        return "Enables " .. label:lower() .. "."
    end
    return nil
end

function M.should_tooltip(item)
    if not item or not item.id then return false end
    if not M.ALLOW_TYPES[item.type] then return false end
    if M.SKIP_IDS[item.id] then return false end
    return true
end

function M.for_item(item)
    if not M.should_tooltip(item) then return nil end
    if item.tip and item.tip ~= "" then
        return item.tip
    end
    if item.id and M.BY_ID[item.id] then
        return M.BY_ID[item.id]
    end
    return fallback_tip(item)
end

return M

end)()

-- ── ui/menu_shim.lua ──
April._mods["ui.menu_shim"] = (function()
--[[
  Replaces Vector's menu.* API with a store backed by ui.gs_state.
  Feature register_menu() code keeps working; nothing is added to the Vector UI.
]]

local state = April.require("ui.gs_state")

local M = {}
M.installed = false
M._real = nil

local function as_bool_default(default)
    return default == true
end

local shim = {}

function shim.add_tab() end
function shim.add_group() end
function shim.add_separator() end
function shim.add_label() end

function shim.add_checkbox(_T, _G, id, _label, default, opts)
    state.define(id, as_bool_default(default))
    opts = opts or {}
    if opts.colorpicker then
        state.define_color(id, opts.colorpicker)
    end
    if opts.key and opts.key ~= 0 then
        if state.get_key(id) == 0 then
            state.set_key(id, opts.key)
        end
    end
end

function shim.add_slider_int(_T, _G, id, _label, _min, _max, default, _opts)
    -- Some call sites pass format string as 8th arg then opts
    state.define(id, tonumber(default) or 0)
end

function shim.add_slider_float(_T, _G, id, _label, _min, _max, default, _fmt, _opts)
    state.define(id, tonumber(default) or 0)
end

function shim.add_combo(_T, _G, id, _label, _options, default, _opts)
    state.define(id, tonumber(default) or 0)
end

function shim.add_multicombo(_T, _G, id, _label, options, defaults, _opts)
    local def = {}
    local n = type(options) == "table" and #options or 0
    for i = 1, n do
        def[i] = defaults and defaults[i] == true
    end
    state.define(id, def)
end

function shim.add_colorpicker(_T, _G, id, _label, default, _opts)
    state.define_color(id, default or { 1, 1, 1, 1 })
    -- Also mirror as value for config dumps that read get()
    state.define(id, default or { 1, 1, 1, 1 })
end

function shim.add_input(_T, _G, id, _label, default)
    state.define(id, default or "")
end

function shim.add_button(_T, _G, id, _label, callback)
    if type(callback) == "function" then
        state.set_button(id, callback)
    end
end

function shim.add_hotkey(_T, _G, id, _label, default_vk, opts)
    opts = opts or {}
    if default_vk and default_vk ~= 0 and state.get_key(id) == 0 then
        state.set_key(id, default_vk)
    end
    local mode_id = id .. "_mode"
    state.define(mode_id, opts.default_mode or opts.mode_default or 1)
end

function shim.get(id)
    return state.get(id, nil)
end

function shim.set(id, value)
    state.set(id, value)
end

function shim.get_color(id)
    return state.get_color(id, nil)
end

function shim.set_color(id, color)
    state.set_color(id, color)
end

function shim.get_key(id)
    return state.get_key(id)
end

function shim.set_key(id, vk)
    state.set_key(id, vk)
end

function shim.set_callback(id, fn)
    state.set_menu_callback(id, fn)
end

function shim.set_visible(id, show)
    state.set_visible(id, show)
end

-- PascalCase / camelCase aliases (Vector registers all three styles)
local aliases = {
    AddTab = "add_tab",
    AddGroup = "add_group",
    AddSeparator = "add_separator",
    AddLabel = "add_label",
    AddCheckbox = "add_checkbox",
    AddSliderInt = "add_slider_int",
    AddSliderFloat = "add_slider_float",
    AddCombo = "add_combo",
    AddMulticombo = "add_multicombo",
    AddColorpicker = "add_colorpicker",
    AddInput = "add_input",
    AddButton = "add_button",
    AddHotkey = "add_hotkey",
    Get = "get",
    Set = "set",
    GetColor = "get_color",
    SetColor = "set_color",
    GetKey = "get_key",
    SetKey = "set_key",
    SetCallback = "set_callback",
    SetVisible = "set_visible",
    addTab = "add_tab",
    addGroup = "add_group",
    addCheckbox = "add_checkbox",
    addSliderInt = "add_slider_int",
    addSliderFloat = "add_slider_float",
    addCombo = "add_combo",
    addMulticombo = "add_multicombo",
    addColorpicker = "add_colorpicker",
    addInput = "add_input",
    addButton = "add_button",
    addHotkey = "add_hotkey",
    getColor = "get_color",
    setColor = "set_color",
    getKey = "get_key",
    setKey = "set_key",
    setCallback = "set_callback",
    setVisible = "set_visible",
}

for alias, real in pairs(aliases) do
    shim[alias] = shim[real]
end

function M.install()
    if M.installed then return true end
    -- Vector sandbox has no rawget; keep a reference then replace the global.
    M._real = menu
    April._vector_menu = M._real
    April.custom_ui = true
    menu = shim
    M.installed = true
    return true
end

function M.api()
    return shim
end

return M

end)()

-- ── ui/combat_labels.lua ──
April._mods["ui.combat_labels"] = (function()
-- Label lists shared by the custom UI catalog (no feature / menu deps).
local M = {}

M.TP_METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

return M

end)()

-- ── ui/gs_icons.lua ──
April._mods["ui.gs_icons"] = (function()
-- Vector-drawn sidebar icons (sharper Gamesense-style glyphs).
local theme = April.require("ui.gs_theme")

local M = {}

local function line(x1, y1, x2, y2, col, t)
    if draw and draw.line then
        draw.line(x1, y1, x2, y2, col, t or 1.6)
    end
end

local function circle(x, y, r, col, filled, segs)
    if not draw then return end
    segs = segs or 20
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, segs)
    elseif draw.circle then
        draw.circle(x, y, r, col, segs, 1.6)
    end
end

local function rect(x, y, w, h, col, filled)
    if not draw then return end
    if filled then
        draw.rect_filled(x, y, w, h, col, 0)
    else
        draw.rect(x, y, w, h, col, 0, 1.5)
    end
end

local function poly(points, col, t)
    if draw and draw.poly then
        draw.poly(points, col, t or 1.5)
    else
        for i = 1, #points - 1 do
            line(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], col, t)
        end
    end
end

local function ellipse_arc(cx, cy, rx, ry, a0, a1, col, steps)
    steps = steps or 10
    local pts = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * (i / steps)
        pts[#pts + 1] = { cx + math.cos(t) * rx, cy + math.sin(t) * ry }
    end
    poly(pts, col, 1.5)
end

function M.draw(name, cx, cy, col)
    col = col or theme.TEXT

    if name == "aim" then
        -- Crosshair with outer brackets
        circle(cx, cy, 5.5, col, false, 22)
        circle(cx, cy, 1.4, col, true, 10)
        line(cx - 9, cy, cx - 4, cy, col, 1.7)
        line(cx + 4, cy, cx + 9, cy, col, 1.7)
        line(cx, cy - 9, cx, cy - 4, col, 1.7)
        line(cx, cy + 4, cx, cy + 9, col, 1.7)
        -- corner ticks
        line(cx - 8, cy - 8, cx - 5, cy - 8, col, 1.3)
        line(cx - 8, cy - 8, cx - 8, cy - 5, col, 1.3)
        line(cx + 8, cy - 8, cx + 5, cy - 8, col, 1.3)
        line(cx + 8, cy - 8, cx + 8, cy - 5, col, 1.3)
        line(cx - 8, cy + 8, cx - 5, cy + 8, col, 1.3)
        line(cx - 8, cy + 8, cx - 8, cy + 5, col, 1.3)
        line(cx + 8, cy + 8, cx + 5, cy + 8, col, 1.3)
        line(cx + 8, cy + 8, cx + 8, cy + 5, col, 1.3)

    elseif name == "visuals" then
        -- Eye
        ellipse_arc(cx, cy, 8, 4.5, math.pi, math.pi * 2, col, 12)
        ellipse_arc(cx, cy, 8, 4.5, 0, math.pi, col, 12)
        circle(cx, cy, 2.8, col, false, 14)
        circle(cx + 0.6, cy - 0.4, 1.1, col, true, 8)

    elseif name == "world" then
        -- Globe with meridians
        circle(cx, cy, 7, col, false, 24)
        -- latitude
        ellipse_arc(cx, cy, 7, 2.8, 0, math.pi * 2, col, 16)
        -- longitude
        ellipse_arc(cx, cy, 2.8, 7, 0, math.pi * 2, col, 16)
        line(cx, cy - 7, cx, cy + 7, col, 1.2)

    elseif name == "guns" then
        -- Side-view rifle silhouette
        -- barrel
        rect(cx - 2, cy - 2.5, 10, 2.2, col, true)
        -- receiver
        rect(cx - 7, cy - 3.2, 7, 4.2, col, true)
        -- stock
        poly({
            { cx - 7, cy - 2.5 },
            { cx - 11, cy - 3.5 },
            { cx - 11, cy + 2.5 },
            { cx - 7, cy + 1.2 },
        }, col, 1.6)
        line(cx - 7, cy - 2.5, cx - 11, cy - 3.5, col, 1.6)
        line(cx - 11, cy - 3.5, cx - 11, cy + 2.5, col, 1.6)
        line(cx - 11, cy + 2.5, cx - 7, cy + 1.2, col, 1.6)
        -- mag
        rect(cx - 4.5, cy + 1, 2.4, 4, col, true)
        -- front sight
        line(cx + 6, cy - 2.5, cx + 6, cy - 5, col, 1.4)

    elseif name == "misc" then
        -- Three control sliders
        for i = 0, 2 do
            local yy = cy - 6 + i * 6
            line(cx - 7, yy, cx + 7, yy, col, 1.4)
            local knob = ({ -3, 3, 0 })[i + 1]
            circle(cx + knob, yy, 2.2, col, true, 10)
            circle(cx + knob, yy, 2.2, col, false, 10)
        end

    elseif name == "radar" then
        -- Radar dish + sweep
        circle(cx, cy, 7.5, col, false, 24)
        circle(cx, cy, 4.5, col, false, 18)
        circle(cx, cy, 1.5, col, true, 10)
        line(cx, cy, cx + 6.5, cy - 3.5, col, 1.8)
        -- blip
        circle(cx + 3.5, cy + 2.5, 1.3, col, true, 8)
        -- north tick
        line(cx, cy - 7.5, cx, cy - 9.5, col, 1.5)

    elseif name == "config" then
        -- Gear
        local teeth = 8
        for i = 0, teeth - 1 do
            local a = (i / teeth) * math.pi * 2
            local c, s = math.cos(a), math.sin(a)
            local x1, y1 = cx + c * 3.2, cy + s * 3.2
            local x2, y2 = cx + c * 7.2, cy + s * 7.2
            local px, py = -s * 1.5, c * 1.5
            poly({
                { x1 + px, y1 + py },
                { x2 + px * 0.7, y2 + py * 0.7 },
                { x2 - px * 0.7, y2 - py * 0.7 },
                { x1 - px, y1 - py },
                { x1 + px, y1 + py },
            }, col, 1.35)
        end
        circle(cx, cy, 3.8, col, false, 16)
        circle(cx, cy, 1.8, col, true, 10)

    else
        circle(cx, cy, 4, col, false)
    end
end

return M

end)()

-- ── ui/gs_widgets.lua ──
April._mods["ui.gs_widgets"] = (function()
-- Gamesense-style widgets (draw API) backed by ui.gs_state.
local theme = April.require("ui.gs_theme")
local input = April.require("ui.gs_input")
local state = April.require("ui.gs_state")
local anim = April.require("ui.gs_anim")
local ui_theme = April.require("core.ui_theme")
local tooltips = April.require("ui.tooltips")

local M = {}

M.active_slider = nil
M.active_slider_input = nil
M.active_input = nil
M.open_combo = nil
M.open_multi = nil
M.open_color = nil
M.listening_key = nil
M.drag_offset_x = 0
M.drag_offset_y = 0
M.dragging_window = false
M.clip = nil -- { x, y, w, h }
M.popup_used_click = false -- set when a popup consumes this frame's click
M.interacted = false -- any widget captured LMB this frame
M._hue_cache = {} -- id -> hue 0..1 for color picker
M._list_scroll = {} -- id -> first visible option index (0-based)
M.LIST_MAX_VISIBLE = 8
M.wheel_consumed = false -- set when a dropdown/list eats the wheel this frame
M.block_under = false -- true while pointer is over a floating popup (prior frame rect)
-- Floating color picker (drawn after the menu so it doesn't expand sections)
M._color_anchor = nil -- { id, x, y, w }
M._color_hit = nil -- { x, y, w, h } last drawn picker rect
M.open_bind_mode = nil -- keybind id whose Always/Hold/Toggle menu is open
M._bind_mode_anchor = nil -- { id, x, y, w }
M._bind_mode_hit = nil
M._active_input_rect = nil -- { x, y, w, h } for click-outside blur
M._active_slider_input_rect = nil
M._slider_input_meta = {} -- id -> { min, max, float, fmt }
M._slider_edit_text = {} -- id -> string while editing
M._input_repeat_at = 0
M._input_repeat_vk = nil
M.TIP_DELAY_MS = 450
M.TIP_FADE_MS = 180
M._tip_candidate = nil
M._tip_hover_id = nil
M._tip_hover_ms = 0

local LISTEN_SKIP = {
    [0x01] = true, -- LMB used for UI
}

local function listen_skip_vk(vk)
    if LISTEN_SKIP[vk] then return true end
    local menu_vk = state.get_key("april_ui_menu_key")
    if not menu_vk or menu_vk == 0 then menu_vk = 0x2D end
    return vk == menu_vk
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function text_w(str, size)
    if draw and draw.get_text_size then
        local w = draw.get_text_size(str, size or theme.FONT)
        if type(w) == "number" then return w end
    end
    return #(tostring(str or "")) * 7
end

local function fit_text(str, max_w, size)
    str = tostring(str or "")
    if max_w <= 0 or text_w(str, size) <= max_w then return str end
    local suffix = "..."
    while #str > 0 and text_w(str .. suffix, size) > max_w do
        str = str:sub(1, -2)
    end
    return str .. suffix
end

local function in_clip(y, h)
    local c = M.clip
    if not c then return true end
    return y >= c.y and y + h <= c.y + c.h
end

local function stacked_metrics(y)
    local label_y = y + 3
    local ctrl_y = y + theme.LABEL_H + theme.LABEL_GAP
    return label_y, ctrl_y, theme.CTRL_H, theme.STACKED_ROW_H
end

local function interactive(x, y, w, h)
    if M.block_under then return false end
    if not in_clip(y, h) then return false end
    local c = M.clip
    if c and not input.hover(c.x, c.y, c.w, c.h) then
        return false
    end
    return true
end

local function ui_clicked(x, y, w, h)
    if M.block_under then return false end
    return input.clicked(x, y, w, h)
end

local function ui_rmb_clicked(x, y, w, h)
    if M.block_under then return false end
    return input.rmb_click and input.hover(x, y, w, h)
end

local function rgb_to_hsv(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local d = max - min
    local h = 0
    if d > 1e-6 then
        if max == r then
            h = ((g - b) / d) % 6
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
        if h < 0 then h = h + 1 end
    end
    local s = max <= 1e-6 and 0 or (d / max)
    return h, s, max
end

local function hsv_to_rgb(h, s, v)
    h = (h % 1) * 6
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p end
    if i == 1 then return q, v, p end
    if i == 2 then return p, v, t end
    if i == 3 then return p, q, v end
    if i == 4 then return t, p, v end
    return v, p, q
end

function M.begin_popups()
    M.popup_used_click = false
    M.interacted = false
    M.wheel_consumed = false
    M._color_anchor = nil
    M._bind_mode_anchor = nil
    M._active_input_rect = nil
    M._active_slider_input_rect = nil
    M._tip_candidate = nil

    -- Block underlay widgets when the cursor is over last frame's popup rect
    M.block_under = false
    if M.open_color and M._color_hit then
        local r = M._color_hit
        if input.hover(r.x, r.y, r.w, r.h) then
            M.block_under = true
            if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
                M.interacted = true
                M.popup_used_click = true
            end
        end
    end
    if M.open_bind_mode and M._bind_mode_hit then
        local r = M._bind_mode_hit
        if input.hover(r.x, r.y, r.w, r.h) then
            M.block_under = true
            if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
                M.interacted = true
                M.popup_used_click = true
            end
        end
    end
end

local function mark_interacted()
    M.interacted = true
    M.popup_used_click = true
end

local function open_color_popup(id, anchor_x, anchor_y, row_w)
    if M.open_color == id then
        M.open_color = nil
        M._color_anchor = nil
        M._color_hit = nil
    else
        M.open_color = id
        M.open_combo = nil
        M.open_multi = nil
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M._color_anchor = { id = id, x = anchor_x, y = anchor_y, w = row_w or 160 }
    end
end

local function open_bind_mode_popup(id, anchor_x, anchor_y, chip_w)
    if M.open_bind_mode == id then
        M.open_bind_mode = nil
        M._bind_mode_anchor = nil
        M._bind_mode_hit = nil
    else
        M.open_bind_mode = id
        M.open_combo = nil
        M.open_multi = nil
        M.open_color = nil
        M._color_hit = nil
        M._bind_mode_anchor = { id = id, x = anchor_x, y = anchor_y, w = chip_w or 56 }
    end
end

local function list_scroll_for(id, count, max_vis)
    max_vis = max_vis or M.LIST_MAX_VISIBLE
    local max_off = math.max(0, count - max_vis)
    local off = M._list_scroll[id] or 0
    if off < 0 then off = 0 end
    if off > max_off then off = max_off end
    M._list_scroll[id] = off
    return off, max_off, math.min(count, max_vis)
end

local LIST_SCROLL_EDGE = 22

local function apply_list_edge_scroll(id, count, max_vis, list_x, list_y, list_w, list_h)
    max_vis = max_vis or M.LIST_MAX_VISIBLE
    local max_off = math.max(0, count - max_vis)
    if max_off <= 0 then return end
    if not input.hover(list_x, list_y, list_w, list_h) then return end

    local off = M._list_scroll[id] or 0
    if input.wheel ~= 0 and not M.wheel_consumed then
        off = off - input.wheel
        M.wheel_consumed = true
    elseif input.my < list_y + LIST_SCROLL_EDGE then
        off = off - 1
    elseif input.my > list_y + list_h - LIST_SCROLL_EDGE then
        off = off + 1
    end
    if off < 0 then off = 0 end
    if off > max_off then off = max_off end
    M._list_scroll[id] = off
end

local function frame_dt()
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 and dt < 0.25 then return dt end
    end
    return 0.016
end

function M.register_tooltip_hover(id, tip, x, y, w, h)
    if not id or not tip or tip == "" then return end
    if M.block_under then return end
    if not in_clip(y, h) then return end
    if input.hover(x, y, w, h) then
        M._tip_candidate = { id = id, tip = tip, x = x, y = y, w = w, h = h }
    end
end

function M.end_tooltip_frame()
    local c = M._tip_candidate
    if c and c.id == M._tip_hover_id then
        M._tip_hover_ms = M._tip_hover_ms + frame_dt() * 1000
    else
        M._tip_hover_id = c and c.id or nil
        M._tip_hover_ms = 0
    end
    M._tip_active = c
end

local function wrap_tip_lines(text, max_w, fs)
    text = tostring(text or "")
    local lines = {}
    local line = ""
    for word in text:gmatch("%S+") do
        local test = line == "" and word or (line .. " " .. word)
        if text_w(test, fs) > max_w and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end
    if line ~= "" then
        lines[#lines + 1] = line
    end
    return #lines > 0 and lines or { text }
end

function M.draw_tooltip_overlay()
    if M.block_under or M.open_combo or M.open_multi or M.open_color or M.open_bind_mode then
        return
    end
    if not M._tip_active or M._tip_hover_ms < M.TIP_DELAY_MS then
        return
    end

    local fade = math.min(1, (M._tip_hover_ms - M.TIP_DELAY_MS) / M.TIP_FADE_MS)
    fade = fade * fade * (3 - 2 * fade)
    if fade <= 0.01 then return end

    local anchor = M._tip_active
    local fs = 11
    local pad = 8
    local max_line_w = 228
    local lines = wrap_tip_lines(anchor.tip, max_line_w, fs)

    local tw = 0
    for i = 1, #lines do
        tw = math.max(tw, text_w(lines[i], fs))
    end

    local box_w = math.min(260, tw + pad * 2)
    local box_h = #lines * 13 + pad * 2
    local tx = anchor.x + anchor.w * 0.5 - box_w * 0.5
    local ty = anchor.y + anchor.h + 6

    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    tx = math.max(8, math.min(tx, sw - box_w - 8))
    if ty + box_h > sh - 8 then
        ty = anchor.y - box_h - 6
    end
    ty = math.max(8, ty)

    local bg = theme.alpha(ui_theme.PANEL, 0.96 * fade)
    local border = theme.alpha(ui_theme.BORDER, 0.55 * fade)
    local accent = theme.alpha(ui_theme.CYAN, fade)
    M.rect(tx, ty, box_w, box_h, bg, true, theme.CORNER_SMALL)
    M.rect(tx, ty, box_w, box_h, border, false, theme.CORNER_SMALL)
    M.rect(tx + 1, ty + 1, box_w - 2, 2, accent, true)

    for i = 1, #lines do
        local col = theme.alpha(i == 1 and ui_theme.TEXT or ui_theme.TEXT_MUTED, fade)
        M.text(tx + pad, ty + pad + (i - 1) * 13, lines[i], col, fs)
    end
end

function M.end_popups()
    if input.lmb_click and M.active_slider_input and M._active_slider_input_rect then
        local r = M._active_slider_input_rect
        if not input.hover(r.x, r.y, r.w, r.h) then
            M.commit_slider_input()
        end
    end

    if input.lmb_click and M.active_input and M._active_input_rect then
        local r = M._active_input_rect
        if not input.hover(r.x, r.y, r.w, r.h) then
            M.active_input = nil
        end
    end

    if (input.lmb_click or input.rmb_click) and not M.popup_used_click then
        if M.open_combo or M.open_multi or M.open_color or M.open_bind_mode then
            M.open_combo = nil
            M.open_multi = nil
            M.open_color = nil
            M.open_bind_mode = nil
            M._color_anchor = nil
            M._color_hit = nil
            M._bind_mode_anchor = nil
            M._bind_mode_hit = nil
        end
    end
end

--- Draw floating color picker on top of the whole menu (call after columns).
function M.draw_color_overlay()
    if not M.open_color then
        M._color_hit = nil
        return
    end
    local id = M.open_color
    local col = state.get_color(id, { 1, 1, 1, 1 })
    local pw, ph = 168, 138
    local ax = M._color_anchor
    local px, py
    if ax and ax.id == id then
        px = ax.x + (ax.w or 160) - pw
        py = ax.y + theme.ROW_H + 2
    else
        px = input.mx + 12
        py = input.my + 12
    end
    -- Keep on screen
    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end
    if px + pw > sw - 4 then px = sw - pw - 4 end
    if py + ph > sh - 4 then py = sh - ph - 4 end

    M._color_hit = { x = px, y = py, w = pw, h = ph }

    -- Soft shadow / backdrop
    M.rect(px + 6, py + 8, pw, ph, theme.SHADOW_DEEP, true, theme.CORNER)
    M.rect(px + 3, py + 4, pw, ph, theme.SHADOW, true, theme.CORNER)
    M.draw_color_picker(px, py, pw, ph, id, col)

    if input.hover(px, py, pw, ph) then
        if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
            mark_interacted()
        end
    end
end

--- Right-click keybind settings card.
function M.draw_bind_mode_overlay()
    if not M.open_bind_mode then
        M._bind_mode_hit = nil
        return
    end
    local id = M.open_bind_mode
    local modes = { "Always", "Hold", "Toggle" }
    local mode_id = id .. "_mode"
    local cur = tonumber(state.get(mode_id, 2)) or 2

    local feature_bind = nil
    pcall(function()
        feature_bind = April.require("core.feature_bind")
    end)
    local show_hide = feature_bind and feature_bind.is_registered(id)
    local hide_id = show_hide and feature_bind.hide_key_id(id) or nil
    local hidden = show_hide and state.get(hide_id, false) == true

    local pw = show_hide and 190 or 112
    local header_h = 24
    local row_h = 22
    local footer_h = show_hide and 32 or 0
    local ph = header_h + #modes * row_h + footer_h + 5
    local ax = M._bind_mode_anchor
    local px, py
    if ax and ax.id == id then
        px = ax.x + (ax.w or 56) - pw
        py = ax.y + 18
    else
        px = input.mx
        py = input.my + 8
    end
    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end
    if px + pw > sw - 4 then px = sw - pw - 4 end
    if py + ph > sh - 4 then py = sh - ph - 4 end

    M._bind_mode_hit = { x = px, y = py, w = pw, h = ph }

    M.rect(px + 4, py + 5, pw, ph, theme.SHADOW, true, theme.CORNER_SMALL)
    M.rect(px, py, pw, ph, theme.OVERLAY, true, theme.CORNER_SMALL)
    M.rect(px, py, pw, ph, theme.BORDER_HOT, false, theme.CORNER_SMALL)
    anim.draw_title_bar(px + 1, py, pw - 2, 2)

    M.text(px + 9, py + 6, "KEYBIND SETTINGS", theme.TEXT_TITLE, theme.FONT_CAPTION)
    M.rect(px + 8, py + header_h - 1, pw - 16, 1, theme.BORDER_SOFT, true)

    for i, name in ipairs(modes) do
        local iy = py + header_h + (i - 1) * row_h
        local selected = (cur == i - 1)
        if input.hover(px, iy, pw, row_h) then
            M.rect(px + 5, iy + 2, pw - 10, row_h - 4, theme.HOVER, true, theme.CORNER_SMALL)
        end
        if selected then
            M.rect(px + 5, iy + 2, pw - 10, row_h - 4,
                theme.alpha(theme.FOCUS, 0.18), true, theme.CORNER_SMALL)
            anim.draw_tab_indicator(px + 5, iy + 5, 2, row_h - 10)
        end
        local dot_x = px + pw - 15
        local dot_y = iy + math.floor(row_h * 0.5)
        M.text(px + 13, iy + 4, name, selected and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
        if draw and draw.circle then
            draw.circle(dot_x, dot_y, 4, selected and theme.FOCUS or theme.BORDER, 12, 1)
        end
        if selected and draw and draw.circle_filled then
            draw.circle_filled(dot_x, dot_y, 2, anim.checkbox_fill(), 10)
        end
        if input.clicked(px, iy, pw, row_h) then
            mark_interacted()
            state.set(mode_id, i - 1)
            M.open_bind_mode = nil
            M._bind_mode_hit = nil
        end
    end

    if show_hide then
        state.define(hide_id, false)
        local footer_y = py + header_h + #modes * row_h
        M.rect(px + 8, footer_y, pw - 16, 1, theme.BORDER_SOFT, true)
        local hide_y = footer_y + 3
        local hide_h = footer_h - 4
        if input.hover(px, hide_y, pw, hide_h) then
            M.rect(px + 5, hide_y + 2, pw - 10, hide_h - 4, theme.HOVER, true, theme.CORNER_SMALL)
        end
        local box = theme.CHECK_SIZE
        local bx = px + 11
        local by = hide_y + math.floor((hide_h - box) * 0.5)
        M.rect(bx, by, box, box, theme.CHECK_OFF, true, theme.CORNER_SMALL)
        M.rect(bx, by, box, box, hidden and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
        if hidden then
            M.rect(bx + 2, by + 2, box - 4, box - 4, anim.checkbox_fill(), true, theme.CORNER_SMALL)
        end
        M.text(bx + box + 8, hide_y + 7, "Hide from keybind list",
            hidden and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
        if input.clicked(px, hide_y, pw, hide_h) then
            mark_interacted()
            state.set(hide_id, not hidden)
        end
    end

    if input.hover(px, py, pw, ph) and (input.lmb_click or input.rmb_click) then
        mark_interacted()
    end
end

function M.vk_name(vk)
    return April.require("core.vk_names").label(vk)
end

function M.rect(x, y, w, h, col, filled, rounding)
    if not draw then return end
    local c = M.clip
    if c then
        local x2 = x + w
        local y2 = y + h
        local cx = c.x
        local cy = c.y
        local cx2 = c.x + c.w
        local cy2 = c.y + c.h
        if x2 <= cx or y2 <= cy or x >= cx2 or y >= cy2 then return end
        if x < cx then
            w = w - (cx - x)
            x = cx
        end
        if y < cy then
            h = h - (cy - y)
            y = cy
        end
        if x + w > cx2 then w = cx2 - x end
        if y + h > cy2 then h = cy2 - y end
        if w <= 0 or h <= 0 then return end
    end
    if filled then
        draw.rect_filled(x, y, w, h, col, rounding or 0)
    else
        draw.rect(x, y, w, h, col, rounding or 0, 1)
    end
end

function M.text(x, y, str, col, size)
    if draw and draw.text then
        draw.text(x, y, tostring(str), col, size or theme.FONT)
    end
end

function M.rainbow_bar(x, y, w, h)
    anim.draw_title_bar(x, y, w, h)
end

function M.group_box(x, y, w, h, title)
    local c = M.clip
    if c then
        -- Only paint the portion inside the clip rect
        local top = math.max(y, c.y)
        local bot = math.min(y + h, c.y + c.h)
        if bot <= top then return end
        M.rect(x, top, w, bot - top, theme.PANEL, true)
        M.rect(x, top, w, bot - top, theme.BORDER, false)
        if y >= c.y - 2 and y < c.y + c.h then
            M.text(x + 12, y + 5, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
        end
        return
    end
    M.rect(x, y, w, h, theme.PANEL, true)
    M.rect(x, y, w, h, theme.BORDER, false)
    M.text(x + 12, y + 5, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
end

local LISTEN_VKS = {
    0x02, 0x04, 0x05, 0x06, 0x08, 0x09, 0x0D, 0x10, 0x11, 0x12, 0x14, 0x1B, 0x20,
    0x25, 0x26, 0x27, 0x28, 0x2E,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
    0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B,
    0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0,
}

function M.tick_key_listen()
    if not M.listening_key then return end
    if input.key_pressed(0x1B) then
        M.listening_key = nil
        return
    end
    for i = 1, #LISTEN_VKS do
        local vk = LISTEN_VKS[i]
        if not listen_skip_vk(vk) and input.key_pressed(vk) then
            state.set_key(M.listening_key, vk)
            M.listening_key = nil
            return
        end
    end
end

local INPUT_VKS = {
    0x20,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
    0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
    0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xDB, 0xDC, 0xDD, 0xDE,
}

local INPUT_SHIFT = {
    [0x30] = ")", [0x31] = "!", [0x32] = "@", [0x33] = "#", [0x34] = "$",
    [0x35] = "%", [0x36] = "^", [0x37] = "&", [0x38] = "*", [0x39] = "(",
    [0xBA] = ":", [0xBB] = "+", [0xBC] = "<", [0xBD] = "_", [0xBE] = ">",
    [0xBF] = "?", [0xC0] = "~", [0xDB] = "{", [0xDC] = "|", [0xDD] = "}",
    [0xDE] = "\"",
}

local INPUT_PLAIN = {
    [0x20] = " ",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-", [0xBE] = ".",
    [0xBF] = "/", [0xC0] = "`", [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]",
    [0xDE] = "'",
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function vk_to_char(vk)
    local shift = input.key_down(0x10)
    if vk >= 0x41 and vk <= 0x5A then
        local ch = string.char(vk)
        return shift and ch or string.lower(ch)
    end
    if shift then
        return INPUT_SHIFT[vk] or INPUT_PLAIN[vk]
    end
    return INPUT_PLAIN[vk]
end

local function input_key_repeat(vk)
    if input.key_pressed(vk) then
        M._input_repeat_vk = vk
        M._input_repeat_at = tick_ms() + 400
        return true
    end
    if M._input_repeat_vk ~= vk or not input.key_down(vk) then
        return false
    end
    local now = tick_ms()
    if now >= M._input_repeat_at then
        M._input_repeat_at = now + 35
        return true
    end
    return false
end

local function focus_input(id)
    M.active_input = id
    M.active_slider_input = nil
    M.open_combo = nil
    M.open_multi = nil
    M.open_color = nil
    M.open_bind_mode = nil
    M.listening_key = nil
    M._input_repeat_vk = nil
end

local SLIDER_INPUT_VKS = {
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0xBD, 0x6D, 0xBE, 0x6E,
}

local function slider_vk_to_char(vk)
    if vk >= 0x30 and vk <= 0x39 then
        return string.char(vk)
    end
    if vk >= 0x60 and vk <= 0x69 then
        return string.char(vk - 0x30)
    end
    if vk == 0xBD or vk == 0x6D then return "-" end
    if vk == 0xBE or vk == 0x6E then return "." end
    return nil
end

local function slider_char_allowed(text, ch, is_float, minv)
    if ch:match("%d") then return true end
    if ch == "-" and minv < 0 and text == "" then return true end
    if is_float and ch == "." and not text:find(".", 1, true) then return true end
    return false
end

local function parse_slider_text(text, meta)
    if not meta then return nil end
    text = tostring(text or ""):match("^%s*(.-)%s*$") or ""
    if text == "" or text == "-" or text == "." or text == "-." then return nil end
    local n = tonumber(text)
    if not n then return nil end
    if not meta.float then
        n = math.floor(n + 0.5)
    end
    return clamp(n, meta.min, meta.max)
end

function M.commit_slider_input()
    local id = M.active_slider_input
    if not id then return end
    local meta = M._slider_input_meta[id]
    local n = parse_slider_text(M._slider_edit_text[id], meta)
    if n ~= nil then
        state.set(id, n)
    end
    M.active_slider_input = nil
    M._active_slider_input_rect = nil
    M._input_repeat_vk = nil
end

function M.cancel_slider_input()
    M.active_slider_input = nil
    M._active_slider_input_rect = nil
    M._input_repeat_vk = nil
end

function M.begin_slider_input(id, minv, maxv, is_float, val, fmt)
    M.active_slider_input = id
    M.active_slider = nil
    M.active_input = nil
    M.open_combo = nil
    M.open_multi = nil
    M.open_color = nil
    M.open_bind_mode = nil
    M.listening_key = nil
    M._input_repeat_vk = nil
    fmt = fmt or (is_float and "%.2f" or "%d")
    M._slider_input_meta[id] = {
        min = minv,
        max = maxv,
        float = is_float == true,
        fmt = fmt,
    }
    M._slider_edit_text[id] = string.format(fmt, val)
end

function M.tick_slider_input()
    if not M.active_slider_input or M.listening_key then return end
    if input.key_down(0x11) or input.key_down(0x12) then return end

    local id = M.active_slider_input
    local meta = M._slider_input_meta[id]
    if not meta then
        M.cancel_slider_input()
        return
    end

    local val = tostring(M._slider_edit_text[id] or "")

    if input.key_pressed(0x1B) then
        M.cancel_slider_input()
        return
    end

    if input.key_pressed(0x0D) then
        M.commit_slider_input()
        return
    end

    if input_key_repeat(0x08) or input_key_repeat(0x2E) then
        if #val > 0 then
            M._slider_edit_text[id] = val:sub(1, -2)
        end
        return
    end

    for i = 1, #SLIDER_INPUT_VKS do
        local vk = SLIDER_INPUT_VKS[i]
        if input_key_repeat(vk) then
            local ch = slider_vk_to_char(vk)
            if ch and slider_char_allowed(val, ch, meta.float, meta.min) then
                M._slider_edit_text[id] = val .. ch
            end
            M._input_repeat_vk = nil
            return
        end
    end
end

function M.tick_text_input()
    if not M.active_input or M.listening_key then return end
    if input.key_down(0x11) or input.key_down(0x12) then return end

    local id = M.active_input
    local val = tostring(state.get(id, ""))

    if input.key_pressed(0x1B) or input.key_pressed(0x0D) then
        M.active_input = nil
        M._input_repeat_vk = nil
        return
    end

    if input_key_repeat(0x08) then
        if #val > 0 then
            state.set(id, val:sub(1, -2))
        end
        return
    end

    if input_key_repeat(0x2E) then
        if #val > 0 then
            state.set(id, val:sub(1, -2))
        end
        return
    end

    for i = 1, #INPUT_VKS do
        local vk = INPUT_VKS[i]
        if input.key_pressed(vk) then
            local ch = vk_to_char(vk)
            if ch then
                state.set(id, val .. ch)
            end
            M._input_repeat_vk = nil
            return
        end
    end
end

function M.checkbox(x, y, w, id, label, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then
        return 0
    end
    state.define(id, opts.default == true)
    if opts.color then
        state.define_color(id, opts.color)
    end
    local on = state.get(id, false)
    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    local hovered = input.hover(x, y, w, h)
    local active = on == true
    local hover_fill = anim.transition("check-hover:" .. tostring(id), hovered, 16)
    if hover_fill > 0.01 then
        M.rect(x, y + 1, w, h - 2, theme.alpha(theme.HOVER, hover_fill), true, theme.CORNER_SMALL)
    end

    local bx = x + 4
    local by = y + (h - theme.CHECK_SIZE) * 0.5
    local active_t = anim.transition("check-state:" .. tostring(id), active, anim.motion_rate(22))
    M.rect(bx + 1, by + 2, theme.CHECK_SIZE, theme.CHECK_SIZE, theme.SHADOW, true, theme.CORNER_SMALL)
    M.rect(bx, by, theme.CHECK_SIZE, theme.CHECK_SIZE, theme.CHECK_OFF, true, theme.CORNER_SMALL)
    M.rect(bx, by, theme.CHECK_SIZE, theme.CHECK_SIZE,
        active and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    if active_t > 0.01 then
        local inset = 2 + (1 - active_t) * (theme.CHECK_SIZE * 0.35)
        local inner = theme.CHECK_SIZE - inset * 2
        if inner > 1 then
            M.rect(bx + inset, by + inset, inner, inner, theme.alpha(anim.checkbox_fill(), active_t), true, theme.CORNER_SMALL)
        end
    end

    local label_w = w - theme.CHECK_SIZE - 38
    M.text(bx + theme.CHECK_SIZE + 8, y + 4, fit_text(label, label_w, theme.FONT),
        on and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT)

    local has_color = opts.color or state.colors[id]
    local swatch_clicked = false
    if has_color then
        local col = state.get_color(id, opts.color or { 1, 1, 1, 1 })
        local cx = x + w - 18
        M.rect(cx, by, 12, 12, col, true, 2)
        M.rect(cx, by, 12, 12, theme.BORDER, false, 2)
        if ui_clicked(cx - 2, by - 2, 16, 16) then
            swatch_clicked = true
            mark_interacted()
            local hh = rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1)
            M._hue_cache[id] = hh
            open_color_popup(id, x, y, w)
        elseif M.open_color == id then
            -- Keep anchor updated while open so overlay tracks scroll
            M._color_anchor = { id = id, x = x, y = y, w = w }
        end
    end

    if not swatch_clicked and interactive(x, y, w, h) and ui_clicked(x, y, w - (has_color and 22 or 0), h) then
        mark_interacted()
        state.toggle(id)
        pcall(function()
            April.require("core.menu_util").sync_master(id)
        end)
    end
    return h
end

function M.slider(x, y, w, id, label, minv, maxv, default, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then return 0 end
    local is_float = opts.float == true
    state.define(id, default)
    local val = tonumber(state.get(id, default)) or default
    local h = theme.SLIDER_ROW_H
    if not in_clip(y, h) then return h end

    local editing = M.active_slider_input == id
    if editing then
        M._active_slider_input_rect = { x = x, y = y, w = w, h = h }
    end

    local hovered = input.hover(x, y, w, h)
    local hover_fill = anim.transition("slider-hover:" .. tostring(id), hovered, 16)
    if hover_fill > 0.01 then
        M.rect(x, y + 1, w, h - 2, theme.alpha(theme.HOVER, hover_fill), true, theme.CORNER_SMALL)
    end

    local fmt = opts.fmt or (is_float and "%.2f" or "%d")
    local shown
    if editing then
        shown = tostring(M._slider_edit_text[id] or "")
    else
        shown = string.format(fmt, val)
    end
    local vw = text_w(shown ~= "" and shown or "0", theme.FONT_SMALL)
    local value_x = x + w - vw - 6
    M.text(x + 4, y + 3, fit_text(label, w - vw - 22, theme.FONT), theme.TEXT, theme.FONT)
    if editing then
        M.rect(value_x - 4, y + 1, vw + 8, theme.LABEL_H + 2, theme.alpha(theme.FOCUS, 0.22), true, theme.CORNER_SMALL)
        M.rect(value_x - 4, y + 1, vw + 8, theme.LABEL_H + 2, theme.FOCUS, false, theme.CORNER_SMALL)
    end
    M.text(value_x, y + 3, shown, editing and theme.TEXT_ACTIVE or theme.TEXT_DIM, theme.FONT_SMALL)
    if editing then
        local now = tick_ms()
        if math.floor(now / 500) % 2 == 0 then
            M.rect(value_x + vw + 1, y + 4, 1, theme.LABEL_H - 2, theme.TEXT_ACTIVE, true)
        end
    end

    local sx = x + 4
    local sy = y + theme.LABEL_H + theme.LABEL_GAP + 4
    local sw = w - 8
    M.rect(sx, sy, sw, theme.SLIDER_H, theme.SLIDER_BG, true, theme.SLIDER_H * 0.5)
    local t = 0
    if maxv > minv then
        t = clamp((val - minv) / (maxv - minv), 0, 1)
    end
    if t > 0 then
        anim.draw_slider_fill(sx, sy, math.max(2, sw * t), theme.SLIDER_H)
    end
    M.rect(sx, sy, sw, theme.SLIDER_H, theme.BORDER_SOFT, false, theme.SLIDER_H * 0.5)
    local thumb_x = sx + sw * t
    local drag_t = anim.transition("slider-active:" .. tostring(id), M.active_slider == id, anim.motion_rate(24))
    local thumb_w = 6 + drag_t * 2
    M.rect(thumb_x - thumb_w * 0.5 + 1, sy - 1, thumb_w, theme.SLIDER_H + 4,
        theme.SHADOW, true, thumb_w * 0.5)
    M.rect(thumb_x - thumb_w * 0.5, sy - 2, thumb_w, theme.SLIDER_H + 4,
        anim.mix(anim.checkbox_fill(), theme.TEXT_ACTIVE, drag_t), true, thumb_w * 0.5)

    local hot = input.hover(sx, sy - 4, sw, theme.SLIDER_H + 8)
    if interactive(x, y, w, h) and ui_rmb_clicked(x, y, w, h) then
        mark_interacted()
        M.begin_slider_input(id, minv, maxv, is_float, val, fmt)
    elseif not editing and interactive(x, y, w, h)
        and ((input.lmb_click and hot) or (input.lmb and M.active_slider == id)) then
        M.active_slider = id
        mark_interacted()
        local nt = clamp((input.mx - sx) / sw, 0, 1)
        local nv = minv + (maxv - minv) * nt
        if not is_float then nv = math.floor(nv + 0.5) end
        state.set(id, nv)
    elseif M.active_slider == id and not input.lmb then
        M.active_slider = nil
    end
    return h
end

function M.combo(x, y, w, id, label, options, default_idx)
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default_idx or 0)
    local idx = tonumber(state.get(id, default_idx or 0)) or 0
    local label_y, ctrl_y, ctrl_h, h = stacked_metrics(y)
    local open = M.open_combo == id
    if not in_clip(y, h) and not open then return h end

    M.text(x + 4, label_y, fit_text(label, w - 8, theme.FONT), theme.TEXT, theme.FONT)
    local bx, by, bw, bh = x + 4, ctrl_y, w - 8, ctrl_h
    local hovered = input.hover(bx, by, bw, bh)
    local fill = anim.interactive_fill("combo:" .. tostring(id), theme.BUTTON, hovered, open)
    M.rect(bx, by, bw, bh, fill, true, theme.CORNER_SMALL)
    M.rect(bx, by, bw, bh, open and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    local cur = options[idx + 1] or options[1] or "-"
    M.text(bx + 6, by + math.floor((bh - 12) * 0.5),
        fit_text(cur, bw - 28, theme.FONT_SMALL), theme.TEXT_ACTIVE, theme.FONT_SMALL)
    M.text(bx + bw - 13, by + math.floor((bh - 12) * 0.5), open and "^" or "v", open and theme.TEXT_ACTIVE or theme.TEXT_DIM, theme.FONT_SMALL)

    -- Header toggles open/closed (do not require clip hover - fixes "can't close")
    if ui_clicked(bx, by, bw, bh) then
        mark_interacted()
        if open then
            M.open_combo = nil
        else
            M.open_combo = id
            M.open_multi = nil
            M.open_color = nil
            M.open_bind_mode = nil
            M._list_scroll[id] = 0
        end
        open = M.open_combo == id
    end

    if open then
        local n = #options
        local off, max_off, vis = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)
        local list_h = vis * 18
        local list_y = by + bh
        apply_list_edge_scroll(id, n, M.LIST_MAX_VISIBLE, bx, list_y, bw, list_h)
        off = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)

        M.rect(bx + 2, by + bh + 2, bw, list_h, theme.SHADOW, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.OVERLAY, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER_HOT, false, theme.CORNER_SMALL)
        for row = 0, vis - 1 do
            local i = off + row + 1
            local opt = options[i]
            if not opt then break end
            local iy = by + bh + row * 18
            if input.hover(bx, iy, bw, 18) then
                M.rect(bx + 2, iy + 1, bw - 4, 16, theme.HOVER, true, theme.CORNER_SMALL)
            end
            if i - 1 == idx then
                M.rect(bx + 3, iy + 4, 2, 10, anim.checkbox_fill(), true, 1)
            end
            M.text(bx + 10, iy + 2, fit_text(opt, bw - 20, theme.FONT_SMALL),
                (i - 1 == idx) and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
            if ui_clicked(bx, iy, bw, 18) then
                mark_interacted()
                state.set(id, i - 1)
                M.open_combo = nil
            end
        end
        if max_off > 0 then
            local thumb_h = math.max(10, list_h * (vis / n))
            local ty = by + bh + (list_h - thumb_h) * (off / math.max(1, max_off))
            M.rect(bx + bw - 4, by + bh, 3, list_h, theme.SLIDER_BG, true)
            anim.draw_scroll_thumb(bx + bw - 4, ty, 3, thumb_h)
        end
        if input.hover(bx, by, bw, bh + list_h) and input.lmb_click and not M.block_under then
            mark_interacted()
        end
        return h + list_h
    end
    return h
end

function M.multi(x, y, w, id, label, options, defaults, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then return 0 end
    defaults = defaults or {}
    local def = {}
    for i = 1, #options do
        def[i] = defaults[i] == true
    end
    state.define(id, def)
    local vals = state.get(id, def)
    if type(vals) ~= "table" then
        vals = def
        state.set(id, vals)
    end
    if type(opts.sync_ids) == "table" then
        for i, alias_id in ipairs(opts.sync_ids) do
            vals[i] = state.get(alias_id, def[i]) == true
        end
        -- Derived UI summary; source feature IDs remain authoritative.
        state.values[id] = vals
    end

    local h = theme.STACKED_ROW_H
    local open = M.open_multi == id
    if not in_clip(y, h) and not open then return h end

    local label_y, ctrl_y, ctrl_h = stacked_metrics(y)
    M.text(x + 4, label_y, fit_text(label, w - 8, theme.FONT), theme.TEXT, theme.FONT)
    local bx, by, bw, bh = x + 4, ctrl_y, w - 8, ctrl_h
    local hovered = input.hover(bx, by, bw, bh)
    local fill = anim.interactive_fill("multi:" .. tostring(id), theme.BUTTON, hovered, open)
    M.rect(bx, by, bw, bh, fill, true, theme.CORNER_SMALL)
    M.rect(bx, by, bw, bh, open and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)

    local parts = {}
    for i, opt in ipairs(options) do
        if vals[i] then parts[#parts + 1] = opt end
    end
    local summary = (#parts > 0) and table.concat(parts, ", ") or "None"
    summary = fit_text(summary, bw - 20, theme.FONT_SMALL)
    M.text(bx + 6, by + math.floor((bh - 12) * 0.5), summary, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_clicked(bx, by, bw, bh) then
        mark_interacted()
        if open then
            M.open_multi = nil
        else
            M.open_multi = id
            M.open_combo = nil
            M.open_color = nil
            M.open_bind_mode = nil
            M._list_scroll[id] = 0
        end
        open = M.open_multi == id
    end

    if open then
        local n = #options
        local off, max_off, vis = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)
        local list_h = vis * 18
        local list_y = by + bh
        apply_list_edge_scroll(id, n, M.LIST_MAX_VISIBLE, bx, list_y, bw, list_h)
        off = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)

        M.rect(bx + 2, by + bh + 2, bw, list_h, theme.SHADOW, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.OVERLAY, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER_HOT, false, theme.CORNER_SMALL)
        for row = 0, vis - 1 do
            local i = off + row + 1
            local opt = options[i]
            if not opt then break end
            local iy = by + bh + row * 18
            local on = vals[i] == true
            if input.hover(bx, iy, bw, 18) then
                M.rect(bx + 2, iy + 1, bw - 4, 16, theme.HOVER, true, theme.CORNER_SMALL)
            end
            M.rect(bx + 5, iy + 3, 12, 12, theme.CHECK_OFF, true, 2)
            if on then
                M.rect(bx + 7, iy + 5, 8, 8, anim.checkbox_fill(), true, 2)
            end
            M.text(bx + 24, iy + 2, fit_text(opt, bw - 32, theme.FONT_SMALL),
                on and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
            if ui_clicked(bx, iy, bw, 18) then
                mark_interacted()
                vals[i] = not on
                state.set(id, vals)
                local alias_id = opts.sync_ids and opts.sync_ids[i]
                if alias_id then
                    state.set(alias_id, vals[i])
                end
            end
        end
        if max_off > 0 then
            local thumb_h = math.max(10, list_h * (vis / n))
            local ty = by + bh + (list_h - thumb_h) * (off / math.max(1, max_off))
            M.rect(bx + bw - 4, by + bh, 3, list_h, theme.SLIDER_BG, true)
            anim.draw_scroll_thumb(bx + bw - 4, ty, 3, thumb_h)
        end
        if input.hover(bx, by, bw, bh + list_h) and input.lmb_click and not M.block_under then
            mark_interacted()
        end
        return h + list_h
    end
    return h
end

function M.button(x, y, w, id, label)
    if id and not state.is_visible(id) then return 0 end
    local h = 24
    if not in_clip(y, h) then return h end
    local hovered = input.hover(x, y, w, h)
    local pressed = hovered and input.lmb
    local press_t = anim.transition("button-press:" .. tostring(id), pressed, anim.motion_rate(28))
    local oy = press_t * 1.5
    M.rect(x + 2, y + 3, w, h, theme.SHADOW, true, theme.CORNER_SMALL)
    M.rect(x, y + oy, w, h,
        anim.interactive_fill("button:" .. tostring(id), theme.BUTTON, hovered, pressed),
        true, theme.CORNER_SMALL)
    M.rect(x, y + oy, w, h, hovered and theme.BORDER_HOT or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    local shown = fit_text(label, w - 16, theme.FONT_SMALL)
    local tw = text_w(shown, theme.FONT_SMALL)
    M.text(x + (w - tw) * 0.5, y + 6 + oy, shown, theme.TEXT_ACTIVE, theme.FONT_SMALL)
    if interactive(x, y, w, h) and ui_clicked(x, y, w, h) then
        mark_interacted()
        state.fire_button(id)
    end
    return h
end

function M.label(x, y, w, text, dim)
    local h = theme.ROW_H - 4
    if not in_clip(y, h) then return h end
    M.text(x + 4, y + 3, text, dim and theme.TEXT_DIM or theme.TEXT_TITLE, theme.FONT_SMALL)
    return h
end

function M.separator(x, y, w)
    local h = 18
    if not in_clip(y, h) then return h end
    M.rect(x + 5, y + 9, w - 10, 1, theme.BORDER_SOFT, true)
    return h
end

function M.keybind(x, y, w, id, label, default_on)
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default_on == true)
    local mode_id = id .. "_mode"
    local hide_id = id .. "_hide_kb"
    state.define(mode_id, 2) -- default Toggle (Always=0, Hold=1, Toggle=2)
    state.define(hide_id, false)

    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    -- checkbox portion (leave room for key chip; mode is RMB popup)
    local chip_w = 56
    local cw = w - chip_w - 6
    local used = M.checkbox(x, y, cw, id, label, { default = default_on })

    -- key chip: LMB bind, RMB mode (Always / Hold / Toggle)
    local kx = x + w - chip_w
    local ky = y + 3
    local listening = M.listening_key == id
    local vk = state.get_key(id)
    local klabel = listening and "..." or ("[" .. M.vk_name(vk) .. "]")
    local mode_open = M.open_bind_mode == id
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.ACCENT_DIM or theme.BUTTON, true, 8)
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.FOCUS or theme.BORDER_SOFT, false, 8)
    local tw = text_w(klabel, theme.FONT_SMALL)
    M.text(kx + (chip_w - tw) * 0.5, ky + 1, klabel, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_rmb_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.listening_key = nil
        open_bind_mode_popup(id, kx, ky, chip_w)
    elseif ui_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M.listening_key = listening and nil or id
    elseif mode_open then
        M._bind_mode_anchor = { id = id, x = kx, y = ky, w = chip_w }
    end

    return used
end

function M.aim_key_row(x, y, w, key_id, mode_id, label)
    if key_id and not state.is_visible(key_id) then return 0 end
    mode_id = mode_id or (key_id .. "_mode")
    state.define(mode_id, 1)

    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    local chip_w = 56
    M.text(x + 4, y + 3, fit_text(label, w - chip_w - 12, theme.FONT), theme.TEXT, theme.FONT)

    local kx = x + w - chip_w
    local ky = y + 3
    local listening = M.listening_key == key_id
    local vk = state.get_key(key_id)
    local klabel = listening and "..." or ("[" .. M.vk_name(vk) .. "]")
    local mode_open = M.open_bind_mode == key_id
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.ACCENT_DIM or theme.BUTTON, true, 8)
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.FOCUS or theme.BORDER_SOFT, false, 8)
    local tw = text_w(klabel, theme.FONT_SMALL)
    M.text(kx + (chip_w - tw) * 0.5, ky + 1, klabel, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_rmb_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.listening_key = nil
        open_bind_mode_popup(key_id, kx, ky, chip_w)
    elseif ui_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M.listening_key = listening and nil or key_id
    elseif mode_open then
        M._bind_mode_anchor = { id = key_id, x = kx, y = ky, w = chip_w }
    end

    return h
end

function M.hotkey_row(x, y, w, id, label, default_vk)
    if id and not state.is_visible(id) then return 0 end
    if state.get_key(id) == 0 and default_vk and default_vk ~= 0 then
        state.set_key(id, default_vk)
    end

    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    local chip_w = 56
    M.text(x + 4, y + 4, fit_text(label, w - chip_w - 12, theme.FONT), theme.TEXT, theme.FONT)

    local kx = x + w - chip_w
    local ky = y + 4
    local listening = M.listening_key == id
    local vk = state.get_key(id)
    local klabel = listening and "..." or ("[" .. M.vk_name(vk) .. "]")
    M.rect(kx, ky, chip_w, 18, listening and theme.ACCENT_DIM or theme.BUTTON, true, 8)
    M.rect(kx, ky, chip_w, 18, listening and theme.FOCUS or theme.BORDER_SOFT, false, 8)
    local tw = text_w(klabel, theme.FONT_SMALL)
    M.text(kx + (chip_w - tw) * 0.5, ky + 3, klabel, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_clicked(kx, ky, chip_w, 18) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M.listening_key = listening and nil or id
    end

    return h
end

function M.color_row(x, y, w, id, label, default_col)
    if id and not state.is_visible(id) then return 0 end
    state.define_color(id, default_col or { 1, 1, 1, 1 })
    local col = state.get_color(id, default_col)
    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    M.text(x + 4, y + 3, fit_text(label, w - 32, theme.FONT), theme.TEXT, theme.FONT)
    local cx = x + w - 18
    M.rect(cx, y + 4, 12, 12, col, true, 3)
    M.rect(cx, y + 4, 12, 12, theme.BORDER, false, 3)

    if ui_clicked(cx - 2, y + 2, 16, 16) then
        mark_interacted()
        M._hue_cache[id] = select(1, rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1))
        open_color_popup(id, x, y, w)
    elseif M.open_color == id then
        M._color_anchor = { id = id, x = x, y = y, w = w }
    end
    return h
end

function M.draw_color_picker(px, py, pw, ph, id, col)
    M.rect(px, py, pw, ph, theme.OVERLAY, true, theme.CORNER)
    M.rect(px, py, pw, ph, theme.BORDER_HOT, false, theme.CORNER)

    local hue = M._hue_cache[id]
    if not hue then
        hue = select(1, rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1))
        M._hue_cache[id] = hue
    end
    local _, sat, val = rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1)
    local alpha = col[4] or 1

    local sq = 96
    local sx, sy = px + 8, py + 8
    -- Saturation / value square (sampled grid)
    local steps = 8
    local cell = sq / steps
    for iy = 0, steps - 1 do
        for ix = 0, steps - 1 do
            local s = ix / (steps - 1)
            local v = 1 - iy / (steps - 1)
            local r, g, b = hsv_to_rgb(hue, s, v)
            M.rect(sx + ix * cell, sy + iy * cell, cell + 0.5, cell + 0.5, { r, g, b, 1 }, true)
        end
    end
    M.rect(sx, sy, sq, sq, theme.BORDER, false, theme.CORNER_SMALL)

    -- Hue bar
    local hx, hy, hw, hh = sx + sq + 8, sy, 14, sq
    for i = 0, 23 do
        local t = i / 23
        local r, g, b = hsv_to_rgb(t, 1, 1)
        M.rect(hx, hy + i * (hh / 24), hw, hh / 24 + 0.5, { r, g, b, 1 }, true)
    end
    M.rect(hx, hy, hw, hh, theme.BORDER, false, theme.CORNER_SMALL)

    -- Alpha bar
    local ax, ay, aw, ah = sx, sy + sq + 8, sq + 22, 10
    M.rect(ax, ay, aw, ah, { 0.15, 0.15, 0.15, 1 }, true)
    M.rect(ax, ay, aw * clamp(alpha, 0, 1), ah, { col[1], col[2], col[3], 1 }, true)
    M.rect(ax, ay, aw, ah, theme.BORDER, false, theme.CORNER_SMALL)

    -- Preview
    local prx = ax + aw + 6
    M.rect(prx, ay - 2, 18, 14, { col[1], col[2], col[3], alpha }, true)
    M.rect(prx, ay - 2, 18, 14, theme.BORDER, false)

    local function apply(s, v, a, new_hue)
        if new_hue then
            M._hue_cache[id] = new_hue
            hue = new_hue
        end
        local r, g, b = hsv_to_rgb(hue, s, v)
        state.set_color(id, { r, g, b, a })
        if id == "april_ui_accent" then
            anim.sync_theme()
        end
    end

    if input.lmb and input.hover(sx, sy, sq, sq) then
        M.popup_used_click = true
        local ns = clamp((input.mx - sx) / sq, 0, 1)
        local nv = clamp(1 - (input.my - sy) / sq, 0, 1)
        apply(ns, nv, alpha, nil)
    elseif input.lmb and input.hover(hx, hy, hw, hh) then
        M.popup_used_click = true
        local nh = clamp((input.my - hy) / hh, 0, 1)
        apply(sat, val, alpha, nh)
    elseif input.lmb and input.hover(ax, ay, aw, ah) then
        M.popup_used_click = true
        local na = clamp((input.mx - ax) / aw, 0, 1)
        apply(sat, val, na, nil)
    end

    if input.hover(px, py, pw, ph) and input.lmb_click then
        M.popup_used_click = true
    end

    -- Cursor marks
    local mx = sx + sat * sq
    local my = sy + (1 - val) * sq
    M.rect(mx - 2, my - 2, 4, 4, { 1, 1, 1, 1 }, false)
    M.rect(hx - 1, hy + hue * hh - 1, hw + 2, 3, { 1, 1, 1, 1 }, false)
end

function M.input_row(x, y, w, id, label, default)
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default or "")
    local val = tostring(state.get(id, default or ""))
    local label_y, ctrl_y, ctrl_h, h = stacked_metrics(y)
    if not in_clip(y, h) then return h end
    M.text(x + 4, label_y, fit_text(label, w - 8, theme.FONT), theme.TEXT, theme.FONT)
    local bx, by, bw, bh = x + 4, ctrl_y, w - 8, ctrl_h
    local focused = M.active_input == id
    local hot = input.hover(bx, by, bw, bh)
    if focused then
        M._active_input_rect = { x = bx, y = by, w = bw, h = bh }
    end
    M.rect(bx, by, bw, bh, anim.interactive_fill("input:" .. tostring(id), theme.BUTTON, hot, focused), true, theme.CORNER_SMALL)
    M.rect(bx, by, bw, bh, focused and theme.FOCUS or (hot and theme.BORDER_HOT or theme.BORDER_SOFT), false, theme.CORNER_SMALL)

    local shown = val
    local text_x = bx + 6
    local max_w = bw - 12
    local text_y = by + math.floor((bh - 12) * 0.5)
    if shown == "" then
        M.text(text_x, text_y, "...", theme.TEXT_DIM, theme.FONT_SMALL)
    else
        while #shown > 0 and text_w(shown, theme.FONT_SMALL) > max_w do
            shown = shown:sub(2)
        end
        M.text(text_x, text_y, shown, focused and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
    end

    if focused then
        local caret_x = text_x + text_w(shown ~= "" and shown or "", theme.FONT_SMALL)
        local now = tick_ms()
        if math.floor(now / 500) % 2 == 0 then
            M.rect(caret_x, by + math.floor((bh - 10) * 0.5), 1, 10, theme.TEXT_ACTIVE, true)
        end
    end

    if interactive(bx, by, bw, bh) and ui_clicked(bx, by, bw, bh) then
        mark_interacted()
        focus_input(id)
    end
    return h
end

function M.estimate_height(item)
    local t = item.type
    local extra = 0
    -- Color pickers overlay - they do not expand layout height
    if item.id and M.open_combo == item.id and item.options then
        extra = math.min(#item.options, M.LIST_MAX_VISIBLE) * 18
    elseif item.id and M.open_multi == item.id and item.options then
        extra = math.min(#item.options, M.LIST_MAX_VISIBLE) * 18
    end
    if t == "slider" then
        return theme.SLIDER_ROW_H + extra
    elseif t == "combo" or t == "multi" or t == "input" then
        return theme.STACKED_ROW_H + extra
    elseif t == "separator" then
        return 18
    elseif t == "button" then
        return 24
    elseif t == "label" then
        return theme.ROW_H - 4
    elseif t == "color" then
        return theme.ROW_H
    elseif t == "checkbox" or t == "keybind" or t == "aim_key" or t == "hotkey" then
        return theme.ROW_H
    end
    return theme.ROW_H + extra
end

function M.draw_item(item, x, y, w)
    local t = item.type
    local h = 0
    if t == "checkbox" then
        h = M.checkbox(x, y, w, item.id, item.label, item)
    elseif t == "keybind" then
        h = M.keybind(x, y, w, item.id, item.label, item.default)
    elseif t == "aim_key" then
        h = M.aim_key_row(x, y, w, item.id, item.mode_id, item.label)
    elseif t == "hotkey" then
        h = M.hotkey_row(x, y, w, item.id, item.label, item.default)
    elseif t == "slider" then
        h = M.slider(x, y, w, item.id, item.label, item.min, item.max, item.default, item)
    elseif t == "combo" then
        h = M.combo(x, y, w, item.id, item.label, item.options, item.default)
    elseif t == "multi" then
        h = M.multi(x, y, w, item.id, item.label, item.options, item.defaults, item)
    elseif t == "button" then
        h = M.button(x + 4, y, w - 8, item.id, item.label)
    elseif t == "label" then
        h = M.label(x, y, w, item.label, item.dim)
    elseif t == "separator" then
        h = M.separator(x, y, w)
    elseif t == "color" then
        h = M.color_row(x, y, w, item.id, item.label, item.default)
    elseif t == "input" then
        h = M.input_row(x, y, w, item.id, item.label, item.default)
    end

    local tip = tooltips.for_item(item)
    if tip and item.id and h > 0 then
        M.register_tooltip_hover(item.id, tip, x, y, w, h)
    end
    return h
end

return M

end)()

-- ── ui/catalog.lua ──
April._mods["ui.catalog"] = (function()
--[[
  Layout catalog for the custom Gamesense UI.
  Values / callbacks come from feature register_menu() via ui.menu_shim.
  Nested options use `gate` so they only appear under their parent toggle.
]]

local maps = April.require("game.esp_maps")
local combat_menu = April.require("ui.combat_labels")

local M = {}

local function cb(id, label, default, color, gate)
    return { type = "checkbox", id = id, label = label, default = default == true, color = color, gate = gate }
end

local function kb(id, label, default, gate)
    return { type = "keybind", id = id, label = label, default = default == true, gate = gate }
end

local function sl(id, label, minv, maxv, default, float, gate, extra)
    local item = {
        type = "slider",
        id = id,
        label = label,
        min = minv,
        max = maxv,
        default = default,
        float = float == true,
        fmt = float and "%.2f" or "%d",
        gate = gate,
    }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            item[k] = v
        end
    end
    return item
end

local function combo(id, label, options, default, gate)
    return { type = "combo", id = id, label = label, options = options, default = default or 0, gate = gate }
end

local function multi(id, label, options, defaults, gate, extra)
    local item = { type = "multi", id = id, label = label, options = options, defaults = defaults, gate = gate }
    if type(extra) == "table" then
        for k, v in pairs(extra) do item[k] = v end
    end
    return item
end

local function btn(id, label, gate)
    return { type = "button", id = id, label = label, gate = gate }
end

local function sep(gate)
    return { type = "separator", gate = gate }
end

local function label(text, dim, gate)
    return { type = "label", label = text, dim = dim, gate = gate }
end

local function color(id, label_text, default, gate, override_idx)
    return {
        type = "color",
        id = id,
        label = label_text,
        default = default,
        gate = gate,
        color_override_idx = override_idx,
    }
end

local function input(id, label_text, default, gate)
    return { type = "input", id = id, label = label_text, default = default or "", gate = gate }
end

local function ak(key_id, label, gate)
    return { type = "aim_key", id = key_id, mode_id = key_id .. "_mode", label = label, gate = gate }
end

local function hk(id, label, gate, default_vk)
    return { type = "hotkey", id = id, label = label, gate = gate, default = default_vk or 0x2D }
end

local function from_toggles(list, gate)
    local out = {}
    for _, t in ipairs(list) do
        out[#out + 1] = cb(t.id, t.label, false, t.color, gate)
        if t.ring_id then
            out[#out + 1] = cb(t.ring_id, t.label .. " Range Ring", false, nil, gate)
        end
    end
    return out
end

local function append(dst, src)
    for _, v in ipairs(src) do
        dst[#dst + 1] = v
    end
end

M.TABS = {
    { id = "aim", icon = "aim", title = "Aimbot" },
    { id = "visuals", icon = "visuals", title = "Visuals" },
    { id = "world", icon = "world", title = "World" },
    { id = "guns", icon = "guns", title = "Gun Mods" },
    { id = "misc", icon = "misc", title = "Misc" },
    { id = "radar", icon = "radar", title = "Radar" },
    { id = "config", icon = "config", title = "Config" },
}

local function build_aim()
    local regular = {
        title = "Aimbot",
        master = "april_aimbot",
        items = {
            cb("april_aimbot", "Enable Aimbot", false),
            ak("april_aim_key", "Aim Key"),
            sep(),
            combo("april_aim_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
            combo("april_aim_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_aim_targets", "Aim At", { "Players", "NPCs" }, { true, false }),
            multi("april_aim_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_aim_whitelist_ids", "Whitelist IDs", ""),
            btn("april_aim_whitelist_clear", "Clear Whitelist"),
            sl("april_aim_max_dist", "Max Distance (m)", 50, 2000, 500),
            sep(),
            multi("april_aim_options", "Options", { "Sticky Target" }, { false }),
            sl("april_aim_smooth", "Smoothness", 1, 25, 10),
            sl("april_aim_fov", "FOV Radius (px)", 20, 600, 120),
            sep(),
            cb("april_aim_draw_fov", "FOV Circle", false, { 0.2, 1, 0.45, 1 }),
            combo("april_aim_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, "april_aim_draw_fov"),
            cb("april_aim_target_line", "Target Line", false, { 0.2, 1, 0.45, 1 }),
        },
    }

    local rage = {
        title = "Ragebot",
        master = "april_rage_enabled",
        items = {
            kb("april_rage_enabled", "Enable Ragebot", false),
            sep(),
            combo("april_rage_target_type", "Target Type", { "Crosshair", "Distance" }, 1),
            combo("april_rage_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_rage_targets", "Aim At", { "Players", "NPCs" }, { true, false }),
            multi("april_rage_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_rage_whitelist_ids", "Whitelist IDs", ""),
            btn("april_rage_whitelist_clear", "Clear Whitelist"),
            sl("april_rage_max_dist", "Max Distance (m)", 50, 2000, 500),
            sep(),
            multi("april_rage_options", "Options", { "Sticky Target" }, { false }),
            cb("april_rage_autofire", "Autofire", true),
            sl("april_rage_fire_delay", "Fire Delay (ms)", 20, 400, 80),
        },
    }

    local silent = {
        title = "Silent Aim",
        master = "april_silent_aim",
        items = {
            kb("april_silent_aim", "Enable Silent Aim", false),
            sep(),
            combo("april_silent_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
            combo("april_silent_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_silent_targets", "Aim At", { "Players", "NPCs" }, { true, false }),
            multi("april_silent_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_silent_whitelist_ids", "Whitelist IDs", ""),
            btn("april_silent_whitelist_clear", "Clear Whitelist"),
            sl("april_silent_max_dist", "Max Distance (m)", 50, 2000, 500),
            sep(),
            multi("april_silent_options", "Options", { "Sticky Target" }, { false }),
            sl("april_silent_hit_chance", "Hit Chance %", 1, 100, 100),
            sl("april_silent_fov", "FOV Radius (px)", 20, 600, 150),
            sep(),
            cb("april_silent_draw_fov", "FOV Circle", false, { 0.55, 0.2, 1, 1 }),
            combo("april_silent_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, "april_silent_draw_fov"),
            cb("april_silent_target_line", "Snapline", false, { 1, 0.25, 0.25, 1 }),
        },
    }

    local bullet = {
        title = "Bullet",
        master = "april_bullet_enabled",
        items = {
            cb("april_bullet_enabled", "Enable Bullet", false),
            sep(),
            cb("april_silent_hitscan", "Hitscan", false),
            sep(),
            cb("april_silent_bullet_tp", "Bullet TP", false),
            sep("april_silent_bullet_tp"),
            cb("april_silent_bullet_manip", "Silent Bullet Manip", false),
            sl("april_silent_manip_dist", "Manip Distance", 0.1, 1, 1, true, "april_silent_bullet_manip"),
            cb("april_silent_manip_extend", "Extend", false, nil, "april_silent_bullet_manip"),
            sl("april_silent_manip_extend_dist", "Extend Distance", 1, 7, 7, true, "april_silent_manip_extend"),
            cb("april_bullet_body_peek", "Body Peek (desync)", false, nil, "april_silent_bullet_manip"),
            sep("april_bullet_enabled"),
            cb("april_silent_manip_status", "Status HUD", false, nil, "april_bullet_enabled"),
            cb("april_silent_manip_peek_vis", "Peek Visual", false, nil, "april_bullet_enabled"),
        },
    }

    return { regular, rage, silent, bullet }
end

local function build_visuals()
    local left = {
        title = "Player ESP",
        master = "april_player_enabled",
        items = {
            kb("april_player_enabled", "Player ESP", false),
            combo("april_player_box_mode", "Player Box", { "None", "2D", "Corner" }, 1),
            multi("april_ui_player_elements", "Displayed Elements", {
                "Health Bar", "Skeleton", "Name", "Clan Tag", "Distance", "Weapon",
            }, { true, false, true, true, true, false }, nil, {
                sync_ids = {
                    "april_player_health", "april_player_skeleton", "april_player_show_name",
                    "april_player_clan_tag", "april_player_show_distance", "april_player_show_weapon",
                },
            }),
            multi("april_player_esp_filters", "ESP Filters", {
                "Team Check", "Skip Safezone", "Skip Downed",
            }, { true, false, false }),
            multi("april_player_esp_flags", "ESP Flags", {
                "Downed", "Safezone", "Staff", "Reviving",
            }, { true, true, true, true }),
            sl("april_player_range", "Player Range", 50, 2000, 500),
        },
    }

    local gear = {
        title = "Target Gear",
        master = "april_target_overlay",
        items = {
            kb("april_target_overlay", "Target Gear Overlay", false),
            combo("april_target_gear_source", "Target From", { "Auto", "Ragebot", "Silent Aim", "Aimbot" }, 0, "april_target_overlay"),
            sl("april_target_overlay_gear_size", "Gear Icon Size", 32, 64, 48, false, "april_target_overlay"),
            sl("april_target_overlay_top", "Top Offset", 48, 160, 88, false, "april_target_overlay"),
        },
    }

    local target_vis = {
        title = "Crosshair",
        items = {
            cb("april_crosshair_enabled", "Custom Crosshair", false),
            combo("april_crosshair_type", "Style", {
                "Cross", "Circle", "Dot", "T-Shape", "Diamond", "Plus", "Brackets", "X",
            }, 0, "april_crosshair_enabled"),
            cb("april_crosshair_follow", "Follow Target", false, nil, "april_crosshair_enabled"),
            combo("april_crosshair_source", "Target From", { "Auto", "Ragebot", "Silent Aim", "Aimbot" }, 0, "april_crosshair_follow"),
            sl("april_crosshair_follow_smooth", "Follow Smoothness", 4, 40, 18, false, "april_crosshair_follow"),
            multi("april_ui_crosshair_motion", "Motion", { "Spin", "Pulse Size" }, { false, false }, "april_crosshair_enabled", {
                sync_ids = { "april_crosshair_spin", "april_crosshair_pulse" },
            }),
            sl("april_crosshair_spin_speed", "Spin Speed", 1, 100, 35, false, "april_crosshair_spin"),
            sl("april_crosshair_pulse_speed", "Pulse Speed", 1, 100, 40, false, "april_crosshair_pulse"),
            multi("april_ui_crosshair_options", "Options", {
                "Center Dot", "Outline", "Rainbow",
            }, { false, true, false }, "april_crosshair_enabled", {
                sync_ids = {
                    "april_crosshair_dot", "april_crosshair_outline", "april_crosshair_rainbow",
                },
            }),
            color("april_crosshair_color", "Crosshair Color", { 0, 1, 0, 1 }, "april_crosshair_enabled"),
            color("april_crosshair_dot", "Center Dot Color", { 1, 1, 1, 1 }, "april_crosshair_dot"),
            sl("april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10, false, "april_crosshair_rainbow"),
            sl("april_crosshair_size", "Size", 1, 50, 10, false, "april_crosshair_enabled"),
            sl("april_crosshair_gap", "Gap", 0, 20, 5, false, "april_crosshair_enabled"),
            sl("april_crosshair_thickness", "Thickness", 1, 10, 2, false, "april_crosshair_enabled"),
        },
    }

    local colors = {
        title = "Player Colors",
        master = "april_player_enabled",
        items = {
            color("april_player_skeleton", "Skeleton", { 1, 1, 1, 0.92 }),
            color("april_player_show_name", "Name", { 1, 0.35, 0.35, 1 }),
            color("april_player_clan_tag", "Clan Tag", { 0.84, 0.31, 0.80, 1 }),
            color("april_player_show_distance", "Distance", { 0.82, 0.84, 0.88, 0.92 }),
            color("april_player_show_weapon", "Weapon", { 0.82, 0.84, 0.88, 0.92 }),
            sep(),
            color("april_player_flag_downed", "Downed", { 1, 0.35, 0.35, 1 }),
            color("april_player_flag_safezone", "Safezone", { 0.35, 0.85, 1, 1 }),
            color("april_player_flag_staff", "Staff", { 1, 0.33, 0.33, 1 }),
            color("april_player_flag_reviving", "Reviving", { 0.45, 1, 0.55, 1 }),
        },
    }
    return { left, gear, target_vis, colors }
end

local function build_world()
    local resources = {
        title = "Resources",
        master = "april_world_enabled",
        items = {
            kb("april_world_enabled", "Resource ESP", false),
        },
    }
    append(resources.items, from_toggles(maps.WORLD_TOGGLES))
    append(resources.items, {
        cb("april_world_boxes", "Resource 3D Boxes", false),
        cb("april_world_show_name", "Resource Show Name", true),
        cb("april_world_show_distance", "Resource Show Distance", true),
        sl("april_world_range", "Resource Range", 50, 2000, 500),
        multi("april_world_chams", "Resource Chams", (function()
            local labels = {}
            for i, t in ipairs(maps.WORLD_TOGGLES) do labels[i] = t.label end
            return labels
        end)(), {}),
        combo("april_world_chams_mode", "Resource Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
        color("april_world_chams_color", "Resource Chams Color", { 0.4, 1, 0.4, 1 }),
    })

    local loot = {
        title = "Loot",
        master = "april_loot_enabled",
        items = {
            kb("april_loot_enabled", "Loot ESP", false),
        },
    }
    append(loot.items, from_toggles(maps.LOOT_TOGGLES))
    append(loot.items, {
        cb("april_loot_boxes", "Loot 3D Boxes", false),
        cb("april_loot_show_name", "Loot Show Name", true),
        cb("april_loot_show_distance", "Loot Show Distance", true),
        sl("april_loot_range", "Loot Range", 50, 2000, 300),
        multi("april_loot_chams", "Loot Chams", (function()
            local labels = {}
            for i, t in ipairs(maps.LOOT_TOGGLES) do labels[i] = t.label end
            return labels
        end)(), {}),
        combo("april_loot_chams_mode", "Loot Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
        color("april_loot_chams_color", "Loot Chams Color", { 1, 0.85, 0.35, 1 }),
    })

    local bases = {
        title = "Bases",
        master = "april_base_enabled",
        items = {
            kb("april_base_enabled", "Base ESP", false),
        },
    }
    append(bases.items, from_toggles(maps.BASE_TOGGLES))
    append(bases.items, {
        cb("april_base_boxes", "Base 3D Boxes", false),
        cb("april_base_show_name", "Base Show Name", true),
        cb("april_base_show_distance", "Base Show Distance", false),
        sl("april_base_range", "Base Range", 50, 500, 150),
        multi("april_base_chams", "Base Chams", (function()
            local labels = {}
            for i, t in ipairs(maps.BASE_TOGGLES) do labels[i] = t.label end
            return labels
        end)(), {}),
        combo("april_base_chams_mode", "Base Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
        color("april_base_chams_color", "Base Chams Color", { 0.55, 0.55, 1, 1 }),
    })

    local npcs = {
        title = "NPCs",
        master = "april_npc_enabled",
        items = {
            kb("april_npc_enabled", "NPC ESP", false),
            multi("april_ui_npc_types", "NPC Types", { "Soldiers", "Bosses" }, { false, false }, nil, {
                sync_ids = { "april_npc_soldiers", "april_npc_bosses" },
            }),
            combo("april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1),
            multi("april_ui_npc_elements", "Displayed Elements", {
                "Health Bar", "Skeleton", "Name", "Distance", "Weapon",
            }, { true, false, true, true, false }, nil, {
                sync_ids = {
                    "april_npc_health", "april_npc_skeleton", "april_npc_show_name",
                    "april_npc_show_distance", "april_npc_show_weapon",
                },
            }),
            color("april_npc_soldiers", "Soldier Color", { 1, 0.3, 0.3, 1 }),
            color("april_npc_bosses", "Boss Color", { 1, 0.5, 0.1, 1 }),
            color("april_npc_skeleton", "Skeleton Color", { 1, 1, 1, 0.85 }),
            color("april_npc_show_name", "Name Color", { 1, 0.3, 0.3, 1 }),
            color("april_npc_show_distance", "Distance Color", { 0.82, 0.84, 0.88, 0.92 }),
            color("april_npc_show_weapon", "Weapon Color", { 0.82, 0.84, 0.88, 0.92 }),
            sl("april_npc_range", "NPC Range", 50, 2000, 500),
        },
    }

    return { resources, loot, npcs, bases }
end

local function build_guns()
    return {
        {
            title = "Gun Mods",
            master = "april_gunmods_enabled",
            items = {
                kb("april_gunmods_enabled", "Enable Gun Mods", false),
                sep(),
                cb("april_gm_recoil", "No Recoil", false),
                sl("april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, false, "april_gm_recoil"),
                sep(),
                cb("april_gm_spread", "No Spread", false),
                sl("april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, false, "april_gm_spread"),
                sep(),
                cb("april_gm_sway", "No Sway", false),
                sep(),
                cb("april_gm_fire_rate", "Fire Rate", false),
                sl("april_gm_fire_rate_mult", "Fire Rate Multiplier", 1, 3, 1.5, true, "april_gm_fire_rate"),
                sep(),
                cb("april_gm_speed", "Bullet Speed", false),
                sl("april_gm_speed_mult", "Speed Mult", 1, 100, 100, false, "april_gm_speed"),
                sep(),
                cb("april_gm_range", "Gun Range", false),
                sl("april_gm_range_mult", "Range Mult", 1, 20, 10, false, "april_gm_range"),
                sep(),
                cb("april_gm_double_tap", "Double Tap", false),
            },
        },
    }
end

local function build_misc()
    return {
        {
            title = "Movement",
            items = {
                kb("april_noclip_enabled", "Fly", false),
                sl("april_noclip_speed", "Fly Speed", 1, 20, 5, false, "april_noclip_enabled"),
                kb("april_slowfall_enabled", "Slowfall", false),
                sl("april_slowfall_speed", "Fall Speed", 1, 50, 5, false, "april_slowfall_enabled"),
                sep(),
                kb("april_desync_enabled", "Desync", false),
                cb("april_desync_visualizer", "Desync Visualize", false, { 0.2, 0.85, 1, 0.9 }, "april_desync_enabled"),
                sep(),
                kb("april_antiaim_enabled", "Anti-Aim", false),
                combo("april_antiaim_yaw_mode", "Yaw Mode", { "None", "Backwards", "Spin", "Jitter", "Random Jitter", "Sideways Left", "Sideways Right", "Manual" }, 1, "april_antiaim_enabled"),
                sl("april_antiaim_yaw_manual", "Manual Yaw", -180, 180, 90, false, "april_antiaim_enabled", {
                    gate_combo = "april_antiaim_yaw_mode",
                    gate_combo_value = 7,
                }),
                sl("april_antiaim_spin_speed", "Spin Speed", 30, 720, 180, false, "april_antiaim_enabled", {
                    gate_combo = "april_antiaim_yaw_mode",
                    gate_combo_value = 2,
                }),
                sl("april_antiaim_jitter_step", "Jitter Step", 15, 180, 90, false, "april_antiaim_enabled", {
                    gate_any_combo = {
                        { "april_antiaim_yaw_mode", { 3, 4 } },
                    },
                }),
                sl("april_antiaim_jitter_ms", "Jitter Interval (ms)", 40, 500, 120, false, "april_antiaim_enabled", {
                    gate_any_combo = {
                        { "april_antiaim_yaw_mode", { 3, 4 } },
                    },
                }),
                kb("april_fakeduck_enabled", "Fake Duck", false),
                sl("april_fakeduck_height", "Duck Height", 0.01, 1.5, 1.1, true, "april_fakeduck_enabled"),
                cb("april_fakeduck_spam", "Spam Height", false, nil, "april_fakeduck_enabled"),
                combo("april_fakeduck_spam_mode", "Spam Mode", { "Alternating", "Random" }, 0, "april_fakeduck_spam"),
                sl("april_fakeduck_spam_min", "Spam Min", 0.01, 1.5, 0.01, true, "april_fakeduck_spam"),
                sl("april_fakeduck_spam_max", "Spam Max", 0.01, 1.5, 1.5, true, "april_fakeduck_spam"),
                sl("april_fakeduck_spam_ms", "Spam Interval (ms)", 20, 400, 80, false, "april_fakeduck_spam"),
                sep(),
                kb("april_fling_enabled", "Fling", false),
                sl("april_fling_fov", "Fling FOV", 20, 600, 150, false, "april_fling_enabled"),
                sl("april_fling_duration", "Fling Duration", 2, 10, 2, false, "april_fling_enabled"),
            },
        },
        {
            title = "Utility",
            items = {
                kb("april_farm_helper", "Farm Helper", false),
                cb("april_farm_silent", "Silent Farm", false, nil, "april_farm_helper"),
                sl("april_farm_radius", "Farm Range (studs)", 1, 10, 7, false, "april_farm_helper"),
                sl("april_farm_smooth", "Camera Smoothness", 1, 30, 8, false, "april_farm_helper"),
                sep(),
                cb("april_anti_afk", "Anti AFK", false),
                cb("april_mod_checker_enabled", "Mod Checker", false),
                sl("april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500, false, "april_mod_checker_enabled"),
                sep(),
                cb("april_keybinds_enabled", "Keybind Viewer", false),
                cb("april_keybinds_active_only", "Only Show Active", false, nil, "april_keybinds_enabled"),
                cb("april_keybinds_show_unbound", "Show Unbound", true, nil, "april_keybinds_enabled"),
                cb("april_keybinds_show_mode", "Show Bind Mode", true, nil, "april_keybinds_enabled"),
            },
        },
    }
end

local function build_radar()
    return {
        {
            title = "Tactical Map",
            master = "april_map_enabled",
            items = {
                kb("april_map_enabled", "Tactical Map", false),
                multi("april_ui_radar_layers", "Visible Layers", {
                    "Players", "NPCs", "Loot", "Resources", "Base Parts", "Waypoints", "Labels",
                }, { true, false, true, true, false, true, false }, nil, {
                    sync_ids = {
                        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
                        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
                        "april_map_labels",
                    },
                }),
                color("april_map_player_col", "Radar Players Color", { 1, 0.25, 0.25, 1 }),
                color("april_map_npc_col", "Radar NPCs Color", { 1, 0.55, 0.15, 1 }),
                color("april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }),
                color("april_map_world_col", "Radar Resources Color", { 0.35, 0.9, 0.35, 1 }),
                color("april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }),
                color("april_map_wp_col", "Radar Waypoints Color", { 0.3, 0.9, 1, 1 }),
                sl("april_map_zoom", "Radar Zoom Level", 0.05, 5, 1, true),
                sl("april_map_size", "Radar Size", 140, 420, 240),
                sl("april_map_icon_scale", "Radar Blip Size", 2, 6, 3),
                btn("april_map_reset_position", "Reset Radar Position"),
            },
        },
        {
            title = "Waypoints",
            master = "april_waypoints_enabled",
            items = {
                kb("april_waypoints_enabled", "Waypoints", false),
                cb("april_wp_dist", "Waypoint Show Distance", false),
                cb("april_wp_beacon", "Beacon Pillar", false),
                sl("april_wp_beacon_h", "Beacon Height", 20, 200, 90, false, "april_wp_beacon"),
                cb("april_wp_draw", "Draw Markers", false, { 0.2, 1, 0.8, 1 }),
                sl("april_wp_slot", "Waypoint Active Slot", 1, 5, 1),
                btn("april_wp_set", "Set Active Waypoint"),
                btn("april_wp_clear", "Clear Active Waypoint"),
                btn("april_wp_clear_all", "Clear All Waypoints"),
            },
        },
    }
end

local function build_config()
    local modes = { "Static", "Rainbow", "Pulse", "Wave", "Flow" }
    local elem_modes = { "Default", "Static", "Rainbow", "Pulse", "Wave", "Flow" }
    local COL = "april_ui_custom_colors"
    local ANM = "april_ui_custom_anim"
    local ELS = "april_ui_per_element"

    local appearance = {
        title = "Appearance",
        items = {
            hk("april_ui_menu_key", "Menu Toggle Key"),
            sep(),
            combo("april_ui_theme_preset", "Theme Preset", {
                "Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass",
            }, 0),
            sl("april_ui_window_opacity", "Window Opacity %", 45, 100, 86),
            sl("april_ui_panel_opacity", "Panel Opacity %", 35, 100, 72),
            sl("april_ui_border_strength", "Border Strength %", 10, 100, 58),
            combo("april_ui_corner_style", "Control Corners", { "Sharp", "Soft", "Rounded" }, 2),
            sl("april_ui_scale", "UI Scale %", 80, 125, 100),
            combo("april_ui_density", "Density", { "Compact", "Balanced", "Comfortable" }, 1),
            sl("april_ui_bg_dim", "Backdrop Dim", 0, 40, 0),
            cb("april_ui_show_cursor_dot", "Show Cursor Dot", true),
        },
    }

    local motion = {
        title = "Motion",
        items = {
            combo("april_ui_motion_profile", "Motion Profile", {
                "Subtle", "Balanced", "Expressive",
            }, 1),
            cb("april_ui_reduce_motion", "Reduce Motion", false),
            cb("april_ui_custom_anim", "Advanced Animation", false),
            combo("april_ui_accent_anim", "Accent Style", modes, 1, ANM),
            sl("april_ui_anim_speed", "Accent Speed", 1, 100, 40, false, ANM),
            cb("april_ui_menu_fade", "Ambient Fade Pulse", false, nil, ANM),
            multi("april_ui_anim_targets", "Animate", {
                "Title Bar", "Section Tops", "Sliders", "Scrollbars", "Sidebar", "Checkboxes", "Hover", "Overlay Panels",
            }, { true, true, true, true, true, true, true, true }, ANM),
            cb("april_ui_per_element", "Individual Styles", false, nil, ANM),
            sep(ANM),
            { type = "combo", id = "april_ui_style_title", label = "Title Bar", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_section", label = "Section Tops", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_slider", label = "Sliders", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_scroll", label = "Scrollbars", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_sidebar", label = "Sidebar", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_checkbox", label = "Checkboxes", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_overlay", label = "Overlay Panels", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
        },
    }

    local accent = {
        title = "Accent Colors",
        items = {
            cb("april_ui_custom_colors", "Color Options", false),
            color("april_ui_accent", "Accent", { 0.78, 0.20, 0.92, 1 }, COL),
            multi("april_ui_color_overrides", "Override Colors For", {
                "Title Bar", "Section Tops", "Sliders", "Scrollbars", "Sidebar", "Checkboxes", "Overlay Panels",
            }, {}, COL),
            color("april_ui_col_title", "Title Bar Color", { 0.78, 0.20, 0.92, 1 }, COL, 1),
            color("april_ui_col_section", "Section Top Color", { 0.78, 0.20, 0.92, 1 }, COL, 2),
            color("april_ui_col_slider", "Slider Color", { 0.78, 0.20, 0.92, 1 }, COL, 3),
            color("april_ui_col_scroll", "Scrollbar Color", { 0.78, 0.20, 0.92, 1 }, COL, 4),
            color("april_ui_col_sidebar", "Sidebar Color", { 0.78, 0.20, 0.92, 1 }, COL, 5),
            color("april_ui_col_checkbox", "Checkbox Color", { 0.78, 0.20, 0.92, 1 }, COL, 6),
            color("april_ui_col_overlay", "Overlay Panel Color", { 0.78, 0.20, 0.92, 1 }, COL, 7),
        },
    }

    local config_group = {
        title = "Config",
        items = {
            input("april_cfg_profile_name", "Profile Name", "Default"),
            sl("april_cfg_slot", "Active Slot (1-5)", 1, 5, 1),
            btn("april_cfg_save", "Save to Active Slot"),
            btn("april_cfg_load", "Load Active Slot"),
            btn("april_cfg_delete", "Delete Active Slot"),
            sep(),
            cb("april_cfg_autoload", "Autoload on Start", false),
            input("april_cfg_autoload_profile", "Autoload Profile Name", "", "april_cfg_autoload"),
            sl("april_cfg_autoload_slot", "Autoload Slot", 1, 5, 1, false, "april_cfg_autoload"),
            sep(),
            sl("april_esp_text_size", "ESP Text Size", 8, 24, 13),
            btn("april_reload_modules", "Reload Game Modules"),
        },
    }

    return { appearance, motion, accent, config_group }
end

function M.groups_for(tab_id)
    if tab_id == "aim" then return build_aim() end
    if tab_id == "visuals" then return build_visuals() end
    if tab_id == "world" then return build_world() end
    if tab_id == "guns" then return build_guns() end
    if tab_id == "misc" then return build_misc() end
    if tab_id == "radar" then return build_radar() end
    if tab_id == "config" then return build_config() end
    return {}
end

return M

end)()

-- ── ui/custom_menu.lua ──
April._mods["ui.custom_menu"] = (function()
--[[
  Gamesense-style custom menu for April.
  INSERT toggles by default (rebindable in Config -> Menu).
  Scroll: mouse wheel when Vector exposes a reader; else edge-hover (top/bottom of column).
]]

local theme = April.require("ui.gs_theme")
local gin = April.require("ui.gs_input")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local icons = April.require("ui.gs_icons")
local catalog = April.require("ui.catalog")
local state = April.require("ui.gs_state")

local M = {}

local TOGGLE_VK_DEFAULT = 0x2D

local function menu_toggle_vk()
    local vk = state.get_key("april_ui_menu_key")
    if not vk or vk == 0 then
        vk = TOGGLE_VK_DEFAULT
    end
    return vk
end
local open = true
local tab_index = 1
local win_x, win_y = 80, 80
local scroll = { left = 0, right = 0 }
local scroll_visual = { left = 0, right = 0 }
local collapsed_groups = {}

local SCROLL_EDGE = 36
local SCROLL_SPEED = 5
local WHEEL_STEP = 48
local PAGE_STEP = 90
local VK_PRIOR, VK_NEXT = 0x21, 0x22

local function screen_size()
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    return 1920, 1080
end

local function clamp_window()
    local sw, sh = screen_size()
    win_x = math.max(0, math.min(win_x, sw - theme.WINDOW_W))
    win_y = math.max(0, math.min(win_y, sh - 40))
end

local function master_on(id)
    if not id then return true end
    return state.get(id, false) == true
end

local function combo_value(id)
    if not id then return nil end
    local v = state.get(id)
    if v == nil and menu and menu.get then
        v = menu.get(id)
    end
    return tonumber(v)
end

local function color_override_on(idx)
    if not idx then return true end
    local t = state.get("april_ui_color_overrides")
    if type(t) ~= "table" then return false end
    local v = t[idx]
    if v == nil and idx >= 1 then
        v = t[idx - 1]
    end
    return v == true or v == 1
end

local function item_visible(item, group)
    if group and group.master then
        if item.id == group.master then
            return true
        end
        if not master_on(group.master) then
            return false
        end
    end
    if item.gate and not master_on(item.gate) then
        return false
    end
    if item.gate2 and not master_on(item.gate2) then
        return false
    end
    if item.gate_combo then
        local cur = combo_value(item.gate_combo)
        local want = tonumber(item.gate_combo_value) or 0
        if cur ~= want then
            return false
        end
    end
    -- Show if ANY (combo_id, value) pair matches. pair = { id, value } or { id, {v1,v2} }
    if item.gate_any_combo then
        local ok = false
        for _, pair in ipairs(item.gate_any_combo) do
            local cid = pair[1] or pair.id
            local want = pair[2] or pair.value
            local cur = combo_value(cid)
            if type(want) == "table" then
                for _, w in ipairs(want) do
                    if cur == w then ok = true; break end
                end
            elseif cur == want then
                ok = true
            end
            if ok then break end
        end
        if not ok then return false end
    end
    if item.color_override_idx and not color_override_on(item.color_override_idx) then
        return false
    end
    if item.id and not state.is_visible(item.id) then
        return false
    end
    return true
end

local function content_height(items, group)
    local h = 0
    local count = 0
    for _, item in ipairs(items) do
        if item_visible(item, group) then
            h = h + widgets.estimate_height(item)
            count = count + 1
        end
    end
    if count > 1 then
        h = h + (count - 1) * theme.ITEM_GAP
    end
    return h + 20
end

local function group_visible(group)
    local items = group.items or {}
    for _, item in ipairs(items) do
        if item_visible(item, group) then
            return true
        end
    end
    return false
end

local function draw_sidebar(x, y, h)
    widgets.rect(x, y, theme.SIDEBAR_W, h, theme.SIDEBAR, true)
    widgets.rect(x + 1, y + 1, theme.SIDEBAR_W - 2, 1, theme.GLASS_HIGHLIGHT, true)
    widgets.rect(x + theme.SIDEBAR_W - 1, y, 1, h, theme.BORDER_SOFT, true)
    widgets.rect(x + theme.SIDEBAR_W - 2, y + 8, 1, h - 16, { 0, 0, 0, 0.26 }, true)

    local tabs = catalog.TABS
    local count = #tabs
    local total_h = count * theme.TAB_H
    local start_y = y + math.max(0, (h - total_h) * 0.5)

    for i, tab in ipairs(tabs) do
        local ty = start_y + (i - 1) * theme.TAB_H
        local active = i == tab_index
        local hot = gin.hover(x + 4, ty + 2, theme.SIDEBAR_W - 9, theme.TAB_H - 8)
        local emphasis = anim.transition("tab:" .. tab.id, active or hot, 14)
        if active then
            anim.draw_tab_indicator(x + 1, ty + 8, 2, theme.TAB_H - 16)
            widgets.rect(x + 8, ty + 5, theme.SIDEBAR_W - 16, theme.TAB_H - 10,
                theme.alpha(theme.SIDEBAR_ACTIVE, 0.42 + emphasis * 0.30), true, theme.CORNER)
        elseif emphasis > 0.01 then
            -- Hover is intentionally limited to a small icon halo; active tabs
            -- use only the icon and left indicator, not a filled selection tile.
            widgets.rect(x + theme.SIDEBAR_W * 0.5 - 14, ty + theme.TAB_H * 0.5 - 14, 28, 28,
                theme.alpha(theme.HOVER, emphasis * 0.45), true, theme.CORNER)
        end

        local col = active and anim.tab_icon_color() or anim.mix(theme.TEXT_DIM, theme.TEXT, emphasis * 0.45)
        local cx = x + theme.SIDEBAR_W * 0.5
        local cy = ty + theme.TAB_H * 0.5
        icons.draw(tab.icon or tab.id, cx, cy, col)

        if gin.clicked(x, ty, theme.SIDEBAR_W, theme.TAB_H) then
            tab_index = i
            scroll.left = 0
            scroll.right = 0
            scroll_visual.left = 0
            scroll_visual.right = 0
            anim.clear_tab_progress(tab.id)
            widgets.open_combo = nil
            widgets.open_multi = nil
        end
    end
end

local function clamp_scroll(key, content_h, view_h)
    local max_scroll = math.max(0, content_h - view_h)
    if scroll[key] < 0 then scroll[key] = 0 end
    if scroll[key] > max_scroll then scroll[key] = max_scroll end
    return max_scroll
end

local function draw_scrollbar(x, y, h, content_h, scroll_key, view_h)
    view_h = view_h or h
    local max_scroll = clamp_scroll(scroll_key, content_h, view_h)
    if max_scroll <= 0 then
        scroll[scroll_key] = 0
        return
    end

    local thumb_h = math.max(28, math.min(68, h * (view_h / content_h)))
    local visual = scroll_visual[scroll_key] or scroll[scroll_key]
    visual = math.max(0, math.min(max_scroll, visual))
    local t = visual / max_scroll
    local thumb_y = y + t * (h - thumb_h)

    -- Inset pill only: no full-height accent track above the section cards.
    widgets.rect(x + 1, y, 2, h, theme.alpha(theme.SLIDER_BG, 0.28), true, 1)
    anim.draw_scroll_thumb(x, thumb_y, 3, thumb_h)
end

local function handle_column_scroll(x, y, w, h, scroll_key, content_h)
    local max_scroll = clamp_scroll(scroll_key, content_h, h)
    if max_scroll <= 0 then return end

    local hot = gin.hover(x, y, w + 14, h)
    if not hot and scroll_key == "left" then
        hot = gin.hover(gin.ui_x, y, theme.SIDEBAR_W + 8, h)
    end
    if not hot then return end

    -- Prefer real wheel when any probe delivers notches this frame.
    -- Open dropdowns consume the wheel first (see gs_widgets).
    if gin.wheel ~= 0 and not widgets.wheel_consumed then
        scroll[scroll_key] = scroll[scroll_key] - gin.wheel * WHEEL_STEP
        clamp_scroll(scroll_key, content_h, h)
        widgets.wheel_consumed = true
        return
    end

    -- Page Up / Page Down while hovering a column (documented IsKeyDown path).
    if gin.key_pressed(VK_PRIOR) then
        scroll[scroll_key] = scroll[scroll_key] - PAGE_STEP
        clamp_scroll(scroll_key, content_h, h)
        return
    end
    if gin.key_pressed(VK_NEXT) then
        scroll[scroll_key] = scroll[scroll_key] + PAGE_STEP
        clamp_scroll(scroll_key, content_h, h)
        return
    end

    -- Fallback: edge hover (only when wheel isn't available / not moving).
    if gin.my < y + SCROLL_EDGE then
        scroll[scroll_key] = scroll[scroll_key] - SCROLL_SPEED
        clamp_scroll(scroll_key, content_h, h)
    elseif gin.my > y + h - SCROLL_EDGE then
        scroll[scroll_key] = scroll[scroll_key] + SCROLL_SPEED
        clamp_scroll(scroll_key, content_h, h)
    end
end

local function draw_group_title(x, box_top, w, title, collapsed, hot)
    local hover = anim.transition("group-header:" .. tostring(title), hot, anim.motion_rate(16))
    if hover > 0.01 then
        widgets.rect(x + 3, box_top + 3, w - 6, theme.GROUP_HEADER_H - 6,
            theme.alpha(theme.HOVER, hover * 0.55), true, 0)
    end
    widgets.text(x + 12, box_top + 7, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
    widgets.text(x + w - 18, box_top + 7, collapsed and "+" or "-",
        hot and theme.TEXT_ACTIVE or theme.TEXT_DIM, theme.FONT_TITLE)
end

local function draw_group_column(groups, x, y, w, h, scroll_key)
    local pad = theme.GROUP_PAD
    local visible_groups = {}
    for _, group in ipairs(groups) do
        if group_visible(group) then
            local collapse_key = scroll_key .. ":" .. tostring(group.title)
            local collapsed = collapsed_groups[collapse_key] == true
            local expanded = anim.transition(
                "group-expand:" .. collapse_key,
                not collapsed,
                anim.motion_rate(18)
            )
            if collapsed and expanded < 0.02 then expanded = 0 end
            if not collapsed and expanded > 0.98 then expanded = 1 end
            local full_h = content_height(group.items or {}, group)
            visible_groups[#visible_groups + 1] = {
                group = group,
                key = collapse_key,
                collapsed = collapsed,
                expanded = expanded,
                full_h = full_h,
                -- Exactly zero when collapsed: prevents a second bottom strip
                -- from showing beneath the closed section header.
                inner_h = full_h * expanded,
            }
        end
    end

    local total = 0
    for _, entry in ipairs(visible_groups) do
        total = total + entry.inner_h + theme.GROUP_HEADER_H + theme.GROUP_GAP
    end

    clamp_scroll(scroll_key, total, h)

    scroll_visual[scroll_key] = anim.smooth(
        "column-scroll:" .. scroll_key,
        scroll[scroll_key],
        anim.motion_rate(18)
    )
    local gy = y + pad - scroll_visual[scroll_key]
    widgets.clip = { x = x, y = y, w = w, h = h }

    for _, entry in ipairs(visible_groups) do
        local group = entry.group
        local items = group.items or {}
        local inner_h = entry.inner_h
        local box_h = inner_h + theme.GROUP_HEADER_H

        local box_top = gy
        local box_bot = gy + box_h
        if box_bot > y and box_top < y + h then
            local vis_y = math.max(box_top, y)
            local vis_b = math.min(box_bot, y + h)
            local vis_h = vis_b - vis_y
            if vis_h > 1 then
                -- Vector already shadows primitives. Extra offset panels caused the
                -- stacked transparent borders visible on the right/bottom edges.
                widgets.rect(x, vis_y, w, vis_h, theme.PANEL, true, 0)
                widgets.rect(x, vis_y, w, vis_h, theme.BORDER_SOFT, false, 0)
                widgets.rect(x + 1, vis_y + 1, w - 2, 1, theme.GLASS_HIGHLIGHT, true)
                if box_top >= y - 2 and box_top < y + h then
                    widgets.rect(x + 1, box_top + 1, w - 2, theme.GROUP_HEADER_H - 2,
                        theme.PANEL_ALT, true, 0)
                    anim.draw_section_top(x + 1, box_top, w - 2)
                    local header_hot = gin.hover(x, box_top, w, theme.GROUP_HEADER_H)
                    draw_group_title(x, box_top, w, group.title, entry.collapsed, header_hot)
                    if gin.clicked(x, box_top, w, theme.GROUP_HEADER_H)
                        and not widgets.block_under
                        and not widgets.open_combo and not widgets.open_multi
                        and not widgets.open_color and not widgets.open_bind_mode
                    then
                        collapsed_groups[entry.key] = not entry.collapsed
                    end
                end
            end

            local iy = gy + theme.GROUP_HEADER_H + 6
            local ix = x + 7
            local iw = w - 16
            local reveal_bottom = gy + theme.GROUP_HEADER_H + inner_h
            for _, item in ipairs(items) do
                if item_visible(item, group) then
                    local est = widgets.estimate_height(item)
                    if iy >= y and iy + est <= y + h and iy + est <= reveal_bottom then
                        local used = widgets.draw_item(item, ix, iy, iw)
                        if used < 1 then used = est end
                        iy = iy + used + theme.ITEM_GAP
                    else
                        iy = iy + est + theme.ITEM_GAP
                    end
                end
            end
        end

        gy = gy + box_h + theme.GROUP_GAP
    end

    widgets.clip = nil
    handle_column_scroll(x, y, w, h, scroll_key, total)
    draw_scrollbar(x + w - 5, y + pad, h - pad * 2, total, scroll_key, h)
end

local function split_groups(groups, tab_id)
    -- Aim: left = Aimbot + Ragebot, right = Silent + Bullet
    if tab_id == "aim" and #groups >= 4 then
        return { groups[1], groups[2] }, { groups[3], groups[4] }
    end
    if tab_id == "aim" and #groups >= 3 then
        return { groups[1] }, { groups[2], groups[3] }
    end
    if tab_id == "config" and #groups >= 4 then
        return { groups[1], groups[2], groups[3] }, { groups[4] }
    end
    if tab_id == "config" and #groups >= 2 then
        return { groups[1] }, { groups[2] }
    end
    if #groups == 2 then
        return { groups[1] }, { groups[2] }
    end
    local left, right = {}, {}
    for i, g in ipairs(groups) do
        if i % 2 == 1 then
            left[#left + 1] = g
        else
            right[#right + 1] = g
        end
    end
    return left, right
end

function M.init()
    state.define("april_ui_theme_preset", 0)
    state.define("april_ui_window_opacity", 86)
    state.define("april_ui_panel_opacity", 72)
    state.define("april_ui_border_strength", 58)
    state.define("april_ui_corner_style", 2)
    state.define("april_ui_scale", 100)
    state.define("april_ui_density", 1)
    state.define("april_ui_motion_profile", 1)
    state.define("april_ui_reduce_motion", false)
    state.define("april_ui_custom_colors", false)
    state.define("april_ui_custom_anim", false)
    state.define("april_ui_per_element", false)
    state.define("april_ui_show_cursor_dot", true)
    state.define("april_ui_accent", theme.ACCENT)
    state.define("april_ui_accent_anim", 1)
    state.define("april_ui_anim_speed", 40)
    state.define("april_ui_bg_dim", 0)
    state.define("april_ui_menu_fade", false)
    state.define("april_ui_anim_targets", {
        true, true, true, true, true, true, true, true,
    })
    state.define("april_ui_color_overrides", {})
    state.define("april_ui_style_title", 0)
    state.define("april_ui_style_section", 0)
    state.define("april_ui_style_slider", 0)
    state.define("april_ui_style_scroll", 0)
    state.define("april_ui_style_sidebar", 0)
    state.define("april_ui_style_checkbox", 0)
    state.define("april_ui_style_overlay", 0)
    state.define_color("april_ui_col_title", theme.ACCENT)
    state.define_color("april_ui_col_section", theme.ACCENT)
    state.define_color("april_ui_col_slider", theme.ACCENT)
    state.define_color("april_ui_col_scroll", theme.ACCENT)
    state.define_color("april_ui_col_sidebar", theme.ACCENT)
    state.define_color("april_ui_col_checkbox", theme.ACCENT)
    state.define_color("april_ui_col_overlay", theme.ACCENT)
    if state.get_key("april_ui_menu_key") == 0 then
        state.set_key("april_ui_menu_key", TOGGLE_VK_DEFAULT)
    end
    local sw, sh = screen_size()
    theme.sync()
    local default_x = math.floor((sw - theme.WINDOW_W) * 0.5)
    local default_y = math.floor((sh - theme.WINDOW_H) * 0.3)
    state.define("april_ui_window_x", default_x)
    state.define("april_ui_window_y", default_y)
    win_x = tonumber(state.get("april_ui_window_x", default_x)) or default_x
    win_y = tonumber(state.get("april_ui_window_y", default_y)) or default_y
    clamp_window()
end

function M.is_open()
    return open
end

function M.draw()
    if not draw then return end

    gin.begin_frame()
    anim.sync_theme()
    widgets.begin_popups()

    if gin.key_pressed(menu_toggle_vk()) and not widgets.listening_key
        and not widgets.active_input and not widgets.active_slider_input then
        open = not open
        gin.set_menu_open(open)
    end

    widgets.tick_key_listen()
    widgets.tick_slider_input()
    widgets.tick_text_input()

    local open_progress = anim.menu_open_progress(open)
    if not open and open_progress <= 0.015 then
        if gin._menu_open or gin._game_cursor_hidden then
            gin.set_menu_open(false)
        end
        return
    end
    if not open then
        widgets.block_under = true
    end

    gin.set_menu_open(open)
    theme.apply_global_alpha(open_progress)
    if not widgets.dragging_window then
        win_x = tonumber(state.get("april_ui_window_x", win_x)) or win_x
        win_y = tonumber(state.get("april_ui_window_y", win_y)) or win_y
    end
    clamp_window()

    local x = win_x
    local y = win_y + math.floor((1 - open_progress) * 10 * (theme.SCALE or 1))
    local w, h = theme.WINDOW_W, theme.WINDOW_H
    gin.set_ui_rect(x, y, w, h)

    -- Faux glass: backdrop dim + layered translucent depth (Vector has no blur API).
    local sw, sh = screen_size()
    local backdrop = math.max(0, math.min(40, tonumber(state.get("april_ui_bg_dim", 0)) or 0))
    if backdrop > 0 then
        widgets.rect(0, 0, sw, sh, { 0, 0, 0, backdrop * 0.008 * open_progress }, true)
    end

    -- Frame
    local fade = anim.menu_fade()
    local panel_bg = anim.panel_bg()
    -- A single glass surface avoids doubled translucent borders. Vector adds its
    -- own primitive shadow pass, so manual full-window shadows are unnecessary.
    widgets.rect(x, y, w, h, theme.alpha(panel_bg, (panel_bg[4] or 1) * fade), true, 0)
    widgets.rect(x, y, w, h, theme.BORDER, false, 0)
    widgets.rect(x + 1, y + 1, w - 2, 1, theme.GLASS_HIGHLIGHT, true)
    widgets.rect(x + 1, y + 1, w - 2, 1, theme.BORDER_HOT, true)
    anim.draw_title_bar(x + 1, y + 1, w - 2, 2)

    local title_h = math.max(28, math.floor(28 * (theme.SCALE or 1)))
    widgets.rect(x + 1, y + 3, w - 2, title_h, theme.BG_INNER, true, 0)
    widgets.rect(x + 1, y + title_h + 3, w - 2, 1, theme.BORDER_SOFT, true)
    local tab = catalog.TABS[tab_index]
    widgets.text(x + 12, y + 10, "APRIL", theme.TEXT_ACTIVE, theme.FONT_TITLE)
    widgets.text(x + 55, y + 10, "/  " .. (tab and tab.title or ""), theme.TEXT_TITLE, theme.FONT_TITLE)

    if gin.lmb_click and gin.hover(x, y, w - theme.SIDEBAR_W, title_h + 5)
        and not widgets.active_slider and not widgets.active_slider_input and not widgets.listening_key
        and not widgets.active_input
        and not widgets.block_under
        and not widgets.open_combo and not widgets.open_multi and not widgets.open_color
        and not widgets.open_bind_mode then
        widgets.dragging_window = true
        widgets.drag_offset_x = gin.mx - win_x
        widgets.drag_offset_y = gin.my - win_y
    end
    if widgets.dragging_window then
        if gin.lmb then
            win_x = gin.mx - widgets.drag_offset_x
            win_y = gin.my - widgets.drag_offset_y
            clamp_window()
            state.set("april_ui_window_x", math.floor(win_x))
            state.set("april_ui_window_y", math.floor(win_y))
        else
            widgets.dragging_window = false
        end
    end

    local body_y = y + title_h + 6
    local body_h = h - title_h - 10

    draw_sidebar(x + 1, body_y, body_h)

    local content_x = x + theme.SIDEBAR_W + 12
    local content_w = w - theme.SIDEBAR_W - 30
    local col_w = math.floor((content_w - 16) * 0.5)
    local groups = catalog.groups_for(tab and tab.id or "aim")
    local left_groups, right_groups = split_groups(groups, tab and tab.id or "aim")
    local tab_progress = anim.tab_progress(tab and tab.id or "aim")
    local tab_shift = math.floor((1 - tab_progress) * 8 * (theme.SCALE or 1))

    draw_group_column(left_groups, content_x + tab_shift, body_y + 2, col_w, body_h - 4, "left")
    draw_group_column(right_groups, content_x + col_w + 12 + tab_shift, body_y + 2, col_w, body_h - 4, "right")

    widgets.end_tooltip_frame()

    -- Floating popups above all sections
    widgets.draw_color_overlay()
    widgets.draw_bind_mode_overlay()
    widgets.draw_tooltip_overlay()
    widgets.end_popups()

    if open then
        gin.draw_cursor()
    end
end

return M

end)()

-- ── menu/tabs.lua ──
April._mods["menu.tabs"] = (function()
local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local bootstrap = April.require("game.bootstrap")

local M = {}

M.features = {}
M._menu_registered = false

M.FEATURE_ORDER = {
    "features.combat.camera_aimbot",
    "features.combat.aimbot",
    "features.combat.ragebot",
    "features.combat.body_peek",
    "features.combat.gun_mods",
    "features.visuals.target_overlay",
    "features.visuals.target_visuals",
    "features.visuals.player_esp",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.tactical_map",
    "features.radar.waypoints",
    "features.movement.exploits",
    "features.movement.desync",
    "features.movement.anti_aim",
    "features.movement.fake_duck",
    "features.movement.fling",
    "features.combat.perfect_farm",
    "features.utility.mod_checker",
    "features.utility.anti_afk",
    "features.utility.keybind_viewer",
    "features.utility.config",
}

function M.register_all()
    if M._menu_registered then return end

    menu_util.ensure_groups()

    M.features = {}
    local registered = 0

    for _, path in ipairs(M.FEATURE_ORDER) do
        local feat = April.require(path)
        table.insert(M.features, feat)
        if feat.register_menu then
            local ok, err = pcall(feat.register_menu)
            if ok then
                registered = registered + 1
            else
                debug.error_once("menu:" .. path, err)
            end
        end
    end

    M._menu_registered = true
    if April and April.debug then
        debug.log("Menu: " .. registered .. " sections")
    end

    pcall(function()
        local mod = April.require("features.utility.mod_checker")
        if mod.init then mod.init() end
    end)
end

function M.setup_scans()
    local settings = April.require("core.settings")
    local cache = April.require("core.cache")
    local iscan = April.require("core.incremental_scan")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    local npc_esp = April.require("features.world.npc_esp")

    iscan.configure({ budget_ms = 6, items_per_step = 18 })

    local SCAN_MS = cache.WORKSPACE_SCAN_MS or 1000

    local function map_on(layer)
        return function()
            if not settings.enabled("april_map_enabled") then return false end
            return settings.enabled("april_map_show_" .. layer)
        end
    end

    iscan.register("world", SCAN_MS, function()
        return settings.enabled("april_world_enabled") or map_on("world")()
    end, world_esp.begin_static_scan, world_esp.step_static_scan, world_esp.complete_static_scan, 0)

    iscan.register("world_dynamic", SCAN_MS, function()
        if not settings.enabled("april_world_enabled") then return false end
        return settings.enabled("april_deer")
            or settings.enabled("april_boar")
            or settings.enabled("april_wolf")
    end, world_esp.begin_dynamic_scan, world_esp.step_dynamic_scan, world_esp.complete_dynamic_scan, 120)

    iscan.register("loot", SCAN_MS, function()
        return settings.enabled("april_loot_enabled") or map_on("loot")()
    end, loot_esp.begin_static_scan, loot_esp.step_static_scan, loot_esp.complete_static_scan, 240)

    iscan.register("loot_drops", SCAN_MS, function()
        if settings.enabled("april_loot_enabled") then
            return settings.enabled("april_dropped_item")
        end
        return map_on("loot")()
    end, loot_esp.begin_drops_scan, loot_esp.step_drops_scan, loot_esp.complete_drops_scan, 360)

    iscan.register("base", SCAN_MS, function()
        return settings.enabled("april_base_enabled") or map_on("base")()
    end, base_esp.begin_scan, base_esp.step_scan, base_esp.complete_scan, 480)

    iscan.register("npcs", SCAN_MS, function()
        if settings.enabled("april_npc_enabled") then return true end
        return map_on("npcs")()
    end, npc_esp.begin_scan, npc_esp.step_scan, npc_esp.complete_scan, 600)
end

function M.update(dt)
    bootstrap.tick()

    local weapons = April.require("game.weapons")
    weapons.tick()

    local runservice = April.require("core.runservice")
    runservice.dispatch(dt)

    April.require("core.incremental_scan").tick()
    for i, feat in ipairs(M.features) do
        if feat.update then
            debug.guard("update:" .. i, feat.update, dt)
        end
    end
end

function M.draw()
    for i, feat in ipairs(M.features) do
        if feat.draw then
            debug.guard("draw:" .. i, feat.draw)
        end
    end
end

function M.init()
    local env = April.require("core.env")
    local ok, missing = env.require_apis({ "draw", "utility", "entity", "game" })
    if not ok then
        debug.error_once("init:apis", "Missing required API: " .. tostring(missing))
        return false
    end

    -- Custom UI backend: feature register_menu() writes into gs_state, not Vector menu.
    pcall(function()
        April.require("ui.menu_shim").install()
    end)

    M.register_all()
    M.setup_scans()
    M.setup_player_hooks()

    pcall(function()
        April.require("features.utility.config").try_autoload()
    end)

    return true
end

function M.setup_player_hooks()
    local mod = April.require("features.utility.mod_checker")

    _G.on_player_added = function(p)
        debug.guard("on_player_added", mod.on_player_added, p)
    end

    _G.on_player_removed = function(p)
        debug.guard("on_player_removed", mod.on_player_removed, p)
    end
end

return M

end)()

-- ── app.lua ──
April._mods["app"] = (function()
local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")
local custom_menu = April.require("ui.custom_menu")

local M = {}
local initialized = false

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    if initialized then
        pcall(custom_menu.init)
    end
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.tick_frame()

    pcall(function()
        April.require("core.feature_bind").tick()
    end)
    pcall(function()
        April.require("core.aim_key").tick("april_aim_key", "april_aim_key_mode")
    end)

    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end

    debug.guard("tabs.update", tabs.update, dt)
    debug.guard("overlay_theme.sync", April.require("core.overlay_theme").sync)
    debug.guard("tabs.draw", tabs.draw)
    debug.guard("notify.draw", notify.draw)
    debug.guard("custom_menu.draw", custom_menu.draw)
end

return M

end)()

-- Install custom UI menu backend before any register_menu() calls.
do
    April.require("ui.menu_shim").install()
    April.require("menu.tabs").register_all()
end

April._init_ok = false

local ok, err = pcall(function()
    local debug = April.require("core.debug")
    local caps = April.require("core.capabilities")
    local app = April.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false — features disabled")
        return
    end

    April.require("core.movement_ctrl").install()
    April.require("features.movement.fling").install()
    April.require("features.movement.anti_aim").install()
    April.require("features.movement.fake_duck").install()

    April._init_ok = true
    print("[April] v" .. tostring(April.version) .. " — custom UI (INSERT to toggle)")

    local c = caps.probe()
    if c.fallen_gc then
        local gc = April.require("game.gc_weapon_mods")
        gc.probe_on_load()
    end

    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
end

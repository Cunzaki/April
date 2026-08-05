local M = {}
local asset_urls = April.require("game.asset_urls")
local DIALOGUE_ROOT = asset_urls.CDN_BASE .. "/anime/april/"

local H = {
    id = "april",
    name = "April",
    aspect = 346 / 400,
    mouth_x = 0.56,
    mouth_y = 0.30,
    expressions = {
        neutral = "normal", smile = "smile", happy = "happy", laugh = "hah",
        smug = "angrysmile", pout = "pout", worried = "worried", fear = "fear",
        sad = "sad", disgusted = "disgusted", evil = "evil", surprised = "oh",
    },
    dialogue = {},
}

function H.sprite_file(expression)
    return (H.expressions[expression] or H.expressions.neutral) .. ".png"
end

function H.url(expression)
    local urls = H.urls(expression)
    return urls[1]
end

function H.urls(expression)
    return asset_urls.anime_sprite_urls("april", H.sprite_file(expression))
end

local FALLBACK = {
    "greeting|roasty|smug|Oh, you enabled me? Try not to embarrass us.",
    "greeting|supportive|smile|April online. I'll keep an eye on you.",
    "death|roasty|laugh|You suck, lol. Want to try that again?",
    "death|supportive|sad|That one hurt. Reset and take it slower.",
    "respawn|roasty|smug|Back already? Try keeping this body for a minute.",
    "respawn|supportive|happy|You're back. New life, clean slate.",
    "downed|roasty|laugh|Floor inspection going well?",
    "downed|supportive|worried|You're downed. Get behind cover and call for help.",
    "revived|roasty|smug|Someone actually picked you up. Be grateful.",
    "revived|supportive|happy|You're up! Heal before re-engaging.",
    "low_health|roasty|pout|One sneeze and you're back at respawn.",
    "low_health|supportive|worried|Low health. Disengage and heal now.",
    "recovered|roasty|smug|Health restored. Common sense still pending.",
    "recovered|supportive|happy|Health recovered. You're ready again.",
    "safe_enter|roasty|smug|Safe zone reached. Even you should survive in here.",
    "safe_enter|supportive|happy|Safe zone reached. Take a moment to reset.",
    "safe_leave|roasty|evil|Leaving safety? This should be entertaining.",
    "safe_leave|supportive|worried|Leaving the safe zone. Check your route.",
}

local function add_line(line)
    local event, tone, expression, text =
        tostring(line):match("^([^|]+)|([^|]+)|([^|]+)|(.+)$")
    if not event then return end
    H.dialogue[event] = H.dialogue[event] or {}
    H.dialogue[event][tone] = H.dialogue[event][tone] or {}
    local pool = H.dialogue[event][tone]
    pool[#pool + 1] = { expression, text }
end

local function load_lines(body)
    H.dialogue = {}
    for line in tostring(body or ""):gmatch("[^\r\n]+") do add_line(line) end
end

load_lines(table.concat(FALLBACK, "\n"))

function M.load_remote()
    local fn = utility and (utility.http_get or utility.HttpGet)
    if type(fn) ~= "function" then return false end
    local ok, body, status = pcall(fn, DIALOGUE_ROOT .. "dialogue.txt")
    if not ok or type(body) ~= "string" or #body < 100 or tonumber(status) ~= 200 then
        return false
    end
    load_lines(body)
    return true
end

M.characters = { H }
M.character_labels = { H.name }

function M.character(index)
    return M.characters[math.floor(tonumber(index) or 0) + 1] or H
end

return M

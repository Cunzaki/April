/**
 * Regenerates dialogue tables for anime_announcer_data.lua from
 * assets/anime/april/dialogue.txt + dialogue_ru.txt
 * Supports: event|tone|expression|text
 *        or event|tone|expression|rarity|text
 */
import fs from "fs";

const dataPath = "src/game/anime_announcer_data.lua";
const enPath = "assets/anime/april/dialogue.txt";
const ruPath = "assets/anime/april/dialogue_ru.txt";

function luaString(s) {
  return `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

function asLuaArray(lines, name) {
  const body = lines.map((l) => `    ${luaString(l)},`).join("\n");
  return `local ${name} = {\n${body}\n}\n`;
}

const en = fs.readFileSync(enPath, "utf8").trim().split(/\r?\n/).filter(Boolean);
const ru = fs.readFileSync(ruPath, "utf8").trim().split(/\r?\n/).filter(Boolean);
if (en.length !== ru.length) {
  console.warn("line count mismatch en", en.length, "ru", ru.length);
}

const src = fs.readFileSync(dataPath, "utf8");
let start = src.indexOf("-- Offline + bundled dialogue.");
if (start < 0) start = src.indexOf("-- Tiny offline seed.");
const endMarkers = ["M.characters = { H, V }", "M.characters = { H }"];
let end = -1;
for (const m of endMarkers) {
  end = src.indexOf(m);
  if (end >= 0) break;
}
if (start < 0 || end < 0) {
  console.error("markers not found");
  process.exit(1);
}

const middle = `-- Offline + bundled dialogue. Remote refresh optional.
${asLuaArray(en, "DIALOGUE_EN")}
${asLuaArray(ru, "DIALOGUE_RU")}

local function normalize_rarity(r)
    r = tostring(r or "common"):lower()
    if r == "uncommon" or r == "rare" or r == "mythic" or r == "common" then
        return r
    end
    return "common"
end

local function add_line(target, line)
    line = tostring(line or "")
    local event, tone, expression, rarity, text =
        line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.+)$")
    if not (event and (rarity == "common" or rarity == "uncommon" or rarity == "rare" or rarity == "mythic")) then
        event, tone, expression, text = line:match("^([^|]+)|([^|]+)|([^|]+)|(.+)$")
        rarity = "common"
    end
    if not event or not text then return end
    rarity = normalize_rarity(rarity)
    target[event] = target[event] or {}
    target[event][tone] = target[event][tone] or {}
    local pool = target[event][tone]
    pool[#pool + 1] = { expression, text, rarity }
end

local function load_lines(target, body)
    for k in pairs(target) do target[k] = nil end
    for line in tostring(body or ""):gmatch("[^\\r\\n]+") do
        add_line(target, line)
    end
end

H.dialogue_en = {}
H.dialogue_ru = {}
load_lines(H.dialogue_en, table.concat(DIALOGUE_EN, "\\n"))
load_lines(H.dialogue_ru, table.concat(DIALOGUE_RU, "\\n"))
-- Compat alias (English).
H.dialogue = H.dialogue_en
-- Vector shares April's line pools (same events / tones / wording).
V.dialogue_en = H.dialogue_en
V.dialogue_ru = H.dialogue_ru
V.dialogue = H.dialogue_en

local function fetch_dialogue(file_name)
    local fn = utility and (utility.http_get or utility.HttpGet)
    if type(fn) ~= "function" then return nil end
    local urls = {
        DIALOGUE_ROOT .. file_name,
        asset_urls.JSDELIVR_BASE .. "/anime/april/" .. file_name,
    }
    for _, url in ipairs(urls) do
        local ok, body, status = pcall(fn, url)
        if ok and type(body) == "string" and #body >= 100 then
            if status == nil or tonumber(status) == 200 then
                return body
            end
        end
    end
    return nil
end

function M.load_remote()
    local en_body = fetch_dialogue("dialogue.txt")
    if en_body then
        load_lines(H.dialogue_en, en_body)
        H.dialogue = H.dialogue_en
        V.dialogue_en = H.dialogue_en
        V.dialogue = H.dialogue_en
    end
    local ru_body = fetch_dialogue("dialogue_ru.txt")
    if ru_body then
        load_lines(H.dialogue_ru, ru_body)
        V.dialogue_ru = H.dialogue_ru
    end
    return en_body ~= nil or ru_body ~= nil
end

function M.dialogue_for(character)
    character = character or H
    local ru = false
    pcall(function()
        ru = April.require("ui.i18n").is_ru() == true
    end)
    if ru and character.dialogue_ru and next(character.dialogue_ru) ~= nil then
        return character.dialogue_ru
    end
    return character.dialogue_en or character.dialogue or H.dialogue_en
end

`;

const out = src.slice(0, start) + middle + src.slice(end);
fs.writeFileSync(dataPath, out);
console.log("patched", dataPath, "en", en.length, "ru", ru.length);

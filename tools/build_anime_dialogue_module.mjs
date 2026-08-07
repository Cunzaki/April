/**
 * Regenerates dialogue tables for anime_announcer_data.lua from
 * assets/anime/april/dialogue.txt + dialogue_ru.txt
 * (keeps sprite/header logic intact by patching only the dialogue section).
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

// Replace from FALLBACK through load_remote return with dual-language loader.
const start = src.indexOf("-- Tiny offline seed.");
const end = src.indexOf("M.characters = { H }");
if (start < 0 || end < 0) {
  console.error("markers not found");
  process.exit(1);
}

const middle = `-- Offline + bundled dialogue. Remote refresh optional.
${asLuaArray(en, "DIALOGUE_EN")}
${asLuaArray(ru, "DIALOGUE_RU")}

local function add_line(target, line)
    local event, tone, expression, text =
        tostring(line):match("^([^|]+)|([^|]+)|([^|]+)|(.+)$")
    if not event then return end
    target[event] = target[event] or {}
    target[event][tone] = target[event][tone] or {}
    local pool = target[event][tone]
    pool[#pool + 1] = { expression, text }
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
    end
    local ru_body = fetch_dialogue("dialogue_ru.txt")
    if ru_body then
        load_lines(H.dialogue_ru, ru_body)
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

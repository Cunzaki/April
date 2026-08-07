/**
 * Convert Cyrillic string values in src/ui/i18n.lua to Latin transliteration
 * so Vector's built-in draw font can render them (no Cyrillic glyphs).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const FILE = path.join(ROOT, "src/ui/i18n.lua");

const MAP = {
  А: "A", Б: "B", В: "V", Г: "G", Д: "D", Е: "E", Ё: "E", Ж: "Zh", З: "Z",
  И: "I", Й: "Y", К: "K", Л: "L", М: "M", Н: "N", О: "O", П: "P", Р: "R",
  С: "S", Т: "T", У: "U", Ф: "F", Х: "H", Ц: "Ts", Ч: "Ch", Ш: "Sh", Щ: "Sch",
  Ъ: "", Ы: "Y", Ь: "", Э: "E", Ю: "Yu", Я: "Ya",
  а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "e", ж: "zh", з: "z",
  и: "i", й: "y", к: "k", л: "l", м: "m", н: "n", о: "o", п: "p", р: "r",
  с: "s", т: "t", у: "u", ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh", щ: "sch",
  ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya",
};

function translit(s) {
  let out = "";
  for (const ch of s) {
    out += MAP[ch] !== undefined ? MAP[ch] : ch;
  }
  return out;
}

let src = fs.readFileSync(FILE, "utf8");
let count = 0;

// Transliterate Lua string literals that contain Cyrillic (values only).
// Match "..." strings; skip keys that are English (left side of =).
src = src.replace(/"((?:\\.|[^"\\])*)"/g, (full, inner) => {
  if (!/[А-Яа-яЁё]/.test(inner)) return full;
  count += 1;
  const converted = translit(inner.replace(/\\"/g, '"')).replace(/"/g, '\\"');
  return `"${converted}"`;
});

// Also transliterate modes() hardcoded Cyrillic if any remain as long strings
src = src.replace(
  /return \{ "Всегда", "Удержание", "Переключение" \}/g,
  'return { "Vsegda", "Uderzhanie", "Pereklyuchenie" }'
);

fs.writeFileSync(FILE, src, "utf8");
console.log("transliterated", count, "string literals");

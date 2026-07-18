#!/usr/bin/env node
/**
 * Builds april_ui.lua — Gamesense custom UI demo only.
 * Does not include features, Vector menu registration, or the main April script.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "src");
const OUT = path.join(ROOT, "april_ui.lua");

const ORDER = [
  "game/esp_maps.lua",
  "ui/combat_labels.lua",
  "ui/gs_theme.lua",
  "ui/gs_input.lua",
  "ui/gs_state.lua",
  "ui/gs_widgets.lua",
  "ui/catalog.lua",
  "ui/custom_menu.lua",
  "ui/standalone_app.lua",
];

const header = `--[[
    April Fallen — Custom UI demo (Gamesense placeholder)
    Standalone: does NOT load april.lua features or Vector menu tabs.
    Toggle: INSERT
    Built: ${new Date().toISOString()}
]]

April = {
    version = "ui-0.1.0",
    debug = false,
    _mods = {},
    bundled = true,
    ui_only = true,
}

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April UI] bundled module missing: " .. path)
    end
    return mod
end

`;

const footer = `
do
    local ok, err = pcall(function()
        local app = April.require("ui.standalone_app")
        if not app.init() then
            print("[April UI] init failed")
            return
        end

        function on_frame()
            app.on_frame()
        end
    end)

    if not ok then
        print("[April UI] Fatal: " .. tostring(err))
    end
end
`;

let body = "";
for (const rel of ORDER) {
  const full = path.join(SRC, rel);
  if (!fs.existsSync(full)) {
    console.error("Missing:", rel);
    process.exit(1);
  }
  const modPath = rel.replace(/\.lua$/, "").replace(/\//g, ".");
  const src = fs.readFileSync(full, "utf8");
  body += `\n-- ── ${rel} ──\n`;
  body += `April._mods["${modPath}"] = (function()\n${src}\nend)()\n`;
}

fs.writeFileSync(OUT, header + body + footer);
console.log("Built", path.relative(ROOT, OUT), `(${(fs.statSync(OUT).size / 1024).toFixed(1)} KB)`);

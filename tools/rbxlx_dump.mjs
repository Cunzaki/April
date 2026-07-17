#!/usr/bin/env node
/**
 * Full rbxlx decompiler / dumper
 * Parses Roblox XML place files and writes an organized dump folder.
 */

import fs from "fs";
import path from "path";
import { createRequire } from "module";

const require = createRequire(import.meta.url);

const INPUT = process.argv[2];
const OUT_DIR = process.argv[3] || path.join(process.cwd(), "dump");

if (!INPUT) {
  console.error("Usage: node rbxlx_dump.mjs <file.rbxlx> [output_dir]");
  process.exit(1);
}

const SCRIPT_CLASSES = new Set(["Script", "LocalScript", "ModuleScript"]);
const REMOTE_CLASSES = new Set([
  "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
]);
const VALUE_CLASSES = new Set([
  "IntValue", "NumberValue", "BoolValue", "StringValue", "ObjectValue",
  "Vector3Value", "CFrameValue", "BrickColorValue", "Color3Value", "RayValue",
]);

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function sanitizePath(str) {
  return str
    .replace(/[<>:"|?*]/g, "_")
    .replace(/\s+/g, "_")
    .replace(/_+/g, "_")
    .slice(0, 180);
}

function decodeAttributesSerialize(b64) {
  if (!b64) return null;
  try {
    const buf = Buffer.from(b64, "base64");
    const out = {};
    let i = 0;
    while (i < buf.length) {
      if (i + 1 >= buf.length) break;
      const nameLen = buf.readUInt16LE(i);
      i += 2;
      if (i + nameLen > buf.length) break;
      const name = buf.toString("utf8", i, i + nameLen);
      i += nameLen;
      if (i >= buf.length) break;
      const type = buf[i++];
      if (type === 0x02 && i + 4 <= buf.length) {
        out[name] = buf.readFloatLE(i);
        i += 4;
      } else if (type === 0x01 && i < buf.length) {
        out[name] = buf[i++] !== 0;
      } else if (type === 0x03) {
        if (i + 2 > buf.length) break;
        const slen = buf.readUInt16LE(i);
        i += 2;
        out[name] = buf.toString("utf8", i, i + slen);
        i += slen;
      } else {
        break;
      }
    }
    return Object.keys(out).length ? out : null;
  } catch {
    return { _raw_base64: b64 };
  }
}

function propValueToString(type, text, attrs) {
  const t = (text || "").trim();
  if (!t && attrs) {
    if (type === "Vector3" || type === "Vector2") {
      const parts = ["X", "Y", "Z", "W"]
        .filter((k) => attrs[k] !== undefined)
        .map((k) => `${k}=${attrs[k]}`);
      return parts.join(", ");
    }
    if (type === "CoordinateFrame" || type === "CFrame") {
      return Object.entries(attrs)
        .map(([k, v]) => `${k}=${v}`)
        .join(", ");
    }
    if (type === "Color3") {
      return `R=${attrs.R || attrs.r || 0}, G=${attrs.G || attrs.g || 0}, B=${attrs.B || attrs.b || 0}`;
    }
  }
  return t;
}

function loadSax() {
  try {
    return require("sax");
  } catch {
    console.error("Missing dependency 'sax'. Run: npm install sax");
    process.exit(1);
  }
}

async function main() {
  const sax = loadSax();
  const stat = fs.statSync(INPUT);
  const baseName = path.basename(INPUT);

  ensureDir(OUT_DIR);
  ensureDir(path.join(OUT_DIR, "scripts"));

  const files = {
    hierarchy: fs.createWriteStream(path.join(OUT_DIR, "hierarchy.txt")),
    index: fs.createWriteStream(path.join(OUT_DIR, "index.tsv")),
    instances: fs.createWriteStream(path.join(OUT_DIR, "instances.jsonl")),
    scriptsIndex: fs.createWriteStream(path.join(OUT_DIR, "scripts", "_index.tsv")),
    remotes: fs.createWriteStream(path.join(OUT_DIR, "remotes.txt")),
    bindables: fs.createWriteStream(path.join(OUT_DIR, "bindables.txt")),
    values: fs.createWriteStream(path.join(OUT_DIR, "values.txt")),
    modules: fs.createWriteStream(path.join(OUT_DIR, "modules.txt")),
    tools: fs.createWriteStream(path.join(OUT_DIR, "tools.txt")),
    sounds: fs.createWriteStream(path.join(OUT_DIR, "sounds.txt")),
    prompts: fs.createWriteStream(path.join(OUT_DIR, "proximity_prompts.txt")),
    guis: fs.createWriteStream(path.join(OUT_DIR, "gui_tree.txt")),
    attributes: fs.createWriteStream(path.join(OUT_DIR, "attributes.jsonl")),
    propertiesByClass: {},
  };

  files.index.write("referent\tpath\tclass\tname\tparent_referent\n");

  const classStats = {};
  const serviceRoots = [];
  let itemCount = 0;
  let scriptCount = 0;
  let usedScriptNames = new Set();

  const stack = [];
  let inProperties = false;
  let propDepth = 0;
  let currentProp = null;
  let propText = "";
  let propAttrs = null;
  let currentItem = null;

  function bumpClass(cls) {
    classStats[cls] = (classStats[cls] || 0) + 1;
  }

  function getPathParts() {
    return stack.map((n) => n.name || n.class);
  }

  function scriptFilePath(itemPath, className, referent) {
    const rel = sanitizePath(itemPath.join(".")) || `ref_${referent}`;
    let file = path.join(OUT_DIR, "scripts", `${rel}.${className}.lua`);
    let n = 1;
    while (usedScriptNames.has(file)) {
      file = path.join(OUT_DIR, "scripts", `${rel}.${className}.${n}.lua`);
      n++;
    }
    usedScriptNames.add(file);
    return file;
  }

  function finalizeItem(item) {
    itemCount++;
    bumpClass(item.class);

    const itemPath = getPathParts();
    const parent = stack.length > 1 ? stack[stack.length - 2] : null;
    const parentRef = parent ? parent.referent : "";
    const indent = "  ".repeat(Math.max(0, stack.length - 1));

    files.hierarchy.write(
      `${indent}[${item.class}] ${item.name || "(unnamed)"} (ref ${item.referent})\n`
    );

    files.index.write(
      `${item.referent}\t${itemPath.join(".")}\t${item.class}\t${item.name || ""}\t${parentRef}\n`
    );

  const instRecord = {
      referent: item.referent,
      class: item.class,
      name: item.name,
      path: itemPath.join("."),
      parent_referent: parentRef || null,
      properties: item.properties,
      attributes: item.attributes,
    };
    files.instances.write(JSON.stringify(instRecord) + "\n");

    if (!files.propertiesByClass[item.class]) {
      files.propertiesByClass[item.class] = fs.createWriteStream(
        path.join(OUT_DIR, "properties", `${sanitizePath(item.class)}.jsonl`)
      );
      ensureDir(path.join(OUT_DIR, "properties"));
    }
    files.propertiesByClass[item.class].write(JSON.stringify(instRecord) + "\n");

    if (item.attributes) {
      files.attributes.write(
        JSON.stringify({
          referent: item.referent,
          path: itemPath.join("."),
          class: item.class,
          attributes: item.attributes,
        }) + "\n"
      );
    }

    if (stack.length === 1) {
      serviceRoots.push({ class: item.class, name: item.name, referent: item.referent });
    }

    if (SCRIPT_CLASSES.has(item.class) && item.source != null) {
      scriptCount++;
      const relPath = itemPath.join(".");
      const outFile = scriptFilePath(itemPath, item.class, item.referent);
      const relOut = path.relative(OUT_DIR, outFile);
      fs.writeFileSync(outFile, item.source, "utf8");
      files.scriptsIndex.write(
        `${item.referent}\t${item.class}\t${relPath}\t${relOut}\t${item.source.length}\n`
      );
      if (item.class === "ModuleScript") {
        files.modules.write(`${relPath}\t${relOut}\n`);
      }
    }

    if (REMOTE_CLASSES.has(item.class)) {
      const line = `${item.class}\t${itemPath.join(".")}\tref=${item.referent}\n`;
      if (item.class.includes("Bindable")) files.bindables.write(line);
      else files.remotes.write(line);
    }

    if (VALUE_CLASSES.has(item.class)) {
      const val = item.properties.Value ?? item.properties.value;
      files.values.write(
        `${item.class}\t${itemPath.join(".")}\tValue=${JSON.stringify(val)}\n`
      );
    }

    if (item.class === "Tool") {
      files.tools.write(`${itemPath.join(".")}\tref=${item.referent}\n`);
    }
    if (item.class === "Sound") {
      const sid = item.properties.SoundId || item.properties.soundId || "";
      files.sounds.write(`${itemPath.join(".")}\tSoundId=${sid}\n`);
    }
    if (item.class === "ProximityPrompt") {
      files.prompts.write(
        `${itemPath.join(".")}\tEnabled=${item.properties.Enabled}\tActionText=${item.properties.ActionText || ""}\tObjectText=${item.properties.ObjectText || ""}\n`
      );
    }
    if (
      item.class === "ScreenGui" ||
      item.class === "Frame" ||
      item.class === "TextLabel" ||
      item.class === "TextButton" ||
      item.class === "ImageLabel" ||
      item.class === "ImageButton" ||
      item.class === "ScrollingFrame" ||
      item.class === "TextBox"
    ) {
      const text = item.properties.Text || "";
      files.guis.write(`${item.class}\t${itemPath.join(".")}\tText=${JSON.stringify(text)}\n`);
    }
  }

  const parser = sax.createStream(true, { lowercase: false, trim: false });

  parser.on("opentag", (node) => {
    const tag = node.name;
    if (tag === "Item") {
      const cls = node.attributes.class;
      const referent = node.attributes.referent;
      currentItem = {
        class: cls,
        referent,
        name: cls,
        properties: {},
        attributes: null,
        source: null,
      };
      stack.push(currentItem);
      return;
    }

    if (tag === "Properties" && currentItem) {
      inProperties = true;
      return;
    }

    if (inProperties && currentItem) {
      if (
        [
          "string", "bool", "int", "float", "double", "token",
          "ProtectedString", "Content", "Ref", "Vector3", "Vector2",
          "CoordinateFrame", "Color3", "BinaryString", "OptionalCoordinateFrame",
          "SecurityCapabilities", "UniqueId",
        ].includes(tag)
      ) {
        currentProp = {
          type: tag,
          name: node.attributes.name,
        };
        propText = "";
        propAttrs = { ...node.attributes };
        propDepth = 1;
        return;
      }
      if (tag === "X" || tag === "Y" || tag === "Z" || tag === "R" || tag === "G" || tag === "B") {
        propDepth++;
        return;
      }
      if (tag === "CFrame") {
        propDepth++;
        return;
      }
    }
  });

  parser.on("text", (text) => {
    if (currentProp) propText += text;
  });

  parser.on("cdata", (text) => {
    if (currentProp) propText += text;
  });

  parser.on("closetag", (tag) => {
    if (tag === "X" || tag === "Y" || tag === "Z" || tag === "R" || tag === "G" || tag === "B") {
      if (currentProp && propAttrs) {
        propAttrs[tag] = propText.trim();
        propText = "";
        propDepth--;
      }
      return;
    }
    if (tag === "CFrame") {
      propDepth--;
      return;
    }

    if (currentProp && inProperties) {
      const propTags = new Set([
        "string", "bool", "int", "float", "double", "token",
        "ProtectedString", "Content", "Ref", "Vector3", "Vector2",
        "CoordinateFrame", "Color3", "BinaryString", "OptionalCoordinateFrame",
        "SecurityCapabilities", "UniqueId",
      ]);
      if (propTags.has(tag)) {
        const val = propValueToString(currentProp.type, propText, propAttrs);
        if (currentProp.name === "Name") currentItem.name = val;
        if (currentProp.name === "Source" && currentProp.type === "ProtectedString") {
          currentItem.source = propText;
        }
        if (currentProp.name === "AttributesSerialize" && currentProp.type === "BinaryString") {
          currentItem.attributes = decodeAttributesSerialize(propText.trim());
        } else {
          currentItem.properties[currentProp.name] = val;
        }
        currentProp = null;
        propText = "";
        propAttrs = null;
        return;
      }
    }

    if (tag === "Properties") {
      inProperties = false;
      return;
    }

    if (tag === "Item" && currentItem) {
      finalizeItem(currentItem);
      stack.pop();
      currentItem = stack.length ? stack[stack.length - 1] : null;
    }
  });

  parser.on("error", (err) => {
    console.error("XML parse error:", err.message);
    process.exit(1);
  });

  await new Promise((resolve, reject) => {
    const rs = fs.createReadStream(INPUT, { encoding: "utf8" });
    rs.on("error", reject);
    parser.on("end", resolve);
    rs.pipe(parser);
  });

  // close writers
  for (const key of Object.keys(files)) {
    if (key === "propertiesByClass") continue;
    if (files[key] && typeof files[key].end === "function") files[key].end();
  }
  for (const ws of Object.values(files.propertiesByClass)) ws.end();

  const manifest = {
    source_file: baseName,
    source_size_bytes: stat.size,
    dumped_at: new Date().toISOString(),
    place_id_guess: baseName.match(/place\s+(\d+)/i)?.[1] || null,
    total_instances: itemCount,
    total_scripts: scriptCount,
    class_stats: classStats,
    service_roots: serviceRoots,
    output_dir: OUT_DIR,
  };

  fs.writeFileSync(path.join(OUT_DIR, "manifest.json"), JSON.stringify(manifest, null, 2));
  fs.writeFileSync(path.join(OUT_DIR, "class_stats.json"), JSON.stringify(classStats, null, 2));

  const sorted = Object.entries(classStats).sort((a, b) => b[1] - a[1]);
  fs.writeFileSync(
    path.join(OUT_DIR, "class_stats.txt"),
    sorted.map(([k, v]) => `${k}\t${v}`).join("\n")
  );

  fs.writeFileSync(path.join(OUT_DIR, "class_stats.txt"), sorted.map(([k, v]) => `${k}\t${v}`).join("\n"));

  const readme = `Fallen Survival - rbxlx Full Dump
Source: ${baseName}
Size: ${(stat.size / 1024 / 1024).toFixed(2)} MB
Instances: ${itemCount}
Scripts: ${scriptCount}

Structure:
  manifest.json         - metadata + class stats
  hierarchy.txt         - full indented instance tree
  index.tsv             - flat referent/path/class index
  instances.jsonl       - every instance + all properties (JSON lines)
  properties/<class>.jsonl - instances grouped by class
  scripts/              - decompiled Script/LocalScript/ModuleScript source
  scripts/_index.tsv    - script path -> file map
  remotes.txt           - RemoteEvent/RemoteFunction
  bindables.txt         - BindableEvent/BindableFunction
  values.txt            - all Value instances
  modules.txt           - ModuleScript index
  tools.txt             - Tool instances
  sounds.txt            - Sound instances
  proximity_prompts.txt - ProximityPrompt instances
  gui_tree.txt          - GUI instances
  attributes.jsonl      - decoded custom attributes
`;
  fs.writeFileSync(path.join(OUT_DIR, "README.txt"), readme);

  console.log(`Done. ${itemCount} instances, ${scriptCount} scripts -> ${OUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

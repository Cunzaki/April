/**
 * April rbxlx dumper — full place dump for Fallen / Vector work.
 *
 * Improvements vs old dump:
 * - Proper AttributesSerialize / Tags decoding (no raw binary junk)
 * - Asset catalogs (meshes, images, sounds, animations)
 * - Organized layout: catalog/ tree/ index/ instances/ scripts/ attributes/
 * - Service overview + GAME_REFERENCE from live tree
 * - Keeps flat script names for existing extract-* tools
 *
 * Usage:
 *   node scripts/dump-rbxlx.mjs [path/to/place.rbxlx] [outDir]
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const DEFAULT_RBXLX =
  process.env.APRIL_RBXLX ||
  path.join(
    process.env.LOCALAPPDATA || "",
    "Volt",
    "workspace",
    "place 13800717766 Fallen Survival Large Server(1).rbxlx"
  );

const rbxlxPath = path.resolve(process.argv[2] || DEFAULT_RBXLX);
const outDir = path.resolve(process.argv[3] || path.join(ROOT, "dump"));

const SCRIPT_CLASSES = new Set(["Script", "LocalScript", "ModuleScript"]);
const REMOTE_CLASSES = new Set([
  "RemoteEvent",
  "RemoteFunction",
  "UnreliableRemoteEvent",
]);
const BINDABLE_CLASSES = new Set(["BindableEvent", "BindableFunction"]);
const VALUE_CLASSES = new Set([
  "BoolValue",
  "NumberValue",
  "IntValue",
  "StringValue",
  "ObjectValue",
  "Vector3Value",
  "CFrameValue",
  "Color3Value",
  "BrickColorValue",
  "RayValue",
]);
const GUI_CLASSES = new Set([
  "ScreenGui",
  "BillboardGui",
  "SurfaceGui",
  "Frame",
  "ScrollingFrame",
  "TextLabel",
  "TextButton",
  "TextBox",
  "ImageLabel",
  "ImageButton",
  "ViewportFrame",
]);

function die(msg) {
  console.error(msg);
  process.exit(1);
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function wipeDir(p) {
  fs.rmSync(p, { recursive: true, force: true });
  ensureDir(p);
}

function textContent(raw) {
  if (raw == null) return "";
  const m = String(raw).match(/<!\[CDATA\[([\s\S]*?)\]\]>/);
  if (m) return m[1];
  return String(raw)
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'");
}

function safeSeg(name) {
  return String(name || "")
    .replace(/[<>:"/\\|?*\x00-\x1f]/g, "_")
    .replace(/\s+/g, "_")
    .slice(0, 120);
}

function scriptFileName(instPath, className) {
  return `${safeSeg(instPath)}.${className}.lua`;
}

/** Mirror instance path as nested folders: ReplicatedStorage/Modules/Items/ModuleScript.lua */
function scriptPathFile(instPath, className) {
  const parts = String(instPath || "")
    .split(".")
    .map(safeSeg)
    .filter(Boolean);
  return path.join(...parts, `${className}.lua`);
}

/** Roblox AttributesSerialize (BinaryString base64) */
function decodeAttributes(b64) {
  if (!b64 || !b64.trim()) return null;
  let buf;
  try {
    buf = Buffer.from(b64.trim(), "base64");
  } catch {
    return { _error: "bad_base64" };
  }
  if (buf.length < 4) return null;
  let o = 0;
  const count = buf.readUInt32LE(o);
  o += 4;
  if (count > 10_000) return { _error: "count_too_large", count };
  const out = {};
  try {
    for (let i = 0; i < count; i++) {
      if (o + 4 > buf.length) break;
      const nlen = buf.readUInt32LE(o);
      o += 4;
      if (nlen > 4096 || o + nlen > buf.length) break;
      const name = buf.slice(o, o + nlen).toString("utf8");
      o += nlen;
      if (o >= buf.length) break;
      const t = buf[o++];
      let value;
      switch (t) {
        case 2: {
          // string
          const sl = buf.readUInt32LE(o);
          o += 4;
          value = buf.slice(o, o + sl).toString("utf8");
          o += sl;
          break;
        }
        case 3: // bool
          value = buf[o++] !== 0;
          break;
        case 4: // int32
          value = buf.readInt32LE(o);
          o += 4;
          break;
        case 5: // float
          value = buf.readFloatLE(o);
          o += 4;
          break;
        case 6: // double
          value = buf.readDoubleLE(o);
          o += 8;
          break;
        case 7: {
          // UDim
          value = { scale: buf.readFloatLE(o), offset: buf.readInt32LE(o + 4) };
          o += 8;
          break;
        }
        case 8: {
          // UDim2
          value = {
            x: { scale: buf.readFloatLE(o), offset: buf.readInt32LE(o + 4) },
            y: { scale: buf.readFloatLE(o + 8), offset: buf.readInt32LE(o + 12) },
          };
          o += 16;
          break;
        }
        case 9: {
          // BrickColor
          value = buf.readUInt32LE(o);
          o += 4;
          break;
        }
        case 10: {
          // Color3
          value = {
            r: buf.readFloatLE(o),
            g: buf.readFloatLE(o + 4),
            b: buf.readFloatLE(o + 8),
          };
          o += 12;
          break;
        }
        case 11: {
          // Vector2
          value = { x: buf.readFloatLE(o), y: buf.readFloatLE(o + 4) };
          o += 8;
          break;
        }
        case 12: {
          // Vector3
          value = {
            x: buf.readFloatLE(o),
            y: buf.readFloatLE(o + 4),
            z: buf.readFloatLE(o + 8),
          };
          o += 12;
          break;
        }
        case 14: {
          // NumberSequence — skip carefully
          const keypoints = buf.readUInt32LE(o);
          o += 4;
          const pts = [];
          for (let k = 0; k < keypoints && o + 12 <= buf.length; k++) {
            pts.push({
              time: buf.readFloatLE(o),
              value: buf.readFloatLE(o + 4),
              envelope: buf.readFloatLE(o + 8),
            });
            o += 12;
          }
          value = pts;
          break;
        }
        case 15: {
          // ColorSequence
          const keypoints = buf.readUInt32LE(o);
          o += 4;
          const pts = [];
          for (let k = 0; k < keypoints && o + 20 <= buf.length; k++) {
            pts.push({
              time: buf.readFloatLE(o),
              r: buf.readFloatLE(o + 4),
              g: buf.readFloatLE(o + 8),
              b: buf.readFloatLE(o + 12),
              envelope: buf.readFloatLE(o + 16),
            });
            o += 20;
          }
          value = pts;
          break;
        }
        case 16: {
          // NumberRange
          value = { min: buf.readFloatLE(o), max: buf.readFloatLE(o + 4) };
          o += 8;
          break;
        }
        case 17: {
          // Rect
          value = {
            min: { x: buf.readFloatLE(o), y: buf.readFloatLE(o + 4) },
            max: { x: buf.readFloatLE(o + 8), y: buf.readFloatLE(o + 12) },
          };
          o += 16;
          break;
        }
        case 19: {
          // FontFace-ish / string fallback
          const sl = buf.readUInt32LE(o);
          o += 4;
          value = buf.slice(o, o + sl).toString("utf8");
          o += sl;
          break;
        }
        default:
          value = {
            _unknownType: t,
            _hex: buf.slice(o, Math.min(o + 24, buf.length)).toString("hex"),
          };
          // can't safely continue
          out[name] = value;
          return out;
      }
      out[name] = value;
    }
  } catch (e) {
    out._decodeError = String(e.message || e);
  }
  return Object.keys(out).length ? out : null;
}

/** Tags BinaryString: repeated length-prefixed strings */
function decodeTags(b64) {
  if (!b64 || !b64.trim()) return [];
  let buf;
  try {
    buf = Buffer.from(b64.trim(), "base64");
  } catch {
    return [];
  }
  const tags = [];
  let o = 0;
  while (o + 4 <= buf.length) {
    const len = buf.readUInt32LE(o);
    o += 4;
    if (len === 0 || len > 512 || o + len > buf.length) break;
    tags.push(buf.slice(o, o + len).toString("utf8"));
    o += len;
  }
  return tags;
}

function parseVector3(inner) {
  const x = +(inner.match(/<X>([^<]*)<\/X>/)?.[1] ?? NaN);
  const y = +(inner.match(/<Y>([^<]*)<\/Y>/)?.[1] ?? NaN);
  const z = +(inner.match(/<Z>([^<]*)<\/Z>/)?.[1] ?? NaN);
  if ([x, y, z].some(Number.isNaN)) return textContent(inner);
  return { x, y, z };
}

function parseCFrame(inner) {
  const nums = {};
  for (const k of ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"]) {
    const m = inner.match(new RegExp(`<${k}>([^<]*)</${k}>`));
    if (m) nums[k] = +m[1];
  }
  return Object.keys(nums).length ? nums : textContent(inner);
}

function parseContent(inner) {
  const url = inner.match(/<url>([\s\S]*?)<\/url>/);
  if (url) return textContent(url[1]);
  if (/<null\s*\/>/.test(inner)) return null;
  return textContent(inner);
}

function parsePropValue(tag, inner) {
  switch (tag) {
    case "bool":
      return inner.trim() === "true";
    case "int":
    case "int64":
    case "token":
      return Number.parseInt(inner, 10);
    case "float":
    case "double":
      return Number.parseFloat(inner);
    case "string":
    case "ProtectedString":
      return textContent(inner);
    case "Ref":
      return inner.trim();
    case "BinaryString":
      return inner.trim(); // base64 kept; decoded separately for known fields
    case "Color3":
    case "Color3uint8":
      return textContent(inner);
    case "Vector3":
      return parseVector3(inner);
    case "CoordinateFrame":
    case "OptionalCoordinateFrame":
      return parseCFrame(inner);
    case "Content":
    case "UniqueId":
    case "SecurityCapabilities":
      return parseContent(inner);
    default:
      if (inner.includes("<")) {
        if (inner.includes("<X>") && inner.includes("<Y>")) return parseVector3(inner);
        return textContent(inner);
      }
      return textContent(inner);
  }
}

function parseProperties(block) {
  const props = {};
  const re =
    /<(bool|int|int64|float|double|token|string|ProtectedString|Ref|BinaryString|Color3|Color3uint8|Vector3|CoordinateFrame|OptionalCoordinateFrame|Content|UniqueId|SecurityCapabilities|NumberRange|UDim|UDim2|Rect2D|Font|SharedString|url) name="([^"]+)"[^>]*>([\s\S]*?)<\/\1>/g;
  let m;
  while ((m = re.exec(block))) {
    props[m[2]] = parsePropValue(m[1], m[3]);
  }
  // self-closing nulls etc.
  const emptyRe =
    /<(bool|int|float|string|BinaryString|Content) name="([^"]+)"\s*\/>/g;
  while ((m = emptyRe.exec(block))) {
    if (!(m[2] in props)) props[m[2]] = null;
  }
  return props;
}

/**
 * Stack-based Item tree parse. Handles nested Items.
 * Returns flat list of instances with parent_referent + children order.
 */
function parseItems(xml) {
  const instances = [];
  const stack = []; // { referent, className, startProps... }
  const re = /<Item class="([^"]+)" referent="([^"]+)">|<\/Item>/g;
  let m;
  const opens = [];

  // Collect open positions first via combined scan
  while ((m = re.exec(xml))) {
    if (m[0].startsWith("</")) {
      if (!opens.length) continue;
      const open = opens.pop();
      const inner = xml.slice(open.endTag, m.index);
      // Properties are the first <Properties>...</Properties> not nested in child Items —
      // child Items start after Properties closes for standard SynSaveInstance layout.
      const propsMatch = inner.match(/^[\s\S]*?<Properties>([\s\S]*?)<\/Properties>/);
      const props = propsMatch ? parseProperties(propsMatch[1]) : {};
      const nameRaw = props.Name != null ? String(props.Name) : open.className;
      const name = nameRaw.trim();
      // Keep trimmed Name in props so paths stay clean
      if (props.Name != null) props.Name = name;
      const parent = opens.length ? opens[opens.length - 1] : null;
      const inst = {
        referent: open.referent,
        class: open.className,
        name,
        parent_referent: parent ? parent.referent : null,
        properties: props,
      };
      instances.push(inst);
      // Remember insertion order under parent for hierarchy
      if (parent) {
        parent.childRefs = parent.childRefs || [];
        parent.childRefs.push(open.referent);
      } else {
        stack.push(inst); // roots
      }
      // stash childRefs on open object transferred — attach to instance map later
      inst._childRefs = open.childRefs || [];
    } else {
      opens.push({
        className: m[1],
        referent: m[2],
        endTag: m.index + m[0].length,
        childRefs: [],
      });
    }
  }
  return instances;
}

function buildPaths(instances) {
  const byRef = new Map(instances.map((i) => [i.referent, i]));
  for (const inst of instances) {
    const parts = [];
    let cur = inst;
    const guard = new Set();
    while (cur && !guard.has(cur.referent)) {
      guard.add(cur.referent);
      parts.push(String(cur.name || cur.class));
      cur = cur.parent_referent != null ? byRef.get(cur.parent_referent) : null;
    }
    parts.reverse();
    inst.path = parts.join(".");
  }
  return byRef;
}

function extractAssetIds(value, into) {
  if (value == null) return;
  if (typeof value === "string") {
    for (const m of value.matchAll(/rbxassetid:\/\/(\d+)/g)) into.add(m[1]);
    for (const m of value.matchAll(/id=(\d{5,})/g)) into.add(m[1]);
  } else if (typeof value === "object") {
    for (const v of Object.values(value)) extractAssetIds(v, into);
  }
}

function writeLines(file, lines) {
  fs.writeFileSync(file, lines.join("\n") + (lines.length ? "\n" : ""), "utf8");
}

function tsvEscape(s) {
  return String(s ?? "").replace(/\t/g, " ").replace(/\r?\n/g, " ");
}

function main() {
  if (!fs.existsSync(rbxlxPath)) die(`Missing rbxlx: ${rbxlxPath}`);

  console.log(`Reading ${rbxlxPath} ...`);
  const t0 = Date.now();
  const xml = fs.readFileSync(rbxlxPath, "utf8");
  const sourceStat = fs.statSync(rbxlxPath);

  const meta = {
    placeId: +(xml.match(/PlaceId:\s*(\d+)/)?.[1] || 13800717766),
    placeVersion: +(xml.match(/PlaceVersion:\s*(\d+)/)?.[1] || 0),
    clientVersion: xml.match(/Client Version:\s*([^\s]+)/)?.[1] || null,
    executor: xml.match(/Executor:\s*([^\n\]]+)/)?.[1]?.trim() || null,
    dumpedAtUtc: xml.match(/Date \(UTC\):\s*([^\n]+)/)?.[1]?.trim() || null,
  };

  console.log("Parsing Item tree...");
  const instances = parseItems(xml);
  console.log(`  ${instances.length} instances`);
  const byRef = buildPaths(instances);

  // Decode attributes / tags; extract script sources
  const allAssets = new Set();
  const classStats = {};
  const scripts = [];
  const remotes = [];
  const bindables = [];
  const values = [];
  const tools = [];
  const sounds = [];
  const prompts = [];
  const animations = [];
  const imageAssets = [];
  const meshAssets = [];
  const attrRows = [];

  for (const inst of instances) {
    classStats[inst.class] = (classStats[inst.class] || 0) + 1;
    const props = inst.properties;

    if (props.AttributesSerialize) {
      inst.attributes = decodeAttributes(props.AttributesSerialize);
      delete props.AttributesSerialize;
      if (inst.attributes) {
        attrRows.push({
          referent: inst.referent,
          path: inst.path,
          class: inst.class,
          attributes: inst.attributes,
        });
      }
    } else {
      inst.attributes = null;
    }

    if (props.Tags) {
      inst.tags = decodeTags(props.Tags);
      delete props.Tags;
    } else {
      inst.tags = [];
    }

    for (const v of Object.values(props)) extractAssetIds(v, allAssets);

    if (SCRIPT_CLASSES.has(inst.class)) {
      const source = props.Source != null ? String(props.Source) : "";
      // Keep Source out of giant jsonl props to save space — still in scripts/
      const { Source, ...rest } = props;
      inst.properties = rest;
      inst._source = source;
      scripts.push(inst);
    }

    if (REMOTE_CLASSES.has(inst.class)) remotes.push(inst);
    if (BINDABLE_CLASSES.has(inst.class)) bindables.push(inst);
    if (VALUE_CLASSES.has(inst.class)) values.push(inst);
    if (inst.class === "Tool") tools.push(inst);
    if (inst.class === "Sound") {
      sounds.push(inst);
      extractAssetIds(props.SoundId, allAssets);
    }
    if (inst.class === "ProximityPrompt") prompts.push(inst);
    if (inst.class === "Animation") {
      animations.push(inst);
      extractAssetIds(props.AnimationId, allAssets);
    }
    if (inst.class === "ImageLabel" || inst.class === "ImageButton" || inst.class === "Decal" || inst.class === "Texture") {
      const img = props.Image || props.Texture || props.TextureID || null;
      if (img) imageAssets.push({ path: inst.path, class: inst.class, image: img });
      extractAssetIds(img, allAssets);
    }
    if (inst.class === "MeshPart" || inst.class === "SpecialMesh" || inst.class === "FileMesh") {
      const mesh = props.MeshId || null;
      const tex = props.TextureID || props.TextureId || null;
      meshAssets.push({ path: inst.path, class: inst.class, meshId: mesh, textureId: tex });
      extractAssetIds(mesh, allAssets);
      extractAssetIds(tex, allAssets);
    }
  }

  console.log("Writing dump layout...");
  wipeDir(outDir);
  const dirs = {
    catalog: path.join(outDir, "catalog"),
    catalogRemotes: path.join(outDir, "catalog", "remotes"),
    catalogAssets: path.join(outDir, "catalog", "assets"),
    catalogGameplay: path.join(outDir, "catalog", "gameplay"),
    tree: path.join(outDir, "tree"),
    treeServices: path.join(outDir, "tree", "services"),
    index: path.join(outDir, "index"),
    instances: path.join(outDir, "instances"),
    byClass: path.join(outDir, "instances", "by_class"),
    byService: path.join(outDir, "instances", "by_service"),
    scripts: path.join(outDir, "scripts"),
    scriptsByPath: path.join(outDir, "scripts", "by_path"),
    scriptsFlat: path.join(outDir, "scripts", "flat"),
    attributes: path.join(outDir, "attributes"),
  };
  for (const d of Object.values(dirs)) ensureDir(d);

  // --- instances/all.jsonl + by_class ---
  const byClassLines = new Map();
  const allLines = [];
  const indexLines = ["referent\tclass\tname\tpath\tparent_referent\ttags"];
  for (const inst of instances) {
    const row = {
      referent: inst.referent,
      class: inst.class,
      name: inst.name,
      path: inst.path,
      parent_referent: inst.parent_referent,
      properties: inst.properties,
      attributes: inst.attributes,
      tags: inst.tags,
    };
    const line = JSON.stringify(row);
    allLines.push(line);
    if (!byClassLines.has(inst.class)) byClassLines.set(inst.class, []);
    byClassLines.get(inst.class).push(line);
    indexLines.push(
      [inst.referent, inst.class, tsvEscape(inst.name), tsvEscape(inst.path), inst.parent_referent ?? "", (inst.tags || []).join(",")].join("\t")
    );
  }
  writeLines(path.join(dirs.instances, "all.jsonl"), allLines);
  for (const [cls, lines] of byClassLines) {
    writeLines(path.join(dirs.byClass, `${safeSeg(cls)}.jsonl`), lines);
  }
  writeLines(path.join(dirs.index, "instances.tsv"), indexLines);
  // Compat alias
  fs.copyFileSync(path.join(dirs.index, "instances.tsv"), path.join(outDir, "index.tsv"));
  fs.copyFileSync(path.join(dirs.instances, "all.jsonl"), path.join(outDir, "instances.jsonl"));

  // --- scripts (flat compat + by_path mirror) ---
  const scriptIndex = ["referent\tclass\tpath\tflat_file\tpath_file\tbytes"];
  for (const inst of scripts) {
    const flatFile = scriptFileName(inst.path, inst.class);
    const pathFile = scriptPathFile(inst.path, inst.class);
    const src = inst._source || "";
    fs.writeFileSync(path.join(dirs.scriptsFlat, flatFile), src, "utf8");
    const nested = path.join(dirs.scriptsByPath, pathFile);
    ensureDir(path.dirname(nested));
    fs.writeFileSync(nested, src, "utf8");
    // Legacy flat name at scripts/ root for extract-* tools
    fs.writeFileSync(path.join(dirs.scripts, flatFile), src, "utf8");
    scriptIndex.push(
      [
        inst.referent,
        inst.class,
        tsvEscape(inst.path),
        `scripts\\flat\\${flatFile}`,
        `scripts\\by_path\\${pathFile.replace(/\//g, "\\")}`,
        Buffer.byteLength(src),
      ].join("\t")
    );
  }
  writeLines(path.join(dirs.scripts, "_index.tsv"), scriptIndex);

  // --- attributes ---
  writeLines(
    path.join(dirs.attributes, "all.jsonl"),
    attrRows.map((r) => JSON.stringify(r))
  );
  fs.copyFileSync(path.join(dirs.attributes, "all.jsonl"), path.join(outDir, "attributes.jsonl"));

  // --- catalog ---
  const sortedClasses = Object.entries(classStats).sort((a, b) => b[1] - a[1]);
  fs.writeFileSync(
    path.join(dirs.catalog, "class_stats.json"),
    JSON.stringify(Object.fromEntries(sortedClasses), null, 2)
  );
  writeLines(
    path.join(dirs.catalog, "class_stats.txt"),
    sortedClasses.map(([c, n]) => `${n}\t${c}`)
  );

  const catalogTsv = (file, rows, cols, mapFn) => {
    writeLines(path.join(dirs.catalog, file), [
      cols.join("\t"),
      ...rows.map(mapFn),
    ]);
  };

  catalogTsv("remotes.tsv", remotes, ["class", "path", "referent"], (i) =>
    [i.class, tsvEscape(i.path), i.referent].join("\t")
  );
  fs.copyFileSync(path.join(dirs.catalog, "remotes.tsv"), path.join(dirs.catalogRemotes, "index.tsv"));
  catalogTsv("bindables.tsv", bindables, ["class", "path", "referent"], (i) =>
    [i.class, tsvEscape(i.path), i.referent].join("\t")
  );
  catalogTsv("modules.tsv", scripts.filter((s) => s.class === "ModuleScript"), ["path", "referent", "file"], (i) =>
    [tsvEscape(i.path), i.referent, scriptFileName(i.path, i.class)].join("\t")
  );
  catalogTsv("values.tsv", values, ["class", "path", "value"], (i) => {
    const v =
      i.properties.Value ??
      i.properties.Value ??
      i.properties["Value"];
    return [i.class, tsvEscape(i.path), tsvEscape(JSON.stringify(v))].join("\t");
  });
  catalogTsv("tools.tsv", tools, ["path", "referent"], (i) =>
    [tsvEscape(i.path), i.referent].join("\t")
  );
  fs.copyFileSync(path.join(dirs.catalog, "tools.tsv"), path.join(dirs.catalogGameplay, "tools.tsv"));
  catalogTsv("sounds.tsv", sounds, ["path", "soundId"], (i) =>
    [tsvEscape(i.path), tsvEscape(i.properties.SoundId)].join("\t")
  );
  catalogTsv("proximity_prompts.tsv", prompts, ["path", "action", "object"], (i) =>
    [
      tsvEscape(i.path),
      tsvEscape(i.properties.ActionText),
      tsvEscape(i.properties.ObjectText),
    ].join("\t")
  );
  catalogTsv("animations.tsv", animations, ["path", "animationId"], (i) =>
    [tsvEscape(i.path), tsvEscape(i.properties.AnimationId)].join("\t")
  );
  catalogTsv("image_assets.tsv", imageAssets, ["class", "path", "image"], (i) =>
    [i.class, tsvEscape(i.path), tsvEscape(i.image)].join("\t")
  );
  catalogTsv("mesh_assets.tsv", meshAssets, ["class", "path", "meshId", "textureId"], (i) =>
    [i.class, tsvEscape(i.path), tsvEscape(i.meshId), tsvEscape(i.textureId)].join("\t")
  );
  writeLines(path.join(dirs.catalogAssets, "all_ids.tsv"), [
    "assetId",
    ...[...allAssets].sort((a, b) => Number(a) - Number(b)),
  ]);
  fs.copyFileSync(path.join(dirs.catalogAssets, "all_ids.tsv"), path.join(dirs.catalog, "assets.tsv"));

  // Compat text indexes (old layout)
  writeLines(
    path.join(outDir, "remotes.txt"),
    remotes.map((i) => `${i.class}\t${i.path}`)
  );
  writeLines(
    path.join(outDir, "bindables.txt"),
    bindables.map((i) => `${i.class}\t${i.path}`)
  );
  writeLines(
    path.join(outDir, "modules.txt"),
    scripts
      .filter((s) => s.class === "ModuleScript")
      .map((i) => `${i.path}\t${scriptFileName(i.path, i.class)}`)
  );
  writeLines(
    path.join(outDir, "values.txt"),
    values.map((i) => `${i.class}\t${i.path}\t${JSON.stringify(i.properties.Value)}`)
  );
  writeLines(
    path.join(outDir, "tools.txt"),
    tools.map((i) => i.path)
  );
  writeLines(
    path.join(outDir, "sounds.txt"),
    sounds.map((i) => `${i.path}\t${i.properties.SoundId ?? ""}`)
  );
  writeLines(
    path.join(outDir, "proximity_prompts.txt"),
    prompts.map((i) => i.path)
  );
  fs.copyFileSync(path.join(dirs.catalog, "class_stats.json"), path.join(outDir, "class_stats.json"));
  fs.copyFileSync(path.join(dirs.catalog, "class_stats.txt"), path.join(outDir, "class_stats.txt"));
  // properties/ compat
  ensureDir(path.join(outDir, "properties"));
  for (const cls of byClassLines.keys()) {
    const src = path.join(dirs.byClass, `${safeSeg(cls)}.jsonl`);
    fs.copyFileSync(src, path.join(outDir, "properties", `${safeSeg(cls)}.jsonl`));
  }

  // --- tree ---
  const children = new Map();
  for (const inst of instances) {
    const p = inst.parent_referent ?? "__root__";
    if (!children.has(p)) children.set(p, []);
    children.get(p).push(inst);
  }
  const hier = [];
  function walk(ref, depth) {
    const kids = children.get(ref) || [];
    for (const k of kids) {
      hier.push(`${"  ".repeat(depth)}${k.class} ${k.name}`);
      walk(k.referent, depth + 1);
    }
  }
  walk("__root__", 0);
  writeLines(path.join(dirs.tree, "hierarchy.txt"), hier);
  fs.copyFileSync(path.join(dirs.tree, "hierarchy.txt"), path.join(outDir, "hierarchy.txt"));

  const guiLines = [];
  function walkGui(ref, depth) {
    for (const k of children.get(ref) || []) {
      if (GUI_CLASSES.has(k.class) || depth === 0) {
        if (GUI_CLASSES.has(k.class)) {
          guiLines.push(`${"  ".repeat(depth)}${k.class} ${k.path}`);
        }
        walkGui(k.referent, GUI_CLASSES.has(k.class) ? depth + 1 : depth);
      } else {
        walkGui(k.referent, depth);
      }
    }
  }
  // Simpler: list all GUI by path
  writeLines(
    path.join(dirs.tree, "gui_tree.txt"),
    instances.filter((i) => GUI_CLASSES.has(i.class)).map((i) => `${i.class}\t${i.path}`)
  );
  fs.copyFileSync(path.join(dirs.tree, "gui_tree.txt"), path.join(outDir, "gui_tree.txt"));

  const roots = instances.filter((i) => i.parent_referent == null);
  const serviceLines = ["class\tname\tpath\tchild_count\treferent"];
  for (const r of roots) {
    const cc = (children.get(r.referent) || []).length;
    serviceLines.push([r.class, tsvEscape(r.name), tsvEscape(r.path), cc, r.referent].join("\t"));
  }
  writeLines(path.join(dirs.tree, "services.tsv"), serviceLines);

  // Per-service subtree dumps (Workspace, ReplicatedStorage, …)
  const SERVICE_ROOTS = new Set([
    "Workspace",
    "ReplicatedStorage",
    "ReplicatedFirst",
    "ServerScriptService",
    "ServerStorage",
    "StarterPlayer",
    "StarterGui",
    "Lighting",
    "SoundService",
    "Players",
  ]);
  for (const r of roots) {
    if (!SERVICE_ROOTS.has(r.name)) continue;
    const svcLines = [];
    function walkSvc(ref, depth) {
      for (const k of children.get(ref) || []) {
        svcLines.push(`${"  ".repeat(depth)}${k.class} ${k.name}\t${k.path}`);
        walkSvc(k.referent, depth + 1);
      }
    }
    walkSvc(r.referent, 0);
    writeLines(path.join(dirs.treeServices, `${safeSeg(r.name)}.txt`), svcLines);
  }

  // instances/by_service — jsonl chunks under each top-level service
  const byServiceLines = new Map();
  for (const inst of instances) {
    const top = inst.path.split(".")[0];
    if (!byServiceLines.has(top)) byServiceLines.set(top, []);
    byServiceLines.get(top).push(
      JSON.stringify({
        referent: inst.referent,
        class: inst.class,
        name: inst.name,
        path: inst.path,
        parent_referent: inst.parent_referent,
        properties: inst.properties,
        attributes: inst.attributes,
        tags: inst.tags,
      })
    );
  }
  for (const [svc, lines] of byServiceLines) {
    writeLines(path.join(dirs.byService, `${safeSeg(svc)}.jsonl`), lines);
  }

  // Workspace folder cheat-sheet
  const ws = instances.find((i) => i.class === "Workspace" && i.parent_referent == null);
  const wsFolders = ws
    ? (children.get(ws.referent) || [])
        .filter((c) => c.class === "Folder" || c.class === "Model")
        .map((c) => `  workspace.${c.name}`)
    : [];
  const rs = instances.find((i) => i.class === "ReplicatedStorage");
  const rsKids = rs
    ? (children.get(rs.referent) || []).map((c) => `  ReplicatedStorage.${c.name} (${c.class})`)
    : [];

  const gameRef = [
    "Fallen Survival — Game Reference (from dump/)",
    "=============================================",
    `Dumped: ${new Date().toISOString()}`,
    `Source: ${path.basename(rbxlxPath)} (${(sourceStat.size / 1e6).toFixed(2)} MB)`,
    `PlaceId: ${meta.placeId}  PlaceVersion: ${meta.placeVersion}`,
    `Client: ${meta.clientVersion || "?"}  Executor: ${meta.executor || "?"}`,
    `SynSaveInstance UTC: ${meta.dumpedAtUtc || "?"}`,
    `Instances: ${instances.length}  Scripts: ${scripts.length}  Remotes: ${remotes.length}  Assets: ${allAssets.size}`,
    "",
    "WORKSPACE FOLDERS (for ESP / scans)",
    "------------------------------------",
    ...wsFolders,
    "",
    "REPLICATED STORAGE (top-level)",
    "------------------------------",
    ...rsKids,
    "",
    "USEFUL DUMP PATHS",
    "-----------------",
    "  catalog/remotes.tsv, modules.tsv, assets.tsv, image_assets.tsv",
    "  tree/hierarchy.txt, tree/services.tsv, tree/gui_tree.txt",
    "  instances/all.jsonl, instances/by_class/<Class>.jsonl",
    "  scripts/  — decompiled sources (flat names for extract-* tools)",
    "  attributes/all.jsonl — decoded AttributesSerialize",
    "",
    "REMOTE COUNTS",
    "-------------",
    `  RemoteEvent: ${remotes.filter((r) => r.class === "RemoteEvent").length}`,
    `  UnreliableRemoteEvent: ${remotes.filter((r) => r.class === "UnreliableRemoteEvent").length}`,
    `  RemoteFunction: ${remotes.filter((r) => r.class === "RemoteFunction").length}`,
    `  BindableEvent: ${bindables.filter((r) => r.class === "BindableEvent").length}`,
    `  BindableFunction: ${bindables.filter((r) => r.class === "BindableFunction").length}`,
  ];
  writeLines(path.join(outDir, "GAME_REFERENCE.txt"), gameRef);

  const manifest = {
    source_file: path.basename(rbxlxPath),
    source_path: rbxlxPath,
    source_size_bytes: sourceStat.size,
    dumped_at: new Date().toISOString(),
    place_id: meta.placeId,
    place_version: meta.placeVersion,
    client_version: meta.clientVersion,
    executor: meta.executor,
    synsave_dumped_at_utc: meta.dumpedAtUtc,
    total_instances: instances.length,
    total_scripts: scripts.length,
    total_remotes: remotes.length,
    total_assets: allAssets.size,
    total_attributes_instances: attrRows.length,
    class_stats: Object.fromEntries(sortedClasses),
    layout: {
      catalog: "indexes (remotes, modules, assets, …)",
      "catalog/remotes": "remote index copy",
      "catalog/assets": "rbxassetid catalog",
      "catalog/gameplay": "tools, prompts copies",
      tree: "hierarchy + services + gui",
      "tree/services": "per-service subtree listings",
      index: "flat instance TSV",
      instances: "all.jsonl + by_class/ + by_service/",
      scripts: "flat root (compat) + flat/ + by_path/",
      attributes: "decoded attribute jsonl",
    },
    dumper: "scripts/dump-rbxlx.mjs",
  };
  fs.writeFileSync(path.join(outDir, "manifest.json"), JSON.stringify(manifest, null, 2));

  const readme = [
    "# Fallen Survival — rbxlx Full Dump",
    "",
    `Source: \`${manifest.source_file}\``,
    `Size: ${(sourceStat.size / 1e6).toFixed(2)} MB`,
    `PlaceVersion: ${meta.placeVersion}`,
    `Instances: ${instances.length}`,
    `Scripts: ${scripts.length}`,
    `Unique rbxassetids: ${allAssets.size}`,
    "",
    "## Layout",
    "",
    "| Path | Purpose |",
    "|------|---------|",
    "| `manifest.json` | metadata + class stats |",
    "| `GAME_REFERENCE.txt` | quick ESP / RS cheat sheet |",
    "| `catalog/` | remotes, modules, assets, sounds, … |",
    "| `catalog/remotes/`, `catalog/assets/`, `catalog/gameplay/` | grouped indexes |",
    "| `tree/` | hierarchy, services, gui |",
    "| `tree/services/` | per-service subtree (`Workspace.txt`, …) |",
    "| `index/instances.tsv` | flat referent/path/class |",
    "| `instances/all.jsonl` | every instance + props + attrs |",
    "| `instances/by_class/` | per-class jsonl |",
    "| `instances/by_service/` | per top-level service jsonl |",
    "| `scripts/by_path/` | sources mirrored as instance folders |",
    "| `scripts/flat/` | flat filenames (same as root `scripts/*.lua`) |",
    "| `scripts/` | flat compat + `_index.tsv` |",
    "| `attributes/all.jsonl` | decoded AttributesSerialize |",
    "",
    "Root-level `*.txt` / `instances.jsonl` / `properties/` are **compat aliases** for older April tools.",
    "",
    "Regenerate:",
    "```bash",
    "node scripts/dump-rbxlx.mjs",
    "```",
  ];
  writeLines(path.join(outDir, "README.md"), readme);

  const ms = Date.now() - t0;
  console.log(`Done in ${(ms / 1000).toFixed(1)}s → ${outDir}`);
  console.log(
    `  instances=${instances.length} scripts=${scripts.length} remotes=${remotes.length} assets=${allAssets.size} attrs=${attrRows.length}`
  );

  const items = path.join(
    dirs.scripts,
    "ReplicatedStorage.Modules.Items.ModuleScript.lua"
  );
  console.log(`  Items module: ${fs.existsSync(items) ? "OK" : "MISSING"}`);
}

main();

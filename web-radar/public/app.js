/* April Web Radar — matches tactical_map.lua world_to_map / map_basis exactly */

const canvas = document.getElementById("radar");
const ctx = canvas.getContext("2d");

/** Exact Lua:
 *  fx, fz = sin(yaw), cos(yaw)
 *  rx, rz = -cos(yaw), sin(yaw)
 */
function mapBasis(yaw) {
  const fx = Math.sin(yaw);
  const fz = Math.cos(yaw);
  const rx = -Math.cos(yaw);
  const rz = Math.sin(yaw);
  return { fx, fz, rx, rz };
}

function worldToMap(wx, wz, viewX, viewZ, mapCx, mapCy, zoom, yaw) {
  const wdx = wx - viewX;
  const wdz = wz - viewZ;
  const { fx, fz, rx, rz } = mapBasis(yaw);
  const localFwd = wdx * fx + wdz * fz;
  const localRight = wdx * rx + wdz * rz;
  return { x: mapCx + localRight * zoom, y: mapCy - localFwd * zoom };
}

function clampSquare(mx, my, x, y, size) {
  const edge = 11;
  const clampedX = Math.max(x + edge, Math.min(x + size - edge, mx));
  const clampedY = Math.max(y + edge, Math.min(y + size - edge, my));
  return {
    x: clampedX,
    y: clampedY,
    clamped: clampedX !== mx || clampedY !== my,
  };
}

const FILTER_GROUPS = [
  {
    id: "players",
    title: "Players",
    items: [
      { id: "players", label: "Enemy Players", color: "#ff5577", bucket: "players" },
    ],
  },
  {
    id: "npcs",
    title: "NPCs",
    items: [
      { id: "npc_soldier", label: "Soldiers", color: "#ff9a3c", bucket: "npcs" },
      { id: "npc_boss", label: "Bosses", color: "#ff7ad1", bucket: "npcs" },
    ],
  },
  {
    id: "loot",
    title: "Loot & Vehicles",
    items: [
      { id: "april_dropped_item", label: "Dropped Items", color: "#ffc857", bucket: "loot" },
      { id: "april_wooden_crate", label: "Wooden Crate", color: "#c48a4a", bucket: "loot" },
      { id: "april_metal_crate", label: "Metal Crate", color: "#9aa0b0", bucket: "loot" },
      { id: "april_steel_crate", label: "Steel Crate", color: "#c0c4d0", bucket: "loot" },
      { id: "april_food_crate", label: "Food Crate", color: "#4fe39a", bucket: "loot" },
      { id: "april_timed_crate", label: "Timed Crate", color: "#ff9a3c", bucket: "loot" },
      { id: "april_care_package", label: "Care Package", color: "#ff5577", bucket: "loot" },
      { id: "april_btr_crate", label: "BTR Crate", color: "#e04040", bucket: "loot" },
      { id: "april_body_bag", label: "Body Bag", color: "#6a6a6a", bucket: "loot" },
      { id: "april_sleeper", label: "Sleepers", color: "#d070d0", bucket: "loot" },
      { id: "april_trash_can", label: "Trash Can", color: "#808080", bucket: "loot" },
      { id: "april_oil_barrel", label: "Oil Barrel", color: "#404040", bucket: "loot" },
      { id: "april_small_egg", label: "Small Egg / Gift", color: "#f0d080", bucket: "loot" },
      { id: "april_medium_egg", label: "Medium Egg / Gift", color: "#e8b060", bucket: "loot" },
      { id: "april_large_egg", label: "Large Egg / Gift", color: "#d89040", bucket: "loot" },
      { id: "april_wooden_boat", label: "Wooden Boat", color: "#a07040", bucket: "loot" },
      { id: "april_military_boat", label: "Military Boat", color: "#608060", bucket: "loot" },
      { id: "april_flycopter", label: "Salvaged Flycopter", color: "#a0a0b0", bucket: "loot" },
    ],
  },
  {
    id: "world",
    title: "Resources & Plants",
    items: [
      { id: "april_stone_node", label: "Stone Node", color: "#909090", bucket: "world" },
      { id: "april_metal_node", label: "Metal Node", color: "#c08050", bucket: "world" },
      { id: "april_phosphate_node", label: "Phosphate Node", color: "#40d040", bucket: "world" },
      { id: "april_corn_plant", label: "Corn Plant", color: "#ffe050", bucket: "world" },
      { id: "april_tomato_plant", label: "Tomato Plant", color: "#ff7050", bucket: "world" },
      { id: "april_pumpkin_plant", label: "Pumpkin Plant", color: "#ff8020", bucket: "world" },
      { id: "april_lemon_plant", label: "Lemon Plant", color: "#fff040", bucket: "world" },
      { id: "april_raspberry_plant", label: "Raspberry Plant", color: "#e04070", bucket: "world" },
      { id: "april_blueberry_plant", label: "Blueberry Plant", color: "#5080e0", bucket: "world" },
      { id: "april_wool_plant", label: "Wool Plant", color: "#d8d8e0", bucket: "world" },
      { id: "april_hemp_plant", label: "Hemp Plant", color: "#50b040", bucket: "world" },
    ],
  },
  {
    id: "animals",
    title: "Animals",
    items: [
      { id: "april_deer", label: "Deer", color: "#a07040", bucket: "world" },
      { id: "april_boar", label: "Wild Boar", color: "#705030", bucket: "world" },
      { id: "april_wolf", label: "Wolf", color: "#909090", bucket: "world" },
    ],
  },
  {
    id: "base",
    title: "Base",
    items: [
      { id: "april_base_cabinet", label: "Base Cabinet", color: "#ffcc40", bucket: "base" },
      { id: "april_storage_cabinet", label: "Storage Cabinet", color: "#a07040", bucket: "base" },
      { id: "april_small_box", label: "Small Box", color: "#906030", bucket: "base" },
      { id: "april_large_box", label: "Large Box", color: "#805020", bucket: "base" },
      { id: "april_sleeping_bag", label: "Sleeping Bag", color: "#e04040", bucket: "base" },
      { id: "april_auto_turret", label: "Auto Turret", color: "#ff4040", bucket: "base" },
      { id: "april_shotgun_turret", label: "Shotgun Turret", color: "#ff6030", bucket: "base" },
      { id: "april_wooden_door", label: "Wooden Door", color: "#805020", bucket: "base" },
      { id: "april_wooden_double_door", label: "Wooden Double Door", color: "#905828", bucket: "base" },
      { id: "april_metal_door", label: "Metal Door", color: "#9090a0", bucket: "base" },
      { id: "april_salvaged_door", label: "Salvaged Metal Door", color: "#908880", bucket: "base" },
      { id: "april_metal_double_door", label: "Metal Double Door", color: "#888898", bucket: "base" },
      { id: "april_steel_door", label: "Steel Door", color: "#a8a8b8", bucket: "base" },
      { id: "april_steel_double_door", label: "Steel Double Door", color: "#a0a0b0", bucket: "base" },
      { id: "april_garage_door", label: "Garage Door", color: "#707070", bucket: "base" },
      { id: "april_trap_door", label: "Trap Door", color: "#806440", bucket: "base" },
      { id: "april_triangle_trap_door", label: "Triangle Trap Door", color: "#785c38", bucket: "base" },
      { id: "april_small_battery", label: "Small Battery", color: "#40c060", bucket: "base" },
      { id: "april_medium_battery", label: "Medium Battery", color: "#30a850", bucket: "base" },
      { id: "april_large_battery", label: "Large Battery", color: "#209040", bucket: "base" },
      { id: "april_solar_panel", label: "Solar Panel", color: "#4070d8", bucket: "base" },
      { id: "april_windmill", label: "Windmill", color: "#c0d8f0", bucket: "base" },
    ],
  },
  {
    id: "waypoints",
    title: "Waypoints",
    items: [
      { id: "waypoints", label: "Waypoints", color: "#3ee7ff", bucket: "waypoints" },
    ],
  },
];

const ALL_FILTERS = FILTER_GROUPS.flatMap((g) => g.items);
const FILTER_BY_ID = Object.fromEntries(ALL_FILTERS.map((f) => [f.id, f]));
const LS_KEY = "april_webradar_filters_v2";

function defaultFilters() {
  return Object.fromEntries(ALL_FILTERS.map((f) => [f.id, true]));
}

function loadFilters() {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (!raw) return defaultFilters();
    const parsed = JSON.parse(raw);
    const out = defaultFilters();
    for (const id of Object.keys(out)) {
      if (parsed[id] === false) out[id] = false;
    }
    return out;
  } catch {
    return defaultFilters();
  }
}

const els = {
  hostUrl: document.getElementById("host-url"),
  copyUrl: document.getElementById("copy-url"),
  statusPill: document.getElementById("status-pill"),
  statusText: document.getElementById("status-text"),
  playerCount: document.getElementById("player-count"),
  markerCount: document.getElementById("marker-count"),
  updateMs: document.getElementById("update-ms"),
  yawDeg: document.getElementById("yaw-deg"),
  playerList: document.getElementById("player-list"),
  entityList: document.getElementById("entity-list"),
  filterGroups: document.getElementById("filter-groups"),
  youLine: document.getElementById("you-line"),
  placeLine: document.getElementById("place-line"),
  seqLine: document.getElementById("seq-line"),
  countsLine: document.getElementById("counts-line"),
  waitingCard: document.getElementById("waiting-card"),
  tooltip: document.getElementById("tooltip"),
  legend: document.getElementById("legend"),
  zoom: document.getElementById("zoom"),
  labels: document.getElementById("opt-labels"),
  sweep: document.getElementById("opt-sweep"),
  trail: document.getElementById("opt-trail"),
  playerSearch: document.getElementById("player-search"),
  entitySearch: document.getElementById("entity-search"),
  filterSearch: document.getElementById("filter-search"),
  entityTypeFilters: document.getElementById("entity-type-filters"),
  btnAllOn: document.getElementById("btn-all-on"),
  btnAllOff: document.getElementById("btn-all-off"),
};

const state = {
  target: null,
  filters: loadFilters(),
  openGroups: new Set(["players"]),
  hoverId: null,
  tooltipKey: null,
  sweepAngle: 0,
  screenMarkers: [],
  layout: null,
  lastSeq: -1,
  lastPollAt: 0,
  pollInFlight: false,
  filtersBuilt: false,
  // Display pose — yaw snaps hard so look direction stays accurate
  view: { x: 0, z: 0, yaw: 0 },
  you: { x: 0, z: 0 },
  entityBucketFilter: "all",
  filterCounts: {},
};

els.hostUrl.textContent = window.location.origin;

function saveFilters() {
  try {
    localStorage.setItem(LS_KEY, JSON.stringify(state.filters));
  } catch { /* ignore */ }
}

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function lerpAngle(a, b, t) {
  let d = b - a;
  while (d > Math.PI) d -= Math.PI * 2;
  while (d < -Math.PI) d += Math.PI * 2;
  return a + d * t;
}

function rgbFromClan(c) {
  if (!Array.isArray(c) || c.length < 3) return null;
  const scale = c[0] > 1 || c[1] > 1 || c[2] > 1 ? 1 : 255;
  return `rgb(${Math.round(c[0] * scale)},${Math.round(c[1] * scale)},${Math.round(c[2] * scale)})`;
}

function playerColor(p) {
  if (p.local) return "#3ee7ff";
  if (p.staff) return "#ff7ad1";
  if (p.vip) return "#ffc857";
  if (p.down) return "#8b879c";
  if (p.sz) return "#4fe39a";
  return rgbFromClan(p.clanColor) || "#ff5577";
}

function resolveToggle(item, bucket) {
  if (item.toggle && FILTER_BY_ID[item.toggle]) return item.toggle;
  if (bucket === "players") return "players";
  if (bucket === "waypoints") return "waypoints";
  if (bucket === "npcs") {
    return item.kind === "boss" || item.toggle === "npc_boss" ? "npc_boss" : "npc_soldier";
  }
  // Fallback: match by name against filter labels / ids
  const name = (item.name || "").toLowerCase();
  if (name.includes("sleeper")) return "april_sleeper";
  if (name.includes("dropped") || item.dynamic) return "april_dropped_item";
  for (const f of ALL_FILTERS) {
    if (f.bucket !== bucket) continue;
    const label = f.label.toLowerCase();
    if (name.includes(label.replace(" / gift", "").split(" ")[0])) return f.id;
  }
  // Show unknown under first matching bucket master — use dropped for loot, stone for world, etc.
  if (bucket === "loot") return "april_dropped_item";
  if (bucket === "world") return "april_stone_node";
  if (bucket === "base") return "april_base_cabinet";
  return null;
}

function isVisible(item, bucket) {
  const toggle = resolveToggle(item, bucket);
  if (!toggle) return true;
  return state.filters[toggle] !== false;
}

function resizeCanvas() {
  const wrap = canvas.parentElement;
  const size = Math.min(wrap.clientWidth, 780);
  const dpr = window.devicePixelRatio || 1;
  canvas.width = Math.floor(size * dpr);
  canvas.height = Math.floor(size * dpr);
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}

window.addEventListener("resize", resizeCanvas);
resizeCanvas();

function patchFilterState(ids) {
  const idList = Array.isArray(ids) ? ids : [ids];
  for (const id of idList) {
    const row = els.filterGroups.querySelector(`[data-filter="${id}"]`);
    if (!row) continue;
    const on = state.filters[id] !== false;
    const input = row.querySelector(".switch input");
    if (input) input.checked = on;
  }
}

function syncAccordionBody(item, open) {
  const body = item.querySelector(".acc-body");
  const inner = item.querySelector(".acc-body-inner");
  if (!body || !inner) return;
  if (open) {
    body.style.maxHeight = `${inner.scrollHeight}px`;
    body.style.opacity = "1";
  } else {
    body.style.maxHeight = "0px";
    body.style.opacity = "0";
  }
}

function toggleAccordionGroup(groupId) {
  if (state.openGroups.has(groupId)) state.openGroups.delete(groupId);
  else state.openGroups.add(groupId);
  const item = els.filterGroups.querySelector(`[data-group="${groupId}"]`);
  if (!item) return;
  const open = state.openGroups.has(groupId);
  item.classList.toggle("open", open);
  syncAccordionBody(item, open);
  const trigger = item.querySelector(".acc-trigger");
  if (trigger) trigger.setAttribute("aria-expanded", open ? "true" : "false");
}

function syncAllAccordionHeights() {
  els.filterGroups.querySelectorAll(".acc-item").forEach((item) => {
    syncAccordionBody(item, item.classList.contains("open"));
  });
}

function setGroupFilters(groupId, enabled) {
  const g = FILTER_GROUPS.find((x) => x.id === groupId);
  if (!g) return;
  for (const it of g.items) state.filters[it.id] = enabled;
  saveFilters();
  patchFilterState(g.items.map((it) => it.id));
  if (state.target) renderEntityList(state.target);
}

function buildFiltersUI() {
  const q = (els.filterSearch.value || "").trim().toLowerCase();
  const forceOpen = q.length > 0;

  els.filterGroups.innerHTML = FILTER_GROUPS.map((group) => {
    const items = group.items.filter((it) => !q || it.label.toLowerCase().includes(q) || it.id.includes(q));
    if (!items.length) return "";
    const visibleCount = items.reduce((total, it) => total + (state.filterCounts[it.id] || 0), 0);
    const open = forceOpen || state.openGroups.has(group.id);
    return `<div class="acc-item${open ? " open" : ""}" data-group="${group.id}">
      <div class="acc-head">
        <button type="button" class="acc-trigger" aria-expanded="${open ? "true" : "false"}">
          <span class="acc-trigger-left">
            <svg class="acc-chevron" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 4l4 4-4 4"/></svg>
            <span class="acc-title">${group.title}</span>
          </span>
        </button>
        <span class="acc-trigger-right">
          <button type="button" class="btn-sm" data-group-on="${group.id}">On</button>
          <button type="button" class="btn-sm" data-group-off="${group.id}">Off</button>
          <span class="acc-group-count" data-group-count="${group.id}">${visibleCount}</span>
        </span>
      </div>
      <div class="acc-body">
        <div class="acc-body-inner">
          <div class="acc-items">
            ${items.map((it) => {
              const on = state.filters[it.id] !== false;
              const count = state.filterCounts[it.id] || 0;
              return `<div class="acc-row" data-filter="${it.id}" role="switch" aria-checked="${on ? "true" : "false"}">
                <span class="acc-row-left">
                  <span class="acc-swatch" style="background:${it.color}"></span>
                  <span class="acc-name">${it.label}</span>
                </span>
                <span class="acc-row-count" data-count="${it.id}">${count}</span>
                <label class="switch" aria-hidden="true">
                  <input type="checkbox" ${on ? "checked" : ""} tabindex="-1" />
                  <span class="switch-slider"></span>
                </label>
              </div>`;
            }).join("")}
          </div>
        </div>
      </div>
    </div>`;
  }).join("");

  state.filtersBuilt = true;
  requestAnimationFrame(syncAllAccordionHeights);
}

function updateFilterCounts(data) {
  const counts = {};
  for (const bucket of ["players", "loot", "world", "npcs", "base", "waypoints"]) {
    for (const item of data[bucket] || []) {
      const toggle = resolveToggle(item, bucket);
      if (toggle) counts[toggle] = (counts[toggle] || 0) + 1;
    }
  }
  state.filterCounts = counts;

  // Patch counts only — never rebuild accordion on poll (prevents flash/reset).
  document.querySelectorAll("[data-count]").forEach((node) => {
    node.textContent = String(counts[node.dataset.count] || 0);
  });
  document.querySelectorAll("[data-group-count]").forEach((node) => {
    const g = FILTER_GROUPS.find((x) => x.id === node.dataset.groupCount);
    if (!g) return;
    const total = g.items.reduce((t, it) => t + (counts[it.id] || 0), 0);
    node.textContent = String(total);
  });
}

function buildLegend() {
  const bits = [
    ["#3ee7ff", "You / FWD"],
    ["#ff5577", "Player"],
    ["#ff9a3c", "NPC"],
    ["#ffc857", "Loot"],
    ["#4fe39a", "Resource"],
    ["#8ea0ff", "Base"],
    ["#3ee7ff", "Waypoint"],
  ];
  els.legend.innerHTML = bits.map(([c, t]) => `<span><i style="background:${c};color:${c}"></i>${t}</span>`).join("");
}

function buildEntityTypeChips() {
  const types = [
    ["all", "All"],
    ["loot", "Loot"],
    ["world", "World"],
    ["npcs", "NPCs"],
    ["base", "Base"],
    ["waypoints", "WPs"],
  ];
  els.entityTypeFilters.innerHTML = types.map(([id, label]) =>
    `<button type="button" class="chip-btn ${state.entityBucketFilter === id ? "active" : ""}" data-ebucket="${id}">${label}</button>`
  ).join("");
  els.entityTypeFilters.querySelectorAll("[data-ebucket]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.entityBucketFilter = btn.dataset.ebucket;
      buildEntityTypeChips();
      if (state.target) renderEntityList(state.target);
    });
  });
}

document.querySelectorAll(".sidebar-tab").forEach((tab) => {
  tab.addEventListener("click", () => {
    document.querySelectorAll(".sidebar-tab").forEach((t) => t.classList.remove("active"));
    document.querySelectorAll(".sidebar-pane").forEach((p) => p.classList.remove("active"));
    tab.classList.add("active");
    document.querySelector(`[data-panel="${tab.dataset.tab}"]`).classList.add("active");
    if (state.target && tab.dataset.tab === "players") renderPlayers(state.target);
    if (state.target && tab.dataset.tab === "entities") renderEntityList(state.target);
  });
});

els.filterGroups.addEventListener("click", (e) => {
  const onBtn = e.target.closest("[data-group-on]");
  if (onBtn) {
    e.stopPropagation();
    setGroupFilters(onBtn.dataset.groupOn, true);
    return;
  }
  const offBtn = e.target.closest("[data-group-off]");
  if (offBtn) {
    e.stopPropagation();
    setGroupFilters(offBtn.dataset.groupOff, false);
    return;
  }
  const row = e.target.closest("[data-filter]");
  if (row) {
    const id = row.dataset.filter;
    state.filters[id] = !(state.filters[id] !== false);
    saveFilters();
    patchFilterState(id);
    row.setAttribute("aria-checked", state.filters[id] !== false ? "true" : "false");
    if (state.target) renderEntityList(state.target);
    return;
  }
  const trigger = e.target.closest(".acc-trigger");
  if (trigger) {
    const item = trigger.closest("[data-group]");
    if (item) toggleAccordionGroup(item.dataset.group);
  }
});

els.copyUrl.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(window.location.origin);
    els.copyUrl.textContent = "Copied";
    setTimeout(() => { els.copyUrl.textContent = "Copy"; }, 1000);
  } catch { /* ignore */ }
});

els.btnAllOn.addEventListener("click", () => {
  for (const f of ALL_FILTERS) state.filters[f.id] = true;
  saveFilters();
  patchFilterState(ALL_FILTERS.map((f) => f.id));
  if (state.target) renderEntityList(state.target);
});

els.btnAllOff.addEventListener("click", () => {
  for (const f of ALL_FILTERS) state.filters[f.id] = false;
  saveFilters();
  patchFilterState(ALL_FILTERS.map((f) => f.id));
  if (state.target) renderEntityList(state.target);
});

els.filterSearch.addEventListener("input", buildFiltersUI);

function roundRect(x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function drawBackground(x, y, size) {
  const g = ctx.createLinearGradient(x, y, x + size, y + size);
  g.addColorStop(0, "rgba(16, 28, 42, 1)");
  g.addColorStop(0.55, "rgba(8, 15, 24, 1)");
  g.addColorStop(1, "rgba(5, 10, 17, 1)");
  ctx.fillStyle = g;
  ctx.fillRect(x, y, size, size);
  ctx.strokeStyle = "rgba(86, 215, 255, 0.38)";
  ctx.lineWidth = 1;
  ctx.strokeRect(x + 0.5, y + 0.5, size - 1, size - 1);
}

function drawGrid(x, y, size, zoom) {
  const half = size * 0.5;
  const step = size / 8;
  ctx.strokeStyle = "rgba(105, 152, 190, 0.13)";
  ctx.lineWidth = 1;
  for (let i = 1; i < 8; i += 1) {
    const p = x + i * step;
    ctx.beginPath();
    ctx.moveTo(p, y);
    ctx.lineTo(p, y + size);
    ctx.stroke();
    const q = y + i * step;
    ctx.beginPath();
    ctx.moveTo(x, q);
    ctx.lineTo(x + size, q);
    ctx.stroke();
  }
  ctx.strokeStyle = "rgba(86, 215, 255, 0.33)";
  ctx.beginPath();
  ctx.moveTo(x + half, y);
  ctx.lineTo(x + half, y + size);
  ctx.moveTo(x, y + half);
  ctx.lineTo(x + size, y + half);
  ctx.stroke();
  const meters = Math.round(140 / Math.max(zoom, 0.15));
  ctx.fillStyle = "rgba(154,148,173,0.8)";
  ctx.font = "500 10px JetBrains Mono, monospace";
  ctx.fillText(`${meters}m`, x + half + 6, y + size * 0.25);
}

function drawSweep(cx, cy, size) {
  if (!els.sweep.checked) return;
  state.sweepAngle = (state.sweepAngle + 0.016) % (Math.PI * 2);
  ctx.save();
  ctx.translate(cx, cy);
  ctx.rotate(state.sweepAngle);
  const radius = size * 0.74;
  const grad = ctx.createLinearGradient(0, 0, 0, -radius);
  grad.addColorStop(0, "rgba(62,231,255,0)");
  grad.addColorStop(1, "rgba(62,231,255,0.14)");
  ctx.fillStyle = grad;
  ctx.beginPath();
  ctx.moveTo(0, 0);
  ctx.arc(0, 0, radius, -0.18, 0);
  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

function drawBlip(x, y, color, size, shape, alpha, glow) {
  ctx.globalAlpha = alpha;
  ctx.shadowColor = glow ? color : "transparent";
  ctx.shadowBlur = glow ? 16 : 0;
  ctx.strokeStyle = "rgba(255,255,255,0.3)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  if (shape === "square") {
    ctx.rect(x - size, y - size, size * 2, size * 2);
    ctx.fillStyle = color;
  } else if (shape === "diamond") {
    ctx.moveTo(x, y - size - 1);
    ctx.lineTo(x + size + 1, y);
    ctx.lineTo(x, y + size + 1);
    ctx.lineTo(x - size - 1, y);
    ctx.closePath();
    ctx.fillStyle = color;
  } else {
    ctx.arc(x, y, size + 2.5, 0, Math.PI * 2);
    ctx.fillStyle = `${color}30`;
    ctx.fill();
    ctx.beginPath();
    ctx.arc(x, y, size, 0, Math.PI * 2);
    ctx.fillStyle = color;
  }
  ctx.fill();
  ctx.stroke();
  ctx.shadowBlur = 0;
  ctx.globalAlpha = 1;
}

function drawLabel(x, y, text, color) {
  ctx.font = "600 10px Inter, sans-serif";
  const w = ctx.measureText(text).width + 10;
  const lx = x - w / 2;
  const ly = y + 9;
  ctx.fillStyle = "rgba(6,6,12,0.9)";
  ctx.strokeStyle = "rgba(212,72,255,0.28)";
  roundRect(lx, ly, w, 16, 5);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = color;
  ctx.fillText(text, lx + 5, ly + 12);
}

function shapeFor(bucket, toggle) {
  if (bucket === "loot") return "square";
  if (bucket === "world" || bucket === "base") return "diamond";
  return "circle";
}

function sizeFor(bucket) {
  if (bucket === "players" || bucket === "npcs") return 4.8;
  if (bucket === "waypoints") return 5.2;
  return 3.4;
}

function markerHoverKey(item) {
  return `${item.bucket}:${item.id || item.name || "?"}`;
}

function collectMarkers(data) {
  const buckets = [
    ["world", data.world],
    ["base", data.base],
    ["loot", data.loot],
    ["npcs", data.npcs],
    ["waypoints", data.waypoints],
    ["players", data.players],
  ];
  const out = [];
  const counts = {};

  for (const [bucket, list] of buckets) {
    for (const item of list || []) {
      const toggle = resolveToggle(item, bucket);
      if (toggle) counts[toggle] = (counts[toggle] || 0) + 1;
      if (!isVisible(item, bucket)) continue;
      const color = bucket === "players"
        ? playerColor(item)
        : (FILTER_BY_ID[toggle]?.color || "#ffffff");
      out.push({
        ...item,
        bucket,
        toggle,
        color,
        shape: shapeFor(bucket, toggle),
        size: sizeFor(bucket),
        mid: item.id || `${bucket}:${item.name}:${item.x}:${item.z}`,
      });
    }
  }

  state.filterCounts = counts;
  return out;
}

function stepPose(dt) {
  if (!state.target?.ok) return;
  const smooth = els.trail.checked;
  // Positions smooth; yaw nearly snaps so look direction stays accurate
  const tp = smooth ? Math.min(1, dt * 16) : 1;
  const ty = smooth ? Math.min(1, dt * 28) : 1;
  const tv = state.target.view;
  const tyou = state.target.you;
  state.view.x = lerp(state.view.x, tv.x, tp);
  state.view.z = lerp(state.view.z, tv.z, tp);
  state.view.yaw = lerpAngle(state.view.yaw, tv.yaw, ty);
  state.you.x = lerp(state.you.x, tyou.x, tp);
  state.you.z = lerp(state.you.z, tyou.z, tp);
}

function drawFrame() {
  if (!state.target?.ok) return;

  const size = canvas.clientWidth;
  const cx = size / 2;
  const cy = size / 2;
  // Match in-game zoom feel (april_map_zoom ~1 → similar density)
  const zoom = Number(els.zoom.value) * 2.35;
  const layout = { x: 0, y: 0, size, cx, cy, zoom };
  state.layout = layout;

  const view = state.view;
  const markers = collectMarkers(state.target);

  ctx.clearRect(0, 0, size, size);
  drawBackground(0, 0, size);
  drawGrid(0, 0, size, zoom);
  drawSweep(cx, cy, size);

  state.screenMarkers = [];

  for (const item of markers) {
    const mapped = worldToMap(item.x, item.z, view.x, view.z, cx, cy, zoom, view.yaw);
    const clamped = clampSquare(mapped.x, mapped.y, 0, 0, size);
    const hover = state.hoverId === markerHoverKey(item);
    drawBlip(clamped.x, clamped.y, item.color, item.size, item.shape, clamped.clamped ? 0.5 : 1, hover);

    if (hover) {
      ctx.strokeStyle = "rgba(255,255,255,0.9)";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(clamped.x, clamped.y, item.size + 7, 0, Math.PI * 2);
      ctx.stroke();
    }

    if (els.labels.checked && !clamped.clamped && (item.bucket === "players" || item.bucket === "npcs" || item.bucket === "waypoints" || hover)) {
      const label = item.name || "?";
      drawLabel(clamped.x, clamped.y, label.length > 18 ? `${label.slice(0, 17)}…` : label, item.color);
    }

    state.screenMarkers.push({ ...item, sx: clamped.x, sy: clamped.y, clamped: clamped.clamped });
  }

  // Local player: always facing screen-up (forward). Body offset from camera shown as small blip.
  const body = worldToMap(state.you.x, state.you.z, view.x, view.z, cx, cy, zoom, view.yaw);
  const bodyClamped = clampSquare(body.x, body.y, 0, 0, size);

  ctx.fillStyle = "rgba(62,231,255,0.2)";
  ctx.strokeStyle = "rgba(62,231,255,0.98)";
  ctx.lineWidth = 2.2;
  ctx.beginPath();
  ctx.moveTo(cx, cy - 15);
  ctx.lineTo(cx - 9, cy + 9);
  ctx.lineTo(cx + 9, cy + 9);
  ctx.closePath();
  ctx.fill();
  ctx.stroke();

  if (Math.hypot(bodyClamped.x - cx, bodyClamped.y - cy) > 3) {
    ctx.strokeStyle = "rgba(62,231,255,0.45)";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(bodyClamped.x, bodyClamped.y);
    ctx.lineTo(cx, cy);
    ctx.stroke();
    drawBlip(bodyClamped.x, bodyClamped.y, "#3ee7ff", 3.5, "circle", 0.85, false);
  }

  els.markerCount.textContent = String(state.screenMarkers.length);
}

function setStatus(mode, text) {
  els.statusPill.className = `status-badge ${mode}`;
  els.statusText.textContent = text;
  els.waitingCard.classList.toggle("show", mode === "wait");
}

function tooltipHtml(hit) {
  const filter = FILTER_BY_ID[hit.toggle];
  const kind = filter?.label || hit.bucket;
  const rows = [];
  if (hit.dist != null) rows.push(`${Math.round(hit.dist)}m away`);
  if (hit.hp != null) rows.push(`HP ${Math.round(hit.hp)} / ${Math.round(hit.maxHp || 100)}`);
  if (hit.y != null) rows.push(`Height ${Math.round(hit.y)}`);
  if (hit.x != null) rows.push(`X ${Math.round(hit.x)} · Z ${Math.round(hit.z)}`);
  if (hit.kind) rows.push(`Kind ${hit.kind}`);
  if (hit.live) rows.push("Live entity");
  if (hit.dynamic) rows.push("Dynamic");
  if (hit.slot) rows.push(`Slot ${hit.slot}`);

  const flags = [];
  if (hit.local) flags.push("You");
  if (hit.vip) flags.push("VIP");
  if (hit.sz) flags.push("Safezone");
  if (hit.down) flags.push("Downed");
  if (hit.reviving) flags.push("Reviving");
  if (hit.staff) flags.push(hit.staff);
  if (hit.clan) flags.push(`[${hit.clan}]`);

  return `<strong>${escapeHtml(hit.name || "?")}</strong>
    <span class="tt-kind">${escapeHtml(kind)}</span>
    ${rows.map((r) => `<div class="tt-row">${escapeHtml(r)}</div>`).join("")}
    ${flags.length ? `<div class="tt-flags">${flags.map((f) => `<span class="tag">${escapeHtml(f)}</span>`).join("")}</div>` : ""}`;
}

function hideTooltip() {
  els.tooltip.classList.remove("visible");
  window.setTimeout(() => {
    if (!state.hoverId) els.tooltip.hidden = true;
  }, 150);
}

canvas.addEventListener("mousemove", (ev) => {
  if (!state.layout || !state.screenMarkers.length) {
    state.hoverId = null;
    hideTooltip();
    return;
  }
  const rect = canvas.getBoundingClientRect();
  const x = ev.clientX - rect.left;
  const y = ev.clientY - rect.top;
  let hit = null;
  let best = Infinity;
  for (const m of state.screenMarkers) {
    const d = Math.hypot(m.sx - x, m.sy - y);
    if (d <= m.size + 9 && d < best) {
      best = d;
      hit = m;
    }
  }
  state.hoverId = hit ? markerHoverKey(hit) : null;
  if (!hit) {
    hideTooltip();
    state.tooltipKey = null;
    return;
  }
  const tooltipKey = markerHoverKey(hit);
  if (state.tooltipKey !== tooltipKey) {
    els.tooltip.innerHTML = tooltipHtml(hit);
    state.tooltipKey = tooltipKey;
  }
  els.tooltip.hidden = false;
  els.tooltip.style.left = `${Math.min(rect.width - 220, x + 14)}px`;
  els.tooltip.style.top = `${Math.max(8, y - 14)}px`;
  requestAnimationFrame(() => els.tooltip.classList.add("visible"));
});

canvas.addEventListener("mouseleave", () => {
  state.hoverId = null;
  state.tooltipKey = null;
  hideTooltip();
});

function renderPlayers(data) {
  const q = els.playerSearch.value.trim().toLowerCase();
  const players = (data.players || [])
    .slice()
    .sort((a, b) => (a.dist || 0) - (b.dist || 0))
    .filter((p) => !q || (p.name || "").toLowerCase().includes(q) || (p.clan || "").toLowerCase().includes(q));

  els.playerCount.textContent = String((data.players || []).length);

  if (!players.length) {
    els.playerList.innerHTML = `<li class="empty">${q ? "No match." : "No players."}</li>`;
    return;
  }

  els.playerList.innerHTML = players.map((p) => {
    const hp = Math.max(0, Math.round(p.hp || 0));
    const maxHp = Math.max(1, Math.round(p.maxHp || 100));
    const pct = Math.max(0, Math.min(100, (hp / maxHp) * 100));
    const pills = [
      p.local ? `<span class="tag you">You</span>` : "",
      p.vip ? `<span class="tag vip">VIP</span>` : "",
      p.sz ? `<span class="tag sz">SZ</span>` : "",
      p.down ? `<span class="tag">Down</span>` : "",
      p.reviving ? `<span class="tag">Revive</span>` : "",
      p.staff ? `<span class="tag staff">${escapeHtml(p.staff)}</span>` : "",
      p.clan ? `<span class="tag">${escapeHtml(p.clan)}</span>` : "",
    ].join("");
    return `<li class="list-item">
      <div class="list-item-top">
        <div class="list-item-name" style="color:${playerColor(p)}">${escapeHtml(p.name || "?")}</div>
        <div class="list-item-dist">${Math.round(p.dist || 0)}m</div>
      </div>
      <div class="list-item-meta">${pills || `<span class="tag">Player</span>`}</div>
      <div class="hp-track"><div class="hp-fill" style="width:${pct}%"></div></div>
    </li>`;
  }).join("");
}

function renderEntityList(data) {
  const q = els.entitySearch.value.trim().toLowerCase();
  const want = state.entityBucketFilter;
  const rows = [];
  for (const bucket of ["loot", "world", "npcs", "base", "waypoints"]) {
    if (want !== "all" && want !== bucket) continue;
    for (const item of data[bucket] || []) {
      if (!isVisible(item, bucket)) continue;
      const toggle = resolveToggle(item, bucket);
      const filter = FILTER_BY_ID[toggle];
      rows.push({
        ...item,
        bucket,
        kindLabel: filter?.label || bucket,
        color: filter?.color || "#fff",
      });
    }
  }
  rows.sort((a, b) => (a.dist || 0) - (b.dist || 0));
  const filtered = rows.filter((r) =>
    !q || (r.name || "").toLowerCase().includes(q) || r.kindLabel.toLowerCase().includes(q)
  );

  if (!filtered.length) {
    els.entityList.innerHTML = `<li class="empty">${q ? "No match." : "No markers (enable filters / wait for scans)."}</li>`;
    return;
  }

  els.entityList.innerHTML = filtered.slice(0, 200).map((r) =>
    `<li class="list-item">
      <div class="list-item-top">
        <div class="list-item-name" style="color:${r.color}">${escapeHtml(r.name || "?")}</div>
        <div class="list-item-dist">${Math.round(r.dist || 0)}m</div>
      </div>
      <div class="list-item-meta"><span class="tag">${escapeHtml(r.kindLabel)}</span></div>
    </li>`
  ).join("");
}

function updateHud(data) {
  const c = data.counts || {};
  els.countsLine.textContent =
    `P:${c.players ?? (data.players || []).length} L:${c.loot ?? (data.loot || []).length} N:${c.npcs ?? (data.npcs || []).length} W:${c.world ?? (data.world || []).length} B:${c.base ?? (data.base || []).length} WP:${c.waypoints ?? (data.waypoints || []).length}`;
  const you = data.you || {};
  const yawDeg = Math.round(((data.view?.yaw || 0) * 180) / Math.PI);
  els.yawDeg.textContent = `${yawDeg}°`;
  els.youLine.textContent = `You — ${you.name || "?"} · HP ${Math.round(you.hp || 0)}/${Math.round(you.maxHp || 100)} · looking ${yawDeg}°`;
  els.placeLine.textContent = `Place — ${data.place || "?"}`;
  els.seqLine.textContent = `Seq — ${data.seq || 0} · ${new Date().toLocaleTimeString()}`;
}

async function pollOnce() {
  if (state.pollInFlight) return;
  state.pollInFlight = true;
  const t0 = performance.now();
  try {
    const res = await fetch(`/api/radar?t=${Date.now()}`, { cache: "no-store" });
    const raw = await res.text();
    let data;
    try {
      data = JSON.parse(raw);
    } catch {
      setStatus("wait", "Bad data — reload April v3.86.5+");
      return;
    }

    if (!data.ok || data.waiting) {
      setStatus("wait", data.message || "Waiting for April");
      return;
    }

    const first = !state.target;
    state.target = data;
    if (first) {
      state.view = { x: data.view.x, z: data.view.z, yaw: data.view.yaw };
      state.you = { x: data.you.x, z: data.you.z };
    }

    if (data.seq !== state.lastSeq) {
      state.lastSeq = data.seq;
      updateFilterCounts(data);
      // Only update off-screen lists when the user has asked to view them.
      // This keeps hover/controls visually stable while the feed is live.
      const activeTab = document.querySelector(".sidebar-tab.active")?.dataset.tab;
      if (activeTab === "players") renderPlayers(data);
      if (activeTab === "entities") renderEntityList(data);
      updateHud(data);
    }

    setStatus("live", "Live");
    els.updateMs.textContent = `${Math.max(0, Math.round(performance.now() - t0))}ms`;
    state.lastPollAt = performance.now();
  } catch {
    if (performance.now() - state.lastPollAt > 2500) setStatus("wait", "Server offline");
  } finally {
    state.pollInFlight = false;
  }
}

let lastFrame = performance.now();
function frame(now) {
  const dt = Math.min(0.05, (now - lastFrame) / 1000);
  lastFrame = now;
  stepPose(dt);
  drawFrame();
  requestAnimationFrame(frame);
}

els.playerSearch.addEventListener("input", () => state.target && renderPlayers(state.target));
els.entitySearch.addEventListener("input", () => state.target && renderEntityList(state.target));

buildFiltersUI();
buildLegend();
buildEntityTypeChips();
pollOnce();
setInterval(pollOnce, 50);
requestAnimationFrame(frame);

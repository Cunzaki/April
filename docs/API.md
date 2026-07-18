# Vector Lua Engine — API Reference (April)

> **Source:** [Vector Lua Engine GitBook](https://project-vector-1.gitbook.io/vector-lua-engine) via MCP (`vector-lua-engine`), last synced **2026-07-06 (API 1.4)**.  
> **Audience:** AI agents and developers working on April v3.34+. Read the relevant section before implementing features.

---

## API 1.4 highlights (April uses these)

| Feature | What changed | April usage |
|---------|--------------|-------------|
| `raycast.cast` | Full closest-hit raycast (position, distance, instance, terrain) | Inf Fly ground check in `features/movement/exploits.lua` |
| Silent raycast hook | `enable_silent_hook`, `track_silent_target`, `set_silent_target` | `core/silent_ray.lua` + `features/combat/aimbot.lua` |
| Async GC | `refreshgc` / `getgc` / `applygc` never block; background scans | Gun mods apply on toggle; skip `refreshgc` when nodes already warm |
| RunService | `game.get_service("RunService")` | `core/runservice.lua` — movement sim on Heartbeat when Connect works |
| Checkbox keybind modes | Right-click key → **Always / Hold / Toggle** | Use `settings.enabled(id)` — no custom Hold/Toggle combos |
| `raycast.is_visible` | Checks parts **and terrain** | Targeting visibility filter |
| `raycast.is_player_visible` | Cached per-player visibility (~16 ms) | Preferred over per-frame `is_visible` loops |
| GPU instance chams | `exploits.ApplyChamsToInstance` / mode+color setters (not on GitBook yet) | Loot/resource/base ESP chams via `core/gpu_chams.lua` |

---

## Table of contents

| # | Section | When to read |
|---|---------|--------------|
| 1 | [Overview](#1-overview) | Every session — naming, globals, lifecycle |
| 2 | [Rules (must follow)](#2-rules-must-follow) | Before any feature work |
| 3 | [Callbacks](#3-callbacks) | Frame loop, player events |
| 4 | [Draw API](#4-draw-api) | ESP, overlays, images |
| 5 | [Entity API](#5-entity-api) | Players, bones, bounds |
| 6 | [Game API](#6-game-api) | Instances, camera, input, part |
| 7 | [RunService](#7-runservice) | Movement sim timing (API 1.4) |
| 8 | [GC API](#8-gc-api) | Weapon mods, Lua heap patches |
| 9 | [Menu API](#9-menu-api) | UI controls, keybind modes |
| 10 | [Utility API](#10-utility-api) | W2S, timing, input sim, HTTP |
| 11 | [Thread API](#11-thread-api) | Background timers |
| 12 | [Raycast API](#12-raycast-api) | Visibility + silent hook |
| 13 | [Memory API](#13-memory-api) | Raw address reads/writes |
| 14 | [FFlag API](#14-fflag-api) | Roblox fast flags |
| 15 | [Exploits API — GPU chams](#15-exploits-api--gpu-chams) | Native GPU instance chams (pre-docs) |
| 16 | [April notes](#16-april-project-notes) | Fallen-specific conventions |

---

## 1. Overview

The Vector Lua Engine runs **sandboxed Lua 5.1** scripts inside Project Vector. Scripts read game state, draw overlays, register menu controls, and run background tasks.

### Naming convention

Every API function is registered under **three styles**. Pick one and stay consistent:

| Style | Example |
|-------|---------|
| `snake_case` | `entity.get_players()` |
| `camelCase` | `entity.getPlayers()` |
| `PascalCase` | `entity.GetPlayers()` |

All examples below use `snake_case`.

### Global objects

| Global | Purpose |
|--------|---------|
| `draw` | 2D rendering — lines, boxes, text, circles, images, chams |
| `entity` | Player cache, bones, bounds, live properties |
| `game` | Roblox DataModel — services, instances, properties |
| `camera` | Camera position, look vector, FOV, `look_at` |
| `input` | Key state, mouse, screen center |
| `part` | Direct memory writes to part properties |
| `menu` | Cheat menu UI — add/read/write controls |
| `thread` | Background interval callbacks |
| `utility` | W2S, delta time, FPS, validity, input sim, HTTP |
| `raycast` | Cached player visibility + live ray tests + silent hook |
| `memory` | Raw process memory read/write |
| `fflag` | Roblox Fast Flag read/write |
| `exploits` | Native exploit helpers — **GPU instance chams** (see §15) |
| `Vector3` | 3D vector constructor |
| `print` | Script console output |

**GC globals** (not tables — top-level functions): `refreshgc`, `getgc`, `applygc`, `dumpgc`, `setgc`.

### Lua environment

| Available | Removed / blocked |
|-----------|-------------------|
| `table`, `string`, `math`, `bit`, `os`, `io`, `loadstring` | `loadfile`, `dofile`, `load` |
| `os.time`, `os.date`, `os.clock` | `os.execute`, `os.exit`, `os.remove` |
| `io.open`, `io.read`, `io.write` | `io.popen` |
| `tostring`, `tonumber`, `type`, `pairs`, `ipairs` | `string.dump`, `collectgarbage` |

There is **no `task` global**. Use `thread.create(fn, interval_ms)` for delayed/periodic work.

### Script lifecycle

```
Script loaded
  └─ Top-level code runs once (menu registration, thread setup)
        └─ Callbacks defined

Every frame
  └─ on_frame() — all drawing happens here

Player join/leave
  └─ on_player_added(player) / on_player_removed(player)

Script unloaded
  └─ Threads stopped, menu elements cleared
```

### Minimal script

```lua
menu.add_tab("Demo", "D")
menu.add_group("Demo", "Main")
menu.add_checkbox("Demo", "Main", "demo_on", "Enable", false)

function on_frame()
    if not menu.get("demo_on") then return end
    draw.text(10, 10, "April", {1, 1, 1, 1})
end
```

---

## 2. Rules (must follow)

### Engine rules

| Rule | Detail |
|------|--------|
| Draw in `on_frame` only | `draw.*` outside `on_frame` has no effect |
| Menu at top level | Register controls once at script load, not every frame |
| Threads guarded | Never call `thread.create` unconditionally in `on_frame` |
| Read menu every frame | Use `menu.get(id)` in `on_frame` — do not cache toggle state |
| Validate instances | `utility.is_valid(inst)` before property access on stale refs |
| Cache live reads | `p.health`, `p.position` are live memory reads — cache if used multiple times per frame |
| Delta time | Use `utility.get_delta_time()` for movement/animation |

### Keybound master toggles (API 1.4)

Checkboxes with `{ key = vk }` support **Always / Hold / Toggle** (right-click the key in menu). There is **no** `menu.get_key_mode` — the mode is user-side only.

```lua
-- WRONG for keybound masters — ignores Hold/Toggle gating
if settings.bool("april_world_enabled", false) then ... end

-- CORRECT — respects Always/Hold/Toggle
if settings.enabled("april_world_enabled") then ... end
```

Use `settings.bool` only for **child options** without their own key (colors, sub-toggles under a master).

### GC rules (Fallen / weapon mods)

| Rule | Detail |
|------|--------|
| **Never `getgc(true)`** when `refreshgc`/`applygc` exist | Poisons the node cache → returns 0 nodes |
| Call `refreshgc()` once at start | Cheap when cache valid; rescans on background thread when stale |
| `getgc` then `applygc` | Warm cache with key list, then patch |
| Re-apply on interval | Games reset values — use `thread.create` loop |
| Writable via GC | `number`, `bool` only — not `string`, `table`, `function`, `userdata` |
| Non-blocking (1.4) | Safe every frame; April still applies gun mods on toggle only |

### April-specific

| Rule | Detail |
|------|--------|
| Images | Load once; `draw.image` every frame with **0–255 RGBA** args |
| Image URLs | One direct HTTPS URL per asset — no fallback chains |
| Menu labels | Unique `id` **and** unique `label` text per tab+group |
| Fallen AC | Avoid writing `WalkSpeed` — prefer velocity/root movement |
| Farm GC | **Do not** patch `Cooldown` / melee tables — ban risk |
| Movement sim | Register via `core/runservice.lua` `on_sim()` — not raw `on_frame` poll |

---

## 3. Callbacks

Scripts respond to engine events by defining **global functions**. The engine calls them automatically.

### `on_frame`

Called every render frame. **All drawing must happen here.**

```lua
function on_frame()
    local dt = utility.get_delta_time()
    draw.text(10, 10, string.format("dt=%.3f", dt), {1, 1, 1, 1})
end
```

### `on_player_added(player)`

```lua
function on_player_added(player)
    print(player.name .. " joined")
end
```

### `on_player_removed(player)`

```lua
function on_player_removed(player)
    print(player.name .. " left")
end
```

### April frame flow

April registers `on_frame` via `core/debug.lua` → `app.on_frame()` → `menu/tabs.lua`:

1. `runservice.dispatch(dt)` — movement sim (Heartbeat or fallback)
2. `scheduler.tick()` — timed scan jobs
3. Feature `update(dt)` / `draw()` loops

---

## 4. Draw API

2D overlay rendering. Origin: **top-left**. X right, Y down.

**Colors:** Normalized RGBA `{r, g, b, a}` with components **0.0–1.0** for primitives/text.  
**Exception — `draw.image`:** April uses separate **0–255** integer args (see Images).

### Primitives

| Function | Signature | Notes |
|----------|-----------|-------|
| `draw.line` | `(x1,y1, x2,y2, color, thickness?)` | Default thickness `1.0` |
| `draw.rect` | `(x,y,w,h, color, rounding?, thickness?)` | Outlined rect |
| `draw.rect_filled` | `(x,y,w,h, color, rounding?)` | Filled rect |
| `draw.circle` | `(x,y,radius, color, segments?, thickness?)` | Default 32 segments |
| `draw.circle_filled` | `(x,y,radius, color, segments?)` | Filled circle |
| `draw.text` | `(x,y,text, color, size?)` | Black outline auto; default size 14 |
| `draw.get_text_size` | `(text, size?)` → `w, h` | Measure text |

### ESP helpers

| Function | Signature | Notes |
|----------|-----------|-------|
| `draw.box` | `(x,y,w,h, color, rounding?, style?)` | `style`: 0=full, 1=corners |
| `draw.corner_box` | `(x,y,w,h, color)` | Corner segments only |
| `draw.health_bar` | `(x,y,height, health, max_health)` | Vertical green→red bar |
| `draw.world_to_screen` | `(x,y,z)` → `sx,sy,visible` | Behind camera → `0,0,false` |
| `draw.get_screen_size` | `()` → `w,h` | Render resolution |
| `draw.window` | `(x,y,id,title,items)` | Floating info panel |

### Polygons & chams

| Function | Notes |
|----------|-------|
| `draw.poly` / `draw.poly_closed` | Open / closed polylines |
| `draw.poly_filled` | **Convex hull order required** |
| `draw.compute_hull` | Sort points for `poly_filled` |
| `draw.chams_player` | `style`: 0=filled, 1=outline, 2=glow |
| `draw.get_player_hulls` | Per-body-part polygons |

### Images

Async download on background thread. Same URL → same handle (deduplicated).

| Function | Returns | Description |
|----------|---------|-------------|
| `draw.load_image(url)` | handle | Start download; safe to call every frame |
| `draw.image_loaded(handle)` | bool | True when GPU-ready |
| `draw.image_failed(handle)` | bool | Download/decode failed |
| `draw.image_size(handle)` | w, h | Native dimensions |
| `draw.free_image(handle)` | — | Release texture |
| `draw.image(handle,x,y,w,h)` | — | Draw scaled |
| `draw.image(handle,x,y,w,h, color)` | — | Tint table `{r,g,b,a}` 0–1 |

**Supported URL formats:** HTTPS, `http://www.roblox.com/asset/?id=`, `rbxassetid://`

#### April image pattern (0–255 color args)

```lua
local icon = nil

function on_frame()
    if icon == nil then
        icon = draw.load_image("https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/items/123.png")
        return
    end
    if draw.image_failed(icon) then return end
    draw.image(icon, 10, 10, 64, 64, 255, 255, 255, 255)
end
```

Item CDN: `https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/items/{id}.png`

---

## 5. Entity API

Player objects are **frame snapshots**. Properties marked **live** re-read memory on every access.

### Module functions

| Function | Returns | Description |
|----------|---------|-------------|
| `entity.get_players()` | table | All valid players (includes workspace NPCs/bots) |
| `entity.get_local_player()` | player/nil | Local player |
| `entity.get_player_count()` | number | Count in cache |

### Live properties (memory read each access)

`health`, `max_health`, `is_alive`, `position`, `velocity`, `head_position`, `walk_speed`, `state`, `state_name`, …

### Player methods

| Method | Returns | Description |
|--------|---------|-------------|
| `:get_bone_screen(name)` | x, y, visible | Single bone W2S |
| `:get_bones_screen()` | table | All bones → `{ ["Head"] = {x,y}, ... }` |
| `:get_bounds()` | `{x,y,w,h,valid}` | Screen bounding box |
| `:distance_to(point?)` | number | To point or camera if omitted |

### ESP loop template

```lua
function on_frame()
    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end

        local b = p:get_bounds()
        if not b.valid then goto continue end

        local hp, max = p.health, p.max_health
        draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
        draw.health_bar(b.x - 6, b.y, b.h, hp, max)

        ::continue::
    end
end
```

---

## 6. Game API

Mirrors Roblox DataModel. Five globals: `game`, `camera`, `input`, `part`, `Vector3`.

### `game` root

| Property | Type | Description |
|----------|------|-------------|
| `game.workspace` | Instance | Workspace |
| `game.players` | Instance | Players service |
| `game.local_player` | Instance | Local player |
| `game.place_id` | number | Place ID |
| `game.game_id` | number | Game ID |

### `game.get_service(name)`

Supported services: `ReplicatedStorage`, `ReplicatedFirst`, `StarterGui`, `StarterPack`, `StarterPlayer`, `Teams`, `SoundService`, `Chat`, **`RunService`**.

```lua
local rep = game.get_service("ReplicatedStorage")
local rs  = game.get_service("RunService")
```

### Instance methods

`:get_children()`, `:get_descendants()`, `:find_first_child(name)`, `:find_first_child_of_class(class)`, `:is_a(class_name)`, `:get_attribute(name)`, `:set_attribute(name, value)`, …

Always validate: `utility.is_valid(inst)` before reads on cached refs.

### `camera` global

```lua
local pos  = camera.get_position()
local look = camera.get_look_vector()
camera.look_at(target_vec3)       -- snap
camera.look_at(x, y, z, 10)       -- smooth ~10 frames
camera.set_fov(90)
```

### `input` global

| VK | Key |
|----|-----|
| `0x01` | LMB |
| `0x02` | RMB |
| `0x10` | Shift |
| `0x11` | Ctrl |
| `0x20` | Space |
| `0x1B` | Escape |

```lua
if input.is_key_down(0x01) then ... end
local cx, cy = input.get_screen_center()
```

**Mouse wheel (custom UI):** Vector only documents `utility.mouse_scroll(amount)` to *simulate* scroll. There is **no documented wheel reader** for draw-only menus. Native `menu.add_*` panels scroll with the wheel automatically. April's custom draw UI uses **edge hover scroll** — move the cursor near the top or bottom of a column or open dropdown list to scroll.

### `part` global (direct memory writes)

```lua
part.set_velocity(root, 0, 100, 0)
part.set_can_collide(root, false)
part.set_anchored(root, true)
```

### Humanoid states (reference)

| Value | Name |
|-------|------|
| 5 | Freefall |
| 6 | Flying |
| 8 | Running |
| 12 | Climbing |
| 15 | Dead |

---

## 7. RunService

**API 1.4** exposes `RunService` via `game.get_service("RunService")`. Fallen game scripts use it for Heartbeat/RenderStepped timing; Vector mirrors the DataModel service object.

### What the GitBook documents

The official Game API documents **retrieving** RunService. It does **not** yet document event `:Connect()` in prose — but mirrored instances may expose Roblox-style events (`Heartbeat`, `RenderStepped`, `Stepped`) when the service is valid.

### April pattern — `core/runservice.lua`

```lua
local runservice = April.require("core.runservice")

-- Gate movement features (Mod Checker / Name Hider work without RunService)
if not runservice.movement_allowed() then return end

-- Register physics/movement tick — runs on Heartbeat when Connect works
runservice.on_sim(function(dt)
    -- velocity writes, fly, spider, etc.
end)

-- Called once per on_frame from menu/tabs.lua (fallback if Heartbeat unavailable)
runservice.dispatch(dt)
```

| Function | Description |
|----------|-------------|
| `runservice.get()` | Cached RunService instance or nil |
| `runservice.available()` | Same as `get() ~= nil` |
| `runservice.movement_allowed()` | Required for Inf Fly, Spider, Desync, Freecam, Bullet Manip |
| `runservice.on_sim(fn)` | Register movement callback; tries Heartbeat Connect |
| `runservice.dispatch(dt)` | Runs sim hooks when Heartbeat not connected |
| `runservice.uses_heartbeat()` | True when native Heartbeat hook active |

### Example — Inf Fly ground check with `raycast.cast`

```lua
runservice.on_sim(function(_dt)
    if not settings.enabled("april_noclip_enabled") then return end

    local root = get_root()
    local pos = root and root.Position
    if not pos then return end

    if not raycast.is_ready() then return end
    local hit, _, dist = raycast.cast(
        pos.x, pos.y, pos.z,
        pos.x, pos.y - 1000, pos.z
    )
    if hit and dist > 4 and hum.State == 6 then
        -- one-frame Y velocity pulse (Fallen infinite fly)
    end
end)
```

### Roblox reference (game scripts)

Fallen's own scripts connect like this (dump reference — not guaranteed identical in Vector):

```lua
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
    -- per-tick logic
end)
```

April probes `Heartbeat:Connect` / `RenderStepped:Connect` via `core/runservice.lua` and falls back to `on_frame` dispatch.

---

## 8. GC API

Direct read/write of **Lua VM runtime tables** in process memory. Bypasses the DataModel — weapon stats, multipliers, heap-only config.

### Async behavior (API 1.4)

| Function | Blocking? | Notes |
|----------|-----------|-------|
| `refreshgc()` | **No** | Cheap if cache valid; background rescan when stale |
| `getgc(keys)` | **No** | Queues background scan; returns cached count immediately |
| `applygc(keys, values)` | **No** | Throttled; cache miss queues scan instead of inline walk |
| `dumpgc(path)` | **Yes** (1–3 s) | Never in a loop |
| `setgc(target, patches)` | Throttled | Prefer `applygc` for per-frame use |

If `applygc` returns `0`: VMs may have restarted (`refreshgc()` + retry) or background scan still in flight (call again next frame).

### Functions

#### `refreshgc()` → number

```lua
local vms = refreshgc()
print("VMs: " .. vms)
```

Call at script start and after teleport. Safe every frame.

#### `getgc(keys)` → number

Pre-warms node cache. Does not write.

```lua
local n = getgc({"RecoilMult", "AimSpreadMult", "HipSpreadMult", "RangeMult", "SpeedMult", "SwayMult", "FireRateMult"})
```

#### `applygc(keys, values)` → number

Primary write function. Patches **every** matching node in **every** VM.

```lua
applygc(
    {"RecoilMult", "AimSpreadMult", "HipSpreadMult"},
    { RecoilMult = 0, AimSpreadMult = 0, HipSpreadMult = 0 }
)
```

April / Fallen split form (also accepted):

```lua
applygc({ RecoilMult = -1, RangeMult = 10, SpeedMult = 100 })
```

Writable types: `number`, `bool`.

#### Persistence loop

```lua
refreshgc()

local KEYS = {"RecoilMult", "AimSpreadMult", "HipSpreadMult"}
local VALUES = { RecoilMult = 0, AimSpreadMult = 0, HipSpreadMult = 0 }

thread.create(function()
    applygc(KEYS, VALUES)
end, 100)
```

| Interval (ms) | When to use |
|---------------|-------------|
| 50 | Values reset every frame |
| 100 | Standard (reload / per second) |
| 500–1000 | Respawn / map change only |

#### `dumpgc(filepath?)` → number

Discovery tool. Targeted mode:

```lua
dumpgc({"RecoilMult", "Damage"}, "C:/targeted.txt")
```

#### `setgc(target, patches)`

Low-level filter — only patches tables matching target key/value pairs:

```lua
setgc({RPM = 150}, {RPM = 600, Damage = 60})
```

### Fallen Survival — known weapon keys

| Key | Typical use |
|-----|-------------|
| `RecoilMult` | `-1` = 100% recoil reduction |
| `AimSpreadMult` / `HipSpreadMult` | `-1` = no spread |
| `SwayMult` | `-1` = no sway |
| `FireRateMult` | e.g. `1.5` |
| `SpeedMult` | bullet speed (e.g. `100`) |
| `RangeMult` | e.g. `10` |

**Never patch on Fallen:** `Cooldown`, `GatherMult`, melee swing tables.

---

## 9. Menu API

All controls need a **tab** and **group**. Register at script load.

### Setup

```lua
menu.add_tab("Visuals", "V")                    -- name, icon
menu.add_tab("Loot", "L", "half")               -- half-width tab
menu.add_group("Visuals", "Players")            -- tab, group
menu.add_group("Aimbot", "Smoothing", 0, true)  -- same row as previous group
menu.add_group("Loot", "Filters", -1)           -- full width
```

April uses full mode: `menu.add_tab("April", "A", "full")`.

### Elements

| Function | Notes |
|----------|-------|
| `menu.add_checkbox(tab, group, id, label, default, options?)` | `options`: `{ key, show_mode, colorpicker, parent, color }` |
| `menu.add_slider_int(...)` | Format string or `{ parent = id }` |
| `menu.add_slider_float(...)` | Same pattern |
| `menu.add_combo(...)` | Returns **zero-based** index via `menu.get` |
| `menu.add_multicombo(...)` | Returns `{bool,...}` per item |
| `menu.add_button(tab, group, id, label, callback)` | |
| `menu.add_colorpicker(...)` | Standalone color picker |
| `menu.add_hotkey(...)` | Standalone key picker (same Always/Hold/Toggle) |
| `menu.add_input(...)` | Text field |
| `menu.add_label(tab, group, text)` | No id |
| `menu.add_separator(tab, group)` | Spacer |

### Read / write

```lua
local enabled = menu.get("esp_on")           -- bool
local fov     = menu.get("fov_size")         -- number
local style   = menu.get("box_style")        -- zero-based combo index
local bones   = menu.get("bone_list")        -- table of bools
local color   = menu.get_color("esp_color")  -- {r,g,b,a}
local key     = menu.get_key("aim_key")      -- VK code

menu.set("esp_on", true)
menu.set_color("esp_color", {0, 1, 0.8, 1})
menu.set_key("aim_key", 0x02)
menu.set_callback("esp_on", function(v) print(v) end)
menu.set_visible("fov_size", false)
```

> **No `menu.get_key_mode`** — Always/Hold/Toggle is user-set via right-click on the key in menu only.

### Checkbox keybind modes (API 1.4)

Any checkbox with `{ key = vk }` or `add_hotkey`:

| Mode | Behavior |
|------|----------|
| **Always** (default) | Key display only — toggle via checkbox or `menu.set` |
| **Hold** | `menu.get(id)` true only while key held |
| **Toggle** | Each key press flips checkbox |

Right-click the key display to switch modes (`show_mode = true` by default).

```lua
menu.add_checkbox("April", "Combat", "april_world_enabled", "Enable World ESP", false, { key = 0x58 })

function on_frame()
    if settings.enabled("april_world_enabled") then
        -- respects Hold/Toggle/Always
    end
end
```

### Parent visibility

```lua
menu.add_checkbox("Aimbot", "Settings", "aimbot_on", "Enable Aimbot", false)
menu.add_slider_float("Aimbot", "Settings", "smooth", "Smooth", 0, 1, 0.15, { parent = "aimbot_on" })
```

### Full setup example

```lua
menu.add_tab("Visuals", "V")
menu.add_group("Visuals", "ESP")

menu.add_checkbox("Visuals", "ESP", "esp_on", "Enable ESP", false, { key = 0x2E, colorpicker = {1,1,1,1} })
menu.add_checkbox("Visuals", "ESP", "esp_names", "Names", true, { parent = "esp_on" })
menu.add_slider_int("Visuals", "ESP", "esp_dist", "Max Dist", 0, 500, 200, { parent = "esp_on" })

function on_frame()
    if not menu.get("esp_on") then return end
    local color = menu.get_color("esp_on")
    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local b = p:get_bounds()
        if b.valid then draw.box(b.x, b.y, b.w, b.h, color) end
        ::continue::
    end
end
```

---

## 10. Utility API

| Function | Returns | Description |
|----------|---------|-------------|
| `utility.world_to_screen(x,y,z)` | sx, sy, on_screen | Stricter than `draw.world_to_screen` |
| `utility.get_screen_size()` | w, h | Render resolution |
| `utility.get_mouse_pos()` | mx, my | Cursor position |
| `utility.get_delta_time()` | number | Seconds since last frame |
| `utility.get_time()` | number | Seconds since engine start |
| `utility.get_tick_count()` | number | `GetTickCount64()` ms |
| `utility.get_fps()` | number | Smoothed FPS |
| `utility.is_valid(instance)` | bool | Instance still alive |

### Key bindings (alternative to menu key modes)

```lua
local esp_id = utility.on_key(0x46, "toggle", function(state)
    esp_on = state
end)

utility.on_key(0x02, "hold", function(state)
    if state then print("RMB held") end
end)

utility.remove_key(esp_id)
utility.clear_keys()
```

Modes: `"toggle"`, `"hold"`, `"always"`.

### Input simulation (OS-level)

```lua
utility.mouse_click("left")
utility.key_press(0x20)          -- space
utility.type_string("hello", 50)
```

### Network

```lua
local body, status = utility.http_get("https://example.com/data.json")
local ok, err = utility.load_url("https://example.com/script.lua")
```

---

## 11. Thread API

Background timers — **not** for drawing.

| Function | Description |
|----------|-------------|
| `thread.create(callback, interval_ms?)` → id | Default 100ms |
| `thread.stop(id)` | Stop one |
| `thread.stop_all()` | Stop all |
| `thread.is_running(id)` | bool |
| `thread.set_interval(id, ms)` | Change interval live |

```lua
local t = nil
function on_frame()
    if t ~= nil then return end
    t = thread.create(function()
        applygc(KEYS, VALUES)
    end, 100)
end
```

Use `on_frame` for render; threads for GC re-apply, logging, scans.

---

## 12. Raycast API

Background worker maintains obstacle spatial hash (~2 s rebuild), terrain voxel cache, and per-player visibility (~16 ms refresh). Lua reads are cheap hash lookups.

### Fail-open vs fail-closed

| Function | Cache not ready |
|----------|-----------------|
| `is_player_visible` | Returns `true` (fail open) |
| `is_visible` | Returns `true` (fail open) |
| `cast` | Returns `hit = false` (fail closed) |

Both `is_visible` and `cast` check **parts and terrain**.

### `raycast.is_ready()` → bool

```lua
function on_frame()
    if not raycast.is_ready() then
        draw.text(10, 10, "building raycast cache...", {1, 1, 0, 1})
        return
    end
end
```

### `raycast.is_player_visible(character_address)` → bool

Cached visibility from camera to key body parts. **Prefer this** over per-player `is_visible` loops.

```lua
local char = p.character
if utility.is_valid(char) then
    local vis = raycast.is_player_visible(char.address)
    local col = vis and {0, 1, 0.4, 1} or {0.5, 0.5, 0.5, 0.6}
    draw.box(b.x, b.y, b.w, b.h, col)
end
```

### `raycast.is_visible(from, to)` → bool

Live ray test. Six numbers or two Vector3s.

```lua
local cam = camera.get_position()
local head = p.head_position
local visible = raycast.is_visible(cam, head)
-- or
local visible = raycast.is_visible(cam.x, cam.y, cam.z, head.x, head.y, head.z)
```

### `raycast.cast(from, to)` → hit, position, distance, instance, is_terrain

Full closest hit. Guard with `is_ready()` when distinguishing "no hit" vs "warming up".

```lua
if not raycast.is_ready() then return end

local cam  = camera.get_position()
local look = camera.get_look_vector()
local hit, pos, dist, inst, is_terrain = raycast.cast(cam, cam + look * 2000)

if hit then
    if is_terrain then
        draw.text(10, 30, string.format("terrain at %.0f studs", dist), {1, 1, 0, 1})
    else
        draw.text(10, 30, string.format("hit %s at %.0f studs", inst.Name, dist), {0, 1, 0, 1})
    end
end
```

Inf Fly ground distance:

```lua
local hit, _, dist = raycast.cast(pos.x, pos.y, pos.z, pos.x, pos.y - 1000, pos.z)
if hit and dist > 4 then ... end
```

### Silent raycast hook (API 1.4)

Overrides what the **game engine** sees on internal `Workspace:Raycast` — different from script-side `is_visible`/`cast`.

| Function | Description |
|----------|-------------|
| `raycast.enable_silent_hook()` → bool | Install hook once |
| `raycast.disable_silent_hook()` | Remove hook |
| `raycast.is_silent_hook_active()` → bool | Hook installed |
| `raycast.set_silent_target(origin, direction)` | One-shot next engine raycast |
| `raycast.clear_silent_target()` | Clear one-shot |
| `raycast.track_silent_target(origin, direction, key)` → bool | Live update + native-speed thread while `key` held |
| `raycast.stop_silent_tracking()` | Stop tracking thread |

Hook auto-tears-down on script reload. Install once; use `track_silent_target` for silent aim.

```lua
function on_frame()
    if not raycast.is_silent_hook_active() then
        raycast.enable_silent_hook()
    end

    local target = find_target()
    if not target then return end

    local cam  = camera.get_position()
    local head = target.head_position
    if not cam or not head then return end

    local dir = head - cam
    raycast.track_silent_target(cam, dir, 0x01)  -- LMB held
end
```

April: `core/silent_ray.lua` wraps this; `features/combat/aimbot.lua` adds weapon prediction via `game/weapons.lua`.

### Performance notes

* `is_player_visible` — essentially free (visibility buffer lookup)
* `is_visible` — live test but spatial-hash bound; OK once per player per frame
* `cast` — slightly more work than `is_visible`; still spatial-hash bound
* Obstacle cache rebuilds ~every 2 s — new parts may lag
* Transparent parts (≥ 1.0) excluded from obstacles
* `track_silent_target` — one atomic store per frame from Lua; native thread while key held

---

## 13. Memory API

| API | Description |
|-----|-------------|
| `memory.base` | Roblox module base address |
| `memory.read(addr, type)` | Typed read |
| `memory.write(addr, type, value)` → bool | Typed write |
| `memory.read_buffer(addr, size)` → string | Raw bytes (max 65536) |
| `memory.read_string(addr, max?)` | Null-terminated C string |

Types: `uint8`, `int32`, `float`, `uint64`/`ptr`, `bool`, … — invalid reads return safe defaults.

---

## 14. FFlag API

~6000–7000 flags cached in background.

```lua
if fflag.is_scanned() then
    fflag.set_value("TaskSchedulerTargetFps", 9999)
end

local matches = fflag.find("fps")
fflag.reset_all()
```

---

## 15. Exploits API — GPU chams

> **Status:** Working in current Vector builds (`exploits.*`) but **not published on the GitBook yet**.  
> Documented from a verified Node Chams sample so April can implement correctly. Prefer this over `draw.chams_player` when you need mesh/instance chams (nodes, loot, viewmodels, etc.).

Unlike `draw.chams_player` (2D/overlay player hulls drawn every frame), these chams are applied to **live BasePart / MeshPart instances** and rendered by the engine/GPU overlay.

### Global / capability

```lua
if not (exploits and exploits.ApplyChamsToInstance) then
    -- build too old — fall back or hide UI
    return
end
```

| Function | Signature | Description |
|----------|-----------|-------------|
| `exploits.GetChamsMode` | `()` → `number` | Current chams mode index |
| `exploits.SetChamsMode` | `(mode)` | Set global mode used by subsequent applies |
| `exploits.GetChamsColor` | `()` → `number` | Current chams color index |
| `exploits.SetChamsColor` | `(color)` | Set global color used by subsequent applies |
| `exploits.ApplyChamsToInstance` | `(inst \| address)` → `bool` | Apply current mode/color to a part (or re-apply by `Address`) |
| `exploits.RevertChams` | `()` | Clear **all** applied GPU chams |

### Mode & color indices

Combos should use these exact label lists (zero-based indices):

| Mode index | Label |
|------------|-------|
| `0` | Fill |
| `1` | Wireframe |
| `2` | Fill Glow |
| `3` | Wireframe Glow |

| Color index | Label |
|-------------|-------|
| `0` | Default |
| `1` | Red |
| `2` | Green |
| `3` | Yellow |
| `4` | Blue |
| `5` | Magenta |
| `6` | Cyan |

**Color visibility rule (from sample):** show the color combo only for glow modes:

```lua
menu.set_visible("my_chams_color", mode == 2 or mode == 3)
```

### Apply / track / rescan pattern

```lua
local PART_CLASSES = {
    Part = true, MeshPart = true, WedgePart = true, CornerWedgePart = true,
    TrussPart = true, UnionOperation = true, NegateOperation = true,
}

local applied = {} -- [Address] = true

local function cham_instance(inst)
    if not inst then return end
    local addr = inst.Address
    if addr and applied[addr] then return end
    if exploits.ApplyChamsToInstance(inst) then
        if addr then applied[addr] = true end
    end
end

-- Prefer the model's Main part when present
local main = node:FindFirstChild("Main")
if main and PART_CLASSES[main.ClassName] then
    cham_instance(main)
end

-- After mode/color change, re-stamp every known address:
for addr in pairs(applied) do
    exploits.ApplyChamsToInstance(addr)
end

-- On disable:
exploits.RevertChams()
applied = {}
```

### Important behaviours

| Rule | Why |
|------|-----|
| **Mode/color are global** | `SetChamsMode` / `SetChamsColor` affect every subsequent apply. Different owners (loot vs arms) need: set style → apply that bucket → set style → apply next bucket. |
| **`RevertChams` is all-or-nothing** | Disabling one feature must rebuild remaining owners (revert → re-apply). |
| **Track by `inst.Address`** | Dedupes rescans; `ApplyChamsToInstance(addr)` refreshes style without holding the instance. |
| **Rescan on an interval** | New world props / viewmodels appear over time (`thread.create(scan, 3000)`). |
| **Only part-like classes** | Skip Models/Folders — cham `Main` or MeshPart/Part descendants. |
| **Not the same as `draw.chams_player`** | Player ESP overlay vs GPU mesh chams on arbitrary instances. |

### April wiring

| Module | Role |
|--------|------|
| `core/gpu_chams.lua` | Capability check, double-buffer apply, owner rebuild |
| `features/world/*_esp.lua` | Multicombo “Chams types” + mode/color under Loot / Resource / Base |
```

Menu shape:

```lua
-- Under Loot / Resource / Base master:
menu.add_multicombo(T, G, "april_loot_chams", "Loot Chams", labels, defaults, parent)
menu.add_combo(T, G, "april_loot_chams_mode", "Loot Chams Mode", MODES, 0, parent)
menu.add_combo(T, G, "april_loot_chams_color", "Loot Chams Color", COLORS, 0, parent)
```

**Double-buffer (April):** each owner keeps a front set (currently applied addresses) and builds a back set (in-range only) every rescan. If anything left the back set → `RevertChams` + re-apply only the back set. Collectors **fail closed** without local player position (never cham the full cache). Prefer one visual part per ESP entry (`cham_entry_part`) so shared MeshIds don’t light up every copy in the world.

---

## 16. April project notes

### Build & layout

| Path | Role |
|------|------|
| `April/src/` | Edit source |
| `April/scripts/bundle.mjs` | Bundle → `april.lua` + `Script 1.lua` |
| `April/docs/API.md` | This file |
| `gc_dump.txt` | GC key discovery output |

### `core/settings.lua`

| Function | Use |
|----------|-----|
| `settings.enabled(id)` | **Master toggles with `{ key = vk }`** — respects Hold/Toggle |
| `settings.bool(id, default)` | Child options without keybind gating |
| `settings.num(id, default)` | Sliders / combo indices |
| `settings.color(id, default)` | Color pickers |
| `settings.on_change(id, fn)` | Menu callback wrapper |

### Module map (API 1.4)

| Module | Role |
|--------|------|
| `core/runservice.lua` | RunService gate + Heartbeat sim hooks |
| `core/misc_gate.lua` | Thin wrapper → `runservice.movement_allowed()` |
| `core/silent_ray.lua` | Silent hook + `track_silent_target` |
| `core/gpu_chams.lua` | `exploits` GPU instance chams owners (loot/world/base) |
| `game/gc_weapon_mods.lua` | `refreshgc` → `getgc` → `applygc` |
| `features/combat/aimbot.lua` | Bullet prediction + silent ray vis |
| `features/combat/targeting.lua` | Target selection + `is_player_visible` filter |
| `features/movement/exploits.lua` | Inf Fly + Spider via `runservice.on_sim` |

### Gun mods (Fallen)

- Master: `april_gunmods_enabled` — use `settings.enabled`
- Apply on toggle only (not slider drag) — async GC safe but avoids spam
- Flow: equip gun → toggle on → `getgc` warm → `applygc`
- **Never** `getgc(true)`

### Silent aim (Fallen)

- Vector built-in silent raycast assumed; April augments with prediction
- **Bullet Prediction** feeds `track_silent_target` while LMB (`0x01`) held
- No `camera.look_at` for silent — camera stays natural
- **Visualize Silent Ray** draws world line via `esp_util.draw_world_line`

### Farm helper

- `features/combat/perfect_farm.lua` — `camera.look_at` for nodes/trees
- Independent of gun mods master toggle

### Bundle order (critical)

Combat modules in `bundle.mjs`:

```
features/combat/gun_mods.lua
features/combat/targeting.lua   ← BEFORE aimbot
features/combat/aimbot.lua
```

---

## Quick lookup — common tasks

| Task | API / April module |
|------|-------------------|
| Box ESP | `p:get_bounds()` + `draw.box` |
| Visible-only ESP | `raycast.is_player_visible(char.address)` |
| Aimbot visibility | `settings.enabled` + `targeting.passes_visibility` |
| Menu master toggle | `settings.enabled("id")` |
| Child option toggle | `settings.bool("id", false)` |
| Weapon recoil | GC: `RecoilMult = -1` via `gc_weapon_mods` |
| Discover GC keys | `dumpgc(path)` |
| Inf Fly | `runservice.on_sim` + `raycast.cast` downward |
| Silent aim | `track_silent_target(cam, dir, 0x01)` |
| Periodic GC | `thread.create(fn, 100)` |
| GPU instance chams | `exploits.ApplyChamsToInstance` via `core/gpu_chams` |
| Movement gate | `runservice.movement_allowed()` |
| Load item icon | `draw.load_image(url)` once, `draw.image(..., 255,255,255,255)` |
| FPS unlock | `fflag.set_value("TaskSchedulerTargetFps", 9999)` |

---

*End of API reference. For additional prose examples see the [Vector Lua Engine GitBook](https://project-vector-1.gitbook.io/vector-lua-engine).*

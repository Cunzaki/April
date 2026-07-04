# Vector Lua Engine — API Reference (April)

> **Source:** [Vector Lua Engine GitBook](https://project-vector-1.gitbook.io/vector-lua-engine) via MCP (`vector-lua-engine`), last synced **2026-07-04**.  
> **Audience:** AI agents and developers working on April v3. Read the relevant section before implementing features.

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
| 7 | [GC API](#7-gc-api) | Weapon mods, Lua heap patches |
| 8 | [Menu API](#8-menu-api) | UI controls |
| 9 | [Utility API](#9-utility-api) | W2S, timing, input sim, HTTP |
| 10 | [Thread API](#10-thread-api) | Background timers |
| 11 | [Raycast API](#11-raycast-api) | Visibility checks |
| 12 | [Memory API](#12-memory-api) | Raw address reads/writes |
| 13 | [FFlag API](#13-fflag-api) | Roblox fast flags |
| 14 | [April notes](#14-april-project-notes) | Fallen-specific conventions |

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
| `raycast` | Cached player visibility + live ray tests |
| `memory` | Raw process memory read/write |
| `fflag` | Roblox Fast Flag read/write |
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

### GC rules (Fallen / weapon mods)

| Rule | Detail |
|------|--------|
| **Never `getgc(true)`** when `refreshgc`/`applygc` exist | Poisons the `getgc({ keys })` node cache → returns 0 nodes |
| Call `refreshgc()` once at start | Call again after teleport / VM restart |
| `getgc` then `applygc` | April pattern: warm cache with key list, then patch (see [§7](#7-gc-api)) |
| Re-apply on interval | Games reset values — use `thread.create` loop, not blocking `while true` |
| Writable via GC | `number`, `bool` only — not `string`, `table`, `function`, `userdata` |

### April-specific

| Rule | Detail |
|------|--------|
| Images | Load once; `draw.image` every frame with **0–255 RGBA** args (see [§4 Images](#images)) |
| Image URLs | One direct HTTPS URL per asset — no fallback chains |
| Menu labels | Unique `id` **and** unique `label` text per tab+group (visibility tied to labels) |
| Fallen AC | Avoid writing `WalkSpeed` — prefer velocity/root movement for speed hacks |
| Farm GC | **Do not** patch `Cooldown` / melee tables — ban risk; use camera aim (Farm Helper) instead |

---

## 3. Callbacks

### `on_frame`

Called every render frame. **All drawing must happen here.**

```lua
function on_frame()
    draw.text(10, 10, "running", {1, 1, 1, 1})
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

---

## 4. Draw API

2D overlay rendering. Origin: **top-left**. X right, Y down.

**Colors:** Normalized RGBA table `{r, g, b, a}` with components **0.0–1.0** for primitives/text.  
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
| `draw.window` | `(x,y,id,title,items)` | Floating info panel; `items` = `{ {label, value}, ... }` |

### Polygons & chams

| Function | Signature | Notes |
|----------|-----------|-------|
| `draw.poly` | `(points, color, thickness?)` | Open polyline; points = `{{x,y},...}` |
| `draw.poly_closed` | `(points, color, thickness?)` | Closed outline |
| `draw.poly_filled` | `(points, color)` | **Convex hull order required** |
| `draw.compute_hull` | `(points)` → ordered table | Sort points for `poly_filled` |
| `draw.chams_player` | `(player, color, color2?, style?)` | `style`: 0=filled, 1=outline, 2=glow |
| `draw.get_player_hulls` | `(player)` → hulls | Per-body-part polygons |

### Images

Async download on background thread. Same URL → same handle (deduplicated).

| Function | Returns | Description |
|----------|---------|-------------|
| `draw.load_image(url)` | handle | Start download; safe to call every frame |
| `draw.image_loaded(handle)` | bool | True when GPU-ready |
| `draw.image_failed(handle)` | bool | Download/decode failed |
| `draw.image_size(handle)` | w, h | Native dimensions; 0,0 if not loaded |
| `draw.free_image(handle)` | — | Release texture + cache entry |
| `draw.image(handle,x,y,w,h)` | — | Draw scaled |
| `draw.image(handle,x,y,w,h, color)` | — | With tint table `{r,g,b,a}` 0–1 |

**Supported URL formats:**

| Format | Example |
|--------|---------|
| HTTPS | `https://raw.githubusercontent.com/user/repo/icon.png` |
| Roblox asset | `http://www.roblox.com/asset/?id=12345` |
| rbxassetid | `rbxassetid://10774541653` |

Formats: PNG, JPEG, BMP, TGA.

#### April image pattern (0–255 color args)

Working pattern in April — load once, skip first draw frame, call every frame:

```lua
local icon = nil

function on_frame()
    if icon == nil then
        icon = draw.load_image("https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/items/123.png")
        return  -- skip load frame
    end
    if draw.image_failed(icon) then return end

    -- 0-255 RGBA — no image_loaded gate needed; no-ops until ready
    draw.image(icon, 10, 10, 64, 64, 255, 255, 255, 255)
end
```

Item CDN base: `https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/items/{id}.png`

---

## 5. Entity API

Player objects are **frame snapshots**. Properties marked **live** re-read memory on every access.

### Module functions

| Function | Returns | Description |
|----------|---------|-------------|
| `entity.get_players()` | table | All valid players (includes workspace NPCs/bots) |
| `entity.get_local_player()` | player/nil | Local player |
| `entity.get_player_count()` | number | Count in cache |

### Cached properties (cheap)

`name`, `display_name`, `user_id`, `team`, `has_team`, `tool_name`, `is_local`, `is_valid`, `is_workspace_entity`, `rig_type`

### Live properties (memory read each access)

`health`, `max_health`, `is_alive`, `is_dead`, `position`, `velocity`, `head_position`, `look_vector`, `move_direction`, `camera_offset`, `walk_speed`, `jump_power`, `jump_height`, `hip_height`, `max_slope_angle`, `state`, `state_name`, `sit`, `is_jumping`, `platform_stand`, `auto_rotate`, `is_walking`, `floor_material`

### Instance refs

`character`, `humanoid`, `player` — game API instance objects.

### Writable (immediate memory write)

**Humanoid:** `health`, `max_health`, `walk_speed`, `jump_power`, `jump_height`, `hip_height`, `max_slope_angle`, `state`, `sit`, `jump`, `platform_stand`, `auto_rotate`, `auto_jump_enabled`, `use_jump_power`, `requires_neck`, `break_joints_on_death`, `evaluate_state_machine`, `camera_offset`, `walkspeed_check`

**Root primitive:** `position`, `velocity`, `angular_velocity`, `anchored`, `can_collide`, `can_query`, `can_touch`

### Player methods

| Method | Returns | Description |
|--------|---------|-------------|
| `:get_bone_screen(name)` | x, y, visible | Single bone W2S |
| `:get_bones_screen()` | table | All bones → `{ ["Head"] = {x,y}, ... }` |
| `:get_bounds()` | `{x,y,w,h,valid}` | Screen bounding box |
| `:distance_to(point?)` | number | To point or camera if omitted |

**R6 bones:** Head, Torso, Left Arm, Right Arm, Left Leg, Right Leg, HumanoidRootPart  
**R15 bones:** Head, UpperTorso, LowerTorso, arms, legs, HumanoidRootPart (full set in GitBook)

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
| `game.lighting` | Instance | Lighting |
| `game.local_player` | Instance | Local player |
| `game.place_id` | number | Place ID |
| `game.game_id` | number | Game ID |

```lua
local rep = game.get_service("ReplicatedStorage")
-- ReplicatedStorage, ReplicatedFirst, StarterGui, StarterPack, StarterPlayer, Teams, SoundService, Chat
```

### Instance query methods

| Method | Returns |
|--------|---------|
| `:get_children()` | table |
| `:get_descendants()` | table |
| `:find_first_child(name)` | Instance |
| `:find_first_child(name, true)` | Instance (recursive) |
| `:find_first_child_of_class(class)` | Instance |
| `:find_first_child_which_is_a(class)` | Instance |
| `:find_first_descendant(name)` | Instance |
| `:find_first_descendant_of_class(class)` | Instance |
| `:find_first_ancestor(name)` | Instance |
| `:find_first_ancestor_of_class(class)` | Instance |
| `:is_a(class_name)` | bool |
| `:is_descendant_of(ancestor)` | bool |
| `:is_ancestor_of(descendant)` | bool |

**Common read-only:** `Name`, `ClassName`, `Parent`, `Address`

### Key instance properties (read / write)

**BasePart:** `Position`, `Size`, `Velocity`, `AngularVelocity`, `CFrame` (position only), `Transparency`, `CanCollide`, `Anchored`, `CanQuery`, `CanTouch`, `LookVector`, `Color`

**Humanoid:** `Health`, `MaxHealth`, `WalkSpeed`, `JumpPower`, `State`, `StateName`, `IsAlive`, `MoveDirection`, `HumanoidRootPart`, `WalkspeedCheck`, `SeatPart`, …

**Player:** `Character`, `UserId`, `Team`, `CameraMode`, `MaxZoomDistance`, `MinZoomDistance`

**Camera (instance):** `Position`, `FieldOfView`, `LookVector`, `CameraSubject`

**Model:** `PrimaryPart`  
**Tool:** `CanBeDropped`, `Enabled`  
**Value instances:** `Value` (read/write)

### Custom Roblox attributes

| Method | Description |
|--------|-------------|
| `inst:get_attribute(name)` | Read custom attribute (nil if missing) |
| `inst:get_attributes()` | All attributes as table |
| `inst:set_attribute(name, value)` | Write number/bool only |

Types returned: `number`, `boolean`, `string`, `Vector3`, `{r,g,b}` Color3, `{x,y}` Vector2.

### `camera` global

| Method | Returns | Description |
|--------|---------|-------------|
| `camera.get_position()` | Vector3 | World position |
| `camera.get_look_vector()` | Vector3 | Forward |
| `camera.get_fov()` | number | Field of view |
| `camera.set_fov(value)` | bool | Set FOV |
| `camera.look_at(target, smooth?)` | bool | Aim at Vector3 or x,y,z; optional smooth frame count |

```lua
camera.look_at(target_vec3)        -- snap
camera.look_at(x, y, z, 10)        -- smooth over ~10 frames
```

### `input` global

| Method | Description |
|--------|-------------|
| `input.is_key_down(vk)` | Key held |
| `input.get_screen_center()` | cx, cy |
| `input.move_mouse(dx, dy)` | Relative mouse move |

| VK | Key |
|----|-----|
| `0x01` | LMB |
| `0x02` | RMB |
| `0x10` | Shift |
| `0x11` | Ctrl |
| `0x12` | Alt |
| `0x20` | Space |
| `0x1B` | Escape |

### `part` global (direct writes)

`part.set_position`, `set_size`, `set_velocity`, `set_angular_velocity`, `set_transparency`, `set_can_collide`, `set_anchored`, `set_can_query`, `set_can_touch` — all `(inst, ...)`.

### `Vector3`

```lua
local v = Vector3.new(x, y, z)
-- v.x, v.y, v.z, v.magnitude, v.unit
-- v:dot(other), v:cross(other), v:lerp(other, t)
-- operators: +, -, *, /, #, ==
```

---

## 7. GC API

Direct read/write of **Lua VM runtime tables** in process memory. Bypasses the DataModel — used for weapon stats, multipliers, and other heap-only config.

### Functions

#### `refreshgc()` → number

Rescans memory for active Lua VMs, clears node cache. Call at script start and after teleport.

```lua
local vms = refreshgc()
print("VMs: " .. vms)
```

#### `getgc(keys)` → number

Pre-warms node cache for key names. **Does not write.**

| Param | Type | Description |
|-------|------|-------------|
| `keys` | table or string | `{"RecoilMult","RangeMult"}` or `"RecoilMult"` |

Returns **count** of matching nodes across all VMs.

```lua
local n = getgc({"RecoilMult", "AimSpreadMult", "HipSpreadMult", "RangeMult", "SpeedMult", "SwayMult", "FireRateMult"})
print(n .. " nodes")
```

#### `applygc(keys, values)` → number

Locates nodes and writes values. Runs `getgc` internally if cache empty.

**Official signature (two arguments):**

```lua
applygc(
    {"RecoilMult", "AimSpreadMult", "HipSpreadMult"},
    { RecoilMult = 0, AimSpreadMult = 0, HipSpreadMult = 0 }
)
```

**April / Fallen pattern (split — used in `gc_weapon_mods.lua`):**

```lua
refreshgc()
local n = getgc({"RecoilMult", "RangeMult", "SpeedMult", "AimSpreadMult", "HipSpreadMult", "SwayMult", "FireRateMult"})
if n > 0 then
    applygc({ RecoilMult = -1, AimSpreadMult = -1, HipSpreadMult = -1, RangeMult = 10, SpeedMult = 100, SwayMult = -1, FireRateMult = 1.5 })
end
```

Patches **every** matching node in **every** VM. Writable types: `number`, `bool`.

#### `dumpgc(filepath?)` → number

Full or targeted scan → file or console. Use to discover key names.

```lua
dumpgc("C:/gc_dump.txt")
dumpgc({"RecoilMult", "Damage"}, "C:/targeted.txt")
```

Output format: `[type  ] KeyName = value`  
Full dumps: 100k–500k lines, 1–3 seconds — **never in a loop**.

#### `setgc(target, patches)`

Low-level: patch only tables matching `target` filter (must run after `getgc`/`applygc` warmed cache).

```lua
setgc({RPM = 150}, {RPM = 600, Damage = 60})
```

### Persistence / re-apply

Games reset GC values on respawn, reload, or tick. Re-apply via thread:

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

### Fallen Survival — known weapon keys

From `gc_dump.txt` / ToolInfo (equipped **gun** runtime tables):

| Key | Typical use |
|-----|-------------|
| `RecoilMult` | `-1` = 100% recoil reduction |
| `AimSpreadMult` / `HipSpreadMult` | `-1` = no spread |
| `SwayMult` | `-1` = no sway |
| `FireRateMult` | e.g. `1.5` |
| `SpeedMult` | bullet speed (e.g. `100`) |
| `RangeMult` | e.g. `10` |

**Not for client mods (ban / server-side / wrong target):**

| Key | Why |
|-----|-----|
| `GatherMult` | Server game-mode mult (with `CraftSpeedMult`, etc.) |
| `Cooldown` | Melee swing rate — **detected** |
| `SwingAnimSpeed` | Tool anim — risky on Fallen |

### Discovery workflow

```lua
refreshgc()
dumpgc("C:/Users/.../gc_dump.txt")
-- Search dump for RecoilMult, Damage, RPM, Ammo, etc.
```

---

## 8. Menu API

All controls need a **tab** and **group**. Register at script load.

### Setup

```lua
menu.add_tab("April", "A")              -- name, icon letter
menu.add_group("April", "Combat")       -- tab, group name
```

Vector **full mode** also supports left/right columns: `menu.add_group(tab, name, 0, true)` for right column.

### Add controls

| Function | Key args |
|----------|----------|
| `menu.add_checkbox(tab, group, id, label, default, options?)` | options: `{ key=vk, colorpicker={}, parent=id, ... }` |
| `menu.add_slider_int(tab, group, id, label, min, max, default, options?)` | options: format string or `{ parent=id }` |
| `menu.add_slider_float(...)` | Same pattern |
| `menu.add_combo(tab, group, id, label, items, default_index, options?)` | Returns **zero-based** index |
| `menu.add_multicombo(...)` | Returns `{bool,...}` per item |
| `menu.add_button(tab, group, id, label, callback)` | |
| `menu.add_colorpicker(tab, group, id, label, default_rgba, options?)` | |
| `menu.add_hotkey(tab, group, id, label, default_vk, options?)` | |
| `menu.add_input(tab, group, id, label, default_text)` | |
| `menu.add_label(tab, group, text)` | No id |
| `menu.add_separator(tab, group)` | Spacer |

### Read / write

```lua
menu.get(id)              -- bool, number, string, or table
menu.get_color(id)        -- {r,g,b,a}
menu.get_key(id)          -- VK code
menu.set(id, value)
menu.set_color(id, rgba)
menu.set_key(id, vk)
menu.set_callback(id, function(new_value) end)
menu.set_visible(id, bool)
```

**Parent visibility:** `{ parent = "master_toggle_id" }` — child only shows when parent checkbox enabled.

---

## 9. Utility API

| Function | Returns | Description |
|----------|---------|-------------|
| `utility.world_to_screen(x,y,z)` or `(vec3)` | sx, sy, on_screen | On-screen only if inside bounds (stricter than `draw.world_to_screen`) |
| `utility.get_screen_size()` | w, h | Render resolution |
| `utility.get_mouse_pos()` | mx, my | Cursor position |
| `utility.get_delta_time()` | number | Seconds since last frame (clamped) |
| `utility.get_time()` | number | Seconds since engine start (monotonic) |
| `utility.get_tick_count()` | number | `GetTickCount64()` ms |
| `utility.get_fps()` | number | Smoothed FPS (60-frame avg) |
| `utility.is_valid(instance)` | bool | Instance still alive in memory |

### Key bindings

| Function | Description |
|----------|-------------|
| `utility.on_key(vk, mode, callback)` → id | Modes: `"toggle"`, `"hold"`, `"always"` |
| `utility.remove_key(id)` | Unregister |
| `utility.clear_keys()` | Remove all |
| `utility.is_key_toggled(id)` | Toggle state |

### Input simulation (OS-level via SendInput)

> Menu open captures input — close menu before simulating clicks/keys in practice.

| Function | Description |
|----------|-------------|
| `utility.mouse_click(button?, x?, y?)` | `"left"`, `"right"`, `"middle"` |
| `utility.mouse_move(x, y, absolute?)` | Relative or absolute |
| `utility.mouse_scroll(amount)` | Wheel |
| `utility.key_press(vk, hold_ms?)` | Full press; default hold 30ms |
| `utility.key_down(vk)` / `utility.key_up(vk)` | Hold/release |
| `utility.type_string(text, delay_ms?)` | Unicode typing |

### Network

| Function | Returns |
|----------|---------|
| `utility.http_get(url)` | body, status (or nil, error) |
| `utility.load_url(url)` | ok, err — fetch + execute Lua |

---

## 10. Thread API

Background timers — **not** for drawing.

| Function | Description |
|----------|-------------|
| `thread.create(callback, interval_ms?)` → id | Default 100ms, min 1ms |
| `thread.stop(id)` | Stop one |
| `thread.stop_all()` | Stop all |
| `thread.is_running(id)` | bool |
| `thread.set_interval(id, ms)` | Change interval live |

```lua
local t = nil
function on_frame()
    if t ~= nil then return end
    t = thread.create(function() print("tick") end, 500)
end
```

| Interval | Use |
|----------|-----|
| 100–200ms | Frequent updates |
| 500–1000ms | Monitoring |
| 2000ms+ | Infrequent checks |

Use `on_frame` for render + input; threads for GC re-apply, logging, scans.

---

## 11. Raycast API

Background visibility cache — cheap reads from Lua.

| Function | Returns | Description |
|----------|---------|-------------|
| `raycast.is_ready()` | bool | Obstacle cache built |
| `raycast.is_player_visible(char_address)` | bool | Cached per-player visibility; fail-open if not ready |
| `raycast.is_visible(x1,y1,z1, x2,y2,z2)` | bool | Live ray test (spatial hash) |
| `raycast.is_visible(vec3_from, vec3_to)` | bool | Vector3 form |

```lua
local char = p.character
if utility.is_valid(char) then
    local vis = raycast.is_player_visible(char.address)
    local col = vis and {0,1,0.4,1} or {0.5,0.5,0.5,0.6}
    draw.box(b.x, b.y, b.w, b.h, col)
end
```

- Obstacles rebuild ~every 2s  
- Player visibility refresh ~16ms  
- Transparent parts (≥1.0) excluded from obstacles  
- Prefer `is_player_visible` over per-frame `is_visible` for many players

---

## 12. Memory API

Raw process memory at absolute addresses.

| API | Description |
|-----|-------------|
| `memory.base` | Roblox module base address |
| `memory.read(addr, type)` | Typed read |
| `memory.write(addr, type, value)` → bool | Typed write |
| `memory.read_buffer(addr, size)` → string | Raw bytes (max 65536) |
| `memory.read_string(addr, max?)` | Null-terminated C string |
| `memory.write_string(addr, str, max?)` | Write C string |

### Type strings

| Types | Width |
|-------|-------|
| `uint8`/`u8`/`byte`, `int8`/`i8` | 1 |
| `uint16`/`u16`/`word`, `int16`/`i16` | 2 |
| `uint32`/`u32`/`dword`, `int32`/`i32`/`int`, `float`/`f32` | 4 |
| `uint64`/`u64`/`ptr`/`pointer`, `double`/`f64` | 8 |
| `bool`/`boolean` | 1 |

Invalid reads return `0` / `false` / `""` — no crash.

---

## 13. FFlag API

Roblox Fast Flags — background scan, ~6000–7000 flags cached.

| Function | Description |
|----------|-------------|
| `fflag.is_scanned()` | Cache ready |
| `fflag.get_count()` | Total flags |
| `fflag.get_value(name)` | Current int value |
| `fflag.set_value(name, value)` → bool | Write (DWORD) |
| `fflag.reset_value(name)` | Restore original |
| `fflag.reset_all()` | Restore all |
| `fflag.find(pattern)` | Case-insensitive search → `{name,value,original,changed,index}` |
| `fflag.get_all()` | All flags (+ `address`) — avoid every frame |

```lua
if fflag.is_scanned() then
    fflag.set_value("TaskSchedulerTargetFps", 9999)
end
```

---

## 14. April project notes

### Build & layout

| Path | Role |
|------|------|
| `April/src/` | Edit source |
| `April/scripts/bundle.mjs` | Bundle → `april.lua` |
| `April/Script 1.lua` | Vector load file |
| `April/references/dump/` | Game hierarchy, ToolInfo, Items |
| `gc_dump.txt` | GC key discovery output |

### Required APIs for April bootstrap

`menu`, `draw`, `utility`, `entity`, `game` — checked in `env.require_apis`.

### Gun mods (Fallen)

- Module: `game/gc_weapon_mods.lua`
- Keys: `RecoilMult`, `RangeMult`, `SpeedMult`, `AimSpreadMult`, `HipSpreadMult`, `SwayMult`, `FireRateMult`
- Flow: `refreshgc()` → `getgc(keys)` → `applygc(values)` on toggle only (not weapon swap)
- Must equip gun in-match for `n > 0`
- **Never** `getgc(true)` — breaks node cache (`module_scan.lua`)

### Farm helper (camera aim)

- Module: `features/combat/perfect_farm.lua`
- Independent of gun mods master toggle
- Scans `workspace.Nodes`, `Plants`, `Trees` for `NodeSpark` / `TreeX`
- Within range: `camera.look_at(x, y, z, smoothness)`
- Settings: `april_farm_helper`, `april_farm_radius`, `april_farm_smooth`

### Humanoid states (reference)

| Value | Name |
|-------|------|
| 0 | FallingDown |
| 3 | Jumping |
| 5 | Freefall |
| 6 | Flying |
| 8 | Running |
| 12 | Climbing |
| 13 | Seated |
| 15 | Dead |

---

## Quick lookup — common tasks

| Task | API |
|------|-----|
| Box ESP | `p:get_bounds()` + `draw.box` |
| Name tag | `draw.get_text_size` + `draw.text` |
| World label | `utility.world_to_screen` + `draw.text` |
| Aim camera | `camera.look_at(x,y,z, smooth)` |
| Menu toggle | `menu.get("id")` in `on_frame` |
| Valid instance | `utility.is_valid(inst)` |
| Weapon recoil | GC: `RecoilMult = -1` |
| Discover GC keys | `dumpgc(path)` |
| Visibility ESP | `raycast.is_player_visible(char.address)` |
| Load item icon | `draw.load_image(https_url)` once, `draw.image(..., 255,255,255,255)` every frame |
| Periodic work | `thread.create(fn, ms)` with nil-guard |
| FPS unlock | `fflag.set_value("TaskSchedulerTargetFps", 9999)` |

---

*End of API reference. For full prose examples see the [Vector Lua Engine GitBook](https://project-vector-1.gitbook.io/vector-lua-engine).*

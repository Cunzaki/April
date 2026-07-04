# Vector Lua Engine

The Vector Lua Engine lets you write scripts that run inside the cheat. Scripts can read game state, draw to the screen, add menu elements, and run background tasks — all through a safe, sandboxed Lua 5.1 environment.

***

### Naming convention

Every function in the API is registered under three naming styles simultaneously. You can use whichever you prefer — just stay consistent within a script.

| Style        | Example                |
| ------------ | ---------------------- |
| `snake_case` | `entity.get_players()` |
| `camelCase`  | `entity.getPlayers()`  |
| `PascalCase` | `entity.GetPlayers()`  |

All examples in this documentation use `snake_case`.

***

### Callbacks

Scripts respond to engine events by defining global functions. The engine calls them automatically.

#### on\_frame

Called every render frame. All drawing must happen here.

```lua
function on_frame()
    draw.text(10, 10, "script running", {1, 1, 1, 1})
end
```

#### on\_player\_added

Called when a player joins the game.

```lua
function on_player_added(player)
    print(player.name .. " joined")
end
```

#### on\_player\_removed

Called when a player leaves the game.

```lua
function on_player_removed(player)
    print(player.name .. " left")
end
```

***

### Available globals

| Global    | Description                                      |
| --------- | ------------------------------------------------ |
| `draw`    | 2D rendering — lines, boxes, text, circles       |
| `entity`  | Player list, local player, player properties     |
| `game`    | DataModel, instances, camera, input, parts       |
| `camera`  | Camera position, look vector, FOV                |
| `input`   | Key state, mouse position, mouse movement        |
| `part`    | Write part properties (position, size, velocity) |
| `menu`    | Add UI elements, read/write values               |
| `thread`  | Background timer-based callbacks                 |
| `utility` | Screen projection, delta time, FPS, tick count   |
| `Vector3` | 3D vector constructor                            |
| `print`   | Logs to the script console                       |

***

### Minimal working script

```lua
```

***

### Environment

The engine opens a restricted subset of the Lua 5.1 standard library:

| Available                                                | Removed                              |
| -------------------------------------------------------- | ------------------------------------ |
| `table`, `string`, `math`, `bit`, `os`, `io, loadstring` | `loadfile`, `dofile`, `load`         |
| `os.time`, `os.date`, `os.clock`                         | `os.execute`, `os.exit`, `os.remove` |
| `io.open`, `io.read`, `io.write`                         | `io.popen`                           |
| `tostring`, `tonumber`, `type`, `pairs`, `ipairs`        | `string.dump`, `collectgarbage`      |

***

### Script lifecycle

```
Script loaded
    └─ Top-level code runs once
        └─ Menu elements registered
        └─ Threads created (if any)
        └─ Callbacks defined

Every frame
    └─ on_frame() called (if defined)

Player joins
    └─ on_player_added(player) called (if defined)

Player leaves
    └─ on_player_removed(player) called (if defined)

Script unloaded
    └─ All threads stopped automatically
    └─ Menu elements cleared
```

***

### Tips

* Register menu elements at the top level of your script, outside `on_frame`. They only need to be created once.
* Create threads at the top level or with a nil-guard inside `on_frame`. Never call `thread.create` unconditionally inside `on_frame` — it runs every frame.
* Use `utility.get_delta_time()` for any time-based animation or movement so it stays frame-rate independent.
* Use `:get_bounds()` for box ESP. Use `:get_bone_screen()` for specific bone positions. Use `:get_bones_screen()` when you need multiple bones — it batches the reads.
* `p.health`, `p.position`, and `p.head_position` are live memory reads. Cache them into locals if you read them more than once per frame.

```lua
-- good: read once, use multiple times
local hp     = p.health
local max_hp = p.max_health
local ratio  = hp / max_hp
draw.health_bar(b.x - 5, b.y, b.h, hp, max_hp)
draw.text(b.x, b.y - 16, math.floor(hp) .. " / " .. math.floor(max_hp), {1,1,1,1})
```

# Navigating The UI

Master the Vector interface. This documentation covers the fundamental workflow of our scripting environment, from initial UI orientation to script execution.

<figure><img src="/files/AcALJxnm4EFHHU9oW3Jf" alt=""><figcaption></figcaption></figure>

To get started simply press **Create Script** in the script editor

<figure><img src="/files/GQzYS7ao5sLxK2ZfJZuw" alt=""><figcaption></figcaption></figure>

Once your script is made, you can see we have many options

* Execute Script
* Load Script
* Unload Script
* New Script
* Refresh Script List
* Open Folder

<figure><img src="/files/FXbf2HQRxOBMeFxp5iT7" alt=""><figcaption></figcaption></figure>

We can also right click to open the context menu to show more options

<figure><img src="/files/S6TavviTFvP4tMuWLXRe" alt=""><figcaption></figcaption></figure>

# Thread API

The thread API lets you run callbacks on a background timer, independent of the render loop. Use it for periodic monitoring, data collection, or any task that doesn't need to run every frame.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

### thread.create

```lua
local id = thread.create(callback, interval_ms)
```

| Parameter     | Type     | Required | Description                                        |
| ------------- | -------- | -------- | -------------------------------------------------- |
| `callback`    | function | yes      | Function to call repeatedly                        |
| `interval_ms` | number   | no       | Interval in milliseconds. Default: 100. Minimum: 1 |

Returns a `thread_id` number used to control the thread later.

```lua
local my_thread = thread.create(function()
    print("tick")
end, 500)
```

***

### thread.stop

```lua
thread.stop(thread_id)
```

Stops a specific thread and releases its callback.

```lua
thread.stop(my_thread)
```

***

### thread.stop\_all

```lua
thread.stop_all()
```

Stops every running thread at once.

***

### thread.is\_running

```lua
local running = thread.is_running(thread_id)
```

Returns `true` if the thread is still active.

```lua
if thread.is_running(my_thread) then
    print("still running")
end
```

***

### thread.set\_interval

```lua
thread.set_interval(thread_id, new_interval_ms)
```

Changes the interval of a running thread without stopping it.

```lua
thread.set_interval(my_thread, 200)
```

***

### Examples

**Background health monitor — create once, runs forever:**

```lua
local health_thread = nil

function on_frame()
    if health_thread ~= nil then return end

    health_thread = thread.create(function()
        local players = entity.get_players()
        for _, p in ipairs(players) do
            print(p.name .. " hp: " .. p.health)
        end
    end, 1000)
end
```

**Multiple threads at different rates:**

```lua
local threads = {}

function on_frame()
    if #threads > 0 then return end

    -- fast cache refresh
    threads[1] = thread.create(function()
        print("cache update")
    end, 200)

    -- slow status log
    threads[2] = thread.create(function()
        print("status check")
    end, 5000)
end
```

**Toggle thread on/off with a key:**

```lua
local monitor = nil

function on_frame()
    if input.is_key_down(0x4D) then  -- M key
        if monitor == nil then
            monitor = thread.create(function()
                print("monitoring...")
            end, 1000)
        else
            thread.stop(monitor)
            monitor = nil
        end
    end
end
```

**Lifecycle — create, check, adjust, stop:**

```lua
local my_thread = thread.create(function()
    print("working")
end, 1000)

if thread.is_running(my_thread) then
    thread.set_interval(my_thread, 500)
end

thread.stop(my_thread)

-- or stop everything at once
thread.stop_all()
```

***

### Notes

* Never call `thread.create` unconditionally inside `on_frame` — it runs every frame and will spawn thousands of threads. Guard with a nil check.
* Use threads for monitoring and background work. Use `on_frame` for all rendering and real-time input.
* Threads share the Lua state and can read globals written by `on_frame`.

***

### API Reference

| Function                      | Returns | Description               |
| ----------------------------- | ------- | ------------------------- |
| `thread.create(fn, ms)`       | number  | Create thread, returns ID |
| `thread.stop(id)`             | —       | Stop specific thread      |
| `thread.stop_all()`           | —       | Stop all threads          |
| `thread.is_running(id)`       | boolean | Check if thread is active |
| `thread.set_interval(id, ms)` | —       | Change thread interval    |

***

### Interval Guidelines

| Interval    | Use Case           |
| ----------- | ------------------ |
| 100–200ms   | Frequent updates   |
| 500–1000ms  | Regular monitoring |
| 2000–5000ms | Periodic tasks     |
| 5000ms+     | Infrequent checks  |

Use `on_frame` for rendering and real-time input. Use threads for everything else.

# Game API

The Game API mirrors the Roblox DataModel, giving scripts access to services, instances, and their properties. Five globals are available: `game`, `camera`, `input`, `part`, and `Vector3`. All instance methods and properties support `snake_case`, `camelCase`, and `PascalCase` naming.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

### game

The `game` global mirrors the Roblox DataModel root.

#### Properties

| Property            | Type     | Description           |
| ------------------- | -------- | --------------------- |
| `game.workspace`    | Instance | Workspace service     |
| `game.players`      | Instance | Players service       |
| `game.lighting`     | Instance | Lighting service      |
| `game.local_player` | Instance | Local player instance |
| `game.place_id`     | number   | Current place ID      |
| `game.game_id`      | number   | Current game ID       |

#### game.get\_service

```lua
local svc = game.get_service(name)
```

| Parameter | Type   | Required | Description  |
| --------- | ------ | -------- | ------------ |
| `name`    | string | yes      | Service name |

Retrieves any service by name. Supported: `ReplicatedStorage`, `ReplicatedFirst`, `StarterGui`, `StarterPack`, `StarterPlayer`, `Teams`, `SoundService`, `Chat`.

```lua
local rep = game.get_service("ReplicatedStorage")
local gui = game.get_service("StarterGui")
```

***

### Instance Methods

All instances returned by `game` or `entity` share these methods.

#### Query

| Method                                       | Returns  | Description                       |
| -------------------------------------------- | -------- | --------------------------------- |
| `inst:get_children()`                        | table    | Direct children                   |
| `inst:get_descendants()`                     | table    | All descendants recursively       |
| `inst:find_first_child(name)`                | Instance | First child with matching name    |
| `inst:find_first_child(name, true)`          | Instance | Recursive child search            |
| `inst:find_first_child_of_class(class)`      | Instance | First child matching class name   |
| `inst:find_first_child_which_is_a(class)`    | Instance | First child inheriting class      |
| `inst:find_first_descendant(name)`           | Instance | Recursive descendant by name      |
| `inst:find_first_descendant_of_class(class)` | Instance | Recursive descendant by class     |
| `inst:find_first_ancestor(name)`             | Instance | First ancestor with matching name |
| `inst:find_first_ancestor_of_class(class)`   | Instance | First ancestor matching class     |
| `inst:is_a(class_name)`                      | bool     | Checks class inheritance          |
| `inst:is_descendant_of(ancestor)`            | bool     | True if inst is under ancestor    |
| `inst:is_ancestor_of(descendant)`            | bool     | True if inst is above descendant  |

```lua
local char  = game.local_player.character
local hum   = char:find_first_child("Humanoid")
local parts = char:get_children()
local descs = game.workspace:get_descendants()

for _, v in ipairs(descs) do
    if v:is_a("BasePart") then
        print(v.name)
    end
end
```

***

### Instance Properties

All instances expose `Name`, `ClassName`, `Parent`, and `Address` as read-only properties. Additional properties depend on the instance class. Properties marked **read / write** can be set directly by assignment.

#### Common

| Property    | Type     | Access |
| ----------- | -------- | ------ |
| `Name`      | string   | read   |
| `ClassName` | string   | read   |
| `Parent`    | Instance | read   |
| `Address`   | number   | read   |

#### BasePart

| Property          | Type            | Access                       |
| ----------------- | --------------- | ---------------------------- |
| `Position`        | Vector3         | read / write                 |
| `Size`            | Vector3         | read / write                 |
| `Velocity`        | Vector3         | read / write                 |
| `AngularVelocity` | Vector3         | read / write                 |
| `CFrame`          | Vector3         | read / write (position only) |
| `Rotation`        | table (3×3)     | read / write                 |
| `LookVector`      | Vector3         | read                         |
| `RightVector`     | Vector3         | read                         |
| `UpVector`        | Vector3         | read                         |
| `Color`           | table `{R,G,B}` | read                         |
| `Transparency`    | number          | read / write                 |
| `Reflectance`     | number          | read / write                 |
| `CanCollide`      | bool            | read / write                 |
| `Anchored`        | bool            | read / write                 |
| `CanQuery`        | bool            | read / write                 |
| `CanTouch`        | bool            | read / write                 |
| `CastShadow`      | bool            | read / write                 |
| `Locked`          | bool            | read / write                 |
| `Massless`        | bool            | read / write                 |
| `Shape`           | number          | read                         |

#### Humanoid

| Property                | Type     | Access       |
| ----------------------- | -------- | ------------ |
| `Health`                | number   | read / write |
| `MaxHealth`             | number   | read / write |
| `WalkSpeed`             | number   | read / write |
| `JumpPower`             | number   | read / write |
| `JumpHeight`            | number   | read / write |
| `HipHeight`             | number   | read / write |
| `MaxSlopeAngle`         | number   | read / write |
| `State`                 | number   | read / write |
| `StateName`             | string   | read         |
| `IsAlive`               | bool     | read         |
| `IsDead`                | bool     | read         |
| `Sit`                   | bool     | read / write |
| `Jump`                  | bool     | read / write |
| `PlatformStand`         | bool     | read / write |
| `AutoRotate`            | bool     | read / write |
| `AutoJumpEnabled`       | bool     | read / write |
| `UseJumpPower`          | bool     | read / write |
| `RequiresNeck`          | bool     | read / write |
| `BreakJointsOnDeath`    | bool     | read / write |
| `EvaluateStateMachine`  | bool     | read / write |
| `IsWalking`             | bool     | read         |
| `WalkspeedCheck`        | number   | read / write |
| `WalkTimer`             | number   | read         |
| `MoveDirection`         | Vector3  | read         |
| `CameraOffset`          | Vector3  | read / write |
| `TargetPoint`           | Vector3  | read         |
| `RigType`               | number   | read         |
| `FloorMaterial`         | number   | read         |
| `DisplayDistanceType`   | number   | read / write |
| `HealthDisplayDistance` | number   | read / write |
| `HealthDisplayType`     | number   | read / write |
| `NameDisplayDistance`   | number   | read / write |
| `NameOcclusion`         | number   | read / write |
| `DisplayName`           | string   | read         |
| `SeatPart`              | Instance | read         |
| `HumanoidRootPart`      | Instance | read         |

#### Player

| Property                | Type     | Access       |
| ----------------------- | -------- | ------------ |
| `Character`             | Instance | read         |
| `UserId`                | number   | read         |
| `DisplayName`           | string   | read         |
| `Team`                  | Instance | read         |
| `AccountAge`            | number   | read         |
| `CameraMode`            | number   | read / write |
| `MaxZoomDistance`       | number   | read / write |
| `MinZoomDistance`       | number   | read / write |
| `HealthDisplayDistance` | number   | read / write |
| `NameDisplayDistance`   | number   | read / write |

#### Camera

| Property              | Type     | Access       |
| --------------------- | -------- | ------------ |
| `Position` / `CFrame` | Vector3  | read         |
| `FieldOfView`         | number   | read / write |
| `LookVector`          | Vector3  | read         |
| `CameraType`          | number   | read / write |
| `CameraSubject`       | Instance | read         |

#### Model

| Property      | Type     | Access |
| ------------- | -------- | ------ |
| `PrimaryPart` | Instance | read   |
| `Scale`       | number   | read   |

#### Tool

| Property               | Type | Access       |
| ---------------------- | ---- | ------------ |
| `CanBeDropped`         | bool | read / write |
| `Enabled`              | bool | read / write |
| `ManualActivationOnly` | bool | read / write |
| `RequiresHandle`       | bool | read / write |

#### Sound

| Property             | Type   | Access       |
| -------------------- | ------ | ------------ |
| `Volume`             | number | read / write |
| `PlaybackSpeed`      | number | read / write |
| `Looped`             | bool   | read / write |
| `Playing`            | bool   | read / write |
| `RollOffMinDistance` | number | read / write |
| `RollOffMaxDistance` | number | read / write |

#### ProximityPrompt

| Property                | Type   | Access       |
| ----------------------- | ------ | ------------ |
| `Enabled`               | bool   | read / write |
| `MaxActivationDistance` | number | read / write |
| `HoldDuration`          | number | read / write |
| `KeyCode`               | number | read / write |
| `RequiresLineOfSight`   | bool   | read / write |

#### Seat / VehicleSeat

| Property    | Type     | Access       |
| ----------- | -------- | ------------ |
| `Occupant`  | Instance | read         |
| `MaxSpeed`  | number   | read / write |
| `Steer`     | number   | read         |
| `Throttle`  | number   | read         |
| `Torque`    | number   | read / write |
| `TurnSpeed` | number   | read / write |

#### ScreenGui

| Property  | Type | Access       |
| --------- | ---- | ------------ |
| `Enabled` | bool | read / write |

#### Workspace

| Property              | Type     | Access       |
| --------------------- | -------- | ------------ |
| `Gravity`             | number   | read / write |
| `Terrain`             | Instance | read         |
| `DistributedGameTime` | number   | read         |

#### Lighting

| Property                   | Type              | Access       |
| -------------------------- | ----------------- | ------------ |
| `Brightness`               | number            | read / write |
| `ExposureCompensation`     | number            | read / write |
| `FogStart`                 | number            | read / write |
| `FogEnd`                   | number            | read / write |
| `EnvironmentDiffuseScale`  | number            | read / write |
| `EnvironmentSpecularScale` | number            | read / write |
| `ClockTime`                | number            | read / write |
| `GeographicLatitude`       | number            | read / write |
| `GlobalShadows`            | bool              | read / write |
| `Ambient`                  | table `{r,g,b,a}` | read / write |
| `OutdoorAmbient`           | table `{r,g,b,a}` | read / write |
| `FogColor`                 | table `{r,g,b,a}` | read / write |

#### Terrain

| Property            | Type              | Access       |
| ------------------- | ----------------- | ------------ |
| `GrassLength`       | number            | read / write |
| `WaterTransparency` | number            | read / write |
| `WaterReflectance`  | number            | read / write |
| `WaterWaveSize`     | number            | read / write |
| `WaterWaveSpeed`    | number            | read / write |
| `WaterColor`        | table `{r,g,b,a}` | read / write |

#### GuiObject (Frame, TextLabel, TextButton, TextBox, ImageLabel, ImageButton, ScrollingFrame)

| Property           | Type            | Access |
| ------------------ | --------------- | ------ |
| `Visible`          | bool            | read   |
| `Rotation`         | number          | read   |
| `LayoutOrder`      | number          | read   |
| `Position`         | table           | read   |
| `Size`             | table           | read   |
| `BackgroundColor3` | table `{R,G,B}` | read   |
| `Text`             | string          | read   |
| `RichText`         | bool            | read   |
| `TextColor3`       | table `{R,G,B}` | read   |

#### Value Instances (IntValue, NumberValue, BoolValue, StringValue, ObjectValue, Vector3Value, CFrameValue)

| Property | Type   | Access       |
| -------- | ------ | ------------ |
| `Value`  | varies | read / write |

***

### Getting and Setting Attributes

Every property listed in the tables above can be read or written directly using dot notation — no boilerplate, no helper functions.

#### Getting an Attribute

```lua
local value = instance.AttributeName
```

```lua
local char = game.local_player.character
local hum  = char:find_first_child("Humanoid")

local hp       = hum.Health         -- number
local speed    = hum.WalkSpeed      -- number
local alive    = hum.IsAlive        -- bool
local state    = hum.StateName      -- string
local pos      = hum.HumanoidRootPart.Position  -- Vector3

print(hp, speed, alive, state)
print(pos.x, pos.y, pos.z)
```

#### Setting an Attribute

```lua
instance.AttributeName = value
```

```lua
local hum = game.local_player.character:find_first_child("Humanoid")

hum.WalkSpeed   = 100
hum.JumpPower   = 200
hum.MaxHealth   = 9999
hum.Health      = 9999
```

#### Checking Before Access

Always validate instances before reading from them, especially when iterating the workspace or using cached references:

```lua
local inst = game.workspace:find_first_child("SomePart")
if not utility.is_valid(inst) then return end

local t = inst.Transparency
```

#### Reading Across the Hierarchy

You can chain property access across parent–child relationships:

```lua
local lp    = game.local_player
local char  = lp.character
local root  = char:find_first_child("HumanoidRootPart")
local hum   = char:find_first_child("Humanoid")

if utility.is_valid(root) and utility.is_valid(hum) then
    local pos   = root.Position
    local speed = hum.WalkSpeed
    local state = hum.StateName
    print(string.format("pos=%.1f,%.1f,%.1f  speed=%d  state=%s",
        pos.x, pos.y, pos.z, speed, state))
end
```

#### Writing Across Instance Types

The same dot-notation write works on any writable property regardless of instance class:

```lua
-- BasePart
local part = game.workspace:find_first_child("Floor")
if utility.is_valid(part) then
    part.Transparency = 0.5
    part.CanCollide   = false
    part.Anchored     = true
end

-- Lighting
local lit = game.lighting
lit.ClockTime      = 14
lit.Brightness     = 2
lit.GlobalShadows  = false
lit.Ambient        = {1, 1, 1}

-- Sound
for _, inst in ipairs(game.workspace:get_descendants()) do
    if inst:is_a("Sound") then
        inst.Volume  = 0
        inst.Playing = false
    end
end

-- Value instance
local val = game.workspace:find_first_descendant("ArmorValue")
if utility.is_valid(val) then
    print(val.Value)         -- read
    val.Value = 100          -- write
end
```

#### Iterating and Reading Attributes From All Instances of a Class

```lua
-- print the health of every Humanoid in the workspace
for _, inst in ipairs(game.workspace:get_descendants()) do
    if inst:is_a("Humanoid") then
        print(inst.parent.Name .. " -> " .. inst.Health .. " / " .. inst.MaxHealth)
    end
end
```

```lua
-- collect every BasePart that is anchored
local anchored = {}
for _, inst in ipairs(game.workspace:get_descendants()) do
    if inst:is_a("BasePart") and inst.Anchored then
        table.insert(anchored, inst)
    end
end
print("anchored parts: " .. #anchored)
```

#### Watching an Attribute Every Frame

```lua
function on_frame()
    local hum = game.local_player.character
                    and game.local_player.character:find_first_child("Humanoid")
    if not utility.is_valid(hum) then return end

    local hp  = hum.Health
    local max = hum.MaxHealth
    local pct = hp / max

    -- draw a local health bar at the top of the screen
    local sw  = select(1, draw.get_screen_size())
    local bw  = 200
    local bx  = (sw - bw) * 0.5
    draw.rect_filled(bx, 10, bw, 10, {0.15, 0.15, 0.15, 0.8})
    draw.rect_filled(bx, 10, math.floor(bw * pct), 10, {0, 1, 0.3, 1})
    draw.text(bx, 22, string.format("%.0f / %.0f", hp, max), {1, 1, 1, 1})
end
```

***

### Custom Roblox Attributes

Roblox lets developers attach arbitrary key-value pairs — called **custom attributes** — to any instance using the Studio **Attributes** panel or `Instance:SetAttribute()`. These are separate from the built-in properties listed above. The engine exposes three methods to read and write them.

#### inst:get\_attribute

```lua
local value = inst:get_attribute(name)
```

| Parameter | Type   | Required | Description                   |
| --------- | ------ | -------- | ----------------------------- |
| `name`    | string | yes      | Attribute key, case-sensitive |

Returns the value of the named attribute as the correct Lua type (`number`, `boolean`, `string`, `Vector3`, or `table` for Color3 / Vector2). Returns `nil` if the attribute does not exist on this instance.

**Example — Workspace.Oasis.MaxHeight:**

```lua
-- Oasis is a direct child of Workspace
local oasis = game.workspace:find_first_child("Oasis")
if not utility.is_valid(oasis) then return end

local max_height = oasis:get_attribute("MaxHeight")
print("MaxHeight:", max_height)   -- 365
```

***

#### inst:get\_attributes

```lua
local attrs = inst:get_attributes()
```

Returns a table containing all custom attributes on the instance, keyed by attribute name. Useful for inspecting what attributes exist without knowing their names in advance.

```lua
local oasis = game.workspace:find_first_child("Oasis")
if not utility.is_valid(oasis) then return end

local all = oasis:get_attributes()
for k, v in pairs(all) do
    print(k, "=", v)
end
-- MaxHeight = 365
```

***

#### inst:set\_attribute

```lua
local ok = inst:set_attribute(name, value)
```

| Parameter | Type             | Required | Description                               |
| --------- | ---------------- | -------- | ----------------------------------------- |
| `name`    | string           | yes      | Attribute key, case-sensitive             |
| `value`   | number / boolean | yes      | New value — must match the attribute type |

Writes `value` to the attribute. Returns `true` on success, `false` if the attribute was not found on this instance or the type is not writable (string, Color3, and Vector3 attributes are read-only via this method).

```lua
local oasis = game.workspace:find_first_child("Oasis")
if not utility.is_valid(oasis) then return end

-- read the current value
local height = oasis:get_attribute("MaxHeight")
print("before:", height)      -- 365

-- write a new value
local ok = oasis:set_attribute("MaxHeight", 50)
print("set ok:", ok)          -- true

-- verify
print("after:", oasis:get_attribute("MaxHeight"))  -- 50
```

***

#### Supported Attribute Types

| Lua type returned | Roblox type               |
| ----------------- | ------------------------- |
| `number`          | float, double, int, int64 |
| `boolean`         | bool                      |
| `string`          | string                    |
| `Vector3`         | Vector3                   |
| `table {r,g,b}`   | Color3                    |
| `table {x,y}`     | Vector2                   |

> `set_attribute` supports writing `number` and `boolean` attributes. String, Color3, and Vector3 attributes are read-only through this API.

***

### Write Methods

Some writes are also available as explicit method calls in addition to property assignment.

#### BasePart Methods

| Method                               | Parameters | Description                 |
| ------------------------------------ | ---------- | --------------------------- |
| `inst:set_position(x, y, z)`         | number × 3 | Set world position          |
| `inst:set_size(x, y, z)`             | number × 3 | Set dimensions              |
| `inst:set_velocity(x, y, z)`         | number × 3 | Set linear velocity         |
| `inst:set_angular_velocity(x, y, z)` | number × 3 | Set rotational velocity     |
| `inst:set_transparency(v)`           | number     | Set transparency 0–1        |
| `inst:set_can_collide(b)`            | bool       | Toggle collision            |
| `inst:set_anchored(b)`               | bool       | Toggle anchored             |
| `inst:set_can_query(b)`              | bool       | Toggle raycast queryability |
| `inst:set_can_touch(b)`              | bool       | Toggle touch events         |

#### Humanoid Methods

| Method                    | Parameters | Description               |
| ------------------------- | ---------- | ------------------------- |
| `inst:set_health(v)`      | number     | Set current health        |
| `inst:set_max_health(v)`  | number     | Set maximum health        |
| `inst:set_walk_speed(v)`  | number     | Set movement speed        |
| `inst:set_jump_power(v)`  | number     | Set jump power            |
| `inst:set_jump_height(v)` | number     | Set jump height           |
| `inst:set_state(id)`      | number     | Set humanoid state (0–18) |

***

### Humanoid States

| Value | Name              | Description                 |
| ----- | ----------------- | --------------------------- |
| 0     | FallingDown       | Tripped / falling down      |
| 1     | Ragdoll           | Ragdolled                   |
| 2     | GettingUp         | Recovering from fall        |
| 3     | Jumping           | Jumping upward              |
| 4     | Swimming          | In water                    |
| 5     | Freefall          | Falling through air         |
| 6     | Flying            | Flying                      |
| 7     | Landed            | Just landed                 |
| 8     | Running           | Running / walking (default) |
| 10    | RunningNoPhysics  | Server-controlled running   |
| 11    | StrafingNoPhysics | Server-controlled strafing  |
| 12    | Climbing          | On a ladder or truss        |
| 13    | Seated            | Sitting in a seat           |
| 14    | PlatformStanding  | Standing on a platform      |
| 15    | Dead              | Dead                        |
| 16    | Physics           | Physics-controlled          |
| 18    | None              | No state / disabled         |

***

### Vector3

#### Constructor

```lua
local v = Vector3.new(x, y, z)
```

#### Properties

| Property    | Type    | Description          |
| ----------- | ------- | -------------------- |
| `x` `y` `z` | number  | Components           |
| `magnitude` | number  | Length of the vector |
| `unit`      | Vector3 | Normalised direction |

#### Methods

| Method             | Parameters      | Returns | Description          |
| ------------------ | --------------- | ------- | -------------------- |
| `v:dot(other)`     | Vector3         | number  | Dot product          |
| `v:cross(other)`   | Vector3         | Vector3 | Cross product        |
| `v:lerp(other, t)` | Vector3, number | Vector3 | Linear interpolation |

#### Operators

```lua
local a = Vector3.new(1, 0, 0)
local b = Vector3.new(0, 1, 0)
local c = a + b        -- addition
local d = a - b        -- subtraction
local e = a * 5        -- scalar multiply
local f = a / 2        -- scalar divide
local g = -a           -- negation
local len = #a         -- magnitude
local eq  = (a == b)   -- equality
```

***

### camera

#### Methods

| Method                            | Returns | Description              |
| --------------------------------- | ------- | ------------------------ |
| `camera.get_position()`           | Vector3 | Camera world position    |
| `camera.get_look_vector()`        | Vector3 | Camera forward direction |
| `camera.get_fov()`                | number  | Current field of view    |
| `camera.set_fov(value)`           | bool    | Set field of view        |
| `camera.look_at(target, smooth?)` | bool    | Point camera at target   |

`camera.look_at` accepts a Vector3, three separate numbers, or a Vector3 with an optional smooth frame count:

```lua
camera.look_at(target_vec3)       -- snap
camera.look_at(target_vec3, 10)   -- smooth over 10 frames
camera.look_at(x, y, z)          -- raw numbers
```

***

### input

#### Methods

| Method                      | Parameters     | Returns        | Description                    |
| --------------------------- | -------------- | -------------- | ------------------------------ |
| `input.is_key_down(vk)`     | number         | bool           | True if key is held            |
| `input.get_screen_center()` | —              | number, number | Screen centre x, y             |
| `input.move_mouse(dx, dy)`  | number, number | —              | Move cursor by relative offset |

#### Common Virtual Key Codes

| Code   | Key                 |
| ------ | ------------------- |
| `0x01` | Left Mouse Button   |
| `0x02` | Right Mouse Button  |
| `0x04` | Middle Mouse Button |
| `0x10` | Shift               |
| `0x11` | Ctrl                |
| `0x12` | Alt                 |
| `0x20` | Space               |
| `0x1B` | Escape              |

***

### part

Directly writes game state to part properties via memory.

| Method                                     | Parameters           | Description                 |
| ------------------------------------------ | -------------------- | --------------------------- |
| `part.set_position(inst, x, y, z)`         | Instance, number × 3 | Set world position          |
| `part.set_size(inst, x, y, z)`             | Instance, number × 3 | Set dimensions              |
| `part.set_velocity(inst, x, y, z)`         | Instance, number × 3 | Set linear velocity         |
| `part.set_angular_velocity(inst, x, y, z)` | Instance, number × 3 | Set rotational velocity     |
| `part.set_transparency(inst, v)`           | Instance, number     | Set transparency 0–1        |
| `part.set_can_collide(inst, b)`            | Instance, bool       | Toggle collision            |
| `part.set_anchored(inst, b)`               | Instance, bool       | Toggle anchored             |
| `part.set_can_query(inst, b)`              | Instance, bool       | Toggle raycast queryability |
| `part.set_can_touch(inst, b)`              | Instance, bool       | Toggle touch events         |

```lua
local root = game.local_player.character:find_first_child("HumanoidRootPart")
if root then
    part.set_velocity(root, 0, 100, 0)
    part.set_anchored(root, true)
    part.set_can_collide(root, false)
end
```

***

### Examples

**Noclip:**

```lua
function on_frame()
    if not input.is_key_down(0x11) then return end
    local char = game.local_player.character
    if not char then return end
    for _, p in ipairs(char:get_children()) do
        if p:is_a("BasePart") then
            p.CanCollide = false
        end
    end
end
```

**Speed hack with anti-cheat mirror:**

```lua
local char = game.local_player.character
local hum  = char:find_first_child("Humanoid")
if hum then
    hum.WalkSpeed     = 100
    hum.WalkspeedCheck = 100
end
```

**Fullbright:**

```lua
local lit = game.lighting
lit.Brightness      = 2
lit.ClockTime       = 14
lit.FogEnd          = 100000
lit.GlobalShadows   = false
lit.Ambient         = {1, 1, 1}
lit.OutdoorAmbient  = {1, 1, 1}
```

**Teleport:**

```lua
local root = game.local_player.character:find_first_child("HumanoidRootPart")
if root then
    root.Position = Vector3.new(0, 100, 0)
end
```

**Force fly state:**

```lua
local hum = game.local_player.character:find_first_child("Humanoid")
if hum then
    hum.State = 6
    print("state: " .. hum.StateName)
end
```

**Disable all proximity prompts:**

```lua
for _, inst in ipairs(game.workspace:get_descendants()) do
    if inst.ClassName == "ProximityPrompt" then
        inst.Enabled = false
    end
end
```

**Mute all sounds:**

```lua
for _, inst in ipairs(game.workspace:get_descendants()) do
    if inst:is_a("Sound") then
        inst.Volume  = 0
        inst.Playing = false
    end
end
```

**Lock first person:**

```lua
local lp = game.local_player
lp.CameraMode       = 1
lp.MinZoomDistance  = 0.5
lp.MaxZoomDistance  = 0.5
```

***

### Notes

* Always call `utility.is_valid(instance)` before accessing properties on instances that may have been destroyed.
* Property writes via dot notation (e.g. `inst.Transparency = 0.5`) work for every property marked **read / write** in the tables above.
* `WalkspeedCheck` mirrors the server-side read of `WalkSpeed` used by some anti-cheats — set both together when changing movement speed.
* Humanoid state writes are client-side only. The server may override them depending on game logic.
* Write operations on physics properties (velocity, position) replicate to the server only when the local client owns the part's network ownership.
* `instance.Address` exposes the raw memory address of any instance. See the Custom Attributes page for how to use it alongside the Memory API.
* `inst:get_attribute(name)` / `inst:set_attribute(name, value)` / `inst:get_attributes()` access Roblox custom attributes — key-value pairs attached in Studio, separate from built-in properties.

# Menu API

The menu API lets scripts add UI elements to the cheat menu. All elements are identified by a string `id` that you use to read and write values later.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

### Setup — tabs and groups

Every element must live inside a tab and a group. Create them before adding elements:

```lua
menu.add_tab("Visuals", "V")           -- name, icon letter
menu.add_group("Visuals", "Players")   -- tab name, group name
```

All `add_*` functions take `tab` and `group` as the first two arguments.

***

### menu.add\_checkbox

```lua
menu.add_checkbox(tab, group, id, label, default, options)
```

| Parameter | Type    | Required | Description                   |
| --------- | ------- | -------- | ----------------------------- |
| `tab`     | string  | yes      | Tab name                      |
| `group`   | string  | yes      | Group name                    |
| `id`      | string  | yes      | Unique element ID             |
| `label`   | string  | yes      | Display label                 |
| `default` | boolean | yes      | Default value                 |
| `options` | table   | no       | Optional settings (see below) |

**Options table:**

| Key           | Type              | Description                              |
| ------------- | ----------------- | ---------------------------------------- |
| `key`         | number            | Attach a hotkey (VK code)                |
| `colorpicker` | table `{r,g,b,a}` | Attach an inline colorpicker             |
| `color`       | table `{r,g,b,a}` | Attach a color swatch                    |
| `parent`      | string            | Element ID to use as a visibility parent |
| `show_mode`   | boolean           | Show hotkey mode selector                |

```lua
-- basic
menu.add_checkbox("Visuals", "Players", "esp_on", "Enable ESP", false)

-- with hotkey and colorpicker
menu.add_checkbox("Visuals", "Players", "esp_on", "Enable ESP", false, {
    key = 0x2E,
    colorpicker = {1, 1, 1, 1},
})
```

***

### menu.add\_slider\_int

```lua
menu.add_slider_int(tab, group, id, label, min, max, default, options)
```

```lua
menu.add_slider_int("Visuals", "Players", "fov_size", "FOV Size", 10, 300, 90)

-- with format string
menu.add_slider_int("Visuals", "Players", "fov_size", "FOV Size", 10, 300, 90, "%dpx")

-- with parent
menu.add_slider_int("Visuals", "Players", "fov_size", "FOV Size", 10, 300, 90,
    { parent = "aimbot_on" })
```

***

### menu.add\_slider\_float

```lua
menu.add_slider_float(tab, group, id, label, min, max, default, options)
```

```lua
menu.add_slider_float("Aimbot", "Settings", "smooth", "Smooth", 0.0, 1.0, 0.15)

-- with format string and parent
menu.add_slider_float("Aimbot", "Settings", "smooth", "Smooth", 0.0, 1.0, 0.15, "%.2f",
    { parent = "aimbot_on" })
```

***

### menu.add\_combo

```lua
menu.add_combo(tab, group, id, label, items, default_index, options)
```

Returns the selected item as a zero-based index.

```lua
menu.add_combo("Visuals", "Players", "box_style", "Box Style",
    {"Normal", "Corner", "Filled"}, 0)
```

***

### menu.add\_multicombo

```lua
menu.add_multicombo(tab, group, id, label, items, defaults)
```

Returns a table of booleans, one per item.

```lua
menu.add_multicombo("Visuals", "Players", "bone_list", "Bones",
    {"Head", "Torso", "Arms", "Legs"},
    {true, true, false, false})
```

***

### menu.add\_button

```lua
menu.add_button(tab, group, id, label, callback)
```

```lua
menu.add_button("Config", "Actions", "reload_btn", "Reload Config", function()
    print("reloading...")
end)
```

***

### menu.add\_colorpicker

```lua
menu.add_colorpicker(tab, group, id, label, default_rgba, options)
```

```lua
menu.add_colorpicker("Visuals", "Players", "esp_color", "ESP Color", {1, 1, 1, 1})

-- with parent
menu.add_colorpicker("Visuals", "Players", "esp_color", "ESP Color", {1, 1, 1, 1},
    { parent = "esp_on" })
```

***

### menu.add\_hotkey

```lua
menu.add_hotkey(tab, group, id, label, default_key, options)
```

```lua
menu.add_hotkey("Aimbot", "Settings", "aim_key", "Aimbot Key", 0x02)
```

***

### menu.add\_input

```lua
menu.add_input(tab, group, id, label, default_text)
```

```lua
menu.add_input("Config", "General", "prefix", "Chat Prefix", "[VEC]")
```

***

### menu.add\_label

```lua
menu.add_label(tab, group, text)
```

Renders a dimmed text label. No ID required.

```lua
menu.add_label("Visuals", "Players", "Colors are in RGBA 0-1 range")
```

***

### menu.add\_separator

```lua
menu.add_separator(tab, group)
```

Inserts a vertical spacer between elements.

***

### Reading values

```lua
local enabled = menu.get("esp_on")        -- boolean
local fov     = menu.get("fov_size")      -- number (int)
local smooth  = menu.get("smooth")        -- number (float)
local style   = menu.get("box_style")     -- number (zero-based index)
local bones   = menu.get("bone_list")     -- table of booleans
local text    = menu.get("prefix")        -- string
local color   = menu.get_color("esp_color")  -- {r, g, b, a}
local key     = menu.get_key("aim_key")   -- number (VK code)
```

***

### Writing values

```lua
menu.set("esp_on", true)
menu.set("fov_size", 120)
menu.set("smooth", 0.2)
menu.set("box_style", 1)
menu.set_color("esp_color", {0, 1, 0.8, 1})
menu.set_key("aim_key", 0x02)
```

***

### Callbacks

Called whenever the user changes the value of an element.

```lua
menu.set_callback("fov_size", function(new_value)
    print("fov changed to: " .. new_value)
end)

menu.set_callback("esp_on", function(new_value)
    print("esp is now: " .. tostring(new_value))
end)
```

***

### Visibility

```lua
menu.set_visible("fov_size", false)
menu.set_visible("fov_size", true)
```

***

### Parent (conditional visibility)

Attach elements to a checkbox — they only render when the checkbox is enabled:

```lua
menu.add_checkbox("Aimbot", "Settings", "aimbot_on", "Enable Aimbot", false)

menu.add_slider_float("Aimbot", "Settings", "smooth", "Smooth",
    0.0, 1.0, 0.15, { parent = "aimbot_on" })

menu.add_slider_int("Aimbot", "Settings", "fov", "FOV",
    10, 300, 90, { parent = "aimbot_on" })

menu.add_hotkey("Aimbot", "Settings", "aim_key", "Key",
    0x02, { parent = "aimbot_on" })
```

***

### Full setup example

```lua
-- tabs and groups
menu.add_tab("Visuals", "V")
menu.add_group("Visuals", "ESP")

menu.add_tab("Aimbot", "A")
menu.add_group("Aimbot", "Settings")

-- visuals
menu.add_checkbox("Visuals", "ESP", "esp_on",    "Enable ESP",  false)
menu.add_checkbox("Visuals", "ESP", "esp_names", "Names",       true,  { parent = "esp_on" })
menu.add_checkbox("Visuals", "ESP", "esp_boxes", "Boxes",       true,  { parent = "esp_on" })
menu.add_combo("Visuals",    "ESP", "box_style", "Box Style",   {"Normal", "Corner"}, 0)
menu.add_colorpicker("Visuals", "ESP", "esp_col", "Color",      {1, 1, 1, 1})
menu.add_slider_float("Visuals", "ESP", "esp_dist", "Max Dist", 0, 500, 200, { parent = "esp_on" })

-- aimbot
menu.add_checkbox("Aimbot", "Settings", "aimbot_on", "Enable Aimbot", false)
menu.add_slider_float("Aimbot", "Settings", "smooth",  "Smooth",  0.0, 1.0, 0.15, { parent = "aimbot_on" })
menu.add_slider_int("Aimbot",   "Settings", "fov",     "FOV",     10, 300, 90,    { parent = "aimbot_on" })
menu.add_hotkey("Aimbot",       "Settings", "aim_key", "Key",     0x02)

-- on_frame usage
function on_frame()
    if not menu.get("esp_on") then return end

    local color = menu.get_color("esp_col")
    local style = menu.get("box_style")
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local b = p:get_bounds()
        if not b.valid then goto continue end

        draw.box(b.x, b.y, b.w, b.h, color, 0, style)

        if menu.get("esp_names") then
            local tw, th = draw.get_text_size(p.name, 14)
            draw.text(b.x + b.w / 2 - tw / 2, b.y - th - 2, p.name, {1, 1, 1, 1})
        end

        ::continue::
    end
end
```

***

### API Reference

| Function                     | Returns | Description                   |
| ---------------------------- | ------- | ----------------------------- |
| `menu.add_tab(name, icon)`   | —       | Register a tab                |
| `menu.add_group(tab, name)`  | —       | Register a group inside a tab |
| `menu.add_checkbox(...)`     | —       | Add a checkbox                |
| `menu.add_slider_int(...)`   | —       | Add an integer slider         |
| `menu.add_slider_float(...)` | —       | Add a float slider            |
| `menu.add_combo(...)`        | —       | Add a dropdown                |
| `menu.add_multicombo(...)`   | —       | Add a multi-select dropdown   |
| `menu.add_button(...)`       | —       | Add a button                  |
| `menu.add_colorpicker(...)`  | —       | Add a color picker            |
| `menu.add_hotkey(...)`       | —       | Add a key bind widget         |
| `menu.add_input(...)`        | —       | Add a text input              |
| `menu.add_label(...)`        | —       | Add a text label              |
| `menu.add_separator(...)`    | —       | Add a spacer                  |
| `menu.get(id)`               | any     | Read element value            |
| `menu.get_color(id)`         | table   | Read color value              |
| `menu.get_key(id)`           | number  | Read key value                |
| `menu.set(id, value)`        | —       | Write element value           |
| `menu.set_color(id, rgba)`   | —       | Write color value             |
| `menu.set_key(id, vk)`       | —       | Write key value               |
| `menu.set_callback(id, fn)`  | —       | Set on-change callback        |
| `menu.set_visible(id, bool)` | —       | Show or hide element          |

# Entity API

The entity API provides access to cached player data. Player objects are snapshots updated each frame. Properties marked as **live** perform a memory read on every access. All others are read from the frame cache.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

### entity.get\_players

```lua
local players = entity.get_players()
```

Returns a table of all valid player objects currently in the game. Includes both Players service characters and workspace entities (NPCs, bots).

***

### entity.get\_local\_player

```lua
local me = entity.get_local_player()
```

Returns the local player object, or nil if not available.

***

### entity.get\_player\_count

```lua
local count = entity.get_player_count()
```

Returns the number of valid players in the cache.

***

### Player Object

#### Cached Properties

Read from the frame snapshot, no memory cost.

| Property              | Type   | Description                                |
| --------------------- | ------ | ------------------------------------------ |
| `name`                | string | Player username                            |
| `display_name`        | string | Display name                               |
| `user_id`             | number | Roblox user ID (0 for NPCs)                |
| `team`                | string | Team name                                  |
| `has_team`            | bool   | Whether the player is on a team            |
| `tool_name`           | string | Name of equipped tool                      |
| `is_local`            | bool   | True if this is the local player           |
| `is_valid`            | bool   | True if the player data is valid           |
| `is_workspace_entity` | bool   | True if found via workspace scan (NPC/bot) |
| `rig_type`            | string | "R15", "R6", or "Unknown"                  |

#### Live Properties

Each access performs a memory read. These reflect the current game state.

| Property          | Type    | Description                         |
| ----------------- | ------- | ----------------------------------- |
| `health`          | number  | Current health                      |
| `max_health`      | number  | Maximum health                      |
| `is_alive`        | bool    | True if health > 0                  |
| `is_dead`         | bool    | True if health <= 0                 |
| `position`        | Vector3 | Root part world position            |
| `velocity`        | Vector3 | Root part linear velocity           |
| `head_position`   | Vector3 | Head world position                 |
| `look_vector`     | Vector3 | Head forward direction              |
| `move_direction`  | Vector3 | Humanoid move direction             |
| `camera_offset`   | Vector3 | Humanoid camera offset              |
| `walk_speed`      | number  | Current walk speed                  |
| `jump_power`      | number  | Current jump power                  |
| `jump_height`     | number  | Current jump height                 |
| `hip_height`      | number  | Hip height                          |
| `max_slope_angle` | number  | Maximum walkable slope angle        |
| `state`           | number  | Humanoid state enum value           |
| `state_name`      | string  | Humanoid state as a readable string |
| `sit`             | bool    | True if seated                      |
| `is_jumping`      | bool    | True if jump is active              |
| `platform_stand`  | bool    | Platform standing state             |
| `auto_rotate`     | bool    | Auto rotate enabled                 |
| `is_walking`      | bool    | True if currently walking           |
| `floor_material`  | number  | Material enum of the floor          |

#### Instance References

These return game API instance objects for interop with the `game` API.

| Property    | Type     | Description           |
| ----------- | -------- | --------------------- |
| `character` | Instance | Character model       |
| `humanoid`  | Instance | Humanoid instance     |
| `player`    | Instance | Player service object |

#### Writable Properties

Player objects support direct property writes through assignment. These write to game memory immediately.

**Humanoid writes** (require humanoid):

| Property                 | Type    | Description                  |
| ------------------------ | ------- | ---------------------------- |
| `health`                 | number  | Set health                   |
| `max_health`             | number  | Set max health               |
| `walk_speed`             | number  | Set walk speed               |
| `jump_power`             | number  | Set jump power               |
| `jump_height`            | number  | Set jump height              |
| `hip_height`             | number  | Set hip height               |
| `max_slope_angle`        | number  | Set max slope angle          |
| `state`                  | number  | Set humanoid state enum      |
| `sit`                    | bool    | Set seated state             |
| `jump`                   | bool    | Trigger/cancel jump          |
| `platform_stand`         | bool    | Set platform standing        |
| `auto_rotate`            | bool    | Set auto rotate              |
| `auto_jump_enabled`      | bool    | Set auto jump                |
| `use_jump_power`         | bool    | Toggle jump power vs height  |
| `requires_neck`          | bool    | Set requires neck joint      |
| `break_joints_on_death`  | bool    | Set break joints on death    |
| `evaluate_state_machine` | bool    | Enable/disable state machine |
| `camera_offset`          | Vector3 | Set humanoid camera offset   |
| `walkspeed_check`        | number  | Anti-cheat walkspeed mirror  |

**Primitive writes** (require root\_primitive):

| Property           | Type    | Description          |
| ------------------ | ------- | -------------------- |
| `position`         | Vector3 | Set root position    |
| `velocity`         | Vector3 | Set linear velocity  |
| `angular_velocity` | Vector3 | Set angular velocity |
| `anchored`         | bool    | Set anchored flag    |
| `can_collide`      | bool    | Set collision flag   |
| `can_query`        | bool    | Set query flag       |
| `can_touch`        | bool    | Set touch flag       |

***

### Player Methods

#### :get\_bone\_screen(bone\_name)

```lua
local sx, sy, visible = p:get_bone_screen(bone_name)
```

Returns the screen position of a named bone and a boolean indicating whether it is on screen.

```lua
local sx, sy, visible = p:get_bone_screen("Head")
if visible then
    draw.circle_filled(sx, sy, 4, {1, 1, 0, 1})
end
```

Supported R6 bones: `Head`, `Torso`, `Left Arm`, `Right Arm`, `Left Leg`, `Right Leg`, `HumanoidRootPart`

Supported R15 bones: `Head`, `UpperTorso`, `LowerTorso`, `LeftUpperArm`, `LeftLowerArm`, `LeftHand`, `RightUpperArm`, `RightLowerArm`, `RightHand`, `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot`, `RightUpperLeg`, `RightLowerLeg`, `RightFoot`, `HumanoidRootPart`

***

#### :get\_bones\_screen()

```lua
local bones = p:get_bones_screen()
```

Returns a table of all valid bones projected to screen space. Keys are bone name strings, values are `{x, y}` tables.

```lua
local bones = p:get_bones_screen()

if bones["Head"] and bones["UpperTorso"] then
    draw.line(
        bones["Head"][1],       bones["Head"][2],
        bones["UpperTorso"][1], bones["UpperTorso"][2],
        {1, 1, 1, 1}
    )
end
```

***

#### :get\_bounds()

```lua
local b = p:get_bounds()
```

Returns a bounding box table with fields `x`, `y`, `w`, `h`, and `valid`.

```lua
local b = p:get_bounds()
if b.valid then
    draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
end
```

***

#### :distance\_to(point)

```lua
local dist = p:distance_to(point)
local dist = p:distance_to() -- defaults to camera position
```

Returns the distance from the player's root position to a point. If no argument is given, returns distance to the camera.

```lua
local me = entity.get_local_player()
for _, p in ipairs(entity.get_players()) do
    if not p.is_local then
        local dist = p:distance_to(me.position)
        print(p.name .. " is " .. math.floor(dist) .. " studs away")
    end
end
```

***

### Humanoid States

The `state` property returns a numeric enum. Use `state_name` for a readable string.

| Value | Name              | Description                |
| ----- | ----------------- | -------------------------- |
| 0     | FallingDown       | Tripped/falling down       |
| 1     | Ragdoll           | Ragdolled                  |
| 2     | GettingUp         | Recovering from fall       |
| 3     | Jumping           | Jumping upward             |
| 4     | Swimming          | In water                   |
| 5     | Freefall          | Falling through air        |
| 6     | Flying            | Flying                     |
| 7     | Landed            | Just landed                |
| 8     | Running           | Running/walking (default)  |
| 10    | RunningNoPhysics  | Server-controlled running  |
| 11    | StrafingNoPhysics | Server-controlled strafing |
| 12    | Climbing          | Climbing a ladder/truss    |
| 13    | Seated            | Sitting in a seat          |
| 14    | PlatformStanding  | Standing on a platform     |
| 15    | Dead              | Dead                       |
| 16    | Physics           | Physics-controlled         |
| 18    | None              | No state / disabled        |

***

### Examples

#### Full ESP loop

```lua
function on_frame()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local b = p:get_bounds()
        if not b.valid then goto continue end

        draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
        draw.health_bar(b.x - 5, b.y, b.h, p.health, p.max_health)

        local tw, th = draw.get_text_size(p.name, 14)
        draw.text(b.x + b.w / 2 - tw / 2, b.y - th - 2, p.name, {1, 1, 1, 1})

        local hx, hy, hv = p:get_bone_screen("Head")
        if hv then
            draw.circle_filled(hx, hy, 3, {1, 1, 0, 1})
        end

        ::continue::
    end
end
```

#### State display

```lua
function on_frame()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local sx, sy, vis = p:get_bone_screen("Head")
        if vis then
            local state = p.state_name
            if state ~= "Running" then
                local tw, th = draw.get_text_size(state, 12)
                draw.text(sx - tw / 2, sy - 30, state, {1, 0.8, 0.2, 1})
            end
        end

        ::continue::
    end
end
```

#### Speed modification

```lua
local me = entity.get_local_player()
if me then
    me.walk_speed = 50
    me.jump_power = 100
    print("Speed: " .. me.walk_speed)
    print("Jump: " .. me.jump_power)
end
```

#### Force state

```lua
local me = entity.get_local_player()
if me then
    me.state = 6  -- set to Flying
    print("State: " .. me.state_name)
end
```

#### Disable collision on all nearby players

```lua
function on_frame()
    local me = entity.get_local_player()
    if not me then return end

    for _, p in ipairs(entity.get_players()) do
        if not p.is_local and p:distance_to(me.position) < 20 then
            p.can_collide = false
        end
    end
end
```

#### Skeleton rendering

```lua
local connections_r15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

function on_frame()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end
        if p.rig_type ~= "R15" then goto continue end

        local bones = p:get_bones_screen()

        for _, conn in ipairs(connections_r15) do
            local a = bones[conn[1]]
            local b = bones[conn[2]]
            if a and b then
                draw.line(a[1], a[2], b[1], b[2], {1, 1, 1, 0.8})
            end
        end

        ::continue::
    end
end
```

***

### API Reference

| Function                       | Returns       | Description                      |
| ------------------------------ | ------------- | -------------------------------- |
| `entity.get_players()`         | table         | All cached player objects        |
| `entity.get_local_player()`    | player/nil    | Local player object              |
| `entity.get_player_count()`    | number        | Player count                     |
| `player:get_bone_screen(name)` | x, y, visible | Screen position of a bone        |
| `player:get_bones_screen()`    | table         | All bones as screen positions    |
| `player:get_bounds()`          | table         | Bounding box {x, y, w, h, valid} |
| `player:distance_to(vec3?)`    | number        | Distance to point or camera      |

# Draw API

The Draw API renders 2D primitives, polygons, player chams, and images onto the game background. All draw calls must occur inside `on_frame`. The coordinate system places the origin at the top-left corner of the screen, with X increasing rightward and Y increasing downward.

Colors use normalised RGBA tables — `{r, g, b, a}` — where every component is in the range `0.0 – 1.0`. For example, `{1, 0, 0, 1}` is fully-opaque red.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

### Primitives

#### draw\.line

```lua
draw.line(x1, y1, x2, y2, color, thickness)
```

| Parameter   | Type   | Required | Description                              |
| ----------- | ------ | -------- | ---------------------------------------- |
| `x1, y1`    | number | yes      | Start point                              |
| `x2, y2`    | number | yes      | End point                                |
| `color`     | table  | yes      | `{r, g, b, a}`                           |
| `thickness` | number | no       | Line thickness in pixels. Default: `1.0` |

```lua
draw.line(100, 100, 400, 300, {1, 0, 0, 1})
draw.line(0, 0, 200, 200, {1, 1, 1, 0.8}, 2.0)
```

***

#### draw\.rect

```lua
draw.rect(x, y, w, h, color, rounding, thickness)
```

| Parameter   | Type   | Required | Description                                 |
| ----------- | ------ | -------- | ------------------------------------------- |
| `x, y`      | number | yes      | Top-left corner                             |
| `w, h`      | number | yes      | Width and height in pixels                  |
| `color`     | table  | yes      | `{r, g, b, a}`                              |
| `rounding`  | number | no       | Corner rounding radius. Default: `0`        |
| `thickness` | number | no       | Outline thickness in pixels. Default: `1.0` |

```lua
draw.rect(50, 50, 200, 100, {1, 1, 1, 1})
draw.rect(50, 50, 200, 100, {1, 1, 1, 1}, 6.0, 1.5)
```

***

#### draw\.rect\_filled

```lua
draw.rect_filled(x, y, w, h, color, rounding)
```

| Parameter  | Type   | Required | Description                          |
| ---------- | ------ | -------- | ------------------------------------ |
| `x, y`     | number | yes      | Top-left corner                      |
| `w, h`     | number | yes      | Width and height in pixels           |
| `color`    | table  | yes      | `{r, g, b, a}`                       |
| `rounding` | number | no       | Corner rounding radius. Default: `0` |

```lua
draw.rect_filled(10, 10, 150, 80, {0, 0, 0, 0.6})
draw.rect_filled(10, 10, 150, 80, {0, 0, 0, 0.6}, 8.0)
```

***

#### draw\.circle

```lua
draw.circle(x, y, radius, color, segments, thickness)
```

| Parameter   | Type   | Required | Description                       |
| ----------- | ------ | -------- | --------------------------------- |
| `x, y`      | number | yes      | Centre point                      |
| `radius`    | number | yes      | Radius in pixels                  |
| `color`     | table  | yes      | `{r, g, b, a}`                    |
| `segments`  | number | no       | Number of segments. Default: `32` |
| `thickness` | number | no       | Outline thickness. Default: `1.0` |

```lua
draw.circle(500, 400, 80, {1, 1, 1, 0.5}, 64, 1.5)
```

***

#### draw\.circle\_filled

```lua
draw.circle_filled(x, y, radius, color, segments)
```

| Parameter  | Type   | Required | Description                       |
| ---------- | ------ | -------- | --------------------------------- |
| `x, y`     | number | yes      | Centre point                      |
| `radius`   | number | yes      | Radius in pixels                  |
| `color`    | table  | yes      | `{r, g, b, a}`                    |
| `segments` | number | no       | Number of segments. Default: `32` |

```lua
draw.circle_filled(500, 400, 12, {1, 0.5, 0, 1})
```

***

### Text

#### draw\.text

```lua
draw.text(x, y, text, color, size)
```

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `x, y`    | number | yes      | Top-left position of the text        |
| `text`    | string | yes      | String to render                     |
| `color`   | table  | yes      | `{r, g, b, a}`                       |
| `size`    | number | no       | Font size in pixels. Default: `14.0` |

Draws text with an automatic black outline for readability.

```lua
draw.text(100, 100, "hello world", {1, 1, 1, 1})
draw.text(100, 120, "big text", {0, 1, 0.4, 1}, 20.0)
```

***

#### draw\.get\_text\_size

```lua
local w, h = draw.get_text_size(text, size)
```

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `text`    | string | yes      | String to measure                    |
| `size`    | number | no       | Font size in pixels. Default: `14.0` |

Returns the pixel width and height the string would occupy. Use this to centre or right-align text.

```lua
local tw, th = draw.get_text_size("Player", 14.0)
local cx = screen_x - tw * 0.5   -- horizontally centred
draw.text(cx, screen_y, "Player", {1, 1, 1, 1})
```

***

### ESP Helpers

#### draw\.box

```lua
draw.box(x, y, w, h, color, rounding, style)
```

| Parameter  | Type   | Required | Description                                          |
| ---------- | ------ | -------- | ---------------------------------------------------- |
| `x, y`     | number | yes      | Top-left corner of the box                           |
| `w, h`     | number | yes      | Width and height in pixels                           |
| `color`    | table  | yes      | `{r, g, b, a}`                                       |
| `rounding` | number | no       | Corner rounding. Default: `0`                        |
| `style`    | number | no       | `0` = full outline, `1` = corners only. Default: `0` |

```lua
local b = p:get_bounds()
if b.valid then
    draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
    draw.box(b.x, b.y, b.w, b.h, {0, 1, 0, 1}, 0, 1)  -- corner style
end
```

***

#### draw\.corner\_box

```lua
draw.corner_box(x, y, w, h, color)
```

| Parameter | Type   | Required | Description                |
| --------- | ------ | -------- | -------------------------- |
| `x, y`    | number | yes      | Top-left corner of the box |
| `w, h`    | number | yes      | Width and height in pixels |
| `color`   | table  | yes      | `{r, g, b, a}`             |

Draws only the four corner segments of a bounding box.

```lua
draw.corner_box(b.x, b.y, b.w, b.h, {0, 1, 1, 1})
```

***

#### draw\.health\_bar

```lua
draw.health_bar(x, y, height, health, max_health)
```

| Parameter    | Type   | Required | Description                            |
| ------------ | ------ | -------- | -------------------------------------- |
| `x, y`       | number | yes      | Top-left position of the bar           |
| `height`     | number | yes      | Bar height in pixels (matches box `h`) |
| `health`     | number | yes      | Current health value                   |
| `max_health` | number | yes      | Maximum health value                   |

Draws a vertical health bar that transitions from green (full) to red (empty).

```lua
local b = p:get_bounds()
if b.valid then
    draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
    draw.health_bar(b.x - 5, b.y, b.h, p.health, p.max_health)
end
```

***

### Utility

#### draw\.world\_to\_screen

```lua
local sx, sy, visible = draw.world_to_screen(x, y, z)
```

| Parameter | Type   | Required | Description    |
| --------- | ------ | -------- | -------------- |
| `x, y, z` | number | yes      | World position |

Returns the 2D screen position and a boolean indicating whether the point is within the screen bounds. Returns `0, 0, false` if the point is behind the camera.

```lua
local sx, sy, vis = draw.world_to_screen(p.position.x, p.position.y, p.position.z)
if vis then
    draw.circle_filled(sx, sy, 4, {1, 1, 0, 1})
end
```

***

#### draw\.get\_screen\_size

```lua
local w, h = draw.get_screen_size()
```

Returns the current render resolution in pixels.

```lua
local sw, sh = draw.get_screen_size()
local cx, cy = sw * 0.5, sh * 0.5
```

***

#### draw\.window

```lua
draw.window(x, y, id, title, items)
```

| Parameter | Type   | Required | Description                                        |
| --------- | ------ | -------- | -------------------------------------------------- |
| `x, y`    | number | yes      | Top-left position of the panel                     |
| `id`      | string | yes      | Unique identifier (used for position persistence)  |
| `title`   | string | yes      | Panel header text                                  |
| `items`   | table  | yes      | Array of `{label, value}` pairs to display as rows |

Draws a floating info panel with a header and labelled rows.

```lua
draw.window(10, 10, "player_info", "Target", {
    { "Name",   p.name          },
    { "Health", p.health        },
    { "Dist",   p:distance_to() },
})
```

***

### Polygons

#### draw\.poly

```lua
draw.poly(points, color, thickness)
```

| Parameter   | Type   | Required | Description                              |
| ----------- | ------ | -------- | ---------------------------------------- |
| `points`    | table  | yes      | Array of `{x, y}` screen-space positions |
| `color`     | table  | yes      | `{r, g, b, a}`                           |
| `thickness` | number | no       | Line thickness. Default: `1.5`           |

Draws an open polyline through the given points (last point is not connected back to first).

```lua
draw.poly({{100,100},{200,150},{300,100}}, {1,1,0,1})
```

***

#### draw\.poly\_closed

```lua
draw.poly_closed(points, color, thickness)
```

Same as `draw.poly` but connects the last point back to the first to close the shape.

```lua
draw.poly_closed({{100,100},{200,50},{300,100},{200,150}}, {0,1,1,1})
```

***

#### draw\.poly\_filled

```lua
draw.poly_filled(points, color)
```

| Parameter | Type  | Required | Description                            |
| --------- | ----- | -------- | -------------------------------------- |
| `points`  | table | yes      | Array of `{x, y}` in convex hull order |
| `color`   | table | yes      | `{r, g, b, a}`                         |

Draws a filled convex polygon. Points must be in convex order — run them through `draw.compute_hull` first if they are unordered.

```lua
local hull = draw.compute_hull(my_points)
draw.poly_filled(hull, {1, 0.5, 0, 0.4})
```

***

#### draw\.compute\_hull

```lua
local ordered = draw.compute_hull(points)
```

| Parameter | Type  | Required | Description                    |
| --------- | ----- | -------- | ------------------------------ |
| `points`  | table | yes      | Array of `{x, y}` in any order |

Returns a new table of points sorted into convex hull order, ready for `draw.poly_filled`.

```lua
local raw    = { {300,200},{100,400},{200,100},{400,350} }
local hull   = draw.compute_hull(raw)
draw.poly_filled(hull, {0, 0.8, 1, 0.3})
```

***

### Chams

#### draw\.chams\_player

```lua
draw.chams_player(player, color, color2, style)
```

| Parameter | Type   | Required | Description                                           |
| --------- | ------ | -------- | ----------------------------------------------------- |
| `player`  | entity | yes      | Player object from `entity.get_players()`             |
| `color`   | table  | yes      | Primary colour `{r, g, b, a}`                         |
| `color2`  | table  | no       | Secondary / outline colour. Default: same as `color`  |
| `style`   | number | no       | `0` = filled, `1` = outline, `2` = glow. Default: `0` |

Renders a full per-body-part chams overlay on the player character.

```lua
for _, p in ipairs(entity.get_players()) do
    if not p.is_local then
        draw.chams_player(p, {0, 1, 0.4, 0.8})
        draw.chams_player(p, {0, 1, 0.4, 0.8}, {0, 0.4, 1, 0.8}, 2)
    end
end
```

***

#### draw\.get\_player\_hulls

```lua
local hulls = draw.get_player_hulls(player)
```

| Parameter | Type   | Required | Description                               |
| --------- | ------ | -------- | ----------------------------------------- |
| `player`  | entity | yes      | Player object from `entity.get_players()` |

Returns a table of polygon tables — one per body part — each already in convex hull order and ready for `draw.poly_filled`. Use this when you need full control over per-part colours or styles.

```lua
local hulls = draw.get_player_hulls(p)
for _, hull in ipairs(hulls) do
    draw.poly_filled(hull, {1, 0, 0, 0.5})
    draw.poly_closed(hull, {1, 1, 1, 0.9}, 1.0)
end
```

***

### Images

#### draw\.load\_image

```lua
local handle = draw.load_image(url)
```

| Parameter | Type   | Required | Description                             |
| --------- | ------ | -------- | --------------------------------------- |
| `url`     | string | yes      | HTTP/HTTPS URL of the image to download |

Returns an integer `handle` immediately. The download runs on a background thread — use `draw.image_loaded` to check readiness before drawing. Calling this with the same URL more than once returns the same handle without starting a second download. Safe to call every frame.

**Supported URL formats:**

| Format              | Example                                 |
| ------------------- | --------------------------------------- |
| Direct HTTP/HTTPS   | `https://example.com/icon.png`          |
| Roblox asset URL    | `http://www.roblox.com/asset/?id=12345` |
| rbxassetid protocol | `rbxassetid://10774541653`              |

Roblox asset and `rbxassetid://` URLs are resolved automatically through the public Thumbnails API before downloading — no manual rewriting needed.

```lua
local h = draw.load_image("https://raw.githubusercontent.com/user/repo/main/icon.png")
local h = draw.load_image("rbxassetid://10774541653")
```

***

#### draw\.image

```lua
draw.image(handle, x, y, w, h)
draw.image(handle, x, y, w, h, color)
```

| Parameter | Type   | Required | Description                                       |
| --------- | ------ | -------- | ------------------------------------------------- |
| `handle`  | number | yes      | Handle returned by `draw.load_image`              |
| `x, y`    | number | yes      | Top-left position in screen pixels                |
| `w, h`    | number | yes      | Draw width and height in pixels                   |
| `color`   | table  | no       | RGBA tint `{r, g, b, a}`. Default: `{1, 1, 1, 1}` |

Draws the image scaled to `w × h`. Only call after `draw.image_loaded` returns `true`.

```lua
if draw.image_loaded(handle) then
    draw.image(handle, 10, 10, 64, 64)
    draw.image(handle, 10, 10, 64, 64, {1, 1, 1, 0.5})  -- 50% transparent
end
```

***

#### draw\.image\_loaded

```lua
local ready = draw.image_loaded(handle)
```

Returns `true` once the download has completed and the texture has been uploaded to the GPU. Returns `false` while still downloading or if the handle is invalid.

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `handle`  | number | yes      | Handle returned by `draw.load_image` |

***

#### draw\.image\_failed

```lua
local failed = draw.image_failed(handle)
```

Returns `true` if the download or image decode failed. A failed handle will never become loaded. Call `draw.free_image` to clear it from the cache so a new download can be attempted with the same URL.

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `handle`  | number | yes      | Handle returned by `draw.load_image` |

***

#### draw\.image\_size

```lua
local w, h = draw.image_size(handle)
```

Returns the native pixel dimensions of the loaded image. Returns `0, 0` if not yet loaded.

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `handle`  | number | yes      | Handle returned by `draw.load_image` |

```lua
local iw, ih = draw.image_size(handle)
-- maintain aspect ratio at a fixed display width of 64px
local dw = 64
local dh = math.floor(dw * ih / iw)
draw.image(handle, x, y, dw, dh)
```

***

#### draw\.free\_image

```lua
draw.free_image(handle)
```

Releases the GPU texture and removes the URL from the cache. After this call, `draw.load_image` with the same URL starts a fresh download.

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `handle`  | number | yes      | Handle returned by `draw.load_image` |

```lua
if draw.image_failed(handle) then
    draw.free_image(handle)
    handle = nil
end
```

***

### Examples

**Full ESP loop — box, health bar, name, bones:**

```lua
function on_frame()
    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end

        local b = p:get_bounds()
        if not b.valid then goto continue end

        draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
        draw.health_bar(b.x - 6, b.y, b.h, p.health, p.max_health)

        local tw, th = draw.get_text_size(p.name)
        draw.text(b.x + (b.w - tw) * 0.5, b.y - th - 2, p.name, {1, 1, 1, 1})

        local sx, sy, vis = p:get_bone_screen("Head")
        if vis then draw.circle_filled(sx, sy, 4, {1, 1, 0, 1}) end

        ::continue::
    end
end
```

**Skeleton ESP:**

```lua
function on_frame()
    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local bones = p:get_bones_screen()

        local connections = {
            {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
            {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
            {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
            {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        }

        for _, conn in ipairs(connections) do
            local a, b = bones[conn[1]], bones[conn[2]]
            if a and b then
                draw.line(a[1], a[2], b[1], b[2], {1, 1, 1, 0.9}, 1.5)
            end
        end

        ::continue::
    end
end
```

**Chams with custom per-part colouring:**

```lua
function on_frame()
    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local vis   = raycast.is_player_visible(p.character.address)
        local color = vis and {0, 1, 0.4, 0.8} or {1, 0.2, 0.2, 0.8}

        draw.chams_player(p, color, {1, 1, 1, 0.3}, 1)

        ::continue::
    end
end
```

**Image loading — basic pattern:**

```lua
local handle = nil

function on_frame()
    if handle == nil then
        handle = draw.load_image("https://example.com/icon.png")
    end

    if draw.image_failed(handle) then
        draw.text(10, 10, "load failed", {1, 0, 0, 1})
        draw.free_image(handle)
        handle = nil
        return
    end

    if not draw.image_loaded(handle) then
        draw.text(10, 10, "loading...", {1, 1, 0, 1})
        return
    end

    draw.image(handle, 10, 10, 64, 64)
end
```

**Image drawn at a player's world position:**

```lua
local icon = draw.load_image("rbxassetid://10774541653")

function on_frame()
    if not draw.image_loaded(icon) then return end

    local iw, ih = draw.image_size(icon)

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local sx, sy, vis = utility.world_to_screen(p.position.x, p.position.y + 3, p.position.z)
        if not vis then goto continue end

        local dw = 48
        local dh = math.floor(dw * ih / iw)
        draw.rect_filled(sx - dw * 0.5 - 2, sy - dh - 2, dw + 4, dh + 4, {0, 0, 0, 0.5})
        draw.image(icon, sx - dw * 0.5, sy - dh, dw, dh)

        ::continue::
    end
end
```

**Slot UI — multiple images by ID:**

```lua
local BASE  = "https://raw.githubusercontent.com/user/repo/main/icons/"
local cache = {}

local function get_image(id)
    if not cache[id] then
        cache[id] = draw.load_image(BASE .. id .. ".png")
    end
    return cache[id]
end

function on_frame()
    local ids = { "sword", "shield", "potion" }
    for i, id in ipairs(ids) do
        local h = get_image(id)
        local x = (i - 1) * 70 + 10
        draw.rect_filled(x, 10, 64, 64, {0.27, 0.27, 0.27, 0.75}, 6)
        if draw.image_loaded(h) then
            draw.image(h, x, 10, 64, 64)
        end
    end
end
```

***

### Notes

* All draw calls must be inside `on_frame`. Drawing outside of `on_frame` has no effect.
* `draw.poly_filled` requires points in convex hull order — run unordered points through `draw.compute_hull` first.
* `draw.load_image` deduplicates by URL — calling it every frame with the same URL is safe and returns the same handle.
* Texture uploads happen on the render thread; `draw.image_loaded` becomes `true` on the first frame after a download completes.
* Supported image formats: PNG, JPEG, BMP, TGA.
* `rbxassetid://` and `roblox.com/asset/?id=` URLs are resolved automatically through the Roblox Thumbnails API.

***

### API Reference

| Function                              | Returns              | Description                         |
| ------------------------------------- | -------------------- | ----------------------------------- |
| `draw.line(x1,y1,x2,y2,col,thick)`    | —                    | Line between two points             |
| `draw.rect(x,y,w,h,col,round,thick)`  | —                    | Outlined rectangle                  |
| `draw.rect_filled(x,y,w,h,col,round)` | —                    | Filled rectangle                    |
| `draw.circle(x,y,r,col,seg,thick)`    | —                    | Outlined circle                     |
| `draw.circle_filled(x,y,r,col,seg)`   | —                    | Filled circle                       |
| `draw.text(x,y,text,col,size)`        | —                    | Text with black outline             |
| `draw.get_text_size(text,size)`       | number, number       | Pixel width and height              |
| `draw.box(x,y,w,h,col,round,style)`   | —                    | ESP bounding box                    |
| `draw.corner_box(x,y,w,h,col)`        | —                    | Corner-only ESP box                 |
| `draw.health_bar(x,y,h,hp,max)`       | —                    | Vertical health bar                 |
| `draw.world_to_screen(x,y,z)`         | number, number, bool | 3D to 2D projection                 |
| `draw.get_screen_size()`              | number, number       | Render resolution                   |
| `draw.window(x,y,id,title,items)`     | —                    | Floating info panel                 |
| `draw.poly(pts,col,thick)`            | —                    | Open polyline                       |
| `draw.poly_closed(pts,col,thick)`     | —                    | Closed polyline                     |
| `draw.poly_filled(pts,col)`           | —                    | Filled convex polygon               |
| `draw.compute_hull(pts)`              | table                | Convex hull from unordered points   |
| `draw.chams_player(p,col,col2,style)` | —                    | Full player chams                   |
| `draw.get_player_hulls(p)`            | table                | Raw per-part hull tables            |
| `draw.load_image(url)`                | number               | Start async download, return handle |
| `draw.image(handle,x,y,w,h,col)`      | —                    | Draw loaded image                   |
| `draw.image_loaded(handle)`           | boolean              | True once ready to draw             |
| `draw.image_failed(handle)`           | boolean              | True if download or decode failed   |
| `draw.image_size(handle)`             | number, number       | Native image dimensions             |
| `draw.free_image(handle)`             | —                    | Release texture and clear cache     |

# Utility API

## Utility API

General-purpose utilities for screen projection, frame timing, cursor position, FPS, key events, input simulation, and HTTP.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

### utility.world\_to\_screen

```lua
local sx, sy, on_screen = utility.world_to_screen(x, y, z)
-- also accepts a Vector3
local sx, sy, on_screen = utility.world_to_screen(vec3)
```

Projects a 3D world position to 2D screen coordinates using the current view matrix. Unlike `draw.world_to_screen`, this version returns `on_screen = true` only when the projected point falls inside the screen bounds — not just in front of the camera.

```lua
local sx, sy, on_screen = utility.world_to_screen(100, 5, 200)
if on_screen then
    draw.circle_filled(sx, sy, 4, {0, 1, 0, 1})
end
```

```lua
local v = Vector3.new(100, 5, 200)
local sx, sy, on_screen = utility.world_to_screen(v)
```

***

### utility.get\_screen\_size

```lua
local w, h = utility.get_screen_size()
```

Returns the current render resolution in pixels.

```lua
local w, h = utility.get_screen_size()
local cx, cy = w / 2, h / 2
```

***

### utility.get\_mouse\_pos

```lua
local mx, my = utility.get_mouse_pos()
```

Returns the current cursor position in screen space using `GetCursorPos`.

```lua
function on_frame()
    local mx, my = utility.get_mouse_pos()
    draw.text(mx + 12, my, "cursor", {1, 1, 1, 1})
end
```

***

### utility.get\_delta\_time

```lua
local dt = utility.get_delta_time()
```

Returns seconds elapsed since the last frame, clamped to \[0.0001, 0.1]. Use this to make any movement or animation frame-rate independent:

```lua
local x = 0
local speed = 200  -- pixels per second

function on_frame()
    local dt = utility.get_delta_time()
    x = x + speed * dt

    local w, h = utility.get_screen_size()
    if x > w then x = 0 end

    draw.circle_filled(x, 100, 5, {0, 1, 1, 1})
end
```

***

### utility.get\_time

```lua
local seconds = utility.get_time()
```

Returns seconds elapsed since the engine started as a high-precision float. Uses `steady_clock` so the value is monotonic and never jumps. Useful for timed logic, cooldowns, and animation timing without dealing with millisecond conversions.

```lua
local last_check = 0

function on_frame()
    local now = utility.get_time()
    if now - last_check < 1.0 then return end
    last_check = now

    print("one second passed")
end
```

***

### utility.get\_tick\_count

```lua
local ms = utility.get_tick_count()
```

Returns `GetTickCount64()` — milliseconds elapsed since system boot. Useful for cooldowns and timed logic.

```lua
local last_action = 0
local cooldown_ms = 500

function on_frame()
    local now = utility.get_tick_count()

    if input.is_key_down(0x46) then  -- F key
        if now - last_action > cooldown_ms then
            print("action fired")
            last_action = now
        end
    end
end
```

***

### utility.get\_fps

```lua
local fps = utility.get_fps()
```

Returns a smoothed FPS value averaged over the last 60 frames.

```lua
function on_frame()
    local fps = utility.get_fps()
    draw.text(10, 10, "FPS: " .. math.floor(fps), {0.6, 1, 0.6, 1})
end
```

***

### utility.is\_valid

```lua
local valid = utility.is_valid(instance)
```

Returns `true` if the given instance userdata still points to a valid Roblox object in memory. Checks the class descriptor, name pointer, and parent to confirm the object has not been destroyed or garbage collected. Use this before accessing properties on instances that may have been removed from the game tree.

```lua
local char = player.character
if utility.is_valid(char) then
    local pos = char.Position
    print(pos.x, pos.y, pos.z)
end
```

***

### utility.on\_key

```lua
local id = utility.on_key(vk_code, mode, callback)
```

Registers a key binding that fires automatically every frame — no manual `input.is_key_down` polling needed. Returns a numeric `id` you can pass to `utility.remove_key` to unregister later.

**Modes:**

```lua
-- Toggle an ESP feature on/off with F
local esp_on = false
local esp_id = utility.on_key(0x46, "toggle", function(state)
    esp_on = state
    print("ESP: " .. (state and "ON" or "OFF"))
end)

-- React to hold/release of G
utility.on_key(0x47, "hold", function(state)
    if state then
        print("G held — activating")
    else
        print("G released")
    end
end)

-- Draw an indicator every frame while RMB is held
utility.on_key(0x02, "always", function(state)
    if state then
        draw.text(10, 10, "ADS ACTIVE", {0, 1, 0, 1}, 14)
    end
end)
```

***

### utility.remove\_key

```lua
utility.remove_key(id)
```

Unregisters one binding by the `id` returned from `utility.on_key`.

```lua
local my_id = utility.on_key(0x46, "toggle", function(state) end)
-- later...
utility.remove_key(my_id)
```

***

### utility.clear\_keys

```lua
utility.clear_keys()
```

Removes all registered key bindings at once.

***

### utility.is\_key\_toggled

```lua
local state = utility.is_key_toggled(id)
```

Returns the current toggle state (`true`/`false`) for a `"toggle"` mode binding. Returns `false` for other modes or an unknown id.

```lua
local id = utility.on_key(0x46, "toggle", function(state) end)

function on_frame()
    if utility.is_key_toggled(id) then
        draw.text(10, 10, "FEATURE ON", {0, 1, 0, 1}, 14)
    end
end
```

***

> **Important:** All input simulation functions send real OS-level input via `SendInput`. While the menu is open it captures input focus, so simulated clicks and key presses will be absorbed by the overlay instead of reaching the game. Close the menu before using these functions. In practice this means input simulation should run inside `on_frame` guarded by a toggle key or condition, not as a one-shot at script load time.

### utility.mouse\_click

```lua
utility.mouse_click(button?, x?, y?)
```

Simulates a full mouse click (down + up) via `SendInput`. Sends real input events that the game receives as genuine clicks.

* `button` — `"left"` (default), `"right"`, or `"middle"`
* `x, y` — optional screen coordinates to move the cursor to before clicking

```lua
-- left click at current cursor position
utility.mouse_click()

-- right click at a specific screen position
utility.mouse_click("right", 500, 300)

-- middle click
utility.mouse_click("middle")
```

***

### utility.mouse\_move

```lua
utility.mouse_move(x, y, absolute?)
```

Moves the mouse cursor via `SendInput`. By default the movement is relative (pixels from current position). Pass `true` as the third argument for absolute screen coordinates.

```lua
-- move 10 pixels right, 5 pixels down from current position
utility.mouse_move(10, 5)

-- move cursor to absolute screen position
utility.mouse_move(960, 540, true)
```

***

### utility.mouse\_scroll

```lua
utility.mouse_scroll(amount)
```

Simulates a mouse scroll wheel event. Positive values scroll up, negative values scroll down. One unit equals one "click" of the scroll wheel.

```lua
-- scroll up 3 clicks
utility.mouse_scroll(3)

-- scroll down 1 click
utility.mouse_scroll(-1)
```

***

### utility.key\_press

```lua
utility.key_press(vk_code, hold_ms?)
```

Simulates a full key press — sends key down, holds for `hold_ms` milliseconds (default `30`, about 2 frames at 60fps), then sends key up. The overlay stays responsive during the hold. Uses Windows virtual key codes.

```lua
-- press the spacebar (held for 30ms by default)
utility.key_press(0x20)

-- press W and hold for 200ms before releasing
utility.key_press(0x57, 200)
```

***

### utility.key\_down

```lua
utility.key_down(vk_code)
```

Sends a key down event only. The key stays held until you call `utility.key_up` with the same key code.

```lua
-- hold W down
utility.key_down(0x57)
-- ... later ...
utility.key_up(0x57)
```

***

### utility.key\_up

```lua
utility.key_up(vk_code)
```

Sends a key up event only. Use after `utility.key_down` to release a held key.

***

### utility.type\_string

```lua
utility.type_string(text, delay_ms?)
```

Types a string character by character using unicode input events. Works with any character including special symbols and non-ASCII text. Each character sends a down + up event with a small delay between characters so the target application registers each one.

* `delay_ms` — milliseconds between each character (default `5`). Set higher if characters are being dropped.

```lua
-- type into a chat box or text field
utility.type_string("hello world")

-- slower typing for applications that need more time
utility.type_string("gg ez", 15)
```

***

### utility.http\_get

```lua
local body, status = utility.http_get(url)
-- on failure:
-- body == nil, status == error string
```

Performs an HTTP/HTTPS GET and returns the response body as a string plus the HTTP status code. The UI stays responsive during the request — the Lua mutex is released while the network call is in progress.

```lua
local body, status = utility.http_get("https://pastebin.com/raw/AbCdEfGh")
if body and status == 200 then
    local fn, err = loadstring(body)
    if fn then fn() else print("compile error: " .. err) end
else
    print("fetch failed: " .. tostring(status))
end
```

***

### utility.load\_url

```lua
local ok, err = utility.load_url(url)
```

Fetches Lua source from a URL and executes it in the current state. Equivalent to `loadstring(http_get(url))()` with full error handling. Globals and functions defined in the remote script are immediately available after this returns. Returns `true` on success, or `false, error_message` on network failure, non-200 status, compile error, or runtime error.

```lua
-- One-liner — load and run a remote script
utility.load_url("https://pastebin.com/raw/AbCdEfGh")

-- With error handling
local ok, err = utility.load_url("https://pastebin.com/raw/AbCdEfGh")
if not ok then
    print("load_url failed: " .. tostring(err))
end
```

***

### Examples

HUD overlay — delta time animation + FPS counter:

```lua
local angle = 0

function on_frame()
    local dt  = utility.get_delta_time()
    local fps = utility.get_fps()
    local w, h = utility.get_screen_size()

    angle = angle + dt * 90
    if angle > 360 then angle = angle - 360 end

    local r = 40
    local cx, cy = 60, h - 60
    local rad = math.rad(angle)
    local px = cx + math.cos(rad) * r
    local py = cy + math.sin(rad) * r

    draw.circle(cx, cy, r, {1, 1, 1, 0.2})
    draw.circle_filled(px, py, 5, {0, 1, 1, 1})
    draw.text(10, 10, "FPS: " .. math.floor(fps), {0.6, 1, 0.6, 1})
end
```

Distance-based ESP with world\_to\_screen:

```lua
function on_frame()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local me = entity.get_local_player()
        if not me then goto continue end

        local dx = p.position.x - me.position.x
        local dy = p.position.y - me.position.y
        local dz = p.position.z - me.position.z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

        if dist > 500 then goto continue end

        local sx, sy, on_screen = utility.world_to_screen(
            p.head_position.x,
            p.head_position.y,
            p.head_position.z
        )
        if on_screen then
            local label = p.name .. " [" .. math.floor(dist) .. "m]"
            draw.text(sx, sy - 16, label, {1, 1, 1, 1})
        end

        ::continue::
    end
end
```

Toggle ESP with F key:

```lua
local esp_on = false

utility.on_key(0x46, "toggle", function(state)
    esp_on = state
    print("ESP: " .. (state and "ON" or "OFF"))
end)

function on_frame()
    if not esp_on then return end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local b = p:get_bounds()
        if b.valid then
            draw.box(b.x, b.y, b.w, b.h, {1, 1, 1, 1})
        end
        ::continue::
    end
end
```

Auto-jump with input simulation — toggle with H key, only runs while menu is closed:

```lua
local jumping = false

utility.on_key(0x48, "toggle", function(state)
    jumping = state
    print("Auto-jump: " .. (state and "ON" or "OFF"))
end)

function on_frame()
    if not jumping then return end

    local me = entity.get_local_player()
    if not me or not me.is_alive then return end

    local now = utility.get_time()
    if not _last_jump or now - _last_jump > 2.0 then
        utility.key_press(0x20)
        _last_jump = now
    end
end
```

Automated typing into chat — triggered by pressing F9:

```lua
utility.on_key(0x78, "hold", function(state)
    if not state then return end

    -- press / to open chat, hold for 100ms so the chat box opens
    utility.key_press(0xBF, 100)

    -- type the message with 10ms between each character
    utility.type_string("gg", 10)

    -- press Enter to send, hold briefly so it registers
    utility.key_press(0x0D, 50)
end)
```

Hold W to walk forward while X is held:

```lua
utility.on_key(0x58, "hold", function(state)
    if state then
        utility.key_down(0x57)   -- hold W
    else
        utility.key_up(0x57)     -- release W
    end
end)
```

Load a remote script on startup:

```lua
local ok, err = utility.load_url("https://pastebin.com/raw/AbCdEfGh")
if not ok then print("load_url failed: " .. tostring(err)) end
```

***

### API Reference

| Function                            | Description                               |
| ----------------------------------- | ----------------------------------------- |
| `utility.world_to_screen(x, y, z)`  | Project world position to screen          |
| `utility.get_screen_size()`         | Get render resolution                     |
| `utility.get_mouse_pos()`           | Get cursor position                       |
| `utility.get_delta_time()`          | Seconds since last frame                  |
| `utility.get_time()`                | Seconds since engine start                |
| `utility.get_tick_count()`          | System uptime in milliseconds             |
| `utility.get_fps()`                 | Smoothed FPS value                        |
| `utility.is_valid(instance)`        | Check if instance is still valid          |
| `utility.on_key(vk, mode, fn)`      | Register a key binding                    |
| `utility.remove_key(id)`            | Remove a key binding                      |
| `utility.clear_keys()`              | Remove all key bindings                   |
| `utility.is_key_toggled(id)`        | Get toggle state of a binding             |
| `utility.mouse_click(btn?, x?, y?)` | Simulate a mouse click                    |
| `utility.mouse_move(x, y, abs?)`    | Move the cursor                           |
| `utility.mouse_scroll(amount)`      | Simulate scroll wheel                     |
| `utility.key_press(vk, ms?)`        | Press and release a key (instant or held) |
| `utility.key_down(vk)`              | Hold a key down                           |
| `utility.key_up(vk)`                | Release a held key                        |
| `utility.type_string(text, ms?)`    | Type a string character by character      |
| `utility.http_get(url)`             | HTTP GET request                          |
| `utility.load_url(url)`             | Fetch and execute remote Lua              |

# Raycast API

The raycast API gives scripts access to the cheat's built-in visibility system. A background worker thread maintains a spatial hash of world obstacles and per-player visibility results — the Lua API just reads from that cache with no render-thread cost.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three.

***

### How it works

The raycast system runs on a dedicated worker thread:

* **Obstacles** are rebuilt from the workspace instance tree every \~2 seconds into a spatial hash grid (50 unit cells).
* **Player visibility** is rechecked every \~16ms against those obstacles, testing head, upper torso, lower torso, and torso for each enemy player.
* Lua reads the already-computed results — there is no per-frame cost beyond a hash lookup.

`raycast.is_ready()` returns false while the first obstacle pass is still running. All functions fail open (return `true`) if the cache is not ready, so your ESP will still draw during startup.

***

### raycast.is\_ready

```lua
local ready = raycast.is_ready()
```

Returns `true` once the obstacle cache has completed its first build. Use this as a guard if you want to suppress ESP until visibility data is available.

```lua
function on_frame()
    if not raycast.is_ready() then
        draw.text(10, 10, "building raycast cache...", {1, 1, 0, 1})
        return
    end
    -- normal ESP below
end
```

***

### raycast.is\_player\_visible

```lua
local visible = raycast.is_player_visible(character_address)
```

Returns `true` if any key body part of the player is visible from the camera position.

Reads directly from the double-buffered visibility cache — no memory reads, no ray tests. The result is updated every \~16ms by the worker thread.

**Parameter:** the character's memory address as a number. Obtain it from `p.character.address` on a player object from `entity.get_players()`.

Returns `true` if the cache is not yet ready (fail open).

```lua
function on_frame()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local b = p:get_bounds()
        if not b.valid then goto continue end

        local char = p.character
        if not utility.is_valid(char) then goto continue end

        local visible = raycast.is_player_visible(char.address)

        -- white box when visible, dark grey when occluded
        local color = visible and {1, 1, 1, 1} or {0.4, 0.4, 0.4, 0.6}
        draw.box(b.x, b.y, b.w, b.h, color)

        ::continue::
    end
end
```

***

### raycast.is\_visible

```lua
-- Six numbers
local visible = raycast.is_visible(x1, y1, z1, x2, y2, z2)

-- Two Vector3 objects
local visible = raycast.is_visible(vec3_from, vec3_to)
```

Fires a ray between two world positions and returns `true` if no obstacle intersects it.

Uses the cached spatial hash to limit OBB tests to only the cells along the ray — typically a small fraction of the total obstacle count. More expensive than `is_player_visible` since it runs the test live, but still much cheaper than a full scene traverse.

Returns `true` if the cache is not yet ready.

```lua
function on_frame()
    local cam_pos = camera.get_position()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local head_pos = p.head_position
        if not head_pos then goto continue end

        local visible = raycast.is_visible(
            cam_pos.x, cam_pos.y, cam_pos.z,
            head_pos.x, head_pos.y, head_pos.z
        )

        local hx, hy, hv = p:get_bone_screen("Head")
        if hv then
            local color = visible and {0, 1, 0, 1} or {1, 0, 0, 1}
            draw.circle_filled(hx, hy, 5, color)
        end

        ::continue::
    end
end
```

**Vector3 form:**

```lua
local from = camera.get_position()
local to   = p.head_position
if from and to then
    local visible = raycast.is_visible(from, to)
end
```

***

### Examples

**Visible-only ESP — skip drawing occluded players entirely:**

```lua
function on_frame()
    if not raycast.is_ready() then return end

    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local char = p.character
        if not utility.is_valid(char) then goto continue end

        -- skip players behind walls entirely
        if not raycast.is_player_visible(char.address) then goto continue end

        local b = p:get_bounds()
        if not b.valid then goto continue end

        draw.box(b.x, b.y, b.w, b.h, {0, 1, 0.5, 1})
        draw.health_bar(b.x - 5, b.y, b.h, p.health, p.max_health)

        local tw, th = draw.get_text_size(p.name, 14)
        draw.text(b.x + b.w / 2 - tw / 2, b.y - th - 2, p.name, {1, 1, 1, 1})

        ::continue::
    end
end
```

**Visible/occluded color coding with info window:**

```lua
function on_frame()
    local players = entity.get_players()

    for _, p in ipairs(players) do
        if p.is_local or not p.is_alive then goto continue end

        local char = p.character
        if not utility.is_valid(char) then goto continue end

        local visible = raycast.is_player_visible(char.address)

        local b = p:get_bounds()
        if not b.valid then goto continue end

        local box_color = visible and {0, 1, 0.4, 1} or {0.5, 0.5, 0.5, 0.5}
        draw.box(b.x, b.y, b.w, b.h, box_color)

        if visible then
            draw.window(b.x + b.w + 4, b.y, "vis_" .. p.user_id, p.name, {
                "HP: " .. math.floor(p.health),
                "Visible: yes",
            })
        end

        ::continue::
    end
end
```

**Custom raycast from camera to arbitrary world point:**

```lua
function on_frame()
    local cam = camera.get_position()

    -- check if a fixed world coordinate is visible from the camera
    local target_x, target_y, target_z = 100, 5, 200

    if raycast.is_visible(cam.x, cam.y, cam.z, target_x, target_y, target_z) then
        local sx, sy, on_screen = utility.world_to_screen(target_x, target_y, target_z)
        if on_screen then
            draw.circle_filled(sx, sy, 6, {0, 1, 0, 1})
            draw.text(sx + 8, sy, "visible", {0, 1, 0, 1})
        end
    end
end
```

***

### Performance notes

* `raycast.is_player_visible` is essentially free — it's a single table scan of the visibility buffer which contains at most one entry per player.
* `raycast.is_visible` runs a live ray test but uses the spatial hash, so it only tests the OBBs in cells the ray actually passes through. Calling it once per player per frame is fine. Calling it dozens of times per frame for many players may add up — prefer `is_player_visible` for per-player visibility checks.
* The obstacle cache rebuilds every \~2 seconds. Freshly spawned parts (doors opening, destructible walls) will not be reflected until the next rebuild.
* Transparent parts (transparency >= 1.0) are excluded from the obstacle list — they won't block visibility.

***

### API Reference

| Function                                 | Returns | Description                               |
| ---------------------------------------- | ------- | ----------------------------------------- |
| `raycast.is_ready()`                     | boolean | True once the obstacle cache is built     |
| `raycast.is_player_visible(char_addr)`   | boolean | Cached visibility check for a player      |
| `raycast.is_visible(x1,y1,z1, x2,y2,z2)` | boolean | Live ray test between two world positions |
| `raycast.is_visible(vec3_from, vec3_to)` | boolean | Same, accepts Vector3 objects             |

# FFlag API

The fflag API gives scripts direct read and write access to Roblox's Fast Flag (FFlag) system. A background thread scans the game's memory for all registered FFlags and caches their names, addresses, and values. The Lua API reads and writes through that cache with no render-thread cost.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three.

***

### How it works

The fflag system runs on a dedicated worker thread:

* **FFlags** are discovered by pattern scanning the Roblox binary for flag registration stubs. Each stub contains a pointer to the flag's DWORD value and a string pointer to its name.
* **Deduplication** removes flags that appear at multiple addresses, preferring the one inside the main module over heap copies.
* **A watch loop** polls flag values every 100ms and publishes updated snapshots via a lock-free shared pointer, so Lua reads are always safe and never block.

`fflag.is_scanned()` returns `false` while the initial scan is still running. All read functions return `nil` or empty tables until the scan completes.

***

### fflag.is\_scanned

```lua
local ready = fflag.is_scanned()
```

Returns `true` once the fflag cache has completed its initial pattern scan. Use this as a guard before accessing flags.

```lua
function on_frame()
    if not fflag.is_scanned() then
        draw.text(10, 10, "scanning fflags...", {1, 1, 0, 1})
        return
    end
    draw.text(10, 10, "flags loaded: " .. fflag.get_count(), {0, 1, 0, 1})
end
```

***

### fflag.get\_count

```lua
local count = fflag.get_count()
```

Returns the total number of FFlags currently cached. Typically around 6000–7000 depending on the Roblox version.

***

### fflag.get\_value

```lua
local value = fflag.get_value(flag_name)
```

Returns the current integer value of a flag by its exact name, or `nil` if the flag was not found.

Parameter: the full flag name as a string. Names are case-sensitive and must match exactly as they appear in Roblox's internal registry.

Returns `nil` if the flag does not exist or the cache is not yet scanned.

```lua
local fps_cap = fflag.get_value("TaskSchedulerTargetFps")
if fps_cap then
    print("current fps cap: " .. fps_cap)
end
```

***

### fflag.set\_value

```lua
local success = fflag.set_value(flag_name, value)
```

Writes a new integer value to a flag. Returns `true` if the flag was found and written, `false` otherwise.

The write goes directly to the flag's memory address in the Roblox process. The change takes effect immediately.

```lua
-- unlock fps
fflag.set_value("TaskSchedulerTargetFps", 9999)

-- enable debug fps display
fflag.set_value("DebugDisplayFPS", 1)
```

***

### fflag.reset\_value

```lua
local success = fflag.reset_value(flag_name)
```

Resets a single flag to its original value (the value it had when first scanned). Returns `true` if the flag was found and reset, `false` otherwise.

```lua
fflag.set_value("TaskSchedulerTargetFps", 9999)
-- later...
fflag.reset_value("TaskSchedulerTargetFps")
```

***

### fflag.reset\_all

```lua
fflag.reset_all()
```

Resets all modified flags back to their original values. Takes no arguments and returns nothing. Useful for cleanup when unloading a script.

***

### fflag.find

```lua
local results = fflag.find(pattern)
```

Searches all cached flags for names containing the given substring. The search is case-insensitive. Returns a table of matching flags, each with the following fields:

* `name` — the full flag name (string)
* `value` — current integer value (number)
* `original` — the value when first scanned (number)
* `changed` — whether the value differs from the original (boolean)
* `index` — the flag's position in the cache (number)

```lua
local physics_flags = fflag.find("physics")
for _, flag in ipairs(physics_flags) do
    local status = flag.changed and " [MODIFIED]" or ""
    print(flag.name .. " = " .. flag.value .. status)
end
```

***

### fflag.get\_all

```lua
local all = fflag.get_all()
```

Returns a table containing every cached flag. Each entry has the same fields as `fflag.find` plus an `address` field containing the flag's memory address. This can return a large table (6000+ entries). Prefer `fflag.find()` for targeted lookups.

```lua
local all = fflag.get_all()
local modified = 0
for _, flag in ipairs(all) do
    if flag.changed then
        modified = modified + 1
        print(flag.name .. ": " .. flag.original .. " -> " .. flag.value)
    end
end
print("total modified: " .. modified)
```

***

### Examples

FPS unlocker — set the task scheduler target every frame in case the game resets it:

```lua
function on_frame()
    if not fflag.is_scanned() then return end

    local current = fflag.get_value("TaskSchedulerTargetFps")
    if current and current ~= 9999 then
        fflag.set_value("TaskSchedulerTargetFps", 9999)
        print("fps unlocked")
    end
end
```

Search and display flags on screen:

```lua
function on_frame()
    if not fflag.is_scanned() then return end

    local render_flags = fflag.find("render")
    local y = 30

    draw.text(10, 10, "Render Flags: " .. #render_flags, {1, 1, 1, 1})

    for i, flag in ipairs(render_flags) do
        if i > 15 then break end
        local color = flag.changed and {1, 0.5, 0, 1} or {0.7, 0.7, 0.7, 1}
        draw.text(10, y, flag.name .. " = " .. flag.value, color)
        y = y + 16
    end
end
```

Bulk modification with cleanup on script unload:

```lua
local modified_flags = {}

function apply_tweaks()
    local tweaks = {
        {"TaskSchedulerTargetFps", 9999},
        {"DebugDisplayFPS", 1},
    }

    for _, tweak in ipairs(tweaks) do
        local name, value = tweak[1], tweak[2]
        local old = fflag.get_value(name)
        if old then
            fflag.set_value(name, value)
            table.insert(modified_flags, name)
            print("set " .. name .. ": " .. old .. " -> " .. value)
        end
    end
end

function cleanup()
    for _, name in ipairs(modified_flags) do
        fflag.reset_value(name)
    end
    modified_flags = {}
    print("all tweaks reverted")
end

function on_frame()
    if not fflag.is_scanned() then return end
    if #modified_flags == 0 then
        apply_tweaks()
    end
end
```

Monitor all modified flags in real time:

```lua
local last_check = 0

function on_frame()
    if not fflag.is_scanned() then return end

    local now = utility.get_time()
    if now - last_check < 1.0 then return end
    last_check = now

    local all = fflag.get_all()
    local changed = {}
    for _, flag in ipairs(all) do
        if flag.changed then
            table.insert(changed, flag)
        end
    end

    if #changed > 0 then
        draw.text(10, 10, "Modified Flags: " .. #changed, {1, 0.5, 0, 1})
        local y = 30
        for _, flag in ipairs(changed) do
            draw.text(10, y, flag.name .. ": " .. flag.original .. " -> " .. flag.value, {1, 0.8, 0.3, 1})
            y = y + 16
        end
    end
end
```

***

### Performance notes

* All read functions (`get_value`, `find`, `get_all`) read from an atomic shared pointer snapshot. They never block the render thread or the fflag worker thread.
* `set_value` and `reset_value` perform a single memory write to the Roblox process per call. They are safe to call every frame but there is no benefit to doing so since the value persists until changed.
* The watch loop detects external changes to flag values every 100ms. If the game resets a flag you modified, you will see the change reflected in the next snapshot.
* Flag values are 32-bit integers (DWORD). Flags that appear as booleans in Roblox use `0` for false and `1` for true.
* The flag cache rebuilds when the game teleports to a new place. Modified values are not preserved across teleports.
* `get_all` returns a large table. Avoid calling it every frame. Use `find` for targeted lookups or cache results in a local variable.

***

### API Reference

| Function                       | Description                                 |
| ------------------------------ | ------------------------------------------- |
| `fflag.is_scanned()`           | Returns `true` when the flag cache is ready |
| `fflag.get_count()`            | Returns total number of cached flags        |
| `fflag.get_value(name)`        | Read a flag's current value by name         |
| `fflag.set_value(name, value)` | Write a new integer value to a flag         |
| `fflag.reset_value(name)`      | Reset a flag to its original value          |
| `fflag.reset_all()`            | Reset all flags to original values          |
| `fflag.find(pattern)`          | Case-insensitive substring search           |
| `fflag.get_all()`              | Get all flags as a table                    |

# Memory API

The memory API exposes direct process memory access, letting scripts read and write arbitrary values at any address. Combined with `instance.Address`, it unlocks every game property regardless of whether the engine exposes it natively.

> All examples use `snake_case`. Every function is also accessible in `camelCase` and `PascalCase` — the engine accepts all three. Pick one and stay consistent in your scripts.

***

#### memory.base

```lua
local base = memory.base
```

Returns the base address of the Roblox module as an integer. Use this as a starting point for pattern-relative offsets.

```lua
print("base: 0x" .. string.format("%X", memory.base))
```

***

#### memory.read

```lua
local value = memory.read(address, type)
```

| Parameter | Type   | Required | Description                                 |
| --------- | ------ | -------- | ------------------------------------------- |
| `address` | number | yes      | Absolute memory address to read from        |
| `type`    | string | yes      | Value type — see type reference table below |

Returns the value at `address` interpreted as `type`. Returns `0` / `false` on failure.

```lua
local hp = memory.read(humanoid_addr + 0x100, "float")
local flags = memory.read(obj_addr + 0x48, "uint32")
local ptr = memory.read(obj_addr + 0xA18, "ptr")
```

***

#### memory.write

```lua
local ok = memory.write(address, type, value)
```

| Parameter | Type   | Required | Description                                 |
| --------- | ------ | -------- | ------------------------------------------- |
| `address` | number | yes      | Absolute memory address to write to         |
| `type`    | string | yes      | Value type — see type reference table below |
| `value`   | any    | yes      | Value to write (must match the type)        |

Returns `true` on success, `false` on failure.

```lua
memory.write(humanoid_addr + 0x100, "float", 100.0)
memory.write(flags_addr, "uint8", 1)
```

***

#### memory.read\_buffer

```lua
local data = memory.read_buffer(address, size)
```

| Parameter | Type   | Required | Description                                   |
| --------- | ------ | -------- | --------------------------------------------- |
| `address` | number | yes      | Absolute memory address to start reading from |
| `size`    | number | yes      | Number of bytes to read (max 65536)           |

Returns a Lua binary string containing the raw bytes. Returns an empty string on failure. Use `string.byte` or `string.sub` to inspect the bytes.

```lua
local raw = memory.read_buffer(some_addr, 64)
print("first byte: " .. string.byte(raw, 1))

-- search for a pattern in raw bytes
if raw:find("rbxassetid", 1, true) then
    print("found asset url in buffer")
end
```

***

#### memory.read\_string

```lua
local str = memory.read_string(address, max_len)
```

| Parameter | Type   | Required | Description                                    |
| --------- | ------ | -------- | ---------------------------------------------- |
| `address` | number | yes      | Absolute address of the first character        |
| `max_len` | number | no       | Maximum bytes to read. Default: 256. Cap: 4096 |

Reads a null-terminated C string. Returns an empty string on failure.

```lua
local name = memory.read_string(name_ptr)
local url  = memory.read_string(url_ptr, 512)
```

***

#### memory.write\_string

```lua
memory.write_string(address, str, max_len)
```

| Parameter | Type   | Required | Description                                 |
| --------- | ------ | -------- | ------------------------------------------- |
| `address` | number | yes      | Absolute address to write to                |
| `str`     | string | yes      | String to write (null terminator appended)  |
| `max_len` | number | no       | Maximum bytes to write. Default: `#str + 1` |

```lua
memory.write_string(name_ptr, "MyName")
```

***

#### Type Reference

| Type string(s)                                   | Width   | Description                       |
| ------------------------------------------------ | ------- | --------------------------------- |
| `uint8` `u8` `byte`                              | 1 byte  | Unsigned 8-bit integer            |
| `uint16` `u16` `word` `ushort`                   | 2 bytes | Unsigned 16-bit integer           |
| `uint32` `u32` `dword` `uint`                    | 4 bytes | Unsigned 32-bit integer           |
| `uint64` `u64` `qword` `ptr` `pointer` `uintptr` | 8 bytes | Unsigned 64-bit integer / pointer |
| `int8` `i8` `sbyte`                              | 1 byte  | Signed 8-bit integer              |
| `int16` `i16` `short`                            | 2 bytes | Signed 16-bit integer             |
| `int32` `i32` `int`                              | 4 bytes | Signed 32-bit integer             |
| `int64` `i64` `long`                             | 8 bytes | Signed 64-bit integer             |
| `float` `f32` `single`                           | 4 bytes | 32-bit floating point             |
| `double` `f64`                                   | 8 bytes | 64-bit floating point             |
| `bool` `boolean`                                 | 1 byte  | Boolean (0 = false, else true)    |

***

#### Examples

**Read a float property by offset:**

```lua
local inst = game.workspace:find_first_child("Part")
if utility.is_valid(inst) then
    local transparency = memory.read(inst.Address + 0x160, "float")
    print("transparency: " .. transparency)
end
```

**Follow a pointer chain:**

```lua
-- read a pointer, then read a string starting at offset 0x0
local str_container = memory.read(inst.Address + 0xA18, "ptr")
if str_container ~= 0 then
    local url = memory.read_string(str_container, 256)
    print(url)
end
```

**Scan a region for a known pattern:**

```lua
local buf = memory.read_buffer(inst.Address + 0x200, 128)
local pos = buf:find("rbxassetid", 1, true)
if pos then
    print("found at byte offset " .. pos)
end
```

**Write back a custom value:**

```lua
-- unlock a flag field
memory.write(inst.Address + 0x48, "uint8", 1)

-- override a float
memory.write(root_prim + 0x130, "float", 999.0)
```

***

#### Notes

* Addresses must be absolute — add `instance.Address` or `memory.base` to any relative offset before calling.
* Reading an unmapped or invalid address returns `0` / `false` / `""` rather than crashing.
* `"ptr"` is an alias for `uint64` and is the correct type for following pointer chains on 64-bit Roblox.
* `memory.read_buffer` is capped at 65536 bytes per call.
* All write operations go directly to process memory and bypass Roblox's network layer.

***

#### API Reference

| Function                               | Returns | Description                        |
| -------------------------------------- | ------- | ---------------------------------- |
| `memory.base`                          | number  | Module base address                |
| `memory.read(addr, type)`              | any     | Read typed value at address        |
| `memory.write(addr, type, val)`        | boolean | Write typed value, returns success |
| `memory.read_buffer(addr, size)`       | string  | Read raw bytes as binary string    |
| `memory.read_string(addr, max?)`       | string  | Read null-terminated C string      |
| `memory.write_string(addr, str, max?)` | —       | Write null-terminated string       |
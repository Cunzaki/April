# April

Modular cheat script for **Fallen Survival** on [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/). April v3 splits features into loadable modules instead of one monolithic file.

## Requirements

- Project Vector with Vector Lua Engine
- Fallen Survival loaded in-game

Vector exposes `loadfile`, `loadstring`, `load`, and `utility.http_get` / `utility.load_url` for loading scripts locally or from a URL.

## Quick load (remote — recommended)

Create a new script in Vector and paste this **one line**, then **Execute Script**:

```lua
utility.load_url("https://raw.githubusercontent.com/cunzaki/April/main/loader_remote.lua")
```

This downloads `loader_remote.lua` from GitHub, which then fetches each module over HTTP. You need internet access when loading and when modules are first required.

## Local install (offline / faster reloads)

1. In Vector, open the script editor and click **Open Folder** (this opens your Scripts directory).
2. Clone or copy this repo into that folder so the layout looks like:

   ```
   Scripts/
     April/
       loader.lua
       app.lua
       core/
       game/
       features/
       menu/
       ...
   ```

3. In Vector: **Load Script** → select `April/loader.lua` → **Execute Script**.

Local loading uses `loadfile` to read modules from disk — no HTTP requests after install.

## Alternative local entry (loadstring wrapper)

If you prefer a tiny root script next to the `April` folder:

```lua
local fn, err = loadfile("April/loader.lua")
if fn then fn() else print("[April] " .. tostring(err)) end
```

Save that as `april.lua` in your Scripts folder (one level above the `April` module directory).

## Menu tabs

| Tab | Features |
|-----|----------|
| Combat | Aimbot, recoil control |
| Visuals | Player ESP, crosshair, hitmarkers |
| World | Resources, loot, bases, NPCs |
| Movement | Noclip, omnisprint |
| Radar | Waypoints, minimap shell |
| Settings | Config save/load, debug overlay |

## Config files

Settings are saved under:

`%LOCALAPPDATA%\Project Vector\Scripts\April_Slot_1.txt`

Use **Settings → Config** in the menu to save/load slot 1.

## Updating

- **Remote users:** Execute the one-liner again (or reload the script) after we push updates.
- **Local users:** `git pull` inside your `April` folder, then re-execute `loader.lua`.

## Development

Repository contains only April source (`core/`, `game/`, `features/`, `menu/`, loaders). Game dumps and legacy monolith are not included here.

# April

Modular cheat script for **Fallen Survival** on [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/). April v3 splits features into loadable modules instead of one monolithic file.

## Requirements

- Project Vector with Vector Lua Engine
- Fallen Survival loaded in-game

Vector exposes `loadfile`, `loadstring`, `load`, and `utility.http_get` / `utility.load_url` for loading scripts locally or from a URL.

## Quick load (remote — recommended)

**Important:** Vector only shows script menu options when `menu.add_tab(..., "full")` runs in **your executed script file**. A bare `load_url` one-liner will load features but hide all menu options.

Copy the contents of `script_entry.lua` into your Vector script file, then **Execute Script**:

```lua
if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end

local ok, err = utility.load_url("https://raw.githubusercontent.com/cunzaki/April/main/loader_remote.lua")
if not ok then
    print("[April] load_url failed: " .. tostring(err))
end
```

Or open `script_entry.lua` from this repo and execute it directly.

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

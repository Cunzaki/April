# Legacy Feature Parity Checklist

Reference: `fallen_legacy.lua` (7,738 lines, single tab "April")

| Legacy group | Feature | v3 module | Phase 1 | Notes |
|--------------|---------|-----------|---------|-------|
| Aimbot | Player/NPC targeting | `features/combat/aimbot.lua` | Basic | FOV, bone, sticky, visibility |
| Aimbot | Prediction / bullet drop | `features/combat/aimbot.lua` | — | Phase 2 + ToolInfo |
| Aimbot | Flick mode (bows) | `features/combat/aimbot.lua` | — | Phase 2 |
| Aimbot | FOV circle / target line | `features/combat/aimbot.lua` | Basic | Simple FOV circle |
| Recoil | Per-weapon profiles (10 guns) | `features/combat/recoil.lua` | Basic | Enable + strength only |
| Visuals | Player ESP boxes/names | `features/visuals/player_esp.lua` | Done | entity API |
| Visuals | Crosshair (6 styles) | `features/visuals/crosshair.lua` | Basic | Cross style |
| Visuals | Hit notifier / markers | `features/visuals/feedback.lua` | Shell | Placeholder |
| Visuals | Bullet tracers / local trail | `features/visuals/feedback.lua` | — | Phase 2 |
| Visuals | Inventory viewer | `features/visuals/inventory.lua` | — | Phase 2 + Fetch |
| World | Nodes / plants / animals / drops | `features/world/world_esp.lua` | Basic | Folder scan |
| Loot | Crates / barrels / events | `features/world/loot_esp.lua` | Basic | |
| NPCs | Soldiers / bosses / BTR | `features/world/npc_esp.lua` | Basic | |
| Base | Cabinets / turrets / chams | `features/world/base_esp.lua` | Basic | No chams P1 |
| Waypoints | Base + 5 slots | `features/radar/waypoints.lua` | Basic | Slot 1 |
| Tactical Map | Full radar | `features/radar/tactical_map.lua` | Shell | Border + dot |
| Misc | Spider / slowfall / noclip / omnisprint | `features/movement/exploits.lua` | Basic | Noclip + omnisprint |
| Misc | Desync (fflags) | `features/movement/exploits.lua` | — | Phase 3 |
| Misc | Mod detector | `features/utility/mod_detector.lua` | — | Phase 3 |
| Misc | Keybind list / events / snow | various | — | Phase 3 |
| Config | 5 slots + autoload | `features/utility/config.lua` | Basic | Slot 1 |

# April Fallen v4.3.0

## Performance and Stability

- Reworked the runtime settings bridge so each value and color is read once per April frame, then shared by every feature that needs it.
- Reused hot-path tables instead of constantly allocating replacements for tracer cleanup, NPC tracking, Sound ESP, Anti Fling, hitbox override, HUD layout, menus, and spatial search results.
- Reworked world, loot, and base spatial indexes to use numeric cells rather than creating string keys during every nearby-object query.
- Precomputed ESP toggle and color state once per frame for World ESP, Loot ESP, Base ESP, and their mesh-chams collectors.
- Replaced repeated per-entry cham-type lookups with direct cached indexes.
- Optimized the custom UI theme pipeline: palettes are rebuilt only when a theme setting changes, UI colors are updated in place, and menu fade alpha no longer creates a new palette every frame.
- Cached menu group definitions and two-column layouts rather than rebuilding the entire custom-menu catalog every frame.
- Added safe cache invalidation for the dynamic config list after saving, loading, deleting, or refreshing configs.
- Cached frequently used UI modules after first use without depending on bundle registration order.
- Reused HUD dock geometry, visible-settings lists, popup rectangles, and panel-width storage.
- Preserved existing feature update rates, ESP ranges, scan budgets, animation behavior, and visual functionality.

## ESP and Visuals

- Added independent `Enable Mesh Chams` master toggles for Resource/World and Loot ESP, so mesh chams can be disabled without disabling the associated ESP.
- Improved mesh-chams cleanup and active-state handling so disabled/empty selections revert correctly.
- Added ammo type to FOV flags.
- Improved regular aimbot prediction with weapon/ammo-aware ballistic handling.
- Kept silent aim separate from regular aimbot prediction: silent aim uses the direct instant ray path and does not apply weapon velocity/gravity prediction.
- Improved event tracking, including active-state filtering, optional notifications, distance/health display, and sorting controls.
- Added a bundled hitsound asset pack for Bullet Tracers/Hitsounds integration.
- Improved player ESP compatibility with hitbox override so ESP bounds do not thrash when the override is active.
- Optimized Bullet Tracers by compacting expired tracers in place.
- Optimized Sound ESP collection and retained its existing scan cadence and limits.

## Gun Mods and Safety

- Hardened gun-mod patching so a field is only patched when the held weapon actually exposes a valid matching GC entry.
- Added clearer held-item/tool validation and patch feedback paths for gun-related modifications.
- Removed the experimental SwingAnimSpeed client tool modification after it proved unreliable across tools.
- Removed the scope zoom override after testing identified it as detected.
- Kept the existing recoil implementation while separating it from the removed experimental changes.

## Interface and Config

- Moved HUD-style controls into the top dock/navbar instead of leaving them as duplicate full menu tabs.
- Removed the experimental loadout dashboard and loaded-ammo system after they did not meet the intended quality/functionality standard.
- Expanded HUD dock controls for Event Status settings.
- Added custom UI color/theme synchronization for overlays and HUD panels.
- Kept `INSERT` as the custom-menu toggle and preserved all existing UI controls.

## Build

- Updated the release version to `4.3.0`.
- Rebuilt `april.lua`, `Script 1.lua`, and `load.lua`.
- Verified `april.lua` and `Script 1.lua` are identical generated runtime files.

## Testing Notes

- Test the full runtime with the menu open, multiple ESP categories active, mesh chams enabled, Bullet Tracers running, and HUD panels enabled at the same time.
- Scope zoom override is intentionally not included because it was detected during testing.
- SwingAnimSpeed is intentionally not included because the tested tool coverage was inconsistent.

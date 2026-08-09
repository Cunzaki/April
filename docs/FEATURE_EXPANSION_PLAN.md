# April Fallen — Feature Expansion Plan

> Scope: feature roadmap for the Project Vector LuaVM runtime.
>
> Evidence base: Vector API reference, Theo offset support, April source, and
> Fallen Survival PlaceVersion 806 dump (`2026-07-31`). This is a planning
> document, not an instruction to add broad remote invocation, server-state
> writes, or unvalidated memory writes.

## Product direction

The strongest next additions are client-observable information and quality-of-
life features that build on April's existing cache, scanner, targeting, item,
and UI systems. They should share data already captured by April rather than
adding independent per-frame scans.

Primary goals:

- Make target, world, and event information more actionable.
- Expand weapon feel only through already-established equipped-weapon GC paths.
- Add useful planning tools based on the game's local catalog and recipes.
- Keep scanning incremental, drawing frame-bound, and modifications reversible.

## Evidence and capability map

| Area | Confirmed evidence | Best use in April |
|---|---|---|
| Vector API | Entity cache, live positions/bones/bounds, draw/image APIs, raycast, camera, threads, GC, FFlags, memory, lighting/terrain | ESP, tactical overlays, camera and visual QoL, safe cached client-state features |
| Theo offsets | `Sound`, `AnimationTrack`, `Animator`, `Misc.AnimationId`, `TaskScheduler` | Existing sound/animation features; no new write-dependent feature required |
| Inventory/client UI | `InventoryController`, `ClientSignals.Inventory`, `Items`, `ItemClass`, `ArmorModule` | Local inventory dashboard, item tooltips, crafting and equipment context |
| Crafting/research | `CraftingController`, `RecipeModule`, `ResearchModule`, `ItemRecipes`, `BasePartRecipes` | Recipe planner and material calculator |
| Weapon data | `ToolInfo`, `Items`, current GC weapon profile system; dump contains `GunRecoilAimMult`, `DefaultZoomLevel`, `ZoomLevel` | Scoped recoil completion and optional scope zoom |
| World/event state | `Events`, `AttackHeli`, `HeliPatrolPoints`, BTR/event assets, `VFXModule`, `EventViewer` | Richer event tracker, heli patrol map, event timeline |
| Base systems | `BenchInfo`, `BasePartInfo`, `AutoTurretController`, `ElectricityController` | Turret/base-device context and powered-state presentation where replicated |
| Vehicles | Salvaged Flycopter, wooden/military boat controllers, vehicle raycast exceptions | Vehicle ESP/radar classification |
| Survival data | `StatusClass`, `Items` nutrition/radiation values, inventory status UI | Local survival monitor and consumable advisor |

## Priority roadmap

### P0 — Scoped recoil completion

**User value:** High. **Implementation risk:** Low. **Performance cost:** Negligible.

The dump exposes `GunRecoilAimMult` alongside existing recoil values. April's
GC gun-mod system already discovers, snapshots, applies, and restores the
equipped weapon's supported keys.

Implementation:

1. Add `GunRecoilAimMult` to the recognized weapon-key set in
   `src/game/gc_weapon_mods.lua`.
2. Incorporate it into the current recoil profile payload in
   `src/features/combat/gun_mods.lua`.
3. Keep it tied to the recoil master setting; do not create a high-frequency
   reapply loop.
4. Preserve existing original-value capture and restoration behavior.

Acceptance checks:

- ADS recoil changes with the existing recoil control.
- Disable, respawn, and tool-switch restore original values.
- No extra GC full scans occur while the control is unchanged.

### P0 — Optional scope zoom profile

**User value:** High. **Implementation risk:** Low–medium. **Performance cost:** Negligible.

The dump and existing GC research show `DefaultZoomLevel` / `ZoomLevel` on
weapon metadata. This is a visual/aiming-feel feature and should stay bounded.

Implementation:

1. Extend `src/game/gc_weapon_mods.lua` with zoom-key discovery and originals.
2. Add a master toggle, multiplier/override selector, and conservative range
   in `src/features/combat/gun_mods.lua`.
3. Apply only to equipped-weapon nodes; restore on disable/equipment changes.
4. Add profile-level exclusions for weapons without optics if testing shows
   undesirable behavior.

Acceptance checks:

- Supported scoped weapons update immediately after equip.
- Unscoped weapons remain unaffected.
- Original zoom values return on disable and session cleanup.

### P1 — Target inventory and equipment inspector

**User value:** High. **Implementation risk:** Medium. **Performance cost:** Low with caching.

April already has item catalogs, item images, attachment images, player gear,
an inventory helper, and a target overlay. The missing piece is a compact,
on-demand target panel rather than a permanently expensive overlay.

Implementation:

1. Create `src/features/visuals/inventory_viewer.lua`.
2. Use `features/combat/active_target.lua` as the selected-player source.
3. Reuse `src/game/player_gear.lua`, `src/game/inventory.lua`,
   `src/game/item_catalog.lua`, and `src/game/item_images.lua`.
4. Add a hold/toggle key and optional docked panel.
5. Cache by player identity and gear/inventory revision; refresh only on target
   change, equipped-item change, or a low-frequency interval.
6. Show confirmed information only: armor, held weapon, attachment icons,
   exposed inventory/container items, and quantities.

Do not attempt to infer server-private inventory state. If a field is not
replicated, show it as unavailable rather than guessing.

### P1 — Hit feedback suite

**User value:** High. **Implementation risk:** Medium. **Performance cost:** Low.

April has tracer and target systems but lacks a unified hit marker/history.

Implementation:

1. Create `src/features/visuals/hit_feedback.lua`.
2. Feed it from locally observable shot, impact, VFX, and health-delta state;
   reuse bullet-tracer timing and active-target context.
3. Add center hit marker, compact event feed, hit distance, target name, and
   optional head/body classification only when the client can determine it.
4. Maintain a fixed-size ring buffer and expiry timestamps; never scan the
   whole world to find hits.

Acceptance checks:

- No feedback is emitted for unconfirmed events.
- The feed has bounded memory and draw work.
- Feature works independently of tracer visibility settings.

### P1 — Vehicle ESP and radar layer

**User value:** High. **Implementation risk:** Medium. **Performance cost:** Low–medium.

The dump contains client controllers and object references for Salvaged
Flycopter, wooden boats, and military boats. Raycast logic explicitly names
the Flycopter, making it a strong classifier candidate.

Implementation:

1. Add vehicle maps to `src/game/esp_maps.lua`.
2. Add a vehicle cache bucket to `src/core/cache.lua`.
3. Register a low-priority incremental scan in `src/menu/tabs.lua`.
4. Create `src/features/world/vehicle_esp.lua` or fold it into `world_esp.lua`
   if that keeps shared presentation simpler.
5. Add tactical-map layer support in `src/features/radar/tactical_map.lua`.
6. Classify by known model names and verified component patterns, not a broad
   workspace descendant scan every frame.

Suggested labels: Flycopter, Wooden Boat, Military Boat, occupied state only
when it is client-visible, and distance.

### P1 — Event intelligence expansion

**User value:** High. **Implementation risk:** Medium. **Performance cost:** Low.

Current event and raid support can be upgraded with information already shown
by the game client.

Implementation:

1. Extend `src/features/utility/event_status.lua` and
   `src/features/world/raid_esp.lua`.
2. Add AttackHeli state cards: seen, health when attributes are present,
   distance, and estimated event phase based on observed VFX/model state.
3. Draw optional patrol paths from `Workspace.HeliPatrolPoints` on the
   tactical map.
4. Add BTR/event movement trail using a capped position history.
5. Include event loot transitions such as Heli Crate through the existing loot
   scan, not a new scanner.

### P2 — Turret and base-device context

**User value:** Medium–high. **Implementation risk:** Medium. **Performance cost:** Low.

`AutoTurretController`, `BenchInfo`, `BasePartInfo`, and
`ElectricityController` provide evidence for useful base classification.

Implementation:

1. Extend base scan entries with a `device_kind` and optional static metadata.
2. Add a turrets/devices sub-filter to `src/features/world/base_esp.lua`.
3. Surface only replicated state: active/powered markers, aim direction,
   health, and owner/authorization where truly visible.
4. Cache state during the existing base scan or a modest tick; do not inspect
   all base descendants during draw.

### P2 — Recipe, research, and material planner

**User value:** Medium–high. **Implementation risk:** Low. **Performance cost:** Negligible.

The complete local item, recipe, bench, and research catalogs make this a
high-confidence offline-style feature.

Implementation:

1. Create `src/features/utility/crafting_planner.lua`.
2. Build indexes from `ItemRecipes`, `BasePartRecipes`, `ResearchModule`, and
   April's item catalog at initialization.
3. Add searchable item selection, recursive ingredient totals, required bench,
   research requirement, and local-inventory comparison.
4. Keep all calculation event-driven: rebuild only when the selected item or
   inventory snapshot changes.

### P2 — Local survival and consumable advisor

**User value:** Medium. **Implementation risk:** Low. **Performance cost:** Negligible.

`StatusClass` confirms health, hunger, thirst, and radiation status concepts;
the Items module exposes consumable effects and armor radiation resistance.

Implementation:

1. Create `src/features/utility/survival_advisor.lua`.
2. Read local, client-visible status only.
3. Match available local inventory items against the Item catalog's Hunger,
   Thirst, and Radiation effects.
4. Show a small advisory panel: low status warning, best available consumable,
   and the known tradeoff (for example, radiation vitamins and thirst).
5. Do not automate consumption or invoke remotes.

### P2 — Environmental visual profiles

**User value:** Medium. **Implementation risk:** Low. **Performance cost:** Negligible.

Vector directly exposes lighting, fog, terrain grass, water, and camera FOV.

Implementation:

1. Create `src/features/visuals/environment.lua`.
2. Provide reversible presets: clarity, low foliage, clear water, night
   visibility, and FOV profile.
3. Snapshot originals once, write only on setting change, and restore on
   disable/unload.
4. Keep gravity and simulation tick-rate changes out of normal presets.

### P3 — Performance and diagnostics HUD

**User value:** Medium for development. **Implementation risk:** Low.

Implementation:

1. Add opt-in timing collection to `src/core/debug.lua`.
2. Add `src/features/utility/performance_hud.lua`.
3. Display frame time, cache sizes, active scan, scan age, indicators, chams
   count, image-cache state, and per-feature update/draw totals.
4. Use a rolling window and fixed-size buffers; no per-frame log files.

## Architecture rules for every addition

### Data ownership

- Extend an existing cache bucket before creating a parallel scanner.
- Use `core.incremental_scan` for workspace-scale discovery.
- Use `core.cache` spatial indexes for range-based world/radar rendering.
- Reuse `active_target` for target-specific features.
- Reuse item and image catalogs rather than fetching or parsing assets during
  frame rendering.

### Frame and scan budgets

- Draw only in `OnFrame`.
- Keep all draw collections bounded or range-filtered.
- Avoid `GetDescendants()` in a frame loop.
- Use short, fixed-size history/ring buffers for trails, hits, and events.
- Read each menu setting once per frame through `core.settings`.
- Scan or rebuild only on an interval, target transition, model transition, or
  explicit reload action.

### State restoration

Every modifying feature must capture originals and restore them on:

- Feature disable.
- Tool/equipment change.
- Character respawn.
- Script unload.

This applies especially to GC weapon values, lighting/terrain values, camera
FOV, chams, and any memory-backed setting.

### Theo offset guardrails

- Continue using automatically fetched offsets.
- Treat offset-backed information as optional: feature unavailable is safer
  than an assumed field after an upstream change.
- Do not add new raw memory writes without a separate validation plan.
- Keep `TaskScheduler` MaxFPS behavior isolated from feature additions.

### Explicitly out of scope

- Remote-event spam or generic remote firing.
- Server-owned stat, item, damage, crafting, or farming mutations.
- Melee `Cooldown` / `SwingAnimSpeed` modification.
- Reload-duration or reload-animation manipulation.
- Full GC walks in a hot loop.
- Unverified raw pointer writes.

## Suggested delivery sequence

1. Scoped recoil completion.
2. Scope zoom profile.
3. Target inventory/equipment inspector.
4. Hit feedback suite.
5. Vehicle ESP/radar.
6. Event intelligence expansion.
7. Turret/base-device context.
8. Recipe/research planner.
9. Survival advisor.
10. Environmental profiles and development HUD.

## Per-feature definition of done

- Feature is modular under `src/features/` and registered in `menu/tabs.lua`.
- UI state is represented in `src/ui/catalog.lua` and connected through the
  existing menu shim/feature-bind path.
- All source paths are included by `scripts/bundle.mjs`.
- Disabled state has no persistent world, GC, visual, or environment changes.
- No current feature update rate is lowered.
- Build produces identical `april.lua` and `Script 1.lua`.
- Runtime behavior is manually checked in Fallen Survival after a game update
  and after Theo offset refresh.

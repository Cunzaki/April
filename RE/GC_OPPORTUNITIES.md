# GC Opportunities — Fallen Survival (Apr 2026)

Research from `gc_dump.txt`, `April/docs/API.md`, and `references/dump/`.  
Goal: find **client-side weapon/feel** patches that are **not** the banned farm paths (`Cooldown`, melee swing tables).

## Methodology

1. `dumpgc("gc_dump.txt")` — full heap scan (~292k lines)
2. Cross-reference keys with ToolInfo module (`references/dump/scripts/ReplicatedStorage.Modules.ToolInfo.ModuleScript.lua`)
3. Filter out server game-mode tables, UI garbage, and keys tied to prior ban incidents

## Already shipped (April gun mods)

Applied via `refreshgc()` → `getgc(keys)` → `applygc(payload)` on toggle only:

| Key | Role |
|-----|------|
| `RecoilMult` | Recoil scale (negative = less) |
| `AimSpreadMult` | ADS spread |
| `HipSpreadMult` | Hip-fire spread |
| `SwayMult` | Weapon sway |
| `RangeMult` | Bullet range |
| `SpeedMult` | Bullet speed |
| `FireRateMult` | RPM multiplier |

These appear together on equipped weapon GC nodes (e.g. dump lines ~54391–54463, ~72921).

---

## Promising — low ban risk (same pattern as gun mods)

### `GunRecoilAimMult`

- Found on the **same weapon stat clusters** as `RecoilMult` / `AimSpreadMult`
- Values like `-0.4`, `-0.15` (scoped recoil feel)
- **Recommendation:** Add to `gc_weapon_mods.WEAPON_FIND_KEYS` + gun mod profile tied to recoil toggle — same apply-on-toggle flow, no loop

### `DefaultZoomLevel` / `ZoomLevel`

- Per-weapon scope zoom (e.g. `1.25`, `1.5`, `8` on Barrett)
- Lives on ToolInfo-derived GC tables alongside reload stats
- **Use case:** “Scope zoom” slider under gun mods (client feel)
- **Risk:** Low–medium — visual/ADS only, not fire rate or damage

---

## Do NOT ship — ban / server-side / wrong target

| Key | Why skip |
|-----|----------|
| `Cooldown` | **User banned** patching this on melee |
| `SwingAnimSpeed` | Farm-speed path — same class of detection |
| `GatherMult` | Server **game mode** multiplier (values 2/3), not tool swing speed |
| `CraftSpeedMult` / `SmeltSpeedMult` / `ShredderSpeedMult` | Server/bench config blobs, not held tool |
| `MaxStackMult` / `DespawnTimeMult` / `DecayDamageMult` | World/server tuning tables |
| `ReloadDuration` / `ReloadAnimSpeed` | Same ToolInfo tables as `Cooldown` — likely server-validated reload timing |
| `DamageMult` on NPC/item rows | Wrong nodes; not player weapon output |
| `Health` / `Radiation` on entity rows | NPC/status tables |

---

## Not viable in Vector

| Approach | Reason |
|----------|--------|
| `getgc(true)` full scan | Poisons keyed cache → 0 nodes (documented in API.md) |
| RaycastUtil hook | `require` path fails in Vector external VM |
| Melee GC farm | Removed; **Farm Helper** (camera aim) remains |

---

## Suggested next steps (priority)

1. **GunRecoilAimMult** — extend existing gun mods whitelist (smallest diff, same UX)
2. **Scope zoom** — optional `DefaultZoomLevel` patch behind new toggle; conservative values only
3. **Re-apply thread** — only if users report mods dropping on respawn (API.md: 100–500 ms thread); currently toggle-only to minimize footprint

---

## References

- `April/docs/API.md` §7 GC API
- `April/src/game/gc_weapon_mods.lua`
- `gc_dump.txt` — weapon cluster ~54366–54464, ToolInfo reload block ~73146–73302
- `April/references/dump/scripts/ReplicatedStorage.Modules.ToolInfo.ModuleScript.lua`

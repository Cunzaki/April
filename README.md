# April Fallen

Fallen Survival script for [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/).

## Load in Vector

Paste this into a Vector script slot and execute:

```lua
utility.LoadUrl("https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua")
```

That always pulls the latest `april.lua` from GitHub `main`.

Menu: **INSERT** (custom UI)

---

## Rebuild & ship

```bash
npm run build
git add april.lua
git commit -m "Ship April vX.Y.Z"
git push origin main
```

After push, `utility.LoadUrl(...)` serves the new build.

---

## Repo layout

| Path | Purpose |
|------|---------|
| `april.lua` | Bundled runtime (what LoadUrl downloads) |
| `load.lua` | Same one-liner as above |
| `src/` | Modular source |
| `scripts/` | Bundle tools |
| `docs/` | API notes |

**Local only (gitignored):** `dump/`, `RE/`, `node_modules/`

---

## License

Use at your own risk. Not affiliated with Project Vector or Fallen Survival.

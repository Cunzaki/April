# April Fallen

Fallen Survival script for [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/).

## Load in Vector

**Option A — loadstring (recommended):**

```lua
utility.load_url("https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua")
```

Or run `load.lua` from this repo.

**Option B — local file:**

1. Build: `npm run build`
2. Load `april.lua` in Vector → **Execute Script**.

Menu: **Scripts → April**

---

## Rebuild from source

```bash
npm run build
```

Edit `src/`, rebuild, push `april.lua` to GitHub.

---

## What's on GitHub (minimal)

| Path | Purpose |
|------|---------|
| `load.lua` | One-line loadstring |
| `april.lua` | Bundled runtime script |
| `src/` | Modular source |
| `scripts/` | Bundle + asset tools |
| `assets/` | CDN images (`raw.githubusercontent.com/.../assets/`) |
| `package.json` | `npm run build` |

**Local only (gitignored):** `references/`, `RE/`, `Script 1.lua`, `node_modules/`

---

## License

Use at your own risk. Not affiliated with Project Vector or Fallen Survival.

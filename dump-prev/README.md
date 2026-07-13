# Game dump (local, gitignored)

**Last dump:** `place 13800717766 Fallen Survival Large Server(1).rbxlx`  
**Instances:** 63097 | **Scripts:** 132 | **Assets:** 6403

Regenerate after a new rbxlx save:

```bash
npm run dump
# or explicit path:
node scripts/dump-rbxlx.mjs "C:/Users/.../place 13800717766 Fallen Survival Large Server(1).rbxlx"

npm run sync-assets
npm run build
```

Key paths:

| Path | Use |
|------|-----|
| `GAME_REFERENCE.txt` | Workspace / ReplicatedStorage layout |
| `scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua` | Item names + image asset IDs |
| `instances/by_service/Lighting.jsonl` | `Lighting.NVG` ColorCorrectionEffect |
| `tree/services/ReplicatedStorage.txt` | Attachments folder models |

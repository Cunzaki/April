import csv
from pathlib import Path

tsv = Path(r"c:\Users\Cunza\Desktop\Vector Fallen V2\April Fallen\dump\catalog\animations.tsv")
out_path = Path(r"c:\Users\Cunza\Desktop\Vector Fallen V2\April Fallen\src\game\fallen_anims.lua")

rows = list(csv.DictReader(tsv.open(encoding="utf-8"), delimiter="\t"))

def clean_id(aid: str) -> str:
    for pref in ("rbxassetid://", "http://www.roblox.com/asset/?id="):
        if aid.startswith(pref):
            return aid[len(pref):]
    return aid

# Prefer character-relevant categories first, then everything else unique by id.
priority_paths = []
rest = []
for r in rows:
    path = r["path"]
    aid = clean_id(r["animationId"])
    name = path.split(".")[-1]
    if "StateAssetController.Animations" in path:
        priority_paths.append(("Loco", name, aid, path))
    elif ".GlobalAnims." in path:
        tool = path.split("VMs.")[-1].split(".GlobalAnims")[0] if "VMs." in path else "Tool"
        priority_paths.append(("Global", f"{tool} {name}", aid, path))
    elif ".CameraAnims." in path:
        tool = path.split("VMs.")[-1].split(".CameraAnims")[0] if "VMs." in path else "Tool"
        priority_paths.append(("Camera", f"{tool} {name}", aid, path))
    elif ".LocalAnims" in path:
        # LocalAnims / LocalAnimsMP5 / etc
        parts = path.split(".")
        # ... VMs.Tool.LocalAnims.Name
        tool = "Tool"
        folder = "LocalAnims"
        for i, p in enumerate(parts):
            if p.startswith("LocalAnims"):
                folder = p
                if i >= 2:
                    tool = parts[i - 1]
                break
        priority_paths.append(("VM", f"{tool} {name}", aid, path))
    elif "SleepAnim" in path:
        priority_paths.append(("World", "Sleep", aid, path))
    elif path.endswith(".Hit") and "Ragdolls" in path:
        priority_paths.append(("World", "Hit", aid, path))
    else:
        rest.append(("Other", name, aid, path))

# Unique by asset id — keep first preferred label
seen = {}
order = []
for cat, label, aid, path in priority_paths + rest:
    if aid in seen:
        continue
    # prettier loco labels (no prefix)
    if cat == "Loco":
        pretty = label
    elif cat == "Global":
        pretty = f"Body {label}"
    elif cat == "VM":
        pretty = f"VM {label}"
    elif cat == "Camera":
        pretty = f"Cam {label}"
    else:
        pretty = label
    seen[aid] = pretty
    order.append((pretty, aid))

# Ensure None first
labels = ["None"]
ids = ["nil"]
used_labels = {"None"}
for pretty, aid in order:
    lab = pretty
    n = 2
    while lab in used_labels:
        lab = f"{pretty} ({aid[-4:]})"
        if lab in used_labels:
            lab = f"{pretty} {aid}"
        n += 1
    used_labels.add(lab)
    labels.append(lab)
    ids.append(f'"{aid}"')

lines = []
lines.append("-- Auto-generated from dump/catalog/animations.tsv — all unique animation asset IDs.")
lines.append("-- Playback must match Fallen: Humanoid:LoadAnimation(anim):Play() with default speed/weight.")
lines.append("")
lines.append("local M = {}")
lines.append("")
lines.append("M.LABELS = {")
for lab in labels:
    lines.append(f'    "{lab}",')
lines.append("}")
lines.append("")
lines.append("M.IDS = {")
for i, aid in enumerate(ids):
    if aid == "nil":
        lines.append("    nil, -- None")
    else:
        lines.append(f"    {aid}, -- {labels[i]}")
lines.append("}")
lines.append("")
lines.append("function M.asset_url(id)")
lines.append("    if not id or id == \"\" then return nil end")
lines.append("    local s = tostring(id)")
lines.append("    if s:find(\"rbxassetid\", 1, true) or s:find(\"http\", 1, true) then")
lines.append("        return s")
lines.append("    end")
lines.append("    return \"rbxassetid://\" .. s")
lines.append("end")
lines.append("")
lines.append("function M.id_for_index(idx)")
lines.append("    idx = tonumber(idx) or 0")
lines.append("    if idx < 0 or idx >= #M.IDS then return nil end")
lines.append("    return M.IDS[idx + 1]")
lines.append("end")
lines.append("")
lines.append("return M")
lines.append("")

out_path.write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {len(labels)} labels ({len(labels)-1} animations) -> {out_path}")

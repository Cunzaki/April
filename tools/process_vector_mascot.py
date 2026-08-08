"""Remove BG, bottom-flush Vector emotions to April 346x400 canvas."""
from __future__ import annotations

import math
from io import BytesIO
from pathlib import Path

from PIL import Image
from rembg import remove

SRC_DIR = Path(
    r"C:\Users\Cunza\.cursor\projects\e-Projects-Vector-Fallen-V2-April-Fallen\assets"
)
OUT_DIR = Path(r"E:\Projects\Vector Fallen V2\April Fallen\assets\anime\vector")
TARGET_W, TARGET_H = 346, 400

ID_TO_EMOTION = {
    "8df1e5d0": "neutral",
    "4ee40bf8": "angry",
    "000eebdc": "sad",
    "c17cbe3c": "happy",
}


def find_sources() -> dict[str, Path]:
    found: dict[str, Path] = {}
    for p in SRC_DIR.glob("*.png"):
        for key, emotion in ID_TO_EMOTION.items():
            if key in p.name:
                found[emotion] = p
    return found


def remove_bg(im: Image.Image) -> Image.Image:
    buf = BytesIO()
    im.convert("RGBA").save(buf, format="PNG")
    return Image.open(BytesIO(remove(buf.getvalue()))).convert("RGBA")


def harden_alpha(im: Image.Image, lo: int = 48, hi: int = 140) -> Image.Image:
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a <= lo:
                a = 0
            elif a >= hi:
                a = 255
            else:
                t = (a - lo) / (hi - lo)
                a = int(80 + t * 175)
            px[x, y] = (r, g, b, a)
    return im


def content_bbox(im: Image.Image, alpha_min: int = 32) -> tuple[int, int, int, int]:
    mask = im.split()[-1].point(lambda v: 255 if v >= alpha_min else 0)
    bb = mask.getbbox()
    if not bb:
        return (0, 0, im.width, im.height)
    return bb


def soft_bottom_fade(im: Image.Image, fade_px: int = 18) -> Image.Image:
    px = im.load()
    w, h = im.size
    bb = content_bbox(im, 32)
    bottom = bb[3] - 1
    top = max(bb[1], bottom - fade_px + 1)
    span = max(1, bottom - top)
    for y in range(top, bottom + 1):
        t = (y - top) / span
        # Keep most of the torso solid; only the last cut softens.
        factor = 1.0 - (t * t) * 0.85
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (r, g, b, max(0, int(a * factor)))
    return im


def fit_shared(images: dict[str, Image.Image], tw: int, th: int) -> dict[str, Image.Image]:
    crops: dict[str, Image.Image] = {}
    max_w = 1
    max_h = 1
    for name, im in images.items():
        crop = im.crop(content_bbox(im, 32))
        crops[name] = crop
        max_w = max(max_w, crop.width)
        max_h = max(max_h, crop.height)

    side_pad = int(min(tw, th) * 0.02)
    scale = min((tw - side_pad * 2) / max_w, th / max_h)

    out: dict[str, Image.Image] = {}
    for name, crop in crops.items():
        nw = max(1, int(round(crop.width * scale)))
        nh = max(1, int(round(crop.height * scale)))
        resized = crop.resize((nw, nh), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        ox = (tw - nw) // 2
        oy = th - nh
        canvas.paste(resized, (ox, oy), resized)
        canvas = soft_bottom_fade(canvas, fade_px=16)
        out[name] = canvas
    return out


def main() -> None:
    srcs = find_sources()
    missing = [e for e in ID_TO_EMOTION.values() if e not in srcs]
    if missing:
        raise SystemExit(f"missing sources: {missing}")

    cutouts: dict[str, Image.Image] = {}
    for emotion, path in sorted(srcs.items()):
        print(f"cutout {emotion}...")
        cutouts[emotion] = harden_alpha(remove_bg(Image.open(path)))

    outs = fit_shared(cutouts, TARGET_W, TARGET_H)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for emotion, out in sorted(outs.items()):
        out_path = OUT_DIR / f"{emotion}.png"
        out.save(out_path, optimize=True)
        a = out.split()[-1]
        hist = a.histogram()
        bb = content_bbox(out, 32)
        solid = 0
        for y in range(out.height - 1, -1, -1):
            if any(a.getpixel((x, y)) >= 200 for x in range(out.width)):
                solid = y
                break
        print(
            f"  {emotion}: full={hist[255]} bbox32={bb} "
            f"last_solid_y={solid} bottom_gap={out.height - 1 - solid}"
        )


if __name__ == "__main__":
    main()

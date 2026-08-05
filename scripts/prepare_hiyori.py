"""Extract the runtime Hiyori expressions from the licensed itch.io archive."""

from __future__ import annotations

import io
import sys
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


EXPRESSIONS = (
    "normal",
    "smile",
    "happy",
    "hah",
    "angrysmile",
    "pout",
    "worried",
    "fear",
    "sad",
    "disgusted",
    "evil",
    "oh",
)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    archive = root / "assets" / "hiyori-download" / "game-17865506.zip"
    output = root / "assets" / "anime" / "april"
    output.mkdir(parents=True, exist_ok=True)

    prefix = "Hiyori_2160p_PNG/hiyori_outing_"
    if archive.is_file():
        source = zipfile.ZipFile(archive)
        source_is_archive = True
    else:
        source = root / "assets" / "anime" / "hiyori"
        source_is_archive = False
        if not source.is_dir():
            print(f"Missing archive and source sprites: {archive}", file=sys.stderr)
            return 1

    with source if source_is_archive else open(__file__, "r", encoding="utf-8"):
        for expression in EXPRESSIONS:
            if source_is_archive:
                member = f"{prefix}{expression}.png"
                with source.open(member) as raw:
                    image = Image.open(io.BytesIO(raw.read())).convert("RGBA")

                alpha = image.getchannel("A")
                bounds = alpha.getbbox()
                if bounds:
                    image = image.crop(bounds)

                max_height = 400
                if image.height > max_height:
                    width = max(1, round(image.width * max_height / image.height))
                    image = image.resize((width, max_height), Image.Resampling.LANCZOS)

                # The overlay is a waist-up announcer, not a full visual-novel sprite.
                image = image.crop((0, 0, image.width, round(image.height * 0.62)))
            else:
                image = Image.open(source / f"{expression}.png").convert("RGBA")

            # Give April a consistent in-universe shirt label on each expression.
            label = "APRIL"
            font_path = Path(r"C:\Windows\Fonts\arialbd.ttf")
            font = ImageFont.truetype(str(font_path), max(14, round(image.height * 0.058)))
            draw = ImageDraw.Draw(image)
            box = draw.textbbox((0, 0), label, font=font, stroke_width=1)
            label_w = box[2] - box[0]
            label_x = round(image.width * 0.53 - label_w * 0.5)
            label_y = round(image.height * 0.58)
            draw.text(
                (label_x, label_y),
                label,
                font=font,
                fill=(239, 210, 255, 255),
                stroke_width=1,
                stroke_fill=(41, 24, 47, 235),
            )

            target = output / f"{expression}.png"
            image.save(target, "PNG", optimize=True, compress_level=9)
            print(f"{expression}: {image.width}x{image.height} -> {target.name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

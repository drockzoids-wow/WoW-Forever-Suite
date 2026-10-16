"""Resize original PNG artwork into WoW textures and review previews.

Requires Pillow. Run with the bundled workspace Python or any Python with Pillow.
Choose icon, gui or all (the default). Only dimensions and file formats change.
"""

import argparse
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent


def build(name, size, source_name=None):
    source_path = ROOT / "artwork" / f"{source_name or name}.png"
    texture_path = ROOT / "src" / "WoWForeverSuite" / "Media" / f"{name}.tga"
    with Image.open(source_path) as image:
        if image.width != image.height:
            raise ValueError("The artwork source must be square.")
        source = image.convert("RGBA")
        if source.getextrema()[3] != (255, 255):
            raise ValueError("This artwork is intended to have an opaque slate background.")
        source.resize((size, size), Image.Resampling.LANCZOS).save(texture_path)
        source.resize((256, 256), Image.Resampling.LANCZOS).save(
            source_path.with_name(f"{name}-preview.png")
        )

    with Image.open(texture_path) as texture:
        assert texture.size == (size, size) and texture.mode == "RGBA"
        assert texture.getextrema()[3] == (255, 255)

    header = texture_path.read_bytes()[:18]
    assert header[2] == 2 and header[16] == 32, "Expected uncompressed 32-bit TGA."
    print(f"Artwork: {texture_path} ({size} x {size}, opaque uncompressed 32-bit TGA)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=("icon", "gui", "all"), nargs="?", default="all")
    target = parser.parse_args().target
    if target in ("icon", "all"):
        build("ForeverSuiteIcon", 128)
    if target in ("gui", "all"):
        build("ForeverSuiteLogo", 256, "ForeverSuiteLogo-v4")

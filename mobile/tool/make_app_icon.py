"""Prepare launcher variants from the approved Reunite mark."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "branding" / "app_icon.png"
FG = ROOT / "assets" / "branding" / "app_icon_foreground.png"
INK = (15, 76, 92)


def near_ink(r: int, g: int, b: int) -> bool:
    return abs(r - INK[0]) < 48 and abs(g - INK[1]) < 48 and abs(b - INK[2]) < 48


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    img.save(SRC)

    pixels = img.load()
    fg = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dest = fg.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a > 8 and not near_ink(r, g, b):
                dest[x, y] = (255, 255, 255, a)
    fg.save(FG)
    print("wrote", SRC)
    print("wrote", FG)


if __name__ == "__main__":
    main()

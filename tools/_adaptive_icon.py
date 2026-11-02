"""Build the Android adaptive layer from the owner's artwork.

The master is a rounded blue tile sitting on a white page. Reusing it directly
as the adaptive foreground would show a small blue tile inside a white circle,
so the outer white margin is flood-filled to transparent (from the corners, so
the white "K" inside the tile is untouched) and the tile is cropped. The
adaptive background is sampled from the tile itself.
"""
import io

from PIL import Image, ImageDraw

LOGO = "app/assets/logo"
source = Image.open(f"{LOGO}/app-icon.png").convert("RGBA")

filled = source.copy()
width, height = filled.size
for corner in [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]:
    ImageDraw.floodfill(filled, corner, (255, 255, 255, 0), thresh=60)

box = filled.getbbox()
if box is None:
    raise SystemExit("could not find the artwork inside the white margin")
cropped = filled.crop(box)
cropped.save(f"{LOGO}/app-icon-adaptive.png", optimize=True)
print("wrote", f"{LOGO}/app-icon-adaptive.png", cropped.size)

blue = cropped.getpixel((cropped.width // 2, max(4, cropped.height // 12)))[:3]
hex_color = "#{:02X}{:02X}{:02X}".format(*blue)
print("adaptive background:", hex_color)

filled.resize((320, 320), Image.LANCZOS).save(".icon-preview-adaptive.png")

pubspec = "app/pubspec.yaml"
text = io.open(pubspec, encoding="utf-8", newline="").read()
text = text.replace(
    '  adaptive_icon_background: "#FDFEFE"',
    f'  adaptive_icon_background: "{hex_color}"',
)
text = text.replace(
    '  adaptive_icon_foreground: "assets/logo/app-icon.png"',
    '  adaptive_icon_foreground: "assets/logo/app-icon-adaptive.png"',
)
text = text.replace(
    "  adaptive_icon_foreground_inset: 16",
    "  adaptive_icon_foreground_inset: 0",
)
io.open(pubspec, "w", encoding="utf-8", newline="").write(text)
print("pubspec adaptive layer updated")

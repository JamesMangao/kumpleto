"""Derive every icon asset from `app/assets/logo/app-icon.png`.

The master artwork is maintained by hand (it is the only file to edit). This
script produces the deliverables that must stay in sync with it:

    assets/logo/app-icon-adaptive.png      adaptive foreground, white margin
                                           flood-filled to transparent
    assets/logo/app-icon-512.png           Play store icon
    assets/logo/feature-graphic-1024x500.png
    android/.../drawable/splash_logo.png   launch-window logo

Afterwards regenerate the Android mipmaps:

    cd app && dart run flutter_launcher_icons
"""
import os

from PIL import Image, ImageDraw

LOGO = "app/assets/logo"
MASTER = f"{LOGO}/app-icon.png"


def tile():
    """The artwork with its outer white page removed."""
    source = Image.open(MASTER).convert("RGBA")
    filled = source.copy()
    width, height = filled.size
    for corner in [
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
    ]:
        ImageDraw.floodfill(filled, corner, (255, 255, 255, 0), thresh=60)
    box = filled.getbbox()
    if box is None:
        raise SystemExit("no artwork found inside the white margin")
    return filled, filled.crop(box)


def save(image, path):
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    image.save(path, "PNG", optimize=True)
    print(f"wrote {path} ({os.path.getsize(path) // 1024} KB)")


def main():
    source, cropped = tile()
    save(cropped, f"{LOGO}/app-icon-adaptive.png")
    save(cropped.resize((512, 512), Image.LANCZOS), f"{LOGO}/app-icon-512.png")

    # Launch window: the tile on the app's background colour.
    splash = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    tile_size = 380
    resized = cropped.resize((tile_size, tile_size), Image.LANCZOS)
    splash.paste(
        resized, ((768 - tile_size) // 2, (768 - tile_size) // 2), resized
    )
    save(splash, "app/android/app/src/main/res/drawable/splash_logo.png")

    # Play feature graphic: 1024x500, teal field, tile on the left.
    graphic = Image.new("RGB", (1024, 500), (14, 107, 88))
    mark = cropped.resize((260, 260), Image.LANCZOS)
    graphic.paste(mark, (150, 120), mark)
    save(graphic, f"{LOGO}/feature-graphic-1024x500.png")

    preview = source.resize((320, 320), Image.LANCZOS)
    save(preview, ".icon-preview.png")


if __name__ == "__main__":
    main()

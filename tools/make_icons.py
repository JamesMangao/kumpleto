"""Draw the Kumpleto mark (folder + check) crisply at every size we ship.

One geometry, one palette, four outputs:
  * icons/icon-1024.png            full-bleed launcher (teal square, white mark)
  * icons/icon-foreground-1024.png adaptive foreground (transparent, safe zone)
  * icons/icon-monochrome-1024.png themed icon silhouette
  * assets/logo/app-icon.png       in-app logo (rounded teal card)
"""
import io
import os

from PIL import Image, ImageDraw

TEAL = (14, 107, 88, 255)  # #0E6B58
WHITE = (255, 255, 255, 255)
SS = 4  # supersample factor for smooth edges


def draw_mark(size, box):
    """Return an RGBA image with the white folder+check drawn inside `box`."""
    canvas = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    x, y, w, h = [v * SS for v in box]

    # Folder tab and body, proportioned from the 1024 master.
    tab_h = h * 0.42
    draw.rounded_rectangle(
        [x + w * 0.02, y, x + w * 0.50, y + tab_h],
        radius=w * 0.09,
        fill=WHITE,
    )
    draw.rounded_rectangle(
        [x, y + h * 0.24, x + w, y + h],
        radius=w * 0.13,
        fill=WHITE,
    )

    # Check: three points, round caps and joins.
    stroke = w * 0.115
    p1 = (x + w * 0.27, y + h * 0.68)
    p2 = (x + w * 0.43, y + h * 0.86)
    p3 = (x + w * 0.75, y + h * 0.42)
    for a, b in ((p1, p2), (p2, p3)):
        draw.line([a, b], fill=TEAL, width=int(stroke))
    for point in (p1, p2, p3):
        r = stroke / 2
        draw.ellipse(
            [point[0] - r, point[1] - r, point[0] + r, point[1] + r],
            fill=TEAL,
        )
    return canvas.resize((size, size), Image.LANCZOS)


def save(image, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, "PNG", optimize=True)
    print(f"wrote {path} ({os.path.getsize(path) // 1024} KB)")


# --- launcher: full-bleed square (Android masks it) -------------------------
launcher = Image.new("RGBA", (1024, 1024), TEAL)
mark = draw_mark(1024, (1024 * 0.235, 1024 * 0.315, 1024 * 0.53, 1024 * 0.33))
launcher = Image.alpha_composite(launcher, mark)
save(launcher, "app/icons/icon-1024.png")

# --- adaptive foreground: mark inside the 66% safe zone --------------------
foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
mark = draw_mark(1024, (1024 * 0.30, 1024 * 0.36, 1024 * 0.40, 1024 * 0.25))
foreground = Image.alpha_composite(foreground, mark)
save(foreground, "app/icons/icon-foreground-1024.png")
save(foreground, "app/icons/icon-monochrome-1024.png")

# --- in-app logo: rounded teal card ---------------------------------------
card = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
ImageDraw.Draw(card).rounded_rectangle(
    [0, 0, 1023, 1023], radius=240, fill=TEAL
)
mark = draw_mark(1024, (1024 * 0.235, 1024 * 0.315, 1024 * 0.53, 1024 * 0.33))
card = Image.alpha_composite(card, mark)
save(card.resize((512, 512), Image.LANCZOS), "app/assets/logo/app-icon.png")

# --- native splash logo (pre-Android 12 window background) -----------------
splash = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
mark = draw_mark(768, (768 * 0.27, 768 * 0.34, 768 * 0.46, 768 * 0.28))
splash = Image.alpha_composite(splash, mark)
save(splash, "app/android/app/src/main/res/drawable/splash_logo.png")

# --- feature graphic keeps its aspect ratio but uses the new mark ----------
graphic = Image.new("RGBA", (1024, 500), TEAL)
mark = draw_mark(500, (120, 110, 260, 280))
graphic = Image.alpha_composite(graphic, mark)
save(graphic, "app/icons/feature-graphic-1024x500.png")

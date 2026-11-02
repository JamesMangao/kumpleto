"""Make app/assets/logo/app-icon.png the single source of truth for the mark.

The master artwork was replaced by the project owner, so everything derives
from it: legacy launcher mipmaps, the adaptive icon (same image, inset into the
safe zone, background sampled from the artwork), the in-app logo and the splash.
"""
import io
import os
import shutil

from PIL import Image

LOGO = "app/assets/logo"
MASTER = f"{LOGO}/app-icon.png"

image = Image.open(MASTER).convert("RGBA")

# Adaptive background sampled from the artwork's corner, so the circle behind
# the inset logo matches the logo instead of fighting it.
corner = image.convert("RGB").getpixel((2, 2))
hex_color = "#{:02X}{:02X}{:02X}".format(*corner)
print("sampled background:", hex_color)

# Play-store sized copies.
image.resize((512, 512), Image.LANCZOS).save(f"{LOGO}/app-icon-512.png", optimize=True)
print("wrote", f"{LOGO}/app-icon-512.png")
shutil.copyfile(
    "app/icons/feature-graphic-1024x500.png",
    f"{LOGO}/feature-graphic-1024x500.png",
)
print("wrote", f"{LOGO}/feature-graphic-1024x500.png")

# Small preview for a visual check.
image.resize((320, 320), Image.LANCZOS).save(".icon-preview.png")
print("wrote .icon-preview.png")

# --- pubspec: launcher icons come from assets/logo -------------------------
pubspec = "app/pubspec.yaml"
text = io.open(pubspec, encoding="utf-8", newline="").read()
start = text.index("# Launcher icon generation")
new_block = f"""# Launcher icon generation. The single source of truth for the brand mark is
# app/assets/logo/app-icon.png — the same file the app shows in-app and the
# splash uses. Replace that one file, then run:
#   dart run flutter_launcher_icons
flutter_launcher_icons:
  android: true
  # No iOS target in this repo (Android-only release).
  ios: false
  image_path: "assets/logo/app-icon.png"
  adaptive_icon_background: "{hex_color}"
  # The master is a full-bleed square, so the adaptive layer reuses it and
  # insets it into the 66% safe zone rather than a separate cut-out layer.
  adaptive_icon_foreground: "assets/logo/app-icon.png"
  adaptive_icon_foreground_inset: 16
"""
text = text[:start] + new_block
io.open(pubspec, "w", encoding="utf-8", newline="").write(text)
print("pubspec launcher block rewritten")

# --- docs point at the new home -------------------------------------------
replacements = {
    "app/icons/icon-512.png": "app/assets/logo/app-icon-512.png",
    "app/icons/feature-graphic-1024x500.png": "app/assets/logo/feature-graphic-1024x500.png",
    "app/icons/icon-1024.png": "app/assets/logo/app-icon.png",
    "app/icons/icon-foreground-1024.png": "app/assets/logo/app-icon.png",
    "app/icons/": "app/assets/logo/",
}
for path in [
    "docs/PLAY_RELEASE.md",
    "docs/REMAINING_WORK.md",
    "TODO.md",
]:
    if not os.path.exists(path):
        continue
    doc = io.open(path, encoding="utf-8", newline="").read()
    original = doc
    for old, new in replacements.items():
        doc = doc.replace(old, new)
    if doc != original:
        io.open(path, "w", encoding="utf-8", newline="").write(doc)
        print("updated", path)

# --- drop the superseded duplicates ---------------------------------------
for stale in [
    "app/icons/icon-1024.png",
    "app/icons/icon-foreground-1024.png",
    "app/icons/icon-monochrome-1024.png",
    "app/icons/icon-512.png",
    "app/icons/feature-graphic-1024x500.png",
]:
    if os.path.exists(stale):
        os.remove(stale)
        print("removed", stale)

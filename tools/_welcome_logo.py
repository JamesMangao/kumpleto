"""The welcome scene draws the brand mark with a painter. Now that the artwork
lives in app/assets/logo, use the same widget the rest of the app uses."""
import io
import sys

path = "app/lib/screens/welcome_screen.dart"
text = io.open(path, encoding="utf-8", newline="").read()

old = """                    Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: 148,
                          height: 148,
                          child: CustomPaint(
                            painter: _BrandMarkPainter(checkProgress: check),
                          ),
                        ),
                      ),
                    ),"""
new = """                    Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: const KumpletoLogo(size: 132, radius: 32),
                      ),
                    ),"""
if text.count(old) != 1:
    print(f"FAIL mark block: {text.count(old)}")
    sys.exit(1)
text = text.replace(old, new)

# The check-drawing progress is no longer used.
old_check = "    final check = _segment(0.30, 0.68);\n"
if text.count(old_check) != 1:
    print(f"FAIL check var: {text.count(old_check)}")
    sys.exit(1)
text = text.replace(old_check, "")

# Drop the painter entirely.
start = text.index("/// Vector Kumpleto mark")
text = text[:start].rstrip() + "\n"

if "widgets/shared.dart" not in text:
    text = text.replace(
        "import '../l10n/app_localizations.dart';",
        "import '../l10n/app_localizations.dart';\nimport '../widgets/shared.dart';",
        1,
    )

io.open(path, "w", encoding="utf-8", newline="").write(text)
print("welcome uses the shared logo")

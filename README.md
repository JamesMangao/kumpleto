# Kumpleto

**Unofficial.** Kumpleto is an offline-first Android app that keeps a
community-maintained checklist of Philippine government document
requirements — NBI clearance, PSA certificates, passport, national ID, and
more — plus life-event bundles (Job Hunt Pack, First Passport, New Driver,
Renew Expired ID).

> **Disclaimer:** Kumpleto is **not** a government app and is **not
> affiliated with any government agency**. Requirements and fees change.
> Always confirm with the official agency website (linked inside every
> document entry) before you apply. See [DISCLAIMER.md](DISCLAIMER.md).

## Why

Preparing Philippine government documents usually means scattered PDFs,
forum posts, and word of mouth. Kumpleto gathers the *requirements*, *steps*,
and *official source link* for each document into one checklist you can tick
off — fully usable **offline**, with **no accounts, no analytics, and no ads**.

## Features

- ✅ Per-document requirement checklists (originals, photocopies, optionals)
- 📦 Life-event bundles with per-document and overall progress
- 🌐 English + Filipino interface and content
- 📴 Works 100% offline on first launch (data bundled as an asset)
- 🔄 Silent data refresh from a public JSON feed — no app release needed
- 🔒 No accounts, no analytics, no crash reporting, no data leaves your device
- ♿ TalkBack labels, 48dp touch targets, works at 200% font size

## Build (development)

Prerequisites: Flutter (see `.fvmrc` for the pinned version), Android SDK
with platform 36, JDK 17+.

```powershell
# 1. Compile the data (repo root)
dart pub get
dart run tools/validate.dart          # schema + semantic validation
dart run tools/build_data.dart        # writes dist/ + app/assets/data/data.json

# 2. Run the app (app/)
cd app
flutter pub get
flutter run --flavor dev              # debug; shows drafts too if generated
```

To include draft entries for development:

```powershell
dart run tools/build_data.dart --include-drafts   # gitignored dev asset
flutter run --flavor dev
```

Release build (never contains drafts):

```powershell
cd app
flutter build appbundle --flavor prod --release
```

Tests:

```powershell
dart test tools/test  # tool tests (repo root)
cd app && flutter test # app tests
```

## Data contribution flow

1. All content lives in `data/**.yaml` — see [docs/DATA_GUIDE.md](docs/DATA_GUIDE.md).
2. **Every factual field must cite an official source URL.** Never invent
   requirements, fees, processing times, or validity periods. If unsure,
   leave it `null` and keep `status: draft`.
3. Only a maintainer may set `status: verified` and `last_verified`.
4. CI validates every change (`tools/validate.dart --strict`); the app picks
   up new data through the public feed without a Play release.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

## Screenshots

_Placeholder — screenshots will be added before the Play release._

## Privacy

No data is collected. The only network request is fetching the public
data bundle. See [PRIVACY.md](PRIVACY.md).

## License

- Source code: [MIT](LICENSE)
- Content under `data/`: [CC BY 4.0](LICENSE-DATA)

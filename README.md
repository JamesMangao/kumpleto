# Kumpleto

**Unofficial.** Kumpleto is an offline-first Android app that keeps an
independently maintained checklist of Philippine government document
requirements — NBI clearance, PSA certificates, passport, national ID, LTO
licences and permits, DTI business names, PRC licences, and more — plus
life-event bundles (Job Hunt Pack, First Passport, New Driver, Renew Expired
ID, Kasal, Senior & PWD Benefits, Overseas Travel).

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
- 👥 Per-person checklists — add the other people you file for, each with its
  own saved barangay, city and postal code
- 📦 Life-event bundles with per-document and overall progress
- 🌐 English + Filipino interface and content
- 📴 Works 100% offline on first launch (data bundled as an asset)
- 🔄 Silent data refresh from a public JSON feed — no app release needed
- 🔍 Search runs through requirements, steps, fees and notes, not just titles
- 🔗 Deep links per document and bundle (`kumpleto://doc/<id>`,
  `kumpleto://bundle/<id>`) plus published `https` checklist pages for sharing
- 🔳 QR sharing: one code, two targets — the offline `kumpleto://` link by
  default, or the public page for a phone without the app
- 📅 Expiry dates export to the phone's own calendar as an `.ics` file, written
  in `Asia/Manila` at 09:00 with 30- and 7-day alarms (an all-day event would
  fire at local midnight and never be seen)
- 🔔 Expiry reminders a month, a week and a day before an acquired document
  lapses (off until you switch it on in Settings, which is when the OS
  notification permission is asked for)
- 🏠 Home-screen widget showing the document that expires next and how many you
  have marked; tapping it opens the app
- 🔒 No accounts, no analytics, no crash reporting, no data leaves your device
- ♿ TalkBack labels, 48dp touch targets, works at 200% font size

## Release status

**Version 1.0.0 (versionCode 1)** — first public release.

- Artifacts from `flutter build apk --flavor prod --release --split-per-abi`
  and `flutter build appbundle --flavor prod --release`:
  `app/build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk` (25.1 MB),
  `app-armeabi-v7a-prod-release.apk` (22.7 MB) and
  `app-x86_64-prod-release.apk` (26.5 MB) for sideloading and QA, plus
  `app/build/app/outputs/bundle/prodRelease/app-prod-release.aab`
  (the Play upload format, 63.0 MB on disk; Play delivers one ABI per device).
- Release builds are obfuscated (`--obfuscate --split-debug-info=build/symbols`).
  Keep `build/symbols/` for de-obfuscating a crash report; it is gitignored.
- A release build carries the verified dataset only — 46 documents, 9 bundles,
  26 agencies. Draft entries never ship, and the bundled `data.json` hash must
  equal `dist/data.json`.
- Every artifact was rebuilt on 2026-11-09 with the current dataset, the new
  welcome-scene logo and obfuscation on; their bundled `data.json` matches
  `dist/data.json` byte for byte. They stay debug-signed until
  `app/android/key.properties` exists, so sign with the upload key before any
  Play upload — see §2 of [docs/PLAY_RELEASE.md](docs/PLAY_RELEASE.md).
- Store signing: the AAB is signed with the upload key only when
  `app/android/key.properties` exists; otherwise it stays debug-signed for QA
  and cannot be uploaded. See [docs/PLAY_RELEASE.md](docs/PLAY_RELEASE.md) §2.

- The 2026-11-11 work adds the home-screen widget, the QR web/app toggle,
  calendar exports at 09:00 `Asia/Manila`, Open Graph tags on the public pages
  and a fix for the home-screen error card. The v1.0.0 artifacts above predate
  them: bump `version` and rebuild `--split-per-abi` plus the AAB before the
  next upload.

## Build (development)

Prerequisites: Flutter (see `.fvmrc` for the pinned version), Android SDK
with platform 36, JDK 17+.

```powershell
# 1. Compile the data (repo root)
dart pub get
dart run tools/validate.dart          # schema + semantic validation
dart run tools/build_data.dart        # writes dist/ + app/assets/data/data.json
dart run tools/build_site.dart        # writes site/ (pages, sitemap, robots, 404)

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
2. **Every factual field must cite an official `.gov.ph` source URL.** Never
   invent requirements, fees, processing times, or validity periods. If
   unsure, leave it `null` and keep `status: draft`.
3. Only a maintainer may set `status: verified` and `last_verified`.
4. CI validates every change (`tools/validate.dart --strict`); the app picks
   up new data through the public feed without a Play release.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

## Screenshots

Real captures from the app running on an Android phone (1080 × 2400, cropped
to drop the system navigation bar). The same four are the Play listing shots.

![Kumpleto welcome, home and bundle screens](docs/screenshots/overview.webp)

| Home | Life-event bundle |
|---|---|
| <img src="docs/screenshots/home.webp" width="300" alt="Home screen with search and life-event bundle cards showing progress"> | <img src="docs/screenshots/bundle.webp" width="300" alt="Job Hunt Pack bundle with progress ring, estimated cost and RA 11261 toggle"> |
| Search, ten curated categories, one-tap chips for the most-looked-up documents, and the date the offline data was compiled. Documents filters by tag, agency and whether you already have it. | One bundle: documents in order, overall progress, estimated cost range, and the first-time jobseeker fee-waiver toggle. |

| Document checklist | Welcome |
|---|---|
| <img src="docs/screenshots/document.webp" width="300" alt="PSA Birth Certificate checklist with original and optional requirement tags"> | <img src="docs/screenshots/welcome.webp" width="300" alt="Welcome screen stating offline, no account and no ads"> |
| Requirements tagged original or optional, the official source link, and the sticky "I already have this document" bar. | First launch: what the app is, and the three promises — offline, no account, no ads. |

## Privacy

No data is collected. The only network request is fetching the public
data bundle. See [PRIVACY.md](PRIVACY.md).

## License

**Proprietary — all rights reserved.** The source code, the content under
`data/`, and the compiled data are the exclusive property of James Mangao. No
permission is granted to copy, redistribute, modify, or build derivative works
from them without prior written permission. See [LICENSE](LICENSE) and
[LICENSE-DATA](LICENSE-DATA).

Third-party libraries keep their own licences; those are listed in the app
under Settings → Open-source licenses.

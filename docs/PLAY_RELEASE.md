# Play release — Kumpleto

How to take the app from a clean checkout to a Play Console upload. Everything
in `app/android/` that is secret (`key.properties`, `*.jks`, `*.keystore`,
`google-services.json`) is already covered by the root `.gitignore` and
scanned by `.github/workflows/gitleaks.yml` — keep it that way.

> **Kumpleto is unofficial.** The disclaimer is the first line of every store
> field below; do not ship listing copy that reads like an agency product.

---

## 1. Upload keystore (human, once)

The **upload key** signs the AAB you send to Play; Play re-signs with its own
**app signing key** before distributing.

```powershell
keytool -genkeypair -v `
  -keystore %USERPROFILE%\kumpleto-upload.jks -keyalg RSA -keysize 2048 `
  -validity 10000 -alias kumpleto-upload
```

* Store it **outside the repo** (or as `app/android/upload-keystore.jks` — the
  `*.jks` rule keeps it out of git anyway).
* Back up the `.jks` and its passwords: losing the upload key means asking
  Google to reset it.
* Never commit it, never paste it into an issue, PR or chat.

## 2. `app/android/key.properties`

Create this file next to `build.gradle.kts` (gitignored — it never shows up in
`git status`):

```properties
storeFile=C:/Users/<you>/kumpleto-upload.jks
storePassword=<the keystore password>
keyAlias=kumpleto-upload
keyPassword=<the key password>
```

`app/android/app/build.gradle.kts` loads this file when it exists and wires it
to the `release` signing config; when it is **absent** the release build falls
back to the debug key, which is why CI and a fresh clone can still run
`flutter build appbundle --flavor prod --debug`.

## 3. Play App Signing (human, once)

1. Create the app in Play Console (`io.github.jamesmangao.kumpleto`).
2. Enrol in **Play App Signing** and upload an AAB — Play generates and holds
   the **app signing key**; your `.jks` stays the **upload key**.
3. Download Play's app-signing public certificate and keep it with the
   keystore backup.
4. If the upload key is ever compromised, use Play Console → *Setup* →
   *App signing* → request an upload key reset; users are unaffected.

## 4. Version policy

`app/pubspec.yaml` is the single source of truth:

```yaml
version: 1.0.0+1   # versionName 1.0.0 · versionCode 1 (first release)
```

* **versionCode must strictly increase for every Play upload.** Bump the `+N`
  part for every release, including internal/closed-testing reruns.
* **versionName** follows semver for humans: patch for data-only and bug-fix
  releases, minor for new screens/features, major for a breaking rewrite.
* CI builds the same `versionName`; the debug AAB CI uploads as an artifact is
  for installability testing only, never for a Play upload.

## 5. Build the release AAB

```powershell
dart run tools/validate.dart --strict-on=errors   # data must be clean
dart run tools/build_data.dart                    # -> dist/data.json + app asset
cd app
flutter pub get
flutter build appbundle --flavor prod --release
```

Output: `app/build/app/outputs/bundle/prodRelease/app-prod-release.aab`
(signed with `key.properties` when present).

`--flavor prod` is mandatory: only the `prod` flavor is store material, and the
release pipeline must never run `build_data.dart --include-drafts`.

## 6. AAB audit (acceptance, every release)

```bash
AAB=app/build/app/outputs/bundle/prodRelease/app-prod-release.aab

# 1. Draft data must not be in the bundle.
unzip -Z1 "$AAB" | grep -i data_drafts.json && echo "FAIL: drafts leaked" || echo "OK: no drafts"

# 2. Bundled data must be byte-identical to the published feed.
ENTRY="$(unzip -Z1 "$AAB" | grep 'assets/data/data.json$' | head -1)"
unzip -p "$AAB" "$ENTRY" | sha256sum
sha256sum dist/data.json

# 3. Signed with the upload key (after step 2 exists).
keytool -printcert -jarfile "$AAB"
```

All three must pass before the upload. Unzip the AAB and eyeball
`assets/` while you are there — it is a thirty-second check that catches a
stale `app/assets/data/data.json`.

## 7. Store listing copy

Paste as-is; every field leads with the disclaimer (Play: title ≤ 30,
short description ≤ 80, full description ≤ 4000 characters).

**Title (27):**

```
Kumpleto: PH Docs Checklist
```

**Short description (67):**

```
Unofficial offline checklists for Philippine government documents.
```

**Full description:**

```
Kumpleto is an UNOFFICIAL checklist app for Philippine government documents.
It is not affiliated with, endorsed by, or maintained by any government
agency. Always confirm requirements on the official agency website before you
apply — the app links to each official source so you can.

What it does
• Step-by-step checklists for NBI clearance, PSA certificates, passport
  applications, SSS, PhilHealth, Pag-IBIG, LTO and more.
• Requirements marked original, photocopy or optional, plus steps, fees and
  where to apply.
• Life-event bundles: get one list for a job hunt, a first passport, or a
  new driver's licence.
• Tick progress as you go — it is stored on your device and works offline.
• English and Filipino (Tagalog).

What it does not do
• No applications, no payments, no personal data collected, no account.
• No government logos, seals or branding.

Every entry shows an "Unverified" badge until a maintainer has checked it
against the official source, with the date of that check.
```

**Release notes** (Play's "What's new" field, ≤ 500 characters) are drafted
per upload from `git log` since the previous versionCode. There is no
`CHANGELOG.md` in this repo by design (decision G3) — this field and the git
history are the release record.

## 8. Graphics

| Asset | Size | Notes |
| --- | --- | --- |
| App icon (Play) | 512 × 512 PNG | same artwork as the launcher icon |
| Feature graphic | 1024 × 500 | no agency branding |
| Phone screenshots | ≥ 2, taken on a physical device | USB debugging, `flutter run --flavor prod` |

Artwork rules (decision U1): **checkmark + folder motif**; explicitly no flags,
seals, sun/stars, eagles or agency branding. The launcher icon is generated
with `flutter_launcher_icons` from the same source artwork.

All artwork lives in `app/assets/logo/` and is ready to upload as-is:

| File | Use |
| --- | --- |
| `app/assets/logo/app-icon-512.png` | 512 × 512 Play store icon |
| `app/assets/logo/feature-graphic-1024x500.png` | 1024 × 500 feature graphic |
| `app/assets/logo/app-icon.png` | source artwork (legacy launcher mipmap) |
| `app/assets/logo/app-icon.png` | adaptive/monochrome foreground layer |

To regenerate the Android mipmaps and adaptive layers after changing the
source artwork:

```bash
cd app && dart run flutter_launcher_icons
```

## 9. Closed testing

Play requires **12+ testers opted in for 14 continuous days** before a new
personal account can release publicly. Track it in `TODO.md`; the testers opt
in through the internal/closed testing track link, not by installing the AAB
by hand.

## 9b. Size audit — updated 2026-11-09 (1.0.0, prod flavor)

> **Rebuilt 2026-11-09 with the current dataset.** Both artifacts carry the
> 46-document dataset (bundled `data.json` sha256 `3112cecf…`) and the new
> welcome-scene logo, and neither contains `data_drafts.json`. They stay
> **debug-signed** until `android/key.properties` exists, so sign with the
> upload key per §2 before uploading.

`flutter build apk --flavor prod --release --split-per-abi` (obfuscated) →
three sideload APKs, `versionName 1.0.0`, `versionCode 1`, `minSdk 24`,
`targetSdk 36`, `compileSdk 36` (confirmed with `aapt dump badging`):

| Split | Bytes | Flutter report |
| --- | --- | --- |
| `app-arm64-v8a-prod-release.apk` | 26,268,812 | 25.1 MB |
| `app-armeabi-v7a-prod-release.apk` | 23,776,214 | 22.7 MB |
| `app-x86_64-prod-release.apk` | 27,786,077 | 26.5 MB |

A universal APK (`--split-per-abi` omitted) stays available as a QA artifact
but is three engine copies at ~70 MB; share a split instead. Unpacked sizes:

| Bucket | Size | Contents |
| --- | --- | --- |
| `lib/` (native) | 67.3 MB | `libflutter.so` + `libapp.so` + `libsqlite3.so`, three times (one per ABI) |
| assets | 2.4 MB | launcher/logo PNGs 1.78 MB, PSGC place shards 0.51 MB, `data.json` 0.16 MB |
| `classes.dex` | 1.2 MB | app + plugin classes (desugared) |
| `res/` | 0.6 MB | mipmaps, launcher icons |

Per ABI: x86_64 26.5 MB, arm64-v8a 25.1 MB, armeabi-v7a 22.7 MB (obfuscated).

`flutter build appbundle --flavor prod --release` → `app-prod-release.aab`,
**66,011,186 bytes (63.0 MiB)** on disk for the same obfuscated 1.0.0 build;
Play splits it per device. Both builds pass
`--obfuscate --split-debug-info=build/symbols`; keep the symbols directory to
symbolise a stack trace later (it is gitignored).

Reading: the app's own payload is ~4 MB — the download is three copies of the
Flutter engine. Ship the App Bundle (§5) so Play delivers ~23 MB to a phone
instead of 72.1 MB; the universal APK stays a sideload/QA artifact. Both
artifacts on disk carry `data.json` hashing `3112cecf…`, matching
`dist/data.json` byte for byte (§6 audit run 2026-11-09); no draft asset leaked
into either of them.

> **2026-11-11 — the numbers above are 1.0.0.** A debug build of the current
> tree (236,770,372 bytes) also carries the home-screen widget, the QR web/app
> toggle, the 09:00 `Asia/Manila` calendar export, the Open Graph tags on the
> public pages and the home-screen error fix. Re-run §5 and §6 with a bumped
> `version` before uploading; do not publish the 1.0.0 artifacts.

## 10. Release checklist

1. `dart run tools/validate.dart --strict-on=errors` passes.
2. Data verified entries reviewed; `status: verified` set only by the human
   maintainer (decision G2).
3. Bump `app/pubspec.yaml` `version: x.y.z+N`.
4. Build per §5, audit per §6.
5. Play Console → testing track → create release → upload the AAB.
6. Fill listing per §7 (disclaimer first), upload graphics per §8.
7. Roll out to closed testing first; promote to production only after the
   rollout has had no crash spike.

## 11. Shared links and the public checklist pages

`tools/build_site.dart` turns `dist/data.json` into the public site the Pages
workflow deploys: `data.json` stays at the root for the app's update feed, and
every document and bundle also gets a static page (`/doc/<id>`, `/bundle/<id>`)
plus `sitemap.xml`, `robots.txt` and a `404.html`. Run it after
`tools/build_data.dart`.

The app answers to those `https` links through the second intent-filter in
`AndroidManifest.xml`, but **without `autoVerify`**: Android will offer Kumpleto
as one of the apps for `https://jamesmangao.github.io/kumpleto/doc/...` and the
reader can set it as the default. Verifying the domain (silent open) requires
`/.well-known/assetlinks.json` at the *origin root*, which a project Pages site
cannot serve. Add that file and `android:autoVerify="true"` only after the
project moves to a custom domain such as `kumpleto.ph`, and generate the file
from the upload certificate's SHA-256:

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload | grep SHA256
```

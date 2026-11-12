# Remaining Work — Kumpleto

Master checklist of everything **not yet done** (as of 2026-10-15, after P2 was
committed and pushed). Phases are done in order; each phase is committed
separately with a Conventional Commit message.

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## P3 — App core [x] done (analyze clean · 190 app tests green · 25/25 tool tests)

> Done so far: `drift`, `sqlite3_flutter_libs`, `crypto`, `path_provider`
> added to `app/pubspec.yaml`; `drift_dev` + `build_runner` added as dev deps.
> Host `sqlite3.dll` for tests located at `C:\Python314\DLLs\sqlite3.dll`.

### Models & parsing

- [x] `lib/models/models.dart` — `Agency`, `Requirement`, `Document`,
      `Bundle`, `DataBundle` classes with tolerant `fromJson` (draft entries
      omit optional fields → null defaults; bilingual fallback `fil` → `en`)
- [x] `lib/models/localized_text.dart` — `LocalizedText {en, fil}` + picker
      by locale with English fallback

### Integrity (mirror of the tooling logic, app-side)

- [x] `lib/core/canonical.dart` — `canonicalize()` (recursively sorted keys),
      `sha256OfJson()`, `verifyDataJson()` — port of
      `lib/src/canonical.dart` from the repo-root tooling

### Bundled data + cache repository

- [x] `lib/data/data_repository.dart`
  - Load release asset `assets/data/data.json` via `rootBundle`
  - Parse + verify (sha256, `schema_version` gate)
  - Read/write cache file in app documents dir (`path_provider`)
  - Pick **newer** `data_version` (asset vs cache); corrupt/unverifiable
      cache is ignored, never crashes
- [x] `lib/data/app_paths.dart` — documents dir + DB/cache file paths
      (single place, so tests can inject temp dirs)

### Silent update service

- [x] `lib/data/update_service.dart`
  - HTTPS-only URL check (reject http before sending)
  - `If-None-Match` from stored ETag; store new ETag on success
  - **Manual redirect loop**, max **3** hops, each hop must be https
      (so the limit is unit-testable — don't rely on `followRedirects`)
  - Body cap: abort if `Content-Length` > 2 MB **or** streamed total
      exceeds 2 MB
  - 10 s overall timeout
  - Result type: `notModified` / `updated(body)` / `invalid(reason)` /
      `failed(reason)`
- [x] Non-blocking trigger after app start: check at most once per 24 h
      (persist `last_data_check` ms + `last_data_etag` in
      `SharedPreferences`); on success → save cache → refresh providers.
      Failures are silent, never block the UI.

### Progress storage (drift)

- [x] `lib/data/progress.dart` — drift table
      `ProgressEntries(documentId, requirementId, checked, updatedAt)`,
      composite PK; `KumpletoDb` with `schemaVersion = 1`
- [x] Run `dart run build_runner build` → generate `progress.g.dart`
      (the generated file is **committed**)
- [x] `lib/data/progress_repository.dart`
  - `watchAll()` → stream of rows
  - `setChecked(documentId, requirementId, bool)`
  - `resetDocument(documentId)`, `resetAll()`
  - `pruneOrphans(validPairs)` — delete rows for documents/requirements
      that no longer exist in the loaded data bundle

### Providers + bootstrap

- [x] `lib/data/providers.dart` — Riverpod:
      `progressDbProvider`, `dataBundleProvider` (with overridable loader
      for tests), `documentsProvider`, `progressEntriesProvider`,
      `updateControllerProvider`
- [x] Wire `lib/main.dart` — async bootstrap (settings + open DB), keep
      first frame fast; data bundle resolves async with a loading state

### Tests (`app/test/`)

- [x] `models_test.dart` — draft parse, bilingual fallback, defaults
- [x] `canonical_test.dart` — same guarantees as the tooling's
- [x] `data_repository_test.dart` — asset vs cache selection:
      cache newer / cache older / corrupt cache / sha mismatch /
      newer `schema_version` rejected
- [x] `update_service_test.dart` — with `MockClient` (+ streaming):
      304 → notModified, 200 valid → updated, 200 bad JSON → invalid,
      500 → failed, oversize body → failed, >3 redirects → failed,
      http URL → rejected, hang → timeout
- [x] `progress_repository_test.dart` — toggle/watch/reset/prune against
      drift; **Windows sqlite3 bootstrap**: probe, else load
      `C:\Python314\DLLs\sqlite3.dll` via
      `sqlite3.overrideFor(OperatingSystem.windows, ...)`; no-op on
      Linux CI (system libsqlite3)

**P3 gates:** `flutter analyze` clean · `flutter test` green ·
`dart test tools/test` still 25/25.

---

## P4 — UI [x] done (screens, l10n, widget tests)

> Placeholder screens exist in `app/lib/screens/` — replace bodies, keep
> routes in `lib/router.dart`.

- [x] **Home** — search field, bundle cards with aggregate progress,
      "Continue" row (docs with partial progress), tag chips
- [x] **Documents** — search, agency/tag filters, status badges
      (draft = grey "Unverified", deprecated = "No longer valid" banner),
      progress summaries
- [x] **Document detail** — header chips (validity, online?, verified age:
      green ≤ 90 d, amber 91–180 d, red > 180 d — color **never** the only
      signal), requirements checklist (originals/photocopies/optionals),
      steps, fee/processing notes, official source link (`url_launcher`),
      "Report outdated info" link, progress bar, reset
- [x] **Bundle detail** — ordered documents, per-doc + overall progress
- [x] **Settings** — language (system/en/fil) and theme pickers, expiry
      reminders, reset progress (confirm dialog), my location, app version,
      about/disclaimer/privacy/licenses. Updates are silent and scheduled, so
      there is no manual "check for updates" button and no replay entry.
- [x] **Onboarding** — final copy polish (disclaimer + language, once)
- [x] **l10n** — every new string in **both** `app_en.arb` and
      `app_fil.arb`; regenerate with `flutter gen-l10n`
- [x] **Accessibility** — TalkBack labels on all interactive elements,
      ≥ 48 dp touch targets, AA contrast, verified at 200% text scale
      (`app/test/accessibility_test.dart`: tooltips/hints, 48 dp targets,
      and every screen + onboarding laid out at 200% on a 360×740 phone
      viewport — onboarding was made scrollable to pass)
- [x] Widget tests per screen (incl. first-run → onboarding flow,
      deprecated banner, accessibility spot-checks)

---

## P5 — Icons & store prep ([~] artwork + release doc + Pages done; human tasks open)

- [x] Launcher icon via `flutter_launcher_icons` (approved): **checkmark +
      folder motif**, no flag/seal/sun-stars, no agency branding;
      same artwork → 512×512 Play store icon + 1024×500 feature graphic
      (source art in `app/assets/logo/`; adaptive + monochrome layers generated)
- [x] `docs/PLAY_RELEASE.md` — keystore + `key.properties` (gitignored)
      setup, Play App Signing, versionName/versionCode policy, store
      listing copy (unofficial disclaimer in first lines)
- [x] `.github/workflows/pages-data.yml` — build data on push to `main`,
      deploy `dist/data.json` to **GitHub Pages** (source: *GitHub
      Actions* — Human TODO)
- [x] Enable GitHub Pages (source: GitHub Actions)
- [ ] Human TODOs: create upload keystore; Play Console account;
      upload the generated graphics; confirm "Kumpleto" name availability

---

## P6 — Release & CI ([~] CI workflows done; release AAB waits on the upload keystore)

- [x] `.github/workflows/ci.yml` — pinned SHAs, Flutter from `.fvmrc`:
      root `dart run tools/validate.dart --strict-on=errors`,
      `dart test tools/test`, then `app/`: `flutter analyze`,
      `flutter test`, `flutter build appbundle --flavor prod --debug`
- [x] `.github/workflows/stale-data.yml` — weekly:
      `dart run tools/stale_report.dart` → file issue when stale entries
      exist
- [x] `.github/workflows/gitleaks.yml` — secret scanning (local: gitleaks
      via winget)
- [ ] **Release AAB**: `flutter build appbundle --flavor prod --release`
- [x] **AAB audit** (acceptance): unzip AAB, assert
      `assets/data/data_drafts.json` is **absent**, assert bundled
      `data.json` sha256 matches `dist/data.json` (verified against the
      debug-signed prod bundle; same three commands in docs/PLAY_RELEASE.md §6)
- [x] Verify `app/build/app/outputs/bundle/prodRelease/*.aab` installable
      path documented for a physical device (USB debugging) — docs/PLAY_RELEASE.md §5

---

## Missing docs & governance files

- [x] `docs/DATA_GUIDE.md` — full schema reference for contributors
      (referenced by CONTRIBUTING.md, not yet written): YAML field tables,
      bilingual rules, source-URL rule, status lifecycle
- [x] `CHANGELOG` policy decision — none planned; note in DECISIONS.md

---

## Human-only tasks (recurring, also in TODO.md / DECISIONS.md)

- [x] Verify the **7 job-hunt documents first**, then the rest (see
      `TODO.md` priority list)
- [x] Verify RA 11261 fee-waiver details + official source before
      job-hunt-pack leaves draft
- [x] Promote entries `draft` → `verified` one by one — 46 of 46 documents
      and 9 of 9 bundles; the 2026-11-07 pass re-checked nine drafts, and the
      2026-11-08 pass added the FSIC, the BIR COR and the DFA apostille (see
      the pass logs in `TODO.md`); `student-to-driver` / `new-business` ship
      with them
- [x] Take 2+ phone screenshots on a physical device — four captures in
      `docs/screenshots/`, used in the README and ready for the Play listing
- [ ] Recruit 12+ testers for 14 continuous days of closed testing
- [x] Enable GitHub Pages (source: GitHub Actions) — live at
      https://jamesmangao.github.io/kumpleto/data.json (+ per-document pages);
      the last publish predates the 2026-11-11 build, so push to re-run it

---

## P7 — Sharing, widget and the public pages [~] code done, device checks open

- [x] Open Graph + Twitter tags on every generated page (`og:type` `website`
      for the index, `article` for a document or bundle) and one shared
      `site/og.png` copied from the store feature graphic
- [x] `sitemap.xml` `<lastmod>` from the payload's `data_version`, not "now"
      (which would claim a change on every deploy)
- [x] `robots.txt` with the `Sitemap:` line
- [x] `404.html`, so a mistyped or retired `/doc/<id>` lands on a real page
- [x] QR dialog with two targets: `kumpleto://doc/<id>` by default (it opens
      the checklist with no connection — the reason a code gets scanned at a
      counter) and the public page behind a chip, with a hint that it needs one
- [x] Calendar `.ics` exports as a timed 09:00 `Asia/Manila` event with an
      explicit `VTIMEZONE` (all-day events alarm at local midnight) plus 30-,
      7- and 1-day alarms
- [x] Home-screen widget: `home_widget` pushes three values, a native
      `RemoteViews` provider renders them, tapping opens the app;
      `previewLayout` on Android 12+, the launcher icon below it
- [x] Tests: calendar export, widget values, update-service ETag round-trip,
      WCAG AA contrast group
- [x] Welcome scene auto-dismisses on returning launches (`welcome_seen` was
      written but never used); the first launch still waits for Skip
- [ ] Pin the widget once on a physical phone and capture a screenshot — adb
      cannot add a widget to the launcher, so this needs a human tap
- [ ] Finish the real-device accessibility pass: reach the QR/share
      content-desc labels on document detail at 200% text, and hear TalkBack
      speech (its own tutorial kept stealing the taps in the automated run)
- [ ] At 200% text the welcome scene's promise chips sit below the fold; it
      scrolls, so nothing is unreachable — decide whether to shrink it there

### Settings cleanup — 2026-11-12

- [x] Dropped the manual "Check for updates" control. The silent, once-a-day
      `scheduledUpdateProvider` in `main()` is now the only update path, and the
      result notice on Home still reports an accepted payload.
- [x] Dropped "Replay introduction & disclaimer" and the now-unused
      `AppSettings.resetFirstRun()`; the disclaimer, privacy note and about page
      stay reachable from their own Settings rows.
- [x] Removed the six strings the two controls used from both ARBs, and the
      Settings goldens at 200% were regenerated for the shorter card.
- [x] Added the acquired / not-yet segmented filter to Documents, with the
      empty-state message following the filter instead of blaming a search.

### Home restructure — 2026-11-12

- [x] `lib/core/categories.dart`: ten curated categories (IDs, civil registry,
      work, driving, business, benefits, senior/PWD/solo parent, travel, land,
      taxes) with their own icons and tag sets; the tag dump moved to Documents.
- [x] Documents accepts `?tags=a,b,c` (categories) as well as `?tag=a` (chip),
      and its empty state follows the filter.
- [x] Popular-document chips under Home's search field: NBI, PSA birth, TIN, SSS.
- [x] `BundleCard` shared by Home and the new `/bundles` list: bar hidden until
      started, two lines reserved for the title, six bundles on Home.
- [x] Distinct bundle icons for business, overseas travel and student-driver.
- [x] "Updated <date> • Offline" on Home and "Last checked <date>" on bundles,
      read from `generated_at` and `last_verified`.
- [x] Profile chip: tooltip plus a sheet header explaining the switcher.
- [x] Goldens at 200% regenerated; the accessibility and golden walkers now
      scroll the lazily built home list instead of assuming the card exists.

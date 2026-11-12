# Kumpleto — Decision Log

Every non-obvious decision is recorded here with rationale, per the project's
"simplest default + log it" rule. Newest entries appended.

---

## 2026-10-15 — P0: Initial plan, environment, toolchain

### Environment recon (before setup)

| Item | Finding |
|---|---|
| Flutter / Dart | Not installed → installed **Flutter 3.47.7 stable** (Dart 3.13.5, rev `abaf9c5237`) at `D:\flutter` |
| JDK | Android Studio JBR **OpenJDK 21.0.10** at `C:\Program Files\Android\Android Studio\jbr` |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk`; platforms android-34, **android-36**, android-36.1; build-tools 34/36/36.1/37; cmdline-tools latest (13114758) installed at P0; all licenses accepted |
| Tooling | git 2.54, gh 2.100 (authed as `JamesMangao`), winget/choco available |
| Devices | No AVD/emulator system-images/connected device → UI verified via widget tests; real screenshots = Human TODO |
| Platform | Windows 11 24H2; locale en-PH |

**flutter doctor result (P0 gate): all green — "No issues found!"** (Flutter,
Windows, Android toolchain with SDK 36.1 + JDK 21, Chrome, VS Build Tools,
connected desktop/web devices, network).

### Toolchain decisions

- **T1 — Flutter pinned to 3.47.7** via `.fvmrc` (single source of truth; CI reads
  the same file). Rationale: reproducible CI and local builds; FVM optional later.
- **T2 — Permanent user env vars**: `ANDROID_HOME`/`ANDROID_SDK_ROOT` → SDK path;
  user `Path` += `D:\flutter\bin`. Rationale: every future shell/CI-parity build finds them.
  **Note**: `JAVA_HOME` should point to a full JDK 17+ for IDE Java language server support,
  not Android Studio's JBR. Remove or update `JAVA_HOME` if the "no usable Java executable" error appears.
- **T3 — SDK installed up front** (maintainer-approved change #2): cmdline-tools,
  `platforms;android-36`, licenses — before any Gradle build. No reactive installs.

### Repo & naming

- **N1 — Repo root = `D:\Kumpleto`** (no nested `kumpleto/` folder). Layout:
  `app/`, `data/`, `schema/`, `tools/`, `dist/`, `docs/`, `.github/`.
  Default branch: `main`.
- **N2 — GitHub repo `JamesMangao/kumpleto` (public).** Constants:
  owner `JamesMangao`, repo `kumpleto`, data URL
  `https://jamesmangao.github.io/kumpleto/data.json`.
- **N3 — Display name "Kumpleto"** (maintainer-confirmed): launcher label and
  Play Store title. No "App" suffix. Store description states "unofficial" in
  the first lines.
- **N4 — applicationId `io.github.jamesmangao.kumpleto`**, kept as a single
  easily-changed constant.

### Data & build pipeline

- **P1 — `sha256` = SHA-256 over canonical JSON** of
  `{schema_version, agencies, documents, bundles}` with **keys recursively
  sorted** (maintainer change #4). The app re-canonicalizes the received payload
  the same way before comparing. No self-reference, order-independent.
- **P2 — Data fetch hardening** (maintainer change #4): **HTTPS only**, max body
  **2 MB**, max **3 redirects**, 10 s timeout, ETag/If-None-Match; accept only
  `schema_version` ≤ app-supported, JSON parses, sha256 matches; else keep
  current data. Failures are silent and never block the UI.
- **P3 — Drafts are never bundled in release** (maintainer change #1).
  `tools/build_data.dart` always emits `dist/data.json` (release, drafts
  excluded) and `dist/data-with-drafts.json` (for dev). For dev builds only,
  `--include-drafts` writes a **gitignored** `app/assets/data/data_drafts.json`
  (declared via directory asset). Android flavors `dev`/`prod`;
  release AAB is built with `--flavor prod` and the **P6 audit unzips the AAB
  and asserts `data_drafts.json` is absent**. Note: Flutter pubspec has no
  native per-flavor asset declarations — this is emulated with the gitignored
  generated file + dev workflow; revisit if Flutter adds native support.
  `INCLUDE_DRAFTS` dart-define is honored in debug builds only.
- **P4 — `deprecated` documents stay visible in release** with a
  "No longer valid" banner; user progress rows are kept (maintainer change #5).
- **P5 — Release output is an AAB** (`flutter build appbundle --flavor prod
  --release`), versionName/versionCode from `pubspec.yaml` version.
- **P6 — Proprietary licence and `.gov.ph`-only sources** (maintainer
  direction, 2026-11-09). The repository is **all rights reserved** (no MIT, no
  CC BY); contributions are assigned to the owner. Every `source_url`,
  `apply_online_url` and agency `website` must be on an official `.gov.ph`
  domain, and `tools/validate.dart --strict` must exit zero with no warnings.

### Tooling & CI

- **C1 — Root `pubspec.yaml` is a pure-Dart tooling package** (`yaml`,
  `json_schema`, `test`) so `dart run tools/validate.dart` works from repo root;
  root `analysis_options.yaml` **excludes `app/**`** (maintainer change #3).
  **All `flutter` commands run inside `app/`** — acceptance criteria and CI
  steps use per-directory working paths accordingly:
  root → `dart pub get`, `dart run tools/validate.dart`, `dart run
  tools/build_data.dart`, `dart test`;
  `app/` → `flutter pub get`, `flutter analyze`, `flutter test`,
  `flutter build appbundle`.
- **C2 — CI on `ubuntu-latest`**, all tooling in Dart (Windows + Linux safe),
  actions pinned to full commit SHA, Flutter version read from `.fvmrc`.
- **C3 — gitleaks** in CI (`gitleaks/gitleaks-action`) and locally via winget;
  no secrets/keystores ever committed.

### App & UX

- **U1 — Launcher icon via `flutter_launcher_icons`** (approved extra package,
  maintainer change #6): **checkmark + folder motif**; explicitly no flags,
  seals, sun/stars, or agency branding. Same artwork generates the 512×512
  Play store icon.
- **U2 — Verification badge**: green ≤ 90 days, amber 91–180, red > 180,
  grey "Unverified" for draft; the age text ("Verified N days ago") is always
  shown — color is never the only signal.
- **U3 — i18n**: gen-l10n ARB files (en, fil) for UI; content strings are
  bilingual inside YAML; default locale = device, `fil` falls back to `en`.

### Contribution policy

- **G1 — Maintainer self-verifies** entries until outside contributors exist;
  the **2-reviewer rule for data PRs is retained as future policy** in
  CONTRIBUTING (maintainer change #7).
- **G2 — Only the human maintainer** may set `status: verified` /
  `last_verified`. Everything authored by the agent is `status: draft`
  and cites an official source URL or leaves fields null.
- **G3 — No `CHANGELOG.md`.** Releases are described by the Play release
  notes drafted at release time (docs/PLAY_RELEASE.md §7) and by git history;
  a hand-maintained changelog would duplicate both and drift. Revisit if a
  GitHub Releases page is ever published.

### P2 follow-up decisions (same day)

- **D-P2a — `kotlin.incremental=false`** in `app/android/gradle.properties`:
  the Kotlin 2.4.0 incremental compiler reproducibly failed with "Could not
  close incremental caches" on this Windows machine (2/2 builds), a known
  file-locking interaction. Non-incremental compilation is slower but
  reliable; first green dev build: 330 s.
- **D-P2b — Bundle `notes`**: the bundle schema was extended with an
  optional `notes: [{en, fil}]` list so the job-hunt-pack RA 11261 pointer
  (required by the spec) can live in the bundle draft itself.
- **D-P2c — `--strict` vs pagibig**: `--strict` intentionally fails on the
  two permanent non-`.gov.ph` warnings — `pagibigfundservices.com` (pag-ibig
  `apply_online_url`) and `pnpclearance.ph` (police-clearance
  `apply_online_url`), both official service domains; CI and the P2 gate use
  errors-only mode (`--strict-on=errors`, the documented default).
- **D-P2d — tool tests run as `dart test tools/test`**: the Dart CLI's
  pre-check ignores `dart_test.yaml` paths when no default `test/` dir
  exists at the root, so the explicit path is the canonical command
  (README/CONTRIBUTING/CI all use it).
- **D-P2e — extra packages approved by maintainer**: `crypto` (sha256; already
  a transitive dep of `http`), plus dev-only `drift_dev` + `build_runner`
  for P3 drift codegen.

### Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | SDK platform mismatch for API 36 | Resolved at P0: `platforms;android-36` + `android-36.1` installed, licenses accepted |
| R2 | AGP/Gradle vs compileSdk 36 | Verify generated template in P1 with a real `assembleDebug`/`bundle` run |
| R3 | drift/sqlite3 in `flutter test` on Windows host | Test bootstrap resolves `sqlite3.dll` (CI Linux has system libsqlite3); interface + fake store for pure unit tests |
| R4 | No device → no real screenshots | Human TODO: physical device via USB debugging |
| R5 | Pag-IBIG official site was `.com`, not `.gov.ph` | Resolved 2026-11-09: entries now cite `pagibigfund.gov.ph`; the validator is strict (0 warnings) |

### Living Human TODO list

- [ ] Verify the **7 job-hunt documents first** (maintainer change #8), then the rest
- [ ] Verify RA 11261 (First Time Jobseekers Assistance Act) fee-waiver details + source before job-hunt-pack leaves draft
- [ ] Create upload keystore + `key.properties` (gitignored) — never commit
- [ ] Open/confirm Play Console developer account
- [ ] Recruit 12+ testers for 14 continuous days of closed testing
- [ ] Take 2+ phone screenshots on a **physical device (USB debugging)**
- [ ] Prepare 512×512 store icon and 1024×500 feature graphic
- [ ] Confirm "Kumpleto" name availability on Play
- [x] Enable **GitHub Pages with source "GitHub Actions"** (maintainer change #8) — done; last publish predates the 2026-11-09 dataset
- [ ] Promote seed documents from `draft` to `verified` one by one, setting `last_verified` only via human review

---

## 2026-11-11 — Sharing, the widget, the public pages and a non-fatal data path

- **S1 — Social and crawl metadata on the static pages.** Every generated page
  carries Open Graph and Twitter tags, and one shared `og.png` (the store
  feature graphic) sits next to the pages so the absolute URL always resolves.
  `og:type` is `website` for the index and `article` for a document or bundle.
- **S2 — `<lastmod>` is the payload's `data_version`.** "Now" would claim every
  page changed on every deploy; the payload timestamp is the honest date.
- **S3 — `404.html`.** GitHub Pages serves it for any unknown path, so a
  retired `/doc/<id>` — or a QR printed for one — lands on a page that says so.
- **Q1 — QR has two targets, the offline one first.** `kumpleto://doc/<id>` is
  the default: a code shown in a barangay hall queue has to open the checklist
  with no data, and a page-shaped code only fails there. A chip switches to the
  public `https` page for a phone without the app, and the hint under the code
  says that variant needs a connection.
- **C1 — Calendar exports are timed events, not all-day.** `VALUE=DATE` hides
  the event at the top of the day and its alarm fires at local midnight, which
  nobody sees. Documents expire at 09:00 `Asia/Manila`, with an explicit
  `VTIMEZONE` so a phone in another region still fires at the right moment;
  alarms at 30, 7 and 1 days.
- **W1 — The widget renders only what Dart pushes.** `updatePeriodMillis=0`:
  no periodic wake-up, because the app already knows when the checklist
  changed. The three preference keys exist twice (Dart writer, Kotlin reader),
  each with a comment pointing at the other side.
- **W2 — `previewLayout` on Android 12+, `previewImage` below it.** Pickers on
  8–11 cannot inflate a `RemoteViews` preview, so they show the launcher icon
  rather than a blank square.
- **W3 — The widget's tap target opens `kumpleto://home`**, which the router
  deliberately does not map: a cold start from the widget lands on the normal
  first screen instead of a "page not found" error.
- **U4 — The welcome scene auto-dismisses on returning launches.** The first
  launch keeps the full ~3 s sequence and its Skip; afterwards `welcome_seen`
  (written but previously unused) also ends the compact scene by itself, and
  reduced motion never waits for a tap at all.
- **R1 — Nothing in the home data path may throw.** `SavedLocation.read` now
  catches every error (a stored value in an unknown shape means "no location
  saved") and `DataRepository._verify` guards verification and parsing as well
  as `jsonDecode` (an unreadable payload is a skipped candidate). Both feed the
  home screen's data provider, and a throw there stranded the UI on an error
  card whose Retry read the same bad value again.
- **D5 — The dark theme is slate-navy, not black, and not green-black.**
  `#0C1424` keeps the page distinct from the cards (`#151E31`), which is
  exactly what pure black erased; the same four steps the light theme has
  (page < card < raised < highest) survive in the new hue.
- **D6 — Body text is 87% white, not 100%.** `#DEFFFFFF` still clears WCAG AA
  by a wide margin while removing the halo that full white gives on a dark
  page. It is a single token, so the light theme is untouched.
- **D7 — The accent is mint on the dark page.** Brand teal `#0E6B58` is a fill
  colour that needs white text on it; as an icon or label on navy it is nearly
  unreadable. `accentColorOf(context)` returns `#5FD3B6` in dark and the brand
  teal in light, so foregrounds lighten while buttons and chips keep their
  dark fill and white labels.
- **F1 — Acquired / not-yet is a segmented filter on Documents, not a chip.**
  The tag and agency chips already reset through their own "All", so the
  acquired state gets its own three-way control above them; both read
  `isDocumentAcquired` from the checklist, so marking a document acquired
  moves it between the segments without a refresh. The empty message changes
  with the filter ("No documents in this filter.") instead of blaming a search
  that was never typed.
- **S1 — Updates are silent only.** The manual "Check for updates" button is
  gone: `scheduledUpdateProvider` already runs once a day at launch, writes the
  ETag, and the Home notice reports an accepted payload. A second, hand-run path
  only added a spinner, a result string and two failure modes to maintain. The
  update service itself is untouched.
- **S2 — The replay entry is gone too.** "Replay introduction & disclaimer"
  duplicated the disclaimer row that sits two lines above it, and re-entering
  first-run would re-ask for a language the reader already chose. The row and
  `AppSettings.resetFirstRun()` are removed; the disclaimer, privacy note and
  about page keep their own rows.
- **H1 — Ten curated categories replace "Browse by tag".** The feed's 81 tag
  slugs (`cfo`, `denr`, `board-exam`, `civil-registry`) are precise for data and
  useless as a front door. `lib/core/categories.dart` maps each friendly
  category to the tags that feed it, and the chip opens Documents with
  `?tags=a,b,c`; the full tag list stays on the Documents chip bar.
- **H2 — Four popular documents sit under the search field.** NBI, PSA birth,
  TIN and SSS are what readers arrive for one at a time, so they are chips that
  open the document directly instead of cards that need the bundle path.
- **H3 — A bundle's bar appears only after it is started, and every card
  reserves two title lines.** Eight identical "0 of N requirements" bars read as
  "nothing here"; the reserved height keeps a long title from shrinking its
  neighbour. Home shows six bundles (`homeBundleLimit`) so no card is stranded
  alone, and "See all >" opens the new `/bundles` list.
- **H4 — Every bundle icon is distinct.** `new-business` had `work` like
  `job-hunt-pack`, `overseas-travel` had `flight_takeoff` like
  `first-passport`, and `student-to-driver` had `directions_car` like
  `new-driver`; they are now `storefront`, `public` and `school`.
- **H5 — Freshness is visible.** Home prints "Updated <date> • Offline" from
  the feed's `generated_at` (new `DataBundle.generatedAt`), and a bundle header
  prints "Last checked <date>" from the newest `last_verified` among its
  documents. Feedback about stale requirements is only fair if the reader can
  see how old the copy is.
- **H6 — The "Me" chip explains itself.** Long-press shows the profile-switcher
  hint as a tooltip, and the sheet opens with the same sentence so the first
  tap does not leave the reader guessing what a name chip does.

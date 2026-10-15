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
- **T2 — Permanent user env vars**: `JAVA_HOME` → Android Studio JBR 21;
  `ANDROID_HOME`/`ANDROID_SDK_ROOT` → SDK path; user `Path` += `D:\flutter\bin`
  and JBR `bin`. Rationale: every future shell/CI-parity build finds them.
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

### Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | SDK platform mismatch for API 36 | Resolved at P0: `platforms;android-36` + `android-36.1` installed, licenses accepted |
| R2 | AGP/Gradle vs compileSdk 36 | Verify generated template in P1 with a real `assembleDebug`/`bundle` run |
| R3 | drift/sqlite3 in `flutter test` on Windows host | Test bootstrap resolves `sqlite3.dll` (CI Linux has system libsqlite3); interface + fake store for pure unit tests |
| R4 | No device → no real screenshots | Human TODO: physical device via USB debugging |
| R5 | Pag-IBIG official site is `.com`, not `.gov.ph` | `.gov.ph` check is warn-only by design |

### Living Human TODO list

- [ ] Verify the **7 job-hunt documents first** (maintainer change #8), then the rest
- [ ] Verify RA 11261 (First Time Jobseekers Assistance Act) fee-waiver details + source before job-hunt-pack leaves draft
- [ ] Create upload keystore + `key.properties` (gitignored) — never commit
- [ ] Open/confirm Play Console developer account
- [ ] Recruit 12+ testers for 14 continuous days of closed testing
- [ ] Take 2+ phone screenshots on a **physical device (USB debugging)**
- [ ] Prepare 512×512 store icon and 1024×500 feature graphic
- [ ] Confirm "Kumpleto" name availability on Play
- [ ] Enable **GitHub Pages with source "GitHub Actions"** (maintainer change #8)
- [ ] Promote seed documents from `draft` to `verified` one by one, setting `last_verified` only via human review

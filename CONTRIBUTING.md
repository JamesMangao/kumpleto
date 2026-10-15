# Contributing to Kumpleto

Thanks for helping keep this checklist accurate! Kumpleto is **unofficial**
and **offline-first**; its value comes entirely from carefully sourced,
community-maintained data.

## Setup

Prerequisites: Flutter (pinned in `.fvmrc`), Android SDK (platform 36),
JDK 17+.

```powershell
dart pub get                          # repo root (tooling)
dart run tools/validate.dart          # validate data
dart run tools/build_data.dart        # compile data -> dist/ + app asset
dart test                             # tool tests
cd app; flutter pub get; flutter test # app tests
```

## The source-URL rule (most important)

**Every factual field must come from an official source URL.**

- Never invent requirements, fees, processing times, validity periods, or links.
- If you are not sure, leave the field `null` and keep `status: draft`.
- Entries may only become `status: verified` when they have an official
  `source_url`, a `last_verified` date, and non-empty `requirements` and
  `steps`.
- Prefer official `.gov.ph` domains (the validator warns otherwise;
  Pag-IBIG's official site is pagibigfund.com).
- Prefer "see official site" over hard-copied fee numbers; include a number
  only with a `source_url` on the same entry.

## Who may set `verified`

**Only the human maintainer** sets `status: verified` and `last_verified`.
Contributor-authored entries are always `status: draft` — that is not a
demotion, drafts simply render with an "Unverified" badge until verified.

## Adding or updating a document

1. Copy the closest existing file in `data/documents/` (or see
   [docs/DATA_GUIDE.md](docs/DATA_GUIDE.md) for the full schema).
2. `id` must be kebab-case and equal the filename.
3. Provide **both** `en` and `fil` strings for every text field.
4. Run `dart run tools/validate.dart` — it must pass with no errors.
5. Open a PR using the checklist template.

## Review policy

- **Current (solo maintainer):** the maintainer self-reviews and merges;
  validator + CI are the second pair of eyes.
- **Future (once contributors exist):** data PRs require **two reviewer
  approvals**, at least one of whom is the maintainer, before merging.

## Code of conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities privately.

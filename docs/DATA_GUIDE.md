# Kumpleto Data Guide

Everything the app displays lives in `data/**.yaml`. This guide is the full
schema reference for contributors — the machine-readable definitions are
[schema/document.schema.json](../schema/document.schema.json),
[schema/bundle.schema.json](../schema/bundle.schema.json) and the agency
rules in `tools/validate.dart`; this document explains how they fit
together.

> **Rule zero: every factual field must cite an official source URL.**
> Never invent requirements, fees, processing times or validity periods.
> If you cannot confirm it from an official page, leave it out and keep
> `status: draft`. See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Layout

| Path | Contents |
|---|---|
| `data/agencies.yaml` | Registry of issuing agencies (id, bilingual name, official website) |
| `data/documents/*.yaml` | One file per document — filename must equal `id` |
| `data/bundles/*.yaml` | Life-event bundles (ordered document lists) |
| `schema/*.json` | JSON Schemas used by the validator and by editors |

## Bilingual text

Every user-visible string is an object with **both** languages required:

```yaml
name:
  en: NBI Clearance
  fil: NBI Clearance
```

- `en` must be a non-empty string; `fil` must be a non-empty string.
- The app renders `fil` for Filipino users and falls back to `en` for any
  other locale, so a missing `fil` at *runtime* degrades gracefully — but the
  schema rejects it at authoring time. Do not rely on the fallback.
- Do not translate agency names, acronyms or statute numbers
  (`NBI`, `Pag-IBIG`, `RA 11261` stay as written).

## Documents (`data/documents/<id>.yaml`)

Required fields: `schema_version`, `id`, `name`, `agency`, `status`.
Everything else is optional — draft entries are expected to be sparse.

| Field | Type | Notes |
|---|---|---|
| `schema_version` | `1` | Must be `1`. Bumped only by a breaking schema change. |
| `id` | kebab-case string | Must equal the filename without `.yaml`. |
| `name` | bilingual | Display name. |
| `agency` | kebab-case string | Key into `agencies.yaml`; unknown ids are an error. |
| `status` | `draft` \| `verified` \| `deprecated` | See [Status lifecycle](#status-lifecycle). |
| `summary` | bilingual \| null | One- or two-sentence description. |
| `source_url` | https URL \| null | The official page every factual field came from. |
| `last_verified` | `YYYY-MM-DD` \| null | **Maintainer-only.** |
| `verified_by` | string \| null | **Maintainer-only** GitHub handle. |
| `validity_months` | int ≥ 0 \| null | `0` means "no fixed expiry". |
| `apply_online` | bool \| null | `null` = unknown, not "no". |
| `apply_online_url` | https URL \| null | The agency's own portal. |
| `where_to_apply` | bilingual \| null | Office/branch guidance. |
| `depends_on` | list of document ids | Documents you need first; cycles are an error. |
| `tags` | list of kebab-case strings | Free-form, e.g. `job-hunt`, `renewal`. |
| `requirements` | list of requirement objects | The checklist. |
| `steps` | list of bilingual strings | Ordered procedure. |
| `fee_note` | bilingual \| null | Fees **with** `source_url` on the same entry. |
| `processing_note` | bilingual \| null | Typical wait time, with its source. |
| `notes` | list of bilingual strings | Community notes (sources, grace periods). |

### Requirement objects

```yaml
requirements:
  - id: valid-ids
    text:
      en: Two (2) valid government-issued IDs, original and not expired
      fil: Dalawang (2) valid na ID mula sa gobyerno, orihinal at hindi expired
    original: true        # optional, default false — must be presented as-is
    photocopies: 2        # optional, default 0
    optional: true        # optional, default false — "nice to have"
    note:                  # optional bilingual footnote
      en: Any unreadable ID will be refused.
      fil: Tatanggihan ang anumang nababasang ID.
```

- `id` is unique **within the document** and must be stable: user progress is
  keyed on `documentId/requirementId`, so renaming an id silently resets
  everyone's ticks for that line.
- Groupings that the schema does not model (originals / photocopies /
  optionals) are expressed through the three flags above, not headings.

## Bundles (`data/bundles/<id>.yaml`)

Required: `schema_version`, `id`, `name`, `description`, `status`,
`documents`.

| Field | Type | Notes |
|---|---|---|
| `documents` | ordered list of document ids | Every id must exist; a bundle is dropped from the release feed if any document is a draft. |
| `tags` | list of kebab-case strings | |
| `icon` | `^[a-z0-9_]+$` | Material icon name, e.g. `work`, `flight_takeoff`, `directions_car`. |
| `notes` | list of bilingual strings | Community notes, e.g. the RA 11261 fee-waiver pointer. |

## Agencies (`data/agencies.yaml`)

A list of:

```yaml
- id: nbi
  name:
    en: National Bureau of Investigation
    fil: National Bureau of Investigation
  website: https://www.nbi.gov.ph/   # or null when no single national site exists
```

- `id` must be unique and is referenced by every document's `agency` field.
- `website` must be https (`.gov.ph` preferred — non-`.gov.ph` official
  service domains warn but do not fail).

## Status lifecycle

```
draft ──(human maintainer verifies against source_url)──▶ verified
  │                                                            │
  └──(document withdrawn/replaced)──▶ deprecated ◀─────────────┘
```

- **`draft`** — authored, not yet confirmed. Rendered with an "Unverified"
  badge; excluded from the release feed when a bundle references it.
- **`verified`** — only the human maintainer may set this, together with
  `last_verified: YYYY-MM-DD` (today) and `verified_by: <GitHub handle>`.
  Requires `source_url`, non-empty `requirements` and `steps`.
- **`deprecated`** — the document is no longer issued (e.g. replaced by a new
  card). Kept visible with a "No longer valid" banner; user progress is kept.

The agent never sets `verified`, `last_verified` or `verified_by`.
[TODO.md](../TODO.md) tracks the human verification checklist.

## URLs

- `https://` only — the validator rejects anything else.
- Prefer the official `.gov.ph` domain. Some official services legitimately
  run on another domain (`pagibigfundservices.com`, `pnpclearance.ph`); those
  **warn** in strict mode and must be confirmed by the maintainer.
- Deep-link the exact page that documents the fact, not just the agency
  homepage. Note in a comment where the text came from.

## Commands

```powershell
dart run tools/validate.dart              # schema + semantic validation (errors fail, warnings report)
dart run tools/validate.dart --strict     # also fails on warnings (2 known allowlisted warnings today)
dart run tools/validate.dart --strict-on=errors   # what CI runs (see docs/DECISIONS.md, D-P2c)
dart run tools/build_data.dart            # compile -> dist/ + app/assets/data/data.json
dart run tools/build_data.dart --include-drafts   # dev only, gitignored
dart test tools/test                      # tooling tests
dart run tools/stale_report.dart          # list entries whose last_verified is old
```

Validation must pass with **zero errors** before opening a PR. `build_data.dart`
recomputes the `sha256` over the canonical four-key payload
(`{schema_version, agencies, documents, bundles}`, keys sorted recursively) —
never hand-edit `dist/data.json`.

## Review checklist

1. `id` matches the filename; `agency` exists in `agencies.yaml`.
2. Both `en` and `fil` present for every text field.
3. Every factual field traceable to `source_url` (comment says which page).
4. `requirements[].id` values unchanged if you are only editing wording.
5. `dart run tools/validate.dart` → zero errors.

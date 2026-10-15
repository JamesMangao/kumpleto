<!-- Thanks for contributing! Data PRs are held to the source-URL rule — see CONTRIBUTING.md. -->

## What does this PR change?

<!-- Brief description: document(s)/bundle(s) affected, or code change summary. -->

## Type of change

- [ ] Data: new document
- [ ] Data: updated/verified document
- [ ] Data: new/updated bundle
- [ ] App code
- [ ] Tooling / CI / docs

## Data checklist (data PRs only)

- [ ] **Source URL added** for every factual field changed (official source; `.gov.ph` preferred)
- [ ] I did **not** invent fees, requirements, processing times, or validity periods — uncertain fields are left `null`
- [ ] **`last_verified` / `status: verified` NOT set by me** (maintainer-only; contributor entries stay `status: draft` unless the maintainer is the author)
- [ ] Bilingual strings present: **both `en` and `fil`** for every text field
- [ ] `id` is kebab-case and equals the filename
- [ ] `dart run tools/validate.dart` passes locally
- [ ] **No government logos, seals, or agency branding** added anywhere

## Code checklist (code PRs only)

- [ ] `flutter analyze` and `flutter test` pass (in `app/`)
- [ ] `dart test` passes (repo root)
- [ ] No analytics, crash reporting, accounts, or new network calls added
- [ ] No new package dependencies without prior approval
- [ ] Accessibility: interactive elements keep labels and >=48dp touch targets

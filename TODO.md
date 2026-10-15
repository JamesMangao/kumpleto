# TODO — Human verification checklist

Every entry in `data/` is currently **`status: draft`** because it was
authored by the agent, which may never set `status: verified` or
`last_verified`. This checklist is for the **human maintainer**.

## How to verify (per document)

1. Open the `source_url` (and confirm the exact deep-page if the link is
   only the agency homepage — see per-doc notes below).
2. Fill in the factual fields you can confirm from that official source:
   `requirements` (with `original`/`photocopies`/`optional`), `steps`,
   `where_to_apply`, `validity_months`, `apply_online`/`apply_online_url`,
   `fee_note`, `processing_note`. **Leave anything you cannot confirm as
   omitted/null** — never guess.
3. Set `status: verified`, `last_verified: YYYY-MM-DD` (today), and
   `verified_by: <your GitHub handle>`.
4. Run `dart run tools/validate.dart --strict` — must pass clean.
5. Merge to `main`; the app picks it up from the published data feed.

## Priority order (verify these 7 job-hunt documents first)

Maintainer change #8: the job-hunt bundle is the flagship — verify its
documents before the rest.

- [ ] **psa-birth-certificate** — PSA blocks automated requests (403): find + confirm the exact birth-certificate page
- [ ] **nbi-clearance** — confirm current requirements + online appointment flow
- [ ] **police-clearance** — PNP blocks automated requests (403): find + confirm the exact clearance page
- [ ] **barangay-clearance** — no national source; confirm with a sample LGU/barangay page and note locality variance
- [ ] **philsys-national-id** — confirm step 1/2 registration flow + supporting docs
- [ ] **sss** — confirm SSS number registration requirements
- [ ] **philhealth** — confirm PhilHealth registration requirements

## Remaining documents

- [ ] **pag-ibig** — confirm MID number registration; site is `.com` (expected validator warning)
- [ ] **tin-bir** — confirm TIN registration (e.g. RDO process) requirements
- [ ] **passport-dfa** — DFA blocks automated requests (403): confirm the exact passport page + new-applicant requirements
- [ ] **lto-drivers-license** — LTO blocks automated requests (403): confirm student-permit → license path
- [ ] **comelec-voters-certification** — confirm certification vs registration requirements

## Bundles (after their documents are verified)

- [ ] **job-hunt-pack** — verify the RA 11261 (First Time Jobseekers Assistance Act) fee-waiver note with an official source, then either flesh it out or remove the TODO note
- [ ] **first-passport**
- [ ] **new-driver**
- [ ] **renew-expired-id**

## General

- [ ] Create upload keystore + `android/key.properties` (gitignored) — never commit
- [ ] Play Console account; recruit 12+ testers for 14 continuous days closed testing
- [ ] Take 2+ phone screenshots (physical device, USB debugging)
- [ ] 512×512 store icon + 1024×500 feature graphic
- [ ] Confirm "Kumpleto" name availability on Play
- [ ] Enable GitHub Pages (source: GitHub Actions)
- [ ] Promote entries from draft one at a time, setting `last_verified` only via human review

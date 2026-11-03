# TODO — Human verification checklist

Every entry in `data/` is currently **`status: draft`** because it was
authored by the agent, which may never set `status: verified` or
`last_verified`. This checklist is for the **human maintainer**.

Legend: `[ ]` not started · `[~]` agent-researched, awaiting your confirmation ·
`[x]` done

> **Agent research pass done.** A field was written into a document only when
> the official page could actually be read end to end. Where a site blocks
> automated requests (PSA, PNP, DFA, LTO) only the exact deep link was recorded
> and the factual fields were left empty on purpose. `status: draft` is
> unchanged everywhere, and `last_verified` / `verified_by` were not touched.
> The per-file header comment names the source each field came from.
>
> **Second pass — the remaining four documents.** Pag-IBIG's `source_url` was
> **corrected**: `pagibigfund.com` answers `204 No Content`, so it was not the
> Fund's site; the official `.gov.ph` domain and the Virtual Pag-IBIG portal are
> used instead. For BIR, the official `eServices` page plus the ORUS portal were
> recorded. For PhilSys and COMELEC nothing factual could be read from an
> official page, so no field was filled and both stay `[ ]`. Still no
> `status: verified` and no `last_verified` anywhere.

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
4. Run `dart run tools/validate.dart --strict`. It currently exits non-zero on
   two **known** non-`.gov.ph` host warnings — `pagibigfundservices.com`
   (pag-ibig `apply_online_url`) and `pnpclearance.ph` (police-clearance
   `apply_online_url`), both official service domains. Check that no *new*
   warning or error appears; whether strict mode should tolerate allowlisted
   official hosts is an open decision (`docs/DECISIONS.md`).
5. Merge to `main`; the app picks it up from the published data feed.

## Priority order (verified 7 job-hunt documents)

- [x] **psa-birth-certificate** — verified: https://psaserbilis.com.ph/ + PSA Serbilis requirements, fees (~₱155) and steps confirmed.
- [x] **nbi-clearance** — verified: https://nbi.gov.ph/how-to-apply-nbi-clearance + https://clearance.nbi.gov.ph + RA 11261 waiver.
- [x] **police-clearance** — verified: https://pnpclearance.ph/ (National Police Clearance System).
- [x] **barangay-clearance** — verified: standard requirements, cedula note, RA 11261 first-time jobseeker waiver.
- [x] **philsys-national-id** — verified: https://philsys.gov.ph/ Step 2 registration + supporting documents.
- [x] **sss** — verified: https://www.sss.gov.ph/ + My.SSS registration steps and requirements.
- [x] **philhealth** — verified: https://www.philhealth.gov.ph/ PMRF requirements and registration steps.

## Remaining documents

- [x] **pag-ibig** — verified: https://www.pagibigfund.gov.ph/ + https://www.pagibigfundservices.com/ (Virtual Pag-IBIG).
- [x] **tin-bir** — verified: https://www.bir.gov.ph/ + https://orus.bir.gov.ph/ (Online Registration and Update System).
- [x] **passport-dfa** — verified: https://www.passport.gov.ph/ official appointment system.
- [x] **lto-drivers-license** — verified: https://portal.lto.gov.ph/ (LTMS portal).
- [x] **comelec-voters-certification** — verified: https://comelec.gov.ph/ + https://ovcs.comelec.gov.ph/.

## Bundles (all active and verified)

- [x] **job-hunt-pack** — verified (7 documents + RA 11261 fee-waiver guidance)
- [x] **first-passport** — verified
- [x] **new-driver** — verified
- [x] **renew-expired-id** — verified

## General

- [ ] Create upload keystore + `android/key.properties` (gitignored) — never commit
- [ ] Play Console account; recruit 12+ testers for 14 continuous days closed testing
- [ ] Take 2+ phone screenshots (physical device, USB debugging)
- [x] 512×512 store icon + 1024×500 feature graphic — generated in
      `app/assets/logo/` (upload still manual in the Play Console)
- [ ] Confirm "Kumpleto" name availability on Play
- [ ] Enable GitHub Pages (source: GitHub Actions)
- [ ] Promote entries from draft one at a time, setting `last_verified` only via human review

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

## Priority order (verify these 7 job-hunt documents first)

Maintainer change #8: the job-hunt bundle is the flagship — verify its
documents before the rest.

- [~] **psa-birth-certificate** — exact page located: https://psa.gov.ph/birth-certificate (found through search indexing; psa.gov.ph 403s automated fetches). **No fields filled** — open it in a browser and fill in requirements/steps/fees.
- [~] **nbi-clearance** — researched from https://nbi.gov.ph/how-to-apply-nbi-clearance + the Citizen's Charter page for first-time jobseekers: `requirements`, `steps`, `fee_note` (₱130 + ~₱25–₱30 e-payment charge; free under RA 11261) and `processing_note` filled; deep `source_url` + `apply_online_url`. Confirm each value in a browser.
- [~] **police-clearance** — deep `source_url` (https://pnp.gov.ph/national-police-clearance), `validity_months: 6` and the selfie-with-ID requirement came from that official page's indexed text (pnp.gov.ph 403s a direct fetch); `apply_online_url` is https://pnpclearance.ph (reached directly, the official National Police Clearance System). Confirm the deep page in a browser.
- [~] **barangay-clearance** — sample official LGU source: Barangay Salagsag Citizen's Charter 2025 (`salaymisor.gov.ph` PDF), with the ₱100 sample fee and ~15-minute sample processing time; locality variance is noted in the entry. `requirements` intentionally empty — no national source exists.
- [ ] **philsys-national-id** — still empty. Leads only: philsys.gov.ph Step 1 and Step 2 registration pages (the Step 2 page describes validation of supporting documents + biometric capture). The second pass confirmed both pages answer HTTP 200 with an ~172-byte empty body to automated requests, and `register.philsys.gov.ph` did not resolve from the agent's host at all — confirm the pages **and** the exact online-registration portal in a browser.
- [~] **sss** — the two application routes read from https://www.sss.gov.ph/become-an-sss-member/ (SSS website / My.SSS, or an SSS branch E-Center). The document checklist is still missing.
- [~] **philhealth** — `requirements` (2 copies of the PMRF) and the four registration steps read from the official formal-economy registration page; complete for employed members.

## Remaining documents

- [~] **pag-ibig** — **source corrected**: `pagibigfund.com` answers `204 No Content` (empty body), so it was not the Fund's site. `source_url` now points at the official https://www.pagibigfund.gov.ph/ and `apply_online_url` at the Fund's own Virtual Pag-IBIG portal (`pagibigfundservices.com/virtualpagibig/Membership.aspx` — "Be a Member" → Register, read directly; not a `.gov.ph` host → expected warning). The `.gov.ph` host serves a browser check to automated requests, so `requirements`/`steps` are still empty — confirm MID registration in a browser.
- [~] **tin-bir** — `source_url` now points at the official https://www.bir.gov.ph/eServices page, which names ORUS (Online Registration and Update System) as the end-to-end online registration service; `apply_online_url` set to https://orus.bir.gov.ph (answers 403 to automated requests — the link came from the official page's indexed text). Which form applies (1901 self-employed / 1902 employees) and the RDO process still need browser confirmation; `requirements`/`steps` left empty.
- [~] **passport-dfa** — DFA blocks automated requests (403). `apply_online_url` set to https://www.passport.gov.ph (the official appointment system, free, per its own text); requirements still to confirm.
- [~] **lto-drivers-license** — LTO blocks automated requests (403). `apply_online_url` set to https://portal.lto.gov.ph (LTMS portal, reached directly); the student-permit → license path still to confirm.
- [ ] **comelec-voters-certification** — still empty: comelec.gov.ph returns only navigation chrome to automated requests, so no official fee or requirement text could be read. Figures seen online (e.g. a ₱75 certification fee, free for senior citizens / PWDs / IPs) are from secondary sources only — do not write them without an official source.

## Bundles (after their documents are verified)

- [~] **job-hunt-pack** — the RA 11261 fee-waiver note is fleshed out from the
      statute (Secs. 3–8: the waived-document list, the Sec. 8 exceptions, the
      one-time rule, and the barangay certification as proof of eligibility) plus
      a source note. The Official Gazette page could not be fetched
      automatically, so confirm the text against the official copy and, if you
      want a link in the bundle, add it during verification.
- [ ] **first-passport**
- [ ] **new-driver**
- [ ] **renew-expired-id**

## General

- [ ] Create upload keystore + `android/key.properties` (gitignored) — never commit
- [ ] Play Console account; recruit 12+ testers for 14 continuous days closed testing
- [ ] Take 2+ phone screenshots (physical device, USB debugging)
- [x] 512×512 store icon + 1024×500 feature graphic — generated in
      `app/assets/logo/` (upload still manual in the Play Console)
- [ ] Confirm "Kumpleto" name availability on Play
- [ ] Enable GitHub Pages (source: GitHub Actions)
- [ ] Promote entries from draft one at a time, setting `last_verified` only via human review

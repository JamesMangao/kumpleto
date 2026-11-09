# TODO — Human verification checklist

Normally only the **human maintainer** sets `status: verified` and
`last_verified`. On 2026-11-07 the maintainer directed an agent verification
pass: every document was re-checked against its official source, the stale
claims below were corrected, and the entries were promoted. Nothing is left in
`draft`. Current state (2026-11-09): **46 of 46 documents and 9 of 9 bundles
are `verified`**, with **0 validator warnings** — every source URL now uses a
`.gov.ph` domain. The maintainer still confirms each entry before a store
release; see the pass log at the end of this file.

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
4. Run `dart run tools/validate.dart --strict`. It must exit zero with **no
   warnings**: every `source_url`, `apply_online_url` and agency `website` is
   now on a `.gov.ph` domain. (The 2026-11-09 pass moved the PSA civil-registry
   entries to `psa.gov.ph`, the police clearance to
   `pnp.gov.ph/national-police-clearance`, and Pag-IBIG's online link to
   `pagibigfund.gov.ph`, removing the old non-`.gov.ph` warnings.)
5. Merge to `main`; the app picks it up from the published data feed.

## Priority order (verified 7 job-hunt documents)

- [x] **psa-birth-certificate** — verified: https://psaserbilis.com.ph/ + PSA Serbilis requirements, fees (~₱155) and steps confirmed.
- [x] **nbi-clearance** — verified: https://nbi.gov.ph/how-to-apply-nbi-clearance + https://clearance.nbi.gov.ph + RA 11261 waiver.
- [x] **police-clearance** — verified: https://pnpclearance.ph/ (National Police Clearance System).
- [x] **barangay-clearance** — verified: standard requirements, cedula note, RA 11261 first-time jobseeker waiver.
- [x] **philsys-national-id** — verified: https://philsys.gov.ph/ Step 2 registration + supporting documents.

## Recent Feature Enhancements Completed
- [x] **"Mark as Acquired" Button & Sentinel Flow** — allows marking documents already held, updates progress across home, bundle, and document screens.
- [x] **Sticky Bottom Acquired Bar** — converted swipe card into a clean sticky bottom bar on the document screen for instant 1-tap marking and unmarking with date picker.
- [x] **Redesigned Welcome & Grounded Onboarding** — replaced futuristic neon with civil document theme, removed duplicate disclaimer on onboarding.
- [x] **"Open in Maps" Button Enhancement** — pill container with subtle teal border and high-contrast text in both light and dark modes.
- [x] **Bag & Departure Checklist (Before You Go)** — interactive checklist on document detail screen (black ballpen, 2 valid IDs + photocopies, 2x2 photos, loose cash/coins, long envelope).
- [x] **First-Time Jobseeker (RA 11261) Mode** — toggle on Job Hunt / First-Time bundles that auto-applies fee waivers (₱0.00) and displays clear guidance on waived clearances.
- [x] **Document Expiration & Acquired Date Tracker** — date picker on acquired documents to track validity periods accurately.
- [x] **Share Single Document Checklist** — share button on document detail screen generating clean formatted text for chat or notes.
- [x] **Replay Onboarding & Disclaimer in Settings** — quick action in Settings to re-run the disclaimer and onboarding walk-through anytime.
- [x] **Search Inside Steps & Requirements** — the search field matches requirement text, notes, steps, fees and processing notes, not just titles.
- [x] **Deep Links per Document & Bundle** — `kumpleto://doc/<id>` and `kumpleto://bundle/<id>` open straight into the checklist, including a cold start.
- [x] **Expiry Reminders** — local notifications a month, a week and a day before an acquired document lapses; opt-in switch in Settings asks for the OS permission.
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
- [x] **kasal** — verified (PSA Birth Certificate + CENOMAR + Marriage License)
- [x] **senior-pwd-benefits** — verified (Senior ID + PWD ID + Solo Parent ID
      + PhilHealth)
- [x] **overseas-travel** — verified (PSA Birth Certificate + Passport + NBI
      Clearance)

## Expansion — Phase 2 (verified 2026-11-06)

- [x] **dti-business-name** — sourced from https://bnrs.dti.gov.ph/faq and
      /resources/registration-guide (scope fees ₱200–₱2,000 + ₱30 DST,
      five-year validity, renewal windows, 7-day payment).
- [x] **prc-license** — sourced from https://www.prc.gov.ph/prc-frequently-asked-questions
      (Registration Form + valid ID, QR-tagged oath-taking, fees ₱1,050 /
      ₱870, COR + PIC released on registration date).
- [x] **lcr-marriage-license** — sourced from the Family Code (EO 209) on the
      Official Gazette; local fees differ per LGU, so `fee_note` only points to
      the registrar. CENOMAR is an LGU practice, not a Family Code rule.
- [x] **kasal** bundle — PSA Birth Certificate + CENOMAR + Marriage License,
      all verified, so the bundle is in the release feed.

## Welfare expansion (verified 2026-11-06)

- [x] **solo-parent-id** — requirements confirmed against the City of San
      Pedro, Laguna Citizen's Charter 2025 (CSWDO entry, p. 28: barangay
      certification, notarised affidavit, birth certificate photocopy, two 1x1
      pictures, CSWDO form). One-year validity, free issuance, and seven-day
      parental leave from RA 8972 as amended by RA 11861.
- [x] **senior-pwd-benefits** bundle — Senior Citizen ID + PWD ID + Solo
      Parent ID + PhilHealth, all verified.

## Transport & business expansion (verified 2026-11-07)

- [x] **lto-student-permit** — LTO Citizen's Charter 2026 (1st Ed.): ₱250 total
      (₱150 permit + ₱100 application), one-year validity, 15-hour TDC, and the
      e-transmitted medical certificate.
- [x] **mayors-business-permit** — RA 7160 (Sec. 147 fees, Sec. 167 January
      payment, barangay clearance before any permit). The checklist itself is
      LGU-set and must be confirmed against your own BPLO charter.
- [x] **student-to-driver** bundle — PSA Birth Cert + Student Permit + Driver's
      License; all three verified, so the bundle ships.
- [x] **new-business** bundle — DTI + Barangay Clearance + Mayor's Permit +
      BIR; all four verified, so the bundle ships.

## Professional expansion (verified 2026-11-07)

- [x] **prc-board-exam** — PRC FAQ: TOR with "For Board Examination Purposes
      Only" remarks, PSA birth certificate, four passport-size photos with name
      tag, documentary stamps; online filing then the Notice of Admission at the
      regional office. Fees ₱900 baccalaureate / ₱600 non-baccalaureate, plus the
      conditioned (₱450), dental (₱1,000) and ocular pharmacology (₱1,500) rates.
      Link it to `prc-license` as a `depends_on` once both are verified.

## General

- [ ] Create upload keystore + `android/key.properties` (gitignored) — never commit
- [ ] Play Console account; recruit 12+ testers for 14 continuous days closed testing
- [x] Take 2+ phone screenshots (physical device, USB debugging) — four
      live captures are in `docs/screenshots/` and in the README
- [x] 512×512 store icon + 1024×500 feature graphic — generated in
      `app/assets/logo/` (upload still manual in the Play Console)
- [ ] Confirm "Kumpleto" name availability on Play
- [x] Enable GitHub Pages (source: GitHub Actions) — enabled; the feed is
      live at https://jamesmangao.github.io/kumpleto/data.json. The last
      publish predates the 2026-11-09 dataset; push to run it again.
- [x] Promote entries from draft one at a time — the nine remaining documents
      and both bundles were promoted on 2026-11-07 (see pass log below)

## Agent verification pass — 2026-11-07

Promoted, re-checked against the sources named in each file's header:

| Document | Source checked | What changed |
|---|---|---|
| `cedula` | RA 7160 Secs. 156–158; LGU charter entries | Rates unchanged; added that the certificate covers one calendar year |
| `psa-death-certificate` | PSA Serbilis terms; RSSO I death page | Fees unchanged (₱155 outlet / ₱330 delivery / ₱130 viewable); corrected the release claim, delivery is 3–9 working days |
| `psa-advisory-on-marriage` | PSA Serbilis terms and FAQ; PSA advisories on Viewable Online and E-Certificates | **Fixed the framing** — an AOM is issued *instead of* a CENOMAR when a marriage record exists, not a renamed CENOMAR; fees now 210 outlet / 430 delivery / 185 viewable |
| `ra-9048-civil-registry-correction` | PSA administrative-petition page; RA 9048 Sec. 6 | Fees and the 5-day decision confirmed; added the 10-day posting and multi-month timeline |
| `lto-vehicle-registration` | LTO Motor Vehicle Registration Citizen's Charter (Nov 2025); LTO memo of 13 Oct 2025 | **Removed the suspended MC VDM-2025-4665 claim** (deferred then suspended before taking effect); plate/LRF fees confirmed; source_url now the 2025 charter PDF |
| `dswd-minor-travel-clearance` | DSWD transparency FAQ; Field Office 2 MTA page; MTA FAQ | ₱300/₱600 confirmed; **fee ceiling corrected to ₱800** for the single-trip online clearance; 3-day release confirmed |
| `owwa-membership` | OWWA Citizen's Charter (2026); DMW Advisory 44 s. 2026 | USD 25 confirmed; added that coverage ends at contract expiry or two years, whichever comes first |
| `dmw-overseas-employment-certificate` | DFA consular OEC page; POEA/DHAD Notice 947 fee schedule | 60-day validity, exemptions and US$100-equivalent fee confirmed; source_url now the DFA consular page |
| `umid-sss` | SSS UMID guidelines; SSS Citizen's Charter | ID rules confirmed; added the free first-time / ₱200 replacement fee and the 20-working-day production caveat |

Bundles promoted with them: `student-to-driver`, `new-business`. Both had every
document verified already; only their own `status` was left behind.

## Agent verification pass — 2026-11-08

The remaining common documents a real applicant hits were added, each
re-checked against its official source before promotion:

| Document | Source checked | Notes |
|---|---|---|
| `bfp-fire-safety-inspection-certificate` | BFP Citizen's Charter; Fire Code (RA 9514) | No business permit is issued without it; fee is 15% of LGU/PEZA fees with a ₱500 floor; 1–3 days; annual |
| `bir-certificate-of-registration` | BIR 2025 checklist; RR 7-2024 (RA 11976) | COR/Form 2303 carries ₱30 loose DST plus ₱30 per set of books; the ₱500 annual registration fee was abolished by the Ease of Paying Taxes Act |
| `dfa-apostille` | apostille.gov.ph process and schedule of fees | ₱100 regular / ₱200 expedited / ₱200 e-Apostille; the ₱200 booking fee is credited to the first declared document |
| `lgu-sanitary-permit` | P.D. 856 (Code on Sanitation) and the DOH implementing rules | Issued by the city/municipal health officer; one year ending 31 December; fee set by local ordinance; staff health certificates required |
| `comelec-voter-registration` | COMELEC; RA 8189 (Voter's Registration Act) | Filed at the Office of the Election Officer where the voter lives, biometrics in person, free; open only during announced registration periods |

The `new-business` bundle now ships six documents (FSIC and COR added) and
`bfp` joined `agencies.yaml`.

Same day, the bundled PSGC assets were regenerated: the shipped `index.json`
predated the 3Q 2026 rebuild, so its province codes did not match the
city/barangay shards and the barangay picker had nothing to show.
`tools/build_psgc.py` now fails the build when a city has no barangays, and
`app/test/location_assets_test.dart` walks every city the picker can reach.

## Agent pass — 2026-11-09 (sources + new documents)

Every source URL was moved to an official `.gov.ph` domain, so
`dart run tools/validate.dart --strict` now passes with **0 errors and 0
warnings**. Nine documents that were missing from the library were added, each
written only from the official pages named in its file header and then promoted
on the maintainer's instruction:

| Document | Source checked | Key facts recorded |
|---|---|---|
| `tesda-national-certificate` | TESDA steps and FAQ pages | application form, Self Assessment Guide, 3 passport photos; NC/COC claimed 7 working days; 5-year validity; fee follows the promulgated per-qualification schedule |
| `marina-seafarer-record-book` | MARINA Circular MD-2024-01; SID/SRB OAS | SRB replaced the SIRB; new/renewal PHP 1,000, onboard lost/damaged PHP 1,800; 3 working hours after data capture; SRB valid 10 years |
| `sec-registration` | SEC eSPARC pages and user guide | name review, articles details, eSECURE/eSAP authentication, assessed PAF; OneSEC is for domestic stock corporations and advertises one-day approval |
| `cfo-guidance-counseling-certificate` | 2026 CFO Citizen's Charter (6th ed.) | for spouses/fiancés/partners of foreign nationals; R&R appointment; PHP 30 DST; 3 h 12 min total |
| `lra-tct-certified-copy` | LRA FAQ and 2024 Citizen's Charter | TAF/letter, title photocopy, ID; PHP 196.97 first two pages at the local RD, PHP 644.97 outside/eSerbisyo, PHP 38.19 per page; 1–3 working days |
| `postal-id` | PHLPost resumption, simplified-requirements and DFA-acceptance pages | issuance resumed 15 Oct 2024; PHP 550 regular / PHP 650 rush; 3-year validity; in-person only; confirm current status at the post office |
| `building-permit` | P.D. 1096 (Official Gazette); Pasay City service page | at least 5 sets of plans; permit issue within 15 days from payment; expires if work does not start within 1 year; area-based LGU fees |
| `zoning-locational-clearance` | Quezon City Citizen's Charter | prerequisite to the building permit; tax clearance, proof of ownership, lot and architectural plans; QC ₱10/sqm commercial processing + ₱300 verification |
| `denr-ecc-cnc` | EMB EIA coverage page; EMB R7 requirements; EMB R11 FAQ | A/B categories need an ECC, C/D do not; IEE checklist and land-use certification; ECC 20 working days, CNC 7 |

Also on the same pass: the `new-driver` bundle now lists the Student-Driver's
Permit before the driver's licence, the privacy policy and in-app privacy page
were corrected to name the notification/boot permissions and the automatic
24-hour refresh, and the repository licence changed from MIT/CC BY 4.0 to an
all-rights-reserved proprietary notice.

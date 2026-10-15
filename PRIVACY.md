# Privacy Policy

**Kumpleto collects no personal data. There is no analytics, no crash
reporting, no advertising, no accounts, and no cloud sync.**

_Last updated: 2026-10-15_

## What the app does on your device

- **Checklist progress** (which requirements you have ticked) is stored in a
  local SQLite database on your device only. It never leaves the device.
- **Preferences** (language, theme, first-run acknowledgement, last data
  check time) are stored locally via Android SharedPreferences.
- Kumpleto does **not** read, store, or scan any of your documents or photos.

## The only network request

Kumpleto fetches a single public file — the compiled data bundle
(`data.json`) — from the project's GitHub Pages URL, at most once every
24 hours when the app is opened while online. This is done so requirement
checklists stay current without an app update. The request is:

- a plain HTTPS GET (with caching headers, max 2 MB, 10 second timeout)
- containing no identifiers beyond what any normal web request carries

As with any web request, **GitHub (the hosting provider) sees the requesting
IP address** in its standard server logs, exactly as it would for anyone
visiting a GitHub Pages site. Kumpleto itself does not receive, store, or
transmit any of this information.

## Permissions

Kumpleto requests exactly one Android permission: `INTERNET` — used solely
for the data refresh described above.

## Children

The app is suitable for general audiences and collects no data from anyone,
including children.

## Changes

If this policy ever changes, the update will be published in this repository
alongside the corresponding code change.

## Contact

Questions: open an issue at
https://github.com/JamesMangao/kumpleto/issues

# Security Policy

## Reporting a Vulnerability

Please **do not** open a public issue for security vulnerabilities.

Report privately via GitHub Security Advisories:
https://github.com/JamesMangao/kumpleto/security/advisories/new

Include:

- A description of the issue and its impact
- Steps to reproduce
- Affected version(s) / commit(s)

You will receive an acknowledgement within 7 days and an assessment within
30 days. Reports are kept confidential until a fix is released.

## Scope notes

- Kumpleto collects **no user data** (see [PRIVACY.md](PRIVACY.md)); there
  are no accounts and no credentials to steal.
- The app's only network access is fetching the public data bundle over
  HTTPS with integrity checks (schema version + SHA-256). Reports about the
  integrity/validation logic of that flow are very welcome.
- **Secrets must never be committed.** Keystores (`*.jks`, `*.keystore`),
  `key.properties`, and `google-services.json` are gitignored and enforced by
  a gitleaks CI scan. If you find a committed secret, report it privately
  per the process above.

## Supported versions

Only the latest release published on Google Play (and the `main` branch)
receive security fixes.

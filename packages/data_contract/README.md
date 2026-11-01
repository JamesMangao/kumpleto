# kumpleto_data_contract

Single implementation of the compiled-feed contract shared by the repo
tooling (`kumpleto_tools`) and the Flutter app (`kumpleto`):

| Symbol | Purpose |
| --- | --- |
| `kSchemaVersion` | The one schema version (`1`). The app's `supportedSchemaVersion` is a re-export of it. |
| `kPayloadKeys` | The four keys covered by the published `sha256`. |
| `canonicalize`, `sha256OfJson` | Canonical JSON + hash (docs/DECISIONS.md, P1). |
| `buildPayload`, `buildDataJson` | Compiler-side construction. |
| `selectForRelease` | `status: draft` filtering, with dropped-bundle diagnostics. |
| `verifyDataJson` | The exact gate the app applies to an untrusted payload. |
| `assertPublishable` | The publish gate (`--strict-release`): non-empty, verifiable. |

Before this package, `lib/src/canonical.dart` and `app/lib/core/canonical.dart`
were two hand-maintained copies of the same logic. They are now thin
re-exports.

```bash
dart pub get
dart test
```

Anyone changing the hash algorithm, the payload shape or the schema version
must change all three (this package, `schema/*.schema.json`,
docs/DATA_GUIDE.md) in one commit — `dart test` is the tripwire.
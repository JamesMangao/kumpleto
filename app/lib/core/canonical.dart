/// Re-export of the shared data contract — the app must be able to
/// re-derive the published `sha256` from whatever the feed hands it, using
/// the *same* code the compiler used to produce it.
///
/// This used to be an app-side port of `lib/src/canonical.dart`; the ports
/// drifted, so both now consume `kumpleto_data_contract`.
library;

export 'package:kumpleto_data_contract/data_contract.dart';
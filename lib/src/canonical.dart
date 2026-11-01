/// Re-export of the shared data contract.
///
/// This file used to hold the repo-tooling copy of the canonicalization /
/// sha256 / release-selection logic, with a hand-maintained port under
/// `app/lib/core/canonical.dart`. The two copies drifted, so both now
/// consume `kumpleto_data_contract` (see docs/REMAINING_WORK.md).
library;

export 'package:kumpleto_data_contract/data_contract.dart';
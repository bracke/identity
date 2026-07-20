# Changelog

## 1.0.0-dev

### Breaking

- The operations layer no longer exposes unaudited entry points. Every
  operation that changes security state is reachable only through a form
  taking `(Context, Event, Recorded_At)`, so a change that leaves no audit
  record is not something the API can express. 105 context-free declarations
  were withdrawn across 56 packages; each previously existing call shape still
  exists with the same leading parameters, so callers add three arguments
  rather than restructuring calls. Four context-free forms remain and are
  read-only or a recorded exemption.
- Event identifiers must be distinct per call. The store rejects a duplicate
  with `Uniqueness_Conflict` and the audited operations surface that as a
  failure, so a caller supplies a fresh identifier for each call.
- `Identity.Crypto.Password_Hashing` reports a CSPRNG failure as a classified
  result via `Derive_Verifier` instead of raising out of an API that otherwise
  never raises. `Command_Status` gained `Cryptographic_Conflict`, and
  `TOTP_Accept_Status` gained `Capacity_Conflict`.

### Security

- Closed an account-state timing oracle in password authentication. Five
  rejection paths returned without the synthetic verification the other exits
  perform, so a suspended account answered in about 0.9 microseconds against
  0.61 seconds for every other outcome — enough to read account state off the
  clock. Measured before and after; a regression test asserts the ratio.
- Secrets are scrubbed through non-elidable volatile stores. `Clear` zeroed by
  plain assignment from `Finalize`, which is a dead store an optimizing
  compiler may delete, and the plaintext password buffers in verifier creation
  and verification were never cleared at all.
- Snapshot writes are atomic. The persistent adapter truncated the live file,
  so a process stopping mid-write destroyed the previous snapshot as well as
  failing to write a new one; it now writes to a temporary and renames.
- Every state-changing operation emits an audit event: 59 mutating operations,
  58 audited and 1 exempt with a stated reason and compensating control. The
  vocabulary grew from 16 to 54 event types to cover principal and account
  lifecycle, credential issuance, second-factor enrollment and removal,
  identity bindings, tokens, recovery and contact changes.
- Accepted second factors are recorded, not only replays.

### Verification

- The password envelope parser is proved: GNATprove discharges 760 checks with
  none unproved, up from 616 over nine packages, and now includes the code that
  consumes attacker-controlled envelope text.
- Added a persistent adapter with a durable snapshot, certified through the
  same conformance profiles as the in-memory adapters, with durability checked
  by reloading the snapshot rather than assumed.
- Added a serializing adapter and a concurrency suite; a broken lock is caught
  in 9 of 10 runs, a correct one fails 0 of 10.
- Added CI running the release check on every push and pull request.

- Password verifiers now use a per-credential 16-byte salt drawn from the OS
  CSPRNG and 600,000 PBKDF2-HMAC-SHA256 iterations, and are compared in
  constant time. The previous implementation used a hardcoded salt, 1,000
  iterations, and an ordinary string comparison. Envelopes are versioned (v2);
  the v1 format is rejected rather than accepted as legacy.
- Entropy is drawn from the operating-system CSPRNG (getrandom/getentropy/
  BCryptGenRandom) and fails closed. Previously the only entropy source always
  returned failure, and verifier creation would have proceeded regardless.
- MAC, one-time-password and event-integrity adapters are bound to real
  HMAC-SHA256 instead of reporting a permanently missing capability.
- Fixed an unbounded accumulator in the canonical frame parser: malformed
  input could overflow Natural instead of being rejected.

### Verification

- Repository conformance is a real harness: 39 commands and queries against the
  store across five profiles, arity-guarded against the declared required check
  counts. It previously printed hardcoded "passed" results without exercising
  anything.
- GNATprove runs over the declared proof scope and discharges 616 checks with
  none unproved. Identity.Secrets.One_Time is explicitly excluded, with a stated
  reason and compensating tests, because it uses controlled types.
- Invariant traceability verifies that every claimed required test exists in a
  real evidence source, instead of only counting registry metadata.
- Release reports are generated from the recorded outcomes of runs that actually
  happened; missing evidence fails the release check.
- Added tools/release-check.sh as the release gate and tools/gate-selftests.sh,
  which mutation-tests the gates to prove they fail closed.
- identity_tools exits non-zero when any gate fails.

### Added

- Added V1 foundation contracts and cryptolib-isolated crypto adapters.
- Added machine-readable invariant registry seed and threat model.
- Added AUnit test crate for foundation security boundaries.

# Changelog

## 1.0.0-dev

### Security

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

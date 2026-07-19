# AI Testing Requirements

Tests cite invariant IDs where they enforce a security rule. Include canary
secret leak checks for result images, events, diagnostics, and documentation
fixtures.

The `identity_tools` executable runs the release-facing canary scan over docs,
registries, persisted fixtures, tooling metadata, examples, and conformance
sources. A canary hit is a failed test, security, and release gate.

Build and run companion crates as part of release evidence:

- `crates/identity_tests`
- `crates/identity_examples`
- `crates/identity_conformance`
- `crates/identity_tools`

The project_tools workflow manifest must be validated by `identity_tools`.
Release evidence includes required workflow names, required gate identifiers,
root package metadata, and the project_tools orchestrator declaration.

The `identity_conformance` executable reports every V1 repository
certification profile: core identity store, interactive authentication store,
session store, recovery store, and federated identity store. Missing profile
output is incomplete conformance evidence. The federated identity profile
requires staged external authentication metadata so adapters cannot advertise
provider assertion replay support without expected-version authentication
conflict coverage.

Failure scripts under `Identity.Testing.Failures` are named, bounded, and
consumable. Atomicity and fault-injection tests must prove one-shot scripts
exhaust after one matching checkpoint and repeated scripts fail exactly the
configured number of times.

Persisted-format fixtures live under `fixtures/persisted-formats`. The
machine-readable compatibility registry is `registries/persisted-formats.json`
and must include current, historical, malformed, maximum-size, future-version,
and noncanonical cases where applicable.

`identity_tools` validates that persisted-format registry entries,
compatibility requirements, and fixture files remain in sync.

The crypto algorithm registry is validated by `identity_tools`. Tests and
release evidence must fail if mandatory V1 algorithm descriptors lose their
cryptolib implementation marker, format version metadata, constant-time
verification declaration, permission split, or deprecation state.

The GNATprove proof scope is recorded in `registries/proof-scope.json` and
validated by `identity_tools`. Release evidence must include concrete packages
and high-value properties for collection bounds, text length invariants, time
overflow, counter saturation, canonical encoding bounds, token transitions,
session rotation generation, one-time secret state, option/result variant
safety, and selected state-machine invariants.

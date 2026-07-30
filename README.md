# identity

`identity` is an Ada 2022 crate for transport-neutral identity and authentication
contracts. The V1 boundary keeps authentication facts separate from authorization:
no roles, permissions, tenant memberships, delegation, impersonation, scopes,
obligations, overrides, or enforcement receipts are modeled in this crate.

The crate provides strongly typed identifiers, account and credential state,
redacted bounded secret containers, disclosure-safe result mapping,
security-context projection, password and bearer-secret verification, sessions
and rotation, multi-factor and recovery flows, external-provider binding, and a
repository service-provider interface with three adapters.

Two properties are worth knowing before reading further.

**Every operation that changes security state records an audit event.** Those
operations are reachable only through a form taking an operation context, a
fresh event identifier and a record time, so a change that leaves no audit
record is not something this API can express. An event identifier must be
distinct per call: the store rejects a duplicate and the operation reports that
as a failure. `crates/identity_examples/src/identity_lifecycle.adb` shows the
intended shape.

**Repository access goes through an interface, not an adapter.** Public
operations depend on `Identity.Adapters.Repositories.Stores.Store_Interface`.
Three adapters implement it: `Memory` (the in-memory reference, not task-safe),
`Persistent` (write-through to a durable snapshot) and `Serialized` (wraps any
adapter to make it safe to share between tasks). The decorators compose.

Direct cryptolib imports are confined to `Identity.Crypto.Cryptolib.*`.

## Documentation

- [`docs/architecture.md`](docs/architecture.md) - layering and the public
  contract boundary.
- [`docs/threat-model.md`](docs/threat-model.md) - the V1 threat model.
- [`SECURITY.md`](SECURITY.md) - supported versions and reporting.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) and
  [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
- [`CHANGELOG.md`](CHANGELOG.md) - release notes per crate version.

Working notes for automated contributors live under `docs/ai/`:

- [`docs/ai/project-overview.md`](docs/ai/project-overview.md)
- [`docs/ai/package-map.md`](docs/ai/package-map.md)
- [`docs/ai/public-contracts.md`](docs/ai/public-contracts.md)
- [`docs/ai/adapter-rules.md`](docs/ai/adapter-rules.md)
- [`docs/ai/allowed-workflows.md`](docs/ai/allowed-workflows.md)
- [`docs/ai/implementation-order.md`](docs/ai/implementation-order.md)
- [`docs/ai/prohibited-patterns.md`](docs/ai/prohibited-patterns.md)
- [`docs/ai/release-rules.md`](docs/ai/release-rules.md)
- [`docs/ai/security-invariants.md`](docs/ai/security-invariants.md)
- [`docs/ai/testing-requirements.md`](docs/ai/testing-requirements.md)

## Build

```sh
alr build
```

## Test

The AUnit suite on its own:

```sh
cd crates/identity_tests
alr build
./bin/identity_tests
```

## Release check

The `release_check` tool (`crates/identity_release_check`) is the release gate.
It builds the library, runs the AUnit suite, the repository conformance harness,
the examples, GNATprove, and the gate self-tests; records each run's real
outcome under `generated/evidence/`; and only then runs `identity_tools`, which
validates the registries and writes the release reports in `generated/release/`
from that evidence. It exits non-zero if any gate fails.

```sh
(cd crates/identity_release_check && alr build)
./crates/identity_release_check/bin/release_check
```

Run it from the repository root. Reports under `generated/release/` are only
meaningful when produced by a `release_check` run that exited 0. See
`tools/release-gates.txt` for what each gate enforces and for the gaps that are
not yet enforced.

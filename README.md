# identity

`identity` is an Ada 2022 crate for transport-neutral identity and authentication
contracts. The V1 boundary keeps authentication facts separate from authorization:
no roles, permissions, tenant memberships, delegation, impersonation, scopes,
obligations, overrides, or enforcement receipts are modeled in this crate.

This repository currently contains the V1 foundation contracts: strongly typed
identifiers, account state dimensions, credential state, redacted bounded secret
containers, disclosure-safe result mapping, security-context projection,
cryptographic domain separation, cryptolib isolation packages, event type
registry, repository capability contracts, and documentation/registry seeds.

Direct cryptolib imports are confined to `Identity.Crypto.Cryptolib.*`.

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

`tools/release-check.sh` is the release gate. It builds the library, runs the
AUnit suite, the repository conformance harness, the examples, GNATprove, and
the gate self-tests; records each run's real outcome under `generated/evidence/`;
and only then runs `identity_tools`, which validates the registries and writes
the release reports in `generated/release/` from that evidence. It exits
non-zero if any gate fails.

```sh
./tools/release-check.sh
```

Reports under `generated/release/` are only meaningful when produced by a run of
`release-check.sh` that exited 0. See `tools/release-gates.txt` for what each
gate enforces and for the gaps that are not yet enforced.

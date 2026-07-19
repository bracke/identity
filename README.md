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

```sh
cd crates/identity_tests
alr build
./bin/identity_tests
```

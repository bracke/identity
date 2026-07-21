# Security

Report vulnerabilities privately to the maintainer listed in `alire.toml`.

## Supported versions

This crate is pre-1.0 (`1.0.0-dev`). Only the current development line receives
fixes; there are no maintained release branches yet.

## Posture

Identity code fails closed when a cryptographic capability is unavailable. The
OS CSPRNG is required for salt generation, and verifier creation raises rather
than emit a predictable-salt verifier; the operations layer surfaces that as a
classified result (`Cryptographic_Conflict`) rather than an exception.

Passwords are stored only as PBKDF2-HMAC-SHA256 verifiers with a per-credential
16-byte OS-random salt at 600,000 iterations, compared in constant time. The
envelope parser that consumes stored verifier text is proved free of runtime
errors by GNATprove.

Secrets are represented by bounded controlled containers. Public projections
must not include credentials, token verifiers, bearer tokens, raw provider
assertions, contact values, roles, permissions, tenant memberships, delegation,
impersonation, administrative overrides, obligations, or enforcement receipts.

Authentication equalises timing across outcomes: an unknown subject, a wrong
password, and an ineligible account (suspended, locked, restricted) all pay the
same key derivation, so account state cannot be read off the response clock.

## Zeroization

Owned secret buffers are cleared on finalization through non-elidable volatile
stores (`CryptoLib.Secure_Wipe`), not a plain assignment an optimizer may
delete. The plaintext buffers used during verifier creation and verification
are scrubbed the same way as soon as the derivation completes. This guarantees
the owned buffers are overwritten; it does not claim erasure of every transient
copy the language or runtime may make.

## What is out of scope for V1

Authorization is deliberately not modeled: no roles, permissions, tenancy,
delegation, impersonation, overrides, obligations, or enforcement receipts. The
repository interface is a contract, not a sandbox -- a malicious adapter is
outside the threat model. See `docs/threat-model.md` for the full boundary.

# Security

Report vulnerabilities privately to the maintainer listed in `alire.toml`.

Identity code must fail closed when cryptographic capabilities are unavailable.
Secrets are represented by bounded controlled containers and public projections
must not include credentials, token verifiers, bearer tokens, raw provider
assertions, contact values, roles, permissions, tenant memberships, delegation,
impersonation, administrative overrides, obligations, or enforcement receipts.

Zeroization statement: logical clearing is guaranteed for owned secret buffers.
The implementation overwrites owned buffers on clear/finalization using the
strongest practical Ada mechanism available here; it does not claim universal
compiler-proof erasure of every temporary.

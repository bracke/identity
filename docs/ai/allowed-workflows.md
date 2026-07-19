# AI Allowed Workflows

Use Alire through `project_tools` gates. The machine-readable workflow list is
`tools/project_tools_workflows.toml`.

Allowed workflow names are:

- check
- test
- security-check
- conformance
- proof
- documentation-check
- fixtures-check
- release-check
- release-artifacts

Do not add parallel shell workflow scripts for release-critical checks. Keep
operation state transition logic transactional and bounded.

The tooling crate owns executable project checks that are part of these gates.
In particular, `identity_tools` validates the architecture boundary rules used
by `check`, `security-check`, and `release-check`.
It also validates `registries/proof-scope.json` so the `proof` workflow names a
concrete GNATprove scope instead of only listing the gate.

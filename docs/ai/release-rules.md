# AI Release Rules

Release gates include full build, AUnit, conformance, cryptolib self-tests,
secret leak scanning, concurrency, atomicity, disclosure, resource bounds,
format compatibility, registry validation, documentation, static architecture
checks, and GNATprove.

`tools/project_tools_workflows.toml` is the source for the expected
project_tools workflow names and release-gate grouping. A release artifact must
not be produced after a failed `release-check` gate.

`identity_tools` validates the project_tools workflow manifest by requiring the
root Identity crate metadata, the project_tools orchestrator declaration, all
standard workflow names, and mandatory gate identifiers.

`registries/proof-scope.json` records the initial GNATprove scope: concrete
packages, high-value proof properties, the project_tools orchestrator, the
`gnatprove` gate, and the rule that proof baselines may not be silently
lowered. Security-critical proof exclusions require documented compensating
tests.

`identity_tools` validates proof-scope coverage by requiring every mandatory
package and high-value property from the proof registry, rejecting undeclared
exclusions, and checking that proof remains tied to the project_tools-managed
GNATprove gate.

`identity_tools` performs an executable architecture boundary validation for
internal package references, cryptolib import isolation, and Identity's
separation from Authorization-owned concepts. Release and security checks must
treat a nonzero `identity_tools` result as a failed gate.

`identity_tools` also performs canary secret-leak validation across
documentation, registries, fixtures, tooling metadata, examples, and conformance
sources. Test-only canary definitions remain in the test crate; release-facing
artifacts must not contain those distinctive secret values.

`identity_tools` validates invariant traceability by requiring each registry
entry to include required-test metadata and failure severity. A registry entry
without test traceability is not release-ready.

`identity_tools` validates event registry coverage by requiring the
machine-readable event registry and `Identity.Events.Types` public constants to
carry the same V1 event identifiers across authentication, sessions, password
workflows, account administration, contact verification, MFA, recovery, API
keys, TOTP replay, and external assertion replay.

`identity_tools` validates crypto algorithm registry coverage by requiring the
mandatory V1 algorithm IDs, cryptolib implementation binding, format version
declarations, constant-time verification capability, separate creation and
verification permissions, and deprecation state.

`registries/release-artifacts.json` is the machine-readable inventory of
required release artifacts and prohibited sensitive material. Artifact
generation must include the inventory, provenance, digests, reports, and a
prohibited-material scan.

`identity_tools` validates the release artifact registry by requiring every V1
artifact ID, requiring all artifacts, rejecting sensitive artifact declarations,
checking the prohibited-material inventory, and requiring every release
provenance field before release artifact generation.

After every executable registry and boundary validation passes, `identity_tools`
writes deterministic, secret-free release report files under
`generated/release`. The generator is intentionally gated after validation so a
failed release check cannot refresh release-facing outputs.

`registries/persisted-formats.json` is the compatibility inventory for
persisted encodings. Release checks must validate the registry and deterministic
fixtures before artifact generation.

`identity_tools` validates persisted-format coverage by requiring every V1
format ID, every named compatibility fixture, all required compatibility flags,
and the presence of each fixture file.

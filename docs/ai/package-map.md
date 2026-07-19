# AI Package Map

Direct cryptolib imports are allowed only below `Identity.Crypto.Cryptolib`.
Public specs must not depend on `Identity.Internal`.
Safe public error projection lives in `Identity.Errors.Public`; adapters should
use it with `Identity.Operations.Disclosure` instead of rendering dependency
exceptions or diagnostic text.
Disclosure profile rules are exposed by `Identity.Operations.Disclosure.Rules_For`;
transport adapters should inspect that bounded contract rather than hard-code
their own public-detail matrix.
Event attributes are created through `Identity.Events.Attributes`; use the
policy-aware constructor when staging mandatory events so invalid event policy
or secret data classes are rejected before persistence.
Event type admission and schema metadata are exposed through
`Identity.Events.Schemas`; adapters should reject unknown event type IDs and
must use the registered schema version and mandatory-audit marker for V1
security events.

Cryptolib child packages must expose Identity-owned semantic contracts. If the
underlying cryptolib capability is unavailable, the child package returns an
explicit missing-capability result and must not provide a local fallback.
Key lookup contracts live in `Identity.Adapters.Keys`; they expose non-secret
key references and bounded admission decisions for creation and verification
so cross-domain, retired, revoked, missing, unavailable, and historical-only
keys do not flow into verifier construction.
Persisted format admission lives in `Identity.Codecs.Persisted`; use
`Admit_Canonical` before decoding repository or fixture payloads so version
window, supported-format, and canonical-framing failures remain structured.
Operation resource admission lives in `Identity.Operations.Budgets`; prefer
`Admit` for operation orchestration so the exceeded budget dimension remains
available with bounded requested and permitted values for safe diagnostics and
deterministic tests.

Repository adapters expose explicit domain commands and projections. Do not add
generic `Save`, `Update`, or `Delete` operations for security transitions.
Use `Identity.Adapters.Repositories.Capabilities.Admit_Transaction` with the
operation-scoped capability snapshot before security-transition work; mandatory
event transitions require security-transition, atomic-event, and optimistic
version support. Use `Admit_Command` before staging atomic workflow commands so
missing rotation, token action, replay registration, idempotency, event-count,
and command-size capabilities fail before mutation.
Attempt and lockout helpers are split across `Identity.Attempts.*`,
`Identity.Throttling.*`, and `Identity.Lockout.*`. Use
`Identity.Throttling.Decisions.Evaluate` for non-sleeping delay/reject
boundaries and
`Identity.Lockout.Evaluation.Evaluate_With_Policy` for cleanup-independent
lockout transitions based on a captured operation instant.
Action-token helpers live under `Identity.Tokens.*`; use
`Identity.Tokens.Verification.Evaluate` for precise internal token outcomes
before `Identity.Operations.Disclosure` collapses them for untrusted callers.
Idempotent one-time issuance is represented by
`Identity.Operations.Idempotency` and the repository SPI child
`Identity.Adapters.Repositories.Idempotency`; adapters must reserve, complete,
replay, and conflict keys explicitly and must not re-emit one-time secrets on a
completed replay.
Post-commit operation outputs are validated by
`Identity.Operations.Post_Commit`; use `Admit_For_Release` before handing
events, notifications, or one-time outputs to adapters so unsafe output is
rejected with a stable reason.

API-key service authentication is exposed in the authentication operation family
as `Identity.Operations.Authentication.API_Key` and in the API-key management
family as `Identity.Operations.API_Keys.Authenticate`. Both remain
transport-neutral and session-neutral.
Assurance evaluation is exposed through `Identity.Assurance.Evaluation`.
Profile requirements are explicit records and evaluation must use structured
assurance attributes, not method-name lookup.

External-provider policy is represented by
`Identity.External_Providers.Policies` and aggregated in immutable policy
snapshots. It requires trusted providers, replay registration inside the
authentication transition, explicit JIT
behavior, and prohibits email auto-linking.
`Identity.External_Providers.Trust` is the public admission boundary for these
facts: it maps provider lifecycle state and local policy to bounded admission
decisions before a normalized assertion can authenticate, enroll, or JIT
provision a local principal.

Session activity updates are exposed as
`Identity.Operations.Sessions.Update_Activity`; it returns a bounded
`Session_Handle` and must not expose bearer verifiers or repository records.
Session enumeration is exposed as `Identity.Operations.Sessions.Enumerate`;
it returns bounded `Session_Summary_Projection` values and never returns
public references, bearer verifiers, or mutable repository entities.
Session-domain code may use `Identity.Sessions.Projections.Summary`; it is the
normative session package-family entry point for the same verifier-free bounded
summary projection.
Session assurance upgrades are exposed as
`Identity.Operations.Sessions.Upgrade_Assurance` and share the same
same-principal, satisfied-transaction, active-session checks used by
authentication step-up.

The normative recovery begin operation is exposed as
`Identity.Operations.Recovery.Begin_Recovery` because `begin` is an Ada
reserved word. Treat it as the package-map equivalent of
`Identity.Operations.Recovery.Begin`; do not attempt to add a child package
named `Begin`.

Companion crates:

- `crates/identity_tests` contains AUnit and invariant smoke coverage.
- `crates/identity_examples` contains the transport-neutral `identity_lifecycle`
  example. It demonstrates principal/account/binding/password setup,
  authentication, stateful session creation, lookup, staged rotation, and
  predecessor rejection without HTTP, cookies, HTML, Forms, Templates, or
  Authorization.
- `crates/identity_conformance` exposes repository conformance entry points.
- `crates/identity_tools` exposes project/release tooling entry points.

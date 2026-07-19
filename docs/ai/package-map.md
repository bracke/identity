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

## Public package families

Every top-level family present under `src/public`. The documentation gate
(`identity_tools:documentation`) fails if a family exists in `src/public` but is
not named here.

- `Identity.Accounts` - account lifecycle, state dimensions, security locks,
  administrative transitions, and account projections.
- `Identity.API_Keys` - API-key credential material, key policies, and rotation.
- `Identity.Assurance` - assurance levels, attributes, profiles, dependencies,
  and structured evaluation.
- `Identity.Attempts` - attempt buckets, fingerprints, outcomes, and policies.
- `Identity.Audit` - audit records, integrity marks, and audit policies.
- `Identity.Authentication` - requests, contexts, challenges, evidence,
  revisions, results, security contexts, and authentication transactions.
- `Identity.Clocks` - the abstract clock interface used to inject time.
- `Identity.Codecs` - canonical and persisted encoding, including
  `Identity.Codecs.Persisted` admission.
- `Identity.Collections` - bounded maps, sets, and vectors.
- `Identity.Contacts` - contact points and their verification state.
- `Identity.Contracts` - the `Contract_Status` vocabulary for condition results.
- `Identity.Correlation` - correlation and causation links.
- `Identity.Credentials` - credential state, kinds, and credential requirements.
- `Identity.Crypto` - domain separation and key handling, including the
  `Identity.Crypto.Cryptolib` isolation subtree.
- `Identity.Diagnostics` - structured diagnostic records for failures.
- `Identity.Errors` - the structured error vocabulary and the safe public
  projection in `Identity.Errors.Public`.
- `Identity.Events` - event types, attributes, schemas, and staging.
- `Identity.External_Providers` - assertion normalization, provider policies,
  and `Identity.External_Providers.Trust` admission.
- `Identity.Identifiers` - strongly typed identifiers.
- `Identity.Identities` - identity records and their projections.
- `Identity.Limits` - the bounded sizes shared by the public contracts.
- `Identity.Lockout` - lockout state and cleanup-independent evaluation.
- `Identity.Multi_Factor` - factor kinds, enrollment state, and challenges.
- `Identity.One_Time_Passwords` - one-time password material and replay state.
- `Identity.Operations` - the transport-neutral operation families
  (authentication, sessions, accounts, API keys, recovery, disclosure, budgets,
  idempotency, and post-commit admission).
- `Identity.Optionals` - the generic `Optional` container.
- `Identity.Passwords` - password policy, verifier state, and change/reset
  contracts.
- `Identity.Policies` - shared policy value types.
- `Identity.Principals` - principal records and projections.
- `Identity.Projections` - the shared read-only projection types.
- `Identity.Recovery` - recovery requests, state, and completion contracts.
- `Identity.Recovery_Codes` - recovery-code material and consumption state.
- `Identity.Redaction` - the predicates that decide what is safe for public
  output.
- `Identity.Results` - `Operation_Status` and the shared result vocabulary.
- `Identity.Secrets` - bounded, redacted secret containers.
- `Identity.Service_Credentials` - service credential records and projections.
- `Identity.Service_Principals` - service principal records.
- `Identity.Services` - service definitions and their state.
- `Identity.Sessions` - session records, state, and verifier-free projections.
- `Identity.System_Actors` - system actor records and projections.
- `Identity.Testing` - deterministic test profiles and injection seams.
- `Identity.Text` - the bounded text types.
- `Identity.Throttling` - non-sleeping delay and reject boundaries.
- `Identity.Times` - instants, durations, and time arithmetic.
- `Identity.Tokens` - action-token material, state, and verification.
- `Identity.Verification` - verification state for contacts and credentials.
- `Identity.Version` - the crate version constants.
- `Identity.Versions` - entity and persisted format version types.

Companion crates:

- `crates/identity_tests` contains AUnit and invariant smoke coverage.
- `crates/identity_examples` contains the transport-neutral `identity_lifecycle`
  example. It demonstrates principal/account/binding/password setup,
  authentication, stateful session creation, lookup, staged rotation, and
  predecessor rejection without HTTP, cookies, HTML, Forms, Templates, or
  Authorization.
- `crates/identity_conformance` exposes repository conformance entry points.
- `crates/identity_tools` exposes project/release tooling entry points.

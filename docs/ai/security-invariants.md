# AI Security Invariants

Use `registries/invariants.json` as the machine-readable source. Critical
invariants require tests and adapter obligations.

`identity_tools` validates that each invariant registry entry carries
required-test traceability and failure-severity metadata. Missing test
traceability is a failed release gate.

Current implemented critical groups include secret redaction, secret-text UTF-8
admission, semantic secret family hard-limit validators, token domain separation, one-time secret extraction, pepper material typing, disclosure
collapse and disclosure-status classifiers, binding uniqueness with lifecycle admission, principal lifecycle
predicate admission, principal retirement,
staged principal retirement,
password operation boundaries, identity binding lifecycle, staged identity-binding revocation, staged identity-binding change, verified replacement,
purpose-bound reset request verifier derivation, atomic reset completion, independent account-state restrictions, verifier-only
session persistence, expected-version action-token single use, purpose-bound atomic contact
verification, immutable safe projections, bounded session-summary enumeration,
policy snapshot hard-limit validation,
account eligibility classification,
explicit service and operation contexts with bounded budgets, deadlines, and
cooperative cancellation-source classifiers,
repository contexts with explicit transaction state and rollback-on-close,
bounded deterministic foundation collections, versioned canonical persisted codecs,
typed event attributes that reject secret classes, bounded diagnostics and redaction,
diagnostic success and failure classification without rendered-text comparisons,
durable audit records with explicit integrity state,
policy-aware audit requirement checks for event data classes,
event policy contracts that bound attributes, reject secret event classes, and
require post-commit publication,
event-sink admission contracts that reject failed status, pre-commit timing, and
invalid publication policy before adapter delivery,
service-principal verifier credentials, non-bypass system actors,
explicit MFA method/enrollment contracts and session-family step-up bindings,
repository child-view contracts for principals, identities, contacts, accounts,
credentials, authentication transactions, challenges, sessions, tokens, attempts,
external bindings, idempotency reservation/staged completion/replay without duplicate
one-time secret output, mandatory events, and conformance profiles,
implementation-only internal boundaries for orchestration, transitions,
validation, encoding, event staging, resource budgets, and crypto bindings,
crypto algorithm registries with separate creation and verification, explicit
missing-capability results, and key lifecycle state,
deterministic testing clocks, entropy scripts, bounded consumable failure checkpoints, barriers,
stable fixture identifiers, and canary metadata,
project_tools-owned workflow manifests for check, test, security, conformance,
proof, documentation, fixture, release, and artifact gates,
bounded password acceptance, secret-free length admission, hashing, history, migration, staged change, and staged reset
policy contracts, synthetic verification for unresolved password subjects,
plus API-key, TOTP, and recovery-code policy and regeneration-admission contracts,
external-provider, key, notification, event-sink, diagnostic, and transport
adapter contracts that preserve core boundaries,
distinct policy-version vector fields for aggregated public policy families,
session state/expiration/activity admission/rotation/family/replay/assurance helpers,
session handle status classifiers, token generation/consumption projections, recovery authority/restriction helpers,
and bounded attempt-recording authentication requests with deterministic
password-failure lockout plus throttle/lockout/fingerprint policies,
account dimension helpers with explicit terminal-state transition admission,
principal/contact lifecycle helpers, and credential
lifecycle/replacement/revocation/factor/projection/dependency helpers,
credential lifecycle admission classifiers,
bounded authentication request/context contracts, normalized external assertion
core admission, and attribute-based assurance evaluation with dependency independence,
bounded UTF-8 text validation, explicit redacted text projection, stable
message identifiers, structured error codes/messages/retry/diagnostics, and
Identity-owned time helper constructors with checked expiration construction,
token kind registries, generic token issue verifier derivation, token issuance
admission, split-token parsing classifiers, token verification state-priority helpers, and contact verification state, staged contact verification, contact binding lifecycle, contact-change state admission, verifier derivation, policy, and result
contracts that keep contact-control proof separate from authentication success,
explicit recovery evidence source records with principal/transaction binding and
reduced-assurance defaults,
API-key verifier-only issuance, request-side staged rotation verifier derivation,
credential authentication admission, staged service authentication, last-use metadata
transitions, rotation, and staged revocation,
secret-free event envelopes, bounded attempt/lockout accounting, single-use
verifier-only recovery codes with request-side derivation, explicit matched-code
admission, expected-version consume conflicts, and staged regeneration, persistent account recovery transactions with
explicit begin, expiration, staged evidence acceptance, staged completion, staged cancellation, and transition admission plus structured recovery restrictions, persistent MFA transactions with
explicit begin, expiration, transaction, staged challenge issuance, staged challenge completion, staged satisfaction, and
assurance-upgrade admission, challenge issuance admission, challenge-bound
evidence, session-bound staged step-up assurance upgrades,
session-named assurance upgrade operations,
external-provider binding lifecycle/revocation/staged revocation/staged authentication/replay registration transition rules, TOTP request-side pending enrollment,
proof-before-activation, request-side verifier derivation, expected-version enrollment completion, expected-version counter acceptance, expected-version factor removal, explicit counter admission, replay-state advancement, and factor removal, and
stateful session verifier-only request creation, staged revocation, staged family revocation, staged principal revocation, staged credential/provider revocation, and staged rotation, renewal, explicit expiration, retained-record purge, rotation
with predecessor rejection, family revocation, and principal-wide session
revocation, credential-derived session revocation, provider-derived session
revocation, external provider definitions, local assurance mapping, explicit
enrollment/JIT decisions, safe external binding projections, and purpose-bound
contact-change verifier derivation and staged activation.

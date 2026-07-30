# Identity Threat Model

Version: 1.0.0-dev

## 1. Scope and method

Identity is a headless, transport-neutral authentication core. This document
states what it defends, what it does not defend, and — for each threat — the
concrete control that mitigates it and the registry invariant that pins that
control to an executable test.

The threat vocabulary here is not invented for this document. It is the
`threats_mitigated` vocabulary of `registries/invariants.json`: 80 invariant
entries carrying 80 distinct identifiers and 59 distinct threat labels. Every
invariant id cited below exists in that registry, and every one of those
invariants carries `required_tests` names that `identity_tools` refuses to
accept unless they appear verbatim in real evidence — the AUnit suite, the gate
self-tests, the conformance harness, or the examples. Metadata presence alone is
not accepted as traceability.

The controls described here are therefore claims that a release gate can
falsify. Where a control does not exist, section 9 says so rather than
implying coverage.

## 2. Assets

Ranked by what their disclosure or forgery would cost.

**Authentication secrets — persisted only one-way, with one deliberate
exception.** Passwords, session bearer credentials, action-token secrets (reset,
contact verification, contact change), API-key secrets, recovery codes, pepper
material, and key material. The crate's central persistence rule is that none of
these are stored: only derived verifier envelopes are (`IDENTITY-SECRET-001`,
`IDENTITY-SECRET-002`, `IDENTITY-SESSION-001`, `IDENTITY-TOKEN-002`,
`IDENTITY-APIKEY-001`, `IDENTITY-RECOVERY-001`).

The exception is the TOTP shared secret. TOTP is symmetric: verifying a code
means recomputing it from the same secret, so a one-way hash could never verify
and the crate would have to hand the secret back to every caller to verify —
which is not verification the crate performs. Instead the shared secret is
stored **sealed** (AES-256-GCM, `Identity.Crypto.CryptoLib.Secret_Box`) under a
key the caller supplies at enrollment and again at verification; the crate never
persists that key. A database read alone therefore yields ciphertext with an
integrity tag, not a usable seed. The at-rest key is the caller's to manage, and
its compromise **together with** a database read does expose TOTP seeds — a
narrower exposure than a plaintext seed, but a real one, and the reason TOTP is
called out separately from the one-way secrets above (`IDENTITY-TOTP-001`,
`IDENTITY-CRYPTO-004`).

**Verifier records and their parameters.** Envelopes disclose algorithm and cost
parameters. Those parameters are themselves an attack surface: an
attacker-supplied envelope with an absurd iteration count is a denial-of-service
vector, which is why cost is bounded on both sides (`IDENTITY-CRYPTO-002`,
`IDENTITY-PASSWORD-POLICY-001`).

**Identity and state records.** Principals, accounts, identity bindings,
external-provider bindings, credentials, sessions and session families,
authentication and recovery transactions, challenges, attempts, lockout state,
replay markers, and idempotency reservations.

**Accountability records.** Security events and audit records. Their value is
that they cannot be silently omitted (`IDENTITY-AUDIT-001`) or poisoned with
secret material (`IDENTITY-EVENT-001`).

**Existence facts.** Whether a subject exists, whether an account is locked,
whether a factor is enrolled, whether a token is consumed rather than merely
wrong. These are assets because leaking them is the enumeration attack
(`IDENTITY-DISCLOSURE-001`).

## 3. Trust boundaries

```
        untrusted input
              |
    [ transport adapter ]  <-- outside the crate: HTTP, cookies, Forms,
              |                Validation, Templates, rendering
    ==========|=================== crate boundary ===================
              v
      Identity.Operations          public workflows, trusted results
              |
      domain + crypto contracts    Identity-owned semantics
              |
     +--------+--------+---------------+
     v                 v               v
 Repository SPI   Cryptolib subtree  Adapter SPIs
 (store impls)    (only place        (keys, notifications,
                  cryptolib is       event sinks, diagnostics,
                  imported)          external providers)
    ==================================================================
              |
       [ Authorization ]  <-- deliberately outside V1 entirely
```

Trust decreases outward. Four properties of this boundary are enforced
statically by `identity_tools` and fail the release check
(`IDENTITY-ARCH-002`, `IDENTITY-INTERNAL-001`):

- public specs carry no `Identity.Internal` dependency;
- direct cryptolib imports occur only under `Identity.Crypto.CryptoLib.*`, so
  there is exactly one place where a cryptographic substitution could be
  introduced;
- no authorization-boundary vocabulary appears in Identity source;
- companion crates use public contracts only.

The crate never crosses the boundary outward on its own: it opens no sockets,
sends no mail, and reads no clock. Time is injected (`Identity.Clocks`), and
entropy arrives through `Identity.Crypto.Entropy`.

## 4. Attacker models considered

| # | Attacker | Capability assumed |
|---|----------|--------------------|
| A1 | Anonymous remote caller | Arbitrary, malformed, oversized, and non-UTF-8 input at every public operation; unlimited request volume |
| A2 | Credential guesser | Large breach-corpus password lists; distributed source addresses; subject enumeration probes |
| A3 | Bearer-secret holder | Possession of a stolen session secret, action token, API key, or recovery code, possibly after rotation |
| A4 | Replayer | Capture and resubmission of tokens, TOTP counters, external assertions, and rotated session predecessors |
| A5 | Race exploiter | Concurrent requests deliberately interleaved to double-spend a single-use secret or win a check-then-act window |
| A6 | Timing observer | Measurement of verification latency to distinguish outcomes |
| A7 | Database reader | Full read of persisted state, without write access |
| A8 | Persistence tamperer | Selected corruption of stored frames: truncated, oversized, noncanonical, future-version |
| A9 | Malicious or compromised external provider | Forged, expired, replayed, or cross-tenant assertions from a federated IdP |
| A10 | Misusing administrator | Administrative operations used to clear restrictions or reuse retired actors |
| A11 | Resource exhauster | Oversized inputs, stored parameters chosen to be expensive, unbounded collection growth |
| A12 | Event injector | Attempts to write attacker-controlled or secret-bearing data into the audit trail |
| A13 | Supply-chain actor | Tampering with registries, fixtures, release artifacts, or gate definitions |

## 5. Attacker models explicitly NOT considered

Stating these plainly is the point of this section. None of the following is
defended against, and no invariant claims otherwise.

- **A privileged local attacker.** Anyone who can read process memory, attach a
  debugger, or read core dumps defeats every control here. Secret containers
  bound and redact values; they do not defend live memory.
- **A compromised cryptolib.** Every derivation, MAC, and constant-time
  comparison is delegated. The crate isolates cryptolib to one subtree so the
  blast radius is auditable, but a backdoored primitive is game over.
- **A compromised compiler or runtime.** Memory clearing depends on the
  compiler not optimising it away. Nothing here verifies that it did not.
- **A malicious repository adapter.** The SPI is a contract, not a sandbox. An
  adapter that lies about a commit, silently drops an event, or returns another
  principal's record is trusted and will be believed. Conformance profiles test
  a cooperative adapter, not an adversarial one.
- **A malicious transport adapter.** Disclosure rules are published for adapters
  to apply. An adapter that ignores `Identity.Operations.Disclosure` and renders
  internal outcomes directly re-introduces enumeration, and the crate cannot
  detect it.
- **Write access to the datastore.** A7 is a read compromise. An attacker who
  can write verifier records can install a verifier for a secret they know.
- **Network-level adversaries.** No transport security, TLS, certificate, or
  channel-binding concern is in scope. There is no transport.
- **Denial of service as an availability goal.** Bounds exist to keep the crate
  deterministic and to stop stored parameters from amplifying cost. They are not
  a claim that the service stays up under load.
- **Side channels beyond comparison timing.** Cache, branch-prediction, and
  power analysis are out of scope. Only the verifier comparison is
  constant-time.
- **Authorization.** See section 9.

## 6. Threats mapped to controls and invariants

Each row: the threat label as it appears in `threats_mitigated`, the concrete
mechanism, and the invariant ids that pin it.

### 6.1 Credential compromise and offline attack

| Threat | Control | Invariants |
|---|---|---|
| `offline-cracking` | Passwords are accepted only through bounded UTF-8-validated secret containers and persisted only as PBKDF2-HMAC-SHA256 verifier envelopes with a 16-byte per-credential salt. Cost is bounded on both sides so a weak envelope is flagged for migration and an expensive one cannot be used as a DoS. | `IDENTITY-SECRET-001`, `IDENTITY-PASSWORD-POLICY-001`, `IDENTITY-CRYPTO-002`, `IDENTITY-CRYPTO-004` |
| `breached-password-reuse` | A compromised-password boundary: the policy's Compromised_Check_Enabled flag is backed by an adapter that receives a non-secret hash prefix (k-anonymity) and returns a verdict; a compromised password is rejected when the check is enabled, and an unavailable check fails open so a down breach service cannot block rotation. The plaintext never crosses the boundary. | `Identity.Adapters.Compromised_Passwords`, `Identity.Passwords.Policies` |
| `audit-tampering` | The audit log is hash-chained: each head commits to the previous head and the next event's canonical encoding under the event-integrity domain, so deleting, reordering, or modifying any event changes the head. Anchoring the head externally makes such tampering by a store administrator detectable. | `Identity.Audit.Chain` |
| `database-read-compromise` | No table holds a directly usable secret. Sessions store a public reference plus a domain-separated verifier; API keys store a public key id plus a verifier; recovery codes store verifier text and single-use state. TOTP is the one symmetric case: the seed is stored **sealed** (AES-256-GCM) under a caller-managed key the crate never persists, plus a replay counter — a read alone yields ciphertext with an integrity tag, and recovering the seed additionally requires the caller's at-rest key. A full read otherwise yields nothing directly presentable. | `IDENTITY-SESSION-001`, `IDENTITY-APIKEY-001`, `IDENTITY-RECOVERY-001`, `IDENTITY-SECRET-002`, `IDENTITY-PROJECTION-001`, `IDENTITY-CRYPTO-004` |
| `credential-theft` | Sessions may carry a bounded optional credential reference, so replacing or revoking a credential revokes exactly the sessions derived from it. | `IDENTITY-SESSION-002` |
| `api-key-theft` | Verifier-only storage, bounded active-key capacity, mandatory expiration, and rotation with positive overlap. | `IDENTITY-APIKEY-001`, `IDENTITY-CREDENTIAL-POLICY-001`, `IDENTITY-SERVICE-001` |
| `key-compromise`, `active-token-theft` | Key references are non-secret and domain-bound, and lifecycle separates active creation keys from historical verification-only keys. A verification-only key cannot mint new verifier material. | `IDENTITY-KEYS-001`, `IDENTITY-ADAPTER-KEYS-001` |
| `cryptographic-substitution` | Cryptolib imports are confined to one subtree by an executable release gate; child packages must return an explicit missing-capability result rather than silently falling back to a local algorithm. | `IDENTITY-ARCH-002`, `IDENTITY-CRYPTO-003` |

### 6.2 Online guessing and enumeration

| Threat | Control | Invariants |
|---|---|---|
| `credential-stuffing` | Attempts are first-class bounded records with typed failure buckets; only failed attempts with a concrete credential failure category advance credential counters, so operational failures cannot be used to drive lockout. | `IDENTITY-ATTEMPT-001`, `IDENTITY-ATTEMPT-002`, `IDENTITY-CREDENTIAL-001`, `IDENTITY-PASSWORD-POLICY-001` |
| `online-guessing` | Deterministic threshold evaluation over failure counts, and non-sleeping throttling that returns delay or reject boundaries for the caller to enforce. | `IDENTITY-ATTEMPT-001`, `IDENTITY-ATTEMPT-002` |
| `user-enumeration` | Untrusted disclosure profiles collapse credential, account, and invalid-token causes into one generic rejection, while preserving resource-limit and operational failures as non-rejections. Unresolved subjects still perform synthetic password verification before returning that identical result. | `IDENTITY-DISCLOSURE-001`, `IDENTITY-AUTH-002`, `IDENTITY-CREDENTIAL-001`, `IDENTITY-ERROR-001`, `IDENTITY-VERIFICATION-001` |
| `subject-guessing` | Subject fingerprints in attempt records are keyed and domain-separated rather than raw subject values. | `IDENTITY-ATTEMPT-002`, `IDENTITY-AUTH-002` |
| `subject-ambiguity` | An active normalized binding for one subject kind maps to at most one active principal; resolution reports `Ambiguous` distinctly internally and collapses it publicly. | `IDENTITY-IDENTITY-001` |
| `factor-enrollment-disclosure`, `token-state-disclosure` | Disclosure profile rules are an explicit bounded contract with monotonic detail ordering, so a less trusted profile provably cannot reveal more than a more trusted one. | `IDENTITY-DISCLOSURE-001` |

Timing (A6) is addressed narrowly: verifier comparison is constant-time
(`Identity.Crypto.Constant_Time.Equal`), and the synthetic-verification path
exists so that an unresolved subject costs roughly what a resolved one does.
Overall operation latency is not equalised.

### 6.3 Bearer-secret and session theft

| Threat | Control | Invariants |
|---|---|---|
| `session-theft` | Verifier-only session persistence, revocation by session, family, principal, credential, or provider, and expiration evaluated from an injected instant rather than a cleanup job. | `IDENTITY-SESSION-001`, `IDENTITY-SESSION-002`, `IDENTITY-SESSION-003`, `IDENTITY-SESSION-004`, `IDENTITY-SESSION-005`, `IDENTITY-TIME-001` |
| `stolen-token-cross-client` | Optional token binding: a session may carry a non-secret client fingerprint (channel binding, client-key thumbprint). A bound token presented from a different client -- or with no fingerprint -- is a theft signal; unbound sessions keep bearer semantics. Narrows the window a lifted bearer secret is usable beyond what rotation and replay detection give. | `Identity.Sessions.Binding` |
| `token-theft` | Bearer secrets exist as one-time extractable values; tokens persist a domain-separated verifier and a purpose. | `IDENTITY-TOKEN-001`, `IDENTITY-SECRET-002`, `IDENTITY-VERIFICATION-001`, `IDENTITY-TIME-001` |
| `reset-token-theft` | Reset tokens are purpose-bound; a newer reset token supersedes earlier live siblings, and successful completion consumes the presented token and supersedes siblings in the same protected transition. | `IDENTITY-TOKEN-002`, `IDENTITY-TOKEN-003`, `IDENTITY-RECOVERY-003`, `IDENTITY-ADAPTER-NOTIFY-001` |
| `session-fixation` | New and rotated sessions require an active principal and produce a fresh public reference and verifier; a caller cannot pre-seed a session identifier. | `IDENTITY-SESSION-005` |
| `rotated-token-replay` | Rotation marks the predecessor unusable and publishes exactly one successor with an advanced generation. Presenting the predecessor is a replay with explicit consequence predicates: reject, revoke successor, revoke family, revoke all principal sessions, or require reauthentication. | `IDENTITY-SESSION-001`, `IDENTITY-SESSION-004`, `IDENTITY-SESSION-005` |
| `stale-context-use` | Authenticated security contexts carry separate authentication, evidence, and session revisions, so a consumer can reject a cached context after the underlying facts changed. Renewal advances the revision. | `IDENTITY-SESSION-001`, `IDENTITY-SESSION-002`, `IDENTITY-SESSION-003`, `IDENTITY-STEPUP-001`, `IDENTITY-PROJECTION-001` |
| `cleanup-dependent-expiry` | Expiration and lockout state are projected from a captured operation instant with checked arithmetic; an expired temporary lock is usable again without a cleanup mutation. | `IDENTITY-TIME-001` |

### 6.4 Replay and cross-purpose substitution

| Threat | Control | Invariants |
|---|---|---|
| `cross-purpose-substitution` | Every bearer verifier is derived under an explicit cryptographic domain (`Identity.Crypto.Domains` declares nine: session token, password reset, contact verification, API key, recovery code, TOTP seed, subject fingerprint, external-assertion fingerprint, event integrity). A verifier derived in one domain does not verify in another. Crypto input is canonically framed, so domain separation cannot be defeated by concatenation ambiguity. | `IDENTITY-TOKEN-001`, `IDENTITY-TOKEN-002`, `IDENTITY-TOKEN-003`, `IDENTITY-CONTACT-001`, `IDENTITY-CONTACT-CHANGE-001`, `IDENTITY-KEYS-001`, `IDENTITY-ADAPTER-KEYS-001`, `IDENTITY-CRYPTO-003`, `IDENTITY-CRYPTO-004`, `IDENTITY-CODEC-001`, `IDENTITY-VERIFICATION-001` |
| `replay`, `token-replay` | Terminal token states (`Consumed`, `Completed`, `Superseded`) cannot reactivate or be consumed twice; consumption is one repository transition. | `IDENTITY-TOKEN-002`, `IDENTITY-TOKEN-003`, `IDENTITY-CONTACT-001`, `IDENTITY-RECOVERY-001`, `IDENTITY-REPOSITORY-003`, `IDENTITY-REPOSITORY-004` |
| Command-level replay of externally triggered operations | The five operations that are triggered from outside and cannot safely be repeated — password reset request, contact verification request, recovery begin, API-key issue, session rotate — offer an idempotency-key overload that reserves the key through the SPI before the transition and closes it after. A replayed reservation returns the recorded outcome instead of repeating the transition. This is opt-in per call: see section 9. | `IDENTITY-REPOSITORY-004` |
| `totp-replay` | TOTP credentials carry a highest-accepted counter; acceptance advances it and rejects same-or-older counters. | `IDENTITY-TOTP-001`, `IDENTITY-MFA-001`, `IDENTITY-MFA-002`, `IDENTITY-CREDENTIAL-POLICY-001`, `IDENTITY-CRYPTO-003` |
| `phishing` | A phishing-resistant possession factor: passkeys (WebAuthn public-key credentials) are stored with the public key and an authenticator sign count. Signature verification is the identity_webauthn adapter's job; the core stores the credential and consumes a verified assertion. | `Identity.WebAuthn.Credentials`, `Identity.Operations.Factors.Register_Passkey`, `Identity.Operations.Factors.Accept_Passkey_Assertion` |
| `passkey-clone` | WebAuthn clone detection: a presented sign count that is equal-or-lower than the stored one, with either non-zero, is a cloned authenticator replaying a captured assertion and is rejected; a strictly greater count advances the replay state; both zero is a counterless authenticator. The possession analogue of TOTP counter replay. | `Identity.WebAuthn.Credentials` (Evaluate_Sign_Count, Admit_Assertion) |
| `single-use-race` | Single-use consumption is staged with an expected version; a stale version conflicts before consumed-state disclosure or secret verification. | `IDENTITY-CONTACT-001` |

### 6.5 Multi-factor, step-up, and evidence

| Threat | Control | Invariants |
|---|---|---|
| `mfa-bypass` | Authentication transactions and challenges are separate persistent records. A challenge is bound to one principal and one transaction, and a transaction cannot become satisfied before challenge evidence has accumulated. | `IDENTITY-MFA-001`, `IDENTITY-TOTP-001`, `IDENTITY-STEPUP-001` |
| `evidence-transfer` | Step-up upgrades exactly one active same-principal session from a satisfied transaction, then consumes the transaction so the same evidence cannot upgrade a second session. Step-up bindings must match session id, principal, family, and rotation generation. | `IDENTITY-STEPUP-001`, `IDENTITY-STEPUP-002`, `IDENTITY-MFA-001` |
| `mfa-fatigue` | Bounded challenge and attempt limits, and assurance decided from structured attributes and independent-factor counts rather than method-name lookup. | `IDENTITY-MFA-002`, `IDENTITY-ASSURANCE-002`, `IDENTITY-CREDENTIAL-002`, `IDENTITY-RECOVERY-004` |

### 6.6 Recovery abuse

| Threat | Control | Invariants |
|---|---|---|
| `recovery-abuse` | Recovery is a persistent transaction with explicit states starting only for an active principal. Completion requires accepted evidence and applies structured restrictions, so authentication returns `Recovery_Action_Required` until they are explicitly cleared. Recovery evidence defaults to reduced assurance. | `IDENTITY-RECOVERY-001`, `IDENTITY-RECOVERY-002`, `IDENTITY-RECOVERY-003`, `IDENTITY-RECOVERY-004`, `IDENTITY-RECOVERY-004`, `IDENTITY-ACCOUNT-002`, `IDENTITY-ASSURANCE-002`, `IDENTITY-PASSWORD-AUTHORITY-001`, `IDENTITY-PRINCIPAL-002`, `IDENTITY-CREDENTIAL-002`, `IDENTITY-MFA-002`, `IDENTITY-CREDENTIAL-POLICY-001` |
| `restriction-bypass` | Restrictions are a structured record, not a boolean. Reset policy validation rejects any policy that would clear administrative restrictions, and successful authentication does not silently clear them. | `IDENTITY-ACCOUNT-001`, `IDENTITY-RECOVERY-002` |
| Recovery-code reuse | Codes are stored as domain-separated verifiers, single-use, transitioning to `Consumed`; regeneration revokes prior verifiers under an explicit admission check. | `IDENTITY-RECOVERY-001` |

### 6.7 Federation and external providers

| Threat | Control | Invariants |
|---|---|---|
| `external-identity-misbinding` | External assertions authenticate only through an explicit active binding keyed by provider id, issuer, and external subject. Email and alternate claims never auto-link — this is enforced as a policy validation rejection, not a convention. | `IDENTITY-EXTERNAL-001`, `IDENTITY-EXTERNAL-002`, `IDENTITY-ADAPTER-EXTERNAL-001`, `IDENTITY-IDENTITY-001`, `IDENTITY-PRINCIPAL-002`, `IDENTITY-SESSION-003`, `IDENTITY-REPOSITORY-004` |
| `malicious-provider-or-tenant` | Provider lifecycle state gates admission: suspended and retired providers, invalid policy snapshots, and email-only matches are rejected before local principal admission. Provider-derived sessions are revocable by provider without relying on contact values. | `IDENTITY-EXTERNAL-001`, `IDENTITY-EXTERNAL-002`, `IDENTITY-SESSION-003` |
| `provider-misuse` | Assertions enter the core only after adapter validation, as normalized records whose adapter status is `Validated`. Replay fingerprints are registered explicitly inside the authentication transition, and assertion admission rejects expired assertions and missing or invalid nonces at the boundary. | `IDENTITY-ADAPTER-EXTERNAL-001`, `IDENTITY-EXTERNAL-001`, `IDENTITY-EXTERNAL-002`, `IDENTITY-SERVICE-001`, `IDENTITY-SESSION-003`, `IDENTITY-ASSURANCE-002`, `IDENTITY-SYSTEM-001` |

### 6.8 Account, principal, and credential state confusion

| Threat | Control | Invariants |
|---|---|---|
| `account-state-confusion` | Administrative state, credential requirements, and lock state are independent dimensions. Authentication observes them; it does not flatten or clear them. | `IDENTITY-ACCOUNT-001`, `IDENTITY-ACCOUNT-002`, `IDENTITY-PRINCIPAL-001`, `IDENTITY-RECOVERY-002` |
| `retired-actor-reuse` | Principal lifecycle is independent of credentials and bindings: once retired, existing active bindings and credentials cannot produce a successful authentication, and no new bindings can be added. | `IDENTITY-PRINCIPAL-001` |
| `credential-state-confusion` | Credential lifecycle admission distinguishes active-required, inactive-slot, terminal, successor-state, and migration-state rejections. Migration follows successful old-verifier validation and cannot complete from an active predecessor. | `IDENTITY-PRINCIPAL-001`, `IDENTITY-CONTACT-001`, `IDENTITY-SESSION-002`, `IDENTITY-CREDENTIAL-002` |
| `administrative-misuse` | Administrative transitions must carry a structurally valid authenticated actor, reason id, operation id, correlation id, request time, expected version, previous and new state, and a mandatory-audit requirement. Closed and retired accounts are terminal for public administrative operations. | `IDENTITY-ACCOUNT-001`, `IDENTITY-ACCOUNT-002`, `IDENTITY-PASSWORD-AUTHORITY-001`, `IDENTITY-PRINCIPAL-002`, `IDENTITY-RECOVERY-002`, `IDENTITY-RECOVERY-003`, `IDENTITY-SYSTEM-001` |
| `contact-misbinding` | A verified contact is never overwritten by a change request. The successor is verified, the predecessor retired, the token consumed, and the change activated atomically. | `IDENTITY-CONTACT-001`, `IDENTITY-CONTACT-CHANGE-001` |
| `authorization-boundary-confusion` | System actors authenticate as system principals but expose no bypass state; `Establishes_Identity_Only` and `Requires_Downstream_Policy` make the boundary explicit. A release gate fails the build if authorization vocabulary appears in Identity source. | `IDENTITY-SYSTEM-001`, `IDENTITY-ARCH-002` |

### 6.9 Disclosure and diagnostic leakage

`diagnostic-leakage` is the single most frequently cited threat in the registry
(27 of 80 invariants), because it is the failure mode that every other control
leaks through.

| Threat | Control | Invariants |
|---|---|---|
| `diagnostic-leakage` | Public projections are dedicated immutable records containing no plaintext secrets, verifier payloads, repository handles, or backend internals. Errors project through `Identity.Errors.Public` with stable codes and no dependency text. Redaction returns a fixed marker for Personal, Sensitive, Secret, and Derived_Secret classes. Diagnostic detail is suppressed unless explicitly requested on an operational path. | `IDENTITY-PROJECTION-001`, `IDENTITY-DISCLOSURE-001`, `IDENTITY-ERROR-001`, `IDENTITY-DIAGNOSTIC-001`, `IDENTITY-TEXT-001`, `IDENTITY-SECRET-001`, `IDENTITY-SECRET-002`, `IDENTITY-CONTEXT-001`, `IDENTITY-ADAPTER-SINK-001`, `IDENTITY-ADAPTER-NOTIFY-001`, `IDENTITY-INTERNAL-001`, `IDENTITY-FOUNDATION-001` |
| `secret-leak-attempts` | Secret containers expose only presence and length as non-secret metadata and have no ordinary image or serialization path. Notification handoffs reject secret-bearing requests. Release-facing artifacts are canary-scanned by an executable gate. | `IDENTITY-SECRET-003`, `IDENTITY-SECRET-003`, `IDENTITY-PROJECTION-001`, `IDENTITY-EVENT-001`, `IDENTITY-EVENT-002`, `IDENTITY-ADAPTER-NOTIFY-001`, `IDENTITY-DIAGNOSTIC-001`, `IDENTITY-FIXTURE-001`, `IDENTITY-RELEASE-001`, `IDENTITY-RELEASE-002`, `IDENTITY-SERVICE-001`, `IDENTITY-TESTING-001`, `IDENTITY-TOOLING-001`, `IDENTITY-REPOSITORY-STRUCTURE-001` |
| `dependency-failure-confusion` | Repository, crypto, and dependency unavailability project as distinct operational failure codes and never as an authentication rejection. | `IDENTITY-ERROR-001` |

### 6.10 Persistence, concurrency, and races

| Threat | Control | Invariants |
|---|---|---|
| `repository-races` | Security transitions are staged with an expected entity version. A stale version returns a structured conflict *before* any mutation and before any state disclosure — this ordering is the control, and it is stated per-operation throughout the public contracts. | `IDENTITY-REPOSITORY-001`, `IDENTITY-REPOSITORY-002`, `IDENTITY-REPOSITORY-003`, `IDENTITY-REPOSITORY-004`, `IDENTITY-CONTEXT-001`, `IDENTITY-CONTACT-CHANGE-001`, `IDENTITY-SESSION-004`, `IDENTITY-STEPUP-002`, `IDENTITY-DIAGNOSTIC-001`, `IDENTITY-INTERNAL-001`, `IDENTITY-TESTING-001` |
| `concurrency-races` | Deterministic concurrency barriers and named failure checkpoints replace sleeps and ambient randomness in tests, so a race is reproducible rather than flaky. | `IDENTITY-TOTP-001`, `IDENTITY-MFA-001`, `IDENTITY-STEPUP-001` |
| `backend-failures` | Repository contexts never commit implicitly; closing an active context rolls back. | `IDENTITY-REPOSITORY-001` |
| `persistence-tampering` | Persisted frames are versioned, length-delimited, and bounded, with canonical decimal numeric fields. Malformed, over-bound, future-version, and noncanonical frames are rejected as structured codec results before domain decoding. Deterministic fixtures cover each of those rejection cases. | `IDENTITY-CODEC-001`, `IDENTITY-FORMAT-001`, `IDENTITY-FORMAT-002`, `IDENTITY-REPOSITORY-001`, `IDENTITY-REPOSITORY-002`, `IDENTITY-AUDIT-001`, `IDENTITY-FIXTURE-001` |

### 6.11 Resource exhaustion

| Threat | Control | Invariants |
|---|---|---|
| `resource-exhaustion`, `resource-exhaustion-attempts` | Explicit per-operation resource budgets across repository reads and writes, entities loaded, cryptographic operations, password-history checks, factor challenges, events, event attributes, collection capacity, retry count, and input and output bytes. Admission preserves the first exceeded dimension with bounded requested and permitted values. | `IDENTITY-CONTEXT-001`, `IDENTITY-POLICY-001`, `IDENTITY-ATTEMPT-001`, `IDENTITY-ATTEMPT-002`, `IDENTITY-FOUNDATION-001`, `IDENTITY-PASSWORD-POLICY-001`, `IDENTITY-CREDENTIAL-POLICY-001`, `IDENTITY-TEXT-001`, `IDENTITY-TESTING-001`, `IDENTITY-TOOLING-001` |
| `stored-parameter-denial-of-service` | Stored parameters cannot be trusted to be sane. Verifier cost is bounded above (`Maximum_Iterations` = 10,000,000) as well as below; policy snapshots may tighten hard limits but never raise them; codec payloads are length-bounded before decoding. | `IDENTITY-CRYPTO-002`, `IDENTITY-CRYPTO-004`, `IDENTITY-CODEC-001`, `IDENTITY-POLICY-001`, `IDENTITY-PASSWORD-POLICY-001`, `IDENTITY-FORMAT-001`, `IDENTITY-FORMAT-002`, `IDENTITY-INTERNAL-001` |
| `configuration-misuse` | Policy validation reports structured findings and rejects configured limits above Identity hard limits, plus embedded policy families that are internally invalid. | `IDENTITY-POLICY-001`, `IDENTITY-CONTEXT-001` |

### 6.12 Accountability and audit

| Threat | Control | Invariants |
|---|---|---|
| `accountability-loss` | A transition and its audit record are inseparable: an operation reserves event capacity *before* mutating and appends after the transition, so a store that cannot accept the event refuses the operation rather than applying a change nobody can audit. Conflicts are audited as well as successes. | `IDENTITY-AUDIT-001` |
| `event-injection`, `event-injection-attempts` | Events are immutable bounded envelopes with typed actors, subjects, targets, and outcomes, deterministically framed. Ordinary event construction rejects `Secret` and `Derived_Secret` data classes for every attribute value kind. Oversized target text is deterministically truncated rather than exceeding public text limits. Event publication is post-commit. | `IDENTITY-EVENT-001`, `IDENTITY-EVENT-002`, `IDENTITY-EVENT-003`, `IDENTITY-AUDIT-001`, `IDENTITY-ADAPTER-SINK-001`, `IDENTITY-REPOSITORY-001`, `IDENTITY-REPOSITORY-004`, `IDENTITY-FOUNDATION-001`, `IDENTITY-CRYPTO-003`, `IDENTITY-TEXT-001`, `IDENTITY-FORMAT-001` |
| `audit-gap` | The event registry and the public `Identity.Events.Types` constants must expose the same identifiers — currently 54, with zero missing on either side — validated by an executable gate. The audit-coverage gate derives the mutating SPI primitives from the interface itself and requires every operation calling one to emit: currently 59 mutating operations, 58 audited and 1 exempt, 0 unaudited. The unaudited entry points have been withdrawn from the API, so an unrecorded mutation is not expressible rather than merely discouraged; the 4 remaining context-free forms are read-only or the recorded exemption. | `IDENTITY-EVENT-003`, `IDENTITY-AUDIT-001` |

### 6.13 Supply chain and release integrity

| Threat | Control | Invariants |
|---|---|---|
| `supply-chain-compromise` | Machine-readable registries for invariants, events, crypto algorithms, persisted formats, release artifacts, and workflows, each validated by `identity_tools` as a release gate. Release reports are generated only from recorded evidence of runs that actually happened. | `IDENTITY-TOOLING-001`, `IDENTITY-REGISTRY-001`, `IDENTITY-RELEASE-001`, `IDENTITY-RELEASE-002`, `IDENTITY-RELEASE-003`, `IDENTITY-FORMAT-001`, `IDENTITY-FORMAT-002`, `IDENTITY-CRYPTO-002`, `IDENTITY-CRYPTO-004`, `IDENTITY-ARCH-002`, `IDENTITY-INTERNAL-001`, `IDENTITY-EVENT-003`, `IDENTITY-FIXTURE-001`, `IDENTITY-SECRET-003`, `IDENTITY-REPOSITORY-STRUCTURE-001` |
| `security-regression` | Every invariant must carry `required_tests` names traceable verbatim to real evidence; metadata alone is rejected. | `IDENTITY-REGISTRY-001`, `IDENTITY-RELEASE-003` |
| `release-gate-bypass` | The workflow manifest is validated for required workflow names and mandatory gate identifiers, and the `gate_selftests` harness (`crates/identity_gate_selftests`) mutation-tests the gates themselves: each case breaks one piece of evidence and requires `identity_tools` to fail with that gate's own marker. This is what distinguishes a gate that passes from a gate that passes vacuously. | `IDENTITY-RELEASE-003` |
| `release-artifact-contamination` | Artifact and prohibited-material inventories with mandatory provenance coverage; artifacts are not generated after failed gates. | `IDENTITY-RELEASE-002` |

## 7. Cryptographic posture

Stated from `src/public/identity-crypto-*.ads` rather than from intent.

- **Password verifiers**: PBKDF2-HMAC-SHA256. `Default_Iterations` = 600,000
  (OWASP guidance for this PRF), `Minimum_Iterations` = 100,000,
  `Maximum_Iterations` = 10,000,000. Salt is 16 bytes per credential, derived
  output 32 bytes.
- **Salt source**: the OS CSPRNG, through `Identity.Crypto.Entropy`. There is no
  fallback generator.
- **Fail-closed**: if the CSPRNG cannot supply a salt, verifier creation
  produces nothing. `Derive_Verifier` returns `Entropy_Missing` with an empty
  envelope; the older `Create_Verifier` raises `Entropy_Unavailable`. Creating a
  verifier with a predictable salt would silently weaken every stored password,
  so the crate refuses instead. `Derive_Verifier` is the preferred form because
  the rest of the crate reports failure as a classified result.
- **Comparison**: derived bytes are compared with
  `Identity.Crypto.Constant_Time.Equal`.
- **Domain separation**: nine registered domains in `Identity.Crypto.Domains`,
  with canonically framed input so separation cannot be defeated by
  concatenation ambiguity.
- **Migration**: verification returns a `Migration_Status` of `Current`,
  `Upgrade_Recommended`, or `Upgrade_Required` alongside the outcome. Envelopes
  below `Minimum_Iterations` require migration. See section 9 — acting on this
  is the caller's job.
- **No local fallback**: if a cryptolib capability is unavailable, the child
  package returns an explicit missing-capability result. Unsupported algorithms
  and missing capabilities are infrastructure failures, never ordinary failed
  presentations.
- **Algorithm governance**: descriptors carry bounded format versions,
  deprecation state, and *separate* creation and verification permissions. A
  deprecated algorithm can still verify but cannot create; a retired one can do
  neither.

## 8. Residual risks

The trust in section 5 has to land somewhere. It lands here.

1. **Adapter correctness.** Every guarantee about atomicity, uniqueness, and
   revocation is a guarantee about a *conforming* adapter. The conformance
   harness runs 39 commands across five certification profiles against memory,
   recording, and persistent adapters and reloads the persistent snapshot to
   check durability actually held. That raises confidence; it does not make the
   SPI adversary-proof.
2. **Cryptolib correctness.** Delegated and unverified here.
3. **Compiler and runtime behaviour for memory clearing.** Not verified.
4. **Durable repository integrity.** The crate detects tampered *frames*. It
   does not detect a consistent, well-formed lie.
5. **Durability granularity.** The persistent adapter writes through after every
   mutating call. Durability is therefore per call, not per transaction: a
   multi-command sequence is not atomic as a whole.
6. **Concurrency detection is probabilistic.** The concurrency suite's ability
   to detect a broken lock was measured at 9 of 10 runs against a deliberately
   disabled lock, with no false failures in 10 runs against a correct one. A
   passing run is evidence, not proof.
7. **Task safety is opt-in.** `Memory.Store` is not task-safe. Sharing a store
   between tasks requires the `Serialized` wrapper, which reports
   `Concurrent_Access` in its capabilities. Nothing prevents a caller from
   sharing an unwrapped store.

## 9. Accepted limitations

These are known gaps, recorded as gaps rather than described as implemented.
They are taken from the "Known gaps" section of `tools/release-gates.txt`.

**Replay protection is opt-in per call.** Idempotency is wired, but only for the
five operations that are triggered from outside and cannot safely be repeated —
password reset request, contact verification request, recovery begin, API-key
issue, and session rotate. These are exactly the members of
`Identity.Operations.Idempotency.Idempotent_Operation_Kind`. Each offers an
overload taking an idempotency key that reserves the key through
`Stores.Reserve_Idempotency` *before* the transition and closes it through
`Stores.Complete_Idempotency` after it applies, so `Full_Memory_Profile`
advertises `Idempotency => True` and the capability gate finds a real caller
behind the flag. A replayed reservation returns the recorded outcome without
performing the transition again: no second reset token, no second API key, no
second recovery transaction, no second audit event. An empty key is refused
without touching the store, because every empty key would collide with every
other.

The limitation is the overload: existing signatures are untouched, so **a caller
that passes no key gets no replay protection at all**. Nothing detects such a
caller. A retried one-time-secret issuance from a key-less call site can still
issue twice. If a fresh reservation's transition does not apply, the record
stays open by design — nothing happened, so nothing may later be replayed under
that key — and a caller wanting a retry must present a fresh key.

Note also that `Command_Status` has no infrastructure verdict of its own, so a
store fault reported by the reservation collapses onto `State_Conflict` while
the decision half of the verdict keeps the real cause. Code that needs to
distinguish an infrastructure failure from a genuine state conflict must read
the decision half.

**Verifier migration is caller-driven.**
`Identity.Operations.Passwords.Migrate_Verifier` re-derives a below-policy
verifier during a successful authentication, but nothing forces a caller to
invoke it — a replacement credential needs an identifier, and this crate never
invents identifiers. A deployment that ignores `Upgrade_Required` keeps weak
verifiers indefinitely. The crate reports; it does not remediate.

**The audit trail is opt-in per call site, and the bypass surface is large.**
Emission was added additively as an overload on each operation so existing
callers kept compiling. Callers that do not pass an operation context keep
working unchanged — and produce no audit trail. Be precise about what the
audit-coverage gate proves: it requires every mutating operation to *offer* an
audited path; it cannot require callers to *take* one. The marker reports both
numbers, and the bypass figure is the larger one — on the order of a hundred
plain overloads against roughly half that many audited ones. Every one of those
plain overloads still mutates without leaving a record. Closing the surface
means removing the plain overloads, which is a breaking change deferred past V1.
Treat the audit trail as a facility this crate offers, not a property it
guarantees.

**The store has fixed capacity.** A `Memory.Store` is 3.3 MB of fixed-capacity
arrays sized for 512 events, 128 sessions, and so on. Two will not fit on a
default 8 MB stack; harnesses needing isolated stores must allocate on the heap,
as the conformance and concurrency harnesses do. The AUnit suite instead shares
one store and uses distinct identifier prefixes, which is weaker isolation and
is recorded as such. Capacity exhaustion is a classified rejection, not a
silent overwrite — but it is still a hard ceiling.

**Authorization is deliberately out of V1's remit.** Identity establishes *who*
a principal is and nothing about *what* they may do. There are no roles,
permissions, scopes, or resource access semantics anywhere — API keys carry
none, system actors carry no bypass state, and credential-class metadata is
classification input only. This is not an omission to be fixed later in V1: an
executable release gate fails the build if authorization vocabulary appears in
Identity source (`IDENTITY-ARCH-002`, `IDENTITY-SYSTEM-001`). Every deployment
must supply its own authorization layer. An application that treats successful
authentication as sufficient for access control has misused this crate, and this
crate cannot detect that.

## 10. How these claims are checked

The `release_check` tool (`crates/identity_release_check`) is the definition of
the gate; CI runs exactly that tool. It builds under `-gnatwe`, runs every suite,
records each run's real
outcome under `generated/evidence/`, and only then runs `identity_tools` to
validate registries and generate release reports from that evidence. A suite
that never ran cannot be reported as satisfied.

Relevant to this document specifically:

- **Invariant traceability** — every name under `required_tests` in
  `registries/invariants.json` must appear verbatim in a real evidence source.
- **GNATprove** over `registries/proof-scope.json` — currently 616 checks, 0
  unproved; fails on any unproved check, any SPARK legality error, and any
  non-excluded proof-scope package that was not analysed.
- **Gate self-tests** — mutation-test the gates so they fail closed.
- **Capability backing** — every flag `Full_Memory_Profile` advertises as `True`
  must have its backing SPI primitive actually called from the operations layer.
- **Canary secret-leak scanning** over docs, registries, fixtures, tools,
  examples, and conformance output. This document is in scope for that scan.

See `tools/release-gates.txt` for the full enforced set and
`docs/ai/security-invariants.md` for the invariant narrative.

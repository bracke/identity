# Architecture

Identity is headless and transport-neutral. Web, Forms, Validation, Templates,
SQL, notification, OAuth/OIDC/SAML/WebAuthn/X.509, and Authorization logic sit
outside the core crate.

Layering:

- Foundation: identifiers, text, time, errors, results, limits.
- Secrets: bounded controlled containers and redaction.
- Domain: principals, accounts, credentials, authentication evidence,
  assurance, sessions, tokens, recovery, attempts, providers.
- Crypto contracts: Identity-owned semantic services.
- Cryptolib integration: the only place direct cryptolib implementation imports
  are allowed.
- Repository SPI: capability-bearing transactional contracts.
- Operations: public workflows returning trusted results plus explicit
  disclosure-safe projections.
- Downstream security contexts are discriminated projections. Authenticated
  contexts carry separate authentication, evidence, and session revisions so
  consumers can reject stale cached contexts when authentication facts change.

Current memory repository semantics:

- `Create_Principal`, `Create_Account`, and `Add_Binding` are explicit domain
  commands, not generic entity saves.
- Principal lifecycle is explicit. Retired principals remain stable records but
  cannot receive new identity bindings or authenticate through otherwise active
  bindings or credentials.
- Account administrative state, credential requirements, and lock state remain
  independent dimensions. Disable, enable, suspend, unlock, and requirement
  close operations update the account state explicitly; authentication observes
  those dimensions and does not clear them.
- Active identity bindings are unique by normalized subject kind/value.
- Identity binding add, change, and revoke are explicit operations. Add and
  change require an active local principal. Resolution considers active bindings
  only; changing a binding revokes the predecessor and publishes one successor
  while preserving uniqueness.
- Subject resolution is centralized and returns `Resolved`, `Not_Found`,
  `Ambiguous`, `Unsupported`, or `Operational_Failure`.
- Password enrollment stores cryptolib-derived verifier envelopes only.
- Password authentication returns `Password_Authentication_Result`; wrong
  credentials are ordinary rejections and public disclosure remains generic.
- Password change verifies the active old credential before replacement, retires
  the predecessor, and stores only the new cryptolib-derived verifier.
- Password reset completion verifies a purpose-bound reset token, replaces the
  active credential, and consumes the token in one repository transition.
- Sessions store a non-secret public reference and verifier text for the bearer
  secret. New and rotated sessions require an active principal. Lookup returns
  `Session_Handle`, not repository records or verifier internals. Renewal
  updates activity and idle expiration while advancing the session revision and
  never extending beyond absolute expiration. Explicit
  expiration marks eligible sessions using operation time, and retention purge
  removes non-active records only after they are outside the retention boundary.
  The purge operation package derives that retention boundary from the validated
  session retention policy and captured operation time, and rejects policy values
  above Identity hard limits.
  Rotation marks the predecessor unusable and publishes one active
  successor with an advanced generation and a new verifier. Family revocation
  marks every usable session in that family unusable. Principal revocation marks
  every usable session for one principal unusable. Sessions may also carry a
  bounded optional credential reference so credential replacement or revocation
  can revoke only sessions derived from that credential, and a bounded optional
  external-provider reference so provider-derived sessions can be revoked
  without relying on contact values.
- Action tokens are split-token workflows: the repository stores `Token_Id`,
  purpose, metadata, lifecycle state, and a domain-separated verifier for the
  bearer secret. Issuance requires an active local principal. Verification
  reports precise internal outcomes. Terminal states such as `Consumed`,
  `Completed`, and `Superseded` cannot reactivate or be consumed again.
- Contact verification requires an active local principal, then stores a
  pending contact binding and a purpose-bound verification token in one request
  transition. Completion verifies the bearer secret with the contact-verification
  domain, checks the token-to-contact link, marks the contact verified, and
  consumes the token in one transition.
- API keys authenticate service principals using a non-secret public key id and
  verifier-only secret storage. Rotation retires the predecessor and publishes
  one active successor with a new public key id and verifier. No permissions or
  resource access semantics are attached to API keys.
- Security events are immutable bounded envelopes with typed actors, subjects,
  targets, outcomes, and deterministic framed canonical encodings. The bounded
  canonical projection includes stable envelope fields and deterministically
  truncates oversized target text rather than exceeding public text limits.
  Ordinary event data classification excludes `Secret` and `Derived_Secret`.
- Post-commit outputs are structured bounded values under
  `Identity.Operations.Post_Commit`. They may reference committed events,
  after-commit event publications, safe notification handoffs, one-time token
  outputs, and committed session issuance; release predicates reject uncounted
  entries, pre-commit publications, secret-bearing delivery requests, and
  one-time outputs that are not safe to return.
- Notification adapters expose typed post-commit delivery failure actions.
  Infrastructure retry is secret-free; unsafe secret-bearing requests require
  revocation compensation, and unsupported channels require replacement
  authority rather than plaintext token retry.
- Idempotent one-time issuance uses `Identity.Operations.Idempotency` and the
  repository idempotency SPI. Fresh completion may return the one-time secret;
  completed replay is reported without re-emitting that secret.
- Persisted canonical frames are versioned, length-delimited, and bounded.
  Numeric frame fields must use canonical decimal form without leading zeros;
  malformed, over-bound, or noncanonical frames are rejected as structured codec
  results before domain decoding.
- Service contexts are immutable construction-time values, and operation
  contexts carry operation, correlation, actor, requested-at, deadline,
  disclosure, diagnostic mode, and cooperative cancellation facts explicitly.
  Domain operations must not depend on ambient global cancellation state.
  Checkpoint evaluation returns `Continue`, `Cancelled`, or `Deadline_Exceeded`
  with cancellation taking precedence when both are true.
- Resource budgets are explicit public policy values covering repository
  reads and writes, loaded entities, cryptographic operations, password-history
  checks, factor challenges, events, event attributes, collection capacity,
  retry count, input size, and output size. Policy validation rejects values
  above Identity hard limits.
- Attempts are first-class bounded records with typed failure buckets. Lockout
  evaluation is deterministic and uses the injected operation time model rather
  than sleeping or cleanup-job assumptions.
- Recovery-code sets store only domain-separated verifier text. Individual
  codes are single-use and transition to `Consumed` on successful use.
- Account recovery uses persistent recovery transactions with explicit states.
  Starting a recovery transaction requires an active local principal. The Ada
  package is `Identity.Operations.Recovery.Begin_Recovery` because `begin` is a
  reserved word; it corresponds to the normative begin operation. Completion
  requires accepted evidence and applies structured recovery
  restrictions to the account, causing authentication to return
  `Recovery_Action_Required` until those restrictions are explicitly cleared.
- MFA uses persistent authentication transactions and separate challenge
  records. Starting an authentication transaction and issuing a challenge require
  an active local principal. Challenges are bound to one principal and one
  transaction; completion advances both the challenge state and the transaction
  evidence count. A transaction cannot become satisfied before challenge
  evidence has been accumulated.
- Step-up uses a satisfied authentication transaction to upgrade exactly one
  active same-principal session. The session assurance facts and revision change
  atomically, and the transaction is consumed so the evidence cannot upgrade
  another session.
- TOTP enrollment requires an active local principal. TOTP credentials store
  verifier metadata and a highest accepted counter. Counter acceptance advances
  replay state and rejects same-or-older counters.
- Recovery-code generation and regeneration require an active local principal;
  recovery-code plaintext is displayed once and persisted only as derived
  verifiers.
- Contact change is a dedicated state machine requiring an active local
  principal. A request stores a pending successor contact and purpose-bound
  token while the verified predecessor remains active. Completion atomically
  verifies the successor, retires the predecessor, consumes the token, and
  activates the change record.
- External provider assertions enter the core only after adapter validation as
  normalized assertion records. Local authentication requires an explicit active
  binding keyed by provider, issuer, and external subject; contact values are
  not used for automatic linking. Replay fingerprints are registered explicitly.
- The in-memory adapter is deterministic and capacity bounded.

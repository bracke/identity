# AI Public Contracts

Public operations return structured results. Ordinary authentication failures
are not exceptions. Disclosure mapping is performed only through
`Identity.Operations.Disclosure`.
`Identity.Results.Resource_Limit` and
`Identity.Results.Internal_Invariant_Failure` are distinct trusted operation
statuses; disclosure projection maps them to operational failure, never to an
ordinary authentication rejection. Use the `Identity.Results` status
classification predicates when branching on success, ordinary rejection,
additional required action, throttling, conflicts, invalid input, unsupported
capabilities, operational failures, resource limits, internal invariants, or
generic disclosure rejection eligibility.
Secret containers expose `Identity.Secrets.Bytes.Is_Present` and `Length` as
non-secret metadata so absent and empty secret inputs remain distinct without
adding any ordinary image or serialization path for secret bytes. Textual
secret constructors must use `Identity.Secrets.Text.Validate_UTF_8`; malformed
UTF-8 and values above `Identity.Limits.Max_Secret_Bytes` are rejected before
secret container construction. Use `Accepted_Input`, `Rejected_Input`,
`Invalid_UTF_8_Rejected`, and `Size_Rejected` to branch on textual secret
admission.
Semantic secret packages expose admission validators for family-specific hard
limits: session secrets, reset tokens, verification tokens, and API-key secrets
use `Identity.Limits.Max_Bearer_Secret_Bytes`; recovery codes use
`Identity.Limits.Max_Recovery_Code_Bytes`. These validators distinguish absent,
empty, accepted, and too-large inputs without creating a disclosure-capable
secret image. Family adapters should branch through `Accepted_Input`,
`Rejected_Input`, `Missing_Input`, and `Size_Rejected`, not enum literals.
Use `Identity.Operations.Disclosure.Rules_For` when a response adapter needs to
know whether a profile may expose subject existence, factor enrollment, lockout,
retry timing, contact destination, diagnostic identifiers, conflict detail, or
token-state detail. Do not duplicate those profile rules in transport code.
Use `Successful`, `Public_Rejection`, `Additional_Action`, `Token_Invalid`,
`Conflict_Detail_Hidden`, `Conflict_Detail_Visible`, `Invalid_Input_Status`,
and `Operational_Status` when branching on disclosure-safe statuses.
Use `Identity.Operations.Disclosure.Reveals_No_More_Than` when comparing
profiles or validating that a less trusted projection cannot expose additional
detail. Operation conflicts collapse to `Authentication_Rejected` for
untrusted profiles and project as `Conflict_Detailed` only when the selected
profile enables conflict detail. Token state conflicts collapse to
`Token_Invalid_Or_Expired` for untrusted profiles and project as
`Conflict_Detailed` only under the same conflict-detail rule.
Public error payloads should use `Identity.Errors.Public.To_Public`; it maps
structured error values to stable code and message identifiers, preserves retry
and cause classes, and suppresses diagnostic detail unless explicitly requested
for an operational/internal failure path.
Use `Identity.Errors.Public.Diagnostic_Disclosure_Allowed`, `Retryable`, and
`Operational` before exposing diagnostic affordances, retry hints, or
operational-failure handling in adapters. Classify public codes with
`Generic_Authentication_Rejection`, `Repository_Unavailable`,
`Crypto_Unavailable`, and `Dependency_Unavailable` instead of comparing
registry identifiers in adapters. Bounded diagnostic records expose
`Safe_Image`, `Failure_Diagnostic`, and `Success_Diagnostic`; branch on the
diagnostic predicates instead of comparing rendered diagnostic text.
Adapter status handling should use public predicates instead of raw literal
comparisons: `Identity.Adapters.Keys` classifies lookup state and creation or
verification admission; `Identity.Adapters.Notifications` classifies queued,
failed, and retryable delivery outcomes before choosing compensation;
`Identity.Adapters.Event_Sinks` classifies accepted, retryable, permanent, and
failed publication status and exposes `Admit_For_Publication` so adapters branch
on accepted, status-rejected, timing-rejected, and policy-rejected publication
admission before delivery; and `Identity.Adapters.Diagnostics` classifies
accepted, redacted, rejected, and received diagnostic submissions.
Principal lifecycle checks should use `Identity.Principals.Lifecycle.Admission`
with `Use_Principal`, `Retire_Principal`, or `Reactivate_Principal`, and branch
with `Admission_Accepted`, `Admission_Rejected`, `Retired_Rejection`, and
`Reactivation_Policy_Rejection`. `Active`, `May_Retire`, and `May_Reactivate`
remain compatibility predicates; adapters must not compare lifecycle
enumeration literals directly when deciding activity, retirement, or
reactivation admission. Principal lifecycle transitions must advance entity
versions through
`Identity.Versions.Next_Entity_Version`.
Reactivation admission, where a local policy permits it, must use
`Identity.Principals.Lifecycle.Admission` or `May_Reactivate`; retired state
alone is insufficient and active principals do not reactivate.
Staged principal retirement should use
`Identity.Operations.Principals.Retire.Staged_Retire_Request`; a stale expected
principal version returns `Version_Conflict` before the lifecycle state changes.
Entity-version checks should use `Identity.Versions.Same_Entity_Version` for
expected-version comparisons and `Identity.Versions.Next_Entity_Version` for
persisted state changes. The advancement helper is saturated at the public hard
limit, so adapters must not open-code entity-version arithmetic.
Staged identity binding changes should use
`Identity.Operations.Identities.Change.Staged_Change_Request`; a stale expected
predecessor binding version returns `Version_Conflict` before the predecessor is
revoked or the successor binding is published.
Invalid token outcomes such as unknown, malformed, wrong secret, expired,
purpose mismatch, consumed, revoked, and attempt-limit reached must be
projected through the token-outcome disclosure overload; untrusted profiles
collapse them to `Token_Invalid_Or_Expired`.
Token outcome classification should use
`Identity.Tokens.Verification.Is_Valid`, `Terminal_Invalid`,
`Disclosure_Collapsed_Invalid`, `Retryable`, and `Infrastructure` before any
operation result or disclosure projection is selected. Infrastructure failures
must not be collapsed into invalid-token public causes by hand-written mapping.
Use `Identity.Tokens.Verification.Evaluate` to turn token state, expiry,
purpose matching, binding matching, and verifier result into precise internal
token outcomes before disclosure projection. Terminal token states take
precedence over purpose or binding mismatch detail; active token states then
evaluate expiry, purpose, binding, and verifier result. Workflows that already
validated purpose or binding should use
`Identity.Tokens.Definitions.Purpose_Matches`, `Bound_To_Principal`,
`Expired_At`, `Verifiability`, `Verifiability_Accepted`,
`Verifiability_Rejected`, `State_Rejected`, `Expiration_Rejected`, `Purpose_Rejected`,
`Principal_Rejected`, and `Evaluate_State_First` for purpose,
principal-binding, and state/expiry priority rules instead of duplicating
token-purpose, token-binding, token-state, or token-expiration conditionals.
`Verifiable_For` is the Boolean compatibility helper; use `Verifiability` when
a trusted result needs the structured reason.
Superseded token state is a structured conflict in both `Evaluate` and
`Evaluate_State_First`; do not collapse it to consumed-token handling before
trusted result selection.
Expose action-token state through `Identity.Tokens.Projections.Summary`; the
projection carries token ID, purpose, bound principal ID, issued and expiration
times, lifecycle state, attempt count, entity version, and a verifier-present
fact without exposing verifier text. Projection consumers should use
`Can_Verify`, `Can_Complete`, and `Terminal` rather than reading repository
token records.
Token policy snapshots should use `Identity.Tokens.Policies.Validate`,
`Validation_Accepted`, `Lifetime_Rejected`, and
`Attempt_Limit_Rejected`; policy construction bounds `Maximum_Attempts` by
`Identity.Limits.Max_Factor_Challenges`. `Valid` remains the Boolean
compatibility wrapper over the structured classifier.
Contact verification result handling should use
`Identity.Verification.Results.Successful`,
`Request_Accepted`, `Completion_Accepted`,
`From_Token_Outcome`,
`Requires_Generic_Token_Disclosure`, `Invalid_Token_Rejection`,
`Binding_Rejection`, `Attempt_Limit_Rejection`,
`Retryable_By_Presentation`, `Conflict`, and `Operational` before projecting a
contact-verification response. Untrusted adapters should not infer token-state
disclosure directly from enum literals.
Protected token consumption should use
`Identity.Tokens.Consumption.Evaluate(Token, Now)` so expiry is admitted through
the same public token-expiration predicate before a protected transition is
staged; the state-only overload remains for already-derived state projections.
Branch on `Consumable`, `Consumption_Rejected`,
`Already_Consumed_Rejection`, `Expired_Rejection`, `Revoked_Rejection`,
`Attempt_Limit_Rejection`, `Conflict`, `Terminal_Rejection`, and
`No_Protected_Mutation` before attempting the protected state mutation.
Staged action-token consumers should use
`Identity.Operations.Tokens.Consume.Consume_Request`; if the stored token
version no longer matches `Expected_Version`, the command returns
`State_Conflict` before consumed-state disclosure or secret verification.
Operation resource budgets must use `Identity.Operations.Budgets` and the
policy snapshot `Resource_Budget` dimensions: repository reads and writes,
entities loaded, cryptographic operations, password-history checks, factor
challenges, events, event attributes, collection capacity, retry count, input
bytes, and output bytes.
Bounded collection consumers should classify `Identity.Collections.Collection_Status`
with `Successful`, `Capacity_Exhausted`, `Duplicate_Rejected`,
`Missing_Rejected`, `Invalid_Index_Rejected`, and `No_Mutation` before
projecting capacity, duplicate, lookup, or index failures. Observable
collection output must keep insertion ordering deterministic.
Foundation contract checks should use `Identity.Contracts.Require` and branch
through `Satisfied_Status`, `Violated_Status`, and `Rejected`. Public UTF-8
input handling should use `Identity.Text.UTF_8.Validate` and classify with
`Valid_Status`, `Invalid_Status`, `Size_Rejected`, and `Rejected` before
constructing bounded text.
Use `Identity.Operations.Budgets.Admit` when a caller needs a structured
resource-limit result; it preserves the first exceeded dimension and the
bounded requested and permitted values while `Within` remains the boolean
convenience predicate. Classify admissions with `Accepted`, `Rejected`,
`Exceeded`, and `Has_Bounded_Detail` before starting bounded operation work or
projecting resource-limit failures.
Use `Hard_Limits`, `Within_Hard_Limits`, and `Admit_Hard_Limits` to validate
policy or operation budgets against implementation maxima from
`Identity.Limits`; use `Exceeds_Hard_Limit` when branching on a specific
hard-limit dimension. Policy snapshots may tighten these values but must not
raise them. Policy validation reports should be classified through
`Identity.Policies.Findings.Has_Findings`, `Has_Warnings`, `Has_Errors`,
`No_Finding_Status`, `Warning_Severity`, and `Error_Severity` before deciding
whether a finding is advisory or release-blocking.
Security event builders should classify envelope values at the source with
`Identity.Events.Envelopes.Low_Severity`, `Warning_Severity`,
`High_Severity`, `Critical_Severity`, `Succeeded_Outcome`,
`Rejected_Outcome`, `Conflict_Outcome`, `Failed_Outcome`,
`Requires_Operational_Attention`, `Unauthenticated_Actor`,
`Authenticated_Actor`, `Human_Actor`, `Service_Actor`, and `System_Actor`.
Event attribute construction should classify
`Identity.Events.Attributes.Attribute_Status` with `Accepted_Status`,
`Key_Rejected`, `Class_Rejected`, `Policy_Rejected`, and
`Attribute_Rejected` before staging mandatory audit events or public
projections.
Operation deadline checks should use
`Identity.Operations.Contexts.Evaluate_Deadline` when boundary detail matters.
It distinguishes no deadline, before deadline, exact boundary, and past
deadline; `Deadline_Exceeded` remains the boolean convenience predicate for the
past-deadline state. Use `Deadline_Unbounded`, `Deadline_Open`,
`Deadline_At_Boundary`, and `Deadline_Past` for deadline-status branching.
`Evaluate_Checkpoint` gives cooperative cancellation precedence over deadline
failure. Classify cancellation sources through
`Identity.Operations.Cancellation.Active` and `Cancelled` rather than negating
the cancellation-requested state at call sites.
Persisted decoders should call `Identity.Codecs.Persisted.Admit_Canonical`
before format-specific parsing. The admission result distinguishes invalid
version windows, unsupported versions, noncanonical framing, and valid
canonical frames without exposing payload internals. Classify
`Identity.Codecs.Codec_Status` with `Accepted`, `Malformed`, `Oversized`,
`Version_Unsupported`, `Noncanonical_Rejected`, and `Decoder_Rejected` before
projecting errors or staging decoded state.
Long-running operations should call
`Identity.Operations.Contexts.Evaluate_Checkpoint` at documented checkpoints.
It returns a structured continue/cancelled/deadline status and gives
cancellation precedence over deadline expiry. Use `Checkpoint_Allows_Progress`,
`Checkpoint_Cancelled`, and `Checkpoint_Deadline_Blocked` before mapping a
checkpoint result to a public operation outcome.
Downstream consumers must treat `Identity.Authentication.Security_Contexts`
as a discriminated projection. Authenticated contexts expose authentication,
evidence, optional session revisions, and an optional validity boundary; use
`Revision_Changed`, `Admission_Status`, or `Usable_For_Downstream` before
relying on a cached context after session, evidence, eligibility, recovery, or
validity facts may have changed. `Admission_Status` classifies stale revisions,
expired anonymous validity, ineligible authenticated state, and authenticated
validity expiry without exposing secrets or repository records. Branch on
admission causes with `Admission_Accepted`, `Stale_Revisions_Rejected`,
`Admission_Rejected`, `Anonymous_Expiration_Rejected`, `Authenticated_Eligibility_Rejected`, and
`Authenticated_Expiration_Rejected`, rather than comparing enum literals in
adapters. Use `Has_Session` only to distinguish session-backed authentication
facts from sessionless authentication.
Recent-authentication checks must use the explicit security-context age
predicates: `Original_Authentication_Recent`,
`Primary_Authentication_Recent`, `MFA_Completion_Recent`, and
`Step_Up_Recent`. They take the operation instant and
`Identity.Times.Durations.Authentication_Maximum_Age`; session renewal or
activity updates must not be treated as fresh proof.
Assurance profile checks should use
`Identity.Assurance.Evaluation.Requirements_For` and `Evaluate`; profiles are
satisfied from structured attributes and independent-factor counts.
Classify requirement lookup with `Requirements_Known` and
`Requirements_Unknown`, and classify evaluation results with
`Evaluation_Satisfied`, `Evaluation_Rejected`, and
`Evaluation_Recovery_Restricted` instead of reading result fields directly in
adapters.
`Identity.Assurance.Attributes.Consistent` rejects impossible attribute
summaries such as independent factors exceeding total factors or user
verification without user presence. Use `Meets_Factor_Floor`,
`Has_Verified_User`, and `Recovery_Restricted` for profile-independent
admission checks; profile satisfaction remains owned by
`Identity.Assurance.Evaluation`. Recovery-used evidence is restricted to the
recovery-restricted profile unless local policy introduces a different explicit
profile.
Recovery workflow result handling should use
`Identity.Recovery.Results.In_Progress`, `Started_Status`,
`Evidence_Required_Status`, `Approved_Status`, `Successful`, `Restricted`,
`Failed`, `May_Issue_Restricted_Authentication`, `Final_Completion`,
`Conflict`, and `Operational` before issuing recovery continuations or
restricted authenticated projections. `Successful` includes both restricted
continuity and final completion; only `May_Issue_Restricted_Authentication`
admits recovery-derived restricted authentication issuance.
Post-commit operation outputs must use `Identity.Operations.Post_Commit`
rather than callbacks. Only counted entries are valid, event publications must
be marked after-commit and accepted, notification handoffs must not include
secret material, and one-time token outputs must be safe to return.
Use `Has_Post_Commit_Work` before handoff orchestration instead of inspecting
each batch manually.
Use `Admit_For_Release` when orchestration needs a structured reason for
rejecting post-commit output: count mismatch, pre-commit publication, unsafe
notification, or unsafe one-time output.
Classify release admission with `Accepted`, `Rejected`,
`Count_Mismatch_Rejection`, `Publication_Timing_Rejection`,
`Notification_Rejection`, `One_Time_Output_Rejection`, and `Safety_Rejection`
instead of duplicating enum comparisons in adapters.
Idempotent secret issuance must reserve and complete through
`Identity.Adapters.Repositories.Idempotency`; staged completion should pass the
reservation version returned by reservation, and stale expected reservation
versions must return a conflict before the reservation is marked completed.
Completion transitions must advance reservation versions through
`Identity.Versions.Next_Entity_Version` and replayed operations must not
re-emit one-time secrets.
Validate externally supplied idempotency keys with
`Identity.Operations.Idempotency.Validate_Input` before reserving repository
state. Empty and oversized keys are structured input rejections; construct
keys with `From_String` only after that admission step.
Use `Identity.Operations.Idempotency.Fresh_Decision`, `Replay_Decision`,
`In_Progress_Decision`, `Conflict_Decision`, `Capacity_Rejected`,
`Infrastructure_Failed`, `Operational_Failure`, `Terminal_Decision`,
`No_Mutation`, `Reserved_State`, `Completed_State`, `Abandoned_State`, and
`Terminal_State` when projecting reservation decisions or deciding whether a
one-time output can be released.
Repository adapters should use
`Identity.Adapters.Repositories.Idempotency.Fresh_Status`, `Replayed_Status`,
`In_Progress_Status`, `Conflict_Status`, `Capacity_Rejected`,
`Infrastructure_Failed`, `Operational_Failure`, and `Terminal_Status` when
mapping repository reservation state to operation idempotency results.
Repository conflict handling should use
`Identity.Adapters.Repositories.Conflicts.Retryable`, `State_Predicate_Failed`,
`Uniqueness_Rejected`, `Replay_Rejected`, `Idempotency_Rejected`,
`Capacity_Rejected`, `Serialization_Rejected`, `Concurrency_Conflict`, and
`One_Time_Use_Conflict` instead of duplicating backend-specific conflict
classification in adapters or operations.
Repository read-view handling should use each package's public status
predicates before projecting results: principal and account read predicates
distinguish found, missing, capacity, and infrastructure failure; identity and
credential predicates additionally identify disclosure-collapsible misses;
authentication transaction predicates identify expired, consumed, operational,
and terminal rejection states.
Contact, challenge, session, token, attempt, external-binding, and mandatory
event staging paths also expose public repository predicates. Use them to
identify contact binding mismatches, consumed or expired challenges and tokens,
session replay that requires a security response, deferred attempt recording,
external assertion replay, and mandatory-event staging failures.
Repository conformance reporting must classify certification status through
`Identity.Adapters.Repositories.Conformance.Not_Run_Status`, `Passed_Status`,
`Failed_Status`, `Unsupported_Status`, `Terminal_Status`, and
`May_Advertise_Profile`; adapters may advertise a profile only after a passed
conformance result.
Repository capability snapshots must be admitted through
`Identity.Adapters.Repositories.Capabilities.Admit_Transaction` before
security-transition work begins. Do not start mutating a protected transition
when required security-transition, atomic mandatory-event, or optimistic-version
capabilities are missing.
Repository context state and transaction results should be classified through
`Identity.Adapters.Repositories.Is_Open`, `In_Transaction`, `Finalized`,
`May_Begin_Transaction`, `May_Commit`, `May_Rollback`, and
`Identity.Adapters.Repositories.Transactions.Succeeded`, `Failed`, `Active`,
`Committed`, and `Rolled_Back`. Repository command outcomes should use
`Is_Applied`, `Is_Rejected`, `Is_Conflict`, `Capacity_Rejected`,
`Infrastructure_Failed`, `Operational_Failure`, `No_Mutation`, and
`Conflicts_As`.
Use `Identity.Adapters.Repositories.Capabilities.Admit_Command` before staging
atomic workflow commands that need session rotation, token action, family
revocation, assertion replay registration, idempotency, deterministic event
ordering, mandatory-event atomicity, optimistic-version validation, or bounded
event and command-size capacity.
SPI command results should use `Identity.Adapters.Repositories.Commands.Success`,
`Rejection`, `Conflict_Result`, `Is_Applied`, `Is_Conflict`, and `Conflicts_As`
rather than ad hoc record aggregates when reporting applied, rejected, and
structured conflict outcomes.
Event attributes should be built through `Identity.Events.Attributes` and, when
an event policy is available, the policy-aware text, integer, or boolean
constructor. Unset or syntactically invalid registry keys, invalid policies,
and Secret or Derived_Secret ordinary-event classes must fail before event
staging for every attribute value kind. Validate event policy snapshots with
`Identity.Events.Policies.Validate`, `Validation_Accepted`,
`Attribute_Capacity_Rejected`, `Secret_Attribute_Rejected`, and
`Publication_Timing_Rejected`; `Valid` remains the Boolean compatibility
projection.
Use `Identity.Redaction.Safe_For_Public_Output` or `Requires_Redaction` before
projecting event data into public diagnostics, reports, or API responses.
`Public_Image` passes only Public and Operational classes through; Personal,
Sensitive, Secret, and Derived_Secret classes return the fixed redacted marker.
Event envelopes should use `Identity.Events.Schemas.Registration_For` to admit
only known V1 event types and to carry the registered schema version,
classification, and mandatory-audit requirement into repository staging.
Durable audit policy snapshots should use `Identity.Audit.Policies.Validate`
with `Validation_Accepted`, `Requirement_Rejected`, and
`Integrity_Rejected`; sensitive and personal events remain required audit
material, and integrity must be required. Use the policy-aware
`Requirement_For` or `Audit_Required` helpers when deciding whether a class
requires durable audit staging. Audit record integrity state should be
classified with `Identity.Audit.Integrity.Not_Configured`, `Verified`,
`Failed`, and `Acceptable` before projecting audit health or release reports.
Notification delivery failures after commit must use
`Identity.Adapters.Notifications.Failure_Action`. Adapters must not persist
plaintext token secrets for retry; revocation, replacement, secret-free retry,
or manual-review compensation is surfaced explicitly.
Key providers expose only non-secret key references through
`Identity.Adapters.Keys`. Use `Admit_For_Creation` and
`Admit_For_Verification` before deriving or verifying keyed verifiers; these
functions reject missing, unavailable, retired, revoked, cross-domain, and
verification-only-for-creation keys with bounded decisions.

Password authentication must be called through
`Identity.Operations.Passwords.Authenticate.Execute`; do not expose a public
`Verify_Password -> Boolean` workflow.
Unresolved subjects and other generic credential-missing rejection paths must
perform synthetic password verification before returning the same rejected
result and disclosure-safe projection.
Identity resolution results should be classified with
`Identity.Identities.Resolution.Successful`, `Generic_Miss`,
`Ambiguity_Detected`, `Unsupported_Subject`, `Operational`, and
`Disclosure_Collapsed_Rejection`. Public adapters must not expose whether the
collapsed path was not-found or ambiguous.
Staged password changes should use
`Identity.Operations.Passwords.Change.Change_Request`; a stale
`Expected_Current_Version` returns trusted `Conflict` before the existing
credential is retired or the replacement credential is stored.
Staged password reset completion should use
`Identity.Operations.Passwords.Complete_Reset.Reset_Completion_Request`; stale
token or predecessor credential versions return `State_Conflict` before the
reset token is consumed, sibling reset tokens are superseded, or the password
credential is replaced.
Password history admission should be classified with
`Identity.Passwords.History.History_Allowed`, `Reuse_Rejected`,
`Malformed_History_Rejected`, `Work_Limit_Rejected`, and
`No_Credential_Replacement` before staging password change or reset
replacement. Reuse, malformed history, and work-limit outcomes must not be
converted into successful credential replacement.
Password change authority should be classified with
`Identity.Passwords.Changes.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Unauthenticated_Rejection`, `Recent_Authentication_Rejection`,
`Assurance_Rejection`, and `Recovery_Restriction_Rejection`. `May_Change`
remains a compatibility predicate over that classifier. The current-password
requirement remains represented by the operation input and policy, not by the
authority-admission result.
Use `Identity.Passwords.History.Evaluate_Record` to convert each stored
history record and verifier outcome into allowed, reused, or malformed-history
status without exposing password text.
Expose password credential state through
`Identity.Passwords.Credentials.Summary`; the projection carries credential ID,
principal, lifecycle state, version, and a Boolean verifier-present fact
without copying verifier text. Projection consumers should use
`Authentication_Admission`, `Authentication_Accepted`,
`Verifier_Missing_Rejection`, `Credential_State_Rejection`,
`Can_Authenticate`, and `Terminal` on that summary.
Use `Identity.Operations.Passwords.Authenticate.Execute` with
`Attempted_Request` when the caller has operation attempt metadata. This
records a bounded attempt with caller-supplied attempt ID, correlation ID, safe
subject fingerprint, timestamps, result category, and optional deterministic
password-failure lockout threshold.
Attempt counters should use `Identity.Attempts.Definitions` and
`Identity.Attempts.Outcomes` predicates. Use `Successful`, `Failed`,
`Throttled`, `Conflict`, `Operational`, `Public_Success`, and
`Hidden_Operational_Failure` for public branching. Use `No_Failure`,
`Password_Failed`, `TOTP_Failed`, `Recovery_Failed`, `Token_Failed`,
`Provider_Failed`, `Session_Replay_Detected`, `Security_Response_Failure`, and
`Counts_In_Failure_Bucket` for bucket-specific handling.
`Counts_As_Credential_Failure` returns true only for failed attempts with a
concrete failure category; operational failures, conflicts, throttles, and
successes must not advance credential failure counters.
Failure-bucket policy snapshots should use
`Identity.Attempts.Buckets.Validate` with `Validation_Accepted`,
`Window_Rejected`, `Threshold_Rejected`, and `Saturation_Rejected`. Aggregate
attempt policies should use `Identity.Attempts.Policies.Validate` with
`Password_Bucket_Rejected`, `TOTP_Bucket_Rejected`, and
`Token_Bucket_Rejected`; `Valid` remains the Boolean compatibility projection.
Policy-aware lockout transitions should use
`Identity.Lockout.Evaluation.Evaluate_With_Policy` with the captured operation
instant. The result explicitly distinguishes allow, temporary lock with checked
expiry, indefinite lock, and time-overflow fallback; temporary-lock correctness
must not depend on cleanup jobs. Branch on `Allows_Attempt`,
`Temporarily_Locks`, `Indefinitely_Locks`, and `Overflowed_To_Indefinite`
before applying account or credential lock consequences.
`Identity.Throttling.Policies.Validate` and
`Identity.Lockout.Policies.Validate` return structured policy validation
statuses for threshold ordering, positive duration requirements, and the rule
against permanent remote-login disablement. Use `Validation_Accepted`,
`Threshold_Rejected`, `Duration_Rejected`, and
`Permanent_Remote_Disablement_Rejected`; `Valid` remains the Boolean
compatibility projection.
Use `Identity.Lockout.States.Attempt_Admission` with the stored temporary
expiration and injected clock instant when evaluating an existing lock; branch
with `Admission_Accepted`, `Admission_Rejected`, `Temporary_Rejection`,
`Indefinite_Rejection`, and `Unlock_Pending_Rejection`. `Can_Attempt_At`
remains the compatibility Boolean.
Use `Identity.Lockout.States.Effective_State_At` and
`Identity.Accounts.Security_Locks.Effective_State_At` for cleanup-independent
state projection; do not require a cleanup mutation before an expired temporary
lock becomes usable.
Throttling decisions should use `Identity.Throttling.Decisions.Evaluate` with
the same captured operation instant. The core returns delay or reject
boundaries and never sleeps; checked time-overflow is an operational failure,
not a credential failure. Branch through `Allows_Request`, `Delays_Request`,
`Rejects_Request`, `Requires_Challenge`, `Operational`, and `Has_Boundary`
instead of matching enum literals in adapters.
Password reset requests should use
`Identity.Operations.Passwords.Request_Reset.Execute` with `Reset_Request` so
Identity derives the purpose-bound token verifier from a reset-token secret
container. The token-record overload remains for conformance fixtures and
adapter-level state setup.
Issuing a newer password-reset token supersedes earlier live reset tokens for
the same principal by default. Token lifecycle changes must advance entity
versions through `Identity.Versions.Next_Entity_Version`.
Successful password reset completion consumes the presented token and
supersedes sibling live password-reset tokens for the same principal in the
same protected transition.
Reset policies should use `Identity.Passwords.Resets.Validate`,
`Validation_Accepted`, `Administrative_Clear_Rejected`,
`Session_Consequence_Rejected`, and `Revokes_Sessions`; `Valid` remains the
Boolean compatibility projection. Core reset policy validation rejects
administrative restriction clearing and reset completion policies that keep all
existing sessions.
Reset completion performs token admission before deriving a replacement
password verifier; repositories still revalidate the token during the protected
credential-replacement transition.
Contact verification requests should use
`Identity.Operations.Verification.Request.Execute` with
`Verification_Token_Request` for the same reason: the operation fixes the
contact-verification purpose and derives the verifier from a verification-token
secret container. The repository command requires an active local principal.
Contact binding state checks should use
`Identity.Contacts.Bindings.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Pending_Verification_Rejected`, `Verified_Rejected`,
`Occupancy_Rejected`, `No_Mutation`, `Can_Request_Verification`,
`Can_Complete_Verification`, `Can_Be_Change_Predecessor`,
`Can_Be_Change_Successor`, `Occupies_Contact_Value`, and
`Same_Occupied_Contact_Value`; contact verification does not establish
real-world identity proof. The structured admission classifier distinguishes
verification request, verification completion, contact-change predecessor,
contact-change successor, and occupied-value uniqueness checks. Contact binding
and contact-change workflow mutations must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Expose contact-binding summaries through `Identity.Contacts.Bindings.Summary`;
the projection carries contact kind, state, version, and value-presence only,
not the normalized contact value. Projection callers should use the overloads
in `Identity.Contacts.Bindings` and `Identity.Contacts.Verification_State` for
state checks.
Contact-control workflows should branch through
`Identity.Verification.Contacts.Unverified_State`,
`Verification_Requested_State`, `Verified_State`,
`Reverification_Required_State`, `Needs_Verification`, and
`Request_In_Flight`; these helpers classify verification control state without
treating contact control as authentication or identity proof.
Workflow token staging should use `Identity.Tokens.Definitions.Admission`
with `Issue_Token`, or the compatibility `Can_Issue` predicate, before
persisting newly issued verification or change tokens. The typed classifier
distinguishes wrong-state, terminal-state, and illegal-forward-transition
rejection before protected token state changes.
Staged contact-verification completion should use
`Identity.Operations.Verification.Complete.Staged_Completion_Request`; if the
stored token or binding version no longer matches the expected value, the
command returns `State_Conflict` before secret verification, terminal token
state disclosure, or binding mutation.
Contact change initiation should use
`Identity.Operations.Verification.Begin_Contact_Change.Execute` with
`Contact_Change_Token_Request` so Identity fixes the contact-change purpose
and persists only a derived verifier for the supplied verification-token
secret container. The repository command requires an active local principal.
Contact-change adapters should use `Identity.Verification.Changes.Admission`,
`Admission_Accepted`, `Admission_Rejected`, `State_Rejected`,
`Terminal_Rejected`, `No_Mutation`, `Can_Begin`, and `Can_Complete` for change state
admission before staging or activating the workflow. Use `In_Progress`,
`Is_Terminal`, `Can_Cancel`, and `Can_Expire` for cancellation and expiration
paths; adapter code should not infer terminal state from enum ordering. The
structured classifier distinguishes wrong-state and terminal-state rejection
before repository commands mutate contact-change records. Use
`Awaiting_New_Contact_Verification`,
`Awaiting_Old_Contact_Confirmation`, `Cooling_Off_Active`, `Activated_State`,
`Cancelled_State`, and `Expired_State` when projecting workflow status or
terminal cause.
Optional old-contact confirmation and cooling-off workflows must stay inside
the same explicit state machine: use
`Can_Record_Old_Contact_Confirmation`, `Can_Start_Cooling_Off`, and
`Can_Activate_After_Gates` instead of adapter-local Boolean flags.
Use `Identity.Verification.Policies.Requires_Old_Contact_Confirmation` to map
the policy mode and predecessor verification state to the old-contact gate;
adapters must not reinterpret `Old_Contact_Confirmation_Mode` independently.
Staged contact-change completion should use
`Identity.Operations.Verification.Complete_Contact_Change.Staged_Completion_Request`;
if the stored token, change, predecessor, or successor version no longer
matches the expected value, the command returns `State_Conflict` before
disclosing consumed-token or terminal workflow state.
Activation after a contact-change cooling-off period should use
`Identity.Verification.Policies.Cooling_Off_Satisfied` with the captured
operation instant; the helper uses checked Identity time arithmetic and rejects
overflowed cooling-off boundaries.
Verification policy snapshots should use
`Identity.Verification.Policies.Validate`, `Validation_Accepted`,
`Token_Lifetime_Rejected`, `Attempt_Limit_Rejected`, and
`Supersession_Rejected`; policy construction bounds `Maximum_Attempts` by
`Identity.Limits.Max_Factor_Challenges`. `Valid` remains the Boolean
compatibility wrapper over the structured classifier.
Generic action-token issuance should use
`Identity.Operations.Tokens.Issue.Execute` with `Issue_Request` when no
purpose-specific operation exists. The request accepts a bounded token secret
container plus an explicit verifier domain and persists only the derived
verifier. Prefer purpose-specific reset, verification, and contact-change
operations when they apply, because those operations fix the purpose and
domain together.
Externally presented split action tokens should be parsed with
`Identity.Tokens.Generation.Parse` before repository lookup or verifier work.
The parser accepts exactly one separator and reports empty input, oversized
input, missing separator, multiple separators, missing public part, and missing
secret part as structured status values. Use `Accepted_Input`,
`Rejected_Input`, `Empty_Rejection`, `Size_Rejection`,
`Structural_Rejection`, `Public_Part_Rejection`, and
`Secret_Part_Rejection` before token lookup or verifier work.
Adapters should use `Identity.Tokens.Definitions.Admission`,
`Admission_Accepted`, `Admission_Rejected`, `Action_Rejected`, `Action_State_Rejected`,
`Action_Terminal_Rejected`, `Action_Advance_Rejected`, `No_Mutation`, `Can_Verify`,
`Can_Complete`, `Is_Consumed_State`, `Is_Terminal`, and `Can_Advance` before
staging token verification, completion, expiration, revocation, supersession,
or attempt-limit transitions. Terminal token states must not advance back to
active states, and illegal state advances must be classified separately from
terminal-state rejection.
Account administrative and requirement operations must derive the next account
state through `Identity.Accounts.States.Can_Apply` and
`Identity.Accounts.States.Apply`. Closed or retired accounts are terminal for
these public account operations; test fixtures that deliberately reopen state
must do so through explicit repository setup and not through public
administrative operations. Branch on derived account eligibility through
`Eligible_State`, `Restricted_State`, `Ineligible_State`, and
`Authentication_Blocked` instead of comparing eligibility literals at call
sites. Administrative transitions must carry a structurally
valid authenticated actor, reason ID, operation ID, correlation ID, request
time, expected account version, previous and new administrative states, and a
mandatory-audit requirement through `Identity.Accounts.Administrative`.
Adapters should branch on `Identity.Accounts.Administrative.Admission` with
`Admission_Accepted`, `Admission_Rejected`, `Actor_Rejected`, `Reason_Rejected`,
`Operation_Rejected`, `Correlation_Rejected`,
`Mandatory_Audit_Rejected`, `Same_State_Rejected`, and
`Closed_State_Rejected` before staging administrative state changes.
Account lifecycle admission should use
`Identity.Accounts.Lifecycle.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Pending_Rejection`, `Expired_Rejection`, and
`Retired_Rejection` before authentication or lifecycle-sensitive mutation.
Account verification admission should use
`Identity.Accounts.Verification.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Verification_Not_Required_Status`, `Pending_Rejection`, and
`Reverification_Rejection` before authentication or verification-sensitive
workflows. `Satisfies_Requirement` and `Requires_Action` remain compatibility
predicates.
Requirement and unlock operations must use their request overloads when the
caller has a loaded account snapshot, so stale expected versions fail as
structured state conflicts. Account-state mutations must advance entity
versions through `Identity.Versions.Next_Entity_Version`.
Recovery-code generation and regeneration should use the request overloads on
`Identity.Operations.Factors.Generate_Recovery_Codes.Execute` and
`Identity.Operations.Factors.Regenerate_Recovery_Codes.Execute`; these accept
bounded recovery-code secret containers and derive verifier-only set records
inside Identity. Regeneration commands should use
`Identity.Recovery_Codes.Sets.Admission`, `Admission_Accepted`,
`Admission_Rejected`, and `Can_Revoke_During_Regeneration` before revoking
prior code verifiers. Use `Active_State`, `Consumed_State`, and
`Revoked_State` when a trusted branch needs direct recovery-code lifecycle
classification. The structured classifier distinguishes active, consumed, and
revoked code states before recovery-code set mutation. Staged regeneration
should use
`Identity.Operations.Factors.Regenerate_Recovery_Codes.Staged_Regenerate_Request`;
a stale expected affected count returns `Version_Conflict` before any prior
code verifier is revoked or the replacement set is installed. Recovery-code
consumption and regeneration mutations must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Recovery-code policy snapshots should use
`Identity.Recovery_Codes.Policies.Validate`, `Validation_Accepted`,
`Display_Rejected`, `Regeneration_Rejected`, and `Assurance_Rejected` before
issuing or regenerating recovery codes. `Valid` remains the Boolean
compatibility wrapper over the structured classifier.
Expose recovery-code set state through
`Identity.Recovery_Codes.Sets.Summary`; the projection carries set ID,
principal ID, creation time, version, total count, active count, consumed
count, and revoked count without exposing code IDs, plaintext codes, or
verifier text. Consumers should use `Has_Usable_Code` and `Fully_Consumed`
plus `Has_Revoked_Code` and `Fully_Revoked` instead of reading repository set
records.
TOTP enrollment should begin through
`Identity.Operations.Factors.Begin_Enrollment.Execute` with
`TOTP_Begin_Request`; this creates a pending credential without caller-supplied
verifier material. Activation and verifier derivation happen only during
completion.
MFA method selection should use `Identity.Multi_Factor.Methods.Admission`,
`Admission_Accepted`, `Admission_Rejected`, `Inactive_Rejection`,
`Category_Rejection`, and
`Usable_For_MFA`; recovery methods are not ordinary possession-factor MFA
methods.
MFA policy snapshots should use `Identity.Multi_Factor.Policies.Validate`,
`Validation_Accepted`, `Challenge_Limit_Rejected`, and
`Attempt_Limit_Rejected` before issuing or retrying factor challenges. `Valid`
remains the Boolean compatibility wrapper over the structured classifier.
TOTP enrollment completion should use
`Identity.Operations.Factors.Complete_Enrollment.Execute` with
`TOTP_Completion_Request` so Identity derives the stored verifier from the
TOTP secret container while preserving the pending-factor activation state
machine.
MFA enrollment activation should be classified with
`Identity.Multi_Factor.Enrollment.Activation_Admission`,
`Activation_Accepted`, `Proof_Required_Rejection`,
`Already_Active_Rejection`, `Cancelled_Rejection`, and `Expired_Rejection`;
`Can_Activate` remains a convenience predicate over that classifier.
Expose TOTP credential state through
`Identity.One_Time_Passwords.Credentials.Summary`; the projection carries the
credential ID, principal ID, algorithm ID, lifecycle state, verifier-present
fact, highest accepted replay counter, and entity version without exposing the
secret verifier. Projection consumers should use `Credential_Usable` and
`Terminal` rather than inspecting repository records.
Staged TOTP completion should use
`Identity.Operations.Factors.Complete_Enrollment.Staged_TOTP_Completion_Request`;
if the pending credential version no longer matches the expected value, the
command returns `Version_Conflict` before factor activation or verifier
replacement.
TOTP policy snapshots should use
`Identity.One_Time_Passwords.Policies.Validate`, `Validation_Accepted`,
`Attempt_Limit_Rejected`, and `Replay_Prevention_Rejected` while policy
construction bounds `Maximum_Attempts` by
`Identity.Limits.Max_Factor_Challenges`. `Valid` remains the Boolean
compatibility wrapper over the structured classifier.
Cryptographic OTP verification consumers should classify
`Identity.Crypto.One_Time_Passwords.OTP_Verification_Status` with
`Verification_Accepted`, `Presentation_Rejected`, `Replay_Rejected`,
`Unsupported_Algorithm_Rejected`, `Missing_Cryptographic_Capability`, and
`Operational_Failure`. Unsupported algorithms and missing cryptographic
capability are infrastructure or policy failures; do not count them as
ordinary failed factor presentations.
Cryptographic registry consumers should classify algorithm descriptors through
`Identity.Crypto.Registries.Registered_Status`,
`Creation_Disabled_Status`, `Verification_Disabled_Status`, `Retired_Status`,
and `Admission_Rejected`, and should classify algorithm lifecycle through
`Identity.Crypto.Algorithms.Current_State`, `Deprecated_State`,
`Retired_State`, `Creation_Allowed_By_State`, and
`Verification_Allowed_By_State`. Capability checks should use
`Identity.Crypto.Capabilities.Capability_Available` and
`Capability_Missing`; event-integrity verification should use
`Verification_Accepted`, `Verification_Rejected`, `Not_Configured_Status`,
`Missing_Cryptographic_Capability`, and `Operational_Failure`.
Credential factor adapters should use
`Identity.Credentials.States.Authentication_Admission`,
`Authentication_Accepted`, `Authentication_Rejected`, `No_Mutation`, `Created_Rejection`,
`Replacement_Pending_Rejection`, `Migration_Pending_Rejection`,
`Expired_Rejection`, `Locked_Rejection`, `Retired_Rejection`, and
`Revoked_Rejection` before credential authentication branching.
Credential factor adapters should also use
`Identity.Credentials.Lifecycle.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Can_Begin_Factor_Enrollment`, `Can_Complete_Factor_Enrollment`,
`Can_Remove_Factor`, `No_Mutation`, and `Occupies_Active_Slot` instead of duplicating active,
terminal, or removable state checks. The structured classifier distinguishes
active-required, inactive-slot-required, terminal, successor-state, and
migration-state rejections before repository commands mutate credential state.
Use `Active_Required_Rejection`, `Inactive_Slot_Rejection`,
`Terminal_Rejection`, `Successor_State_Rejection`, and
`Migration_State_Rejection` for trusted lifecycle diagnostics.
Staged factor removal should use
`Identity.Operations.Factors.Remove.Staged_Removal_Request`; stale expected
credential versions return `Version_Conflict` before revoking the factor.
Credential replacement and revocation adapters should use
`Admission`, `Can_Issue_As_Active`, `Can_Be_Replacement_Predecessor`,
`Can_Be_Replacement_Successor`, and `Can_Revoke` before mutating password,
API-key, or other credential lifecycle state. Credential lifecycle and TOTP
replay-state mutations must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Credential migration adapters should use `Can_Begin_Migration` before entering
the migrating state and `Can_Complete_Migration` before publishing the upgraded
active verifier. Migration is not a replacement shortcut; it follows successful
old-verifier validation and must not complete from an active predecessor state.
After verifier inspection, classify `Identity.Passwords.Migrations.Decide` with
`Authentication_May_Proceed`, `Migration_Not_Needed`,
`Migration_Should_Be_Attempted`, `Migration_Is_Mandatory`,
`Session_Issuance_Restricted`, and `Operational` before issuing, restricting,
or failing an authentication result.
Password hashing consumers should classify
`Identity.Crypto.Password_Hashing.Verification_Outcome` with
`Verification_Accepted`, `Verification_Rejected`,
`Malformed_Verifier_Rejected`, `Unsupported_Format_Rejected`,
`Unsupported_Algorithm_Rejected`, `Resource_Limit_Rejected`,
`Cryptographic_Failed`, and `Operational_Failure`; migration status should use
`Migration_Current`, `Upgrade_Recommended_Status`,
`Upgrade_Required_Status`, and `Requires_Migration`.
Purpose-bound bearer verifier consumers should apply the same outcome
classification through `Identity.Crypto.Secret_Verifiers` before mapping
verification, malformed verifier, unsupported capability, resource limit, or
cryptographic-service results.
Credential assurance adapters should compare dependency domains with
`Identity.Credentials.Dependencies.Same_Domain` and
`Independent_From`; factor independence requires distinct bounded dependency
domain IDs and both domains marked independent.
Authentication transaction and challenge adapters should use
`Identity.Authentication.Transactions.Admission`, `Can_Begin`,
`Can_Issue_Challenge`, `Can_Complete_Challenge`, `Can_Satisfy`,
`Can_Upgrade_Assurance`, `Can_Consume`, `Can_Cancel`, `Is_Terminal`, and
`Expired_At` for transaction action, state, expiry, and evidence admission.
The structured classifier distinguishes expired transactions, wrong-state
transitions, and missing evidence before repository commands mutate
authentication transaction state. Branch on transaction admission with
`Admission_Accepted`, `Admission_Rejected`, `Expired_Rejected`,
`State_Rejected`, and `Evidence_Required` rather than comparing enum literals
in adapters. Use `Command_Applied`, `Unknown_Transaction`,
`Conflict_Status`, `State_Conflict_Status`, `Version_Conflict_Status`,
`Capacity_Conflict_Status`, and `No_Mutation` when branching on atomic
authentication transaction command outcomes. Use
`Identity.Authentication.Challenges.Admission`, `Admission_Accepted`,
`Can_Issue`, `Can_Record_Failure`, `Can_Retry`, `Can_Cancel`, `Is_Terminal`,
and `Admit_Completion` for challenge issuance, retry, failure, cancellation,
terminal, and completion admission. The action classifier distinguishes
expired projections and terminal challenge states before commands mutate
challenge state. Branch on challenge action admission with
`Action_Admission_Accepted`, `Action_Admission_Rejected`, `Action_Expired_Rejected`,
`Action_State_Rejected`, and `Action_Terminal_Rejected` rather than comparing
enum literals in adapters.
Use `Completion_Admitted`, `Completion_Rejected`,
`Already_Completed_Rejected`, `State_Rejected`, `Expiration_Rejected`, and
`No_Mutation` when branching on challenge completion admission outcomes.
Expose transaction and challenge state through
`Identity.Authentication.Transactions.Summary` and
`Identity.Authentication.Challenges.Summary`; these projections carry bounded
state, version, count, and expiry facts. Projection overloads of the admission
predicates are expiry-aware and should be used by downstream summary consumers.
Authentication evidence records carry explicit principal, transaction, and
optional challenge bindings; use `Bound_To_Principal`, `Bound_To_Transaction`,
`Bound_To_Challenge`, and `Transferable_To` before accumulated evidence changes
transaction or session state. Staged challenge issuance should
use `Identity.Operations.Factors.Issue_Challenge.Staged_Issue_Request`; stale
expected transaction versions return `Version_Conflict` before any challenge is
created or transaction state advances. Staged challenge completion should use
`Identity.Operations.Authentication.Continue.Staged_Challenge_Completion_Request`;
stale expected challenge or transaction versions return `Version_Conflict`
before the challenge is completed, evidence count changes, or transaction state
advances. Challenge completion must report expired, completed, failed, and
cancelled states before mutating evidence or transaction state. Staged
transaction satisfaction should use
`Identity.Operations.Authentication.Continue.Staged_Satisfaction_Request`;
stale expected transaction versions return `Version_Conflict` before a
challenge-completed transaction is marked satisfied. Transaction and challenge
state changes must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Session assurance upgrade should use
`Identity.Operations.Sessions.Upgrade_Assurance.Staged_Upgrade_Request` when
the caller has staged session and transaction snapshots; stale expected session
or transaction versions return `Version_Conflict` before assurance, last-seen
time, session revision, or transaction consumption changes.
Recovery transaction adapters should use
`Identity.Recovery.Transactions.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Admission_State_Rejected`, `Admission_Terminal_Rejected`, `Can_Begin`,
`Expired_At`, `Can_Accept_Evidence`, `Can_Approve`,
`Can_Require_Credential_Reestablishment`,
`Can_Establish_Restricted_Authentication`,
`Requires_Credential_Reestablishment`, `Can_Complete`, `Can_Cancel`, and
`Is_Terminal` before mutating recovery transaction or account restriction state.
Adapters and projections should use `Evidence_Phase`,
`Evidence_Accepted_Phase`, `Approval_Phase`,
`Credential_Reestablishment_Phase`, `Restricted_Authentication_Phase`,
`Successful_Terminal`, `Failed_Terminal`, and `Cancelable_State` instead of
literal state branching when classifying recovery lifecycle progress. The typed
classifier distinguishes wrong recovery state from terminal-state rejection
before evidence, approval, completion, restricted-authentication, or
cancellation transitions.
Use `Transition_Applied`, `Unknown_Transaction`, `Conflict_Status`,
`State_Conflict_Status`, `Version_Conflict_Status`,
`Capacity_Conflict_Status`, and `No_Mutation` when branching on recovery
transition command outcomes. Staged
evidence acceptance should use
`Identity.Operations.Recovery.Continue.Staged_Continue_Request`; stale expected
transaction versions return `Version_Conflict` before evidence state advances.
Recovery evidence adapters should use
`Identity.Recovery.Evidence.Bound_To_Recovery_Transaction`,
`Is_Recovery_Category`, `Restricted_Assurance`, and `Summary` when accepting or
projecting recovery evidence. The summary carries recovery source, evidence ID,
binding facts, accepted instant, and reduced-assurance classification without
turning recovery evidence into ordinary high-assurance factor evidence.
Staged completion should use
`Identity.Operations.Recovery.Complete.Staged_Completion_Request`; stale
expected transaction or account versions return `Version_Conflict` before
recovery restrictions, account requirements, transaction state, or entity
versions change. Completion must remain gated on accepted evidence and terminal
recovery states must not be cancelled or reactivated. Staged cancellation should
use `Identity.Operations.Recovery.Cancel.Staged_Cancellation_Request`; stale
expected transaction versions return `Version_Conflict` before the transaction
enters the cancelled terminal state. Use
`Identity.Recovery.Restrictions.Downstream_Recovery_Restricted` when projecting
structured recovery restrictions into downstream authentication facts; do not
replace the structured restriction record with application action checks.
Recovery transaction and
affected account state changes must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Recovery-derived authentication should use
`Identity.Recovery.Restrictions.Recovery_Authentication_Restricted` when
issuing restricted continuation state; `Restricted` only reports that at least
one restriction is present. Use
`Identity.Recovery.Restrictions.Session_Request_Admission` with
`Allow_Effective_Request` or `Require_Exact_Request`, then branch with
`Admission_Accepted`, `Admission_Rejected`, `Reduced_To_Interactive`, and `Persistent_Rejection`
before issuing a session from recovery authority. `Allows_Session_Request`
remains the strict compatibility predicate. Use `Effective_Session_Request`
when a recovery workflow reduces a prohibited persistent session request to an
interactive session, and use `Requires_Limited_Session_Lifetime` when selecting
the bounded session lifetime for recovery-derived continuity.
Expose recovery authority state through `Identity.Recovery.Authority.Summary`;
the projection carries expiry, short-lived status, password-reestablishment
requirement, and current usability without adding application action semantics.
Use `Usability`, `Usability_Accepted`, `Short_Lived_Rejection`,
`Password_Reestablishment_Rejection`, `Expired_Rejection`,
`Projection_Usability_Rejection`, `Expired`, and
`Requires_Password_Reestablishment` when rendering safe authority state. Use
`Requires_Restricted_Authentication` to bind a usable authority projection to
the structured recovery restriction record. Use `Issuance`,
`Issuance_Accepted`, `Issuance_Authority_Rejected`,
`Issuance_Restrictions_Rejected`, and
`Issuance_Session_Request_Rejected` when branching on trusted
recovery-derived continuity outcomes. `Can_Issue_Restricted_Authentication`
remains the Boolean compatibility predicate for code that only needs the
accepted-or-rejected decision.
Recovery policy snapshots should use `Identity.Recovery.Policies.Validate`,
`Validation_Accepted`, `Authority_Lifetime_Rejected`,
`Credential_Reestablishment_Rejected`, and
`Existing_Session_Consequence_Rejected` before recovery-derived
authentication is admitted. `Valid` remains the Boolean compatibility wrapper
over the structured classifier.
Use `Identity.One_Time_Passwords.Credentials.Admit_Counter` before attempting
to advance TOTP replay state, and use
`Identity.Recovery_Codes.Sets.Admission` and `Admit_Matched_Code` after a
recovery-code verifier match. Repository commands still perform the atomic
state mutation and advance the affected set version through
`Identity.Versions.Next_Entity_Version`.
Use `Identity.One_Time_Passwords.Credentials.Evaluate_Presentation` to
classify missing TOTP credential, wrong presented code, unusable credential,
and replay-state outcomes before staging counter acceptance.
Use `Identity.Recovery_Codes.Sets.Evaluate_Presentation` to classify missing
lookup, failed verifier comparison, reuse, and unusable-code state before
staging recovery-code consumption.
Classify TOTP and recovery-code outcomes with
`Counter_Accepted`, `Replay_Rejected`, `Verification_Rejected`,
`Retryable_By_Presentation`, `Unknown_Credential`, `Unusable_Credential`,
`Conflict`, `No_Replay_State_Mutation`, `Consumption_Succeeded`,
`Reuse_Rejected`, `Unknown_Code`, and `No_State_Mutation` before result
projection or mutation staging. Only accepted TOTP counters and consumed recovery codes should
advance replay or single-use state.
Staged TOTP consumers should use
`Identity.Operations.Factors.Accept_TOTP_Counter.Accept_Request`; if the stored
credential version no longer matches `Expected_Version`, the command returns
`State_Conflict` before replay classification or replay-state mutation.
Staged recovery-code consumers should use
`Identity.Operations.Factors.Consume_Recovery_Code.Consume_Request`; if the
stored set version no longer matches `Expected_Version`, the command returns
`State_Conflict` before consuming or reporting verifier reuse.
Session creation should use `Identity.Operations.Sessions.Create.Execute`
with `Create_Request` when the caller has a bearer session secret. The request
accepts a bounded `Session_Secret` container and derives the persisted
session-token verifier inside Identity; the session-record overload remains
for conformance fixtures and adapter-level state setup.
Session renewal and activity updates should use
`Identity.Sessions.Activity.Admit_Update` to distinguish current-session
admission from idle expiration, absolute expiration, revocation, and invalid
idle-extension requests. Renewal must not extend idle expiration beyond the
absolute lifetime or to a time already expired at the operation instant.
Use `Activity_Update_Admitted`, `Activity_Update_Rejected`,
`Expiration_Rejected`, `Idle_Expiration_Rejected`,
`Absolute_Expiration_Rejected`, `Revocation_Rejected`,
`Invalid_Extension_Rejected`, and `No_Activity_Mutation` instead of branching
directly on activity-admission status literals.
Session records, lookup handles, and summaries carry original authentication,
primary authentication, optional MFA completion, and optional step-up instants;
renewal and activity updates must preserve those values while advancing only
activity and revision facts.
Session lookup handle consumers should use
`Identity.Sessions.Handles.Found`, `Disclosure_Collapsed_Invalid`,
`Unknown_Status`, `Not_Verified_Status`, `Retryable_By_Presentation`,
`Expired`, `Revoked`, `Rejected`, and `Terminal_Rejection` instead of
branching directly on lookup status literals.
`Identity.Sessions.Policies.Validate` classifies zero-duration idle, absolute,
and remember-me lifetimes before checking their ordering; policy snapshots must
not admit non-positive session continuity windows. Use `Validation_Accepted`,
`Duration_Rejected`, `Ordering_Rejected`, `Idle_Rejected`,
`Absolute_Rejected`, and `Remember_Me_Rejected` before accepting a session
policy. `Valid` remains the Boolean compatibility wrapper over that classifier.
Session lookup, expiration sweeps, and session-bound assurance updates should
use `Identity.Sessions.Expiration.Evaluate`, `Evaluate_Detail`,
`Blocks_Continuity`, `Allows_Continuity`,
`Rejects_Continuity`, `Idle_Timeout_Expired`, `Absolute_Lifetime_Expired`,
`Revocation_Blocks_Continuity`, `Expiration_Blocks_Continuity`, and `Usable`
for idle, absolute, and revoked continuity states instead of duplicating time
comparisons. `Evaluate_Detail` exposes idle, absolute, and revoked blockers as
independent facts even when `Evaluate` returns one primary status.
Session adapters should use `Identity.Sessions.Definitions.Admission`,
`Admission_Accepted`, `Admission_Rejected`, `Is_Active`, `Lookup_Reports_Revoked`,
`Lookup_Reports_Expired`, `Active_Required_Rejection`,
`Unusable_Required_Rejection`, `Revocable_Required_Rejection`,
`Retained_State_Required_Rejection`, `No_Mutation`, `Can_Revoke`, `Can_Expire`,
`Retainable`, and
`Same_Public_Reference` for session-state admission, lookup projection, and
public-reference uniqueness instead of duplicating enum or bounded-text
checks. The structured classifier distinguishes continuity lookup, rejection
lookup, revocation, expiration, and retention checks before repository
commands mutate session state. Session revocation, rotation, expiration,
renewal, activity, and assurance mutations must advance entity versions
through `Identity.Versions.Next_Entity_Version`.
Session rotation and revocation paths should use
`Identity.Sessions.Rotation.Rotation_Allowed`, `State_Rejected`,
`Generation_Rejected`, `Rotation_Rejected`, and
`Identity.Sessions.Revocation.Applied_Result`, `Already_Final`,
`Missing_Target`, `Conflict_Result`, `Revocation_Rejected`, and `No_Mutation`
before issuing successors, replay responses, or revocation projections.
Staged single-session revocation should use
`Identity.Operations.Sessions.Revoke.Staged_Revoke_Request`; stale expected
session versions return `Version_Conflict` before the session is revoked.
Staged family revocation should use
`Identity.Operations.Sessions.Revoke_Family.Staged_Revoke_Request`; a stale
expected affected count returns `Version_Conflict` before any family session is
revoked.
Staged principal-wide revocation should use
`Identity.Operations.Sessions.Revoke_Principal.Staged_Revoke_Request`; a stale
expected affected count returns `Version_Conflict` before any principal session
is revoked.
Staged credential-derived and provider-derived revocation should use
`Identity.Operations.Sessions.Revoke_Credential.Staged_Revoke_Request` and
`Identity.Operations.Sessions.Revoke_Provider.Staged_Revoke_Request`; stale
expected affected counts return `Version_Conflict` before any matching session
is revoked.
Session rotation should use `Identity.Operations.Sessions.Rotate.Execute`
with `Rotate_Request` for the same reason: the successor bearer secret stays
in a bounded secret container until Identity derives the persisted verifier,
while the repository command enforces predecessor retirement, family binding,
and generation advancement through
`Identity.Sessions.Rotation.Can_Rotate` and
`Identity.Sessions.Rotation.Matches_Successor_Generation`. Use
`Identity.Sessions.Rotation.Same_Rotation_Lineage` to verify that the
successor stays bound to the same family and principal while advancing the
generation. Exhausted rotation generations are not valid predecessors;
adapters must not accept a saturated generation as a non-advancing successor.
Staged session rotation should use
`Identity.Operations.Sessions.Rotate.Staged_Rotate_Request`; if the stored
predecessor version no longer matches `Expected_Predecessor_Version`, the
command returns `Version_Conflict` before disclosing predecessor rotation state
or publishing a successor.
Session-domain projection code should use
`Identity.Sessions.Projections.Summary`, which returns the same bounded
verifier-free `Session_Summary_Projection` as the general projection namespace.
Session summaries include IDs, assurance, authentication-age fields, expiration
boundaries, remember-me state, generation, lifecycle state, session revision,
and a verifier-present fact; they never include bearer secrets, raw public
references, verifier text, or repository internals. Consumers should use
`Identity.Projections.Sessions.Lookup_Usable` and `Terminal` for continuity
classification instead of reading repository records.
Principal and account projection code should use
`Identity.Projections.Principals.Summary`,
`Identity.Principals.Projections.Summary`,
`Identity.Projections.Accounts.Summary`, or
`Identity.Accounts.Projections.Summary` when returning repository records to
callers. Lifecycle and eligibility checks should use the projection predicates
`Active`, `Retired`, `Evaluate`, `Eligible`, `Ineligible`,
`Administratively_Restricted`, `Requires_Credential_Action`,
`Recovery_Restricted`, and `Lock_Restricted` instead of reading repository
records outside the adapter boundary.
Credential projection code should use
`Identity.Projections.Credentials.Summary` or
`Identity.Credentials.Projections.Summary` when returning credential records to
callers. The summary exposes the credential identifier, principal, kind, state,
and version only; lifecycle checks should use the projection predicates
`Can_Authenticate` and `Terminal`.
Event projection consumers should use `Identity.Projections.Events` predicates
for actor authentication state, subject-principal presence, actor-subject
matching, outcome success/rejection/failure, high-severity classification, and
operational-attention classification. Do not duplicate enum interpretation in
adapters or rendered diagnostics.
Use `Identity.Sessions.Replay` consequence predicates when applying rotated
predecessor replay policy. The enum value should not be reinterpreted in
operation code; helpers distinguish rejecting the presented predecessor,
revoking a successor, revoking a family, revoking all principal sessions, and
requiring reauthentication. Use `Revocation_Required` before staging
replay-triggered continuity mutation.
Session-family continuity should use `Identity.Sessions.Families.Admission`,
`Admission_Accepted`, `Admission_Rejected`, `Revoking_Rejection`,
`Revoked_Rejection`, `No_Mutation`, `Usable`, `Active_State`, `Revoking_State`,
`Revoked_State`, and `Terminal_State` before accepting a session family for
renewal, rotation, or step-up.

Principal kind checks should use `Identity.Principals.Kinds.Human_Principal`,
`Service_Principal`, and `System_Principal` before projecting principal facts
or constructing service and system actor contexts.
Service API-key authentication is a structured authentication operation through
`Identity.Operations.Authentication.API_Key.Execute` or the API-key management
alias `Identity.Operations.API_Keys.Authenticate.Execute`; it returns an
authenticated result without granting roles, permissions, or resource access.
Successful authentication is a security transition that records verifier-safe
last-use metadata and advances the API-key credential version; rejected
presentations must not update that metadata. Staged API-key authentication
should use `Identity.Operations.API_Keys.Authenticate.Staged_Authentication_Request`
or `Identity.Operations.Authentication.API_Key.Staged_Authentication_Request`;
stale expected credential versions return `Conflict` before last-use metadata or
credential version changes. API-key lifecycle, rotation, and last-use mutations
must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Adapters should call `Identity.API_Keys.Credentials.Can_Authenticate` for
API-key credential lifecycle and expiration admission before verifier work.
Use `Authentication_Admission` when a precise trusted classifier is needed; it
distinguishes allowed authentication, unusable credential state, missing
verifier material, and expired credential without exposing the verifier. Keep
`Admission_Accepted`, `Admission_Rejected`, `State_Rejected`, `Verifier_Rejected`,
`Expiration_Rejected`, and `No_Mutation` as the only enum interpretation points
in adapters.
Use `Identity.API_Keys.Credentials.Has_Credential_Class` when an API-key
workflow requires bounded credential-class metadata; this metadata is safe
classification input only and does not carry access semantics.
Adapters should use `Same_Public_Key_Id` for public key identifier uniqueness
and `Matches_Public_Key_Id` for lookup by a presented public key identifier.
Expose API-key summaries through `Identity.API_Keys.Credentials.Summary`; the
projection carries public-key metadata, lifecycle, expiry, last-use, and
rotation facts plus a verifier-present boolean, and has no verifier text field.
Projection overloads of `Can_Authenticate`, `Has_Verifier`,
`Authentication_Admission`, `Has_Credential_Class`, `Same_Public_Key_Id`, and
`Matches_Public_Key_Id` should be used by downstream summary consumers.
API-key rotation adapters should use
`Identity.API_Keys.Rotation.Admission` and `Can_Rotate` before staging
rotation, and `Successor_Admission` for successor generation admission.
`Matches_Successor_Generation` remains the Boolean compatibility predicate.
Exhausted rotation generations must not be treated as valid non-advancing
successors. Classify overlap, rotation, and successor generation admission through
`Identity.API_Keys.Rotation.Admission_Accepted`,
`Admission_Rejected`, `Admission_Generation_Rejected`, `Admission_Overlap_Rejected`,
`Successor_Admission_Accepted`, `Successor_Admission_Rejected`, `Successor_Predecessor_Rejected`,
`Successor_Mismatch_Rejected`, `Overlap_Usable`, `Overlap_Terminal`,
`Rotation_Allowed`, and `Generation_Rejected` before deriving or returning a
successor key.
API-key issue, rotation, and authentication revalidate that the owning
principal is active. Credentials for retired principals reject generically and
do not update last-use metadata.
Generic service credential admission through
`Identity.Service_Credentials.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Verifier_Missing_Rejection`,
`Credential_State_Rejection`, and `No_Mutation` requires both an
active credential lifecycle state and non-empty verifier material; a public
label or service-principal kind alone is never authentication evidence.
When a trusted branch needs the exact lifecycle cause, use
`Not_Activated_Rejection`, `Replacement_Pending_Rejection`,
`Migration_Pending_Rejection`, `Expired_Rejection`, `Locked_Rejection`,
`Retired_Rejection`, and `Revoked_Rejection` instead of matching enum literals.
`Can_Authenticate` remains a convenience predicate over that admission result.
Expose service credential metadata through
`Identity.Service_Credentials.Summary`; the projection carries public label,
class, state, version, and a Boolean verifier-present fact without copying
verifier text. Projection consumers should use `Admission`,
`Can_Authenticate`, `Has_Public_Label`, and `Has_Credential_Class` on that
summary.
System actors use `Identity.System_Actors.Establishes_Identity_Only` and
`Requires_Downstream_Policy` to make the boundary explicit: Identity establishes
the system principal, but downstream application policy still decides protected
operation access.
Use `Identity.System_Actors.Summary` when exposing system actor facts; the
projection carries only principal kind and explicit identity-boundary booleans.
Prefer `Identity.Operations.API_Keys.Issue.Execute` with `Issue_Request` for
new service credentials; it accepts an API-key secret container and derives the
stored verifier inside Identity while preserving the caller-supplied
credential-class identifier. Secret-bearing issue requests are admitted through
`Identity.API_Keys.Policies.Validate` and
`Identity.API_Keys.Policies.Evaluate_Issue_Lifetime`. Policy validation
classifies zero active-key capacity, non-positive overlap lifetime, and missing
expiration requirements through `Capacity_Rejected`, `Overlap_Rejected`, and
`Expiration_Policy_Rejected`. Lifetime admission rejects missing or non-future
expirations before verifier derivation. Classify that result with
`Issue_Lifetime_Accepted`, `Policy_Rejected`, `Expiration_Rejected`, and
`Verifier_Derivation_Allowed`; only accepted lifetimes may proceed to verifier
derivation. The lower-level
credential-record overload is for conformance fixtures and adapter-level state
setup.
Prefer `Identity.Operations.API_Keys.Rotate.Execute` with `Rotate_Request`
for service-credential rotation; it accepts the successor API-key secret
container, derives the successor verifier inside Identity, preserves the
successor credential-class identifier, and leaves the repository command
responsible for retiring the predecessor atomically. Secret-bearing rotation
requests use the same issue-lifetime admission and reject invalid successor
lifetimes before repository mutation.
Staged API-key rotation should use
`Identity.Operations.API_Keys.Rotate.Staged_Rotate_Request`; if the stored
predecessor credential version no longer matches
`Expected_Predecessor_Version`, the command returns `Version_Conflict` before
disclosing predecessor credential state or publishing a successor.
Staged API-key revocation should use
`Identity.Operations.API_Keys.Revoke.Staged_Revoke_Request`; stale expected
credential versions return `Version_Conflict` before credential revocation.

External authentication accepts only normalized validated assertions from
adapters. It registers replay state before resolution, never auto-links by
email or alternate contact claims, and revalidates that the bound local
principal is active before returning an authenticated result. New external
bindings require an active local principal. Staged external authentication
should use `Identity.Operations.Authentication.External.Staged_Authentication_Request`
when the caller has a resolved binding snapshot; stale expected binding versions
return `Conflict` before replay registration or authentication-state mutation.
External assurance mapping adapters should use
`Identity.External_Providers.Assurance.Mapping_Accepted`,
`Mapping_Rejected`, `Provider_Rejected`, `Profile_Rejected`, and
`Requires_Additional_Factor` when converting provider-authentication facts into
local assurance outcomes.
External enrollment adapters should use
`Identity.External_Providers.Enrollment.Existing_Binding_Required`,
`Explicit_Binding_Allowed`, `Policy_Controlled_JIT_Allowed`,
`Enrollment_Allowed`, `Enrollment_Rejected`, `Ambiguity_Rejected`, and
`Provider_Rejected` when handling explicit binding and policy-controlled JIT
enrollment outcomes.
Identity binding adapters should use
`Identity.Identities.Bindings.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Active_Rejected`, `Revoked_Rejected`, `No_Mutation`,
`Usable_For_Resolution`, `Can_Revoke`, `Can_Replace`,
`Active_Matches_Subject`, and `Same_Active_Subject` when resolving, revoking,
changing, or enforcing uniqueness for local subject bindings. The structured
admission classifier distinguishes subject resolution, binding revocation, and
binding replacement checks before repository mutation or public result
projection. Binding lifecycle mutations must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Staged identity-binding revocation should use
`Identity.Operations.Identities.Revoke.Staged_Revoke_Request`; stale expected
binding versions return `Version_Conflict` before the binding is revoked or
removed from resolution.
External binding adapters should use
`Identity.External_Providers.Bindings.Admission`,
`Admission_Accepted`, `Admission_Rejected`, `Active_Rejected`, `Revoked_Rejected`,
`No_Mutation`, `Active_State`, `Pending_State`, `Suspended_State`, `Revoked_State`,
`Rebinding_Required_State`, `Authentication_State_Rejected`,
`Lifecycle_Mutation_State_Rejected`, `Usable_For_Authentication`, `Can_Revoke`,
and `Can_Replace` when resolving external assertions, revoking provider
bindings, or replacing explicit provider bindings. The structured classifier
distinguishes assertion authentication from lifecycle mutation checks before
repository commands register replay state or mutate binding state.
Staged external binding revocation should use
`Identity.Operations.External_Identities.Revoke.Staged_Revoke_Request`; stale
expected binding versions return `Version_Conflict` before the binding is
revoked or removed from external assertion resolution.
Adapters should use `Same_Active_External_Key` when enforcing uniqueness for
active provider bindings and `Active_Matches_Assertion` when resolving a
validated assertion against an explicit local binding. External binding
lifecycle mutations must advance entity versions through
`Identity.Versions.Next_Entity_Version`.
Safe external binding projections are built with
`Identity.Projections.External_Bindings.Summary` or the
`Identity.External_Providers.Projections` alias. Downstream projection users
should use `Usable_For_Authentication`, `Same_External_Key`,
`Same_Active_External_Key`, `Matches_Assertion`, and
`Active_Matches_Assertion` instead of reconstructing provider-key comparisons.
External authentication should call
`Identity.External_Providers.Assertions.Admit_For_Core` before replay
registration or binding resolution; expired assertions and missing or invalid
nonce validation are rejected at this boundary. Classify the admission result
with `Assertion_Admitted`, `Assertion_Rejected`, `Assertion_Expired`,
`Nonce_Rejected`, and `Replay_Registration_Eligible` before registering replay
state or projecting safe outcomes.
Nonce validation status should be classified with `Nonce_Not_Required`,
`Nonce_Validated`, `Nonce_Missing`, `Nonce_Invalid`, and
`Nonce_Unacceptable`. Protocol adapters should classify
`Identity.Adapters.External_Providers.Assertion_Adapter_Status` with
`Validated_Status`, `Invalid_Status`, `Expired_Status`, `Audience_Rejected`,
`Nonce_Rejected`, `Provider_Rejected`, `Replay_Rejected`,
`Missing_Capability_Status`, `Infrastructure_Failed`, `Adapter_Rejected`, and
`Operational_Failure` before constructing a normalized assertion result.
Use `Has_Replay_Fingerprint`, `Ready_For_Replay_Registration`, and
`Same_External_Key` on normalized assertions before registering replay markers
or comparing provider identity keys. External identity keys are provider,
issuer, and external subject only; alternate claims must not stand in for that
key.
Provider admission decisions should go through
`Identity.External_Providers.Trust.Evaluate_Admission`. The decision records
whether replay has already been registered, whether an active explicit binding
exists, whether policy-controlled JIT is available, and rejects suspended or
retired providers, invalid policy snapshots, and email-only matches before
local principal admission.
Use `Identity.External_Providers.Trust.Admitted`, `Binding_Required`,
`JIT_Provisioning_Allowed`, `Local_Approval_Required`, and `Rejected` before
branching on provider admission results in adapters or operation projections.
Use `Trusted_Status`, `Untrusted_Status`, `Suspended_Status`,
`Provider_Rejected`, `Provider_State_Rejected`,
`Untrusted_Provider_Rejected`, `Suspended_Provider_Rejected`,
`Retired_Provider_Rejected`, `Replay_Rejected`, `Email_Auto_Link_Rejected`,
and `Policy_Rejected` when selecting internal causes or disclosure-safe
projections.
External provider policy snapshots should use
`Identity.External_Providers.Policies.Validate`, `Validation_Accepted`,
`Trust_Rejected`, `Replay_Rejected`, `Email_Link_Rejected`, and
`JIT_Rejected` before provider admission. `Valid` remains the Boolean
compatibility wrapper over the structured classifier.
Provider adapters should use
`Identity.External_Providers.Definitions.Admission`, `Admission_Accepted`,
`Admission_Rejected`, `Suspended_Rejection`, `Retired_Rejection`, `Is_Active`,
`Can_Authenticate`, `JIT_Allowed`, `Local_Approval_Required`, and
`Can_Use_Policy_Controlled_JIT` instead of open-coding provider lifecycle or
JIT-mode checks.

Public policy records use `Identity.Times.Durations` semantic wrappers for
security-sensitive lifetimes and timeouts. Convert through `To_Base` only at
time-arithmetic boundaries that require `Identity.Times.Duration_Seconds`.
Use `Identity.Times.Expirations.After` for lifetime-derived expiration
boundaries; it returns an explicit overflow status and never fabricates a
present expiration from a sentinel timestamp. Classify the result with
`Construction_Succeeded`, `Overflow_Rejected`, and `Present_Expiration`
before storing or projecting lifetime-derived expiration boundaries.
Use `Identity.Passwords.Policies.Accepts_Length` for password acceptance length
admission. It accepts only a byte count and returns a stable status, so
diagnostics and public results never receive password text. Branch on
`Length_Accepted_Input`, `Length_Rejected`, `Minimum_Length_Rejected`,
`Maximum_Length_Rejected`, and `Policy_Rejected` rather than matching enum
literals in adapters. Validate password policy snapshots with
`Identity.Passwords.Policies.Validate`, `Validation_Accepted`,
`Acceptance_Length_Rejected`, and `Verifier_Length_Rejected`; validate history
policy snapshots with `Identity.Passwords.History.Validate`,
`Validation_Accepted`, and `Verification_Budget_Rejected`. `Valid` remains the
Boolean compatibility projection.

`Identity.Policies.Snapshots.Policy_Snapshot` aggregates the public policy
family records used by V1 operations. Snapshot validation must reject both
values above hard implementation limits and embedded public policy records whose
own `Valid` contract fails. Password acceptance, password hashing, and password
history failures use the specific finding codes
`Invalid_Password_Acceptance_Policy`, `Invalid_Password_Hashing_Policy`, and
`Invalid_Password_History_Policy`; reset authority failures use
`Invalid_Password_Reset_Policy`. Attempts-family failures use
`Invalid_Attempt_Policy`, `Invalid_Throttling_Policy`, and
`Invalid_Lockout_Policy`. MFA and OTP failures use `Invalid_MFA_Policy` and
`Invalid_TOTP_Policy`. Continuity and authority-token failures use
`Invalid_Session_Policy`, `Invalid_Token_Policy`, and
`Invalid_Verification_Policy`. Recovery, service credential, federation, event,
and audit failures use `Invalid_Recovery_Policy`,
`Invalid_Recovery_Code_Policy`, `Invalid_API_Key_Policy`,
`Invalid_External_Provider_Policy`, `Invalid_Event_Policy`, and
`Invalid_Audit_Policy`.

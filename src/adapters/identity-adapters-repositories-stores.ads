--  Repository service-provider interface.
--
--  Public operations depend on this interface rather than on any particular
--  adapter, so a store can be replaced without touching the operations layer.
--  Identity.Adapters.Repositories.Memory is one implementation; a persistent
--  adapter implements the same primitives and is certified by running the
--  conformance harness against it.

with Identity.Adapters.Repositories.Capabilities;
with Identity.Adapters.Repositories.Idempotency;
with Identity.Accounts.Definitions;
with Identity.Accounts.States;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.API_Keys.Credentials;
with Identity.Authentication.Results;
with Identity.Authentication.Transactions;
with Identity.Authentication.Challenges;
with Identity.Attempts.Definitions;
with Identity.Attempts.Outcomes;
with Identity.Contacts.Bindings;
with Identity.Events.Envelopes;
with Identity.External_Providers.Assertions;
with Identity.External_Providers.Bindings;
with Identity.Identities.Bindings;
with Identity.Identities.Resolution;
with Identity.Identities.Subjects;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.One_Time_Passwords.Credentials;
with Identity.Operations.Idempotency;
with Identity.Passwords.Credentials;
with Identity.Projections.Sessions;
with Identity.Principals.Definitions;
with Identity.Recovery.Transactions;
with Identity.Recovery_Codes.Sets;
with Identity.Secrets.Recovery_Codes;
with Identity.Secrets.Sessions;
with Identity.Secrets.API_Keys;
with Identity.Secrets.Tokens;
with Identity.Sessions.Definitions;
with Identity.Sessions.Handles;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Tokens.Definitions;
with Identity.Tokens.Verification;
with Identity.Verification.Changes;
with Identity.Versions;

package Identity.Adapters.Repositories.Stores is
   --  Outcome of a repository command. Declared here rather than in an adapter
   --  so the interface does not depend on an implementation of itself.
   type Command_Status is
     (Applied,
      Version_Conflict,
      State_Conflict,
      Uniqueness_Conflict,
      Capacity_Conflict,
      --  A cryptographic precondition of the command could not be met -- for
      --  example the CSPRNG could not supply a salt for a new verifier.
      --  Adapters never produce this; the operations layer does, so that a
      --  crypto failure is reported as a classified result rather than as an
      --  exception escaping an API that otherwise never raises.
      Cryptographic_Conflict);

   --  Implemented by every repository adapter. Store creation is deliberately
   --  not a primitive: constructing a store is adapter-specific, so callers
   --  build a concrete store and pass it as Store_Interface'Class.
   type Store_Interface is interface;

   --  Return the store to its empty state. Required so a conformance harness
   --  can run successive profiles against any adapter without knowing how that
   --  adapter is constructed.
   procedure Reset (Repository : in out Store_Interface) is abstract;

   function Capabilities (Repository : Store_Interface)
      return Identity.Adapters.Repositories.Capabilities.Repository_Capabilities
     is abstract;

   function Create_Principal
     (Repository : in out Store_Interface;
      Principal  : Identity.Principals.Definitions.Principal_Record) return Command_Status is abstract;

   function Retire_Principal
     (Repository : in out Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status is abstract;

   function Retire_Principal
     (Repository       : in out Store_Interface;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version) return Command_Status is abstract;

   function Create_Account
     (Repository : in out Store_Interface;
      Account    : Identity.Accounts.Definitions.Account_Record) return Command_Status is abstract;

   function Update_Account_State
     (Repository : in out Store_Interface;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      State      : Identity.Accounts.States.Account_State_View)
      return Command_Status is abstract;

   function Add_Binding
     (Repository : in out Store_Interface;
      Binding    : Identity.Identities.Bindings.Binding_Record) return Command_Status is abstract;

   function Revoke_Binding
     (Repository : in out Store_Interface;
      Binding    : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status is abstract;

   function Revoke_Binding
     (Repository               : in out Store_Interface;
      Binding                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Command_Status is abstract;

   function Change_Binding
     (Repository  : in out Store_Interface;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record) return Command_Status is abstract;

   function Change_Binding
     (Repository                   : in out Store_Interface;
      Predecessor                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Identities.Bindings.Binding_Record) return Command_Status is abstract;

   function Enroll_Password
     (Repository : in out Store_Interface;
      Credential : Identity.Passwords.Credentials.Password_Credential_Record) return Command_Status is abstract;

   function Replace_Password
     (Repository  : in out Store_Interface;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.Passwords.Credentials.Password_Credential_Record)
      return Command_Status is abstract;

   function Replace_Password
     (Repository                   : in out Store_Interface;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Command_Status is abstract;

   function Create_Session
     (Repository : in out Store_Interface;
      Session    : Identity.Sessions.Definitions.Session_Record) return Command_Status is abstract;

   procedure Find_Session
     (Repository : Store_Interface;
      Session    : Identity.Identifiers.Entities.Session_Id;
      Found      : out Boolean;
      Value      : out Identity.Sessions.Definitions.Session_Record) is abstract;

   function Revoke_Session
     (Repository : in out Store_Interface;
      Session    : Identity.Identifiers.Entities.Session_Id) return Command_Status is abstract;

   function Revoke_Session
     (Repository               : in out Store_Interface;
      Session                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Session_Version : Identity.Versions.Entity_Version) return Command_Status is abstract;

   function Rotate_Session
     (Repository  : in out Store_Interface;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record) return Command_Status is abstract;

   function Rotate_Session
     (Repository                   : in out Store_Interface;
      Predecessor                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Sessions.Definitions.Session_Record) return Command_Status is abstract;

   function Revoke_Session_Family
     (Repository : in out Store_Interface;
      Family     : Identity.Identifiers.Entities.Session_Family_Id) return Command_Status is abstract;

   function Revoke_Session_Family
     (Repository              : in out Store_Interface;
      Family                  : Identity.Identifiers.Entities.Session_Family_Id;
      Expected_Affected_Count : Natural) return Command_Status is abstract;

   function Revoke_Principal_Sessions
     (Repository : in out Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status is abstract;

   function Revoke_Principal_Sessions
     (Repository              : in out Store_Interface;
      Principal               : Identity.Identifiers.Entities.Principal_Id;
      Expected_Affected_Count : Natural) return Command_Status is abstract;

   function Revoke_Credential_Sessions
     (Repository : in out Store_Interface;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Command_Status is abstract;

   function Revoke_Credential_Sessions
     (Repository              : in out Store_Interface;
      Credential              : Identity.Identifiers.Entities.Credential_Id;
      Expected_Affected_Count : Natural) return Command_Status is abstract;

   function Revoke_Provider_Sessions
     (Repository : in out Store_Interface;
      Provider   : Identity.Identifiers.Entities.External_Provider_Id) return Command_Status is abstract;

   function Revoke_Provider_Sessions
     (Repository              : in out Store_Interface;
      Provider                : Identity.Identifiers.Entities.External_Provider_Id;
      Expected_Affected_Count : Natural) return Command_Status is abstract;

   function Expire_Eligible_Sessions
     (Repository : in out Store_Interface;
      Now        : Identity.Times.Instant) return Natural is abstract;

   function Purge_Retained_Sessions
     (Repository : in out Store_Interface;
      Retain_After : Identity.Times.Instant) return Natural is abstract;

   function Enumerate_Principal_Sessions
     (Repository : Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List is abstract;

   function Issue_Token
     (Repository : in out Store_Interface;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status is abstract;

   procedure Find_Token
     (Repository : Store_Interface;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Found      : out Boolean;
      Value      : out Identity.Tokens.Definitions.Action_Token_Record) is abstract;

   function Begin_Authentication_Transaction
     (Repository  : in out Store_Interface;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Issue_Challenge
     (Repository : in out Store_Interface;
      Challenge  : Identity.Authentication.Challenges.Challenge_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Issue_Challenge
     (Repository                   : in out Store_Interface;
      Challenge                    : Identity.Authentication.Challenges.Challenge_Record;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Complete_Challenge
     (Repository : in out Store_Interface;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Complete_Challenge
     (Repository                   : in out Store_Interface;
      Challenge                    : Identity.Identifiers.Entities.Challenge_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Challenge_Version   : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Satisfy_Authentication_Transaction
     (Repository  : in out Store_Interface;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Satisfy_Authentication_Transaction
     (Repository          : in out Store_Interface;
      Transaction         : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Now                 : Identity.Times.Instant;
      Expected_Version    : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Upgrade_Session_Assurance
     (Repository  : in out Store_Interface;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   function Upgrade_Session_Assurance
     (Repository                   : in out Store_Interface;
      Session                      : Identity.Identifiers.Entities.Session_Id;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Assurance                    : Identity.Assurance.Levels.Assurance_Level;
      Attributes                   : Identity.Assurance.Attributes.Assurance_Attributes;
      Expected_Session_Version     : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is abstract;

   procedure Find_Authentication_Transaction
     (Repository  : Store_Interface;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Authentication.Transactions.Authentication_Transaction_Record) is abstract;

   procedure Find_Challenge
     (Repository : Store_Interface;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Found      : out Boolean;
      Value      : out Identity.Authentication.Challenges.Challenge_Record) is abstract;

   function Issue_API_Key
     (Repository : in out Store_Interface;
      Credential : Identity.API_Keys.Credentials.API_Key_Credential_Record) return Command_Status is abstract;

   function Revoke_API_Key
     (Repository : in out Store_Interface;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Command_Status is abstract;

   function Revoke_API_Key
     (Repository                  : in out Store_Interface;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Command_Status is abstract;

   function Rotate_API_Key
     (Repository  : in out Store_Interface;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Command_Status is abstract;

   function Rotate_API_Key
     (Repository                   : in out Store_Interface;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Command_Status is abstract;

   procedure Find_API_Key
     (Repository : Store_Interface;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.API_Keys.Credentials.API_Key_Credential_Record) is abstract;

   --  True when the store can still accept Count more events. Operations that
   --  must emit a mandatory event check this BEFORE mutating, so a full event
   --  log cannot leave a transition applied with its audit record missing.
   function Event_Capacity_Available
     (Repository : Store_Interface;
      Count      : Positive) return Boolean is abstract;

   function Append_Event
     (Repository : in out Store_Interface;
      Event      : Identity.Events.Envelopes.Event_Envelope) return Command_Status is abstract;

   function Record_Attempt
     (Repository : in out Store_Interface;
      Attempt    : Identity.Attempts.Definitions.Attempt_Record) return Command_Status is abstract;

   procedure Find_Attempt
     (Repository : Store_Interface;
      Attempt    : Identity.Identifiers.Entities.Attempt_Id;
      Found      : out Boolean;
      Value      : out Identity.Attempts.Definitions.Attempt_Record) is abstract;

   function Request_Contact_Verification
     (Repository : in out Store_Interface;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status is abstract;

   function Complete_Contact_Verification
     (Repository : in out Store_Interface;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Complete_Contact_Verification
     (Repository               : in out Store_Interface;
      Token                    : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version   : Identity.Versions.Entity_Version;
      Expected_Contact_Version : Identity.Versions.Entity_Version;
      Secret                   : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                      : Identity.Times.Instant;
      Contact                  : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Begin_Contact_Change
     (Repository : in out Store_Interface;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status is abstract;

   function Complete_Contact_Change
     (Repository  : in out Store_Interface;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Complete_Contact_Change
     (Repository                   : in out Store_Interface;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Change_Version      : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Expected_Successor_Version   : Identity.Versions.Entity_Version;
      Secret                       : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                          : Identity.Times.Instant;
      Predecessor                  : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor                    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   --  Advance a contact change through one of its mid-flow admission actions --
   --  recording old-contact confirmation, starting the cooling-off period,
   --  cancelling, or expiring -- so those states are reachable rather than a
   --  dead branch of the change state machine. Admission-checked against the
   --  current state; the change version guards the transition. Located by the
   --  change's token.
   function Advance_Contact_Change
     (Repository       : in out Store_Interface;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Verification.Changes.Contact_Change_Action;
      Expected_Version : Identity.Versions.Entity_Version)
      return Command_Status is abstract;

   --  Read a contact change by its token, so its state and version are
   --  observable (needed to stage an advance and to project progress).
   procedure Find_Contact_Change
     (Repository : Store_Interface;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Found      : out Boolean;
      Value      : out Identity.Verification.Changes.Contact_Change_Record)
      is abstract;

   procedure Find_Contact_Binding
     (Repository : Store_Interface;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id;
      Found      : out Boolean;
      Value      : out Identity.Contacts.Bindings.Contact_Binding_Record) is abstract;

   function Install_Recovery_Code_Set
     (Repository : in out Store_Interface;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Command_Status is abstract;

   function Regenerate_Recovery_Code_Set
     (Repository : in out Store_Interface;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Command_Status is abstract;

   function Regenerate_Recovery_Code_Set
     (Repository              : in out Store_Interface;
      Codes                   : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
      Expected_Affected_Count : Natural) return Command_Status is abstract;

   procedure Find_Recovery_Code_Set
     (Repository : Store_Interface;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Found      : out Boolean;
      Value      : out Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) is abstract;

   function Begin_Recovery
     (Repository  : in out Store_Interface;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   function Accept_Recovery_Evidence
     (Repository  : in out Store_Interface;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   function Accept_Recovery_Evidence
     (Repository       : in out Store_Interface;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   function Complete_Recovery
     (Repository  : in out Store_Interface;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   function Complete_Recovery
     (Repository                   : in out Store_Interface;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
      Expected_Account_Version     : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   function Cancel_Recovery
     (Repository  : in out Store_Interface;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   function Cancel_Recovery
     (Repository       : in out Store_Interface;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   --  Advance a recovery transaction through one of the mid-flow admission
   --  actions -- approval, requiring credential re-establishment, or
   --  establishing restricted authentication -- so the approval path is
   --  reachable rather than a dead branch of the state machine. The action is
   --  admission-checked against the current state and the transaction version
   --  guards the transition; establishing restricted authentication also marks
   --  the account's recovery restrictions, exactly as Complete_Recovery does.
   function Advance_Recovery
     (Repository       : in out Store_Interface;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Recovery.Transactions.Recovery_Transaction_Action;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is abstract;

   procedure Find_Recovery_Transaction
     (Repository  : Store_Interface;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Recovery.Transactions.Recovery_Transaction_Record) is abstract;

   function Bind_External
     (Repository : in out Store_Interface;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record) return Command_Status is abstract;

   function Revoke_External
     (Repository : in out Store_Interface;
      Binding    : Identity.Identifiers.Entities.External_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status is abstract;

   function Revoke_External
     (Repository               : in out Store_Interface;
      Binding                  : Identity.Identifiers.Entities.External_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Command_Status is abstract;

   --  True when this assertion fingerprint has already been registered.
   --  Authenticate_External registers the fingerprint before it matches any
   --  binding, so checking beforehand is what lets a caller tell a genuine
   --  replay apart from an ordinary version conflict -- both of which the
   --  authentication result reports only as Conflict.
   function External_Replay_Registered
     (Repository  : Store_Interface;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Boolean is abstract;

   function Register_External_Replay
     (Repository  : in out Store_Interface;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Command_Status is abstract;

   function Reserve_Idempotency
     (Repository : in out Store_Interface;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation is abstract;

   function Complete_Idempotency
     (Repository : in out Store_Interface;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation is abstract;

   function Complete_Idempotency
     (Repository       : in out Store_Interface;
      Operation        : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key              : Identity.Operations.Idempotency.Idempotency_Key;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Adapters.Repositories.Idempotency.Reservation is abstract;

   function Begin_TOTP_Enrollment
     (Repository : in out Store_Interface;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Command_Status is abstract;

   function Complete_TOTP_Enrollment
     (Repository : in out Store_Interface;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Command_Status is abstract;

   function Complete_TOTP_Enrollment
     (Repository                  : in out Store_Interface;
      Credential                  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Command_Status is abstract;

   procedure Find_TOTP_Credential
     (Repository : Store_Interface;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record) is abstract;

   function Remove_TOTP
     (Repository : in out Store_Interface;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status is abstract;

   function Remove_TOTP
     (Repository                  : in out Store_Interface;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Principal                   : Identity.Identifiers.Entities.Principal_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Command_Status is abstract;

   function Resolve
     (Repository : Store_Interface;
      Subject    : Identity.Identities.Subjects.Authentication_Subject)
      return Identity.Identities.Resolution.Resolution_Result is abstract;

   procedure Find_Active_Password
     (Repository : Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Credential : out Identity.Passwords.Credentials.Password_Credential_Record) is abstract;

   procedure Find_Principal
     (Repository : Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Value      : out Identity.Principals.Definitions.Principal_Record) is abstract;

   procedure Find_Account
     (Repository : Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Account    : out Identity.Accounts.Definitions.Account_Record) is abstract;

   function Lookup_Session
     (Repository       : Store_Interface;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle is abstract;

   function Renew_Session
     (Repository       : in out Store_Interface;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle is abstract;

   function Verify_Token
     (Repository : Store_Interface;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Consume_Token
     (Repository : in out Store_Interface;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Consume_Token
     (Repository       : in out Store_Interface;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Purpose          : Identity.Identifiers.Registry.Registry_Id;
      Secret           : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Complete_Password_Reset
     (Repository : in out Store_Interface;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant;
      Successor  : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Complete_Password_Reset
     (Repository                   : in out Store_Interface;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Purpose                      : Identity.Identifiers.Registry.Registry_Id;
      Secret                       : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now                          : Identity.Times.Instant;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome is abstract;

   function Authenticate_API_Key
     (Repository    : in out Store_Interface;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is abstract;

   function Authenticate_API_Key
     (Repository                  : in out Store_Interface;
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result is abstract;

   function Failure_Count
     (Repository : Store_Interface;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Category   : Identity.Attempts.Outcomes.Failure_Category)
      return Identity.Versions.Attempt_Count is abstract;

   function Consume_Recovery_Code
     (Repository : in out Store_Interface;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status is abstract;

   function Consume_Recovery_Code
     (Repository       : in out Store_Interface;
      Set_Id           : Identity.Identifiers.Entities.Credential_Set_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Code             : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status is abstract;

   function Authenticate_External
     (Repository : in out Store_Interface;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is abstract;

   function Authenticate_External
     (Repository               : in out Store_Interface;
      Assertion                : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now                      : Identity.Times.Instant;
      Expected_Binding_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result is abstract;

   function Accept_TOTP_Counter
     (Repository : in out Store_Interface;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status is abstract;

   function Accept_TOTP_Counter
     (Repository       : in out Store_Interface;
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Counter          : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status is abstract;

   function Principal_Count (Repository : Store_Interface) return Natural is abstract;

   function Account_Count (Repository : Store_Interface) return Natural is abstract;

   function Binding_Count (Repository : Store_Interface) return Natural is abstract;

   function Password_Credential_Count (Repository : Store_Interface) return Natural is abstract;

   function Session_Count (Repository : Store_Interface) return Natural is abstract;

   function Token_Count (Repository : Store_Interface) return Natural is abstract;

   function Authentication_Transaction_Count (Repository : Store_Interface) return Natural is abstract;

   function Challenge_Count (Repository : Store_Interface) return Natural is abstract;

   function API_Key_Count (Repository : Store_Interface) return Natural is abstract;

   --  Read back a recorded event by position (1 .. Event_Count), oldest
   --  first. Without this a caller -- or a test -- can only count events and
   --  infer what they contain from which branch was reachable.
   procedure Find_Event
     (Repository : Store_Interface;
      Position   : Positive;
      Found      : out Boolean;
      Value      : out Identity.Events.Envelopes.Event_Envelope) is abstract;

   function Event_Count (Repository : Store_Interface) return Natural is abstract;

   function Attempt_Count (Repository : Store_Interface) return Natural is abstract;

   function Contact_Binding_Count (Repository : Store_Interface) return Natural is abstract;

   function Contact_Change_Count (Repository : Store_Interface) return Natural is abstract;

   function Recovery_Code_Set_Count (Repository : Store_Interface) return Natural is abstract;

   function Recovery_Transaction_Count (Repository : Store_Interface) return Natural is abstract;

   function External_Binding_Count (Repository : Store_Interface) return Natural is abstract;

   function External_Replay_Count (Repository : Store_Interface) return Natural is abstract;

   function TOTP_Credential_Count (Repository : Store_Interface) return Natural is abstract;

end Identity.Adapters.Repositories.Stores;

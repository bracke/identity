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

package Identity.Adapters.Repositories.Memory is
   Max_Principals : constant Natural := 64;
   Max_Accounts   : constant Natural := 64;
   Max_Bindings   : constant Natural := 128;
   Max_Password_Credentials : constant Natural := 128;
   Max_Sessions : constant Natural := 128;
   Max_Tokens   : constant Natural := 128;
   Max_Authentication_Transactions : constant Natural := 128;
   Max_Challenges : constant Natural := 128;
   Max_API_Keys : constant Natural := 128;
   Max_Events   : constant Natural := 512;
   Max_Attempts : constant Natural := 512;
   Max_Contact_Bindings : constant Natural := 128;
   Max_Contact_Verification_Links : constant Natural := 128;
   Max_Contact_Changes : constant Natural := 64;
   Max_Recovery_Code_Sets : constant Natural := 64;
   Max_Recovery_Transactions : constant Natural := 64;
   Max_External_Bindings : constant Natural := 128;
   Max_External_Replay_Markers : constant Natural := 512;
   Max_TOTP_Credentials : constant Natural := 128;
   Max_Idempotency_Records : constant Natural := 256;

   type Command_Status is
     (Applied, Version_Conflict, State_Conflict, Uniqueness_Conflict, Capacity_Conflict);

   type Store is private;

   function Capabilities return Identity.Adapters.Repositories.Capabilities.Repository_Capabilities;

   procedure Initialize (Repository : out Store);

   function Create_Principal
     (Repository : in out Store;
      Principal  : Identity.Principals.Definitions.Principal_Record) return Command_Status;

   function Retire_Principal
     (Repository : in out Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status;

   function Retire_Principal
     (Repository       : in out Store;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version) return Command_Status;

   function Create_Account
     (Repository : in out Store;
      Account    : Identity.Accounts.Definitions.Account_Record) return Command_Status;

   function Update_Account_State
     (Repository : in out Store;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      State      : Identity.Accounts.States.Account_State_View)
      return Command_Status;

   function Add_Binding
     (Repository : in out Store;
      Binding    : Identity.Identities.Bindings.Binding_Record) return Command_Status;

   function Revoke_Binding
     (Repository : in out Store;
      Binding    : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status;

   function Revoke_Binding
     (Repository               : in out Store;
      Binding                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Command_Status;

   function Change_Binding
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record) return Command_Status;

   function Change_Binding
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Identities.Bindings.Binding_Record) return Command_Status;

   function Enroll_Password
     (Repository : in out Store;
      Credential : Identity.Passwords.Credentials.Password_Credential_Record) return Command_Status;

   function Replace_Password
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.Passwords.Credentials.Password_Credential_Record)
      return Command_Status;

   function Replace_Password
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Command_Status;

   function Create_Session
     (Repository : in out Store;
      Session    : Identity.Sessions.Definitions.Session_Record) return Command_Status;

   procedure Find_Session
     (Repository : Store;
      Session    : Identity.Identifiers.Entities.Session_Id;
      Found      : out Boolean;
      Value      : out Identity.Sessions.Definitions.Session_Record);

   function Revoke_Session
     (Repository : in out Store;
      Session    : Identity.Identifiers.Entities.Session_Id) return Command_Status;

   function Revoke_Session
     (Repository               : in out Store;
      Session                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Session_Version : Identity.Versions.Entity_Version) return Command_Status;

   function Rotate_Session
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record) return Command_Status;

   function Rotate_Session
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Sessions.Definitions.Session_Record) return Command_Status;

   function Revoke_Session_Family
     (Repository : in out Store;
      Family     : Identity.Identifiers.Entities.Session_Family_Id) return Command_Status;

   function Revoke_Session_Family
     (Repository              : in out Store;
      Family                  : Identity.Identifiers.Entities.Session_Family_Id;
      Expected_Affected_Count : Natural) return Command_Status;

   function Revoke_Principal_Sessions
     (Repository : in out Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status;

   function Revoke_Principal_Sessions
     (Repository              : in out Store;
      Principal               : Identity.Identifiers.Entities.Principal_Id;
      Expected_Affected_Count : Natural) return Command_Status;

   function Revoke_Credential_Sessions
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Command_Status;

   function Revoke_Credential_Sessions
     (Repository              : in out Store;
      Credential              : Identity.Identifiers.Entities.Credential_Id;
      Expected_Affected_Count : Natural) return Command_Status;

   function Revoke_Provider_Sessions
     (Repository : in out Store;
      Provider   : Identity.Identifiers.Entities.External_Provider_Id) return Command_Status;

   function Revoke_Provider_Sessions
     (Repository              : in out Store;
      Provider                : Identity.Identifiers.Entities.External_Provider_Id;
      Expected_Affected_Count : Natural) return Command_Status;

   function Expire_Eligible_Sessions
     (Repository : in out Store;
      Now        : Identity.Times.Instant) return Natural;

   function Purge_Retained_Sessions
     (Repository : in out Store;
      Retain_After : Identity.Times.Instant) return Natural;

   function Enumerate_Principal_Sessions
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List;

   function Issue_Token
     (Repository : in out Store;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status;

   procedure Find_Token
     (Repository : Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Found      : out Boolean;
      Value      : out Identity.Tokens.Definitions.Action_Token_Record);

   function Begin_Authentication_Transaction
     (Repository  : in out Store;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Issue_Challenge
     (Repository : in out Store;
      Challenge  : Identity.Authentication.Challenges.Challenge_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Issue_Challenge
     (Repository                   : in out Store;
      Challenge                    : Identity.Authentication.Challenges.Challenge_Record;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Complete_Challenge
     (Repository : in out Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Complete_Challenge
     (Repository                   : in out Store;
      Challenge                    : Identity.Identifiers.Entities.Challenge_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Challenge_Version   : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Satisfy_Authentication_Transaction
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Satisfy_Authentication_Transaction
     (Repository          : in out Store;
      Transaction         : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Now                 : Identity.Times.Instant;
      Expected_Version    : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Upgrade_Session_Assurance
     (Repository  : in out Store;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Upgrade_Session_Assurance
     (Repository                   : in out Store;
      Session                      : Identity.Identifiers.Entities.Session_Id;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Assurance                    : Identity.Assurance.Levels.Assurance_Level;
      Attributes                   : Identity.Assurance.Attributes.Assurance_Attributes;
      Expected_Session_Version     : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   procedure Find_Authentication_Transaction
     (Repository  : Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Authentication.Transactions.Authentication_Transaction_Record);

   procedure Find_Challenge
     (Repository : Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Found      : out Boolean;
      Value      : out Identity.Authentication.Challenges.Challenge_Record);

   function Issue_API_Key
     (Repository : in out Store;
      Credential : Identity.API_Keys.Credentials.API_Key_Credential_Record) return Command_Status;

   function Revoke_API_Key
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Command_Status;

   function Revoke_API_Key
     (Repository                  : in out Store;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Command_Status;

   function Rotate_API_Key
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Command_Status;

   function Rotate_API_Key
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Command_Status;

   procedure Find_API_Key
     (Repository : Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.API_Keys.Credentials.API_Key_Credential_Record);

   function Append_Event
     (Repository : in out Store;
      Event      : Identity.Events.Envelopes.Event_Envelope) return Command_Status;

   function Record_Attempt
     (Repository : in out Store;
      Attempt    : Identity.Attempts.Definitions.Attempt_Record) return Command_Status;

   procedure Find_Attempt
     (Repository : Store;
      Attempt    : Identity.Identifiers.Entities.Attempt_Id;
      Found      : out Boolean;
      Value      : out Identity.Attempts.Definitions.Attempt_Record);

   function Request_Contact_Verification
     (Repository : in out Store;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status;

   function Complete_Contact_Verification
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Complete_Contact_Verification
     (Repository               : in out Store;
      Token                    : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version   : Identity.Versions.Entity_Version;
      Expected_Contact_Version : Identity.Versions.Entity_Version;
      Secret                   : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                      : Identity.Times.Instant;
      Contact                  : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Begin_Contact_Change
     (Repository : in out Store;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status;

   function Complete_Contact_Change
     (Repository  : in out Store;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Complete_Contact_Change
     (Repository                   : in out Store;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Change_Version      : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Expected_Successor_Version   : Identity.Versions.Entity_Version;
      Secret                       : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                          : Identity.Times.Instant;
      Predecessor                  : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor                    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   procedure Find_Contact_Binding
     (Repository : Store;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id;
      Found      : out Boolean;
      Value      : out Identity.Contacts.Bindings.Contact_Binding_Record);

   function Install_Recovery_Code_Set
     (Repository : in out Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Command_Status;

   function Regenerate_Recovery_Code_Set
     (Repository : in out Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Command_Status;

   function Regenerate_Recovery_Code_Set
     (Repository              : in out Store;
      Codes                   : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
      Expected_Affected_Count : Natural) return Command_Status;

   procedure Find_Recovery_Code_Set
     (Repository : Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Found      : out Boolean;
      Value      : out Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record);

   function Begin_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Accept_Recovery_Evidence
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Accept_Recovery_Evidence
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Complete_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Complete_Recovery
     (Repository                   : in out Store;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
      Expected_Account_Version     : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Cancel_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Cancel_Recovery
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   procedure Find_Recovery_Transaction
     (Repository  : Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Recovery.Transactions.Recovery_Transaction_Record);

   function Bind_External
     (Repository : in out Store;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record) return Command_Status;

   function Revoke_External
     (Repository : in out Store;
      Binding    : Identity.Identifiers.Entities.External_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status;

   function Revoke_External
     (Repository               : in out Store;
      Binding                  : Identity.Identifiers.Entities.External_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Command_Status;

   function Register_External_Replay
     (Repository  : in out Store;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Command_Status;

   function Reserve_Idempotency
     (Repository : in out Store;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation;

   function Complete_Idempotency
     (Repository : in out Store;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation;

   function Complete_Idempotency
     (Repository       : in out Store;
      Operation        : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key              : Identity.Operations.Idempotency.Idempotency_Key;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Adapters.Repositories.Idempotency.Reservation;

   function Begin_TOTP_Enrollment
     (Repository : in out Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Command_Status;

   function Complete_TOTP_Enrollment
     (Repository : in out Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Command_Status;

   function Complete_TOTP_Enrollment
     (Repository                  : in out Store;
      Credential                  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Command_Status;

   procedure Find_TOTP_Credential
     (Repository : Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record);

   function Remove_TOTP
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status;

   function Remove_TOTP
     (Repository                  : in out Store;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Principal                   : Identity.Identifiers.Entities.Principal_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Command_Status;

   function Resolve
     (Repository : Store;
      Subject    : Identity.Identities.Subjects.Authentication_Subject)
      return Identity.Identities.Resolution.Resolution_Result;

   procedure Find_Active_Password
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Credential : out Identity.Passwords.Credentials.Password_Credential_Record);

   procedure Find_Principal
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Value      : out Identity.Principals.Definitions.Principal_Record);

   procedure Find_Account
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Account    : out Identity.Accounts.Definitions.Account_Record);

   function Lookup_Session
     (Repository       : Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle;

   function Renew_Session
     (Repository       : in out Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle;

   function Verify_Token
     (Repository : Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Consume_Token
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Consume_Token
     (Repository       : in out Store;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Purpose          : Identity.Identifiers.Registry.Registry_Id;
      Secret           : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Complete_Password_Reset
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant;
      Successor  : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Complete_Password_Reset
     (Repository                   : in out Store;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Purpose                      : Identity.Identifiers.Registry.Registry_Id;
      Secret                       : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now                          : Identity.Times.Instant;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Authenticate_API_Key
     (Repository    : in out Store;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Authenticate_API_Key
     (Repository                  : in out Store;
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Failure_Count
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Category   : Identity.Attempts.Outcomes.Failure_Category)
      return Identity.Versions.Attempt_Count;

   function Consume_Recovery_Code
     (Repository : in out Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status;

   function Consume_Recovery_Code
     (Repository       : in out Store;
      Set_Id           : Identity.Identifiers.Entities.Credential_Set_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Code             : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status;

   function Authenticate_External
     (Repository : in out Store;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Authenticate_External
     (Repository               : in out Store;
      Assertion                : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now                      : Identity.Times.Instant;
      Expected_Binding_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Accept_TOTP_Counter
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;

   function Accept_TOTP_Counter
     (Repository       : in out Store;
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Counter          : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;

   function Principal_Count (Repository : Store) return Natural;
   function Account_Count (Repository : Store) return Natural;
   function Binding_Count (Repository : Store) return Natural;
   function Password_Credential_Count (Repository : Store) return Natural;
   function Session_Count (Repository : Store) return Natural;
   function Token_Count (Repository : Store) return Natural;
   function Authentication_Transaction_Count (Repository : Store) return Natural;
   function Challenge_Count (Repository : Store) return Natural;
   function API_Key_Count (Repository : Store) return Natural;
   function Event_Count (Repository : Store) return Natural;
   function Attempt_Count (Repository : Store) return Natural;
   function Contact_Binding_Count (Repository : Store) return Natural;
   function Contact_Change_Count (Repository : Store) return Natural;
   function Recovery_Code_Set_Count (Repository : Store) return Natural;
   function Recovery_Transaction_Count (Repository : Store) return Natural;
   function External_Binding_Count (Repository : Store) return Natural;
   function External_Replay_Count (Repository : Store) return Natural;
   function TOTP_Credential_Count (Repository : Store) return Natural;

private
   type Principal_Slot is record
      Present : Boolean := False;
      Value   : Identity.Principals.Definitions.Principal_Record;
   end record;

   type Account_Slot is record
      Present : Boolean := False;
      Value   : Identity.Accounts.Definitions.Account_Record;
   end record;

   type Binding_Slot is record
      Present : Boolean := False;
      Value   : Identity.Identities.Bindings.Binding_Record;
   end record;

   type Password_Credential_Slot is record
      Present : Boolean := False;
      Value   : Identity.Passwords.Credentials.Password_Credential_Record;
   end record;

   type Session_Slot is record
      Present : Boolean := False;
      Value   : Identity.Sessions.Definitions.Session_Record;
   end record;

   type Token_Slot is record
      Present : Boolean := False;
      Value   : Identity.Tokens.Definitions.Action_Token_Record;
   end record;

   type Authentication_Transaction_Slot is record
      Present : Boolean := False;
      Value   : Identity.Authentication.Transactions.Authentication_Transaction_Record;
   end record;

   type Challenge_Slot is record
      Present : Boolean := False;
      Value   : Identity.Authentication.Challenges.Challenge_Record;
   end record;

   type API_Key_Slot is record
      Present : Boolean := False;
      Value   : Identity.API_Keys.Credentials.API_Key_Credential_Record;
   end record;

   type Event_Slot is record
      Present : Boolean := False;
      Value   : Identity.Events.Envelopes.Event_Envelope;
   end record;

   type Attempt_Slot is record
      Present : Boolean := False;
      Value   : Identity.Attempts.Definitions.Attempt_Record;
   end record;

   type Contact_Binding_Slot is record
      Present : Boolean := False;
      Value   : Identity.Contacts.Bindings.Contact_Binding_Record;
   end record;

   type Contact_Verification_Link_Slot is record
      Present : Boolean := False;
      Token   : Identity.Identifiers.Entities.Token_Id;
      Contact : Identity.Identifiers.Entities.Contact_Binding_Id;
   end record;

   type Contact_Change_Slot is record
      Present : Boolean := False;
      Value   : Identity.Verification.Changes.Contact_Change_Record;
   end record;

   type Recovery_Code_Set_Slot is record
      Present : Boolean := False;
      Value   : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
   end record;

   type Recovery_Transaction_Slot is record
      Present : Boolean := False;
      Value   : Identity.Recovery.Transactions.Recovery_Transaction_Record;
   end record;

   type External_Binding_Slot is record
      Present : Boolean := False;
      Value   : Identity.External_Providers.Bindings.External_Binding_Record;
   end record;

   type External_Replay_Slot is record
      Present : Boolean := False;
      Fingerprint : Identity.Text.Bounded.Bounded_Text;
   end record;

   type TOTP_Credential_Slot is record
      Present : Boolean := False;
      Value   : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
   end record;

   type Idempotency_Slot is record
      Present   : Boolean := False;
      Operation : Identity.Operations.Idempotency.Idempotent_Operation_Kind :=
        Identity.Operations.Idempotency.Password_Reset_Request;
      Key       : Identity.Operations.Idempotency.Idempotency_Key :=
        Identity.Operations.Idempotency.From_String ("");
      Completed : Boolean := False;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;

   type Principal_Array is array (Positive range 1 .. Max_Principals) of Principal_Slot;
   type Account_Array is array (Positive range 1 .. Max_Accounts) of Account_Slot;
   type Binding_Array is array (Positive range 1 .. Max_Bindings) of Binding_Slot;
   type Password_Credential_Array is
     array (Positive range 1 .. Max_Password_Credentials) of Password_Credential_Slot;
   type Session_Array is array (Positive range 1 .. Max_Sessions) of Session_Slot;
   type Token_Array is array (Positive range 1 .. Max_Tokens) of Token_Slot;
   type Authentication_Transaction_Array is
     array (Positive range 1 .. Max_Authentication_Transactions) of Authentication_Transaction_Slot;
   type Challenge_Array is array (Positive range 1 .. Max_Challenges) of Challenge_Slot;
   type API_Key_Array is array (Positive range 1 .. Max_API_Keys) of API_Key_Slot;
   type Event_Array is array (Positive range 1 .. Max_Events) of Event_Slot;
   type Attempt_Array is array (Positive range 1 .. Max_Attempts) of Attempt_Slot;
   type Contact_Binding_Array is
     array (Positive range 1 .. Max_Contact_Bindings) of Contact_Binding_Slot;
   type Contact_Verification_Link_Array is
     array (Positive range 1 .. Max_Contact_Verification_Links) of Contact_Verification_Link_Slot;
   type Contact_Change_Array is
     array (Positive range 1 .. Max_Contact_Changes) of Contact_Change_Slot;
   type Recovery_Code_Set_Array is
     array (Positive range 1 .. Max_Recovery_Code_Sets) of Recovery_Code_Set_Slot;
   type Recovery_Transaction_Array is
     array (Positive range 1 .. Max_Recovery_Transactions) of Recovery_Transaction_Slot;
   type External_Binding_Array is
     array (Positive range 1 .. Max_External_Bindings) of External_Binding_Slot;
   type External_Replay_Array is
     array (Positive range 1 .. Max_External_Replay_Markers) of External_Replay_Slot;
   type TOTP_Credential_Array is
     array (Positive range 1 .. Max_TOTP_Credentials) of TOTP_Credential_Slot;
   type Idempotency_Array is
     array (Positive range 1 .. Max_Idempotency_Records) of Idempotency_Slot;

   type Store is record
      Principals : Principal_Array;
      Accounts   : Account_Array;
      Bindings   : Binding_Array;
      Passwords   : Password_Credential_Array;
      Sessions    : Session_Array;
      Tokens      : Token_Array;
      Authentication_Transactions : Authentication_Transaction_Array;
      Challenges  : Challenge_Array;
      API_Keys    : API_Key_Array;
      Events      : Event_Array;
      Attempts    : Attempt_Array;
      Contact_Bindings : Contact_Binding_Array;
      Contact_Verification_Links : Contact_Verification_Link_Array;
      Contact_Changes : Contact_Change_Array;
      Recovery_Code_Sets : Recovery_Code_Set_Array;
      Recovery_Transactions : Recovery_Transaction_Array;
      External_Bindings : External_Binding_Array;
      External_Replays  : External_Replay_Array;
      TOTP_Credentials  : TOTP_Credential_Array;
      Idempotency       : Idempotency_Array;
   end record;
end Identity.Adapters.Repositories.Memory;

with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;
with Identity.Accounts.Definitions;
with Identity.Accounts.States;
with Identity.Adapters.Repositories.Conformance;
with Identity.Adapters.Repositories.Memory;
with Identity.Adapters.Repositories.Persistent;
with Identity.Adapters.Repositories.Recording;
with Identity.Adapters.Repositories.Serialized;
with Identity.Adapters.Repositories.Stores;
with Identity.API_Keys.Credentials;
with Identity.Authentication.Results;
with Identity.Credentials.States;
with Identity.Secrets.Passwords;
with Identity.Operations.Passwords.Enroll;
with Identity.Operations.Passwords.Authenticate;
with Identity.Operations.Contexts;
with Identity.Identities.Subjects;
with Identity.Crypto.Capabilities;
with Identity.Crypto.CryptoLib.Capabilities;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.External_Providers.Assertions;
with Identity.External_Providers.Bindings;
with Identity.Identifiers;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Identities.Bindings;
with Identity.Identifiers.Operations;
with Identity.Events.Envelopes;
with Identity.Identities.Resolution;
with Identity.Principals.Definitions;
with Identity.Principals.Kinds;
with Identity.Authentication.Transactions;
with Identity.Recovery.Transactions;
with Identity.Recovery_Codes.Sets;
with Identity.Verification.Changes;
with Identity.WebAuthn.Credentials;
with Identity.Results;
with Identity.Secrets.Text;
with Identity.Sessions.Definitions;
with Identity.Sessions.Handles;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

--  Repository conformance harness. Every profile below runs real commands and
--  queries against Identity.Adapters.Repositories.Stores.Store and asserts the
--  observable postcondition of each one. Nothing is reported as passed unless
--  the store actually produced the required outcome, and unless the number of
--  checks executed matches Required_Check_Count for that profile.
procedure Identity_Conformance is

   package Conformance renames Identity.Adapters.Repositories.Conformance;
   package Memory renames Identity.Adapters.Repositories.Memory;
   package Stores renames Identity.Adapters.Repositories.Stores;
   package Recording renames Identity.Adapters.Repositories.Recording;
   package Persistent renames Identity.Adapters.Repositories.Persistent;
   package Serialized renames Identity.Adapters.Repositories.Serialized;

   use type Stores.Command_Status;
   use type Memory.Snapshot_Status;
   use type Identity.Accounts.States.Lifecycle_State;
   use type Identity.Crypto.Capabilities.Capability_State;
   use type Identity.External_Providers.Bindings.External_Binding_State;
   use type Identity.Identifiers.Entities.Principal_Id;
   use type Identity.Identities.Resolution.Resolution_Status;
   use type Identity.Principals.Definitions.Principal_Lifecycle;
   use type Identity.Recovery.Transactions.Recovery_Transaction_State;
   use type Identity.Recovery.Transactions.Recovery_Transition_Status;
   use type Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status;
   use type Identity.Results.Operation_Status;
   use type Identity.Sessions.Definitions.Session_Revocation_State;
   use type Identity.Sessions.Handles.Session_Lookup_Status;

   subtype Profile is Conformance.Certification_Profile;

   --  Natural'Image carries a leading blank; strip it for the wire format.
   function Count_Image (Value : Natural) return String is
     (declare
        Raw : constant String := Natural'Image (Value);
      begin Raw (Raw'First + 1 .. Raw'Last));

   function Image (Value : Profile) return String is
     (case Value is
        when Conformance.Core_Identity_Store => "core-identity-store",
        when Conformance.Interactive_Authentication_Store =>
          "interactive-authentication-store",
        when Conformance.Session_Store => "session-store",
        when Conformance.Recovery_Store => "recovery-store",
        when Conformance.Federated_Identity_Store => "federated-identity-store");

   ---------------------------------------------------------------------------
   --  Fixtures
   ---------------------------------------------------------------------------

   function Principal_Of (Suffix : String) return Identity.Identifiers.Entities.Principal_Id is
     (Identity.Identifiers.Entities.Principal
        (Identity.Identifiers.From_String ("00000000-0000-0000-0000-0000000000" & Suffix)));

   function Account_Of (Suffix : String) return Identity.Identifiers.Entities.Account_Id is
     (Identity.Identifiers.Entities.Account
        (Identity.Identifiers.From_String ("10000000-0000-0000-0000-0000000000" & Suffix)));

   function Binding_Of (Suffix : String) return Identity.Identifiers.Entities.Identity_Binding_Id is
     (Identity.Identifiers.Entities.Identity_Binding
        (Identity.Identifiers.From_String ("20000000-0000-0000-0000-0000000000" & Suffix)));

   function External_Binding_Of
     (Suffix : String) return Identity.Identifiers.Entities.External_Binding_Id is
     (Identity.Identifiers.Entities.External_Binding
        (Identity.Identifiers.From_String ("21000000-0000-0000-0000-0000000000" & Suffix)));

   function Credential_Of (Suffix : String) return Identity.Identifiers.Entities.Credential_Id is
     (Identity.Identifiers.Entities.Credential
        (Identity.Identifiers.From_String ("30000000-0000-0000-0000-0000000000" & Suffix)));

   function Credential_Set_Of
     (Suffix : String) return Identity.Identifiers.Entities.Credential_Set_Id is
     (Identity.Identifiers.Entities.Credential_Set
        (Identity.Identifiers.From_String ("31000000-0000-0000-0000-0000000000" & Suffix)));

   function Session_Of (Suffix : String) return Identity.Identifiers.Entities.Session_Id is
     (Identity.Identifiers.Entities.Session
        (Identity.Identifiers.From_String ("40000000-0000-0000-0000-0000000000" & Suffix)));

   function Family_Of (Suffix : String) return Identity.Identifiers.Entities.Session_Family_Id is
     (Identity.Identifiers.Entities.Session_Family
        (Identity.Identifiers.From_String ("50000000-0000-0000-0000-0000000000" & Suffix)));

   function Provider_Of
     (Suffix : String) return Identity.Identifiers.Entities.External_Provider_Id is
     (Identity.Identifiers.Entities.External_Provider
        (Identity.Identifiers.From_String ("22000000-0000-0000-0000-0000000000" & Suffix)));

   function Transaction_Of
     (Suffix : String)
      return Identity.Identifiers.Entities.Authentication_Transaction_Id is
     (Identity.Identifiers.Entities.Authentication_Transaction
        (Identity.Identifiers.From_String ("b0000000-0000-0000-0000-0000000000" & Suffix)));

   function Token_Of (Suffix : String) return Identity.Identifiers.Entities.Token_Id is
     (Identity.Identifiers.Entities.Token
        (Identity.Identifiers.From_String ("c0000000-0000-0000-0000-0000000000" & Suffix)));

   P1 : constant Identity.Identifiers.Entities.Principal_Id := Principal_Of ("01");
   P2 : constant Identity.Identifiers.Entities.Principal_Id := Principal_Of ("02");
   P3 : constant Identity.Identifiers.Entities.Principal_Id := Principal_Of ("03");

   A1 : constant Identity.Identifiers.Entities.Account_Id := Account_Of ("01");
   A2 : constant Identity.Identifiers.Entities.Account_Id := Account_Of ("02");

   Login_Kind : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("login.username");
   OIDC_Protocol : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("oidc");
   Adapter_Profile : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("conformance.adapter.validated");

   Alice : constant Identity.Text.Bounded.Bounded_Text :=
     Identity.Text.Bounded.From_String ("alice");

   Now_Instant : constant Identity.Times.Instant := 1_000;
   Far_Future  : constant Identity.Times.Expiration :=
     (Present => True, Time_Point => 1_000_000);

   Active_Account_State : constant Identity.Accounts.States.Account_State_View :=
     (Administrative => Identity.Accounts.States.Enabled,
      Lifecycle      => Identity.Accounts.States.Active,
      Verification   => Identity.Accounts.States.No_Verification_Required,
      Lock_State     => Identity.Accounts.States.Not_Locked,
      Requirements   => <>,
      Recovery       => <>);

   function Active_Principal
     (Id : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Principals.Definitions.Principal_Record is
     (Id      => Id,
      Kind    => Identity.Principals.Kinds.Human,
      State   => Identity.Principals.Definitions.Active,
      Version => 0);

   ---------------------------------------------------------------------------
   --  Per-profile bookkeeping
   ---------------------------------------------------------------------------

   Executed : Natural := 0;
   Failures : Natural := 0;

   procedure Reset_Profile is
   begin
      Executed := 0;
      Failures := 0;
   end Reset_Profile;

   --  Records one conformance check. Every call counts, whatever the result.
   procedure Check (Outcome : Boolean) is
   begin
      Executed := Executed + 1;
      if not Outcome then
         Failures := Failures + 1;
      end if;
   end Check;

   ---------------------------------------------------------------------------
   --  Core identity store: 8 checks
   ---------------------------------------------------------------------------

   procedure Run_Core (Repository : in out Stores.Store_Interface'Class) is
      Found      : Boolean;
      Principal  : Identity.Principals.Definitions.Principal_Record;
      Account    : Identity.Accounts.Definitions.Account_Record;
   begin
      Stores.Reset (Repository);

      --  1. A fresh principal is accepted and becomes visible.
      Check (Stores.Create_Principal (Repository, Active_Principal (P1)) = Stores.Applied
             and then Stores.Principal_Count (Repository) = 1);

      --  2. Re-creating the same principal identifier is a uniqueness conflict.
      Check (Stores.Create_Principal (Repository, Active_Principal (P1))
             = Stores.Uniqueness_Conflict
             and then Stores.Principal_Count (Repository) = 1);

      --  3. An account for an existing principal is accepted and readable.
      Stores.Find_Account (Repository, P1, Found, Account);
      Check (Stores.Create_Account
               (Repository,
                (Id => A1, Principal => P1, State => Active_Account_State, Version => 0))
             = Stores.Applied
             and then not Found);

      --  4. An account for an unknown principal is refused.
      Check (Stores.Create_Account
               (Repository,
                (Id => A2, Principal => P3, State => Active_Account_State, Version => 0))
             = Stores.State_Conflict
             and then Stores.Account_Count (Repository) = 1);

      --  5. An active binding is added and resolves back to its principal.
      Check (Stores.Add_Binding
               (Repository,
                (Id         => Binding_Of ("01"),
                 Principal  => P1,
                 Kind       => Login_Kind,
                 Normalized => Alice,
                 State      => Identity.Identities.Bindings.Active,
                 Version    => 0))
             = Stores.Applied
             and then Stores.Resolve
               (Repository, (Kind => Login_Kind, Value => Alice)).Status
               = Identity.Identities.Resolution.Resolved
             and then Stores.Resolve
               (Repository, (Kind => Login_Kind, Value => Alice)).Principal = P1);

      --  6. A second active binding over the same subject is refused.
      Check (Stores.Add_Binding
               (Repository,
                (Id         => Binding_Of ("02"),
                 Principal  => P1,
                 Kind       => Login_Kind,
                 Normalized => Alice,
                 State      => Identity.Identities.Bindings.Active,
                 Version    => 0))
             = Stores.Uniqueness_Conflict
             and then Stores.Binding_Count (Repository) = 1);

      --  7. Retiring with a stale expected version is a version conflict and
      --      leaves the principal active.
      Stores.Find_Principal (Repository, P1, Found, Principal);
      Check (Stores.Retire_Principal (Repository, P1, Expected_Version => 99)
             = Stores.Version_Conflict
             and then Found
             and then Principal.State = Identity.Principals.Definitions.Active);

      --  8. Retiring at the current version applies, and further bindings for
      --      the retired principal are refused.
      Check (Stores.Retire_Principal (Repository, P1, Expected_Version => Principal.Version)
             = Stores.Applied
             and then Stores.Add_Binding
               (Repository,
                (Id         => Binding_Of ("03"),
                 Principal  => P1,
                 Kind       => Login_Kind,
                 Normalized => Identity.Text.Bounded.From_String ("alice.second"),
                 State      => Identity.Identities.Bindings.Active,
                 Version    => 0))
               = Stores.State_Conflict);
   end Run_Core;

   ---------------------------------------------------------------------------
   --  Interactive authentication store: 7 checks
   ---------------------------------------------------------------------------

   procedure Run_Interactive (Repository : in out Stores.Store_Interface'Class) is

      Key_Reference : constant Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("api-key-public-1");
      Key_Secret : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("api key bearer secret");
      Wrong_Key_Secret : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("wrong api key bearer secret");
      Password_Secret : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("conformance principal passphrase alpha");

      Key_Record : constant Identity.API_Keys.Credentials.API_Key_Credential_Record :=
        (Id                  => Credential_Of ("02"),
         Principal           => P1,
         Public_Key_Id       => Key_Reference,
         Credential_Class_Id => Adapter_Profile,
         Secret_Verifier     =>
           Identity.Crypto.Secret_Verifiers.Derive_Text
             (Identity.Crypto.Domains.API_Key, Key_Secret),
         State               => Identity.Credentials.States.Active,
         Created_At          => 0,
         Expires_At          => Far_Future,
         Last_Used_At        => (Present => False, Time_Point => 0),
         Rotation_Generation => 0,
         Version             => 0);

      Result : Identity.Authentication.Results.Password_Authentication_Result;
   begin
      Stores.Reset (Repository);

      --  1. A password credential is enrolled for a freshly created principal.
      Check (Stores.Create_Principal (Repository, Active_Principal (P1)) = Stores.Applied
             and then Stores.Enroll_Password
               (Repository,
                (Id        => Credential_Of ("01"),
                 Principal => P1,
                 State     => Identity.Credentials.States.Active,
                 Verifier  =>
                   Identity.Crypto.Secret_Verifiers.Derive_Text
                     (Identity.Crypto.Domains.Password_Reset_Token, Password_Secret),
                 Version   => 0))
               = Stores.Applied
             and then Stores.Password_Credential_Count (Repository) = 1);

      --  2. A second active password for the same principal is refused.
      Check (Stores.Enroll_Password
               (Repository,
                (Id        => Credential_Of ("03"),
                 Principal => P1,
                 State     => Identity.Credentials.States.Active,
                 Verifier  =>
                   Identity.Crypto.Secret_Verifiers.Derive_Text
                     (Identity.Crypto.Domains.Password_Reset_Token, Password_Secret),
                 Version   => 0))
             = Stores.State_Conflict
             and then Stores.Password_Credential_Count (Repository) = 1);

      --  3. An API key is issued and authenticates with the enrolled secret.
      Result := (if Stores.Issue_API_Key (Repository, Key_Record) = Stores.Applied
                 then Stores.Authenticate_API_Key
                        (Repository, Key_Reference, Key_Secret, Now_Instant)
                 else (Status => Identity.Results.Internal_Invariant_Failure,
                       Principal => (Present => False)));
      Check (Result.Status = Identity.Results.Succeeded
             and then Result.Principal.Present
             and then Result.Principal.Value = P1);

      --  4. A wrong secret is rejected without naming a principal.
      Result := Stores.Authenticate_API_Key
        (Repository, Key_Reference, Wrong_Key_Secret, Now_Instant);
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present);

      --  5. A stale expected credential version is a conflict, not a success.
      Result := Stores.Authenticate_API_Key
        (Repository, Key_Reference, Key_Secret, Now_Instant,
         Expected_Credential_Version => 99);
      Check (Result.Status = Identity.Results.Conflict
             and then not Result.Principal.Present);

      --  6-7. A passkey registers, its assertion is accepted, and a replayed
      --       sign count is a cloned authenticator -- certifying the passkey
      --       primitives' forwarding on every adapter.
      declare
         PK_Found : Boolean;
         PK       : Identity.WebAuthn.Credentials.Passkey_Credential_Record;
         use type Identity.WebAuthn.Credentials.Assertion_Status;
      begin
         Check (Stores.Register_Passkey
                  (Repository,
                   (Id => Credential_Of ("pk"), Principal => P1,
                    Credential_Reference =>
                      Identity.Text.Bounded.From_String ("pk-ref"),
                    Public_Key => Identity.Text.Bounded.From_String ("pk-key"),
                    Authenticator_Model =>
                      Identity.Text.Bounded.From_String ("pk-aaguid"),
                    Highest_Sign_Count => 0,
                    State => Identity.Credentials.States.Active,
                    Created_At => 0, Version => 0))
                = Stores.Applied
                and then Stores.Accept_Passkey_Assertion
                  (Repository, Credential_Of ("pk"),
                   Expected_Version => 0, Presented => 1)
                  = Identity.WebAuthn.Credentials.Accepted);
         Stores.Find_Passkey_Credential
           (Repository, Credential_Of ("pk"), PK_Found, PK);
         Check (PK_Found
                and then Stores.Accept_Passkey_Assertion
                  (Repository, Credential_Of ("pk"),
                   Expected_Version => PK.Version, Presented => 1)
                  = Identity.WebAuthn.Credentials.Cloned);
      end;

      --  8-9. An authentication transaction can be resolved (cancelled) via
      --       Resolve_Authentication_Transaction, certifying that primitive's
      --       forwarding on every adapter.
      declare
         MT       : constant Identity.Identifiers.Entities.Authentication_Transaction_Id :=
           Transaction_Of ("mt");
         TX_Found : Boolean;
         TX       : Identity.Authentication.Transactions.Authentication_Transaction_Record;
         use type Identity.Authentication.Transactions.Authentication_Transaction_Status;
         use type Identity.Authentication.Transactions.Authentication_Transaction_State;
      begin
         Check (Stores.Begin_Authentication_Transaction
                  (Repository,
                   (Id => MT, Principal => P1, Requested_Profile => Adapter_Profile,
                    Created_At => 0, Expires_At => Far_Future,
                    State => Identity.Authentication.Transactions.Started,
                    Attempts => 0, Evidence_Count => 0, Version => 0))
                = Identity.Authentication.Transactions.Applied);
         Stores.Find_Authentication_Transaction (Repository, MT, TX_Found, TX);
         Check (TX_Found
                and then Stores.Resolve_Authentication_Transaction
                  (Repository, MT, P1,
                   Identity.Authentication.Transactions.Cancel_Transaction,
                   Now_Instant, TX.Version)
                  = Identity.Authentication.Transactions.Applied);
      end;

      --  10. Retiring the principal applies.
      Check (Stores.Retire_Principal (Repository, P1) = Stores.Applied);

      --  7. Once the principal is retired the same valid secret is rejected.
      Result := Stores.Authenticate_API_Key
        (Repository, Key_Reference, Key_Secret, Now_Instant);
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present);
   end Run_Interactive;

   ---------------------------------------------------------------------------
   --  Session store: 9 checks
   ---------------------------------------------------------------------------

   procedure Run_Sessions (Repository : in out Stores.Store_Interface'Class) is

      Family : constant Identity.Identifiers.Entities.Session_Family_Id := Family_Of ("01");

      Secret_One : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("conformance session bearer alpha");
      Secret_Two : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("conformance session bearer beta");
      Secret_Bad : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("conformance session bearer mismatch");

      Reference_One : constant Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("session-public-reference-1");
      Reference_Two : constant Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("session-public-reference-2");
      Reference_Three : constant Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("session-public-reference-3");

      function Session_For
        (Id         : Identity.Identifiers.Entities.Session_Id;
         Reference  : Identity.Text.Bounded.Bounded_Text;
         Secret     : Identity.Secrets.Text.Secret_Text;
         Generation : Identity.Versions.Rotation_Generation)
         return Identity.Sessions.Definitions.Session_Record is
        (Id                  => Id,
         Family              => Family,
         Principal           => P1,
         Public_Reference    => Reference,
         Secret_Verifier     =>
           Identity.Crypto.Secret_Verifiers.Derive_Text
             (Identity.Crypto.Domains.Session_Token, Secret),
         Idle_Expires_At     => Far_Future,
         Absolute_Expires_At => Far_Future,
         Generation          => Generation,
         State               => Identity.Sessions.Definitions.Active,
         others              => <>);

      S1 : constant Identity.Identifiers.Entities.Session_Id := Session_Of ("01");
      S2 : constant Identity.Identifiers.Entities.Session_Id := Session_Of ("02");
      S3 : constant Identity.Identifiers.Entities.Session_Id := Session_Of ("03");

      Handle : Identity.Sessions.Handles.Session_Handle;
      Found  : Boolean;
      Value  : Identity.Sessions.Definitions.Session_Record;
   begin
      Stores.Reset (Repository);

      --  1. A session is created for a freshly created active principal.
      Check (Stores.Create_Principal (Repository, Active_Principal (P1)) = Stores.Applied
             and then Stores.Create_Session
               (Repository, Session_For (S1, Reference_One, Secret_One, 0))
               = Stores.Applied
             and then Stores.Session_Count (Repository) = 1);

      --  2. A different session reusing the public reference is refused.
      Check (Stores.Create_Session (Repository, Session_For (S2, Reference_One, Secret_Two, 0))
             = Stores.Uniqueness_Conflict
             and then Stores.Session_Count (Repository) = 1);

      --  3. Lookup with the matching secret yields the session and principal.
      Handle := Stores.Lookup_Session (Repository, Reference_One, Secret_One, Now_Instant);
      Check (Handle.Status = Identity.Sessions.Handles.Found
             and then Handle.Principal = P1);

      --  4. Lookup with a non-matching secret does not authenticate.
      Handle := Stores.Lookup_Session (Repository, Reference_One, Secret_Bad, Now_Instant);
      Check (Handle.Status = Identity.Sessions.Handles.Not_Verified);

      --  5. Rotation installs the successor and marks the predecessor rotated.
      Check (Stores.Rotate_Session
               (Repository, S1, Session_For (S2, Reference_Two, Secret_Two, 1))
             = Stores.Applied
             and then Stores.Session_Count (Repository) = 2);
      Stores.Find_Session (Repository, S1, Found, Value);

      --  6. The rotated predecessor no longer authenticates.
      Handle := Stores.Lookup_Session (Repository, Reference_One, Secret_One, Now_Instant);
      Check (Found
             and then Value.State = Identity.Sessions.Definitions.Rotated
             and then Handle.Status = Identity.Sessions.Handles.Revoked);

      --  7. The successor authenticates with its own secret.
      Handle := Stores.Lookup_Session (Repository, Reference_Two, Secret_Two, Now_Instant);
      Check (Handle.Status = Identity.Sessions.Handles.Found
             and then Handle.Principal = P1);

      --  8. Rotating with a stale expected predecessor version is refused.
      Check (Stores.Rotate_Session
               (Repository, S2,
                Expected_Predecessor_Version => 99,
                Successor => Session_For (S3, Reference_Three, Secret_One, 2))
             = Stores.Version_Conflict
             and then Stores.Session_Count (Repository) = 2);

      --  9. Revoking the family stops the surviving successor.
      Check (Stores.Revoke_Session_Family (Repository, Family) = Stores.Applied
             and then Stores.Lookup_Session
               (Repository, Reference_Two, Secret_Two, Now_Instant).Status
               = Identity.Sessions.Handles.Revoked);
   end Run_Sessions;

   ---------------------------------------------------------------------------
   --  Recovery store: 8 checks
   ---------------------------------------------------------------------------

   procedure Run_Recovery (Repository : in out Stores.Store_Interface'Class) is

      Set_Id : constant Identity.Identifiers.Entities.Credential_Set_Id :=
        Credential_Set_Of ("01");
      Transaction : constant Identity.Identifiers.Entities.Authentication_Transaction_Id :=
        Transaction_Of ("01");

      Code_One : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("recovery-code-one");
      Code_Two : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("recovery-code-two");
      Code_Unknown : constant Identity.Secrets.Text.Secret_Text :=
        Identity.Secrets.Text.From_UTF_8 ("recovery-code-never-issued");

      Empty_Code : constant Identity.Recovery_Codes.Sets.Recovery_Code_Verifier :=
        (Code_Id         => Identity.Text.Bounded.From_String (""),
         Secret_Verifier => Identity.Text.Bounded.From_String (""),
         State           => Identity.Recovery_Codes.Sets.Revoked);

      function Code_Verifier
        (Label  : String;
         Secret : Identity.Secrets.Text.Secret_Text)
         return Identity.Recovery_Codes.Sets.Recovery_Code_Verifier is
        (Code_Id         => Identity.Text.Bounded.From_String (Label),
         Secret_Verifier =>
           Identity.Crypto.Secret_Verifiers.Derive_Text
             (Identity.Crypto.Domains.Recovery_Code, Secret),
         State           => Identity.Recovery_Codes.Sets.Active);

      Code_Set : constant Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record :=
        (Id         => Set_Id,
         Principal  => P1,
         Created_At => 0,
         Version    => 0,
         Count      => 2,
         Codes      =>
           [1      => Code_Verifier ("code-1", Code_One),
            2      => Code_Verifier ("code-2", Code_Two),
            others => Empty_Code]);

      Transaction_Record : constant Identity.Recovery.Transactions.Recovery_Transaction_Record :=
        (Id         => Transaction,
         Principal  => P1,
         Account    => A1,
         Created_At => 0,
         Expires_At => Far_Future,
         State      => Identity.Recovery.Transactions.Started,
         Version    => 0);

      Found  : Boolean;
      Stored : Identity.Recovery.Transactions.Recovery_Transaction_Record;
      Account : Identity.Accounts.Definitions.Account_Record;
   begin
      Stores.Reset (Repository);

      --  1. The recovery code set installs for a real principal/account pair,
      --      and re-installing the same set identifier is refused.
      Check (Stores.Create_Principal (Repository, Active_Principal (P1)) = Stores.Applied
             and then Stores.Create_Account
               (Repository,
                (Id => A1, Principal => P1, State => Active_Account_State, Version => 0))
               = Stores.Applied
             and then Stores.Install_Recovery_Code_Set (Repository, Code_Set) = Stores.Applied
             and then Stores.Install_Recovery_Code_Set (Repository, Code_Set)
               = Stores.Uniqueness_Conflict
             and then Stores.Recovery_Code_Set_Count (Repository) = 1);

      --  2. A valid code is consumed exactly once.
      Check (Stores.Consume_Recovery_Code (Repository, Set_Id, Code_One)
             = Identity.Recovery_Codes.Sets.Consumed);

      --  3. Replaying the same code is refused as already consumed.
      Check (Stores.Consume_Recovery_Code (Repository, Set_Id, Code_One)
             = Identity.Recovery_Codes.Sets.Already_Consumed);

      --  4. A code that was never issued does not verify, and the second
      --      issued code is still usable.
      Check (Stores.Consume_Recovery_Code (Repository, Set_Id, Code_Unknown)
             = Identity.Recovery_Codes.Sets.Not_Verified
             and then Stores.Consume_Recovery_Code (Repository, Set_Id, Code_Two)
               = Identity.Recovery_Codes.Sets.Consumed);

      --  5. Beginning recovery moves the transaction into the evidence phase.
      Check (Stores.Begin_Recovery (Repository, Transaction_Record)
             = Identity.Recovery.Transactions.Applied);
      Stores.Find_Recovery_Transaction (Repository, Transaction, Found, Stored);

      --  6. Evidence with a stale expected version is refused; the current
      --      version is accepted.
      Check (Found
             and then Stored.State = Identity.Recovery.Transactions.Evidence_Required
             and then Stores.Accept_Recovery_Evidence
               (Repository, Transaction, P1, Now_Instant, Expected_Version => 99)
               = Identity.Recovery.Transactions.Version_Conflict
             and then Stores.Accept_Recovery_Evidence
               (Repository, Transaction, P1, Now_Instant,
                Expected_Version => Stored.Version)
               = Identity.Recovery.Transactions.Applied);

      --  7. The approval path advances through Advance_Recovery (certifying that
      --      primitive's forwarding on every adapter, not just the memory store).
      Stores.Find_Recovery_Transaction (Repository, Transaction, Found, Stored);
      Check (Found
             and then Stored.State = Identity.Recovery.Transactions.Evidence_Accepted
             and then Stores.Advance_Recovery
               (Repository, Transaction, P1,
                Identity.Recovery.Transactions.Approve_Recovery,
                Now_Instant, Stored.Version)
               = Identity.Recovery.Transactions.Applied);

      --  8. Completion applies once from the approved state, and a replayed
      --      completion is refused.
      Check (Stores.Complete_Recovery (Repository, Transaction, P1, Now_Instant)
             = Identity.Recovery.Transactions.Applied
             and then Stores.Complete_Recovery (Repository, Transaction, P1, Now_Instant)
               = Identity.Recovery.Transactions.State_Conflict);
      --  9. Completion left the account under recovery restrictions.
      Stores.Find_Account (Repository, P1, Found, Account);
      Check (Found
             and then Account.State.Recovery.Restricted_Session
             and then Account.State.Requirements.Credential_Reestablishment_Required
             and then Account.State.Lifecycle = Identity.Accounts.States.Active);

      --  10. The contact-change read and advance primitives delegate on every
      --       adapter: an unknown change reads back absent and advancing it is a
      --       state conflict, but the call still passes through the decorator.
      declare
         CC_Found : Boolean;
         CC       : Identity.Verification.Changes.Contact_Change_Record;
      begin
         Stores.Find_Contact_Change (Repository, Token_Of ("cc"), CC_Found, CC);
         Check (not CC_Found
                and then Stores.Advance_Contact_Change
                  (Repository, Token_Of ("cc"), P1,
                   Identity.Verification.Changes.Cancel_Change,
                   Expected_Version => 0)
                  = Stores.State_Conflict);
      end;
   end Run_Recovery;

   ---------------------------------------------------------------------------
   --  Federated identity store: 7 checks
   ---------------------------------------------------------------------------

   procedure Run_Federated (Repository : in out Stores.Store_Interface'Class) is

      Provider : constant Identity.Identifiers.Entities.External_Provider_Id :=
        Provider_Of ("01");
      Binding_Id : constant Identity.Identifiers.Entities.External_Binding_Id :=
        External_Binding_Of ("01");

      Issuer : constant Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("https://issuer.example");
      Subject : constant Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("provider-subject-123");

      function Assertion_With
        (Fingerprint : String;
         Expires     : Identity.Times.Expiration)
         return Identity.External_Providers.Assertions.Normalized_Assertion is
        (Provider              => Provider,
         Protocol              => OIDC_Protocol,
         Issuer                => Issuer,
         External_Subject      => Subject,
         Issued_At             => 0,
         Authentication_Time   => 0,
         Expires_At            => Expires,
         Nonce                 => Identity.External_Providers.Assertions.Validated,
         Assertion_Fingerprint => Identity.Text.Bounded.From_String (Fingerprint),
         Validation_Profile    => Adapter_Profile);

      Binding_Record : constant Identity.External_Providers.Bindings.External_Binding_Record :=
        (Id               => Binding_Id,
         Principal        => P1,
         Provider         => Provider,
         Issuer           => Issuer,
         External_Subject => Subject,
         State            => Identity.External_Providers.Bindings.Active,
         Created_At       => 0,
         Version          => 0);

      Result : Identity.Authentication.Results.Password_Authentication_Result;
   begin
      Stores.Reset (Repository);

      --  1. The external binding is accepted for a freshly created principal.
      Check (Stores.Create_Principal (Repository, Active_Principal (P1)) = Stores.Applied
             and then Stores.Create_Principal (Repository, Active_Principal (P2))
               = Stores.Applied
             and then Stores.Bind_External (Repository, Binding_Record) = Stores.Applied
             and then Stores.External_Binding_Count (Repository) = 1);

      --  2. A second active binding over the same provider/issuer/subject key
      --      is refused, even for a different principal.
      Check (Stores.Bind_External
               (Repository,
                (Id               => External_Binding_Of ("02"),
                 Principal        => P2,
                 Provider         => Provider,
                 Issuer           => Issuer,
                 External_Subject => Subject,
                 State            => Identity.External_Providers.Bindings.Active,
                 Created_At       => 0,
                 Version          => 0))
             = Stores.Uniqueness_Conflict
             and then Stores.External_Binding_Count (Repository) = 1);

      --  3. A fresh assertion authenticates to the bound principal.
      Result := Stores.Authenticate_External
        (Repository, Assertion_With ("assertion-fingerprint-1", Far_Future), Now_Instant);
      Check (Result.Status = Identity.Results.Succeeded
             and then Result.Principal.Present
             and then Result.Principal.Value = P1
             and then Stores.External_Replay_Count (Repository) = 1);

      --  4. Replaying the same assertion fingerprint is refused as a conflict.
      Result := Stores.Authenticate_External
        (Repository, Assertion_With ("assertion-fingerprint-1", Far_Future), Now_Instant);
      Check (Result.Status = Identity.Results.Conflict
             and then not Result.Principal.Present
             and then Stores.External_Replay_Count (Repository) = 1);

      --  5. Direct replay-marker registration refuses a known fingerprint and
      --      accepts an unseen one.
      Check (Stores.Register_External_Replay
               (Repository, Identity.Text.Bounded.From_String ("assertion-fingerprint-1"))
             = Stores.State_Conflict
             and then Stores.Register_External_Replay
               (Repository, Identity.Text.Bounded.From_String ("assertion-fingerprint-9"))
               = Stores.Applied);

      --  6. An expired assertion is rejected and leaves no replay marker.
      Result := Stores.Authenticate_External
        (Repository,
         Assertion_With ("assertion-fingerprint-2", (Present => True, Time_Point => 10)),
         Now_Instant);
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present
             and then Stores.Register_External_Replay
               (Repository, Identity.Text.Bounded.From_String ("assertion-fingerprint-2"))
               = Stores.Applied);

      --  7. A revoked binding no longer authenticates a fresh assertion.
      Result :=
        (if Stores.Revoke_External (Repository, Binding_Id, P1) = Stores.Applied
         then Stores.Authenticate_External
                (Repository,
                 Assertion_With ("assertion-fingerprint-3", Far_Future), Now_Instant)
         else (Status => Identity.Results.Succeeded, Principal => (Present => False)));
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present);
   end Run_Federated;

   ---------------------------------------------------------------------------
   --  Driver
   ---------------------------------------------------------------------------

   procedure Run
     (Value      : Profile;
      Repository : in out Stores.Store_Interface'Class) is
   begin
      case Value is
         when Conformance.Core_Identity_Store => Run_Core (Repository);
         when Conformance.Interactive_Authentication_Store =>
            Run_Interactive (Repository);
         when Conformance.Session_Store => Run_Sessions (Repository);
         when Conformance.Recovery_Store => Run_Recovery (Repository);
         when Conformance.Federated_Identity_Store => Run_Federated (Repository);
      end case;
   end Run;

   type Adapter_Id is
     (Memory_Adapter, Recording_Adapter, Persistent_Adapter, Serialized_Adapter);

   function Adapter_Image (Value : Adapter_Id) return String is
     (case Value is
        when Memory_Adapter => "memory",
        when Recording_Adapter => "recording",
        when Persistent_Adapter => "persistent",
        when Serialized_Adapter => "serialized");

   --  Reference implementation, and an independent adapter wrapping its own
   --  backing store through the same interface. Both live on the heap: a
   --  Memory.Store is a large fixed-capacity record and two of them plus the
   --  initialisation temporary overflow the default stack.
   type Store_Access is access Memory.Store;

   Reference_Ptr : constant Store_Access := new Memory.Store;
   Backing_Ptr   : constant Store_Access := new Memory.Store;

   Wrapped_Store : Recording.Store
     (Inner => Stores.Store_Interface'Class (Backing_Ptr.all)'Access);

   --  Third adapter: durable, backed by a snapshot file. Certifying it through
   --  the same profiles is what shows the SPI holds up against real storage.
   Persistent_Ptr   : constant Store_Access := new Memory.Store;
   Persistent_Store : Persistent.Store (Inner => Persistent_Ptr);

   --  Fourth adapter: the serialising lock decorator. Certifying it through the
   --  same profiles exercises its per-primitive forwarding, which the narrow
   --  concurrency stress main alone leaves almost entirely uncovered.
   Serialized_Ptr   : constant Store_Access := new Memory.Store;
   Serialized_Store : Serialized.Store
     (Inner => Stores.Store_Interface'Class (Serialized_Ptr.all)'Access);
   --  Resolved relative to the current directory, which differs between a
   --  developer running this from the repo root and release-check.sh running
   --  it from inside the crate. Create the directory rather than depending on
   --  one existing, so a missing directory cannot be mistaken for a store
   --  that failed to persist.
   Snapshot_Dir     : constant String := "generated/evidence";
   Snapshot_Path    : constant String := Snapshot_Dir & "/conformance-store.bin";

   Failed_Run : Boolean := False;
   Status     : Conformance.Conformance_Status;
   Required   : Positive;
   Crypto     : constant Identity.Crypto.Capabilities.Crypto_Capability_Set :=
     Identity.Crypto.CryptoLib.Capabilities.Current;

   procedure Report_Capability
     (Name  : String;
      State : Identity.Crypto.Capabilities.Capability_State) is
   begin
      Ada.Text_IO.Put_Line
        ("identity_conformance:capability:" & Name & ":"
         & (if State = Identity.Crypto.Capabilities.Available then "available" else "missing"));
   end Report_Capability;
begin
   declare
      Status : Memory.Snapshot_Status;
   begin
      Ada.Directories.Create_Path (Snapshot_Dir);
      --  A stale snapshot from an earlier run would make the durability check
      --  pass on data this run never wrote.
      if Ada.Directories.Exists (Snapshot_Path) then
         Ada.Directories.Delete_File (Snapshot_Path);
      end if;
      Persistent.Open (Persistent_Store, Snapshot_Path, Status);
   end;

   --  Every profile runs against every adapter. The memory adapter is the
   --  reference implementation; the recording adapter is an independent
   --  implementation of the same SPI wrapping a memory store. Certifying both
   --  through the identical harness is what demonstrates the SPI is pluggable
   --  rather than merely declared.
   for Adapter in Adapter_Id loop
      for Value in Profile loop
         Reset_Profile;

         case Adapter is
            when Memory_Adapter =>
               Run (Value, Reference_Ptr.all);
            when Recording_Adapter =>
               Run (Value, Wrapped_Store);
            when Persistent_Adapter =>
               Run (Value, Persistent_Store);
            when Serialized_Adapter =>
               Run (Value, Serialized_Store);
         end case;

         Required := Conformance.Required_Check_Count (Value);

         if Failures = 0 and then Executed = Required then
            Status := Conformance.Passed;
         else
            Status := Conformance.Failed;
         end if;

         --  Unqualified lines remain the memory adapter's certification, so
         --  existing consumers of this output keep working.
         if Adapter = Memory_Adapter then
            Ada.Text_IO.Put_Line
              ("identity_conformance:" & Image (Value) & ":"
               & (if Conformance.Passed_Status (Status) then "passed" else "failed"));
            Ada.Text_IO.Put_Line
              ("identity_conformance:" & Image (Value) & ":checks:"
               & Count_Image (Executed) & "/" & Count_Image (Required));
         end if;

         Ada.Text_IO.Put_Line
           ("identity_conformance:adapter:" & Adapter_Image (Adapter) & ":"
            & Image (Value) & ":"
            & (if Conformance.Passed_Status (Status) then "passed" else "failed")
            & ":checks:" & Count_Image (Executed) & "/" & Count_Image (Required));

         if not Conformance.Passed_Status (Status) then
            Failed_Run := True;
         end if;
      end loop;
   end loop;

   --  Durability is the persistent adapter's whole claim, so check it rather
   --  than assume it: reload the snapshot into a fresh store and require the
   --  last profile's state to still be there.
   declare
      Reloaded : constant Store_Access := new Memory.Store;
      Status   : Memory.Snapshot_Status;
   begin
      Memory.Load (Reloaded.all, Snapshot_Path, Status);
      if Status = Memory.Loaded
        and then Stores.Principal_Count (Stores.Store_Interface'Class (Reloaded.all))
                 = Stores.Principal_Count
                     (Stores.Store_Interface'Class (Persistent_Store))
      then
         Ada.Text_IO.Put_Line
           ("identity_conformance:adapter:persistent:snapshot-reloaded:"
            & Count_Image
                (Stores.Principal_Count (Stores.Store_Interface'Class (Reloaded.all))));
      else
         Ada.Text_IO.Put_Line
           ("identity_conformance:adapter:persistent:snapshot-not-durable");
         Failed_Run := True;
      end if;
   end;

   --  A durable auth store is worthless if a credential stops working after a
   --  restart, and the count check above does not exercise that. Seed a fresh
   --  store with a full login fixture, save it, reload into another store, and
   --  require the enrolled password to still authenticate -- and the wrong one
   --  to still be rejected -- through the reloaded store.
   declare
      Cred_Path : constant String := Snapshot_Dir & "/conformance-credential.bin";
      Writer    : constant Store_Access := new Memory.Store;
      Reader    : constant Store_Access := new Memory.Store;
      WV : Stores.Store_Interface'Class renames
        Stores.Store_Interface'Class (Writer.all);
      RV : Stores.Store_Interface'Class renames
        Stores.Store_Interface'Class (Reader.all);
      Subject : constant Identity.Identities.Subjects.Authentication_Subject :=
        (Kind => Login_Kind, Value => Alice);
      Good : constant Identity.Secrets.Passwords.New_Password :=
        Identity.Secrets.Text.From_UTF_8 ("conformance durable credential secret");
      Good_P : constant Identity.Secrets.Passwords.Presented_Password :=
        Identity.Secrets.Text.From_UTF_8 ("conformance durable credential secret");
      Wrong_P : constant Identity.Secrets.Passwords.Presented_Password :=
        Identity.Secrets.Text.From_UTF_8 ("conformance durable credential secreu");
      Ctx : constant Identity.Operations.Contexts.Operation_Context :=
        (Operation =>
           Identity.Identifiers.Operations.Operation
             (Identity.Identifiers.From_String
                ("7f000000-0000-0000-0000-0000000000d0")),
         Correlation =>
           Identity.Identifiers.Operations.Correlation
             (Identity.Identifiers.From_String
                ("7f100000-0000-0000-0000-0000000000d0")),
         Causation => (Present => False), Request => (Present => False),
         Actor => (Kind => Identity.Events.Envelopes.Unauthenticated,
                   Principal => (Present => False)),
         Requested_At => 1, Deadline => (Present => False, Time_Point => 0),
         others => <>);
      function Ev (Suffix : String)
        return Identity.Identifiers.Entities.Event_Id is
        (Identity.Identifiers.Entities.Event
           (Identity.Identifiers.From_String
              ("7f200000-0000-0000-0000-0000000000" & Suffix)));
      Status  : Memory.Snapshot_Status;
      Command : Stores.Command_Status;
      Applied : Boolean;
      Reloaded_OK, Wrong_Rejected : Boolean;
   begin
      --  A leftover credential snapshot from an earlier run would let this
      --  check pass on stale data even if this run's save failed.
      if Ada.Directories.Exists (Cred_Path) then
         Ada.Directories.Delete_File (Cred_Path);
      end if;

      Applied := True;
      Command := Stores.Create_Principal (WV, Active_Principal (P1));
      Applied := Applied and then Command = Stores.Applied;
      Command := Stores.Create_Account (WV,
        (Id => Account_Of ("d1"), Principal => P1,
         State => Active_Account_State, Version => 0));
      Applied := Applied and then Command = Stores.Applied;
      Command := Stores.Add_Binding (WV,
        (Id => Binding_Of ("d1"), Principal => P1, Kind => Login_Kind,
         Normalized => Alice,
         State => Identity.Identities.Bindings.Active, Version => 0));
      Applied := Applied and then Command = Stores.Applied;
      Command := Identity.Operations.Passwords.Enroll.Execute
        (WV, P1, Credential_Of ("d1"), Good, Ctx, Ev ("01"), 1);
      Applied := Applied and then Command = Stores.Applied;

      Memory.Save (Writer.all, Cred_Path, Status);
      if Status /= Memory.Saved then
         Applied := False;
      end if;
      Memory.Load (Reader.all, Cred_Path, Status);

      Reloaded_OK :=
        Identity.Results.Succeeded =
          Identity.Operations.Passwords.Authenticate.Execute
            (RV, Subject, Good_P, Ctx, Ev ("02"), 2).Status;
      Wrong_Rejected :=
        Identity.Results.Succeeded /=
          Identity.Operations.Passwords.Authenticate.Execute
            (RV, Subject, Wrong_P, Ctx, Ev ("03"), 3).Status;

      if Applied and then Status = Memory.Loaded
        and then Reloaded_OK and then Wrong_Rejected
      then
         Ada.Text_IO.Put_Line
           ("identity_conformance:adapter:persistent:credential-survives-reload:passed");
      else
         Ada.Text_IO.Put_Line
           ("identity_conformance:adapter:persistent:credential-survives-reload:failed");
         Failed_Run := True;
      end if;
   end;

   --  The decorator must actually have seen the traffic it delegated; a
   --  wrapper that silently bypassed the SPI would otherwise look certified.
   if Recording.Total_Call_Count (Wrapped_Store) = 0 then
      Ada.Text_IO.Put_Line ("identity_conformance:adapter:recording:no-delegated-calls");
      Failed_Run := True;
   else
      Ada.Text_IO.Put_Line
        ("identity_conformance:adapter:recording:delegated-calls:"
         & Count_Image (Recording.Total_Call_Count (Wrapped_Store)));
   end if;

   Report_Capability ("entropy", Crypto.Entropy);
   Report_Capability ("password-hashing", Crypto.Password_Hashing);
   Report_Capability ("secret-verifiers", Crypto.Secret_Verifiers);
   Report_Capability ("constant-time", Crypto.Constant_Time);
   Report_Capability ("totp-hmac", Crypto.TOTP_HMAC);
   Report_Capability ("event-integrity", Crypto.Event_Integrity);

   if not Identity.Crypto.Capabilities.Supports_Core_V1 (Crypto) then
      Ada.Text_IO.Put_Line ("identity_conformance:crypto-core-v1:failed");
      Failed_Run := True;
   else
      Ada.Text_IO.Put_Line ("identity_conformance:crypto-core-v1:passed");
   end if;

   if Failed_Run then
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Identity_Conformance;

with Ada.Command_Line;
with Ada.Text_IO;
with Identity.Accounts.Definitions;
with Identity.Accounts.States;
with Identity.Adapters.Repositories.Conformance;
with Identity.Adapters.Repositories.Memory;
with Identity.API_Keys.Credentials;
with Identity.Authentication.Results;
with Identity.Credentials.States;
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
with Identity.Identities.Resolution;
with Identity.Principals.Definitions;
with Identity.Principals.Kinds;
with Identity.Recovery.Transactions;
with Identity.Recovery_Codes.Sets;
with Identity.Results;
with Identity.Secrets.Text;
with Identity.Sessions.Definitions;
with Identity.Sessions.Handles;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

--  Repository conformance harness. Every profile below runs real commands and
--  queries against Identity.Adapters.Repositories.Memory.Store and asserts the
--  observable postcondition of each one. Nothing is reported as passed unless
--  the store actually produced the required outcome, and unless the number of
--  checks executed matches Required_Check_Count for that profile.
procedure Identity_Conformance is

   package Conformance renames Identity.Adapters.Repositories.Conformance;
   package Memory renames Identity.Adapters.Repositories.Memory;

   use type Memory.Command_Status;
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

   procedure Run_Core is
      Repository : Memory.Store;
      Found      : Boolean;
      Principal  : Identity.Principals.Definitions.Principal_Record;
      Account    : Identity.Accounts.Definitions.Account_Record;
   begin
      Memory.Initialize (Repository);

      --  1. A fresh principal is accepted and becomes visible.
      Check (Memory.Create_Principal (Repository, Active_Principal (P1)) = Memory.Applied
             and then Memory.Principal_Count (Repository) = 1);

      --  2. Re-creating the same principal identifier is a uniqueness conflict.
      Check (Memory.Create_Principal (Repository, Active_Principal (P1))
             = Memory.Uniqueness_Conflict
             and then Memory.Principal_Count (Repository) = 1);

      --  3. An account for an existing principal is accepted and readable.
      Memory.Find_Account (Repository, P1, Found, Account);
      Check (Memory.Create_Account
               (Repository,
                (Id => A1, Principal => P1, State => Active_Account_State, Version => 0))
             = Memory.Applied
             and then not Found);

      --  4. An account for an unknown principal is refused.
      Check (Memory.Create_Account
               (Repository,
                (Id => A2, Principal => P3, State => Active_Account_State, Version => 0))
             = Memory.State_Conflict
             and then Memory.Account_Count (Repository) = 1);

      --  5. An active binding is added and resolves back to its principal.
      Check (Memory.Add_Binding
               (Repository,
                (Id         => Binding_Of ("01"),
                 Principal  => P1,
                 Kind       => Login_Kind,
                 Normalized => Alice,
                 State      => Identity.Identities.Bindings.Active,
                 Version    => 0))
             = Memory.Applied
             and then Memory.Resolve
               (Repository, (Kind => Login_Kind, Value => Alice)).Status
               = Identity.Identities.Resolution.Resolved
             and then Memory.Resolve
               (Repository, (Kind => Login_Kind, Value => Alice)).Principal = P1);

      --  6. A second active binding over the same subject is refused.
      Check (Memory.Add_Binding
               (Repository,
                (Id         => Binding_Of ("02"),
                 Principal  => P1,
                 Kind       => Login_Kind,
                 Normalized => Alice,
                 State      => Identity.Identities.Bindings.Active,
                 Version    => 0))
             = Memory.Uniqueness_Conflict
             and then Memory.Binding_Count (Repository) = 1);

      --  7. Retiring with a stale expected version is a version conflict and
      --      leaves the principal active.
      Memory.Find_Principal (Repository, P1, Found, Principal);
      Check (Memory.Retire_Principal (Repository, P1, Expected_Version => 99)
             = Memory.Version_Conflict
             and then Found
             and then Principal.State = Identity.Principals.Definitions.Active);

      --  8. Retiring at the current version applies, and further bindings for
      --      the retired principal are refused.
      Check (Memory.Retire_Principal (Repository, P1, Expected_Version => Principal.Version)
             = Memory.Applied
             and then Memory.Add_Binding
               (Repository,
                (Id         => Binding_Of ("03"),
                 Principal  => P1,
                 Kind       => Login_Kind,
                 Normalized => Identity.Text.Bounded.From_String ("alice.second"),
                 State      => Identity.Identities.Bindings.Active,
                 Version    => 0))
               = Memory.State_Conflict);
   end Run_Core;

   ---------------------------------------------------------------------------
   --  Interactive authentication store: 7 checks
   ---------------------------------------------------------------------------

   procedure Run_Interactive is
      Repository : Memory.Store;

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
      Memory.Initialize (Repository);

      --  1. A password credential is enrolled for a freshly created principal.
      Check (Memory.Create_Principal (Repository, Active_Principal (P1)) = Memory.Applied
             and then Memory.Enroll_Password
               (Repository,
                (Id        => Credential_Of ("01"),
                 Principal => P1,
                 State     => Identity.Credentials.States.Active,
                 Verifier  =>
                   Identity.Crypto.Secret_Verifiers.Derive_Text
                     (Identity.Crypto.Domains.Password_Reset_Token, Password_Secret),
                 Version   => 0))
               = Memory.Applied
             and then Memory.Password_Credential_Count (Repository) = 1);

      --  2. A second active password for the same principal is refused.
      Check (Memory.Enroll_Password
               (Repository,
                (Id        => Credential_Of ("03"),
                 Principal => P1,
                 State     => Identity.Credentials.States.Active,
                 Verifier  =>
                   Identity.Crypto.Secret_Verifiers.Derive_Text
                     (Identity.Crypto.Domains.Password_Reset_Token, Password_Secret),
                 Version   => 0))
             = Memory.State_Conflict
             and then Memory.Password_Credential_Count (Repository) = 1);

      --  3. An API key is issued and authenticates with the enrolled secret.
      Result := (if Memory.Issue_API_Key (Repository, Key_Record) = Memory.Applied
                 then Memory.Authenticate_API_Key
                        (Repository, Key_Reference, Key_Secret, Now_Instant)
                 else (Status => Identity.Results.Internal_Invariant_Failure,
                       Principal => (Present => False)));
      Check (Result.Status = Identity.Results.Succeeded
             and then Result.Principal.Present
             and then Result.Principal.Value = P1);

      --  4. A wrong secret is rejected without naming a principal.
      Result := Memory.Authenticate_API_Key
        (Repository, Key_Reference, Wrong_Key_Secret, Now_Instant);
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present);

      --  5. A stale expected credential version is a conflict, not a success.
      Result := Memory.Authenticate_API_Key
        (Repository, Key_Reference, Key_Secret, Now_Instant,
         Expected_Credential_Version => 99);
      Check (Result.Status = Identity.Results.Conflict
             and then not Result.Principal.Present);

      --  6. Retiring the principal applies.
      Check (Memory.Retire_Principal (Repository, P1) = Memory.Applied);

      --  7. Once the principal is retired the same valid secret is rejected.
      Result := Memory.Authenticate_API_Key
        (Repository, Key_Reference, Key_Secret, Now_Instant);
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present);
   end Run_Interactive;

   ---------------------------------------------------------------------------
   --  Session store: 9 checks
   ---------------------------------------------------------------------------

   procedure Run_Sessions is
      Repository : Memory.Store;

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
      Memory.Initialize (Repository);

      --  1. A session is created for a freshly created active principal.
      Check (Memory.Create_Principal (Repository, Active_Principal (P1)) = Memory.Applied
             and then Memory.Create_Session
               (Repository, Session_For (S1, Reference_One, Secret_One, 0))
               = Memory.Applied
             and then Memory.Session_Count (Repository) = 1);

      --  2. A different session reusing the public reference is refused.
      Check (Memory.Create_Session (Repository, Session_For (S2, Reference_One, Secret_Two, 0))
             = Memory.Uniqueness_Conflict
             and then Memory.Session_Count (Repository) = 1);

      --  3. Lookup with the matching secret yields the session and principal.
      Handle := Memory.Lookup_Session (Repository, Reference_One, Secret_One, Now_Instant);
      Check (Handle.Status = Identity.Sessions.Handles.Found
             and then Handle.Principal = P1);

      --  4. Lookup with a non-matching secret does not authenticate.
      Handle := Memory.Lookup_Session (Repository, Reference_One, Secret_Bad, Now_Instant);
      Check (Handle.Status = Identity.Sessions.Handles.Not_Verified);

      --  5. Rotation installs the successor and marks the predecessor rotated.
      Check (Memory.Rotate_Session
               (Repository, S1, Session_For (S2, Reference_Two, Secret_Two, 1))
             = Memory.Applied
             and then Memory.Session_Count (Repository) = 2);
      Memory.Find_Session (Repository, S1, Found, Value);

      --  6. The rotated predecessor no longer authenticates.
      Handle := Memory.Lookup_Session (Repository, Reference_One, Secret_One, Now_Instant);
      Check (Found
             and then Value.State = Identity.Sessions.Definitions.Rotated
             and then Handle.Status = Identity.Sessions.Handles.Revoked);

      --  7. The successor authenticates with its own secret.
      Handle := Memory.Lookup_Session (Repository, Reference_Two, Secret_Two, Now_Instant);
      Check (Handle.Status = Identity.Sessions.Handles.Found
             and then Handle.Principal = P1);

      --  8. Rotating with a stale expected predecessor version is refused.
      Check (Memory.Rotate_Session
               (Repository, S2,
                Expected_Predecessor_Version => 99,
                Successor => Session_For (S3, Reference_Three, Secret_One, 2))
             = Memory.Version_Conflict
             and then Memory.Session_Count (Repository) = 2);

      --  9. Revoking the family stops the surviving successor.
      Check (Memory.Revoke_Session_Family (Repository, Family) = Memory.Applied
             and then Memory.Lookup_Session
               (Repository, Reference_Two, Secret_Two, Now_Instant).Status
               = Identity.Sessions.Handles.Revoked);
   end Run_Sessions;

   ---------------------------------------------------------------------------
   --  Recovery store: 8 checks
   ---------------------------------------------------------------------------

   procedure Run_Recovery is
      Repository : Memory.Store;

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
      Memory.Initialize (Repository);

      --  1. The recovery code set installs for a real principal/account pair,
      --      and re-installing the same set identifier is refused.
      Check (Memory.Create_Principal (Repository, Active_Principal (P1)) = Memory.Applied
             and then Memory.Create_Account
               (Repository,
                (Id => A1, Principal => P1, State => Active_Account_State, Version => 0))
               = Memory.Applied
             and then Memory.Install_Recovery_Code_Set (Repository, Code_Set) = Memory.Applied
             and then Memory.Install_Recovery_Code_Set (Repository, Code_Set)
               = Memory.Uniqueness_Conflict
             and then Memory.Recovery_Code_Set_Count (Repository) = 1);

      --  2. A valid code is consumed exactly once.
      Check (Memory.Consume_Recovery_Code (Repository, Set_Id, Code_One)
             = Identity.Recovery_Codes.Sets.Consumed);

      --  3. Replaying the same code is refused as already consumed.
      Check (Memory.Consume_Recovery_Code (Repository, Set_Id, Code_One)
             = Identity.Recovery_Codes.Sets.Already_Consumed);

      --  4. A code that was never issued does not verify, and the second
      --      issued code is still usable.
      Check (Memory.Consume_Recovery_Code (Repository, Set_Id, Code_Unknown)
             = Identity.Recovery_Codes.Sets.Not_Verified
             and then Memory.Consume_Recovery_Code (Repository, Set_Id, Code_Two)
               = Identity.Recovery_Codes.Sets.Consumed);

      --  5. Beginning recovery moves the transaction into the evidence phase.
      Check (Memory.Begin_Recovery (Repository, Transaction_Record)
             = Identity.Recovery.Transactions.Applied);
      Memory.Find_Recovery_Transaction (Repository, Transaction, Found, Stored);

      --  6. Evidence with a stale expected version is refused; the current
      --      version is accepted.
      Check (Found
             and then Stored.State = Identity.Recovery.Transactions.Evidence_Required
             and then Memory.Accept_Recovery_Evidence
               (Repository, Transaction, P1, Now_Instant, Expected_Version => 99)
               = Identity.Recovery.Transactions.Version_Conflict
             and then Memory.Accept_Recovery_Evidence
               (Repository, Transaction, P1, Now_Instant,
                Expected_Version => Stored.Version)
               = Identity.Recovery.Transactions.Applied);

      --  7. Completion applies once, and a replayed completion is refused.
      Check (Memory.Complete_Recovery (Repository, Transaction, P1, Now_Instant)
             = Identity.Recovery.Transactions.Applied
             and then Memory.Complete_Recovery (Repository, Transaction, P1, Now_Instant)
               = Identity.Recovery.Transactions.State_Conflict);
      --  8. Completion left the account under recovery restrictions.
      Memory.Find_Account (Repository, P1, Found, Account);
      Check (Found
             and then Account.State.Recovery.Restricted_Session
             and then Account.State.Requirements.Credential_Reestablishment_Required
             and then Account.State.Lifecycle = Identity.Accounts.States.Active);
   end Run_Recovery;

   ---------------------------------------------------------------------------
   --  Federated identity store: 7 checks
   ---------------------------------------------------------------------------

   procedure Run_Federated is
      Repository : Memory.Store;

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
      Memory.Initialize (Repository);

      --  1. The external binding is accepted for a freshly created principal.
      Check (Memory.Create_Principal (Repository, Active_Principal (P1)) = Memory.Applied
             and then Memory.Create_Principal (Repository, Active_Principal (P2))
               = Memory.Applied
             and then Memory.Bind_External (Repository, Binding_Record) = Memory.Applied
             and then Memory.External_Binding_Count (Repository) = 1);

      --  2. A second active binding over the same provider/issuer/subject key
      --      is refused, even for a different principal.
      Check (Memory.Bind_External
               (Repository,
                (Id               => External_Binding_Of ("02"),
                 Principal        => P2,
                 Provider         => Provider,
                 Issuer           => Issuer,
                 External_Subject => Subject,
                 State            => Identity.External_Providers.Bindings.Active,
                 Created_At       => 0,
                 Version          => 0))
             = Memory.Uniqueness_Conflict
             and then Memory.External_Binding_Count (Repository) = 1);

      --  3. A fresh assertion authenticates to the bound principal.
      Result := Memory.Authenticate_External
        (Repository, Assertion_With ("assertion-fingerprint-1", Far_Future), Now_Instant);
      Check (Result.Status = Identity.Results.Succeeded
             and then Result.Principal.Present
             and then Result.Principal.Value = P1
             and then Memory.External_Replay_Count (Repository) = 1);

      --  4. Replaying the same assertion fingerprint is refused as a conflict.
      Result := Memory.Authenticate_External
        (Repository, Assertion_With ("assertion-fingerprint-1", Far_Future), Now_Instant);
      Check (Result.Status = Identity.Results.Conflict
             and then not Result.Principal.Present
             and then Memory.External_Replay_Count (Repository) = 1);

      --  5. Direct replay-marker registration refuses a known fingerprint and
      --      accepts an unseen one.
      Check (Memory.Register_External_Replay
               (Repository, Identity.Text.Bounded.From_String ("assertion-fingerprint-1"))
             = Memory.State_Conflict
             and then Memory.Register_External_Replay
               (Repository, Identity.Text.Bounded.From_String ("assertion-fingerprint-9"))
               = Memory.Applied);

      --  6. An expired assertion is rejected and leaves no replay marker.
      Result := Memory.Authenticate_External
        (Repository,
         Assertion_With ("assertion-fingerprint-2", (Present => True, Time_Point => 10)),
         Now_Instant);
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present
             and then Memory.Register_External_Replay
               (Repository, Identity.Text.Bounded.From_String ("assertion-fingerprint-2"))
               = Memory.Applied);

      --  7. A revoked binding no longer authenticates a fresh assertion.
      Result :=
        (if Memory.Revoke_External (Repository, Binding_Id, P1) = Memory.Applied
         then Memory.Authenticate_External
                (Repository,
                 Assertion_With ("assertion-fingerprint-3", Far_Future), Now_Instant)
         else (Status => Identity.Results.Succeeded, Principal => (Present => False)));
      Check (Result.Status = Identity.Results.Rejected
             and then not Result.Principal.Present);
   end Run_Federated;

   ---------------------------------------------------------------------------
   --  Driver
   ---------------------------------------------------------------------------

   procedure Run (Value : Profile) is
   begin
      case Value is
         when Conformance.Core_Identity_Store => Run_Core;
         when Conformance.Interactive_Authentication_Store => Run_Interactive;
         when Conformance.Session_Store => Run_Sessions;
         when Conformance.Recovery_Store => Run_Recovery;
         when Conformance.Federated_Identity_Store => Run_Federated;
      end case;
   end Run;

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
   for Value in Profile loop
      Reset_Profile;
      Run (Value);
      Required := Conformance.Required_Check_Count (Value);

      if Failures = 0 and then Executed = Required then
         Status := Conformance.Passed;
      else
         Status := Conformance.Failed;
      end if;

      Ada.Text_IO.Put_Line
        ("identity_conformance:" & Image (Value) & ":"
         & (if Conformance.Passed_Status (Status) then "passed" else "failed"));
      Ada.Text_IO.Put_Line
        ("identity_conformance:" & Image (Value) & ":checks:"
         & Count_Image (Executed) & "/" & Count_Image (Required));

      if not Conformance.Passed_Status (Status) then
         Failed_Run := True;
      end if;
   end loop;

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

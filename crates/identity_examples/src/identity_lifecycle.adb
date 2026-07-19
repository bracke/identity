with Ada.Text_IO;
with Identity.Adapters.Repositories.Memory;
with Identity.Accounts.States;
with Identity.Assurance.Levels;
with Identity.Identities.Bindings;
with Identity.Identifiers;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Operations.Principals.Create;
with Identity.Operations.Accounts.Create;
with Identity.Operations.Identities.Add;
with Identity.Operations.Passwords.Enroll;
with Identity.Operations.Passwords.Authenticate;
with Identity.Operations.Sessions.Create;
with Identity.Operations.Sessions.Lookup;
with Identity.Operations.Sessions.Rotate;
with Identity.Principals.Definitions;
with Identity.Principals.Kinds;
with Identity.Results;
with Identity.Secrets.Passwords;
with Identity.Secrets.Sessions;
with Identity.Secrets.Text;
with Identity.Sessions.Handles;
with Identity.Text.Bounded;
with Identity.Times.Expirations;

procedure Identity_Lifecycle is
   use type Identity.Adapters.Repositories.Memory.Command_Status;
   use type Identity.Results.Operation_Status;
   use type Identity.Sessions.Handles.Session_Lookup_Status;

   Store : Identity.Adapters.Repositories.Memory.Store;

   Principal : constant Identity.Identifiers.Entities.Principal_Id :=
     Identity.Identifiers.Entities.Principal
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000001"));
   Account : constant Identity.Identifiers.Entities.Account_Id :=
     Identity.Identifiers.Entities.Account
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000002"));
   Binding : constant Identity.Identifiers.Entities.Identity_Binding_Id :=
     Identity.Identifiers.Entities.Identity_Binding
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000003"));
   Credential : constant Identity.Identifiers.Entities.Credential_Id :=
     Identity.Identifiers.Entities.Credential
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000004"));
   Session : constant Identity.Identifiers.Entities.Session_Id :=
     Identity.Identifiers.Entities.Session
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000005"));
   Family : constant Identity.Identifiers.Entities.Session_Family_Id :=
     Identity.Identifiers.Entities.Session_Family
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000006"));
   Rotated_Session : constant Identity.Identifiers.Entities.Session_Id :=
     Identity.Identifiers.Entities.Session
       (Identity.Identifiers.From_String ("10000000-0000-0000-0000-000000000007"));

   Password : constant Identity.Secrets.Passwords.New_Password :=
     Identity.Secrets.Text.From_UTF_8 ("example password");
   Presented : constant Identity.Secrets.Passwords.Presented_Password :=
     Identity.Secrets.Text.From_UTF_8 ("example password");
   Session_Secret : constant Identity.Secrets.Sessions.Session_Secret :=
     Identity.Secrets.Text.From_UTF_8 ("example session secret");
   Rotated_Session_Secret : constant Identity.Secrets.Sessions.Session_Secret :=
     Identity.Secrets.Text.From_UTF_8 ("example rotated session secret");
   Session_Reference : constant Identity.Text.Bounded.Bounded_Text :=
     Identity.Text.Bounded.From_String ("example-session");
   Rotated_Session_Reference : constant Identity.Text.Bounded.Bounded_Text :=
     Identity.Text.Bounded.From_String ("example-session-rotated");
   Subject : constant Identity.Text.Bounded.Bounded_Text :=
     Identity.Text.Bounded.From_String ("example@example.invalid");
   Subject_Kind : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.subject.email");
begin
   Identity.Adapters.Repositories.Memory.Initialize (Store);

   if Identity.Operations.Principals.Create.Execute
        (Store,
         (Id => Principal,
          Kind => Identity.Principals.Kinds.Human,
          State => Identity.Principals.Definitions.Active,
          Version => 0))
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Accounts.Create.Execute
        (Store,
         (Id => Account,
          Principal => Principal,
          State => (Administrative => Identity.Accounts.States.Enabled,
                    Lifecycle => Identity.Accounts.States.Active,
                    Verification => Identity.Accounts.States.No_Verification_Required,
                    Lock_State => Identity.Accounts.States.Not_Locked,
                    Requirements =>
                      (Password_Change_Required => False,
                       MFA_Enrollment_Required => False,
                       Credential_Reestablishment_Required => False,
                       Recent_Authentication_Required => False),
                    Recovery =>
                      (Restricted_Session => False,
                       Required_Credential_Reestablishment => False,
                       MFA_Reenrollment => False,
                       No_Remember_Me => False,
                       Limited_Lifetime => False,
                       Limited_Action_Profile => False)),
          Version => 0))
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Identities.Add.Execute
        (Store,
         (Id => Binding,
          Principal => Principal,
          Kind => Subject_Kind,
          Normalized => Subject,
          State => Identity.Identities.Bindings.Active,
          Version => 0))
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Passwords.Enroll.Execute
        (Store, Principal, Credential, Password)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Passwords.Authenticate.Execute
        (Store, (Kind => Subject_Kind, Value => Subject), Presented).Status
      = Identity.Results.Succeeded
      and then Identity.Operations.Sessions.Create.Execute
        (Store,
         Identity.Operations.Sessions.Create.Create_Request'
           (Id => Session,
            Family => Family,
            Principal => Principal,
            Credential => (Present => True, Value => Credential),
            External_Provider => (Present => False),
            Public_Reference => Session_Reference,
            Secret => Session_Secret,
            Assurance => Identity.Assurance.Levels.Basic,
            Attributes =>
              (Factor_Count => 1,
               Independent_Factor_Count => 1,
               Phishing_Resistant => False,
               Hardware_Bound => False,
               Device_Bound => False,
               Federation => False,
               Recovery_Used => False,
               User_Presence => False,
               User_Verification => False,
               Managed_Credential => False,
               Recent_Authentication => True),
            Created_At => 1,
            Original_Authenticated_At => 1,
            Primary_Authenticated_At => 1,
            MFA_Completed_At => (Present => False),
            Step_Up_At => (Present => False),
            Last_Seen_At => 1,
            Idle_Expires_At => Identity.Times.Expirations.At_Time (3_600),
            Absolute_Expires_At => Identity.Times.Expirations.At_Time (7_200),
            Remembered => False,
            Generation => 0))
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Sessions.Lookup.Execute
        (Store, Session_Reference, Session_Secret, 2).Status
      = Identity.Sessions.Handles.Found
      and then Identity.Operations.Sessions.Rotate.Execute
        (Store,
         Identity.Operations.Sessions.Rotate.Staged_Rotate_Request'
           (Request =>
              (Predecessor => Session,
               Id => Rotated_Session,
               Family => Family,
               Principal => Principal,
               Credential => (Present => True, Value => Credential),
               External_Provider => (Present => False),
               Public_Reference => Rotated_Session_Reference,
               Secret => Rotated_Session_Secret,
               Assurance => Identity.Assurance.Levels.Basic,
               Attributes =>
                 (Factor_Count => 1,
                  Independent_Factor_Count => 1,
                  Phishing_Resistant => False,
                  Hardware_Bound => False,
                  Device_Bound => False,
                  Federation => False,
                  Recovery_Used => False,
                  User_Presence => False,
                  User_Verification => False,
                  Managed_Credential => False,
                  Recent_Authentication => True),
               Created_At => 2,
               Original_Authenticated_At => 2,
               Primary_Authenticated_At => 2,
               MFA_Completed_At => (Present => False),
               Step_Up_At => (Present => False),
               Last_Seen_At => 2,
               Idle_Expires_At => Identity.Times.Expirations.At_Time (3_602),
               Absolute_Expires_At => Identity.Times.Expirations.At_Time (7_200),
               Remembered => False,
               Generation => 1),
            Expected_Predecessor_Version => 0))
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Sessions.Lookup.Execute
        (Store, Session_Reference, Session_Secret, 3).Status
      = Identity.Sessions.Handles.Revoked
      and then Identity.Operations.Sessions.Lookup.Execute
        (Store, Rotated_Session_Reference, Rotated_Session_Secret, 3).Status
      = Identity.Sessions.Handles.Found
   then
      Ada.Text_IO.Put_Line ("identity_lifecycle:ok");
   else
      Ada.Text_IO.Put_Line ("identity_lifecycle:failed");
      raise Program_Error;
   end if;
end Identity_Lifecycle;

with Ada.Text_IO;
with Identity.Accounts.States;
with Identity.Adapters.Repositories.Memory;
with Identity.Assurance.Levels;
with Identity.Events.Envelopes;
with Identity.Identifiers;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Identities.Bindings;
with Identity.Operations.Accounts.Create;
with Identity.Operations.Accounts.Disable;
with Identity.Operations.API_Keys.Authenticate;
with Identity.Operations.API_Keys.Issue;
with Identity.Operations.Sessions.Revoke_Family;
with Identity.Secrets.API_Keys;
with Identity.Operations.Cancellation;
with Identity.Operations.Contexts;
with Identity.Operations.Disclosure;
with Identity.Operations.Identities.Add;
with Identity.Operations.Passwords.Authenticate;
with Identity.Operations.Passwords.Enroll;
with Identity.Operations.Principals.Create;
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
   Wrong_Presented : constant Identity.Secrets.Passwords.Presented_Password :=
     Identity.Secrets.Text.From_UTF_8 ("not the password");
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
   API_Credential : constant Identity.Identifiers.Entities.Credential_Id :=
     Identity.Identifiers.Entities.Credential
       (Identity.Identifiers.From_String
          ("c0000000-0000-0000-0000-0000000000a1"));
   API_Key_Reference : constant Identity.Text.Bounded.Bounded_Text :=
     Identity.Text.Bounded.From_String ("example-api-key");
   API_Key_Secret : constant Identity.Secrets.API_Keys.API_Key_Secret :=
     Identity.Secrets.Text.From_UTF_8 ("example-api-key-secret-material");
   API_Key_Class : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.service.api-key");

   --  Every operation below that changes stored state also writes an audit
   --  event, and refuses the change if that event cannot be stored. That is
   --  why each Execute takes three trailing arguments:
   --
   --    Context     - who is acting, plus the correlation that ties this
   --                  whole flow together in the audit trail. Build it once
   --                  and pass the same value to every call belonging to the
   --                  same unit of work; that is the recommended shape.
   --    Event       - the identifier of the audit record about to be written.
   --                  It must be fresh on every call: the store rejects a
   --                  duplicate identifier and the operation reports that
   --                  rejection as a failure.
   --    Recorded_At - the instant the audit record is stamped with.
   --
   --  This example acts as the system itself, so the actor is a system
   --  principal with no signed-in principal attached.

   Audit_Context : constant Identity.Operations.Contexts.Operation_Context :=
     (Operation =>
        Identity.Identifiers.Operations.Operation
          (Identity.Identifiers.From_String ("a0000000-0000-0000-0000-000000000001")),
      Correlation =>
        Identity.Identifiers.Operations.Correlation
          (Identity.Identifiers.From_String ("a0000000-0000-0000-0000-000000000002")),
      Causation => (Present => False),
      Request => (Present => False),
      Actor =>
        (Kind => Identity.Events.Envelopes.System_Principal,
         Principal => (Present => False)),
      Requested_At => 1,
      Deadline => (Present => False, Time_Point => 0),
      Cancellation => (State => Identity.Operations.Cancellation.Not_Cancelled),
      Disclosure => Identity.Operations.Disclosure.Untrusted_Interactive,
      Diagnostic_Mode => False);

   --  A real caller draws event identifiers from whatever generator it
   --  already uses for entity identifiers. A counter is enough here: all that
   --  matters is that no two audit records share an identifier.
   Audit_Event_Counter : Natural := 0;

   function Next_Audit_Event return Identity.Identifiers.Entities.Event_Id is
      Suffix : String (1 .. 12) := [others => '0'];
      Value : Natural;
   begin
      Audit_Event_Counter := Audit_Event_Counter + 1;
      Value := Audit_Event_Counter;
      for Position in reverse Suffix'Range loop
         Suffix (Position) := Character'Val (Character'Pos ('0') + Value rem 10);
         Value := Value / 10;
      end loop;

      return Identity.Identifiers.Entities.Event
        (Identity.Identifiers.From_String ("e0000000-0000-0000-0000-" & Suffix));
   end Next_Audit_Event;
begin
   Identity.Adapters.Repositories.Memory.Initialize (Store);

   if Identity.Operations.Principals.Create.Execute
        (Store,
         (Id => Principal,
          Kind => Identity.Principals.Kinds.Human,
          State => Identity.Principals.Definitions.Active,
          Version => 0),
         Audit_Context, Next_Audit_Event, 1)
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
          Version => 0),
         Audit_Context, Next_Audit_Event, 1)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Identities.Add.Execute
        (Store,
         (Id => Binding,
          Principal => Principal,
          Kind => Subject_Kind,
          Normalized => Subject,
          State => Identity.Identities.Bindings.Active,
          Version => 0),
         Audit_Context, Next_Audit_Event, 1)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Passwords.Enroll.Execute
        (Store, Principal, Credential, Password,
         Audit_Context, Next_Audit_Event, 1)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Passwords.Authenticate.Execute
        (Store, (Kind => Subject_Kind, Value => Subject), Presented,
         Audit_Context, Next_Audit_Event, 2).Status
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
            Generation => 0),
         Audit_Context, Next_Audit_Event, 2)
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
            Expected_Predecessor_Version => 0),
         Audit_Context, Next_Audit_Event, 3)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Sessions.Lookup.Execute
        (Store, Session_Reference, Session_Secret, 3).Status
      = Identity.Sessions.Handles.Revoked
      and then Identity.Operations.Sessions.Lookup.Execute
        (Store, Rotated_Session_Reference, Rotated_Session_Secret, 3).Status
      = Identity.Sessions.Handles.Found
      --  A wrong password is rejected without disturbing the account.
      and then Identity.Operations.Passwords.Authenticate.Execute
        (Store, (Kind => Subject_Kind, Value => Subject), Wrong_Presented,
         Audit_Context, Next_Audit_Event, 4).Status
      = Identity.Results.Rejected
      --  Revoking the family revokes the surviving rotated session.
      and then Identity.Operations.Sessions.Revoke_Family.Execute
        (Store, Family, Audit_Context, Next_Audit_Event, 4)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Sessions.Lookup.Execute
        (Store, Rotated_Session_Reference, Rotated_Session_Secret, 4).Status
      = Identity.Sessions.Handles.Revoked
      --  A service credential: issue an API key and authenticate with it
      --  (no session -- service auth returns an authenticated principal).
      and then Identity.Operations.API_Keys.Issue.Execute
        (Store,
         Identity.Operations.API_Keys.Issue.Issue_Request'
           (Id => API_Credential,
            Principal => Principal,
            Public_Key_Id => API_Key_Reference,
            Credential_Class_Id => API_Key_Class,
            Secret => API_Key_Secret,
            Created_At => 4,
            Expires_At => Identity.Times.Expirations.At_Time (9_000),
            Rotation_Generation => 0),
         Audit_Context, Next_Audit_Event, 4)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.API_Keys.Authenticate.Execute
        (Store, API_Key_Reference, API_Key_Secret, 5,
         Audit_Context, Next_Audit_Event, 5).Status
      = Identity.Results.Succeeded
      --  Administrative disablement blocks further authentication, and
      --  succeeding with the right password no longer works.
      and then Identity.Operations.Accounts.Disable.Execute
        (Store,
         (Account => Account,
          Principal => Principal,
          Transition =>
            (Actor =>
               (Kind => Identity.Events.Envelopes.Authenticated_Principal,
                Principal => (Present => True, Value => Principal)),
             Reason => Identity.Identifiers.Registry.From_String
               ("identity.account.disable"),
             Operation => Identity.Identifiers.Operations.Operation
               (Identity.Identifiers.From_String
                  ("70000000-0000-0000-0000-0000000000d1")),
             Correlation => Identity.Identifiers.Operations.Correlation
               (Identity.Identifiers.From_String
                  ("71000000-0000-0000-0000-0000000000d1")),
             Requested_At => 4,
             Expected_Version => 0,
             Previous_State => Identity.Accounts.States.Enabled,
             New_State => Identity.Accounts.States.Disabled,
             Mandatory_Audit => True)),
         Audit_Context, Next_Audit_Event, 4)
      = Identity.Adapters.Repositories.Memory.Applied
      and then Identity.Operations.Passwords.Authenticate.Execute
        (Store, (Kind => Subject_Kind, Value => Subject), Presented,
         Audit_Context, Next_Audit_Event, 5).Status
      = Identity.Results.Rejected
      --  Every transition above left an inspectable audit event.
      and then Identity.Adapters.Repositories.Memory.Event_Count (Store) > 0
   then
      Ada.Text_IO.Put_Line ("identity_lifecycle:ok");
   else
      Ada.Text_IO.Put_Line ("identity_lifecycle:failed");
      raise Program_Error;
   end if;
end Identity_Lifecycle;

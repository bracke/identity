with Ada.Directories;
with Ada.Streams.Stream_IO;
with Identity.API_Keys.Rotation;
with Identity.Credentials.Lifecycle;
with Identity.Credentials.States;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Principals.Lifecycle;
with Identity.Results;
with Identity.Sessions.Activity;
with Identity.Sessions.Expiration;
with Identity.Sessions.Rotation;
with Identity.Tokens.Purposes;

package body Identity.Adapters.Repositories.Memory is
   use type Identity.Credentials.States.Credential_State;
   use type Identity.External_Providers.Assertions.Assertion_Admission_Status;
   use type Identity.Identities.Bindings.Binding_State;
   use type Identity.Authentication.Transactions.Authentication_Transaction_State;
   use type Identity.Authentication.Challenges.Challenge_State;
   use type Identity.Authentication.Challenges.Challenge_Completion_Admission;
   use type Identity.Assurance.Levels.Assurance_Level;
   use type Identity.Contacts.Bindings.Contact_Binding_State;
   use type Identity.Operations.Idempotency.Idempotent_Operation_Kind;
   use type Identity.Principals.Definitions.Principal_Lifecycle;
   use type Identity.Recovery_Codes.Sets.Recovery_Code_State;
   use type Identity.Recovery.Transactions.Recovery_Transaction_State;
   use type Identity.Sessions.Activity.Activity_Admission_Status;
   use type Identity.Sessions.Expiration.Expiration_Status;
   use type Identity.Sessions.Definitions.Session_Revocation_State;
   use type Identity.Times.Instant;
   use type Identity.Tokens.Definitions.Token_State;
   use type Identity.Tokens.Verification.Token_Verification_Outcome;
   use type Identity.Versions.Attempt_Count;

   function Capabilities return Identity.Adapters.Repositories.Capabilities.Repository_Capabilities is
     (Identity.Adapters.Repositories.Capabilities.Full_Memory_Profile);

   procedure Save
     (Repository : Store;
      Path       : String;
      Status     : out Snapshot_Status)
   is
      --  Written to a sibling temporary and renamed into place. Writing over
      --  the live file truncates it first, so a process that stopped part way
      --  through left a half-written snapshot AND destroyed the previous one;
      --  the next Load then reported Malformed and yielded an empty store.
      --  A rename is atomic within a directory, so a reader sees either the
      --  old complete snapshot or the new one, never a partial file.
      Temp : constant String := Path & ".partial";
      File : Ada.Streams.Stream_IO.File_Type;
   begin
      Status := Unavailable;

      Ada.Streams.Stream_IO.Create
        (File, Ada.Streams.Stream_IO.Out_File, Temp);
      Store'Write (Ada.Streams.Stream_IO.Stream (File), Repository);
      Ada.Streams.Stream_IO.Close (File);

      begin
         Ada.Directories.Rename (Temp, Path);
      exception
         when others =>
            --  Ada.Directories.Rename rejects an existing target on some
            --  implementations. Replacing it directly is a narrower window
            --  than truncating the live file for the whole write.
            if Ada.Directories.Exists (Path) then
               Ada.Directories.Delete_File (Path);
            end if;
            Ada.Directories.Rename (Temp, Path);
      end;

      Status := Saved;
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         --  Leave the previous snapshot untouched; drop the partial file.
         if Ada.Directories.Exists (Temp) then
            begin
               Ada.Directories.Delete_File (Temp);
            exception
               when others => null;
            end;
         end if;
         Status := Unavailable;
   end Save;

   procedure Load
     (Repository : out Store;
      Path       : String;
      Status     : out Snapshot_Status)
   is
      File : Ada.Streams.Stream_IO.File_Type;
   begin
      Initialize (Repository);
      Status := Unavailable;

      if not Ada.Directories.Exists (Path) then
         return;
      end if;

      Ada.Streams.Stream_IO.Open
        (File, Ada.Streams.Stream_IO.In_File, Path);
      Store'Read (Ada.Streams.Stream_IO.Stream (File), Repository);
      Ada.Streams.Stream_IO.Close (File);
      Status := Loaded;
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         --  A truncated or foreign file must not leave a half-populated
         --  store behind: reset and say so.
         Initialize (Repository);
         Status := Malformed;
   end Load;

   overriding procedure Reset (Repository : in out Store) is
   begin
      Initialize (Repository);
   end Reset;

   --  Dispatching form: lets callers ask a Store_Interface'Class what it
   --  supports without knowing which adapter it is.
   overriding function Capabilities (Repository : Store)
      return Identity.Adapters.Repositories.Capabilities.Repository_Capabilities
   is
      pragma Unreferenced (Repository);
   begin
      return Capabilities;
   end Capabilities;

   --  Cleared component by component rather than by whole-record aggregate.
   --  A Store is a large fixed-capacity record, and an aggregate assignment
   --  builds a full-size temporary on the stack -- enough, with two stores
   --  live, to overflow the default stack before anything useful happens.
   procedure Initialize (Repository : out Store) is
   begin
      Repository.Principals := [others => (Present => False, Value => <>)];
      Repository.Accounts   := [others => (Present => False, Value => <>)];
      Repository.Bindings   := [others => (Present => False, Value => <>)];
      Repository.Passwords  := [others => (Present => False, Value => <>)];
      Repository.Sessions   := [others => (Present => False, Value => <>)];
      Repository.Tokens     := [others => (Present => False, Value => <>)];
      Repository.Authentication_Transactions :=
        [others => (Present => False, Value => <>)];
      Repository.Challenges := [others => (Present => False, Value => <>)];
      Repository.API_Keys   := [others => (Present => False, Value => <>)];
      Repository.Events     := [others => (Present => False, Value => <>)];
      Repository.Attempts   := [others => (Present => False, Value => <>)];
      Repository.Contact_Bindings := [others => (Present => False, Value => <>)];
      Repository.Contact_Verification_Links :=
        [others => (Present => False, Token => <>, Contact => <>)];
      Repository.Contact_Changes := [others => (Present => False, Value => <>)];
      Repository.Recovery_Code_Sets := [others => (Present => False, Value => <>)];
      Repository.Recovery_Transactions :=
        [others => (Present => False, Value => <>)];
      Repository.External_Bindings := [others => (Present => False, Value => <>)];
      Repository.External_Replays :=
        [others => (Present => False, Fingerprint => <>)];
      Repository.TOTP_Credentials := [others => (Present => False, Value => <>)];
      Repository.Idempotency :=
        [others =>
           (Present => False,
            Operation => Identity.Operations.Idempotency.Password_Reset_Request,
            Key => Identity.Operations.Idempotency.From_String (""),
            Completed => False,
            Version => 0)];
   end Initialize;

   function Same_Principal
     (Left, Right : Identity.Identifiers.Entities.Principal_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Account
     (Left, Right : Identity.Identifiers.Entities.Account_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Binding
     (Left, Right : Identity.Identifiers.Entities.Identity_Binding_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Credential
     (Left, Right : Identity.Identifiers.Entities.Credential_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Credential_Set
     (Left, Right : Identity.Identifiers.Entities.Credential_Set_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Session
     (Left, Right : Identity.Identifiers.Entities.Session_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Family
     (Left, Right : Identity.Identifiers.Entities.Session_Family_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Token
     (Left, Right : Identity.Identifiers.Entities.Token_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Contact
     (Left, Right : Identity.Identifiers.Entities.Contact_Binding_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Event
     (Left, Right : Identity.Identifiers.Entities.Event_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Transaction
     (Left, Right : Identity.Identifiers.Entities.Authentication_Transaction_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Challenge
     (Left, Right : Identity.Identifiers.Entities.Challenge_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_External_Binding
     (Left, Right : Identity.Identifiers.Entities.External_Binding_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Attempt
     (Left, Right : Identity.Identifiers.Entities.Attempt_Id) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left)
      = Identity.Identifiers.Entities.To_String (Right));

   function Same_Kind
     (Left, Right : Identity.Identifiers.Registry.Registry_Id) return Boolean is
     (Identity.Identifiers.Registry.Image (Left) = Identity.Identifiers.Registry.Image (Right));

   function Domain_For_Purpose
     (Purpose : Identity.Identifiers.Registry.Registry_Id) return Identity.Identifiers.Registry.Registry_Id is
   begin
      if Same_Kind (Purpose, Identity.Tokens.Purposes.Contact_Verification)
        or else Same_Kind (Purpose, Identity.Tokens.Purposes.Contact_Change)
      then
         return Identity.Crypto.Domains.Contact_Verification_Token;
      else
         return Identity.Crypto.Domains.Password_Reset_Token;
      end if;
   end Domain_For_Purpose;

   function Principal_Exists
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Boolean is
   begin
      for Slot of Repository.Principals loop
         if Slot.Present and then Same_Principal (Slot.Value.Id, Principal) then
            return True;
         end if;
      end loop;
      return False;
   end Principal_Exists;

   function Principal_Is_Active
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Boolean is
   begin
      for Slot of Repository.Principals loop
         if Slot.Present and then Same_Principal (Slot.Value.Id, Principal) then
            return Identity.Principals.Lifecycle.Active (Slot.Value.State);
         end if;
      end loop;
      return False;
   end Principal_Is_Active;

   overriding function Create_Principal
     (Repository : in out Store;
      Principal  : Identity.Principals.Definitions.Principal_Record) return Command_Status
   is
   begin
      if Principal_Exists (Repository, Principal.Id) then
         return Uniqueness_Conflict;
      end if;

      for Slot of Repository.Principals loop
         if not Slot.Present then
            Slot := (Present => True, Value => Principal);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Create_Principal;

   overriding function Retire_Principal
     (Repository : in out Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status
   is
   begin
      for Slot of Repository.Principals loop
         if Slot.Present and then Same_Principal (Slot.Value.Id, Principal) then
            if not Identity.Principals.Lifecycle.May_Retire (Slot.Value.State) then
               return State_Conflict;
            end if;

            Slot.Value.State := Identity.Principals.Definitions.Retired;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Retire_Principal;

   overriding function Retire_Principal
     (Repository       : in out Store;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version) return Command_Status
   is
   begin
      for Slot of Repository.Principals loop
         if Slot.Present and then Same_Principal (Slot.Value.Id, Principal) then
            if not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return Version_Conflict;
            elsif not Identity.Principals.Lifecycle.May_Retire (Slot.Value.State) then
               return State_Conflict;
            end if;

            Slot.Value.State := Identity.Principals.Definitions.Retired;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Retire_Principal;

   overriding function Create_Account
     (Repository : in out Store;
      Account    : Identity.Accounts.Definitions.Account_Record) return Command_Status
   is
   begin
      if not Principal_Exists (Repository, Account.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.Accounts loop
         if Slot.Present and then Same_Account (Slot.Value.Id, Account.Id) then
            return Uniqueness_Conflict;
         end if;
      end loop;

      for Slot of Repository.Accounts loop
         if not Slot.Present then
            Slot := (Present => True, Value => Account);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Create_Account;

   overriding function Update_Account_State
     (Repository : in out Store;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      State      : Identity.Accounts.States.Account_State_View)
      return Command_Status
   is
   begin
      for Slot of Repository.Accounts loop
         if Slot.Present and then Same_Account (Slot.Value.Id, Account) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return State_Conflict;
            end if;

            Slot.Value.State := State;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Update_Account_State;

   overriding function Add_Binding
     (Repository : in out Store;
      Binding    : Identity.Identities.Bindings.Binding_Record) return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Binding.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.Bindings loop
         if Slot.Present then
            if Same_Binding (Slot.Value.Id, Binding.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Identities.Bindings.Same_Active_Subject (Slot.Value, Binding)
            then
               return Uniqueness_Conflict;
            end if;
         end if;
      end loop;

      for Slot of Repository.Bindings loop
         if not Slot.Present then
            Slot := (Present => True, Value => Binding);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Add_Binding;

   overriding function Revoke_Binding
     (Repository : in out Store;
      Binding    : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status
   is
   begin
      for Slot of Repository.Bindings loop
         if Slot.Present and then Same_Binding (Slot.Value.Id, Binding) then
            return Revoke_Binding (Repository, Binding, Principal, Slot.Value.Version);
         end if;
      end loop;

      return State_Conflict;
   end Revoke_Binding;

   overriding function Revoke_Binding
     (Repository               : in out Store;
      Binding                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Command_Status
   is
      use type Identity.Versions.Entity_Version;
   begin
      for Slot of Repository.Bindings loop
         if Slot.Present and then Same_Binding (Slot.Value.Id, Binding) then
            if Slot.Value.Version /= Expected_Binding_Version then
               return Version_Conflict;
            elsif not Same_Principal (Slot.Value.Principal, Principal) then
               return State_Conflict;
            elsif not Identity.Identities.Bindings.Can_Revoke (Slot.Value.State) then
               return State_Conflict;
            end if;

            Slot.Value.State := Identity.Identities.Bindings.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Revoke_Binding;

   overriding function Change_Binding
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record) return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Successor.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Bindings'Range loop
         if Repository.Bindings (Index).Present then
            if Same_Binding (Repository.Bindings (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Binding (Repository.Bindings (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Identities.Bindings.Same_Active_Subject
                (Repository.Bindings (Index).Value, Successor)
              and then not Same_Binding (Repository.Bindings (Index).Value.Id, Predecessor)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 then
         return State_Conflict;
      elsif Free_Index = 0 then
         return Capacity_Conflict;
      elsif not Identity.Identities.Bindings.Can_Replace
        (Repository.Bindings (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      elsif not Same_Principal
        (Repository.Bindings (Predecessor_Index).Value.Principal, Successor.Principal)
      then
         return State_Conflict;
      elsif not Identity.Identities.Bindings.Usable_For_Resolution (Successor.State) then
         return State_Conflict;
      end if;

      Repository.Bindings (Predecessor_Index).Value.State := Identity.Identities.Bindings.Revoked;
      Repository.Bindings (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Bindings (Predecessor_Index).Value.Version);
      Repository.Bindings (Free_Index) := (Present => True, Value => Successor);
      return Applied;
   end Change_Binding;

   overriding function Change_Binding
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Identities.Bindings.Binding_Record) return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Successor.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Bindings'Range loop
         if Repository.Bindings (Index).Present then
            if Same_Binding (Repository.Bindings (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Binding (Repository.Bindings (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Identities.Bindings.Same_Active_Subject
                (Repository.Bindings (Index).Value, Successor)
              and then not Same_Binding (Repository.Bindings (Index).Value.Id, Predecessor)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 then
         return State_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Bindings (Predecessor_Index).Value.Version,
         Expected_Predecessor_Version)
      then
         return Version_Conflict;
      elsif Free_Index = 0 then
         return Capacity_Conflict;
      elsif not Identity.Identities.Bindings.Can_Replace
        (Repository.Bindings (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      elsif not Same_Principal
        (Repository.Bindings (Predecessor_Index).Value.Principal, Successor.Principal)
      then
         return State_Conflict;
      elsif not Identity.Identities.Bindings.Usable_For_Resolution (Successor.State) then
         return State_Conflict;
      end if;

      Repository.Bindings (Predecessor_Index).Value.State := Identity.Identities.Bindings.Revoked;
      Repository.Bindings (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Bindings (Predecessor_Index).Value.Version);
      Repository.Bindings (Free_Index) := (Present => True, Value => Successor);
      return Applied;
   end Change_Binding;

   overriding function Enroll_Password
     (Repository : in out Store;
      Credential : Identity.Passwords.Credentials.Password_Credential_Record) return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Credential.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.Passwords loop
         if Slot.Present then
            if Same_Credential (Slot.Value.Id, Credential.Id) then
               return Uniqueness_Conflict;
            end if;

            if Same_Principal (Slot.Value.Principal, Credential.Principal)
              and then Identity.Credentials.Lifecycle.Occupies_Active_Slot (Slot.Value.State)
              and then Identity.Credentials.Lifecycle.Can_Issue_As_Active (Credential.State)
            then
               return State_Conflict;
            end if;
         end if;
      end loop;

      for Slot of Repository.Passwords loop
         if not Slot.Present then
            Slot := (Present => True, Value => Credential);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Enroll_Password;

   overriding function Replace_Password
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.Passwords.Credentials.Password_Credential_Record)
      return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Successor.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Passwords'Range loop
         if Repository.Passwords (Index).Present then
            if Same_Credential (Repository.Passwords (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Credential (Repository.Passwords (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Same_Principal (Repository.Passwords (Index).Value.Principal, Successor.Principal)
              and then Identity.Credentials.Lifecycle.Occupies_Active_Slot
                (Repository.Passwords (Index).Value.State)
              and then not Same_Credential (Repository.Passwords (Index).Value.Id, Predecessor)
            then
               return State_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 then
         return State_Conflict;
      elsif Free_Index = 0 then
         return Capacity_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Predecessor
        (Repository.Passwords (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      elsif not Same_Principal
        (Repository.Passwords (Predecessor_Index).Value.Principal, Successor.Principal)
      then
         return State_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Successor (Successor.State) then
         return State_Conflict;
      end if;

      Repository.Passwords (Predecessor_Index).Value.State := Identity.Credentials.States.Retired;
      Repository.Passwords (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Passwords (Predecessor_Index).Value.Version);
      Repository.Passwords (Free_Index) := (Present => True, Value => Successor);
      return Applied;
   end Replace_Password;

   overriding function Replace_Password
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Successor.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Passwords'Range loop
         if Repository.Passwords (Index).Present then
            if Same_Credential (Repository.Passwords (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Credential (Repository.Passwords (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Same_Principal (Repository.Passwords (Index).Value.Principal, Successor.Principal)
              and then Identity.Credentials.Lifecycle.Occupies_Active_Slot
                (Repository.Passwords (Index).Value.State)
              and then not Same_Credential (Repository.Passwords (Index).Value.Id, Predecessor)
            then
               return State_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 then
         return State_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Passwords (Predecessor_Index).Value.Version,
         Expected_Predecessor_Version)
      then
         return Version_Conflict;
      elsif Free_Index = 0 then
         return Capacity_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Predecessor
        (Repository.Passwords (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      elsif not Same_Principal
        (Repository.Passwords (Predecessor_Index).Value.Principal, Successor.Principal)
      then
         return State_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Successor (Successor.State) then
         return State_Conflict;
      end if;

      Repository.Passwords (Predecessor_Index).Value.State := Identity.Credentials.States.Retired;
      Repository.Passwords (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Passwords (Predecessor_Index).Value.Version);
      Repository.Passwords (Free_Index) := (Present => True, Value => Successor);
      return Applied;
   end Replace_Password;

   overriding function Create_Session
     (Repository : in out Store;
      Session    : Identity.Sessions.Definitions.Session_Record) return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Session.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.Sessions loop
         if Slot.Present then
            if Same_Session (Slot.Value.Id, Session.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Sessions.Definitions.Same_Public_Reference (Slot.Value, Session) then
               return Uniqueness_Conflict;
            end if;
         end if;
      end loop;

      for Slot of Repository.Sessions loop
         if not Slot.Present then
            Slot := (Present => True, Value => Session);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Create_Session;

   overriding procedure Find_Session
     (Repository : Store;
      Session    : Identity.Identifiers.Entities.Session_Id;
      Found      : out Boolean;
      Value      : out Identity.Sessions.Definitions.Session_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Sessions loop
         if Slot.Present and then Same_Session (Slot.Value.Id, Session) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Session;

   overriding function Revoke_Session
     (Repository : in out Store;
      Session    : Identity.Identifiers.Entities.Session_Id) return Command_Status
   is
      Found : Boolean;
      Value : Identity.Sessions.Definitions.Session_Record;
   begin
      Find_Session (Repository, Session, Found, Value);
      if not Found then
         return State_Conflict;
      end if;

      return Revoke_Session (Repository, Session, Value.Version);
   end Revoke_Session;

   overriding function Revoke_Session
     (Repository               : in out Store;
      Session                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Session_Version : Identity.Versions.Entity_Version) return Command_Status
   is
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present and then Same_Session (Slot.Value.Id, Session) then
            if not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Session_Version)
            then
               return Version_Conflict;
            elsif not Identity.Sessions.Definitions.Is_Active (Slot.Value.State) then
               return State_Conflict;
            end if;
            Slot.Value.State := Identity.Sessions.Definitions.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Revoke_Session;

   overriding function Rotate_Session
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record) return Command_Status
   is
      Found : Boolean;
      Value : Identity.Sessions.Definitions.Session_Record;
   begin
      Find_Session (Repository, Predecessor, Found, Value);
      if not Found then
         return State_Conflict;
      end if;

      return Rotate_Session (Repository, Predecessor, Value.Version, Successor);
   end Rotate_Session;

   overriding function Rotate_Session
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Sessions.Definitions.Session_Record) return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Successor.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Sessions'Range loop
         if Repository.Sessions (Index).Present then
            if Same_Session (Repository.Sessions (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Session (Repository.Sessions (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Sessions.Definitions.Same_Public_Reference
              (Repository.Sessions (Index).Value, Successor)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 or else Free_Index = 0 then
         if Predecessor_Index = 0 then
            return State_Conflict;
         else
            return Capacity_Conflict;
         end if;
      end if;

      if not Identity.Versions.Same_Entity_Version
        (Repository.Sessions (Predecessor_Index).Value.Version,
         Expected_Predecessor_Version)
      then
         return Version_Conflict;
      elsif not Identity.Sessions.Definitions.Is_Active
        (Repository.Sessions (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      elsif not Same_Principal
        (Repository.Sessions (Predecessor_Index).Value.Principal, Successor.Principal)
      then
         return State_Conflict;
      elsif Identity.Identifiers.Entities.To_String
        (Repository.Sessions (Predecessor_Index).Value.Family)
        /= Identity.Identifiers.Entities.To_String (Successor.Family)
      then
         return State_Conflict;
      elsif not Identity.Sessions.Definitions.Is_Active (Successor.State) then
         return State_Conflict;
      elsif not Identity.Sessions.Rotation.Matches_Successor_Generation
        (Repository.Sessions (Predecessor_Index).Value, Successor)
      then
         return Version_Conflict;
      end if;

      Repository.Sessions (Predecessor_Index).Value.State := Identity.Sessions.Definitions.Rotated;
      Repository.Sessions (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Sessions (Predecessor_Index).Value.Version);
      Repository.Sessions (Free_Index) := (Present => True, Value => Successor);
      return Applied;
   end Rotate_Session;

   overriding function Revoke_Session_Family
     (Repository : in out Store;
      Family     : Identity.Identifiers.Entities.Session_Family_Id) return Command_Status
   is
      Changed : Boolean := False;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Same_Family (Slot.Value.Family, Family)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Slot.Value.State := Identity.Sessions.Definitions.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            Changed := True;
         end if;
      end loop;

      if Changed then
         return Applied;
      else
         return State_Conflict;
      end if;
   end Revoke_Session_Family;

   overriding function Revoke_Session_Family
     (Repository              : in out Store;
      Family                  : Identity.Identifiers.Entities.Session_Family_Id;
      Expected_Affected_Count : Natural) return Command_Status
   is
      Actual_Affected_Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Same_Family (Slot.Value.Family, Family)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Actual_Affected_Count := Actual_Affected_Count + 1;
         end if;
      end loop;

      if Actual_Affected_Count /= Expected_Affected_Count then
         return Version_Conflict;
      elsif Actual_Affected_Count = 0 then
         return State_Conflict;
      end if;

      return Revoke_Session_Family (Repository, Family);
   end Revoke_Session_Family;

   overriding function Revoke_Principal_Sessions
     (Repository : in out Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status
   is
      Changed : Boolean := False;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Same_Principal (Slot.Value.Principal, Principal)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Slot.Value.State := Identity.Sessions.Definitions.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            Changed := True;
         end if;
      end loop;

      if Changed then
         return Applied;
      else
         return State_Conflict;
      end if;
   end Revoke_Principal_Sessions;

   overriding function Revoke_Principal_Sessions
     (Repository              : in out Store;
      Principal               : Identity.Identifiers.Entities.Principal_Id;
      Expected_Affected_Count : Natural) return Command_Status
   is
      Actual_Affected_Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Same_Principal (Slot.Value.Principal, Principal)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Actual_Affected_Count := Actual_Affected_Count + 1;
         end if;
      end loop;

      if Actual_Affected_Count /= Expected_Affected_Count then
         return Version_Conflict;
      elsif Actual_Affected_Count = 0 then
         return State_Conflict;
      end if;

      return Revoke_Principal_Sessions (Repository, Principal);
   end Revoke_Principal_Sessions;

   overriding function Revoke_Credential_Sessions
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Command_Status
   is
      Changed : Boolean := False;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Slot.Value.Credential.Present
           and then Same_Credential (Slot.Value.Credential.Value, Credential)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Slot.Value.State := Identity.Sessions.Definitions.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            Changed := True;
         end if;
      end loop;

      if Changed then
         return Applied;
      else
         return State_Conflict;
      end if;
   end Revoke_Credential_Sessions;

   overriding function Revoke_Credential_Sessions
     (Repository              : in out Store;
      Credential              : Identity.Identifiers.Entities.Credential_Id;
      Expected_Affected_Count : Natural) return Command_Status
   is
      Actual_Affected_Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Slot.Value.Credential.Present
           and then Same_Credential (Slot.Value.Credential.Value, Credential)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Actual_Affected_Count := Actual_Affected_Count + 1;
         end if;
      end loop;

      if Actual_Affected_Count /= Expected_Affected_Count then
         return Version_Conflict;
      elsif Actual_Affected_Count = 0 then
         return State_Conflict;
      end if;

      return Revoke_Credential_Sessions (Repository, Credential);
   end Revoke_Credential_Sessions;

   overriding function Revoke_Provider_Sessions
     (Repository : in out Store;
      Provider   : Identity.Identifiers.Entities.External_Provider_Id) return Command_Status
   is
      Changed : Boolean := False;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Slot.Value.External_Provider.Present
           and then Identity.Identifiers.Entities.To_String (Slot.Value.External_Provider.Value)
             = Identity.Identifiers.Entities.To_String (Provider)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Slot.Value.State := Identity.Sessions.Definitions.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            Changed := True;
         end if;
      end loop;

      if Changed then
         return Applied;
      else
         return State_Conflict;
      end if;
   end Revoke_Provider_Sessions;

   overriding function Revoke_Provider_Sessions
     (Repository              : in out Store;
      Provider                : Identity.Identifiers.Entities.External_Provider_Id;
      Expected_Affected_Count : Natural) return Command_Status
   is
      Actual_Affected_Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Slot.Value.External_Provider.Present
           and then Identity.Identifiers.Entities.To_String (Slot.Value.External_Provider.Value)
             = Identity.Identifiers.Entities.To_String (Provider)
           and then Identity.Sessions.Definitions.Can_Revoke (Slot.Value.State)
         then
            Actual_Affected_Count := Actual_Affected_Count + 1;
         end if;
      end loop;

      if Actual_Affected_Count /= Expected_Affected_Count then
         return Version_Conflict;
      elsif Actual_Affected_Count = 0 then
         return State_Conflict;
      end if;

      return Revoke_Provider_Sessions (Repository, Provider);
   end Revoke_Provider_Sessions;

   overriding function Expire_Eligible_Sessions
     (Repository : in out Store;
      Now        : Identity.Times.Instant) return Natural
   is
      Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Identity.Sessions.Expiration.Evaluate (Slot.Value, Now)
             in Identity.Sessions.Expiration.Idle_Expired
              | Identity.Sessions.Expiration.Absolute_Expired
         then
            Slot.Value.State := Identity.Sessions.Definitions.Expired;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Expire_Eligible_Sessions;

   overriding function Purge_Retained_Sessions
     (Repository : in out Store;
      Retain_After : Identity.Times.Instant) return Natural
   is
      Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Identity.Sessions.Definitions.Retainable (Slot.Value.State)
           and then Slot.Value.Last_Seen_At <= Retain_After
         then
            Slot.Present := False;
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Purge_Retained_Sessions;

   overriding function Enumerate_Principal_Sessions
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List
   is
      Result : Identity.Projections.Sessions.Session_Summary_List;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Same_Principal (Slot.Value.Principal, Principal)
           and then Result.Count < Identity.Projections.Sessions.Max_Session_Summaries
         then
            Result.Count := Result.Count + 1;
            Result.Items (Result.Count) :=
              Identity.Projections.Sessions.Summary (Slot.Value);
         end if;
      end loop;

      return Result;
   end Enumerate_Principal_Sessions;

   overriding function Issue_Token
     (Repository : in out Store;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status
   is
      Free_Index : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Token.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Same_Token (Repository.Tokens (Index).Value.Id, Token.Id)
         then
            return Uniqueness_Conflict;
         elsif not Repository.Tokens (Index).Present and then Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Free_Index = 0 then
         return Capacity_Conflict;
      end if;

      if Identity.Tokens.Definitions.Purpose_Matches
        (Token, Identity.Tokens.Purposes.Password_Reset)
      then
         for Index in Repository.Tokens'Range loop
            if Repository.Tokens (Index).Present
              and then Same_Principal (Repository.Tokens (Index).Value.Principal, Token.Principal)
              and then Identity.Tokens.Definitions.Purpose_Matches
                (Repository.Tokens (Index).Value, Identity.Tokens.Purposes.Password_Reset)
              and then Repository.Tokens (Index).Value.State in
                Identity.Tokens.Definitions.Issued
                | Identity.Tokens.Definitions.Presented
                | Identity.Tokens.Definitions.Verified
            then
               Repository.Tokens (Index).Value.State := Identity.Tokens.Definitions.Superseded;
               Repository.Tokens (Index).Value.Version :=
                 Identity.Versions.Next_Entity_Version
                   (Repository.Tokens (Index).Value.Version);
            end if;
         end loop;
      end if;

      Repository.Tokens (Free_Index) := (Present => True, Value => Token);
      return Applied;
   end Issue_Token;

   overriding procedure Find_Token
     (Repository : Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Found      : out Boolean;
      Value      : out Identity.Tokens.Definitions.Action_Token_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Tokens loop
         if Slot.Present and then Same_Token (Slot.Value.Id, Token) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Token;

   overriding function Begin_Authentication_Transaction
     (Repository  : in out Store;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      if not Principal_Is_Active (Repository, Transaction.Principal)
        or else not Identity.Authentication.Transactions.Can_Begin (Transaction.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Slot of Repository.Authentication_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction.Id) then
            return Identity.Authentication.Transactions.Version_Conflict;
         end if;
      end loop;

      for Slot of Repository.Authentication_Transactions loop
         if not Slot.Present then
            Slot :=
              (Present => True,
               Value   =>
                 (Id => Transaction.Id,
                  Principal => Transaction.Principal,
                  Requested_Profile => Transaction.Requested_Profile,
                  Created_At => Transaction.Created_At,
                  Expires_At => Transaction.Expires_At,
                  State => Identity.Authentication.Transactions.Additional_Factor_Required,
                  Attempts => Transaction.Attempts,
                  Evidence_Count => Transaction.Evidence_Count,
                  Version => Identity.Versions.Next_Entity_Version
                    (Transaction.Version)));
            return Identity.Authentication.Transactions.Applied;
         end if;
      end loop;

      return Identity.Authentication.Transactions.Capacity_Conflict;
   end Begin_Authentication_Transaction;

   overriding function Issue_Challenge
     (Repository : in out Store;
      Challenge  : Identity.Authentication.Challenges.Challenge_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Transaction_Index : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Challenge.Principal)
        or else not Identity.Authentication.Challenges.Can_Issue (Challenge.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Index in Repository.Authentication_Transactions'Range loop
         if Repository.Authentication_Transactions (Index).Present
           and then Same_Transaction
             (Repository.Authentication_Transactions (Index).Value.Id, Challenge.Transaction)
         then
            Transaction_Index := Index;
            exit;
         end if;
      end loop;

      if Transaction_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal
        (Repository.Authentication_Transactions (Transaction_Index).Value.Principal,
         Challenge.Principal)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif not Identity.Authentication.Transactions.Can_Issue_Challenge
        (Repository.Authentication_Transactions (Transaction_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Slot of Repository.Challenges loop
         if Slot.Present and then Same_Challenge (Slot.Value.Id, Challenge.Id) then
            return Identity.Authentication.Transactions.Version_Conflict;
         end if;
      end loop;

      for Slot of Repository.Challenges loop
         if not Slot.Present then
            Slot := (Present => True, Value => Challenge);
            Repository.Authentication_Transactions (Transaction_Index).Value.State :=
              Identity.Authentication.Transactions.Challenge_Issued;
            Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
              Identity.Versions.Next_Entity_Version
                (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
            return Identity.Authentication.Transactions.Applied;
         end if;
      end loop;

      return Identity.Authentication.Transactions.Capacity_Conflict;
   end Issue_Challenge;

   overriding function Issue_Challenge
     (Repository                   : in out Store;
      Challenge                    : Identity.Authentication.Challenges.Challenge_Record;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Transaction_Index : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Challenge.Principal)
        or else not Identity.Authentication.Challenges.Can_Issue (Challenge.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Index in Repository.Authentication_Transactions'Range loop
         if Repository.Authentication_Transactions (Index).Present
           and then Same_Transaction
             (Repository.Authentication_Transactions (Index).Value.Id, Challenge.Transaction)
         then
            Transaction_Index := Index;
            exit;
         end if;
      end loop;

      if Transaction_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal
        (Repository.Authentication_Transactions (Transaction_Index).Value.Principal,
         Challenge.Principal)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Authentication_Transactions (Transaction_Index).Value.Version,
         Expected_Transaction_Version)
      then
         return Identity.Authentication.Transactions.Version_Conflict;
      elsif not Identity.Authentication.Transactions.Can_Issue_Challenge
        (Repository.Authentication_Transactions (Transaction_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Slot of Repository.Challenges loop
         if Slot.Present and then Same_Challenge (Slot.Value.Id, Challenge.Id) then
            return Identity.Authentication.Transactions.Version_Conflict;
         end if;
      end loop;

      for Slot of Repository.Challenges loop
         if not Slot.Present then
            Slot := (Present => True, Value => Challenge);
            Repository.Authentication_Transactions (Transaction_Index).Value.State :=
              Identity.Authentication.Transactions.Challenge_Issued;
            Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
              Identity.Versions.Next_Entity_Version
                (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
            return Identity.Authentication.Transactions.Applied;
         end if;
      end loop;

      return Identity.Authentication.Transactions.Capacity_Conflict;
   end Issue_Challenge;

   overriding function Complete_Challenge
     (Repository : in out Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Challenge_Index    : Natural := 0;
      Transaction_Index  : Natural := 0;
      Admission          : Identity.Authentication.Challenges.Challenge_Completion_Admission;
   begin
      for Index in Repository.Challenges'Range loop
         if Repository.Challenges (Index).Present
           and then Same_Challenge (Repository.Challenges (Index).Value.Id, Challenge)
         then
            Challenge_Index := Index;
            exit;
         end if;
      end loop;

      if Challenge_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal (Repository.Challenges (Challenge_Index).Value.Principal, Principal)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      Admission := Identity.Authentication.Challenges.Admit_Completion
        (Repository.Challenges (Challenge_Index).Value, Now);

      if Admission = Identity.Authentication.Challenges.Expired_By_Time then
         Repository.Challenges (Challenge_Index).Value.State := Identity.Authentication.Challenges.Expired;
         Repository.Challenges (Challenge_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Challenges (Challenge_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Admission /= Identity.Authentication.Challenges.Admitted
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Index in Repository.Authentication_Transactions'Range loop
         if Repository.Authentication_Transactions (Index).Present
           and then Same_Transaction
             (Repository.Authentication_Transactions (Index).Value.Id,
              Repository.Challenges (Challenge_Index).Value.Transaction)
         then
            Transaction_Index := Index;
            exit;
         end if;
      end loop;

      if Transaction_Index = 0
        or else not Same_Principal
          (Repository.Authentication_Transactions (Transaction_Index).Value.Principal, Principal)
        or else not Identity.Authentication.Transactions.Can_Complete_Challenge
          (Repository.Authentication_Transactions (Transaction_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Identity.Authentication.Transactions.Expired_At
        (Repository.Authentication_Transactions (Transaction_Index).Value, Now)
      then
         Repository.Authentication_Transactions (Transaction_Index).Value.State :=
           Identity.Authentication.Transactions.Expired;
         Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      Repository.Challenges (Challenge_Index).Value.State := Identity.Authentication.Challenges.Completed;
      Repository.Challenges (Challenge_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Challenges (Challenge_Index).Value.Version);
      Repository.Authentication_Transactions (Transaction_Index).Value.State :=
        Identity.Authentication.Transactions.Challenge_Completed;
      Repository.Authentication_Transactions (Transaction_Index).Value.Evidence_Count :=
        Repository.Authentication_Transactions (Transaction_Index).Value.Evidence_Count + 1;
      Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
      return Identity.Authentication.Transactions.Applied;
   end Complete_Challenge;

   overriding function Complete_Challenge
     (Repository                   : in out Store;
      Challenge                    : Identity.Identifiers.Entities.Challenge_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Challenge_Version   : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Challenge_Index    : Natural := 0;
      Transaction_Index  : Natural := 0;
      Admission          : Identity.Authentication.Challenges.Challenge_Completion_Admission;
   begin
      for Index in Repository.Challenges'Range loop
         if Repository.Challenges (Index).Present
           and then Same_Challenge (Repository.Challenges (Index).Value.Id, Challenge)
         then
            Challenge_Index := Index;
            exit;
         end if;
      end loop;

      if Challenge_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal (Repository.Challenges (Challenge_Index).Value.Principal, Principal)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Index in Repository.Authentication_Transactions'Range loop
         if Repository.Authentication_Transactions (Index).Present
           and then Same_Transaction
             (Repository.Authentication_Transactions (Index).Value.Id,
              Repository.Challenges (Challenge_Index).Value.Transaction)
         then
            Transaction_Index := Index;
            exit;
         end if;
      end loop;

      if Transaction_Index = 0
        or else not Same_Principal
          (Repository.Authentication_Transactions (Transaction_Index).Value.Principal, Principal)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Challenges (Challenge_Index).Value.Version,
         Expected_Challenge_Version)
        or else not Identity.Versions.Same_Entity_Version
          (Repository.Authentication_Transactions (Transaction_Index).Value.Version,
           Expected_Transaction_Version)
      then
         return Identity.Authentication.Transactions.Version_Conflict;
      end if;

      Admission := Identity.Authentication.Challenges.Admit_Completion
        (Repository.Challenges (Challenge_Index).Value, Now);

      if Admission = Identity.Authentication.Challenges.Expired_By_Time then
         Repository.Challenges (Challenge_Index).Value.State := Identity.Authentication.Challenges.Expired;
         Repository.Challenges (Challenge_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Challenges (Challenge_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Admission /= Identity.Authentication.Challenges.Admitted
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif not Identity.Authentication.Transactions.Can_Complete_Challenge
        (Repository.Authentication_Transactions (Transaction_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Identity.Authentication.Transactions.Expired_At
        (Repository.Authentication_Transactions (Transaction_Index).Value, Now)
      then
         Repository.Authentication_Transactions (Transaction_Index).Value.State :=
           Identity.Authentication.Transactions.Expired;
         Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      Repository.Challenges (Challenge_Index).Value.State := Identity.Authentication.Challenges.Completed;
      Repository.Challenges (Challenge_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Challenges (Challenge_Index).Value.Version);
      Repository.Authentication_Transactions (Transaction_Index).Value.State :=
        Identity.Authentication.Transactions.Challenge_Completed;
      Repository.Authentication_Transactions (Transaction_Index).Value.Evidence_Count :=
        Repository.Authentication_Transactions (Transaction_Index).Value.Evidence_Count + 1;
      Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
      return Identity.Authentication.Transactions.Applied;
   end Complete_Challenge;

   overriding function Satisfy_Authentication_Transaction
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      for Slot of Repository.Authentication_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return Identity.Authentication.Transactions.State_Conflict;
            elsif Identity.Authentication.Transactions.Expired_At (Slot.Value, Now) then
               Slot.Value.State := Identity.Authentication.Transactions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return Identity.Authentication.Transactions.State_Conflict;
            elsif not Identity.Authentication.Transactions.Can_Satisfy (Slot.Value)
            then
               return Identity.Authentication.Transactions.State_Conflict;
            end if;

            Slot.Value.State := Identity.Authentication.Transactions.Satisfied;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Authentication.Transactions.Applied;
         end if;
      end loop;

      return Identity.Authentication.Transactions.Unknown;
   end Satisfy_Authentication_Transaction;

   overriding function Satisfy_Authentication_Transaction
     (Repository          : in out Store;
      Transaction         : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Now                 : Identity.Times.Instant;
      Expected_Version    : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      for Slot of Repository.Authentication_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return Identity.Authentication.Transactions.State_Conflict;
            elsif not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return Identity.Authentication.Transactions.Version_Conflict;
            elsif Identity.Authentication.Transactions.Expired_At (Slot.Value, Now) then
               Slot.Value.State := Identity.Authentication.Transactions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return Identity.Authentication.Transactions.State_Conflict;
            elsif not Identity.Authentication.Transactions.Can_Satisfy (Slot.Value)
            then
               return Identity.Authentication.Transactions.State_Conflict;
            end if;

            Slot.Value.State := Identity.Authentication.Transactions.Satisfied;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Authentication.Transactions.Applied;
         end if;
      end loop;

      return Identity.Authentication.Transactions.Unknown;
   end Satisfy_Authentication_Transaction;

   overriding function Upgrade_Session_Assurance
     (Repository  : in out Store;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Session_Index     : Natural := 0;
      Transaction_Index : Natural := 0;
   begin
      for Index in Repository.Sessions'Range loop
         if Repository.Sessions (Index).Present
           and then Same_Session (Repository.Sessions (Index).Value.Id, Session)
         then
            Session_Index := Index;
            exit;
         end if;
      end loop;

      if Session_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal (Repository.Sessions (Session_Index).Value.Principal, Principal)
        or else not Identity.Sessions.Definitions.Is_Active
          (Repository.Sessions (Session_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Identity.Sessions.Expiration.Evaluate
        (Repository.Sessions (Session_Index).Value, Now)
          in Identity.Sessions.Expiration.Idle_Expired
           | Identity.Sessions.Expiration.Absolute_Expired
      then
         Repository.Sessions (Session_Index).Value.State := Identity.Sessions.Definitions.Expired;
         Repository.Sessions (Session_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Sessions (Session_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Index in Repository.Authentication_Transactions'Range loop
         if Repository.Authentication_Transactions (Index).Present
           and then Same_Transaction
             (Repository.Authentication_Transactions (Index).Value.Id, Transaction)
         then
            Transaction_Index := Index;
            exit;
         end if;
      end loop;

      if Transaction_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal
        (Repository.Authentication_Transactions (Transaction_Index).Value.Principal, Principal)
        or else not Identity.Authentication.Transactions.Can_Upgrade_Assurance
          (Repository.Authentication_Transactions (Transaction_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Identity.Authentication.Transactions.Expired_At
        (Repository.Authentication_Transactions (Transaction_Index).Value, Now)
      then
         Repository.Authentication_Transactions (Transaction_Index).Value.State :=
           Identity.Authentication.Transactions.Expired;
         Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Assurance < Repository.Sessions (Session_Index).Value.Assurance then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      Repository.Sessions (Session_Index).Value.Assurance := Assurance;
      Repository.Sessions (Session_Index).Value.Attributes := Attributes;
      Repository.Sessions (Session_Index).Value.Last_Seen_At := Now;
      Repository.Sessions (Session_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Sessions (Session_Index).Value.Version);
      Repository.Authentication_Transactions (Transaction_Index).Value.State :=
        Identity.Authentication.Transactions.Consumed;
      Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
      return Identity.Authentication.Transactions.Applied;
   end Upgrade_Session_Assurance;

   overriding function Upgrade_Session_Assurance
     (Repository                   : in out Store;
      Session                      : Identity.Identifiers.Entities.Session_Id;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Assurance                    : Identity.Assurance.Levels.Assurance_Level;
      Attributes                   : Identity.Assurance.Attributes.Assurance_Attributes;
      Expected_Session_Version     : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Session_Index     : Natural := 0;
      Transaction_Index : Natural := 0;
   begin
      for Index in Repository.Sessions'Range loop
         if Repository.Sessions (Index).Present
           and then Same_Session (Repository.Sessions (Index).Value.Id, Session)
         then
            Session_Index := Index;
            exit;
         end if;
      end loop;

      if Session_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal (Repository.Sessions (Session_Index).Value.Principal, Principal)
        or else not Identity.Sessions.Definitions.Is_Active
          (Repository.Sessions (Session_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      for Index in Repository.Authentication_Transactions'Range loop
         if Repository.Authentication_Transactions (Index).Present
           and then Same_Transaction
             (Repository.Authentication_Transactions (Index).Value.Id, Transaction)
         then
            Transaction_Index := Index;
            exit;
         end if;
      end loop;

      if Transaction_Index = 0 then
         return Identity.Authentication.Transactions.Unknown;
      elsif not Same_Principal
        (Repository.Authentication_Transactions (Transaction_Index).Value.Principal, Principal)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Sessions (Session_Index).Value.Version,
         Expected_Session_Version)
        or else not Identity.Versions.Same_Entity_Version
          (Repository.Authentication_Transactions (Transaction_Index).Value.Version,
           Expected_Transaction_Version)
      then
         return Identity.Authentication.Transactions.Version_Conflict;
      elsif Identity.Sessions.Expiration.Evaluate
        (Repository.Sessions (Session_Index).Value, Now)
          in Identity.Sessions.Expiration.Idle_Expired
           | Identity.Sessions.Expiration.Absolute_Expired
      then
         Repository.Sessions (Session_Index).Value.State := Identity.Sessions.Definitions.Expired;
         Repository.Sessions (Session_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Sessions (Session_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      elsif not Identity.Authentication.Transactions.Can_Upgrade_Assurance
        (Repository.Authentication_Transactions (Transaction_Index).Value.State)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Identity.Authentication.Transactions.Expired_At
        (Repository.Authentication_Transactions (Transaction_Index).Value, Now)
      then
         Repository.Authentication_Transactions (Transaction_Index).Value.State :=
           Identity.Authentication.Transactions.Expired;
         Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
           Identity.Versions.Next_Entity_Version
             (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
         return Identity.Authentication.Transactions.State_Conflict;
      elsif Assurance < Repository.Sessions (Session_Index).Value.Assurance then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      Repository.Sessions (Session_Index).Value.Assurance := Assurance;
      Repository.Sessions (Session_Index).Value.Attributes := Attributes;
      Repository.Sessions (Session_Index).Value.Last_Seen_At := Now;
      Repository.Sessions (Session_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Sessions (Session_Index).Value.Version);
      Repository.Authentication_Transactions (Transaction_Index).Value.State :=
        Identity.Authentication.Transactions.Consumed;
      Repository.Authentication_Transactions (Transaction_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Authentication_Transactions (Transaction_Index).Value.Version);
      return Identity.Authentication.Transactions.Applied;
   end Upgrade_Session_Assurance;

   overriding procedure Find_Authentication_Transaction
     (Repository  : Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Authentication.Transactions.Authentication_Transaction_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Authentication_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Authentication_Transaction;

   overriding procedure Find_Challenge
     (Repository : Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Found      : out Boolean;
      Value      : out Identity.Authentication.Challenges.Challenge_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Challenges loop
         if Slot.Present and then Same_Challenge (Slot.Value.Id, Challenge) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Challenge;

   overriding function Issue_API_Key
     (Repository : in out Store;
      Credential : Identity.API_Keys.Credentials.API_Key_Credential_Record) return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Credential.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.API_Keys loop
         if Slot.Present then
            if Same_Credential (Slot.Value.Id, Credential.Id) then
               return Uniqueness_Conflict;
            elsif Identity.API_Keys.Credentials.Same_Public_Key_Id
              (Slot.Value, Credential)
            then
               return Uniqueness_Conflict;
            end if;
         end if;
      end loop;

      for Slot of Repository.API_Keys loop
         if not Slot.Present then
            Slot := (Present => True, Value => Credential);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Issue_API_Key;

   overriding function Revoke_API_Key
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Command_Status
   is
      Found : Boolean;
      Value : Identity.API_Keys.Credentials.API_Key_Credential_Record;
   begin
      Find_API_Key (Repository, Credential, Found, Value);
      if not Found then
         return State_Conflict;
      end if;

      return Revoke_API_Key (Repository, Credential, Value.Version);
   end Revoke_API_Key;

   overriding function Revoke_API_Key
     (Repository                  : in out Store;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Command_Status
   is
      use type Identity.Versions.Entity_Version;
   begin
      for Slot of Repository.API_Keys loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential) then
            if Slot.Value.Version /= Expected_Credential_Version then
               return Version_Conflict;
            elsif not Identity.Credentials.Lifecycle.Can_Revoke (Slot.Value.State) then
               return State_Conflict;
            end if;
            Slot.Value.State := Identity.Credentials.States.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Revoke_API_Key;

   overriding function Rotate_API_Key
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Command_Status
   is
      Found : Boolean;
      Value : Identity.API_Keys.Credentials.API_Key_Credential_Record;
   begin
      Find_API_Key (Repository, Predecessor, Found, Value);
      if not Found then
         return State_Conflict;
      end if;

      return Rotate_API_Key (Repository, Predecessor, Value.Version, Successor);
   end Rotate_API_Key;

   overriding function Rotate_API_Key
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Successor.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.API_Keys'Range loop
         if Repository.API_Keys (Index).Present then
            if Same_Credential (Repository.API_Keys (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Credential (Repository.API_Keys (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.API_Keys.Credentials.Same_Public_Key_Id
              (Repository.API_Keys (Index).Value, Successor)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 then
         return State_Conflict;
      elsif Free_Index = 0 then
         return Capacity_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.API_Keys (Predecessor_Index).Value.Version,
         Expected_Predecessor_Version)
      then
         return Version_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Predecessor
        (Repository.API_Keys (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      elsif not Same_Principal
        (Repository.API_Keys (Predecessor_Index).Value.Principal, Successor.Principal)
      then
         return State_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Successor (Successor.State) then
         return State_Conflict;
      elsif not Identity.API_Keys.Rotation.Matches_Successor_Generation
        (Repository.API_Keys (Predecessor_Index).Value.Rotation_Generation,
         Successor.Rotation_Generation)
      then
         return Version_Conflict;
      end if;

      Repository.API_Keys (Predecessor_Index).Value.State := Identity.Credentials.States.Retired;
      Repository.API_Keys (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.API_Keys (Predecessor_Index).Value.Version);
      Repository.API_Keys (Free_Index) := (Present => True, Value => Successor);
      return Applied;
   end Rotate_API_Key;

   overriding procedure Find_API_Key
     (Repository : Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.API_Keys.Credentials.API_Key_Credential_Record)
   is
   begin
      Found := False;
      for Slot of Repository.API_Keys loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_API_Key;

   overriding function Event_Capacity_Available
     (Repository : Store;
      Count      : Positive) return Boolean
   is
      Used : Natural := 0;
   begin
      for Slot of Repository.Events loop
         if Slot.Present then
            Used := Used + 1;
         end if;
      end loop;
      return Used + Count <= Max_Events;
   end Event_Capacity_Available;

   overriding function Append_Event
     (Repository : in out Store;
      Event      : Identity.Events.Envelopes.Event_Envelope) return Command_Status
   is
   begin
      for Slot of Repository.Events loop
         if Slot.Present and then Same_Event (Slot.Value.Id, Event.Id) then
            return Uniqueness_Conflict;
         end if;
      end loop;

      for Slot of Repository.Events loop
         if not Slot.Present then
            Slot := (Present => True, Value => Event);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Append_Event;

   overriding function Record_Attempt
     (Repository : in out Store;
      Attempt    : Identity.Attempts.Definitions.Attempt_Record) return Command_Status
   is
   begin
      for Slot of Repository.Attempts loop
         if Slot.Present and then Same_Attempt (Slot.Value.Id, Attempt.Id) then
            return Uniqueness_Conflict;
         end if;
      end loop;

      for Slot of Repository.Attempts loop
         if not Slot.Present then
            Slot := (Present => True, Value => Attempt);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Record_Attempt;

   overriding procedure Find_Attempt
     (Repository : Store;
      Attempt    : Identity.Identifiers.Entities.Attempt_Id;
      Found      : out Boolean;
      Value      : out Identity.Attempts.Definitions.Attempt_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Attempts loop
         if Slot.Present and then Same_Attempt (Slot.Value.Id, Attempt) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Attempt;

   overriding function Request_Contact_Verification
     (Repository : in out Store;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status
   is
      Contact_Free : Natural := 0;
      Token_Free   : Natural := 0;
      Link_Free    : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Contact.Principal)
        or else not Same_Principal (Contact.Principal, Token.Principal)
        or else not Identity.Contacts.Bindings.Can_Request_Verification (Contact.State)
        or else not Identity.Tokens.Definitions.Purpose_Matches
          (Token, Identity.Tokens.Purposes.Contact_Verification)
        or else not Identity.Tokens.Definitions.Can_Issue (Token.State)
      then
         return State_Conflict;
      end if;

      for Index in Repository.Contact_Bindings'Range loop
         if Repository.Contact_Bindings (Index).Present then
            if Same_Contact (Repository.Contact_Bindings (Index).Value.Id, Contact.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Contacts.Bindings.Same_Occupied_Contact_Value
              (Repository.Contact_Bindings (Index).Value, Contact)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Contact_Free = 0 then
            Contact_Free := Index;
         end if;
      end loop;

      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present then
            if Same_Token (Repository.Tokens (Index).Value.Id, Token.Id) then
               return Uniqueness_Conflict;
            end if;
         elsif Token_Free = 0 then
            Token_Free := Index;
         end if;
      end loop;

      for Index in Repository.Contact_Verification_Links'Range loop
         if Repository.Contact_Verification_Links (Index).Present then
            if Same_Token (Repository.Contact_Verification_Links (Index).Token, Token.Id)
              or else Same_Contact (Repository.Contact_Verification_Links (Index).Contact, Contact.Id)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Link_Free = 0 then
            Link_Free := Index;
         end if;
      end loop;

      if Contact_Free = 0 or else Token_Free = 0 or else Link_Free = 0 then
         return Capacity_Conflict;
      end if;

      Repository.Contact_Bindings (Contact_Free) := (Present => True, Value => Contact);
      Repository.Tokens (Token_Free) := (Present => True, Value => Token);
      Repository.Contact_Verification_Links (Link_Free) :=
        (Present => True, Token => Token.Id, Contact => Contact.Id);
      return Applied;
   end Request_Contact_Verification;

   overriding function Complete_Contact_Verification
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      Contact_Value : Identity.Contacts.Bindings.Contact_Binding_Record;
      Found_Contact : Boolean;
      Found_Token   : Boolean;
      Token_Value   : Identity.Tokens.Definitions.Action_Token_Record;
   begin
      Find_Token (Repository, Token, Found_Token, Token_Value);
      if not Found_Token then
         return Identity.Tokens.Verification.Unknown;
      end if;

      Find_Contact_Binding (Repository, Contact, Found_Contact, Contact_Value);
      if not Found_Contact then
         return Identity.Tokens.Verification.Binding_Mismatch;
      end if;

      return Complete_Contact_Verification
        (Repository,
         Token,
         Token_Value.Version,
         Contact_Value.Version,
         Secret,
         Now,
         Contact);
   end Complete_Contact_Verification;

   overriding function Complete_Contact_Verification
     (Repository               : in out Store;
      Token                    : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version   : Identity.Versions.Entity_Version;
      Expected_Contact_Version : Identity.Versions.Entity_Version;
      Secret                   : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                      : Identity.Times.Instant;
      Contact                  : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
      use type Identity.Versions.Entity_Version;
      Contact_Index : Natural := 0;
      Token_Index   : Natural := 0;
      Link_Index    : Natural := 0;
      State_Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Same_Token (Repository.Tokens (Index).Value.Id, Token)
         then
            Token_Index := Index;
            exit;
         end if;
      end loop;

      if Token_Index = 0 then
         return Identity.Tokens.Verification.Unknown;
      elsif Repository.Tokens (Token_Index).Value.Version /= Expected_Token_Version then
         return Identity.Tokens.Verification.State_Conflict;
      elsif not Identity.Tokens.Definitions.Purpose_Matches
        (Repository.Tokens (Token_Index).Value,
         Identity.Tokens.Purposes.Contact_Verification)
      then
         return Identity.Tokens.Verification.Purpose_Mismatch;
      end if;

      State_Outcome :=
        Identity.Tokens.Verification.Evaluate_State_First
          (Repository.Tokens (Token_Index).Value.State,
           Identity.Tokens.Definitions.Expired_At
             (Repository.Tokens (Token_Index).Value, Now));
      if State_Outcome /= Identity.Tokens.Verification.Valid then
         return State_Outcome;
      elsif Identity.Crypto.Secret_Verifiers.Verify_Text
        (Identity.Crypto.Domains.Contact_Verification_Token,
         Secret,
         Repository.Tokens (Token_Index).Value.Secret_Verifier)
        /= Identity.Crypto.Secret_Verifiers.Verified
      then
         return Identity.Tokens.Verification.Not_Verified;
      end if;

      for Index in Repository.Contact_Verification_Links'Range loop
         if Repository.Contact_Verification_Links (Index).Present
           and then Same_Token (Repository.Contact_Verification_Links (Index).Token, Token)
         then
            Link_Index := Index;
            exit;
         end if;
      end loop;

      if Link_Index = 0
        or else not Same_Contact (Repository.Contact_Verification_Links (Link_Index).Contact, Contact)
      then
         return Identity.Tokens.Verification.Binding_Mismatch;
      end if;

      for Index in Repository.Contact_Bindings'Range loop
         if Repository.Contact_Bindings (Index).Present
           and then Same_Contact (Repository.Contact_Bindings (Index).Value.Id, Contact)
         then
            Contact_Index := Index;
            exit;
         end if;
      end loop;

      if Contact_Index = 0
        or else not Same_Principal
          (Repository.Contact_Bindings (Contact_Index).Value.Principal,
           Repository.Tokens (Token_Index).Value.Principal)
      then
         return Identity.Tokens.Verification.Binding_Mismatch;
      elsif Repository.Contact_Bindings (Contact_Index).Value.Version /= Expected_Contact_Version then
         return Identity.Tokens.Verification.State_Conflict;
      elsif not Identity.Contacts.Bindings.Can_Complete_Verification
        (Repository.Contact_Bindings (Contact_Index).Value.State)
      then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      Repository.Contact_Bindings (Contact_Index).Value.State := Identity.Contacts.Bindings.Verified;
      Repository.Contact_Bindings (Contact_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Contact_Bindings (Contact_Index).Value.Version);
      Repository.Tokens (Token_Index).Value.State := Identity.Tokens.Definitions.Consumed;
      Repository.Tokens (Token_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Tokens (Token_Index).Value.Version);

      return Identity.Tokens.Verification.Valid;
   end Complete_Contact_Verification;

   overriding function Begin_Contact_Change
     (Repository : in out Store;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Command_Status
   is
      Predecessor_Index : Natural := 0;
      Successor_Free    : Natural := 0;
      Token_Free        : Natural := 0;
      Link_Free         : Natural := 0;
      Change_Free       : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Change.Principal)
        or else not Same_Principal (Change.Principal, Successor.Principal)
        or else not Same_Principal (Change.Principal, Token.Principal)
        or else not Same_Contact (Change.Successor, Successor.Id)
        or else not Same_Token (Change.Token, Token.Id)
        or else not Identity.Verification.Changes.Can_Begin (Change.State)
        or else not Identity.Contacts.Bindings.Can_Be_Change_Successor (Successor.State)
        or else not Identity.Tokens.Definitions.Purpose_Matches
          (Token, Identity.Tokens.Purposes.Contact_Change)
        or else not Identity.Tokens.Definitions.Can_Issue (Token.State)
      then
         return State_Conflict;
      end if;

      for Index in Repository.Contact_Bindings'Range loop
         if Repository.Contact_Bindings (Index).Present then
            if Same_Contact (Repository.Contact_Bindings (Index).Value.Id, Change.Predecessor) then
               Predecessor_Index := Index;
            end if;

            if Same_Contact (Repository.Contact_Bindings (Index).Value.Id, Successor.Id) then
               return Uniqueness_Conflict;
            end if;

            if Identity.Contacts.Bindings.Same_Occupied_Contact_Value
              (Repository.Contact_Bindings (Index).Value, Successor)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Successor_Free = 0 then
            Successor_Free := Index;
         end if;
      end loop;

      if Predecessor_Index = 0
        or else not Same_Principal
          (Repository.Contact_Bindings (Predecessor_Index).Value.Principal, Change.Principal)
        or else not Identity.Contacts.Bindings.Can_Be_Change_Predecessor
          (Repository.Contact_Bindings (Predecessor_Index).Value.State)
      then
         return State_Conflict;
      end if;

      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present then
            if Same_Token (Repository.Tokens (Index).Value.Id, Token.Id) then
               return Uniqueness_Conflict;
            end if;
         elsif Token_Free = 0 then
            Token_Free := Index;
         end if;
      end loop;

      for Index in Repository.Contact_Verification_Links'Range loop
         if Repository.Contact_Verification_Links (Index).Present then
            if Same_Token (Repository.Contact_Verification_Links (Index).Token, Token.Id)
              or else Same_Contact (Repository.Contact_Verification_Links (Index).Contact, Successor.Id)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Link_Free = 0 then
            Link_Free := Index;
         end if;
      end loop;

      for Index in Repository.Contact_Changes'Range loop
         if Repository.Contact_Changes (Index).Present then
            if Same_Token (Repository.Contact_Changes (Index).Value.Token, Change.Token)
              or else Same_Contact (Repository.Contact_Changes (Index).Value.Successor, Change.Successor)
            then
               return Uniqueness_Conflict;
            end if;
         elsif Change_Free = 0 then
            Change_Free := Index;
         end if;
      end loop;

      if Successor_Free = 0 or else Token_Free = 0 or else Link_Free = 0 or else Change_Free = 0 then
         return Capacity_Conflict;
      end if;

      Repository.Contact_Bindings (Successor_Free) := (Present => True, Value => Successor);
      Repository.Tokens (Token_Free) := (Present => True, Value => Token);
      Repository.Contact_Verification_Links (Link_Free) :=
        (Present => True, Token => Token.Id, Contact => Successor.Id);
      Repository.Contact_Changes (Change_Free) :=
        (Present => True,
         Value => (Principal   => Change.Principal,
                   Predecessor => Change.Predecessor,
                   Successor   => Change.Successor,
                   Token       => Change.Token,
                   State       => Identity.Verification.Changes.New_Contact_Verification,
                   Version     => Identity.Versions.Next_Entity_Version (Change.Version)));
      return Applied;
   end Begin_Contact_Change;

   overriding function Complete_Contact_Change
     (Repository  : in out Store;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      Token_Found       : Boolean;
      Token_Value       : Identity.Tokens.Definitions.Action_Token_Record;
      Change_Version    : Identity.Versions.Entity_Version := 0;
      Predecessor_Found : Boolean;
      Predecessor_Value : Identity.Contacts.Bindings.Contact_Binding_Record;
      Successor_Found   : Boolean;
      Successor_Value   : Identity.Contacts.Bindings.Contact_Binding_Record;
   begin
      Find_Token (Repository, Token, Token_Found, Token_Value);
      if not Token_Found then
         return Identity.Tokens.Verification.Unknown;
      end if;

      for Slot of Repository.Contact_Changes loop
         if Slot.Present and then Same_Token (Slot.Value.Token, Token) then
            Change_Version := Slot.Value.Version;
            exit;
         end if;
      end loop;

      Find_Contact_Binding (Repository, Predecessor, Predecessor_Found, Predecessor_Value);
      Find_Contact_Binding (Repository, Successor, Successor_Found, Successor_Value);
      if not Predecessor_Found or else not Successor_Found then
         return Identity.Tokens.Verification.Binding_Mismatch;
      end if;

      return Complete_Contact_Change
        (Repository,
         Token,
         Token_Value.Version,
         Change_Version,
         Predecessor_Value.Version,
         Successor_Value.Version,
         Secret,
         Now,
         Predecessor,
         Successor);
   end Complete_Contact_Change;

   overriding function Complete_Contact_Change
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
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
      use type Identity.Verification.Changes.Contact_Change_State;
      Change_Index      : Natural := 0;
      Predecessor_Index : Natural := 0;
      Successor_Index   : Natural := 0;
      Token_Index       : Natural := 0;
      Link_Index        : Natural := 0;
      State_Outcome     : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Same_Token (Repository.Tokens (Index).Value.Id, Token)
         then
            Token_Index := Index;
            exit;
         end if;
      end loop;

      if Token_Index = 0 then
         return Identity.Tokens.Verification.Unknown;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Tokens (Token_Index).Value.Version,
         Expected_Token_Version)
      then
         return Identity.Tokens.Verification.State_Conflict;
      elsif not Identity.Tokens.Definitions.Purpose_Matches
        (Repository.Tokens (Token_Index).Value, Identity.Tokens.Purposes.Contact_Change)
      then
         return Identity.Tokens.Verification.Purpose_Mismatch;
      end if;

      State_Outcome :=
        Identity.Tokens.Verification.Evaluate_State_First
          (Repository.Tokens (Token_Index).Value.State,
           Identity.Tokens.Definitions.Expired_At
             (Repository.Tokens (Token_Index).Value, Now));
      if State_Outcome /= Identity.Tokens.Verification.Valid then
         return State_Outcome;
      elsif Identity.Crypto.Secret_Verifiers.Verify_Text
        (Identity.Crypto.Domains.Contact_Verification_Token,
         Secret,
         Repository.Tokens (Token_Index).Value.Secret_Verifier)
        /= Identity.Crypto.Secret_Verifiers.Verified
      then
         return Identity.Tokens.Verification.Not_Verified;
      end if;

      for Index in Repository.Contact_Verification_Links'Range loop
         if Repository.Contact_Verification_Links (Index).Present
           and then Same_Token (Repository.Contact_Verification_Links (Index).Token, Token)
         then
            Link_Index := Index;
            exit;
         end if;
      end loop;

      if Link_Index = 0
        or else not Same_Contact (Repository.Contact_Verification_Links (Link_Index).Contact, Successor)
      then
         return Identity.Tokens.Verification.Binding_Mismatch;
      end if;

      for Index in Repository.Contact_Changes'Range loop
         if Repository.Contact_Changes (Index).Present
           and then Same_Token (Repository.Contact_Changes (Index).Value.Token, Token)
         then
            Change_Index := Index;
            exit;
         end if;
      end loop;

      if Change_Index = 0
        or else not Same_Contact (Repository.Contact_Changes (Change_Index).Value.Predecessor, Predecessor)
        or else not Same_Contact (Repository.Contact_Changes (Change_Index).Value.Successor, Successor)
      then
         return Identity.Tokens.Verification.Binding_Mismatch;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Contact_Changes (Change_Index).Value.Version,
         Expected_Change_Version)
      then
         return Identity.Tokens.Verification.State_Conflict;
      elsif not Identity.Verification.Changes.Can_Complete
        (Repository.Contact_Changes (Change_Index).Value.State)
      then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      for Index in Repository.Contact_Bindings'Range loop
         if Repository.Contact_Bindings (Index).Present then
            if Same_Contact (Repository.Contact_Bindings (Index).Value.Id, Predecessor) then
               Predecessor_Index := Index;
            elsif Same_Contact (Repository.Contact_Bindings (Index).Value.Id, Successor) then
               Successor_Index := Index;
            end if;
         end if;
      end loop;

      if Predecessor_Index = 0 or else Successor_Index = 0 then
         return Identity.Tokens.Verification.Binding_Mismatch;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Contact_Bindings (Predecessor_Index).Value.Version,
         Expected_Predecessor_Version)
        or else not Identity.Versions.Same_Entity_Version
          (Repository.Contact_Bindings (Successor_Index).Value.Version,
           Expected_Successor_Version)
      then
         return Identity.Tokens.Verification.State_Conflict;
      elsif not Same_Principal
        (Repository.Contact_Bindings (Predecessor_Index).Value.Principal,
         Repository.Tokens (Token_Index).Value.Principal)
        or else not Same_Principal
          (Repository.Contact_Bindings (Successor_Index).Value.Principal,
           Repository.Tokens (Token_Index).Value.Principal)
      then
         return Identity.Tokens.Verification.Binding_Mismatch;
      elsif not Identity.Contacts.Bindings.Can_Be_Change_Predecessor
        (Repository.Contact_Bindings (Predecessor_Index).Value.State)
        or else not Identity.Contacts.Bindings.Can_Be_Change_Successor
        (Repository.Contact_Bindings (Successor_Index).Value.State)
      then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      Repository.Contact_Bindings (Successor_Index).Value.State := Identity.Contacts.Bindings.Verified;
      Repository.Contact_Bindings (Successor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Contact_Bindings (Successor_Index).Value.Version);
      Repository.Contact_Bindings (Predecessor_Index).Value.State := Identity.Contacts.Bindings.Retired;
      Repository.Contact_Bindings (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Contact_Bindings (Predecessor_Index).Value.Version);
      Repository.Contact_Changes (Change_Index).Value.State := Identity.Verification.Changes.Activated;
      Repository.Contact_Changes (Change_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Contact_Changes (Change_Index).Value.Version);
      Repository.Tokens (Token_Index).Value.State := Identity.Tokens.Definitions.Consumed;
      Repository.Tokens (Token_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Tokens (Token_Index).Value.Version);

      return Identity.Tokens.Verification.Valid;
   end Complete_Contact_Change;

   overriding procedure Find_Contact_Binding
     (Repository : Store;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id;
      Found      : out Boolean;
      Value      : out Identity.Contacts.Bindings.Contact_Binding_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Contact_Bindings loop
         if Slot.Present and then Same_Contact (Slot.Value.Id, Contact) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Contact_Binding;

   overriding function Install_Recovery_Code_Set
     (Repository : in out Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Codes.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.Recovery_Code_Sets loop
         if Slot.Present then
            if Same_Credential_Set (Slot.Value.Id, Codes.Id) then
               return Uniqueness_Conflict;
            end if;
         end if;
      end loop;

      for Slot of Repository.Recovery_Code_Sets loop
         if not Slot.Present then
            Slot := (Present => True, Value => Codes);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Install_Recovery_Code_Set;

   overriding function Regenerate_Recovery_Code_Set
     (Repository : in out Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Command_Status
   is
      Free_Index : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Codes.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Recovery_Code_Sets'Range loop
         if Repository.Recovery_Code_Sets (Index).Present then
            if Same_Credential_Set (Repository.Recovery_Code_Sets (Index).Value.Id, Codes.Id) then
               return Uniqueness_Conflict;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Free_Index = 0 then
         return Capacity_Conflict;
      end if;

      for Slot of Repository.Recovery_Code_Sets loop
         if Slot.Present and then Same_Principal (Slot.Value.Principal, Codes.Principal) then
            for Code_Index in 1 .. Slot.Value.Count loop
               if Identity.Recovery_Codes.Sets.Can_Revoke_During_Regeneration
                 (Slot.Value.Codes (Code_Index).State)
               then
                  Slot.Value.Codes (Code_Index).State := Identity.Recovery_Codes.Sets.Revoked;
               end if;
            end loop;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
         end if;
      end loop;

      Repository.Recovery_Code_Sets (Free_Index) := (Present => True, Value => Codes);
      return Applied;
   end Regenerate_Recovery_Code_Set;

   overriding function Regenerate_Recovery_Code_Set
     (Repository              : in out Store;
      Codes                   : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
      Expected_Affected_Count : Natural) return Command_Status
   is
      Free_Index            : Natural := 0;
      Actual_Affected_Count : Natural := 0;
   begin
      if not Principal_Is_Active (Repository, Codes.Principal) then
         return State_Conflict;
      end if;

      for Index in Repository.Recovery_Code_Sets'Range loop
         if Repository.Recovery_Code_Sets (Index).Present then
            if Same_Credential_Set (Repository.Recovery_Code_Sets (Index).Value.Id, Codes.Id) then
               return Uniqueness_Conflict;
            end if;

            if Same_Principal (Repository.Recovery_Code_Sets (Index).Value.Principal, Codes.Principal) then
               for Code_Index in 1 .. Repository.Recovery_Code_Sets (Index).Value.Count loop
                  if Identity.Recovery_Codes.Sets.Can_Revoke_During_Regeneration
                    (Repository.Recovery_Code_Sets (Index).Value.Codes (Code_Index).State)
                  then
                     Actual_Affected_Count := Actual_Affected_Count + 1;
                     exit;
                  end if;
               end loop;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Actual_Affected_Count /= Expected_Affected_Count then
         return Version_Conflict;
      elsif Free_Index = 0 then
         return Capacity_Conflict;
      end if;

      for Slot of Repository.Recovery_Code_Sets loop
         if Slot.Present and then Same_Principal (Slot.Value.Principal, Codes.Principal) then
            for Code_Index in 1 .. Slot.Value.Count loop
               if Identity.Recovery_Codes.Sets.Can_Revoke_During_Regeneration
                 (Slot.Value.Codes (Code_Index).State)
               then
                  Slot.Value.Codes (Code_Index).State := Identity.Recovery_Codes.Sets.Revoked;
               end if;
            end loop;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
         end if;
      end loop;

      Repository.Recovery_Code_Sets (Free_Index) := (Present => True, Value => Codes);
      return Applied;
   end Regenerate_Recovery_Code_Set;

   overriding procedure Find_Recovery_Code_Set
     (Repository : Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Found      : out Boolean;
      Value      : out Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Recovery_Code_Sets loop
         if Slot.Present and then Same_Credential_Set (Slot.Value.Id, Set_Id) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Recovery_Code_Set;

   overriding function Begin_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      use type Identity.Recovery.Transactions.Recovery_Transition_Status;
      Account_Found : Boolean := False;
   begin
      if not Principal_Is_Active (Repository, Transaction.Principal)
        or else not Identity.Recovery.Transactions.Can_Begin (Transaction.State)
      then
         return Identity.Recovery.Transactions.State_Conflict;
      end if;

      for Account of Repository.Accounts loop
         if Account.Present and then Same_Account (Account.Value.Id, Transaction.Account) then
            if not Same_Principal (Account.Value.Principal, Transaction.Principal) then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;
            Account_Found := True;
            exit;
         end if;
      end loop;

      if not Account_Found then
         return Identity.Recovery.Transactions.State_Conflict;
      end if;

      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction.Id) then
            return Identity.Recovery.Transactions.Version_Conflict;
         end if;
      end loop;

      for Slot of Repository.Recovery_Transactions loop
         if not Slot.Present then
            Slot := (Present => True,
                     Value => (Id => Transaction.Id,
                               Principal => Transaction.Principal,
                               Account => Transaction.Account,
                               Created_At => Transaction.Created_At,
                               Expires_At => Transaction.Expires_At,
                               State => Identity.Recovery.Transactions.Evidence_Required,
                               Version => Identity.Versions.Next_Entity_Version
                                 (Transaction.Version)));
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Capacity_Conflict;
   end Begin_Recovery;

   overriding function Accept_Recovery_Evidence
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return Identity.Recovery.Transactions.State_Conflict;
            elsif Identity.Recovery.Transactions.Expired_At (Slot.Value, Now) then
               Slot.Value.State := Identity.Recovery.Transactions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Recovery.Transactions.Can_Accept_Evidence (Slot.Value.State)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            Slot.Value.State := Identity.Recovery.Transactions.Evidence_Accepted;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Unknown;
   end Accept_Recovery_Evidence;

   overriding function Accept_Recovery_Evidence
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return Identity.Recovery.Transactions.Version_Conflict;
            elsif Identity.Recovery.Transactions.Expired_At (Slot.Value, Now) then
               Slot.Value.State := Identity.Recovery.Transactions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Recovery.Transactions.Can_Accept_Evidence (Slot.Value.State)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            Slot.Value.State := Identity.Recovery.Transactions.Evidence_Accepted;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Unknown;
   end Accept_Recovery_Evidence;

   overriding function Complete_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      Account_Index : Natural := 0;
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return Identity.Recovery.Transactions.State_Conflict;
            elsif Identity.Recovery.Transactions.Expired_At (Slot.Value, Now) then
               Slot.Value.State := Identity.Recovery.Transactions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Recovery.Transactions.Can_Complete (Slot.Value.State)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            for Index in Repository.Accounts'Range loop
               if Repository.Accounts (Index).Present
                 and then Same_Account (Repository.Accounts (Index).Value.Id, Slot.Value.Account)
               then
                  Account_Index := Index;
                  exit;
               end if;
            end loop;

            if Account_Index = 0
              or else not Same_Principal
                (Repository.Accounts (Account_Index).Value.Principal, Principal)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            Repository.Accounts (Account_Index).Value.State.Recovery.Restricted_Session := True;
            Repository.Accounts (Account_Index).Value.State.Recovery.Required_Credential_Reestablishment := True;
            Repository.Accounts (Account_Index).Value.State.Recovery.No_Remember_Me := True;
            Repository.Accounts (Account_Index).Value.State.Recovery.Limited_Lifetime := True;
            Repository.Accounts (Account_Index).Value.State.Requirements.Credential_Reestablishment_Required := True;
            Repository.Accounts (Account_Index).Value.Version :=
              Identity.Versions.Next_Entity_Version
                (Repository.Accounts (Account_Index).Value.Version);
            Slot.Value.State := Identity.Recovery.Transactions.Restricted_Authentication_Established;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Unknown;
   end Complete_Recovery;

   overriding function Complete_Recovery
     (Repository                   : in out Store;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
      Expected_Account_Version     : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      Account_Index : Natural := 0;
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            for Index in Repository.Accounts'Range loop
               if Repository.Accounts (Index).Present
                 and then Same_Account (Repository.Accounts (Index).Value.Id, Slot.Value.Account)
               then
                  Account_Index := Index;
                  exit;
               end if;
            end loop;

            if Account_Index = 0
              or else not Same_Principal
                (Repository.Accounts (Account_Index).Value.Principal, Principal)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Transaction_Version)
              or else not Identity.Versions.Same_Entity_Version
                (Repository.Accounts (Account_Index).Value.Version,
                 Expected_Account_Version)
            then
               return Identity.Recovery.Transactions.Version_Conflict;
            elsif Identity.Recovery.Transactions.Expired_At (Slot.Value, Now) then
               Slot.Value.State := Identity.Recovery.Transactions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Recovery.Transactions.Can_Complete (Slot.Value.State)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            Repository.Accounts (Account_Index).Value.State.Recovery.Restricted_Session := True;
            Repository.Accounts (Account_Index).Value.State.Recovery.Required_Credential_Reestablishment := True;
            Repository.Accounts (Account_Index).Value.State.Recovery.No_Remember_Me := True;
            Repository.Accounts (Account_Index).Value.State.Recovery.Limited_Lifetime := True;
            Repository.Accounts (Account_Index).Value.State.Requirements.Credential_Reestablishment_Required := True;
            Repository.Accounts (Account_Index).Value.Version :=
              Identity.Versions.Next_Entity_Version
                (Repository.Accounts (Account_Index).Value.Version);
            Slot.Value.State := Identity.Recovery.Transactions.Restricted_Authentication_Established;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Unknown;
   end Complete_Recovery;

   overriding function Cancel_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal)
              or else not Identity.Recovery.Transactions.Can_Cancel (Slot.Value.State)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            Slot.Value.State := Identity.Recovery.Transactions.Cancelled;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Unknown;
   end Cancel_Recovery;

   overriding function Cancel_Recovery
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            elsif not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return Identity.Recovery.Transactions.Version_Conflict;
            elsif not Identity.Recovery.Transactions.Can_Cancel (Slot.Value.State)
            then
               return Identity.Recovery.Transactions.State_Conflict;
            end if;

            Slot.Value.State := Identity.Recovery.Transactions.Cancelled;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Recovery.Transactions.Applied;
         end if;
      end loop;

      return Identity.Recovery.Transactions.Unknown;
   end Cancel_Recovery;

   overriding function Advance_Recovery
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Recovery.Transactions.Recovery_Transaction_Action;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      package RT renames Identity.Recovery.Transactions;
      Target        : RT.Recovery_Transaction_State;
      Account_Index : Natural := 0;
      use type RT.Recovery_Transaction_Action;
   begin
      --  Only the mid-flow admission actions advance through this path; the
      --  begin/accept/complete/cancel actions have their own primitives.
      case Action is
         when RT.Approve_Recovery =>
            Target := RT.Approved;
         when RT.Require_Recovery_Credential_Reestablishment =>
            Target := RT.Credential_Reestablishment_Required;
         when RT.Establish_Recovery_Restricted_Authentication =>
            Target := RT.Restricted_Authentication_Established;
         when others =>
            return RT.State_Conflict;
      end case;

      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            if not Same_Principal (Slot.Value.Principal, Principal) then
               return RT.State_Conflict;
            elsif not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return RT.Version_Conflict;
            elsif RT.Expired_At (Slot.Value, Now) then
               Slot.Value.State := RT.Expired;
               Slot.Value.Version :=
                 Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return RT.State_Conflict;
            elsif RT.Admission_Rejected (RT.Admission (Slot.Value.State, Action)) then
               return RT.State_Conflict;
            end if;

            --  Establishing restricted authentication also marks the account's
            --  recovery restrictions, exactly as Complete_Recovery does, so the
            --  released session is restricted rather than fully privileged.
            if Action = RT.Establish_Recovery_Restricted_Authentication then
               for Index in Repository.Accounts'Range loop
                  if Repository.Accounts (Index).Present
                    and then Same_Account
                      (Repository.Accounts (Index).Value.Id, Slot.Value.Account)
                  then
                     Account_Index := Index;
                     exit;
                  end if;
               end loop;

               if Account_Index = 0
                 or else not Same_Principal
                   (Repository.Accounts (Account_Index).Value.Principal, Principal)
               then
                  return RT.State_Conflict;
               end if;

               Repository.Accounts (Account_Index).Value.State.Recovery.Restricted_Session := True;
               Repository.Accounts (Account_Index).Value.State.Recovery.Required_Credential_Reestablishment := True;
               Repository.Accounts (Account_Index).Value.State.Recovery.No_Remember_Me := True;
               Repository.Accounts (Account_Index).Value.State.Recovery.Limited_Lifetime := True;
               Repository.Accounts (Account_Index).Value.State.Requirements.Credential_Reestablishment_Required := True;
               Repository.Accounts (Account_Index).Value.Version :=
                 Identity.Versions.Next_Entity_Version
                   (Repository.Accounts (Account_Index).Value.Version);
            end if;

            Slot.Value.State := Target;
            Slot.Value.Version :=
              Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return RT.Applied;
         end if;
      end loop;

      return RT.Unknown;
   end Advance_Recovery;

   overriding procedure Find_Recovery_Transaction
     (Repository  : Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Recovery.Transactions.Recovery_Transaction_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present and then Same_Transaction (Slot.Value.Id, Transaction) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Recovery_Transaction;

   overriding function Bind_External
     (Repository : in out Store;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record) return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Binding.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.External_Bindings loop
         if Slot.Present then
            if Same_External_Binding (Slot.Value.Id, Binding.Id) then
               return Uniqueness_Conflict;
            elsif Identity.External_Providers.Bindings.Same_Active_External_Key
              (Slot.Value, Binding)
            then
               return Uniqueness_Conflict;
            end if;
         end if;
      end loop;

      for Slot of Repository.External_Bindings loop
         if not Slot.Present then
            Slot := (Present => True, Value => Binding);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Bind_External;

   overriding function Revoke_External
     (Repository : in out Store;
      Binding    : Identity.Identifiers.Entities.External_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status
   is
   begin
      for Slot of Repository.External_Bindings loop
         if Slot.Present and then Same_External_Binding (Slot.Value.Id, Binding) then
            return Revoke_External (Repository, Binding, Principal, Slot.Value.Version);
         end if;
      end loop;

      return State_Conflict;
   end Revoke_External;

   overriding function Revoke_External
     (Repository               : in out Store;
      Binding                  : Identity.Identifiers.Entities.External_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Command_Status
   is
      use type Identity.External_Providers.Bindings.External_Binding_State;
      use type Identity.Versions.Entity_Version;
   begin
      for Slot of Repository.External_Bindings loop
         if Slot.Present and then Same_External_Binding (Slot.Value.Id, Binding) then
            if Slot.Value.Version /= Expected_Binding_Version then
               return Version_Conflict;
            elsif not Same_Principal (Slot.Value.Principal, Principal) then
               return State_Conflict;
            elsif not Identity.External_Providers.Bindings.Can_Revoke (Slot.Value.State) then
               return State_Conflict;
            end if;

            Slot.Value.State := Identity.External_Providers.Bindings.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Revoke_External;

   overriding function External_Replay_Registered
     (Repository  : Store;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Boolean
   is
   begin
      for Slot of Repository.External_Replays loop
         if Slot.Present
           and then Identity.Text.Bounded.Equal (Slot.Fingerprint, Fingerprint)
         then
            return True;
         end if;
      end loop;
      return False;
   end External_Replay_Registered;

   overriding function Register_External_Replay
     (Repository  : in out Store;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Command_Status
   is
   begin
      for Slot of Repository.External_Replays loop
         if Slot.Present and then Identity.Text.Bounded.Equal (Slot.Fingerprint, Fingerprint) then
            return State_Conflict;
         end if;
      end loop;

      for Slot of Repository.External_Replays loop
         if not Slot.Present then
            Slot := (Present => True, Fingerprint => Fingerprint);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Register_External_Replay;

   function Build_Idempotency_Reservation
     (Status    : Identity.Adapters.Repositories.Idempotency.Idempotency_Status;
      Operation : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key       : Identity.Operations.Idempotency.Idempotency_Key;
      Completed : Boolean;
      Version   : Identity.Versions.Entity_Version)
      return Identity.Adapters.Repositories.Idempotency.Reservation is
     ((Status => Status,
       Operation => Operation,
       Key => Key,
       Completed => Completed,
       Version => Version));

   overriding function Reserve_Idempotency
     (Repository : in out Store;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation
   is
   begin
      for Slot of Repository.Idempotency loop
         if Slot.Present
           and then Identity.Operations.Idempotency.Equal (Slot.Key, Key)
         then
            if Slot.Operation /= Operation then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Conflict,
                  Operation,
                  Key,
                  Slot.Completed,
                  Slot.Version);
            elsif Slot.Completed then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Replayed,
                  Operation,
                  Key,
                  True,
                  Slot.Version);
            else
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.In_Progress,
                  Operation,
                  Key,
                  False,
                  Slot.Version);
            end if;
         end if;
      end loop;

      for Slot of Repository.Idempotency loop
         if not Slot.Present then
            Slot := (Present => True,
                     Operation => Operation,
                     Key => Key,
                     Completed => False,
                     Version => 1);
            return Build_Idempotency_Reservation
              (Identity.Adapters.Repositories.Idempotency.Fresh,
               Operation,
               Key,
               False,
               1);
         end if;
      end loop;

      return Build_Idempotency_Reservation
        (Identity.Adapters.Repositories.Idempotency.Capacity_Exceeded,
         Operation,
         Key,
         False,
         0);
   end Reserve_Idempotency;

   overriding function Complete_Idempotency
     (Repository : in out Store;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation
   is
   begin
      for Slot of Repository.Idempotency loop
         if Slot.Present
           and then Identity.Operations.Idempotency.Equal (Slot.Key, Key)
         then
            if Slot.Operation /= Operation then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Conflict,
                  Operation,
                  Key,
                  Slot.Completed,
                  Slot.Version);
            elsif Slot.Completed then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Replayed,
                  Operation,
                  Key,
                  True,
                  Slot.Version);
            else
               Slot.Completed := True;
               Slot.Version := Identity.Versions.Next_Entity_Version (Slot.Version);
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Fresh,
                  Operation,
                  Key,
                  True,
                  Slot.Version);
            end if;
         end if;
      end loop;

      return Build_Idempotency_Reservation
        (Identity.Adapters.Repositories.Idempotency.Conflict,
         Operation,
         Key,
         False,
         0);
   end Complete_Idempotency;

   overriding function Complete_Idempotency
     (Repository       : in out Store;
      Operation        : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key              : Identity.Operations.Idempotency.Idempotency_Key;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Adapters.Repositories.Idempotency.Reservation
   is
   begin
      for Slot of Repository.Idempotency loop
         if Slot.Present
           and then Identity.Operations.Idempotency.Equal (Slot.Key, Key)
         then
            if Slot.Operation /= Operation then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Conflict,
                  Operation,
                  Key,
                  Slot.Completed,
                  Slot.Version);
            elsif not Identity.Versions.Same_Entity_Version
              (Slot.Version, Expected_Version)
            then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Conflict,
                  Operation,
                  Key,
                  Slot.Completed,
                  Slot.Version);
            elsif Slot.Completed then
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Replayed,
                  Operation,
                  Key,
                  True,
                  Slot.Version);
            else
               Slot.Completed := True;
               Slot.Version := Identity.Versions.Next_Entity_Version (Slot.Version);
               return Build_Idempotency_Reservation
                 (Identity.Adapters.Repositories.Idempotency.Fresh,
                  Operation,
                  Key,
                  True,
                  Slot.Version);
            end if;
         end if;
      end loop;

      return Build_Idempotency_Reservation
        (Identity.Adapters.Repositories.Idempotency.Conflict,
         Operation,
         Key,
         False,
         0);
   end Complete_Idempotency;

   overriding function Begin_TOTP_Enrollment
     (Repository : in out Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Command_Status
   is
   begin
      if not Principal_Is_Active (Repository, Credential.Principal) then
         return State_Conflict;
      elsif not Identity.Credentials.Lifecycle.Can_Begin_Factor_Enrollment (Credential.State) then
         return State_Conflict;
      end if;

      for Slot of Repository.TOTP_Credentials loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential.Id) then
            return Uniqueness_Conflict;
         end if;
      end loop;

      for Slot of Repository.TOTP_Credentials loop
         if not Slot.Present then
            Slot := (Present => True, Value => Credential);
            return Applied;
         end if;
      end loop;

      return Capacity_Conflict;
   end Begin_TOTP_Enrollment;

   overriding function Complete_TOTP_Enrollment
     (Repository : in out Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Command_Status
   is
      Found : Boolean;
      Value : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
   begin
      Find_TOTP_Credential (Repository, Credential.Id, Found, Value);
      if not Found then
         return State_Conflict;
      end if;

      return Complete_TOTP_Enrollment (Repository, Credential, Value.Version);
   end Complete_TOTP_Enrollment;

   overriding function Complete_TOTP_Enrollment
     (Repository                  : in out Store;
      Credential                  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Command_Status
   is
      use type Identity.Versions.Entity_Version;
   begin
      if not Principal_Is_Active (Repository, Credential.Principal) then
         return State_Conflict;
      end if;

      for Slot of Repository.TOTP_Credentials loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential.Id) then
            if Slot.Value.Version /= Expected_Credential_Version then
               return Version_Conflict;
            elsif not Same_Principal (Slot.Value.Principal, Credential.Principal) then
               return State_Conflict;
            elsif not Identity.Credentials.Lifecycle.Can_Complete_Factor_Enrollment
              (Slot.Value.State, Credential.State)
            then
               return State_Conflict;
            end if;

            Slot.Value.Algorithm := Credential.Algorithm;
            Slot.Value.Secret_Verifier := Credential.Secret_Verifier;
            Slot.Value.State := Identity.Credentials.States.Active;
            Slot.Value.Created_At := Credential.Created_At;
            Slot.Value.Highest_Accepted_Counter := Credential.Highest_Accepted_Counter;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Complete_TOTP_Enrollment;

   overriding procedure Find_TOTP_Credential
     (Repository : Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
   is
   begin
      Found := False;
      for Slot of Repository.TOTP_Credentials loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_TOTP_Credential;

   overriding function Remove_TOTP
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Command_Status
   is
      Found : Boolean;
      Value : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
   begin
      Find_TOTP_Credential (Repository, Credential, Found, Value);
      if not Found then
         return State_Conflict;
      end if;

      return Remove_TOTP (Repository, Credential, Principal, Value.Version);
   end Remove_TOTP;

   overriding function Remove_TOTP
     (Repository                  : in out Store;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Principal                   : Identity.Identifiers.Entities.Principal_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Command_Status
   is
      use type Identity.Versions.Entity_Version;
   begin
      for Slot of Repository.TOTP_Credentials loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential) then
            if Slot.Value.Version /= Expected_Credential_Version then
               return Version_Conflict;
            elsif not Same_Principal (Slot.Value.Principal, Principal) then
               return State_Conflict;
            elsif not Identity.Credentials.Lifecycle.Can_Remove_Factor (Slot.Value.State) then
               return State_Conflict;
            end if;

            Slot.Value.State := Identity.Credentials.States.Revoked;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Applied;
         end if;
      end loop;

      return State_Conflict;
   end Remove_TOTP;

   overriding function Resolve
     (Repository : Store;
      Subject    : Identity.Identities.Subjects.Authentication_Subject)
      return Identity.Identities.Resolution.Resolution_Result
   is
      Found : Boolean := False;
      Principal : Identity.Identifiers.Entities.Principal_Id;
   begin
      for Slot of Repository.Bindings loop
         if Slot.Present
           and then Identity.Identities.Bindings.Active_Matches_Subject
             (Slot.Value, Subject)
         then
            if Found and then not Same_Principal (Principal, Slot.Value.Principal) then
               return (Status => Identity.Identities.Resolution.Ambiguous);
            end if;

            Found := True;
            Principal := Slot.Value.Principal;
         end if;
      end loop;

      if Found then
         return (Status => Identity.Identities.Resolution.Resolved, Principal => Principal);
      else
         return (Status => Identity.Identities.Resolution.Not_Found);
      end if;
   end Resolve;

   overriding procedure Find_Active_Password
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Credential : out Identity.Passwords.Credentials.Password_Credential_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Passwords loop
         if Slot.Present
           and then Same_Principal (Slot.Value.Principal, Principal)
           and then Identity.Credentials.Lifecycle.Occupies_Active_Slot (Slot.Value.State)
         then
            Credential := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Active_Password;

   overriding procedure Find_Principal
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Value      : out Identity.Principals.Definitions.Principal_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Principals loop
         if Slot.Present and then Same_Principal (Slot.Value.Id, Principal) then
            Value := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Principal;

   overriding procedure Find_Account
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Account    : out Identity.Accounts.Definitions.Account_Record)
   is
   begin
      Found := False;
      for Slot of Repository.Accounts loop
         if Slot.Present and then Same_Principal (Slot.Value.Principal, Principal) then
            Account := Slot.Value;
            Found := True;
            return;
         end if;
      end loop;
   end Find_Account;

   overriding function Lookup_Session
     (Repository       : Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;

      Verification : Identity.Crypto.Secret_Verifiers.Verification_Outcome;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Identity.Text.Bounded.Equal (Slot.Value.Public_Reference, Public_Reference)
         then
            if Identity.Sessions.Definitions.Lookup_Reports_Revoked (Slot.Value.State) then
               return (Status => Identity.Sessions.Handles.Revoked);
            elsif Identity.Sessions.Definitions.Lookup_Reports_Expired (Slot.Value.State) then
               return (Status => Identity.Sessions.Handles.Expired);
            elsif Identity.Sessions.Expiration.Evaluate (Slot.Value, Now)
              in Identity.Sessions.Expiration.Idle_Expired
               | Identity.Sessions.Expiration.Absolute_Expired
            then
               return (Status => Identity.Sessions.Handles.Expired);
            end if;

            Verification := Identity.Crypto.Secret_Verifiers.Verify_Text
              (Identity.Crypto.Domains.Session_Token,
               Secret,
               Slot.Value.Secret_Verifier);

            if Verification /= Identity.Crypto.Secret_Verifiers.Verified then
               return (Status => Identity.Sessions.Handles.Not_Verified);
            end if;

            return
              (Status       => Identity.Sessions.Handles.Found,
               Session      => Slot.Value.Id,
               Principal    => Slot.Value.Principal,
               Assurance    => Slot.Value.Assurance,
               Attributes   => Slot.Value.Attributes,
               Original_Authenticated_At => Slot.Value.Original_Authenticated_At,
               Primary_Authenticated_At => Slot.Value.Primary_Authenticated_At,
               MFA_Completed_At => Slot.Value.MFA_Completed_At,
               Step_Up_At    => Slot.Value.Step_Up_At,
               Last_Seen_At => Slot.Value.Last_Seen_At,
               Revision     => Identity.Versions.Session_Revision (Slot.Value.Version));
         end if;
      end loop;

      return (Status => Identity.Sessions.Handles.Unknown);
   end Lookup_Session;

   overriding function Renew_Session
     (Repository       : in out Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;

      Verification : Identity.Crypto.Secret_Verifiers.Verification_Outcome;
      Admission    : Identity.Sessions.Activity.Activity_Admission_Status;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present
           and then Identity.Text.Bounded.Equal (Slot.Value.Public_Reference, Public_Reference)
         then
            Admission := Identity.Sessions.Activity.Admit_Update
              (Slot.Value, Now, Idle_Expires_At);

            if Admission = Identity.Sessions.Activity.Revoked then
               return (Status => Identity.Sessions.Handles.Revoked);
            elsif Admission in
              Identity.Sessions.Activity.Idle_Expired
                | Identity.Sessions.Activity.Absolute_Expired
            then
               Slot.Value.State := Identity.Sessions.Definitions.Expired;
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return (Status => Identity.Sessions.Handles.Expired);
            elsif Admission = Identity.Sessions.Activity.Invalid_Idle_Extension then
               return (Status => Identity.Sessions.Handles.Expired);
            end if;

            Verification := Identity.Crypto.Secret_Verifiers.Verify_Text
              (Identity.Crypto.Domains.Session_Token,
               Secret,
               Slot.Value.Secret_Verifier);

            if Verification /= Identity.Crypto.Secret_Verifiers.Verified then
               return (Status => Identity.Sessions.Handles.Not_Verified);
            end if;

            Slot.Value.Last_Seen_At := Now;
            Slot.Value.Idle_Expires_At := Idle_Expires_At;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);

            return
              (Status       => Identity.Sessions.Handles.Found,
               Session      => Slot.Value.Id,
               Principal    => Slot.Value.Principal,
               Assurance    => Slot.Value.Assurance,
               Attributes   => Slot.Value.Attributes,
               Original_Authenticated_At => Slot.Value.Original_Authenticated_At,
               Primary_Authenticated_At => Slot.Value.Primary_Authenticated_At,
               MFA_Completed_At => Slot.Value.MFA_Completed_At,
               Step_Up_At    => Slot.Value.Step_Up_At,
               Last_Seen_At => Slot.Value.Last_Seen_At,
               Revision     => Identity.Versions.Session_Revision (Slot.Value.Version));
         end if;
      end loop;

      return (Status => Identity.Sessions.Handles.Unknown);
   end Renew_Session;

   overriding function Verify_Token
     (Repository : Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
      State_Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      for Slot of Repository.Tokens loop
         if Slot.Present and then Same_Token (Slot.Value.Id, Token) then
            if not Identity.Tokens.Definitions.Purpose_Matches (Slot.Value, Purpose) then
               return Identity.Tokens.Verification.Purpose_Mismatch;
            end if;

            State_Outcome :=
              Identity.Tokens.Verification.Evaluate_State_First
                (Slot.Value.State,
                 Identity.Tokens.Definitions.Expired_At (Slot.Value, Now));
            if State_Outcome /= Identity.Tokens.Verification.Valid then
               return State_Outcome;
            elsif Identity.Crypto.Secret_Verifiers.Verify_Text
              (Domain_For_Purpose (Slot.Value.Purpose),
               Secret,
               Slot.Value.Secret_Verifier) = Identity.Crypto.Secret_Verifiers.Verified
            then
               return Identity.Tokens.Verification.Valid;
            else
               return Identity.Tokens.Verification.Not_Verified;
            end if;
         end if;
      end loop;

      return Identity.Tokens.Verification.Unknown;
   end Verify_Token;

   overriding function Consume_Token
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      Found : Boolean;
      Value : Identity.Tokens.Definitions.Action_Token_Record;
   begin
      Find_Token (Repository, Token, Found, Value);
      if not Found then
         return Identity.Tokens.Verification.Unknown;
      end if;

      return Consume_Token (Repository, Token, Value.Version, Purpose, Secret, Now);
   end Consume_Token;

   overriding function Consume_Token
     (Repository       : in out Store;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Purpose          : Identity.Identifiers.Registry.Registry_Id;
      Secret           : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      Found   : Boolean;
      Current : Identity.Tokens.Definitions.Action_Token_Record;
   begin
      Find_Token (Repository, Token, Found, Current);
      if not Found then
         return Identity.Tokens.Verification.Unknown;
      end if;

      if not Identity.Versions.Same_Entity_Version
        (Current.Version, Expected_Version)
      then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      declare
         Outcome : constant Identity.Tokens.Verification.Token_Verification_Outcome :=
           Verify_Token (Repository, Token, Purpose, Secret, Now);
      begin
         if Outcome /= Identity.Tokens.Verification.Valid then
            return Outcome;
         end if;
      end;

      for Slot of Repository.Tokens loop
         if Slot.Present and then Same_Token (Slot.Value.Id, Token) then
            Slot.Value.State := Identity.Tokens.Definitions.Consumed;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.Tokens.Verification.Valid;
         end if;
      end loop;

      return Identity.Tokens.Verification.State_Conflict;
   end Consume_Token;

   overriding function Complete_Password_Reset
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant;
      Successor  : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
      Token_Index       : Natural := 0;
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
      State_Outcome     : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Same_Token (Repository.Tokens (Index).Value.Id, Token)
         then
            Token_Index := Index;
            exit;
         end if;
      end loop;

      if Token_Index = 0 then
         return Identity.Tokens.Verification.Unknown;
      elsif not Identity.Tokens.Definitions.Purpose_Matches
        (Repository.Tokens (Token_Index).Value, Purpose)
      then
         return Identity.Tokens.Verification.Purpose_Mismatch;
      end if;

      State_Outcome :=
        Identity.Tokens.Verification.Evaluate_State_First
          (Repository.Tokens (Token_Index).Value.State,
           Identity.Tokens.Definitions.Expired_At
             (Repository.Tokens (Token_Index).Value, Now));
      if State_Outcome /= Identity.Tokens.Verification.Valid then
         return State_Outcome;
      elsif Identity.Crypto.Secret_Verifiers.Verify_Text
        (Identity.Crypto.Domains.Password_Reset_Token,
         Secret,
         Repository.Tokens (Token_Index).Value.Secret_Verifier)
        /= Identity.Crypto.Secret_Verifiers.Verified
      then
         return Identity.Tokens.Verification.Not_Verified;
      elsif not Same_Principal (Repository.Tokens (Token_Index).Value.Principal, Successor.Principal) then
         return Identity.Tokens.Verification.Binding_Mismatch;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Successor (Successor.State) then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      for Index in Repository.Passwords'Range loop
         if Repository.Passwords (Index).Present then
            if Same_Credential (Repository.Passwords (Index).Value.Id, Successor.Id) then
               return Identity.Tokens.Verification.State_Conflict;
            end if;

            if Same_Principal (Repository.Passwords (Index).Value.Principal, Successor.Principal)
              and then Identity.Credentials.Lifecycle.Occupies_Active_Slot
                (Repository.Passwords (Index).Value.State)
            then
               Predecessor_Index := Index;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 or else Free_Index = 0 then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      Repository.Passwords (Predecessor_Index).Value.State := Identity.Credentials.States.Retired;
      Repository.Passwords (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Passwords (Predecessor_Index).Value.Version);
      Repository.Passwords (Free_Index) := (Present => True, Value => Successor);
      Repository.Tokens (Token_Index).Value.State := Identity.Tokens.Definitions.Consumed;
      Repository.Tokens (Token_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Tokens (Token_Index).Value.Version);

      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Index /= Token_Index
           and then Same_Principal
             (Repository.Tokens (Index).Value.Principal, Successor.Principal)
           and then Identity.Tokens.Definitions.Purpose_Matches
             (Repository.Tokens (Index).Value, Identity.Tokens.Purposes.Password_Reset)
           and then Repository.Tokens (Index).Value.State in
             Identity.Tokens.Definitions.Issued
             | Identity.Tokens.Definitions.Presented
             | Identity.Tokens.Definitions.Verified
         then
            Repository.Tokens (Index).Value.State := Identity.Tokens.Definitions.Superseded;
            Repository.Tokens (Index).Value.Version :=
              Identity.Versions.Next_Entity_Version
                (Repository.Tokens (Index).Value.Version);
         end if;
      end loop;

      return Identity.Tokens.Verification.Valid;
   end Complete_Password_Reset;

   overriding function Complete_Password_Reset
     (Repository                   : in out Store;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Purpose                      : Identity.Identifiers.Registry.Registry_Id;
      Secret                       : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now                          : Identity.Times.Instant;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
      Token_Index       : Natural := 0;
      Predecessor_Index : Natural := 0;
      Free_Index        : Natural := 0;
      State_Outcome     : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Same_Token (Repository.Tokens (Index).Value.Id, Token)
         then
            Token_Index := Index;
            exit;
         end if;
      end loop;

      if Token_Index = 0 then
         return Identity.Tokens.Verification.Unknown;
      elsif not Identity.Tokens.Definitions.Purpose_Matches
        (Repository.Tokens (Token_Index).Value, Purpose)
      then
         return Identity.Tokens.Verification.Purpose_Mismatch;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Tokens (Token_Index).Value.Version, Expected_Token_Version)
      then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      State_Outcome :=
        Identity.Tokens.Verification.Evaluate_State_First
          (Repository.Tokens (Token_Index).Value.State,
           Identity.Tokens.Definitions.Expired_At
             (Repository.Tokens (Token_Index).Value, Now));
      if State_Outcome /= Identity.Tokens.Verification.Valid then
         return State_Outcome;
      elsif Identity.Crypto.Secret_Verifiers.Verify_Text
        (Identity.Crypto.Domains.Password_Reset_Token,
         Secret,
         Repository.Tokens (Token_Index).Value.Secret_Verifier)
        /= Identity.Crypto.Secret_Verifiers.Verified
      then
         return Identity.Tokens.Verification.Not_Verified;
      elsif not Same_Principal (Repository.Tokens (Token_Index).Value.Principal, Successor.Principal) then
         return Identity.Tokens.Verification.Binding_Mismatch;
      elsif not Identity.Credentials.Lifecycle.Can_Be_Replacement_Successor (Successor.State) then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      for Index in Repository.Passwords'Range loop
         if Repository.Passwords (Index).Present then
            if Same_Credential (Repository.Passwords (Index).Value.Id, Successor.Id) then
               return Identity.Tokens.Verification.State_Conflict;
            end if;

            if Same_Principal (Repository.Passwords (Index).Value.Principal, Successor.Principal)
              and then Identity.Credentials.Lifecycle.Occupies_Active_Slot
                (Repository.Passwords (Index).Value.State)
            then
               Predecessor_Index := Index;
            end if;
         elsif Free_Index = 0 then
            Free_Index := Index;
         end if;
      end loop;

      if Predecessor_Index = 0 or else Free_Index = 0 then
         return Identity.Tokens.Verification.State_Conflict;
      elsif not Identity.Versions.Same_Entity_Version
        (Repository.Passwords (Predecessor_Index).Value.Version,
         Expected_Predecessor_Version)
      then
         return Identity.Tokens.Verification.State_Conflict;
      end if;

      Repository.Passwords (Predecessor_Index).Value.State := Identity.Credentials.States.Retired;
      Repository.Passwords (Predecessor_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Passwords (Predecessor_Index).Value.Version);
      Repository.Passwords (Free_Index) := (Present => True, Value => Successor);
      Repository.Tokens (Token_Index).Value.State := Identity.Tokens.Definitions.Consumed;
      Repository.Tokens (Token_Index).Value.Version :=
        Identity.Versions.Next_Entity_Version
          (Repository.Tokens (Token_Index).Value.Version);

      for Index in Repository.Tokens'Range loop
         if Repository.Tokens (Index).Present
           and then Index /= Token_Index
           and then Same_Principal
             (Repository.Tokens (Index).Value.Principal, Successor.Principal)
           and then Identity.Tokens.Definitions.Purpose_Matches
             (Repository.Tokens (Index).Value, Identity.Tokens.Purposes.Password_Reset)
           and then Repository.Tokens (Index).Value.State in
             Identity.Tokens.Definitions.Issued
             | Identity.Tokens.Definitions.Presented
             | Identity.Tokens.Definitions.Verified
         then
            Repository.Tokens (Index).Value.State := Identity.Tokens.Definitions.Superseded;
            Repository.Tokens (Index).Value.Version :=
              Identity.Versions.Next_Entity_Version
                (Repository.Tokens (Index).Value.Version);
         end if;
      end loop;

      return Identity.Tokens.Verification.Valid;
   end Complete_Password_Reset;

   overriding function Authenticate_API_Key
     (Repository    : in out Store;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
   begin
      for Slot of Repository.API_Keys loop
         if Slot.Present
           and then Identity.API_Keys.Credentials.Matches_Public_Key_Id
             (Slot.Value, Public_Key_Id)
         then
            if not Identity.API_Keys.Credentials.Can_Authenticate (Slot.Value, Now) then
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            elsif not Principal_Is_Active (Repository, Slot.Value.Principal) then
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            elsif Identity.Crypto.Secret_Verifiers.Verify_Text
              (Identity.Crypto.Domains.API_Key, Secret, Slot.Value.Secret_Verifier)
              = Identity.Crypto.Secret_Verifiers.Verified
            then
               Slot.Value.Last_Used_At := (Present => True, Time_Point => Now);
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return
                 (Status    => Identity.Results.Succeeded,
                  Principal => (Present => True, Value => Slot.Value.Principal));
            else
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            end if;
         end if;
      end loop;

      return (Status => Identity.Results.Rejected, Principal => (Present => False));
   end Authenticate_API_Key;

   overriding function Authenticate_API_Key
     (Repository                  : in out Store;
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
   begin
      for Slot of Repository.API_Keys loop
         if Slot.Present
           and then Identity.API_Keys.Credentials.Matches_Public_Key_Id
             (Slot.Value, Public_Key_Id)
         then
            if not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Credential_Version)
            then
               return (Status => Identity.Results.Conflict, Principal => (Present => False));
            elsif not Identity.API_Keys.Credentials.Can_Authenticate (Slot.Value, Now) then
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            elsif not Principal_Is_Active (Repository, Slot.Value.Principal) then
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            elsif Identity.Crypto.Secret_Verifiers.Verify_Text
              (Identity.Crypto.Domains.API_Key, Secret, Slot.Value.Secret_Verifier)
              = Identity.Crypto.Secret_Verifiers.Verified
            then
               Slot.Value.Last_Used_At := (Present => True, Time_Point => Now);
               Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
               return
                 (Status    => Identity.Results.Succeeded,
                  Principal => (Present => True, Value => Slot.Value.Principal));
            else
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            end if;
         end if;
      end loop;

      return (Status => Identity.Results.Rejected, Principal => (Present => False));
   end Authenticate_API_Key;

   overriding function Failure_Count
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Category   : Identity.Attempts.Outcomes.Failure_Category)
      return Identity.Versions.Attempt_Count
   is
      use type Identity.Attempts.Outcomes.Attempt_Outcome;
      use type Identity.Attempts.Outcomes.Failure_Category;
      Count : Identity.Versions.Attempt_Count := 0;
   begin
      for Slot of Repository.Attempts loop
         if Slot.Present
           and then Slot.Value.Principal.Present
           and then Same_Principal (Slot.Value.Principal.Value, Principal)
           and then Slot.Value.Outcome = Identity.Attempts.Outcomes.Failed
           and then Slot.Value.Failure = Category
         then
            if Count < Identity.Versions.Attempt_Count'Last then
               Count := Count + Identity.Versions.Attempt_Count'(1);
            end if;
         end if;
      end loop;
      return Count;
   end Failure_Count;

   overriding function Consume_Recovery_Code
     (Repository : in out Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status
   is
      Found : Boolean;
      Set   : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
   begin
      Find_Recovery_Code_Set (Repository, Set_Id, Found, Set);
      if not Found then
         return Identity.Recovery_Codes.Sets.Unknown;
      end if;

      return Consume_Recovery_Code (Repository, Set_Id, Set.Version, Code);
   end Consume_Recovery_Code;

   overriding function Consume_Recovery_Code
     (Repository       : in out Store;
      Set_Id           : Identity.Identifiers.Entities.Credential_Set_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Code             : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status
   is
      use type Identity.Crypto.Secret_Verifiers.Verification_Outcome;
   begin
      for Slot of Repository.Recovery_Code_Sets loop
         if Slot.Present and then Same_Credential_Set (Slot.Value.Id, Set_Id) then
            if not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return Identity.Recovery_Codes.Sets.State_Conflict;
            end if;

            for Index in 1 .. Slot.Value.Count loop
               if Identity.Crypto.Secret_Verifiers.Verify_Text
                 (Identity.Crypto.Domains.Recovery_Code,
                  Code,
                  Slot.Value.Codes (Index).Secret_Verifier)
                 = Identity.Crypto.Secret_Verifiers.Verified
               then
                  declare
                     Admission : constant Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status :=
                       Identity.Recovery_Codes.Sets.Admit_Matched_Code
                         (Slot.Value.Codes (Index));
                  begin
                     case Admission is
                        when Identity.Recovery_Codes.Sets.Consumed =>
                           null;
                        when others =>
                           return Admission;
                     end case;
                  end;

                  Slot.Value.Codes (Index).State := Identity.Recovery_Codes.Sets.Consumed;
                  Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
                  return Identity.Recovery_Codes.Sets.Consumed;
               end if;
            end loop;

            return Identity.Recovery_Codes.Sets.Not_Verified;
         end if;
      end loop;

      return Identity.Recovery_Codes.Sets.Unknown;
   end Consume_Recovery_Code;

   overriding function Authenticate_External
     (Repository : in out Store;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      Replay_Status : Command_Status;
      Admission     : constant Identity.External_Providers.Assertions.Assertion_Admission_Status :=
        Identity.External_Providers.Assertions.Admit_For_Core (Assertion, Now);
   begin
      if Admission /= Identity.External_Providers.Assertions.Admitted then
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      end if;

      Replay_Status := Register_External_Replay (Repository, Assertion.Assertion_Fingerprint);
      case Replay_Status is
         when Applied =>
            null;
         when State_Conflict =>
            return (Status => Identity.Results.Conflict, Principal => (Present => False));
         when others =>
            return (Status => Identity.Results.Operational_Failure, Principal => (Present => False));
      end case;

      for Binding of Repository.External_Bindings loop
         if Binding.Present
           and then Identity.External_Providers.Bindings.Matches_Assertion
             (Binding.Value, Assertion)
         then
            if Identity.External_Providers.Bindings.Active_Matches_Assertion
              (Binding.Value, Assertion)
            then
               if Principal_Is_Active (Repository, Binding.Value.Principal) then
                  return
                    (Status    => Identity.Results.Succeeded,
                     Principal => (Present => True, Value => Binding.Value.Principal));
               else
                  return (Status => Identity.Results.Rejected, Principal => (Present => False));
               end if;
            else
               return (Status => Identity.Results.Rejected, Principal => (Present => False));
            end if;
         end if;
      end loop;

      return (Status => Identity.Results.Recovery_Action_Required, Principal => (Present => False));
   end Authenticate_External;

   overriding function Authenticate_External
     (Repository               : in out Store;
      Assertion                : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now                      : Identity.Times.Instant;
      Expected_Binding_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      Admission : constant Identity.External_Providers.Assertions.Assertion_Admission_Status :=
        Identity.External_Providers.Assertions.Admit_For_Core (Assertion, Now);
   begin
      if Admission /= Identity.External_Providers.Assertions.Admitted then
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      end if;

      for Binding of Repository.External_Bindings loop
         if Binding.Present
           and then Identity.External_Providers.Bindings.Matches_Assertion
             (Binding.Value, Assertion)
         then
            if not Identity.Versions.Same_Entity_Version
              (Binding.Value.Version, Expected_Binding_Version)
            then
               return (Status => Identity.Results.Conflict, Principal => (Present => False));
            end if;

            return Authenticate_External (Repository, Assertion, Now);
         end if;
      end loop;

      return (Status => Identity.Results.Conflict, Principal => (Present => False));
   end Authenticate_External;

   overriding function Accept_TOTP_Counter
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status
   is
      Found : Boolean;
      Value : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
   begin
      Find_TOTP_Credential (Repository, Credential, Found, Value);
      if not Found then
         return Identity.One_Time_Passwords.Credentials.Unknown;
      end if;

      return Accept_TOTP_Counter (Repository, Credential, Value.Version, Counter);
   end Accept_TOTP_Counter;

   overriding function Accept_TOTP_Counter
     (Repository       : in out Store;
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Counter          : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status
   is
      use type Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;
      Admission : Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;
   begin
      for Slot of Repository.TOTP_Credentials loop
         if Slot.Present and then Same_Credential (Slot.Value.Id, Credential) then
            if not Identity.Versions.Same_Entity_Version
              (Slot.Value.Version, Expected_Version)
            then
               return Identity.One_Time_Passwords.Credentials.State_Conflict;
            end if;

            Admission := Identity.One_Time_Passwords.Credentials.Admit_Counter
              (Slot.Value, Counter);
            if Admission /= Identity.One_Time_Passwords.Credentials.Accepted then
               return Admission;
            end if;

            Slot.Value.Highest_Accepted_Counter := Counter;
            Slot.Value.Version := Identity.Versions.Next_Entity_Version (Slot.Value.Version);
            return Identity.One_Time_Passwords.Credentials.Accepted;
         end if;
      end loop;

      return Identity.One_Time_Passwords.Credentials.Unknown;
   end Accept_TOTP_Counter;

   overriding function Principal_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Principals loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Principal_Count;

   overriding function Account_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Accounts loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Account_Count;

   overriding function Binding_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Bindings loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Binding_Count;

   overriding function Password_Credential_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Passwords loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Password_Credential_Count;

   overriding function Session_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Sessions loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Session_Count;

   overriding function Token_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Tokens loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Token_Count;

   overriding function Authentication_Transaction_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Authentication_Transactions loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Authentication_Transaction_Count;

   overriding function Challenge_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Challenges loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Challenge_Count;

   overriding function API_Key_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.API_Keys loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end API_Key_Count;

   overriding procedure Find_Event
     (Repository : Store;
      Position   : Positive;
      Found      : out Boolean;
      Value      : out Identity.Events.Envelopes.Event_Envelope)
   is
      Seen : Natural := 0;
   begin
      Found := False;
      Value := (others => <>);
      for Slot of Repository.Events loop
         if Slot.Present then
            Seen := Seen + 1;
            if Seen = Position then
               Found := True;
               Value := Slot.Value;
               return;
            end if;
         end if;
      end loop;
   end Find_Event;

   overriding function Event_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Events loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Event_Count;

   overriding function Attempt_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Attempts loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Attempt_Count;

   overriding function Contact_Binding_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Contact_Bindings loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Contact_Binding_Count;

   overriding function Contact_Change_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Contact_Changes loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Contact_Change_Count;

   overriding function Recovery_Code_Set_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Recovery_Code_Sets loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Recovery_Code_Set_Count;

   overriding function Recovery_Transaction_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.Recovery_Transactions loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Recovery_Transaction_Count;

   overriding function External_Binding_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.External_Bindings loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end External_Binding_Count;

   overriding function External_Replay_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.External_Replays loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end External_Replay_Count;

   overriding function TOTP_Credential_Count (Repository : Store) return Natural is
      Count : Natural := 0;
   begin
      for Slot of Repository.TOTP_Credentials loop
         if Slot.Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end TOTP_Credential_Count;
end Identity.Adapters.Repositories.Memory;

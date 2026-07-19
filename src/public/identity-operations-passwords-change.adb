with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Passwords.Credentials;
with Identity.Text.Bounded;

package body Identity.Operations.Passwords.Change is
   function Execute
     (Repository     : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal      : Identity.Identifiers.Entities.Principal_Id;
      New_Credential : Identity.Identifiers.Entities.Credential_Id;
      Current        : Identity.Secrets.Passwords.Presented_Password;
      Replacement    : Identity.Secrets.Passwords.New_Password)
      return Identity.Results.Operation_Status
   is
      use type Identity.Credentials.States.Credential_State;
      use type Identity.Crypto.Password_Hashing.Verification_Outcome;

      Found      : Boolean;
      Existing   : Identity.Passwords.Credentials.Password_Credential_Record;
      Verification : Identity.Crypto.Password_Hashing.Verification_Result;
      Status     : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      Identity.Adapters.Repositories.Stores.Find_Active_Password
        (Repository, Principal, Found, Existing);

      if not Found or else Existing.State /= Identity.Credentials.States.Active then
         return Identity.Results.Rejected;
      end if;

      Verification := Identity.Crypto.Password_Hashing.Verify
        (Current, Identity.Text.Bounded.Image (Existing.Verifier));

      if Verification.Outcome /= Identity.Crypto.Password_Hashing.Verified then
         return Identity.Results.Rejected;
      end if;

      Status := Identity.Adapters.Repositories.Stores.Replace_Password
        (Repository,
         Existing.Id,
         Existing.Version,
         (Id        => New_Credential,
          Principal => Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Identity.Text.Bounded.From_String
            (Identity.Crypto.Password_Hashing.Create_Verifier (Replacement)),
          Version   => 0));

      case Status is
         when Identity.Adapters.Repositories.Stores.Applied =>
            return Identity.Results.Succeeded;
         when Identity.Adapters.Repositories.Stores.Version_Conflict
            | Identity.Adapters.Repositories.Stores.State_Conflict
            | Identity.Adapters.Repositories.Stores.Uniqueness_Conflict =>
            return Identity.Results.Conflict;
         when Identity.Adapters.Repositories.Stores.Capacity_Conflict =>
            return Identity.Results.Operational_Failure;
      end case;
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Change_Request)
      return Identity.Results.Operation_Status
   is
      use type Identity.Credentials.States.Credential_State;
      use type Identity.Crypto.Password_Hashing.Verification_Outcome;

      Found        : Boolean;
      Existing     : Identity.Passwords.Credentials.Password_Credential_Record;
      Verification : Identity.Crypto.Password_Hashing.Verification_Result;
      Status       : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      Identity.Adapters.Repositories.Stores.Find_Active_Password
        (Repository, Request.Principal, Found, Existing);

      if not Found or else Existing.State /= Identity.Credentials.States.Active then
         return Identity.Results.Rejected;
      end if;

      Verification := Identity.Crypto.Password_Hashing.Verify
        (Request.Current, Identity.Text.Bounded.Image (Existing.Verifier));

      if Verification.Outcome /= Identity.Crypto.Password_Hashing.Verified then
         return Identity.Results.Rejected;
      end if;

      Status := Identity.Adapters.Repositories.Stores.Replace_Password
        (Repository,
         Existing.Id,
         Request.Expected_Current_Version,
         (Id        => Request.New_Credential,
          Principal => Request.Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Identity.Text.Bounded.From_String
            (Identity.Crypto.Password_Hashing.Create_Verifier (Request.Replacement)),
          Version   => 0));

      case Status is
         when Identity.Adapters.Repositories.Stores.Applied =>
            return Identity.Results.Succeeded;
         when Identity.Adapters.Repositories.Stores.Version_Conflict
            | Identity.Adapters.Repositories.Stores.State_Conflict
            | Identity.Adapters.Repositories.Stores.Uniqueness_Conflict =>
            return Identity.Results.Conflict;
         when Identity.Adapters.Repositories.Stores.Capacity_Conflict =>
            return Identity.Results.Operational_Failure;
      end case;
   end Execute;

   --  The plain form reports an operation status rather than a store command
   --  status, so the event outcome is derived from it directly: a wrong
   --  current password is a rejection, a losing version check is a conflict,
   --  and anything operational is a failure.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Change_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Results.Operation_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Results.Operation_Status;
   begin
      --  Reserve first: refusing here leaves the stored password untouched.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Results.Operational_Failure;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Password_Changed,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String
                   (Request.New_Credential)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful change.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Results.Operational_Failure;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Passwords.Change;

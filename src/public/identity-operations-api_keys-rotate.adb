with Identity.API_Keys.Policies;
with Identity.Credentials.States;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Operations.Audit;

package body Identity.Operations.API_Keys.Rotate is
   use type Identity.API_Keys.Policies.Issue_Lifetime_Status;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_API_Key
        (Repository, Predecessor, Successor);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      if Identity.API_Keys.Policies.Evaluate_Issue_Lifetime
        (Identity.API_Keys.Policies.API_Key_Policy'
           (Maximum_Active_Keys_Per_Principal => 16,
            Maximum_Overlap => 86_400,
            Expiration_Required => True),
         Request.Created_At,
         Request.Expires_At)
        /= Identity.API_Keys.Policies.Issue_Lifetime_Allowed
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      return Identity.Adapters.Repositories.Stores.Rotate_API_Key
        (Repository,
         Request.Predecessor,
         (Id              => Request.Id,
          Principal       => Request.Principal,
          Public_Key_Id   => Request.Public_Key_Id,
          Credential_Class_Id => Request.Credential_Class_Id,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.API_Key, Request.Secret),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Created_At,
          Expires_At      => Request.Expires_At,
          Last_Used_At    => (Present => False, Time_Point => 0),
          Rotation_Generation => Request.Rotation_Generation,
          Version         => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      if Identity.API_Keys.Policies.Evaluate_Issue_Lifetime
        (Identity.API_Keys.Policies.API_Key_Policy'
           (Maximum_Active_Keys_Per_Principal => 16,
            Maximum_Overlap => 86_400,
            Expiration_Required => True),
         Request.Request.Created_At,
         Request.Request.Expires_At)
        /= Identity.API_Keys.Policies.Issue_Lifetime_Allowed
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      return Identity.Adapters.Repositories.Stores.Rotate_API_Key
        (Repository,
         Request.Request.Predecessor,
         Request.Expected_Predecessor_Version,
         (Id              => Request.Request.Id,
          Principal       => Request.Request.Principal,
          Public_Key_Id   => Request.Request.Public_Key_Id,
          Credential_Class_Id => Request.Request.Credential_Class_Id,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.API_Key, Request.Request.Secret),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Request.Created_At,
          Expires_At      => Request.Request.Expires_At,
          Last_Used_At    => (Present => False, Time_Point => 0),
          Rotation_Generation => Request.Request.Rotation_Generation,
          Version         => 0));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Rotate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: a rotation that cannot be recorded is refused rather
      --  than applied, so no key is ever retired or issued unaudited.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.API_Key_Rotated,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve before mutating, exactly as the request form does: a
      --  transition that cannot be recorded is refused rather than applied.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Predecessor, Successor);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.API_Key_Rotated,
              Subject     => Identity.Operations.Audit.Subject_Of (Successor.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Successor.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Rotate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve before mutating, exactly as the request form does: a
      --  transition that cannot be recorded is refused rather than applied.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.API_Key_Rotated,
              Subject     => Identity.Operations.Audit.Subject_Of
                (Request.Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Request.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.API_Keys.Rotate;

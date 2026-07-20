with Identity.Adapters.Repositories.Idempotency;
with Identity.Credentials.States;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.API_Keys.Policies;

package body Identity.Operations.API_Keys.Issue is
   use type Identity.API_Keys.Policies.Issue_Lifetime_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Issue_API_Key (Repository, Credential);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Issue_Request)
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

      return Identity.Adapters.Repositories.Stores.Issue_API_Key
        (Repository,
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
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Issue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would leave a usable key
      --  whose issue nobody can trace.
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
              Type_Id     => Identity.Events.Types.API_Key_Issued,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Request.Public_Key_Id,
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
      Request     : Issue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;

      Kind : constant Identity.Operations.Idempotency.Idempotent_Operation_Kind :=
        Identity.Operations.Idempotency.API_Key_Issue;

      --  Reserve before the transition: a duplicate issue discovered after the
      --  fact is a live credential that cannot be taken back silently.
      Reserved : constant Identity.Adapters.Repositories.Idempotency.Reservation :=
        (if Identity.Operations.Idempotency.Valid (Key)
         then Identity.Adapters.Repositories.Stores.Reserve_Idempotency
                (Repository, Kind, Key)
         else Identity.Operations.Replay.Unusable_Key (Kind));

      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      if not Identity.Adapters.Repositories.Idempotency.Fresh_Status
        (Reserved.Status)
      then
         return Identity.Operations.Replay.Refused (Reserved);
      end if;

      Status := Execute (Repository, Request, Context, Event, Recorded_At);

      if Status /= Identity.Adapters.Repositories.Stores.Applied then
         --  Nothing was applied, so nothing may be replayed under this key.
         return (Status => Status,
                 Decision => Identity.Operations.Idempotency.Fresh);
      end if;

      return Identity.Operations.Replay.Completed
        (Status,
         Identity.Adapters.Repositories.Stores.Complete_Idempotency
           (Repository, Kind, Key));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.API_Keys.Credentials.API_Key_Credential_Record;
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

      Status := Execute (Repository, Credential);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.API_Key_Issued,
              Subject     => Identity.Operations.Audit.Subject_Of (Credential.Principal),
              Target      => Credential.Public_Key_Id,
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
end Identity.Operations.API_Keys.Issue;

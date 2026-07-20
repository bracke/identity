with Identity.Adapters.Repositories.Idempotency;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Operations.Audit;

package body Identity.Operations.Sessions.Rotate is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_Session
        (Repository, Predecessor, Successor);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_Session
        (Repository,
         Request.Predecessor,
         (Id              => Request.Id,
          Family          => Request.Family,
          Principal       => Request.Principal,
          Credential      => Request.Credential,
          External_Provider => Request.External_Provider,
          Public_Reference => Request.Public_Reference,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Session_Token, Request.Secret),
          Assurance       => Request.Assurance,
          Attributes      => Request.Attributes,
          Created_At      => Request.Created_At,
          Original_Authenticated_At => Request.Original_Authenticated_At,
          Primary_Authenticated_At => Request.Primary_Authenticated_At,
          MFA_Completed_At => Request.MFA_Completed_At,
          Step_Up_At      => Request.Step_Up_At,
          Last_Seen_At    => Request.Last_Seen_At,
          Idle_Expires_At => Request.Idle_Expires_At,
          Absolute_Expires_At => Request.Absolute_Expires_At,
          Remembered      => Request.Remembered,
          Generation      => Request.Generation,
          State           => Identity.Sessions.Definitions.Active,
          Version         => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_Session
        (Repository,
         Request.Request.Predecessor,
         Request.Expected_Predecessor_Version,
         (Id              => Request.Request.Id,
          Family          => Request.Request.Family,
          Principal       => Request.Request.Principal,
          Credential      => Request.Request.Credential,
          External_Provider => Request.Request.External_Provider,
          Public_Reference => Request.Request.Public_Reference,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Session_Token, Request.Request.Secret),
          Assurance       => Request.Request.Assurance,
          Attributes      => Request.Request.Attributes,
          Created_At      => Request.Request.Created_At,
          Original_Authenticated_At =>
            Request.Request.Original_Authenticated_At,
          Primary_Authenticated_At =>
            Request.Request.Primary_Authenticated_At,
          MFA_Completed_At => Request.Request.MFA_Completed_At,
          Step_Up_At      => Request.Request.Step_Up_At,
          Last_Seen_At    => Request.Request.Last_Seen_At,
          Idle_Expires_At => Request.Request.Idle_Expires_At,
          Absolute_Expires_At => Request.Request.Absolute_Expires_At,
          Remembered      => Request.Request.Remembered,
          Generation      => Request.Request.Generation,
          State           => Identity.Sessions.Definitions.Active,
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
      --  than applied, so the predecessor is never retired unaudited.
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
              Type_Id     => Identity.Events.Types.Session_Rotated,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Request.Public_Reference,
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Rotate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;

      Kind : constant Identity.Operations.Idempotency.Idempotent_Operation_Kind :=
        Identity.Operations.Idempotency.Session_Rotate;

      --  Reserve before the transition: rotating twice retires a session the
      --  client is still holding, and no later check can put that back.
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
end Identity.Operations.Sessions.Rotate;

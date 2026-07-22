with Identity.Sessions.Binding;
with Identity.Crypto.Domains;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Crypto.Secret_Verifiers;

package body Identity.Operations.Sessions.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session    : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Create_Session (Repository, Session);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Create_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Create_Session
        (Repository,
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
          Client_Binding  => Identity.Sessions.Binding.Unbound,
          State           => Identity.Sessions.Definitions.Active,
          Version         => 0));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Create_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would leave a session with
      --  no record of its creation.
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
              Type_Id     => Identity.Events.Types.Session_Created,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Request.Public_Reference,
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
      Session     : Identity.Sessions.Definitions.Session_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would leave a session with
      --  no record of its creation.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Session);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Session_Created,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Session.Principal),
              Target      => Session.Public_Reference,
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
end Identity.Operations.Sessions.Create;

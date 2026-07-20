with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Sessions.Revoke is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session    : Identity.Identifiers.Entities.Session_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Revoke_Session (Repository, Session);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Revoke_Session
        (Repository, Request.Session, Request.Expected_Session_Version);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Revoke_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave a revoked session
      --  with no record of the revocation.
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
              Type_Id     => Identity.Events.Types.Session_Revoked,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Session)),
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
      Session     : Identity.Identifiers.Entities.Session_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave a revoked session
      --  with no record of the revocation.
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
              Type_Id     => Identity.Events.Types.Session_Revoked,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Session)),
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
end Identity.Operations.Sessions.Revoke;

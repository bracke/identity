with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Principals.Retire is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Retire_Principal
        (Repository, Principal);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Retire_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Retire_Principal
        (Repository, Request.Principal, Request.Expected_Version);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Retire_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would have already retired the
      --  principal with nothing on record.
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
              Type_Id     => Identity.Events.Types.Principal_Retired,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Principal)),
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
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would have already retired the
      --  principal with nothing on record.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Principal);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Principal_Retired,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Principal)),
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
end Identity.Operations.Principals.Retire;

with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Regenerate_Recovery_Codes is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Regenerate_Recovery_Code_Set
        (Repository, Codes);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Regenerate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Regenerate_Recovery_Code_Set
        (Repository,
         Identity.Operations.Factors.Generate_Recovery_Codes.To_Record (Request));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Regenerate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Regenerate_Recovery_Code_Set
        (Repository,
         Identity.Operations.Factors.Generate_Recovery_Codes.To_Record (Request.Request),
         Request.Expected_Affected_Count);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Regenerate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would have already revoked the
      --  previous codes with nothing on record.
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
              Type_Id     => Identity.Events.Types.Recovery_Codes_Generated,
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

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes       : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
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

      Status := Execute (Repository, Codes);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Recovery_Codes_Generated,
              Subject     => Identity.Operations.Audit.Subject_Of (Codes.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Codes.Id)),
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
      Request     : Regenerate_Request;
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
              Type_Id     => Identity.Events.Types.Recovery_Codes_Generated,
              Subject     => Identity.Operations.Audit.Subject_Of (Request.Principal),
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
end Identity.Operations.Factors.Regenerate_Recovery_Codes;

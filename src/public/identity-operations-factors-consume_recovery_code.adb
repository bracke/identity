with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Consume_Recovery_Code is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Recovery_Code_Consume_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Consume_Recovery_Code (Repository, Set_Id, Code);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Consume_Request)
      return Recovery_Code_Consume_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Consume_Recovery_Code
        (Repository,
         Request.Set_Id,
         Request.Expected_Version,
         Request.Code);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Consume_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Recovery_Code_Consume_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Recovery_Code_Consume_Status;
   begin
      --  Reserve first: refusing here leaves the set untouched, whereas
      --  discovering a full event log afterwards would spend a recovery code
      --  with nothing to show for it.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Recovery_Codes.Sets.State_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Recovery_Code_Consumed,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Set_Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Recovery_Codes.Sets.State_Conflict;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Set_Id      : Identity.Identifiers.Entities.Credential_Set_Id;
      Code        : Identity.Secrets.Recovery_Codes.Recovery_Code;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Recovery_Code_Consume_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Recovery_Code_Consume_Status;
   begin
      --  Reserve before mutating, exactly as the request form does: a
      --  transition that cannot be recorded is refused rather than applied.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Recovery_Codes.Sets.State_Conflict;
      end if;

      Status := Execute (Repository, Set_Id, Code);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Recovery_Code_Consumed,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Set_Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Recovery_Codes.Sets.State_Conflict;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Factors.Consume_Recovery_Code;

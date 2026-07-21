with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Verification.Advance_Contact_Change is
   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Verification.Changes.Contact_Change_Action;
      Expected_Version : Identity.Versions.Entity_Version;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: a change must not advance through a gate with nothing
      --  recorded, exactly as beginning and completing the change reserve.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Identity.Adapters.Repositories.Stores.Advance_Contact_Change
        (Repository, Token, Principal, Action, Expected_Version);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Contact_Change_Advanced,
              Subject     => Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Token)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Verification.Advance_Contact_Change;

with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Authentication.Begin_Transaction is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_Authentication_Transaction
        (Repository, Transaction);
   end Execute;

   --  A transaction verdict is not a store command status: an unknown or
   --  wrongly-staged transaction is a conflict, not a credential rejection.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Authentication.Transactions
        .Authentication_Transaction_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log found afterwards would leave a live sign-in attempt
      --  with no record of where it came from.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Authentication.Transactions.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Transaction);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     =>
                Identity.Events.Types.Authentication_Transaction_Began,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Transaction.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Transaction.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Authentication.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Authentication.Begin_Transaction;

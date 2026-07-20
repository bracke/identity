with Identity.Adapters.Repositories.Idempotency;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Recovery.Begin_Recovery is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_Recovery (Repository, Transaction);
   end Execute;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Recovery.Transactions.Recovery_Transition_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave an open recovery
      --  transaction with no record of who opened it.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Recovery.Transactions.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Transaction);

      declare
         --  The transaction id, not the account, is what a later evidence or
         --  completion event ties back to.
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Recovery_Began,
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
            return Identity.Recovery.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Recovery_Outcome
   is
      use type Identity.Recovery.Transactions.Recovery_Transition_Status;

      Kind : constant Identity.Operations.Idempotency.Idempotent_Operation_Kind :=
        Identity.Operations.Idempotency.Recovery_Begin;

      --  Reserve before the transition: a second recovery transaction opened
      --  by a retry is a second path to the same account, and closing one of
      --  them afterwards does not close the other.
      Reserved : constant Identity.Adapters.Repositories.Idempotency.Reservation :=
        (if Identity.Operations.Idempotency.Valid (Key)
         then Identity.Adapters.Repositories.Stores.Reserve_Idempotency
                (Repository, Kind, Key)
         else Identity.Operations.Replay.Unusable_Key (Kind));

      Status : Identity.Recovery.Transactions.Recovery_Transition_Status;
   begin
      if not Identity.Adapters.Repositories.Idempotency.Fresh_Status
        (Reserved.Status)
      then
         return Identity.Operations.Replay.Refused (Reserved);
      end if;

      Status := Execute (Repository, Transaction, Context, Event, Recorded_At);

      if Status /= Identity.Recovery.Transactions.Applied then
         --  Nothing was applied, so nothing may be replayed under this key.
         return (Status => Status,
                 Decision => Identity.Operations.Idempotency.Fresh);
      end if;

      return Identity.Operations.Replay.Completed
        (Status,
         Identity.Adapters.Repositories.Stores.Complete_Idempotency
           (Repository, Kind, Key));
   end Execute;
end Identity.Operations.Recovery.Begin_Recovery;

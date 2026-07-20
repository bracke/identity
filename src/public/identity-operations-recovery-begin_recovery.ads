with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Operations.Idempotency;
with Identity.Operations.Replay;
with Identity.Recovery.Transactions;
with Identity.Times;

package Identity.Operations.Recovery.Begin_Recovery is

   --  Audited form. Emits identity.recovery.began for the transition, and
   --  refuses the operation if the store cannot accept that event, so an
   --  account recovery never starts without a record of who started it.
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   --  Idempotent form. Recovery is begun by whoever claims to have lost their
   --  credential, over channels that retry freely. Reserving the key before
   --  the transition keeps a retry from opening a second recovery transaction
   --  for the same account, each with its own evidence clock.
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Recovery_Outcome;
end Identity.Operations.Recovery.Begin_Recovery;

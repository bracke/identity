with Identity.Adapters.Repositories.Idempotency;
with Identity.Adapters.Repositories.Stores;
with Identity.Operations.Idempotency;
with Identity.Recovery.Transactions;

--  Replay protection shared by the idempotent operation overloads.
--
--  An externally triggered, side-effecting operation can be retried by a
--  client that never learned whether its first attempt landed: the answer was
--  lost, the connection dropped, the caller timed out. Each such operation
--  therefore offers an overload taking an idempotency key. The key is reserved
--  BEFORE the transition, and a reservation that reports a replay returns the
--  recorded outcome instead of performing the transition a second time.
--
--  Only an applied transition closes its reservation. A refused transition
--  leaves the record open, so a retry with the same key is reported as
--  In_Progress rather than being mistaken for a completed one; a caller that
--  wants that transition attempted again must present a fresh key.
--
--  This package declares only the shared result shape and the mappings from a
--  reservation onto an operation verdict. The reservation itself is made by
--  each operation, so the capability is backed by the operations that use it
--  rather than by a helper standing in for them.
package Identity.Operations.Replay is

   --  Verdict of an idempotent operation: what the store did, and whether this
   --  call is the one that did it.
   type Command_Outcome is record
      Status   : Identity.Adapters.Repositories.Stores.Command_Status :=
        Identity.Adapters.Repositories.Stores.Applied;
      Decision : Identity.Operations.Idempotency.Idempotency_Decision :=
        Identity.Operations.Idempotency.Fresh;
   end record;

   --  Recovery transitions report their own status type, so they need their
   --  own verdict shape; the decision half is identical.
   type Recovery_Outcome is record
      Status   : Identity.Recovery.Transactions.Recovery_Transition_Status :=
        Identity.Recovery.Transactions.Applied;
      Decision : Identity.Operations.Idempotency.Idempotency_Decision :=
        Identity.Operations.Idempotency.Fresh;
   end record;

   --  True when this call performed the transition rather than reporting an
   --  earlier one.
   function Performed (Outcome : Command_Outcome) return Boolean is
     (Identity.Operations.Idempotency.Fresh_Decision (Outcome.Decision));

   function Performed (Outcome : Recovery_Outcome) return Boolean is
     (Identity.Operations.Idempotency.Fresh_Decision (Outcome.Decision));

   --  True when the recorded outcome of an earlier call was returned and no
   --  side effect was repeated.
   function Was_Replayed (Outcome : Command_Outcome) return Boolean is
     (Identity.Operations.Idempotency.Replay_Decision (Outcome.Decision));

   function Was_Replayed (Outcome : Recovery_Outcome) return Boolean is
     (Identity.Operations.Idempotency.Replay_Decision (Outcome.Decision));

   --  A key carrying no bytes cannot identify a request, and every empty key
   --  compares equal to every other. Refusing it without touching the store
   --  keeps unrelated requests from colliding on emptiness.
   function Unusable_Key
     (Operation : Identity.Operations.Idempotency.Idempotent_Operation_Kind)
      return Identity.Adapters.Repositories.Idempotency.Reservation is
     ((Status    => Identity.Adapters.Repositories.Idempotency.Conflict,
       Operation => Operation,
       Key       => Identity.Operations.Idempotency.From_String (""),
       Completed => False,
       Version   => 0));

   --  Verdict for a reservation that refuses the transition. A replay reports
   --  the recorded outcome -- the transition applied on the call that closed
   --  this record -- without performing it again. Everything else is a refusal
   --  under which nothing was applied: an unfinished earlier attempt, the same
   --  key used for a different operation, an exhausted record table, or a
   --  store fault. Command_Status has no separate infrastructure verdict, so
   --  those collapse onto State_Conflict; the decision half keeps the cause.
   function Refused
     (Value : Identity.Adapters.Repositories.Idempotency.Reservation)
      return Command_Outcome is
     ((Status =>
         (case Value.Status is
            when Identity.Adapters.Repositories.Idempotency.Replayed =>
              Identity.Adapters.Repositories.Stores.Applied,
            when Identity.Adapters.Repositories.Idempotency.Capacity_Exceeded =>
              Identity.Adapters.Repositories.Stores.Capacity_Conflict,
            when others =>
              Identity.Adapters.Repositories.Stores.State_Conflict),
       Decision =>
         Identity.Adapters.Repositories.Idempotency.To_Operation_Result
           (Value).Decision));

   function Refused
     (Value : Identity.Adapters.Repositories.Idempotency.Reservation)
      return Recovery_Outcome is
     ((Status =>
         (case Value.Status is
            when Identity.Adapters.Repositories.Idempotency.Replayed =>
              Identity.Recovery.Transactions.Applied,
            when Identity.Adapters.Repositories.Idempotency.Capacity_Exceeded =>
              Identity.Recovery.Transactions.Capacity_Conflict,
            when others =>
              Identity.Recovery.Transactions.State_Conflict),
       Decision =>
         Identity.Adapters.Repositories.Idempotency.To_Operation_Result
           (Value).Decision));

   --  Verdict once the transition applied, given the result of closing the
   --  record. Closing it is what makes the next call with the same key a
   --  replay. If it could not be closed the transition still stands -- it is
   --  not undone to keep a bookkeeping record tidy -- and the decision says
   --  so, because a retry under that key will then be refused as In_Progress
   --  rather than replayed.
   function Completed
     (Status : Identity.Adapters.Repositories.Stores.Command_Status;
      Value  : Identity.Adapters.Repositories.Idempotency.Reservation)
      return Command_Outcome is
     ((Status   => Status,
       Decision =>
         (if Value.Completed
            and then Identity.Adapters.Repositories.Idempotency.Fresh_Status
                       (Value.Status)
          then Identity.Operations.Idempotency.Fresh
          else Identity.Operations.Idempotency.Infrastructure_Failure)));

   function Completed
     (Status : Identity.Recovery.Transactions.Recovery_Transition_Status;
      Value  : Identity.Adapters.Repositories.Idempotency.Reservation)
      return Recovery_Outcome is
     ((Status   => Status,
       Decision =>
         (if Value.Completed
            and then Identity.Adapters.Repositories.Idempotency.Fresh_Status
                       (Value.Status)
          then Identity.Operations.Idempotency.Fresh
          else Identity.Operations.Idempotency.Infrastructure_Failure)));

end Identity.Operations.Replay;

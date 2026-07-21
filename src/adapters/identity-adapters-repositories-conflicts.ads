with Identity.Adapters.Repositories.Idempotency;

package Identity.Adapters.Repositories.Conflicts is
   pragma Pure;
   type Conflict_Category is
     (Version_Conflict, State_Conflict, Uniqueness_Conflict, Replay_Conflict,
      Idempotency_Conflict, Capacity_Conflict, Serialization_Conflict);

   --  Classify a concrete idempotency outcome into the canonical conflict
   --  taxonomy. This is what makes Replay_Conflict, Idempotency_Conflict and
   --  Serialization_Conflict reachable from real outcomes rather than dead
   --  taxonomy values: a replayed idempotent operation is a one-time-use
   --  replay, a stored/parameter mismatch under the same key is an idempotency
   --  conflict, and two operations in flight under one key is a serialization
   --  conflict. Only meaningful when Is_Conflict holds.
   function Is_Conflict
     (Status : Identity.Adapters.Repositories.Idempotency.Idempotency_Status)
      return Boolean is
     (Status in Identity.Adapters.Repositories.Idempotency.Replayed
              | Identity.Adapters.Repositories.Idempotency.In_Progress
              | Identity.Adapters.Repositories.Idempotency.Conflict
              | Identity.Adapters.Repositories.Idempotency.Capacity_Exceeded);

   function Classify
     (Status : Identity.Adapters.Repositories.Idempotency.Idempotency_Status)
      return Conflict_Category is
     (case Status is
         when Identity.Adapters.Repositories.Idempotency.Replayed =>
           Replay_Conflict,
         when Identity.Adapters.Repositories.Idempotency.Conflict =>
           Idempotency_Conflict,
         when Identity.Adapters.Repositories.Idempotency.In_Progress =>
           Serialization_Conflict,
         when others =>
           Capacity_Conflict)
     with Pre => Is_Conflict (Status);

   function Retryable (Category : Conflict_Category) return Boolean is
     (Category in Version_Conflict | Serialization_Conflict);

   function State_Predicate_Failed (Category : Conflict_Category) return Boolean is
     (Category = State_Conflict);

   function Uniqueness_Rejected (Category : Conflict_Category) return Boolean is
     (Category = Uniqueness_Conflict);

   function Replay_Rejected (Category : Conflict_Category) return Boolean is
     (Category = Replay_Conflict);

   function Idempotency_Rejected (Category : Conflict_Category) return Boolean is
     (Category = Idempotency_Conflict);

   function Capacity_Rejected (Category : Conflict_Category) return Boolean is
     (Category = Capacity_Conflict);

   function Serialization_Rejected (Category : Conflict_Category) return Boolean is
     (Category = Serialization_Conflict);

   function Concurrency_Conflict (Category : Conflict_Category) return Boolean is
     (Category in Version_Conflict | Serialization_Conflict);

   function One_Time_Use_Conflict (Category : Conflict_Category) return Boolean is
     (Category in Replay_Conflict | Idempotency_Conflict);
end Identity.Adapters.Repositories.Conflicts;

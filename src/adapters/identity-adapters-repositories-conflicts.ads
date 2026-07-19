package Identity.Adapters.Repositories.Conflicts is
   pragma Pure;
   type Conflict_Category is
     (Version_Conflict, State_Conflict, Uniqueness_Conflict, Replay_Conflict,
      Idempotency_Conflict, Capacity_Conflict, Serialization_Conflict);

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

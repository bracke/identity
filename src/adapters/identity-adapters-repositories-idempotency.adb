package body Identity.Adapters.Repositories.Idempotency is
   function To_Operation_Result
     (Value : Reservation) return Identity.Operations.Idempotency.Idempotency_Result is
   begin
      case Value.Status is
         when Fresh =>
            return
              (Decision => Identity.Operations.Idempotency.Fresh,
               State =>
                 (if Value.Completed
                  then Identity.Operations.Idempotency.Completed
                  else Identity.Operations.Idempotency.Reserved),
               One_Time_Output_Allowed => Value.Completed);
         when Replayed =>
            return
              (Decision => Identity.Operations.Idempotency.Replay_Completed,
               State => Identity.Operations.Idempotency.Completed,
               One_Time_Output_Allowed => False);
         when In_Progress =>
            return
              (Decision => Identity.Operations.Idempotency.In_Progress,
               State => Identity.Operations.Idempotency.Reserved,
               One_Time_Output_Allowed => False);
         when Conflict =>
            return
              (Decision => Identity.Operations.Idempotency.Conflict,
               State => Identity.Operations.Idempotency.Reserved,
               One_Time_Output_Allowed => False);
         when Capacity_Exceeded =>
            return
              (Decision => Identity.Operations.Idempotency.Capacity_Exceeded,
               State => Identity.Operations.Idempotency.Reserved,
               One_Time_Output_Allowed => False);
         when Infrastructure_Failure =>
            return
              (Decision => Identity.Operations.Idempotency.Infrastructure_Failure,
               State => Identity.Operations.Idempotency.Reserved,
               One_Time_Output_Allowed => False);
      end case;
   end To_Operation_Result;
end Identity.Adapters.Repositories.Idempotency;

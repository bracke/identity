package body Identity.Operations.Idempotency is
   function Fresh_Decision (Decision : Idempotency_Decision) return Boolean is
     (Decision = Fresh);

   function Replay_Decision (Decision : Idempotency_Decision) return Boolean is
     (Decision = Replay_Completed);

   function In_Progress_Decision
     (Decision : Idempotency_Decision) return Boolean is
     (Decision = In_Progress);

   function Conflict_Decision (Decision : Idempotency_Decision) return Boolean is
     (Decision = Conflict);

   function Capacity_Rejected (Decision : Idempotency_Decision) return Boolean is
     (Decision = Capacity_Exceeded);

   function Infrastructure_Failed
     (Decision : Idempotency_Decision) return Boolean is
     (Decision = Infrastructure_Failure);

   function Operational_Failure
     (Decision : Idempotency_Decision) return Boolean is
     (Decision in Capacity_Exceeded | Infrastructure_Failure);

   function Terminal_Decision
     (Decision : Idempotency_Decision) return Boolean is
     (Decision in Replay_Completed
              | Conflict
              | Capacity_Exceeded
              | Infrastructure_Failure);

   function No_Mutation (Decision : Idempotency_Decision) return Boolean is
     (Decision in Replay_Completed
              | In_Progress
              | Conflict
              | Capacity_Exceeded
              | Infrastructure_Failure);

   function Reserved_State (State : Completion_State) return Boolean is
     (State = Reserved);

   function Completed_State (State : Completion_State) return Boolean is
     (State = Completed);

   function Abandoned_State (State : Completion_State) return Boolean is
     (State = Abandoned);

   function Terminal_State (State : Completion_State) return Boolean is
     (State in Completed | Abandoned);

   function Validate_Input (Value : String) return Idempotency_Key_Status is
   begin
      if Value'Length = 0 then
         return Empty;
      elsif Value'Length > Identity.Limits.Max_Public_Text_Bytes then
         return Too_Large;
      else
         return Accepted;
      end if;
   end Validate_Input;

   function From_String (Value : String) return Idempotency_Key is
     ((Value => Identity.Text.Bounded.From_String (Value)));

   function Image (Value : Idempotency_Key) return String is
     (Identity.Text.Bounded.Image (Value.Value));

   function Length (Value : Idempotency_Key) return Idempotency_Key_Length is
     (Identity.Text.Bounded.Length (Value.Value));

   function Equal (Left, Right : Idempotency_Key) return Boolean is
     (Identity.Text.Bounded.Equal (Left.Value, Right.Value));

   function Secret_Output_Permitted (Result : Idempotency_Result) return Boolean is
     (Result.Decision = Fresh
      and then Result.State = Completed
      and then Result.One_Time_Output_Allowed);

   function Retry_Is_Safe (Result : Idempotency_Result) return Boolean is
     (Result.Decision = Replay_Completed
      or else Result.Decision = In_Progress
      or else Result.Decision = Conflict);
end Identity.Operations.Idempotency;

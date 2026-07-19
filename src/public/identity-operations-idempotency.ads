with Identity.Limits;
with Identity.Text.Bounded;

package Identity.Operations.Idempotency is
   pragma Pure;

   subtype Idempotency_Key_Length is Natural range 0 .. Identity.Limits.Max_Public_Text_Bytes;

   type Idempotency_Key is private;
   type Idempotency_Key_Status is (Accepted, Empty, Too_Large);

   type Idempotent_Operation_Kind is
     (Password_Reset_Request,
      Contact_Verification_Request,
      Recovery_Begin,
      API_Key_Issue,
      Session_Rotate);

   type Idempotency_Decision is
     (Fresh,
      Replay_Completed,
      In_Progress,
      Conflict,
      Capacity_Exceeded,
      Infrastructure_Failure);

   type Completion_State is (Reserved, Completed, Abandoned);

   function Fresh_Decision (Decision : Idempotency_Decision) return Boolean;
   function Replay_Decision (Decision : Idempotency_Decision) return Boolean;
   function In_Progress_Decision (Decision : Idempotency_Decision) return Boolean;
   function Conflict_Decision (Decision : Idempotency_Decision) return Boolean;
   function Capacity_Rejected (Decision : Idempotency_Decision) return Boolean;
   function Infrastructure_Failed (Decision : Idempotency_Decision) return Boolean;
   function Operational_Failure (Decision : Idempotency_Decision) return Boolean;
   function Terminal_Decision (Decision : Idempotency_Decision) return Boolean;
   function No_Mutation (Decision : Idempotency_Decision) return Boolean;

   function Reserved_State (State : Completion_State) return Boolean;
   function Completed_State (State : Completion_State) return Boolean;
   function Abandoned_State (State : Completion_State) return Boolean;
   function Terminal_State (State : Completion_State) return Boolean;

   function Accepted_Key (Status : Idempotency_Key_Status) return Boolean is
     (Status = Accepted);

   function Rejected_Key (Status : Idempotency_Key_Status) return Boolean is
     (Status /= Accepted);

   function Missing_Key (Status : Idempotency_Key_Status) return Boolean is
     (Status = Empty);

   function Size_Rejected (Status : Idempotency_Key_Status) return Boolean is
     (Status = Too_Large);

   function Validate_Input (Value : String) return Idempotency_Key_Status;

   function From_String (Value : String) return Idempotency_Key
     with Pre => Value'Length <= Identity.Limits.Max_Public_Text_Bytes;

   function Image (Value : Idempotency_Key) return String;
   function Length (Value : Idempotency_Key) return Idempotency_Key_Length;
   function Equal (Left, Right : Idempotency_Key) return Boolean;
   function Valid (Value : Idempotency_Key) return Boolean is
     (Length (Value) > 0);

   type Idempotency_Result is record
      Decision              : Idempotency_Decision := Fresh;
      State                 : Completion_State := Reserved;
      One_Time_Output_Allowed : Boolean := False;
   end record;

   function Secret_Output_Permitted (Result : Idempotency_Result) return Boolean;
   function Retry_Is_Safe (Result : Idempotency_Result) return Boolean;

private
   type Idempotency_Key is record
      Value : Identity.Text.Bounded.Bounded_Text;
   end record;
end Identity.Operations.Idempotency;

package Identity.Times is
   pragma Pure;

   type Instant is range -2**63 .. 2**63 - 1;
   type Duration_Seconds is range 0 .. 2**63 - 1;

   type Deadline is record
      Present : Boolean := False;
      Time_Point : Instant := 0;
   end record;

   type Expiration is record
      Present : Boolean := False;
      Time_Point : Instant := 0;
   end record;

   --  Result of a bounded instant addition. Ok is False exactly when the sum
   --  would pass Instant'Last, in which case Value saturates there.
   type Instant_Sum is record
      Ok    : Boolean := False;
      Value : Instant := 0;
   end record;

   --  SPARK-analysable form of Add. Functions with "out" parameters are not
   --  legal in SPARK, so callers inside the proof scope use this instead.
   function Sum (Base : Instant; Span : Duration_Seconds) return Instant_Sum
     with Post => Sum'Result.Ok = (Base <= Instant'Last - Instant (Span))
                  and then (if not Sum'Result.Ok
                            then Sum'Result.Value = Instant'Last);

   function Add (Base : Instant; Span : Duration_Seconds; Ok : out Boolean) return Instant;
   function Expired (Now : Instant; Boundary : Expiration) return Boolean;
end Identity.Times;

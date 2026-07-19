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

   function Add (Base : Instant; Span : Duration_Seconds; Ok : out Boolean) return Instant;
   function Expired (Now : Instant; Boundary : Expiration) return Boolean;
end Identity.Times;

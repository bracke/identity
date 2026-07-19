package body Identity.Times is
   function Sum (Base : Instant; Span : Duration_Seconds) return Instant_Sum is
   begin
      if Base > Instant'Last - Instant (Span) then
         return (Ok => False, Value => Instant'Last);
      end if;
      return (Ok => True, Value => Base + Instant (Span));
   end Sum;

   function Add (Base : Instant; Span : Duration_Seconds; Ok : out Boolean) return Instant is
   begin
      if Base > Instant'Last - Instant (Span) then
         Ok := False;
         return Instant'Last;
      end if;

      Ok := True;
      return Base + Instant (Span);
   end Add;

   function Expired (Now : Instant; Boundary : Expiration) return Boolean is
   begin
      return Boundary.Present and then Now >= Boundary.Time_Point;
   end Expired;
end Identity.Times;

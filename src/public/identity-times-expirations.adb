package body Identity.Times.Expirations
  with SPARK_Mode => On
is
   function After
     (Base : Identity.Times.Instant;
      Span : Identity.Times.Duration_Seconds) return Expiration_Construction
   is
      Boundary : constant Identity.Times.Instant_Sum :=
        Identity.Times.Sum (Base, Span);
   begin
      if Boundary.Ok then
         return
           (Status => Constructed,
            Value => (Present => True, Time_Point => Boundary.Value));
      else
         return
           (Status => Time_Overflow,
            Value => Never);
      end if;
   end After;
end Identity.Times.Expirations;

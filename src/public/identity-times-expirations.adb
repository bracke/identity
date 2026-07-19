package body Identity.Times.Expirations
  with SPARK_Mode => On
is
   function After
     (Base : Identity.Times.Instant;
      Span : Identity.Times.Duration_Seconds) return Expiration_Construction
   is
      Ok : Boolean := False;
      Boundary : constant Identity.Times.Instant := Identity.Times.Add (Base, Span, Ok);
   begin
      if Ok then
         return
           (Status => Constructed,
            Value => (Present => True, Time_Point => Boundary));
      else
         return
           (Status => Time_Overflow,
            Value => Never);
      end if;
   end After;
end Identity.Times.Expirations;

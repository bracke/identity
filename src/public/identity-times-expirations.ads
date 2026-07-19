package Identity.Times.Expirations is
   subtype Expiration is Identity.Times.Expiration;

   type Expiration_Construction_Status is (Constructed, Time_Overflow);

   type Expiration_Construction is record
      Status : Expiration_Construction_Status := Constructed;
      Value  : Expiration := (Present => False, Time_Point => 0);
   end record;

   function At_Time (Value : Identity.Times.Instant) return Expiration is
     (Present => True, Time_Point => Value);
   function Never return Expiration is
     (Present => False, Time_Point => 0);
   function After
     (Base : Identity.Times.Instant;
      Span : Identity.Times.Duration_Seconds) return Expiration_Construction;

   function Construction_Succeeded
     (Status : Expiration_Construction_Status) return Boolean is
     (Status = Constructed);

   function Overflow_Rejected
     (Status : Expiration_Construction_Status) return Boolean is
     (Status = Time_Overflow);

   function Construction_Succeeded
     (Result : Expiration_Construction) return Boolean is
     (Result.Status = Constructed);

   function Overflow_Rejected
     (Result : Expiration_Construction) return Boolean is
     (Result.Status = Time_Overflow);

   function Present_Expiration
     (Result : Expiration_Construction) return Boolean is
     (Result.Status = Constructed and then Result.Value.Present);
end Identity.Times.Expirations;

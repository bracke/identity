package body Identity.Verification.Policies is
   use type Identity.Times.Instant;

   function Cooling_Off_Satisfied
     (Value        : Contact_Verification_Policy;
      Requested_At : Identity.Times.Instant;
      Now          : Identity.Times.Instant) return Boolean
   is
      Ok       : Boolean := False;
      Boundary : constant Identity.Times.Instant :=
        Identity.Times.Add
          (Requested_At,
           Identity.Times.Duration_Seconds (Value.Cooling_Off),
           Ok);
   begin
      return Ok and then Now >= Boundary;
   end Cooling_Off_Satisfied;
end Identity.Verification.Policies;

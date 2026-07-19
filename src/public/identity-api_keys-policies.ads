with Identity.Times;
with Identity.Times.Durations;

package Identity.API_Keys.Policies is
   pragma Pure;
   use type Identity.Times.Instant;
   use type Identity.Times.Durations.Token_Lifetime;

   type Issue_Lifetime_Status is
     (Issue_Lifetime_Allowed,
      Policy_Invalid,
      Expiration_Missing,
      Expiration_Not_After_Creation);

   type API_Key_Policy is record
      Maximum_Active_Keys_Per_Principal : Natural range 0 .. 128 := 16;
      Maximum_Overlap : Identity.Times.Durations.Token_Lifetime := 86_400;
      Expiration_Required : Boolean := True;
   end record;

   type API_Key_Policy_Validation_Status is
     (API_Key_Policy_Valid,
      API_Key_Active_Key_Capacity_Zero,
      API_Key_Overlap_Non_Positive,
      API_Key_Expiration_Not_Required);

   function Validate
     (Value : API_Key_Policy) return API_Key_Policy_Validation_Status is
     (if Value.Maximum_Active_Keys_Per_Principal = 0 then
        API_Key_Active_Key_Capacity_Zero
      elsif Value.Maximum_Overlap = 0 then
        API_Key_Overlap_Non_Positive
      elsif not Value.Expiration_Required then
        API_Key_Expiration_Not_Required
      else
        API_Key_Policy_Valid);

   function Validation_Accepted
     (Status : API_Key_Policy_Validation_Status) return Boolean is
     (Status = API_Key_Policy_Valid);

   function Capacity_Rejected
     (Status : API_Key_Policy_Validation_Status) return Boolean is
     (Status = API_Key_Active_Key_Capacity_Zero);

   function Overlap_Rejected
     (Status : API_Key_Policy_Validation_Status) return Boolean is
     (Status = API_Key_Overlap_Non_Positive);

   function Expiration_Policy_Rejected
     (Status : API_Key_Policy_Validation_Status) return Boolean is
     (Status = API_Key_Expiration_Not_Required);

   function Valid (Value : API_Key_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));

   function Evaluate_Issue_Lifetime
     (Policy     : API_Key_Policy;
      Created_At : Identity.Times.Instant;
      Expires_At : Identity.Times.Expiration) return Issue_Lifetime_Status is
     (if not Valid (Policy) then Policy_Invalid
      elsif Policy.Expiration_Required and then not Expires_At.Present then Expiration_Missing
      elsif Expires_At.Present and then Expires_At.Time_Point <= Created_At
      then Expiration_Not_After_Creation
      else Issue_Lifetime_Allowed);

   function Issue_Lifetime_Accepted
     (Status : Issue_Lifetime_Status) return Boolean is
     (Status = Issue_Lifetime_Allowed);

   function Policy_Rejected
     (Status : Issue_Lifetime_Status) return Boolean is
     (Status = Policy_Invalid);

   function Expiration_Rejected
     (Status : Issue_Lifetime_Status) return Boolean is
     (Status in Expiration_Missing | Expiration_Not_After_Creation);

   function Verifier_Derivation_Allowed
     (Status : Issue_Lifetime_Status) return Boolean is
     (Status = Issue_Lifetime_Allowed);
end Identity.API_Keys.Policies;

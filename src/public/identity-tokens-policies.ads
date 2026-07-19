with Identity.Times.Durations;
with Identity.Limits;
with Identity.Versions;

package Identity.Tokens.Policies is
   pragma Pure;
   use type Identity.Times.Durations.Token_Lifetime;
   use type Identity.Versions.Attempt_Count;

   type Token_Policy is record
      Lifetime          : Identity.Times.Durations.Token_Lifetime := 3_600;
      Maximum_Attempts  : Identity.Versions.Attempt_Count
        range 0 .. Identity.Versions.Attempt_Count (Identity.Limits.Max_Factor_Challenges) := 5;
      Supersede_Siblings : Boolean := True;
   end record;

   type Token_Policy_Validation_Status is
     (Token_Policy_Valid,
      Token_Lifetime_Non_Positive,
      Token_Attempt_Limit_Non_Positive);

   function Validate
     (Value : Token_Policy) return Token_Policy_Validation_Status is
     (if Value.Lifetime = 0 then
         Token_Lifetime_Non_Positive
      elsif Value.Maximum_Attempts = 0 then
         Token_Attempt_Limit_Non_Positive
      else
         Token_Policy_Valid);

   function Validation_Accepted
     (Status : Token_Policy_Validation_Status) return Boolean is
     (Status = Token_Policy_Valid);

   function Lifetime_Rejected
     (Status : Token_Policy_Validation_Status) return Boolean is
     (Status = Token_Lifetime_Non_Positive);

   function Attempt_Limit_Rejected
     (Status : Token_Policy_Validation_Status) return Boolean is
     (Status = Token_Attempt_Limit_Non_Positive);

   function Valid (Value : Token_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Tokens.Policies;

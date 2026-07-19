with Identity.Limits;

package Identity.Multi_Factor.Policies is
   pragma Pure;

   type MFA_Policy is record
      Maximum_Challenges : Natural range 0 .. Identity.Limits.Max_Evidence_Per_Context := 4;
      Maximum_Attempts   : Natural range 0 .. 32 := 5;
      Alternative_Methods_Allowed : Boolean := True;
   end record;

   type MFA_Policy_Validation_Status is
     (MFA_Policy_Valid,
      MFA_Challenge_Limit_Non_Positive,
      MFA_Attempt_Limit_Non_Positive);

   function Validate (Value : MFA_Policy) return MFA_Policy_Validation_Status is
     (if Value.Maximum_Challenges = 0 then
         MFA_Challenge_Limit_Non_Positive
      elsif Value.Maximum_Attempts = 0 then
         MFA_Attempt_Limit_Non_Positive
      else
         MFA_Policy_Valid);

   function Validation_Accepted
     (Status : MFA_Policy_Validation_Status) return Boolean is
     (Status = MFA_Policy_Valid);

   function Challenge_Limit_Rejected
     (Status : MFA_Policy_Validation_Status) return Boolean is
     (Status = MFA_Challenge_Limit_Non_Positive);

   function Attempt_Limit_Rejected
     (Status : MFA_Policy_Validation_Status) return Boolean is
     (Status = MFA_Attempt_Limit_Non_Positive);

   function Valid (Value : MFA_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Multi_Factor.Policies;

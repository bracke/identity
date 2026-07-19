with Identity.Times.Durations;

package Identity.Recovery.Policies is
   pragma Pure;
   use type Identity.Times.Durations.Token_Lifetime;

   type Recovery_Policy is record
      Authority_Lifetime : Identity.Times.Durations.Token_Lifetime := 900;
      Require_Credential_Reestablishment : Boolean := True;
      Require_MFA_Reenrollment : Boolean := False;
      Revoke_Existing_Sessions : Boolean := True;
   end record;

   type Recovery_Policy_Validation_Status is
     (Recovery_Policy_Valid,
      Recovery_Authority_Lifetime_Non_Positive,
      Credential_Reestablishment_Not_Required,
      Existing_Session_Consequence_Not_Required);

   function Validate
     (Value : Recovery_Policy) return Recovery_Policy_Validation_Status is
     (if Value.Authority_Lifetime = 0 then
         Recovery_Authority_Lifetime_Non_Positive
      elsif not Value.Require_Credential_Reestablishment then
         Credential_Reestablishment_Not_Required
      elsif not Value.Revoke_Existing_Sessions then
         Existing_Session_Consequence_Not_Required
      else
         Recovery_Policy_Valid);

   function Validation_Accepted
     (Status : Recovery_Policy_Validation_Status) return Boolean is
     (Status = Recovery_Policy_Valid);

   function Authority_Lifetime_Rejected
     (Status : Recovery_Policy_Validation_Status) return Boolean is
     (Status = Recovery_Authority_Lifetime_Non_Positive);

   function Credential_Reestablishment_Rejected
     (Status : Recovery_Policy_Validation_Status) return Boolean is
     (Status = Credential_Reestablishment_Not_Required);

   function Existing_Session_Consequence_Rejected
     (Status : Recovery_Policy_Validation_Status) return Boolean is
     (Status = Existing_Session_Consequence_Not_Required);

   function Valid (Value : Recovery_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Recovery.Policies;

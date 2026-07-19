with Identity.Times.Durations;
with Identity.Times;
with Identity.Limits;
with Identity.Versions;

package Identity.Verification.Policies is
   pragma Pure;
   use type Identity.Times.Durations.Token_Lifetime;
   use type Identity.Versions.Attempt_Count;

   type Old_Contact_Confirmation_Mode is (Not_Required, Required_When_Verified, Always_Required);

   type Contact_Verification_Policy is record
      Token_Lifetime       : Identity.Times.Durations.Token_Lifetime := 3_600;
      Maximum_Attempts     : Identity.Versions.Attempt_Count
        range 0 .. Identity.Versions.Attempt_Count (Identity.Limits.Max_Factor_Challenges) := 5;
      Supersede_Open_Tokens : Boolean := True;
      Old_Contact_Confirmation : Old_Contact_Confirmation_Mode := Required_When_Verified;
      Cooling_Off          : Identity.Times.Durations.Token_Lifetime := 0;
   end record;

   type Contact_Verification_Policy_Validation_Status is
     (Contact_Verification_Policy_Valid,
      Contact_Verification_Token_Lifetime_Non_Positive,
      Contact_Verification_Attempt_Limit_Non_Positive,
      Contact_Verification_Supersession_Not_Required);

   function Validate
     (Value : Contact_Verification_Policy)
      return Contact_Verification_Policy_Validation_Status is
     (if Value.Token_Lifetime = 0 then
         Contact_Verification_Token_Lifetime_Non_Positive
      elsif Value.Maximum_Attempts = 0 then
         Contact_Verification_Attempt_Limit_Non_Positive
      elsif not Value.Supersede_Open_Tokens then
         Contact_Verification_Supersession_Not_Required
      else
         Contact_Verification_Policy_Valid);

   function Validation_Accepted
     (Status : Contact_Verification_Policy_Validation_Status) return Boolean is
     (Status = Contact_Verification_Policy_Valid);

   function Token_Lifetime_Rejected
     (Status : Contact_Verification_Policy_Validation_Status) return Boolean is
     (Status = Contact_Verification_Token_Lifetime_Non_Positive);

   function Attempt_Limit_Rejected
     (Status : Contact_Verification_Policy_Validation_Status) return Boolean is
     (Status = Contact_Verification_Attempt_Limit_Non_Positive);

   function Supersession_Rejected
     (Status : Contact_Verification_Policy_Validation_Status) return Boolean is
     (Status = Contact_Verification_Supersession_Not_Required);

   function Valid (Value : Contact_Verification_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));

   function Requires_Old_Contact_Confirmation
     (Mode                     : Old_Contact_Confirmation_Mode;
      Predecessor_Is_Verified  : Boolean) return Boolean is
     (Mode = Always_Required
      or else (Mode = Required_When_Verified and then Predecessor_Is_Verified));

   function Cooling_Off_Satisfied
     (Value        : Contact_Verification_Policy;
      Requested_At : Identity.Times.Instant;
      Now          : Identity.Times.Instant) return Boolean;
end Identity.Verification.Policies;

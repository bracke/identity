with Identity.Limits;

package Identity.Passwords.Policies is
   pragma Pure;

   type Password_Acceptance_Policy is record
      Minimum_Length : Natural range 0 .. Identity.Limits.Max_Password_Bytes := 12;
      Maximum_Length : Natural range 0 .. Identity.Limits.Max_Password_Bytes := 256;
      Quality_Checks_Enabled : Boolean := False;
      Compromised_Check_Enabled : Boolean := False;
   end record;

   type Password_Hashing_Policy is record
      Preferred_Format : Positive := 1;
      Maximum_Verifier_Bytes : Natural range 0 .. Identity.Limits.Max_Public_Text_Bytes := 256;
      Accepted_Legacy_Formats : Natural range 0 .. 16 := 0;
      Pepper_Required : Boolean := False;
   end record;

   type Password_Length_Status is
     (Length_Accepted,
      Too_Short,
      Too_Long,
      Invalid_Policy);

   type Password_Acceptance_Policy_Validation_Status is
     (Password_Acceptance_Policy_Valid,
      Password_Minimum_Length_Zero,
      Password_Maximum_Length_Below_Minimum);

   type Password_Hashing_Policy_Validation_Status is
     (Password_Hashing_Policy_Valid,
      Password_Maximum_Verifier_Bytes_Zero);

   function Validate
     (Value : Password_Acceptance_Policy)
      return Password_Acceptance_Policy_Validation_Status is
     (if Value.Minimum_Length = 0 then
        Password_Minimum_Length_Zero
      elsif Value.Minimum_Length > Value.Maximum_Length then
        Password_Maximum_Length_Below_Minimum
      else
        Password_Acceptance_Policy_Valid);

   function Validate
     (Value : Password_Hashing_Policy)
      return Password_Hashing_Policy_Validation_Status is
     (if Value.Maximum_Verifier_Bytes = 0 then
        Password_Maximum_Verifier_Bytes_Zero
      else
        Password_Hashing_Policy_Valid);

   function Validation_Accepted
     (Status : Password_Acceptance_Policy_Validation_Status) return Boolean is
     (Status = Password_Acceptance_Policy_Valid);

   function Validation_Accepted
     (Status : Password_Hashing_Policy_Validation_Status) return Boolean is
     (Status = Password_Hashing_Policy_Valid);

   function Acceptance_Length_Rejected
     (Status : Password_Acceptance_Policy_Validation_Status) return Boolean is
     (Status in Password_Minimum_Length_Zero
              | Password_Maximum_Length_Below_Minimum);

   function Verifier_Length_Rejected
     (Status : Password_Hashing_Policy_Validation_Status) return Boolean is
     (Status = Password_Maximum_Verifier_Bytes_Zero);

   function Valid (Value : Password_Acceptance_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));

   function Valid (Value : Password_Hashing_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));

   function Length_Accepted_Input
     (Status : Password_Length_Status) return Boolean is
     (Status = Length_Accepted);

   function Length_Rejected
     (Status : Password_Length_Status) return Boolean is
     (Status /= Length_Accepted);

   function Minimum_Length_Rejected
     (Status : Password_Length_Status) return Boolean is
     (Status = Too_Short);

   function Maximum_Length_Rejected
     (Status : Password_Length_Status) return Boolean is
     (Status = Too_Long);

   function Policy_Rejected
     (Status : Password_Length_Status) return Boolean is
     (Status = Invalid_Policy);

   function Accepts_Length
     (Policy : Password_Acceptance_Policy;
      Presented_Length : Natural) return Password_Length_Status is
     (if not Valid (Policy) then Invalid_Policy
      elsif Presented_Length < Policy.Minimum_Length then Too_Short
      elsif Presented_Length > Policy.Maximum_Length then Too_Long
      else Length_Accepted);
end Identity.Passwords.Policies;

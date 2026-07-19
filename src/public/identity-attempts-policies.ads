with Identity.Attempts.Buckets;

package Identity.Attempts.Policies is
   pragma Pure;

   type Attempt_Policy is record
      Password : Identity.Attempts.Buckets.Failure_Bucket_Policy;
      TOTP     : Identity.Attempts.Buckets.Failure_Bucket_Policy;
      Token    : Identity.Attempts.Buckets.Failure_Bucket_Policy;
   end record;

   type Attempt_Policy_Validation_Status is
     (Attempt_Policy_Valid,
      Attempt_Password_Bucket_Invalid,
      Attempt_TOTP_Bucket_Invalid,
      Attempt_Token_Bucket_Invalid);

   function Validate
     (Value : Attempt_Policy) return Attempt_Policy_Validation_Status is
     (if not Identity.Attempts.Buckets.Valid (Value.Password) then
        Attempt_Password_Bucket_Invalid
      elsif not Identity.Attempts.Buckets.Valid (Value.TOTP) then
        Attempt_TOTP_Bucket_Invalid
      elsif not Identity.Attempts.Buckets.Valid (Value.Token) then
        Attempt_Token_Bucket_Invalid
      else
        Attempt_Policy_Valid);

   function Validation_Accepted
     (Status : Attempt_Policy_Validation_Status) return Boolean is
     (Status = Attempt_Policy_Valid);

   function Password_Bucket_Rejected
     (Status : Attempt_Policy_Validation_Status) return Boolean is
     (Status = Attempt_Password_Bucket_Invalid);

   function TOTP_Bucket_Rejected
     (Status : Attempt_Policy_Validation_Status) return Boolean is
     (Status = Attempt_TOTP_Bucket_Invalid);

   function Token_Bucket_Rejected
     (Status : Attempt_Policy_Validation_Status) return Boolean is
     (Status = Attempt_Token_Bucket_Invalid);

   function Valid (Value : Attempt_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Attempts.Policies;

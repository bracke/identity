with Identity.Times;
with Identity.Versions;

package Identity.Attempts.Buckets is
   pragma Pure;
   use type Identity.Times.Duration_Seconds;
   use type Identity.Versions.Attempt_Count;

   type Failure_Bucket_Kind is
     (Password_Failures,
      TOTP_Failures,
      Recovery_Failures,
      Token_Failures,
      Provider_Failures,
      Session_Replay_Events);

   type Failure_Bucket_Policy is record
      Kind       : Failure_Bucket_Kind := Password_Failures;
      Window     : Identity.Times.Duration_Seconds := 900;
      Threshold  : Identity.Versions.Attempt_Count := 5;
      Saturation : Identity.Versions.Attempt_Count := 100;
   end record;

   type Failure_Bucket_Policy_Validation_Status is
     (Failure_Bucket_Policy_Valid,
      Failure_Bucket_Window_Non_Positive,
      Failure_Bucket_Threshold_Zero,
      Failure_Bucket_Saturation_Below_Threshold);

   function Validate
     (Value : Failure_Bucket_Policy)
      return Failure_Bucket_Policy_Validation_Status is
     (if Value.Window = 0 then
        Failure_Bucket_Window_Non_Positive
      elsif Value.Threshold = 0 then
        Failure_Bucket_Threshold_Zero
      elsif Value.Saturation < Value.Threshold then
        Failure_Bucket_Saturation_Below_Threshold
      else
        Failure_Bucket_Policy_Valid);

   function Validation_Accepted
     (Status : Failure_Bucket_Policy_Validation_Status) return Boolean is
     (Status = Failure_Bucket_Policy_Valid);

   function Window_Rejected
     (Status : Failure_Bucket_Policy_Validation_Status) return Boolean is
     (Status = Failure_Bucket_Window_Non_Positive);

   function Threshold_Rejected
     (Status : Failure_Bucket_Policy_Validation_Status) return Boolean is
     (Status = Failure_Bucket_Threshold_Zero);

   function Saturation_Rejected
     (Status : Failure_Bucket_Policy_Validation_Status) return Boolean is
     (Status = Failure_Bucket_Saturation_Below_Threshold);

   function Valid (Value : Failure_Bucket_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Attempts.Buckets;

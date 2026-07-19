with Identity.Times.Durations;
with Identity.Versions;

package Identity.Throttling.Policies is
   pragma Pure;
   use type Identity.Times.Durations.Lockout_Duration;
   use type Identity.Versions.Attempt_Count;

   type Throttling_Policy is record
      Delay_After : Identity.Versions.Attempt_Count := 3;
      Reject_After : Identity.Versions.Attempt_Count := 10;
      Delay_Duration : Identity.Times.Durations.Lockout_Duration := 30;
   end record;

   type Throttling_Policy_Validation_Status is
     (Throttling_Policy_Valid,
      Throttling_Reject_Not_After_Delay,
      Throttling_Delay_Duration_Non_Positive);

   function Validate
     (Value : Throttling_Policy)
      return Throttling_Policy_Validation_Status is
     (if Value.Delay_After >= Value.Reject_After then
        Throttling_Reject_Not_After_Delay
      elsif Value.Delay_Duration = 0 then
        Throttling_Delay_Duration_Non_Positive
      else
        Throttling_Policy_Valid);

   function Validation_Accepted
     (Status : Throttling_Policy_Validation_Status) return Boolean is
     (Status = Throttling_Policy_Valid);

   function Threshold_Rejected
     (Status : Throttling_Policy_Validation_Status) return Boolean is
     (Status = Throttling_Reject_Not_After_Delay);

   function Duration_Rejected
     (Status : Throttling_Policy_Validation_Status) return Boolean is
     (Status = Throttling_Delay_Duration_Non_Positive);

   function Valid (Value : Throttling_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Throttling.Policies;

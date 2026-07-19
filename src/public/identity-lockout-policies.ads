with Identity.Times.Durations;
with Identity.Versions;

package Identity.Lockout.Policies is
   pragma Pure;
   use type Identity.Times.Durations.Lockout_Duration;
   use type Identity.Versions.Attempt_Count;

   type Lockout_Policy is record
      Temporary_Threshold : Identity.Versions.Attempt_Count := 5;
      Indefinite_Threshold : Identity.Versions.Attempt_Count := 50;
      Temporary_Duration : Identity.Times.Durations.Lockout_Duration := 900;
      Permanent_Remote_Login_Disablement : Boolean := False;
   end record;

   type Lockout_Policy_Validation_Status is
     (Lockout_Policy_Valid,
      Lockout_Temporary_Threshold_Zero,
      Lockout_Indefinite_Not_After_Temporary,
      Lockout_Temporary_Duration_Non_Positive,
      Lockout_Permanent_Remote_Login_Disablement);

   function Validate
     (Value : Lockout_Policy) return Lockout_Policy_Validation_Status is
     (if Value.Temporary_Threshold = 0 then
        Lockout_Temporary_Threshold_Zero
      elsif Value.Temporary_Threshold >= Value.Indefinite_Threshold then
        Lockout_Indefinite_Not_After_Temporary
      elsif Value.Temporary_Duration = 0 then
        Lockout_Temporary_Duration_Non_Positive
      elsif Value.Permanent_Remote_Login_Disablement then
        Lockout_Permanent_Remote_Login_Disablement
      else
        Lockout_Policy_Valid);

   function Validation_Accepted
     (Status : Lockout_Policy_Validation_Status) return Boolean is
     (Status = Lockout_Policy_Valid);

   function Threshold_Rejected
     (Status : Lockout_Policy_Validation_Status) return Boolean is
     (Status in Lockout_Temporary_Threshold_Zero
              | Lockout_Indefinite_Not_After_Temporary);

   function Duration_Rejected
     (Status : Lockout_Policy_Validation_Status) return Boolean is
     (Status = Lockout_Temporary_Duration_Non_Positive);

   function Permanent_Remote_Disablement_Rejected
     (Status : Lockout_Policy_Validation_Status) return Boolean is
     (Status = Lockout_Permanent_Remote_Login_Disablement);

   function Valid (Value : Lockout_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Lockout.Policies;

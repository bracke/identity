with Identity.Limits;

package Identity.One_Time_Passwords.Policies is
   pragma Pure;

   type TOTP_Policy is record
      Time_Step_Seconds : Positive := 30;
      Digit_Count : Natural range 6 .. 10 := 6;
      Accepted_Skew_Steps : Natural range 0 .. Identity.Limits.Max_TOTP_Skew_Steps := 1;
      Maximum_Attempts : Natural range 0 .. Identity.Limits.Max_Factor_Challenges := 5;
      Minimum_Secret_Bytes : Natural range 16 .. 128 := 20;
      Replay_Prevention_Required : Boolean := True;
   end record;

   type TOTP_Policy_Validation_Status is
     (TOTP_Policy_Valid,
      TOTP_Attempt_Limit_Non_Positive,
      TOTP_Replay_Prevention_Not_Required);

   function Validate (Value : TOTP_Policy) return TOTP_Policy_Validation_Status is
     (if Value.Maximum_Attempts = 0 then
         TOTP_Attempt_Limit_Non_Positive
      elsif not Value.Replay_Prevention_Required then
         TOTP_Replay_Prevention_Not_Required
      else
         TOTP_Policy_Valid);

   function Validation_Accepted
     (Status : TOTP_Policy_Validation_Status) return Boolean is
     (Status = TOTP_Policy_Valid);

   function Attempt_Limit_Rejected
     (Status : TOTP_Policy_Validation_Status) return Boolean is
     (Status = TOTP_Attempt_Limit_Non_Positive);

   function Replay_Prevention_Rejected
     (Status : TOTP_Policy_Validation_Status) return Boolean is
     (Status = TOTP_Replay_Prevention_Not_Required);

   function Valid (Value : TOTP_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.One_Time_Passwords.Policies;

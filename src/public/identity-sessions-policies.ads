with Identity.Times.Durations;

package Identity.Sessions.Policies is
   pragma Pure;
   use type Identity.Times.Durations.Duration_Seconds;
   use type Identity.Times.Durations.Session_Absolute_Lifetime;

   type Session_Request_Kind is (No_Session, Interactive_Session, Persistent_Session);

   type Session_Policy is record
      Idle_Timeout          : Identity.Times.Durations.Session_Idle_Timeout := 3_600;
      Absolute_Lifetime     : Identity.Times.Durations.Session_Absolute_Lifetime := 86_400;
      Remember_Me_Lifetime  : Identity.Times.Durations.Session_Absolute_Lifetime := 2_592_000;
      Rotation_Required     : Boolean := True;
      Remember_Me_Allowed   : Boolean := True;
   end record;

   type Session_Policy_Validation_Status is
     (Session_Policy_Valid,
      Idle_Timeout_Non_Positive,
      Absolute_Lifetime_Non_Positive,
      Remember_Me_Lifetime_Non_Positive,
      Idle_Exceeds_Absolute_Lifetime,
      Absolute_Exceeds_Remember_Me_Lifetime);

   function Validate
     (Value : Session_Policy) return Session_Policy_Validation_Status is
     (if Identity.Times.Durations.To_Base (Value.Idle_Timeout) = 0 then
         Idle_Timeout_Non_Positive
      elsif Value.Absolute_Lifetime = 0 then
         Absolute_Lifetime_Non_Positive
      elsif Value.Remember_Me_Lifetime = 0 then
         Remember_Me_Lifetime_Non_Positive
      elsif Identity.Times.Durations.To_Base (Value.Idle_Timeout)
        > Identity.Times.Durations.To_Base (Value.Absolute_Lifetime)
      then
         Idle_Exceeds_Absolute_Lifetime
      elsif Value.Absolute_Lifetime > Value.Remember_Me_Lifetime then
         Absolute_Exceeds_Remember_Me_Lifetime
      else
         Session_Policy_Valid);

   function Validation_Accepted
     (Status : Session_Policy_Validation_Status) return Boolean is
     (Status = Session_Policy_Valid);

   function Duration_Rejected
     (Status : Session_Policy_Validation_Status) return Boolean is
     (Status in Idle_Timeout_Non_Positive
              | Absolute_Lifetime_Non_Positive
              | Remember_Me_Lifetime_Non_Positive);

   function Ordering_Rejected
     (Status : Session_Policy_Validation_Status) return Boolean is
     (Status in Idle_Exceeds_Absolute_Lifetime
              | Absolute_Exceeds_Remember_Me_Lifetime);

   function Idle_Rejected
     (Status : Session_Policy_Validation_Status) return Boolean is
     (Status in Idle_Timeout_Non_Positive | Idle_Exceeds_Absolute_Lifetime);

   function Absolute_Rejected
     (Status : Session_Policy_Validation_Status) return Boolean is
     (Status in Absolute_Lifetime_Non_Positive
              | Idle_Exceeds_Absolute_Lifetime
              | Absolute_Exceeds_Remember_Me_Lifetime);

   function Remember_Me_Rejected
     (Status : Session_Policy_Validation_Status) return Boolean is
     (Status in Remember_Me_Lifetime_Non_Positive
              | Absolute_Exceeds_Remember_Me_Lifetime);

   function Valid (Value : Session_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Sessions.Policies;

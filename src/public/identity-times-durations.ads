package Identity.Times.Durations is
   pragma Pure;

   subtype Duration_Seconds is Identity.Times.Duration_Seconds;
   type Session_Idle_Timeout is new Duration_Seconds;
   type Session_Absolute_Lifetime is new Duration_Seconds;
   type Token_Lifetime is new Duration_Seconds;
   type Lockout_Duration is new Duration_Seconds;
   type Authentication_Maximum_Age is new Duration_Seconds;
   type Challenge_Lifetime is new Duration_Seconds;

   function Seconds (Value : Duration_Seconds) return Duration_Seconds is (Value);
   function To_Base (Value : Session_Idle_Timeout) return Duration_Seconds is
     (Duration_Seconds (Value));
   function To_Base (Value : Session_Absolute_Lifetime) return Duration_Seconds is
     (Duration_Seconds (Value));
   function To_Base (Value : Token_Lifetime) return Duration_Seconds is
     (Duration_Seconds (Value));
   function To_Base (Value : Lockout_Duration) return Duration_Seconds is
     (Duration_Seconds (Value));
   function To_Base (Value : Authentication_Maximum_Age) return Duration_Seconds is
     (Duration_Seconds (Value));
   function To_Base (Value : Challenge_Lifetime) return Duration_Seconds is
     (Duration_Seconds (Value));
end Identity.Times.Durations;

package Identity.Crypto.Capabilities is
   pragma Pure;

   type Capability_State is (Available, Missing);

   type Crypto_Capability_Set is record
      Entropy          : Capability_State := Missing;
      Password_Hashing : Capability_State := Missing;
      Secret_Verifiers : Capability_State := Missing;
      Constant_Time    : Capability_State := Missing;
      TOTP_HMAC        : Capability_State := Missing;
      Event_Integrity  : Capability_State := Missing;
   end record;

   function Supports_Core_V1 (Value : Crypto_Capability_Set) return Boolean is
     (Value.Entropy = Available
      and then Value.Password_Hashing = Available
      and then Value.Secret_Verifiers = Available
      and then Value.Constant_Time = Available);

   function Available_State (Value : Capability_State) return Boolean is
     (Value = Available);
   function Missing_State (Value : Capability_State) return Boolean is
     (Value = Missing);
   function Capability_Available (Value : Capability_State) return Boolean is
     (Available_State (Value));
   function Capability_Missing (Value : Capability_State) return Boolean is
     (Missing_State (Value));
end Identity.Crypto.Capabilities;

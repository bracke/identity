package Identity.Internal.Crypto_Bindings is
   pragma Pure;

   type Crypto_Binding_Point is
     (Entropy,
      Password_Hashing,
      Secret_Verifier,
      MAC,
      Constant_Time_Comparison,
      One_Time_Password,
      Event_Integrity,
      Key_Lookup);

   type Crypto_Binding_Status is (Available, Missing_Capability, Unsupported, Failure);
end Identity.Internal.Crypto_Bindings;

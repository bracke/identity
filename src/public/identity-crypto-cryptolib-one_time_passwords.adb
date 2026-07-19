with Identity.Crypto.CryptoLib.MACs;

package body Identity.Crypto.CryptoLib.One_Time_Passwords is
   --  One-time-password verification is keyed by HMAC, so the OTP capability
   --  is exactly the MAC adapter's capability for the bound primitive.
   function Capability
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.One_Time_Passwords.OTP_Capability is
     ((HMAC =>
         Identity.Crypto.CryptoLib.MACs.Capability
           (Identity.Crypto.CryptoLib.MACs.HMAC_SHA256_Algorithm),
       Algorithm => Algorithm));
end Identity.Crypto.CryptoLib.One_Time_Passwords;

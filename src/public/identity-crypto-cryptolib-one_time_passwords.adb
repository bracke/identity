with Identity.Crypto.Capabilities;

package body Identity.Crypto.CryptoLib.One_Time_Passwords is
   function Capability
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.One_Time_Passwords.OTP_Capability is
     ((HMAC => Identity.Crypto.Capabilities.Missing,
       Algorithm => Algorithm));
end Identity.Crypto.CryptoLib.One_Time_Passwords;

with Identity.Crypto.One_Time_Passwords;
with Identity.Identifiers.Registry;

package Identity.Crypto.CryptoLib.One_Time_Passwords is
   pragma Pure;

   function Capability
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.One_Time_Passwords.OTP_Capability;
end Identity.Crypto.CryptoLib.One_Time_Passwords;

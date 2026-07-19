with CryptoLib.Macs;

package body Identity.Crypto.CryptoLib.Password_Hashing is
   function PBKDF2_SHA256
     (Password   : Ada.Streams.Stream_Element_Array;
      Salt       : Salt_Bytes;
      Iterations : Positive) return Derived_Bytes
   is
   begin
      return Standard.CryptoLib.Macs.PBKDF2_HMAC_SHA256
        (Password_Data => Password,
         Salt_Data     => Salt,
         Iterations    => Iterations,
         Output_Length => Derived_Length);
   end PBKDF2_SHA256;
end Identity.Crypto.CryptoLib.Password_Hashing;

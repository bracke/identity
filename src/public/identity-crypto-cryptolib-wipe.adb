with CryptoLib.Secure_Wipe;

package body Identity.Crypto.CryptoLib.Wipe is
   procedure Scrub (Address : System.Address; Length : Natural) is
   begin
      Standard.CryptoLib.Secure_Wipe.Wipe (Address, Length);
   end Scrub;
end Identity.Crypto.CryptoLib.Wipe;

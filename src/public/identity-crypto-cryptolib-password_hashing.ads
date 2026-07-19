with Ada.Streams;

package Identity.Crypto.CryptoLib.Password_Hashing is
   function PBKDF2_SHA256_Test_Envelope
     (Password : Ada.Streams.Stream_Element_Array) return String;
end Identity.Crypto.CryptoLib.Password_Hashing;

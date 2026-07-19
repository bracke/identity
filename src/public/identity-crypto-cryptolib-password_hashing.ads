with Ada.Streams;

package Identity.Crypto.CryptoLib.Password_Hashing is
   --  Byte lengths of the two variable fields in a v2 password envelope.
   Salt_Length    : constant := 16;
   Derived_Length : constant := 32;

   subtype Salt_Bytes is
     Ada.Streams.Stream_Element_Array (1 .. Salt_Length);
   subtype Derived_Bytes is
     Ada.Streams.Stream_Element_Array (1 .. Derived_Length);

   --  PBKDF2-HMAC-SHA256 over a caller-supplied per-credential salt.
   function PBKDF2_SHA256
     (Password   : Ada.Streams.Stream_Element_Array;
      Salt       : Salt_Bytes;
      Iterations : Positive) return Derived_Bytes;
end Identity.Crypto.CryptoLib.Password_Hashing;

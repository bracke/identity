with Ada.Streams;

package Identity.Crypto.CryptoLib.Secret_Verifiers is
   function Derive_SHA256
     (Domain : String;
      Secret : Ada.Streams.Stream_Element_Array) return Ada.Streams.Stream_Element_Array;
end Identity.Crypto.CryptoLib.Secret_Verifiers;

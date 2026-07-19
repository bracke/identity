with Ada.Streams;
with Identity.Crypto.Capabilities;
with Identity.Crypto.Entropy;

package Identity.Crypto.CryptoLib.Entropy is
   type Unavailable_Source is
     limited new Identity.Crypto.Entropy.Entropy_Source with null record;

   overriding function Fill
     (Source : in out Unavailable_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean;

   function Capability return Identity.Crypto.Capabilities.Capability_State;
end Identity.Crypto.CryptoLib.Entropy;

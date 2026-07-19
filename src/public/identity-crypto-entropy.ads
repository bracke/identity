with Ada.Streams;

package Identity.Crypto.Entropy is
   type Entropy_Source is limited interface;
   function Fill
     (Source : in out Entropy_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean is abstract;
end Identity.Crypto.Entropy;

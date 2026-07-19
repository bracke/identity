package body Identity.Crypto.CryptoLib.Entropy is
   overriding function Fill
     (Source : in out Unavailable_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean is
      pragma Unreferenced (Source);
   begin
      Buffer := [others => 0];
      return False;
   end Fill;

   function Capability return Identity.Crypto.Capabilities.Capability_State is
     (Identity.Crypto.Capabilities.Missing);
end Identity.Crypto.CryptoLib.Entropy;

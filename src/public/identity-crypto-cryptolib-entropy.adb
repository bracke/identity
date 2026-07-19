with CryptoLib.OS_Random;

package body Identity.Crypto.CryptoLib.Entropy is
   function Fill_Bytes
     (Buffer : out Ada.Streams.Stream_Element_Array) return Boolean
   is
      Success : Boolean;
   begin
      Standard.CryptoLib.OS_Random.Fill_OS (Buffer, Success);
      if not Success then
         Buffer := [others => 0];
      end if;
      return Success;
   exception
      when others =>
         Buffer := [others => 0];
         return False;
   end Fill_Bytes;

   overriding function Fill
     (Source : in out OS_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean
   is
      pragma Unreferenced (Source);
   begin
      return Fill_Bytes (Buffer);
   end Fill;

   overriding function Fill
     (Source : in out Unavailable_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean
   is
      pragma Unreferenced (Source);
   begin
      Buffer := [others => 0];
      return False;
   end Fill;

   function Capability return Identity.Crypto.Capabilities.Capability_State is
      Probe : Ada.Streams.Stream_Element_Array (1 .. 8);
   begin
      if Fill_Bytes (Probe) then
         return Identity.Crypto.Capabilities.Available;
      else
         return Identity.Crypto.Capabilities.Missing;
      end if;
   end Capability;
end Identity.Crypto.CryptoLib.Entropy;

with CryptoLib.Macs;
with Identity.Text.Bounded;

package body Identity.Crypto.CryptoLib.MACs is
   use type Identity.Crypto.Capabilities.Capability_State;
   use type Identity.Identifiers.Registry.Registry_Id;

   Hex_Digits : constant String := "0123456789abcdef";

   function HMAC_SHA256_Algorithm
     return Identity.Identifiers.Registry.Registry_Id
   is (Identity.Identifiers.Registry.From_String ("identity.hmac-sha256"));

   function HMAC_SHA256
     (Key  : Ada.Streams.Stream_Element_Array;
      Data : Ada.Streams.Stream_Element_Array) return HMAC_SHA256_Tag
   is
      Digest : constant Standard.CryptoLib.Macs.HMAC_SHA256_Digest :=
        Standard.CryptoLib.Macs.HMAC_SHA256
          (Key_Data => Key, Message_Data => Data);
      Result : HMAC_SHA256_Tag;
   begin
      for Index in Digest'Range loop
         Result (Ada.Streams.Stream_Element_Offset (Index)) := Digest (Index);
      end loop;
      return Result;
   end HMAC_SHA256;

   function Capability
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.Capabilities.Capability_State
   is
   begin
      if Algorithm = HMAC_SHA256_Algorithm then
         return Identity.Crypto.Capabilities.Available;
      else
         return Identity.Crypto.Capabilities.Missing;
      end if;
   end Capability;

   function To_Hex (Data : Ada.Streams.Stream_Element_Array) return String is
      Result : String (1 .. Data'Length * 2);
      Pos    : Natural := Result'First;
      Value  : Natural;
   begin
      for B of Data loop
         Value := Natural (B);
         Result (Pos) := Hex_Digits (Value / 16 + 1);
         Result (Pos + 1) := Hex_Digits (Value mod 16 + 1);
         Pos := Pos + 2;
      end loop;
      return Result;
   end To_Hex;

   function Compute
     (Algorithm : Identity.Identifiers.Registry.Registry_Id;
      Key       : Ada.Streams.Stream_Element_Array;
      Data      : Ada.Streams.Stream_Element_Array)
      return Identity.Crypto.MACs.MAC_Result
   is
   begin
      if Capability (Algorithm) /= Identity.Crypto.Capabilities.Available then
         return Unsupported (Algorithm);
      end if;
      return
        (Capability => Identity.Crypto.Capabilities.Available,
         Algorithm  => Algorithm,
         Output     =>
           Identity.Text.Bounded.From_String (To_Hex (HMAC_SHA256 (Key, Data))));
   exception
      when others =>
         return Unsupported (Algorithm);
   end Compute;

   function Unsupported
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.MACs.MAC_Result
   is (Identity.Crypto.MACs.Unsupported (Algorithm));
end Identity.Crypto.CryptoLib.MACs;

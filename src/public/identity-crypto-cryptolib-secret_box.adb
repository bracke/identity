with CryptoLib.Ciphers;
with CryptoLib.Errors;

package body Identity.Crypto.CryptoLib.Secret_Box is
   use type Ada.Streams.Stream_Element_Offset;
   use type Standard.CryptoLib.Errors.Status;

   Algorithm : constant String := "aes256-gcm@openssh.com";
   Tag_Length : constant := 16;
   Nonce_Length : constant := 12;

   function Seal
     (Key    : Key_Bytes;
      Nonce  : Ada.Streams.Stream_Element_Array;
      Secret : Ada.Streams.Stream_Element_Array) return Sealed_Secret
   is
      Box_Length : constant Ada.Streams.Stream_Element_Offset :=
        Ada.Streams.Stream_Element_Offset (Nonce_Length)
        + Secret'Length + Ada.Streams.Stream_Element_Offset (Tag_Length);
      Result : Sealed_Secret (Length => Box_Length);
      Wire   : Ada.Streams.Stream_Element_Array
        (1 .. Secret'Length + Ada.Streams.Stream_Element_Offset (Tag_Length));
      Status : Standard.CryptoLib.Errors.Status;
   begin
      Status :=
        Standard.CryptoLib.Ciphers.Seal_AEAD
          (Algorithm_Name  => Algorithm,
           Key_Data        => Key,
           IV_Data         => Nonce,
           Associated_Data => [1 .. 0 => 0],
           Plain_Packet    => Secret,
           Wire_Packet     => Wire);
      if Status /= Standard.CryptoLib.Errors.Ok then
         return (Length => 0, Status => Seal_Failed, Data => <>);
      end if;

      --  Stored box is nonce followed by ciphertext-and-tag, so Open needs the
      --  key alone.
      Result.Status := Sealed;
      Result.Data (1 .. Ada.Streams.Stream_Element_Offset (Nonce_Length)) := Nonce;
      Result.Data
        (Ada.Streams.Stream_Element_Offset (Nonce_Length) + 1 .. Box_Length) := Wire;
      return Result;
   exception
      when others =>
         return (Length => 0, Status => Seal_Failed, Data => <>);
   end Seal;

   function Open
     (Key : Key_Bytes;
      Box : Ada.Streams.Stream_Element_Array) return Opened_Secret
   is
   begin
      if Box'Length < Ada.Streams.Stream_Element_Offset (Nonce_Length + Tag_Length) then
         return (Length => 0, Status => Malformed, Data => <>);
      end if;

      declare
         Nonce : constant Ada.Streams.Stream_Element_Array :=
           Box (Box'First ..
                Box'First + Ada.Streams.Stream_Element_Offset (Nonce_Length) - 1);
         Wire  : constant Ada.Streams.Stream_Element_Array :=
           Box (Box'First + Ada.Streams.Stream_Element_Offset (Nonce_Length) ..
                Box'Last);
         Plain_Length : constant Ada.Streams.Stream_Element_Offset :=
           Wire'Length - Ada.Streams.Stream_Element_Offset (Tag_Length);
         Result : Opened_Secret (Length => Plain_Length);
         Plain  : Ada.Streams.Stream_Element_Array (1 .. Plain_Length);
         Status : Standard.CryptoLib.Errors.Status;
      begin
         Status :=
           Standard.CryptoLib.Ciphers.Open_AEAD
             (Algorithm_Name  => Algorithm,
              Key_Data        => Key,
              IV_Data         => Nonce,
              Associated_Data => [1 .. 0 => 0],
              Wire_Packet     => Wire,
              Plain_Packet    => Plain);
         if Status /= Standard.CryptoLib.Errors.Ok then
            return (Length => 0, Status => Tag_Rejected, Data => <>);
         end if;
         Result.Status := Opened;
         Result.Data := Plain;
         return Result;
      end;
   exception
      when others =>
         return (Length => 0, Status => Malformed, Data => <>);
   end Open;
end Identity.Crypto.CryptoLib.Secret_Box;

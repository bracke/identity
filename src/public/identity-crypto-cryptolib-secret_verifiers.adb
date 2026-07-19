with CryptoLib.Hashes;

package body Identity.Crypto.CryptoLib.Secret_Verifiers is
   function Derive_SHA256
     (Domain : String;
      Secret : Ada.Streams.Stream_Element_Array) return Ada.Streams.Stream_Element_Array
   is
      use type Ada.Streams.Stream_Element_Offset;
      Framed : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Domain'Length + Secret'Length + 8));
      Pos : Ada.Streams.Stream_Element_Offset := Framed'First;
      Digest : Standard.CryptoLib.Hashes.SHA256_Digest;
      Result : Ada.Streams.Stream_Element_Array (1 .. 32);
   begin
      Framed (Pos) := 1;
      Pos := Pos + 1;
      Framed (Pos) := Ada.Streams.Stream_Element (Domain'Length / 256);
      Pos := Pos + 1;
      Framed (Pos) := Ada.Streams.Stream_Element (Domain'Length mod 256);
      Pos := Pos + 1;
      for Ch of Domain loop
         Framed (Pos) := Character'Pos (Ch);
         Pos := Pos + 1;
      end loop;
      Framed (Pos) := Ada.Streams.Stream_Element (Secret'Length / 16#0100_0000#);
      Pos := Pos + 1;
      Framed (Pos) := Ada.Streams.Stream_Element ((Secret'Length / 16#0001_0000#) mod 256);
      Pos := Pos + 1;
      Framed (Pos) := Ada.Streams.Stream_Element ((Secret'Length / 256) mod 256);
      Pos := Pos + 1;
      Framed (Pos) := Ada.Streams.Stream_Element (Secret'Length mod 256);
      Pos := Pos + 1;
      for B of Secret loop
         Framed (Pos) := B;
         Pos := Pos + 1;
      end loop;
      Framed (Pos) := 0;

      Digest := Standard.CryptoLib.Hashes.SHA256 (Framed);
      for Index in Digest'Range loop
         Result (Ada.Streams.Stream_Element_Offset (Index)) := Digest (Index);
      end loop;
      return Result;
   end Derive_SHA256;
end Identity.Crypto.CryptoLib.Secret_Verifiers;

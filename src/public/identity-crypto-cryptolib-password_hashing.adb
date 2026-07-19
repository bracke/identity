with CryptoLib.Macs;

package body Identity.Crypto.CryptoLib.Password_Hashing is
   Hex : constant String := "0123456789abcdef";

   function To_Hex (Data : Ada.Streams.Stream_Element_Array) return String is
      Result : String (1 .. Data'Length * 2);
      Pos    : Natural := Result'First;
      Value  : Natural;
   begin
      for B of Data loop
         Value := Natural (B);
         Result (Pos) := Hex (Value / 16 + 1);
         Result (Pos + 1) := Hex (Value mod 16 + 1);
         Pos := Pos + 2;
      end loop;
      return Result;
   end To_Hex;

   function PBKDF2_SHA256_Test_Envelope
     (Password : Ada.Streams.Stream_Element_Array) return String
   is
      Salt : constant Ada.Streams.Stream_Element_Array (1 .. 16) :=
        [16#49#, 16#44#, 16#45#, 16#4e#, 16#54#, 16#49#, 16#54#, 16#59#,
         16#2d#, 16#56#, 16#31#, 16#2d#, 16#53#, 16#41#, 16#4c#, 16#54#];
      Derived : constant Ada.Streams.Stream_Element_Array :=
        Standard.CryptoLib.Macs.PBKDF2_HMAC_SHA256
          (Password_Data => Password,
           Salt_Data     => Salt,
           Iterations    => 1000,
           Output_Length => 32);
   begin
      return To_Hex (Salt) & ":" & To_Hex (Derived);
   end PBKDF2_SHA256_Test_Envelope;
end Identity.Crypto.CryptoLib.Password_Hashing;

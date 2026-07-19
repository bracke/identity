with Identity.Crypto.CryptoLib.Secret_Verifiers;
with Identity.Crypto.Constant_Time;
with Identity.Limits;

package body Identity.Crypto.Secret_Verifiers is
   Hex : constant String := "0123456789abcdef";

   function To_Hex (Data : Verifier_Data; Length : Verifier_Length) return String is
      Result : String (1 .. Length * 2);
      Pos    : Natural := Result'First;
      Value  : Natural;
   begin
      for Index in 1 .. Length loop
         Value := Natural (Data (Index));
         Result (Pos) := Hex (Value / 16 + 1);
         Result (Pos + 1) := Hex (Value mod 16 + 1);
         Pos := Pos + 2;
      end loop;
      return Result;
   end To_Hex;

   function Derive
     (Domain : Identity.Identifiers.Registry.Registry_Id;
      Secret : Identity.Secrets.Bytes.Secret_Bytes) return Verifier_Envelope
   is
      Buffer : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Last   : Natural;
      Digest : Ada.Streams.Stream_Element_Array (1 .. 32);
      Result : Verifier_Envelope;
   begin
      Identity.Secrets.Bytes.Borrow (Secret, Buffer, Last);
      Digest := Identity.Crypto.CryptoLib.Secret_Verifiers.Derive_SHA256
        (Identity.Identifiers.Registry.Image (Domain),
         Buffer (1 .. Ada.Streams.Stream_Element_Offset (Last)));
      Result.Domain := Domain;
      Result.Length := Digest'Length;
      for Index in 1 .. Digest'Length loop
         Result.Data (Index) := Digest (Ada.Streams.Stream_Element_Offset (Index));
      end loop;
      return Result;
   end Derive;

   function Verify
     (Domain   : Identity.Identifiers.Registry.Registry_Id;
      Secret   : Identity.Secrets.Bytes.Secret_Bytes;
      Verifier : Verifier_Envelope) return Verification_Outcome
   is
      Candidate : constant Verifier_Envelope := Derive (Domain, Secret);
      Left_Data : Ada.Streams.Stream_Element_Array (1 .. 64) := [others => 0];
      Right_Data : Ada.Streams.Stream_Element_Array (1 .. 64) := [others => 0];
   begin
      if Verifier.Format /= 1 then
         return Unsupported_Format;
      elsif Identity.Identifiers.Registry.Image (Verifier.Domain)
        /= Identity.Identifiers.Registry.Image (Domain)
      then
         return Not_Verified;
      elsif Candidate.Length /= Verifier.Length then
         return Malformed_Verifier;
      else
         for Index in 1 .. Verifier.Length loop
            Left_Data (Ada.Streams.Stream_Element_Offset (Index)) := Candidate.Data (Index);
            Right_Data (Ada.Streams.Stream_Element_Offset (Index)) := Verifier.Data (Index);
         end loop;
      end if;

      if Identity.Crypto.Constant_Time.Equal
        (Left_Data (1 .. Ada.Streams.Stream_Element_Offset (Verifier.Length)),
         Right_Data (1 .. Ada.Streams.Stream_Element_Offset (Verifier.Length)))
      then
         return Verified;
      else
         return Not_Verified;
      end if;
   exception
      when others =>
         return Cryptographic_Failure;
   end Verify;

   function Derive_Text
     (Domain : Identity.Identifiers.Registry.Registry_Id;
      Secret : Identity.Secrets.Bytes.Secret_Bytes) return Identity.Text.Bounded.Bounded_Text
   is
      Envelope : constant Verifier_Envelope := Derive (Domain, Secret);
      Image    : constant String :=
        "v1:" & Identity.Identifiers.Registry.Image (Domain) & ":" &
        To_Hex (Envelope.Data, Envelope.Length);
   begin
      return Identity.Text.Bounded.From_String (Image);
   end Derive_Text;

   function Verify_Text
     (Domain   : Identity.Identifiers.Registry.Registry_Id;
      Secret   : Identity.Secrets.Bytes.Secret_Bytes;
      Verifier : Identity.Text.Bounded.Bounded_Text) return Verification_Outcome
   is
      Expected : constant Identity.Text.Bounded.Bounded_Text := Derive_Text (Domain, Secret);
   begin
      if Identity.Text.Bounded.Equal (Expected, Verifier) then
         return Verified;
      else
         return Not_Verified;
      end if;
   exception
      when others =>
         return Cryptographic_Failure;
   end Verify_Text;
end Identity.Crypto.Secret_Verifiers;

with Identity.Credentials.States;
with Identity.Crypto.CryptoLib.TOTP;
with Identity.Operations.Factors.Accept_TOTP_Counter;
with Identity.Text.Bounded;
with Interfaces;

package body Identity.Operations.Factors.Verify_TOTP is
   package Stores renames Identity.Adapters.Repositories.Stores;
   package Creds renames Identity.One_Time_Passwords.Credentials;
   package Box renames Identity.Crypto.CryptoLib.Secret_Box;
   package Engine renames Identity.Crypto.CryptoLib.TOTP;

   use type Ada.Streams.Stream_Element_Offset;
   use type Box.Open_Status;
   use type Creds.TOTP_Accept_Status;

   --  A sealed box is arbitrary bytes; keep it verbatim as a byte-string so no
   --  encoding can lose or reinterpret it.
   function Encode_Box
     (Box : Ada.Streams.Stream_Element_Array) return String
   is
      Result : String (1 .. Natural (Box'Length));
      Pos    : Natural := Result'First;
   begin
      for B of Box loop
         Result (Pos) := Character'Val (Natural (B));
         Pos := Pos + 1;
      end loop;
      return Result;
   end Encode_Box;

   function Decode_Box
     (Text : String) return Ada.Streams.Stream_Element_Array
   is
      Result : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
      Pos    : Ada.Streams.Stream_Element_Offset := Result'First;
   begin
      for Ch of Text loop
         Result (Pos) := Ada.Streams.Stream_Element (Character'Pos (Ch));
         Pos := Pos + 1;
      end loop;
      return Result;
   end Decode_Box;

   Period : constant := 30;

   function Execute
     (Repository  : in out Stores.Store_Interface'Class;
      Request     : Verify_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant) return Creds.TOTP_Accept_Status
   is
      Found      : Boolean;
      Credential : Creds.TOTP_Credential_Record;
   begin
      Stores.Find_TOTP_Credential (Repository, Request.Credential, Found, Credential);
      if not Found then
         return Creds.Unknown;
      end if;
      if not Identity.Credentials.States.Can_Authenticate (Credential.State) then
         return Creds.Credential_Unusable;
      end if;

      declare
         Sealed : constant Ada.Streams.Stream_Element_Array :=
           Decode_Box (Identity.Text.Bounded.Image (Credential.Secret_Verifier));
         Opened : constant Box.Opened_Secret := Box.Open (Request.Opening_Key, Sealed);
      begin
         if Opened.Status /= Box.Opened then
            --  A wrong key or a tampered stored secret. Report as not verified
            --  rather than leaking which; nothing about the credential changed.
            return Creds.Not_Verified;
         end if;

         declare
            Now_Step : constant Interfaces.Unsigned_64 :=
              Engine.Time_Step
                (Interfaces.Unsigned_64 (Identity.Times.Instant'Max (Request.Now, 0)),
                 Period, 0);
            Outcome : constant Engine.Verification :=
              Engine.Verify_Code
                (Secret    => Opened.Data,
                 Presented => Request.Presented_Code,
                 Center    => Now_Step,
                 Skew      => Request.Skew_Steps,
                 Algorithm => Engine.SHA1,
                 Code_Length => 6);
         begin
            if not Outcome.Matched then
               return Creds.Not_Verified;
            end if;

            --  The code verified. Advance replay state through the existing
            --  counter operation, which also records the accepted or replayed
            --  event: a code for a step at or before the last accepted one is a
            --  replay, even though it verified.
            return Accept_TOTP_Counter.Execute
              (Repository,
               (Credential       => Request.Credential,
                Expected_Version => Credential.Version,
                Counter          => Creds.TOTP_Counter (Outcome.Counter)),
               Context, Event, Recorded_At);
         end;
      end;
   end Execute;
end Identity.Operations.Factors.Verify_TOTP;

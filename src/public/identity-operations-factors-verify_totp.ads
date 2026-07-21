with Ada.Streams;
with Identity.Adapters.Repositories.Stores;
with Identity.Crypto.CryptoLib.Secret_Box;
with Identity.Identifiers.Entities;
with Identity.One_Time_Passwords.Credentials;
with Identity.Operations.Contexts;
with Identity.Times;

--  Verify a presented TOTP code against the enrolled secret, then advance the
--  replay counter -- the code-verification half of TOTP the crate previously
--  delegated to the caller.
--
--  The secret is stored sealed (see Factors.Complete_Enrollment), so
--  verification needs the same key it was sealed under. The caller manages
--  that key; the crate never persists it. On a verified, non-replayed code the
--  operation advances the credential's replay state exactly as
--  Accept_TOTP_Counter does, and emits the same events.
package Identity.Operations.Factors.Verify_TOTP is

   type Verify_Request is record
      Credential     : Identity.Identifiers.Entities.Credential_Id;
      --  The decimal code the user presented, e.g. 492871.
      Presented_Code : Natural;
      --  The instant to verify against; the time step is derived from it.
      Now            : Identity.Times.Instant;
      --  How many 30-second steps of clock skew to accept on each side.
      Skew_Steps     : Natural := 1;
      --  Key the secret was sealed under at enrollment.
      Opening_Key    : Identity.Crypto.CryptoLib.Secret_Box.Key_Bytes;
   end record;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Verify_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;

   --  Encode a sealed box as the byte-string stored in a TOTP credential's
   --  verifier field, and decode it back. Exposed so enrollment and this
   --  operation agree on the representation.
   function Encode_Box
     (Box : Ada.Streams.Stream_Element_Array) return String;
   function Decode_Box
     (Text : String) return Ada.Streams.Stream_Element_Array;
end Identity.Operations.Factors.Verify_TOTP;

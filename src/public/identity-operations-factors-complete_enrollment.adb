with Ada.Streams;
with Identity.Credentials.States;
with Identity.Crypto.CryptoLib.Entropy;
with Identity.Events.Types;
with Identity.Limits;
with Identity.Operations.Audit;
with Identity.Operations.Factors.Verify_TOTP;
with Identity.Secrets.Bytes;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Complete_Enrollment is
   package Box renames Identity.Crypto.CryptoLib.Secret_Box;
   use type Box.Seal_Status;
   use type Ada.Streams.Stream_Element_Offset;

   --  Seal the shared secret for storage. A failure (no entropy for the nonce,
   --  an over-long secret, or a seal error) yields an empty verifier, which
   --  makes the stored credential unusable for verification rather than
   --  storing something unverifiable -- fail closed.
   function Seal_Verifier
     (Secret : Identity.Secrets.One_Time_Passwords.TOTP_Secret;
      Key    : Box.Key_Bytes) return Identity.Text.Bounded.Bounded_Text
   is
      Buffer : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Last   : Natural;
      Nonce  : Ada.Streams.Stream_Element_Array (1 .. 12);
   begin
      if not Identity.Crypto.CryptoLib.Entropy.Fill_Bytes (Nonce) then
         return Identity.Text.Bounded.From_String ("");
      end if;
      Identity.Secrets.Bytes.Borrow (Secret, Buffer, Last);
      if Ada.Streams.Stream_Element_Offset (Last) > Box.Max_Secret_Length then
         return Identity.Text.Bounded.From_String ("");
      end if;
      declare
         Sealed : constant Box.Sealed_Secret :=
           Box.Seal
             (Key, Nonce,
              Buffer (1 .. Ada.Streams.Stream_Element_Offset (Last)));
      begin
         if Sealed.Status /= Box.Sealed then
            return Identity.Text.Bounded.From_String ("");
         end if;
         return Identity.Text.Bounded.From_String
           (Verify_TOTP.Encode_Box (Sealed.Data));
      end;
   end Seal_Verifier;
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_TOTP_Enrollment
        (Repository, Credential);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : TOTP_Completion_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_TOTP_Enrollment
        (Repository,
         (Id              => Request.Id,
          Principal       => Request.Principal,
          Algorithm       => Request.Algorithm,
          Secret_Verifier => Seal_Verifier (Request.Secret, Request.Sealing_Key),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Created_At,
          Highest_Accepted_Counter => Request.Highest_Accepted_Counter,
          Version         => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_TOTP_Completion_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_TOTP_Enrollment
        (Repository,
         (Id              => Request.Request.Id,
          Principal       => Request.Request.Principal,
          Algorithm       => Request.Request.Algorithm,
          Secret_Verifier =>
            Seal_Verifier (Request.Request.Secret, Request.Request.Sealing_Key),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Request.Created_At,
          Highest_Accepted_Counter => Request.Request.Highest_Accepted_Counter,
          Version         => 0),
         Request.Expected_Credential_Version);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_TOTP_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would leave a live second
      --  factor whose enrollment nobody can trace.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.MFA_Factor_Enrolled,
              Subject     => Identity.Operations.Audit.Subject_Of
                (Request.Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Request.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve before mutating, exactly as the request form does: a
      --  transition that cannot be recorded is refused rather than applied.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Credential);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.MFA_Factor_Enrolled,
              Subject     => Identity.Operations.Audit.Subject_Of (Credential.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Credential.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : TOTP_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve before mutating, exactly as the request form does: a
      --  transition that cannot be recorded is refused rather than applied.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.MFA_Factor_Enrolled,
              Subject     => Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Factors.Complete_Enrollment;

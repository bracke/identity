with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Accept_TOTP_Counter is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Accept_TOTP_Counter
        (Repository, Credential, Counter);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Accept_Request)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Accept_TOTP_Counter
        (Repository,
         Request.Credential,
         Request.Expected_Version,
         Request.Counter);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Accept_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      use type Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;

      Status : Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;
   begin
      --  Reserve before the counter can advance: whether this presentation
      --  turns out to be a replay is only known afterwards, so the capacity
      --  for that event has to be held from the start.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.One_Time_Passwords.Credentials.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      if Status /= Identity.One_Time_Passwords.Credentials.Replayed then
         --  Every other verdict is ordinary traffic; only a replay is worth
         --  a security event of its own.
         return Status;
      end if;

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.TOTP_Replay_Detected,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Credential)),
              Outcome     => Identity.Events.Envelopes.Conflict,
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store; a detected replay must never go unrecorded.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.One_Time_Passwords.Credentials.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Factors.Accept_TOTP_Counter;

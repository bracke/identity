with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Identifiers.Registry;
with Identity.Operations.Audit;
with Identity.Text.Bounded;
with Identity.Tokens.Purposes;

package body Identity.Operations.Passwords.Request_Reset is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      if Identity.Identifiers.Registry.Image (Token.Purpose)
        /= Identity.Identifiers.Registry.Image (Identity.Tokens.Purposes.Password_Reset)
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      return Identity.Adapters.Repositories.Stores.Issue_Token (Repository, Token);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Reset_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Issue_Token
        (Repository,
         (Id              => Request.Id,
          Purpose         => Identity.Tokens.Purposes.Password_Reset,
          Principal       => Request.Principal,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Password_Reset_Token, Request.Secret),
          Issued_At       => Request.Issued_At,
          Expires_At      => Request.Expires_At,
          State           => Identity.Tokens.Definitions.Issued,
          Attempts        => 0,
          Version         => 0));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Reset_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
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
              Type_Id     => Identity.Events.Types.Password_Reset_Requested,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Passwords.Request_Reset;

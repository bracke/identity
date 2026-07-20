with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Tokens.Consume is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Consume_Token
        (Repository, Token, Purpose, Secret, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Consume_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Consume_Token
        (Repository,
         Request.Token,
         Request.Expected_Version,
         Request.Purpose,
         Request.Secret,
         Request.Now);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Consume_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      --  Reserve first: refusing here leaves the token unspent, whereas a full
      --  event log discovered afterwards would have already burned it with
      --  nothing on record.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Tokens.Verification.Infrastructure_Failure;
      end if;

      Outcome := Execute (Repository, Request);

      declare
         --  The request carries no principal of its own -- the token names the
         --  holder -- so the token id is the target and there is no subject.
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Token_Consumed,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Token)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Outcome),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Tokens.Verification.Infrastructure_Failure;
         end if;
      end;

      return Outcome;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Purpose     : Identity.Identifiers.Registry.Registry_Id;
      Secret      : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      --  Reserve first: refusing here leaves the token unspent, whereas a full
      --  event log discovered afterwards would have already burned it with
      --  nothing on record.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Tokens.Verification.Infrastructure_Failure;
      end if;

      Outcome := Execute (Repository, Token, Purpose, Secret, Now);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Token_Consumed,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Token)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Outcome),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Tokens.Verification.Infrastructure_Failure;
         end if;
      end;

      return Outcome;
   end Execute;
end Identity.Operations.Tokens.Consume;

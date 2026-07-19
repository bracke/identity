with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Verification.Complete is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Contact_Verification
        (Repository, Token, Secret, Now, Contact);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Contact_Verification
        (Repository,
         Request.Token,
         Request.Expected_Token_Version,
         Request.Expected_Contact_Version,
         Request.Secret,
         Request.Now,
         Request.Contact);
   end Execute;

   --  A token verdict is not a store command status: an unusable token is a
   --  rejection, a losing version check is a conflict, and only broken
   --  infrastructure is a failure.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Tokens.Verification.Infrastructure_Failure;
      end if;

      Outcome := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Contact_Verified,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Contact)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Outcome),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Tokens.Verification.Infrastructure_Failure;
         end if;
      end;

      return Outcome;
   end Execute;
end Identity.Operations.Verification.Complete;

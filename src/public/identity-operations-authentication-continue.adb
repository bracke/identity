with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Authentication.Continue is
   --  A transaction verdict is not a store command status: an unknown or
   --  wrongly-staged transaction is a conflict, and nothing here is a plain
   --  credential rejection.

   function Complete_Challenge
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Challenge
        (Repository, Challenge, Principal, Now);
   end Complete_Challenge;

   function Complete_Challenge
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Challenge_Completion_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Challenge
        (Repository,
         Request.Challenge,
         Request.Principal,
         Request.Now,
         Request.Expected_Challenge_Version,
         Request.Expected_Transaction_Version);
   end Complete_Challenge;

   function Complete_Challenge
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Challenge_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Authentication.Transactions
        .Authentication_Transaction_Status;
   begin
      --  Reserve first: refusing here leaves the challenge and its
      --  transaction untouched.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Authentication.Transactions.Capacity_Conflict;
      end if;

      Status := Complete_Challenge (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.MFA_Challenge_Completed,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Challenge)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Authentication.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Complete_Challenge;

   function Satisfy
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Satisfy_Authentication_Transaction
        (Repository, Transaction, Principal, Now);
   end Satisfy;

   function Satisfy
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Satisfaction_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Satisfy_Authentication_Transaction
        (Repository,
         Request.Transaction,
         Request.Principal,
         Request.Now,
         Request.Expected_Version);
   end Satisfy;

   function Resolve
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Authentication.Transactions.Authentication_Transaction_Action;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Authentication.Transactions.Authentication_Transaction_Status;
   begin
      --  Reserve first: an unsuccessful resolution is exactly the outcome an
      --  account owner needs recorded, so it must not be applied silently.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Authentication.Transactions.Capacity_Conflict;
      end if;

      Status := Identity.Adapters.Repositories.Stores.Resolve_Authentication_Transaction
        (Repository, Transaction, Principal, Action, Now, Expected_Version);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Authentication_Rejected,
              Subject     => Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Transaction)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Authentication.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Resolve;
end Identity.Operations.Authentication.Continue;

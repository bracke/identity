with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Recovery.Complete is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Recovery
        (Repository, Transaction, Principal, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Completion_Request)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Recovery
        (Repository,
         Request.Transaction,
         Request.Principal,
         Request.Now,
         Request.Expected_Transaction_Version,
         Request.Expected_Account_Version);
   end Execute;

   --  A recovery verdict is not a store command status: an unknown or
   --  wrongly-staged transaction is a conflict, and nothing here is a plain
   --  credential rejection.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Recovery.Transactions.Recovery_Transition_Status;
   begin
      --  Reserve first: refusing here leaves the recovery transaction and the
      --  account it would release untouched.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Recovery.Transactions.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Recovery_Completed,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Transaction)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Recovery.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Recovery.Transactions.Recovery_Transition_Status;
   begin
      --  Reserve first: refusing here leaves the recovery transaction and the
      --  account it would release untouched.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Recovery.Transactions.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Transaction, Principal, Now);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Recovery_Completed,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Transaction)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Recovery.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Recovery.Complete;

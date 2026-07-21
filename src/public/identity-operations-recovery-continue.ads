with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Recovery.Transactions;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Recovery.Continue is
   type Staged_Continue_Request is record
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version;
   end record;

   --  Audited advance: each step a recovery takes toward releasing an account
   --  has to be reconstructable afterwards, not just the final release.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Continue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   --  Audited advance taking the transaction, principal and clock reading
   --  directly.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   --  Audited advance through a mid-flow admission action: approval, requiring
   --  credential re-establishment, or establishing restricted authentication.
   --  This is what makes the approval path reachable; before it, a recovery
   --  could only accept evidence and then complete, and the Approved and
   --  Credential_Reestablishment_Required states were dead. Audited under
   --  identity.recovery.continued like the evidence step.
   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Recovery.Transactions.Recovery_Transaction_Action;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;
end Identity.Operations.Recovery.Continue;

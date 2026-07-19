with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Recovery.Transactions;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Recovery.Complete is
   type Staged_Completion_Request is record
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
      Expected_Account_Version     : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Completion_Request)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;
end Identity.Operations.Recovery.Complete;

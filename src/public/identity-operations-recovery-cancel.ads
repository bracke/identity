with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Recovery.Transactions;
with Identity.Versions;

package Identity.Operations.Recovery.Cancel is
   type Staged_Cancellation_Request is record
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Cancellation_Request)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;
end Identity.Operations.Recovery.Cancel;

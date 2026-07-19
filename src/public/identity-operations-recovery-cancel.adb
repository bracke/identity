package body Identity.Operations.Recovery.Cancel is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Cancel_Recovery
        (Repository, Transaction, Principal);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Cancellation_Request)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Cancel_Recovery
        (Repository,
         Request.Transaction,
         Request.Principal,
         Request.Expected_Version);
   end Execute;
end Identity.Operations.Recovery.Cancel;

package body Identity.Operations.Recovery.Continue is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Accept_Recovery_Evidence
        (Repository, Transaction, Principal, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Continue_Request)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Accept_Recovery_Evidence
        (Repository,
         Request.Transaction,
         Request.Principal,
         Request.Now,
         Request.Expected_Version);
   end Execute;
end Identity.Operations.Recovery.Continue;

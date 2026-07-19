package body Identity.Operations.Authentication.Begin_Transaction is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Begin_Authentication_Transaction
        (Repository, Transaction);
   end Execute;
end Identity.Operations.Authentication.Begin_Transaction;

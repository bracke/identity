package body Identity.Operations.Authentication.Begin_Transaction is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_Authentication_Transaction
        (Repository, Transaction);
   end Execute;
end Identity.Operations.Authentication.Begin_Transaction;

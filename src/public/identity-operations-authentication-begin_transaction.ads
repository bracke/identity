with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Transactions;

package Identity.Operations.Authentication.Begin_Transaction is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Authentication.Begin_Transaction;

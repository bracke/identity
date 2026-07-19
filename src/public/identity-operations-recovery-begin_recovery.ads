with Identity.Adapters.Repositories.Stores;
with Identity.Recovery.Transactions;

package Identity.Operations.Recovery.Begin_Recovery is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;
end Identity.Operations.Recovery.Begin_Recovery;

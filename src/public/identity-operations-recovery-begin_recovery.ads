with Identity.Adapters.Repositories.Memory;
with Identity.Recovery.Transactions;

package Identity.Operations.Recovery.Begin_Recovery is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status;
end Identity.Operations.Recovery.Begin_Recovery;

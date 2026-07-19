package body Identity.Operations.Recovery.Begin_Recovery is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Begin_Recovery (Repository, Transaction);
   end Execute;
end Identity.Operations.Recovery.Begin_Recovery;

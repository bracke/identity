package body Identity.Operations.Recovery.Begin_Recovery is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_Recovery (Repository, Transaction);
   end Execute;
end Identity.Operations.Recovery.Begin_Recovery;

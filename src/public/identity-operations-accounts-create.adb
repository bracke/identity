package body Identity.Operations.Accounts.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account    : Identity.Accounts.Definitions.Account_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Create_Account (Repository, Account);
   end Execute;
end Identity.Operations.Accounts.Create;

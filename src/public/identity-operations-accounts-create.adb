package body Identity.Operations.Accounts.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Account    : Identity.Accounts.Definitions.Account_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Create_Account (Repository, Account);
   end Execute;
end Identity.Operations.Accounts.Create;

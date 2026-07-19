with Identity.Accounts.Definitions;
with Identity.Adapters.Repositories.Memory;

package Identity.Operations.Accounts.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Account    : Identity.Accounts.Definitions.Account_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Accounts.Create;

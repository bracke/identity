with Identity.Accounts.Definitions;
with Identity.Adapters.Repositories.Stores;

package Identity.Operations.Accounts.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account    : Identity.Accounts.Definitions.Account_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Accounts.Create;

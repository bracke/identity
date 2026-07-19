with Identity.Adapters.Repositories.Stores;
with Identity.Accounts.Administrative;
with Identity.Identifiers.Entities;

package Identity.Operations.Accounts.Disable is
   type Disable_Request is record
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Transition : Identity.Accounts.Administrative.Administrative_Transition_Request;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Disable_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Accounts.Disable;

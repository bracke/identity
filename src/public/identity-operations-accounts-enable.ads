with Identity.Adapters.Repositories.Memory;
with Identity.Accounts.Administrative;
with Identity.Identifiers.Entities;

package Identity.Operations.Accounts.Enable is
   type Enable_Request is record
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Transition : Identity.Accounts.Administrative.Administrative_Transition_Request;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Enable_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Accounts.Enable;

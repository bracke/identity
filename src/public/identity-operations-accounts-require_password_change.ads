with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Operations.Accounts.Require_Password_Change is
   type Requirement_Request is record
      Account          : Identity.Identifiers.Entities.Account_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Requirement_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Accounts.Require_Password_Change;

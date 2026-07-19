with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Operations.Principals.Retire is
   type Staged_Retire_Request is record
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Retire_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Principals.Retire;

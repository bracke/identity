with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Operations.External_Identities.Revoke is
   type Staged_Revoke_Request is record
      Binding                  : Identity.Identifiers.Entities.External_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Binding    : Identity.Identifiers.Entities.External_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.External_Identities.Revoke;

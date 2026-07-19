with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Operations.Factors.Remove is
   type Staged_Removal_Request is record
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Principal                   : Identity.Identifiers.Entities.Principal_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Removal_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Remove;

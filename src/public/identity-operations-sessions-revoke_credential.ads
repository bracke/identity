with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;

package Identity.Operations.Sessions.Revoke_Credential is
   type Staged_Revoke_Request is record
      Credential              : Identity.Identifiers.Entities.Credential_Id;
      Expected_Affected_Count : Natural;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Credential : Identity.Identifiers.Entities.Credential_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Sessions.Revoke_Credential;

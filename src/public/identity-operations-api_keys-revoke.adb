package body Identity.Operations.API_Keys.Revoke is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Credential : Identity.Identifiers.Entities.Credential_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_API_Key (Repository, Credential);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_API_Key
        (Repository, Request.Credential, Request.Expected_Credential_Version);
   end Execute;
end Identity.Operations.API_Keys.Revoke;

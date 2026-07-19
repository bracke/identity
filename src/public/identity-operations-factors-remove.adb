package body Identity.Operations.Factors.Remove is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Remove_TOTP
        (Repository, Credential, Principal);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Removal_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Remove_TOTP
        (Repository,
         Request.Credential,
         Request.Principal,
         Request.Expected_Credential_Version);
   end Execute;
end Identity.Operations.Factors.Remove;

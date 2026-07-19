package body Identity.Operations.External_Identities.Revoke is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Binding    : Identity.Identifiers.Entities.External_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_External
        (Repository, Binding, Principal);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_External
        (Repository,
         Request.Binding,
         Request.Principal,
         Request.Expected_Binding_Version);
   end Execute;
end Identity.Operations.External_Identities.Revoke;

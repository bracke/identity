package body Identity.Operations.Sessions.Revoke_Provider is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Provider   : Identity.Identifiers.Entities.External_Provider_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_Provider_Sessions
        (Repository, Provider);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_Provider_Sessions
        (Repository, Request.Provider, Request.Expected_Affected_Count);
   end Execute;
end Identity.Operations.Sessions.Revoke_Provider;

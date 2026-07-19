package body Identity.Operations.Sessions.Revoke_Principal is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_Principal_Sessions
        (Repository, Principal);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Revoke_Principal_Sessions
        (Repository, Request.Principal, Request.Expected_Affected_Count);
   end Execute;
end Identity.Operations.Sessions.Revoke_Principal;

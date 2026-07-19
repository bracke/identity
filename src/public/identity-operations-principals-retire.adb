package body Identity.Operations.Principals.Retire is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Retire_Principal
        (Repository, Principal);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Retire_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Retire_Principal
        (Repository, Request.Principal, Request.Expected_Version);
   end Execute;
end Identity.Operations.Principals.Retire;

package body Identity.Operations.Principals.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Principals.Definitions.Principal_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Create_Principal (Repository, Principal);
   end Execute;
end Identity.Operations.Principals.Create;

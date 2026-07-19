package body Identity.Operations.Principals.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Principals.Definitions.Principal_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Create_Principal (Repository, Principal);
   end Execute;
end Identity.Operations.Principals.Create;

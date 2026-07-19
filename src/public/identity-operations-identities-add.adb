package body Identity.Operations.Identities.Add is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Binding    : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Add_Binding (Repository, Binding);
   end Execute;
end Identity.Operations.Identities.Add;

package body Identity.Operations.Identities.Add is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding    : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Add_Binding (Repository, Binding);
   end Execute;
end Identity.Operations.Identities.Add;

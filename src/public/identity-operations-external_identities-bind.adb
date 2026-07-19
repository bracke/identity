package body Identity.Operations.External_Identities.Bind is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Bind_External (Repository, Binding);
   end Execute;
end Identity.Operations.External_Identities.Bind;

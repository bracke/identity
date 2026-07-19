package body Identity.Operations.External_Identities.Bind is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Bind_External (Repository, Binding);
   end Execute;
end Identity.Operations.External_Identities.Bind;

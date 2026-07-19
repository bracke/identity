with Identity.Adapters.Repositories.Memory;
with Identity.External_Providers.Bindings;

package Identity.Operations.External_Identities.Bind is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.External_Identities.Bind;

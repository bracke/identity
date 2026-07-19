with Identity.Adapters.Repositories.Memory;
with Identity.Identities.Bindings;

package Identity.Operations.Identities.Add is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Binding    : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Identities.Add;

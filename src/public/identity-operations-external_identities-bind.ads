with Identity.Adapters.Repositories.Stores;
with Identity.External_Providers.Bindings;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.External_Identities.Bind is

   --  Audited form. Emits identity.external.binding.created for the binding,
   --  and refuses the operation if the store cannot accept that event, so a
   --  new route into an account never appears without a record of it.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding     : Identity.External_Providers.Bindings.External_Binding_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.External_Identities.Bind;

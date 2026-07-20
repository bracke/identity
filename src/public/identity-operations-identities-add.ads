with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Identities.Bindings;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Identities.Add is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding    : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.binding.added for the transition, and
   --  refuses the operation if the store cannot accept that event, so a new
   --  way of signing in is never added without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding     : Identity.Identities.Bindings.Binding_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Identities.Add;

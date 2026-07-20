with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Principals.Definitions;
with Identity.Times;

package Identity.Operations.Principals.Create is

   --  Audited form. Emits identity.principal.created for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  principal never comes into existence without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal   : Identity.Principals.Definitions.Principal_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Principals.Create;

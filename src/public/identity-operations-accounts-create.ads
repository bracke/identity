with Identity.Accounts.Definitions;
with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Accounts.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account    : Identity.Accounts.Definitions.Account_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.account.created for the transition, and
   --  refuses the operation if the store cannot accept that event, so an
   --  account never exists without a record of who brought it into being.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account     : Identity.Accounts.Definitions.Account_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Accounts.Create;

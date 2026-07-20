with Identity.Accounts.Administrative;
with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Accounts.Suspend is
   type Suspend_Request is record
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Transition : Identity.Accounts.Administrative.Administrative_Transition_Request;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Suspend_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.account.suspended for the transition, and refuses
   --  the operation if the store cannot accept that event, so an account is
   --  never suspended without a record of who suspended it.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Suspend_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account     : Identity.Identifiers.Entities.Account_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Accounts.Suspend;

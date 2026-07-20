with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Accounts.Require_MFA is
   type Requirement_Request is record
      Account          : Identity.Identifiers.Entities.Account_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version;
   end record;

   --  Audited form. Emits identity.account.mfa-required for the transition, and
   --  refuses the operation if the store cannot accept that event, so
   --  the requirement is never imposed without a record of who imposed it.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Requirement_Request;
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
end Identity.Operations.Accounts.Require_MFA;

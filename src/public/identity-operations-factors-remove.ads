with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Factors.Remove is
   type Staged_Removal_Request is record
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Principal                   : Identity.Identifiers.Entities.Principal_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version;
   end record;

   --  Audited form. Emits identity.mfa.factor.removed for the transition, and
   --  refuses the operation if the store cannot accept that event, so a factor
   --  is never removed without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Removal_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.Identifiers.Entities.Credential_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Remove;

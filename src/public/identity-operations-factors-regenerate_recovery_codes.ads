with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Operations.Factors.Generate_Recovery_Codes;
with Identity.Recovery_Codes.Sets;
with Identity.Times;

package Identity.Operations.Factors.Regenerate_Recovery_Codes is
   subtype Regenerate_Request is Identity.Operations.Factors.Generate_Recovery_Codes.Generate_Request;

   type Staged_Regenerate_Request is record
      Request                 : Regenerate_Request;
      Expected_Affected_Count : Natural;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Regenerate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Regenerate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.recovery-codes.generated for the
   --  transition, and refuses the operation if the store cannot accept that
   --  event, so a code set is never replaced without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Regenerate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes       : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Regenerate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Regenerate_Recovery_Codes;

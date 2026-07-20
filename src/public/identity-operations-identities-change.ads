with Identity.Adapters.Repositories.Stores;
with Identity.Identities.Bindings;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Identities.Change is
   type Staged_Change_Request is record
      Predecessor                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Identities.Bindings.Binding_Record;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Change_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited change: repointing a sign-in route is exactly the change an
   --  investigation needs to be able to attribute afterwards.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Change_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited change, taking the binding pair directly. Same record as the
   --  staged form; only the way the change is stated differs.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Identities.Change;

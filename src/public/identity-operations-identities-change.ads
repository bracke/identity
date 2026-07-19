with Identity.Adapters.Repositories.Memory;
with Identity.Identities.Bindings;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Operations.Identities.Change is
   type Staged_Change_Request is record
      Predecessor                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Identities.Bindings.Binding_Record;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Change_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Identities.Change;

package body Identity.Operations.Identities.Change is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Change_Binding
        (Repository, Predecessor, Successor);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Change_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Change_Binding
        (Repository,
         Request.Predecessor,
         Request.Expected_Predecessor_Version,
         Request.Successor);
   end Execute;
end Identity.Operations.Identities.Change;

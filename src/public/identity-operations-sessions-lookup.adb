package body Identity.Operations.Sessions.Lookup is
   function Execute
     (Repository       : Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle is
   begin
      return Identity.Adapters.Repositories.Stores.Lookup_Session
        (Repository, Public_Reference, Secret, Now);
   end Execute;
end Identity.Operations.Sessions.Lookup;

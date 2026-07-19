package body Identity.Operations.Sessions.Lookup is
   function Execute
     (Repository       : Identity.Adapters.Repositories.Memory.Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle is
   begin
      return Identity.Adapters.Repositories.Memory.Lookup_Session
        (Repository, Public_Reference, Secret, Now);
   end Execute;
end Identity.Operations.Sessions.Lookup;

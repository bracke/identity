package body Identity.Operations.Sessions.Update_Activity is
   function Execute
     (Repository       : in out Identity.Adapters.Repositories.Memory.Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle is
   begin
      return Identity.Adapters.Repositories.Memory.Renew_Session
        (Repository, Public_Reference, Secret, Now, Idle_Expires_At);
   end Execute;
end Identity.Operations.Sessions.Update_Activity;

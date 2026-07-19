package body Identity.Operations.Sessions.Update_Activity is
   function Execute
     (Repository       : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle is
   begin
      return Identity.Adapters.Repositories.Stores.Renew_Session
        (Repository, Public_Reference, Secret, Now, Idle_Expires_At);
   end Execute;
end Identity.Operations.Sessions.Update_Activity;

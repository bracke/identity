package body Identity.Operations.Sessions.Expire_Eligible is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Now        : Identity.Times.Instant) return Natural is
   begin
      return Identity.Adapters.Repositories.Stores.Expire_Eligible_Sessions
        (Repository, Now);
   end Execute;
end Identity.Operations.Sessions.Expire_Eligible;

package body Identity.Operations.Sessions.Expire_Eligible is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Now        : Identity.Times.Instant) return Natural is
   begin
      return Identity.Adapters.Repositories.Memory.Expire_Eligible_Sessions
        (Repository, Now);
   end Execute;
end Identity.Operations.Sessions.Expire_Eligible;

with Identity.Adapters.Repositories.Memory;
with Identity.Times;

package Identity.Operations.Sessions.Expire_Eligible is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Now        : Identity.Times.Instant) return Natural;
end Identity.Operations.Sessions.Expire_Eligible;

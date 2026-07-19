with Identity.Adapters.Repositories.Stores;
with Identity.Times;

package Identity.Operations.Sessions.Expire_Eligible is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Now        : Identity.Times.Instant) return Natural;
end Identity.Operations.Sessions.Expire_Eligible;

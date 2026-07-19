with Identity.Adapters.Repositories.Stores;
with Identity.Policies.Snapshots;
with Identity.Times;

package Identity.Operations.Sessions.Purge_Retained is
   function Retention_Boundary
     (Now    : Identity.Times.Instant;
      Policy : Identity.Policies.Snapshots.Session_Policy;
      Ok     : out Boolean) return Identity.Times.Instant;

   function Execute
     (Repository   : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Retain_After : Identity.Times.Instant) return Natural;
end Identity.Operations.Sessions.Purge_Retained;

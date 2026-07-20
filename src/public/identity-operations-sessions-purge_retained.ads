with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
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

   --  Audited form. The purge is one operation however many rows it removes,
   --  so it emits a single identity.session.purged event whose target carries
   --  the affected count. Capacity for that one event is reserved first: a
   --  store that cannot accept it refuses the purge and removes nothing,
   --  reported as zero affected rows.
   function Execute
     (Repository   : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Retain_After : Identity.Times.Instant;
      Context      : Identity.Operations.Contexts.Operation_Context;
      Event        : Identity.Identifiers.Entities.Event_Id;
      Recorded_At  : Identity.Times.Instant) return Natural;
end Identity.Operations.Sessions.Purge_Retained;

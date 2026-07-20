with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Sessions.Expire_Eligible is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Now        : Identity.Times.Instant) return Natural;

   --  Audited form. The sweep is one operation however many sessions it
   --  touches, so it emits a single identity.session.expired event whose
   --  target carries the affected count. Capacity for that one event is
   --  reserved first: a store that cannot accept it refuses the sweep and
   --  expires nothing, reported as zero affected sessions.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant) return Natural;
end Identity.Operations.Sessions.Expire_Eligible;

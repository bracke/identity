with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.Sessions;
with Identity.Sessions.Handles;
with Identity.Text.Bounded;
with Identity.Times;

package Identity.Operations.Sessions.Renew is

   --  Audited renewal: extending a session's life is a change to how long a
   --  credential stays usable, so it leaves a record like any other.
   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle;
end Identity.Operations.Sessions.Renew;

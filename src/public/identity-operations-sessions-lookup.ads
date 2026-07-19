with Identity.Adapters.Repositories.Memory;
with Identity.Secrets.Sessions;
with Identity.Sessions.Handles;
with Identity.Text.Bounded;
with Identity.Times;

package Identity.Operations.Sessions.Lookup is
   function Execute
     (Repository       : Identity.Adapters.Repositories.Memory.Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle;
end Identity.Operations.Sessions.Lookup;

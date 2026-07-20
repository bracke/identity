with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Sessions.Revoke is
   type Staged_Revoke_Request is record
      Session                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Session_Version : Identity.Versions.Entity_Version;
   end record;

   --  Audited form. Emits identity.session.revoked for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  session is never revoked without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Revoke_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form taking the session directly, for callers that hold no
   --  expected version to stage.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Sessions.Revoke;

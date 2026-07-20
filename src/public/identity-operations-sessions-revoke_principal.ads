with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Sessions.Revoke_Principal is
   type Staged_Revoke_Request is record
      Principal               : Identity.Identifiers.Entities.Principal_Id;
      Expected_Affected_Count : Natural;
   end record;

   --  Audited form. Emits identity.session.revoked for the principal-wide
   --  revocation, and refuses the operation if the store cannot accept that
   --  event, so sessions are never revoked without an audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Revoke_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form taking the principal directly, for callers that hold no
   --  expected count to stage.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Sessions.Revoke_Principal;

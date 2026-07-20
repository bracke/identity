with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Sessions.Revoke_Provider is
   type Staged_Revoke_Request is record
      Provider                : Identity.Identifiers.Entities.External_Provider_Id;
      Expected_Affected_Count : Natural;
   end record;

   --  Audited form. Emits identity.session.revoked for the provider-wide
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

   --  Audited form taking the provider directly, for callers that hold no
   --  expected count to stage.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Provider    : Identity.Identifiers.Entities.External_Provider_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Sessions.Revoke_Provider;

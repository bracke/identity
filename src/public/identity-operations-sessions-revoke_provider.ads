with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;

package Identity.Operations.Sessions.Revoke_Provider is
   type Staged_Revoke_Request is record
      Provider                : Identity.Identifiers.Entities.External_Provider_Id;
      Expected_Affected_Count : Natural;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Provider   : Identity.Identifiers.Entities.External_Provider_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Sessions.Revoke_Provider;

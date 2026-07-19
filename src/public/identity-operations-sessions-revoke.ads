with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Operations.Sessions.Revoke is
   type Staged_Revoke_Request is record
      Session                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Session_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Session    : Identity.Identifiers.Entities.Session_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Sessions.Revoke;

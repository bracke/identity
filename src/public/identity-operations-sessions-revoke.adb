package body Identity.Operations.Sessions.Revoke is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session    : Identity.Identifiers.Entities.Session_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Revoke_Session (Repository, Session);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Revoke_Session
        (Repository, Request.Session, Request.Expected_Session_Version);
   end Execute;
end Identity.Operations.Sessions.Revoke;

package body Identity.Operations.Sessions.Revoke_Family is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Family     : Identity.Identifiers.Entities.Session_Family_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Revoke_Session_Family
        (Repository, Family);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Revoke_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Revoke_Session_Family
        (Repository, Request.Family, Request.Expected_Affected_Count);
   end Execute;
end Identity.Operations.Sessions.Revoke_Family;

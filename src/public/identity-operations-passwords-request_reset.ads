with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Definitions;

package Identity.Operations.Passwords.Request_Reset is
   type Reset_Request is record
      Id         : Identity.Identifiers.Entities.Token_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Issued_At  : Identity.Times.Instant := 0;
      Expires_At : Identity.Times.Expiration;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Reset_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Passwords.Request_Reset;

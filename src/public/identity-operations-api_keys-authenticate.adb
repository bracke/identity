package body Identity.Operations.API_Keys.Authenticate is
   function Execute
     (Repository    : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Stores.Authenticate_API_Key
        (Repository, Public_Key_Id, Secret, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Authentication_Request)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Stores.Authenticate_API_Key
        (Repository,
         Request.Public_Key_Id,
         Request.Secret,
         Request.Now,
         Request.Expected_Credential_Version);
   end Execute;
end Identity.Operations.API_Keys.Authenticate;

with Identity.Operations.API_Keys.Authenticate;

package body Identity.Operations.Authentication.API_Key is
   function Execute
     (Repository    : in out Identity.Adapters.Repositories.Memory.Store;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Operations.API_Keys.Authenticate.Execute
        (Repository, Public_Key_Id, Secret, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Authentication_Request)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Operations.API_Keys.Authenticate.Execute
        (Repository,
         Identity.Operations.API_Keys.Authenticate.Staged_Authentication_Request'
           (Public_Key_Id => Request.Public_Key_Id,
            Secret => Request.Secret,
            Now => Request.Now,
            Expected_Credential_Version => Request.Expected_Credential_Version));
   end Execute;
end Identity.Operations.Authentication.API_Key;

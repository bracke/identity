with Identity.Adapters.Repositories.Memory;
with Identity.Authentication.Results;
with Identity.Secrets.API_Keys;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.API_Keys.Authenticate is
   type Staged_Authentication_Request is record
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository    : in out Identity.Adapters.Repositories.Memory.Store;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Authentication_Request)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.API_Keys.Authenticate;

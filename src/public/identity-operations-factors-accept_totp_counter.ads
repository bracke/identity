with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.One_Time_Passwords.Credentials;
with Identity.Versions;

package Identity.Operations.Factors.Accept_TOTP_Counter is
   type Accept_Request is record
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Counter          : Identity.One_Time_Passwords.Credentials.TOTP_Counter;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Accept_Request)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;
end Identity.Operations.Factors.Accept_TOTP_Counter;

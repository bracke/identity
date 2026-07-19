package body Identity.Operations.Factors.Accept_TOTP_Counter is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Accept_TOTP_Counter
        (Repository, Credential, Counter);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Accept_Request)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Accept_TOTP_Counter
        (Repository,
         Request.Credential,
         Request.Expected_Version,
         Request.Counter);
   end Execute;
end Identity.Operations.Factors.Accept_TOTP_Counter;

with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.One_Time_Passwords.Credentials;
with Identity.Secrets.One_Time_Passwords;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Factors.Complete_Enrollment is
   type TOTP_Completion_Request is record
      Id              : Identity.Identifiers.Entities.Credential_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Algorithm       : Identity.Identifiers.Registry.Registry_Id;
      Secret          : Identity.Secrets.One_Time_Passwords.TOTP_Secret;
      Created_At      : Identity.Times.Instant := 0;
      Highest_Accepted_Counter : Identity.One_Time_Passwords.Credentials.TOTP_Counter := 0;
   end record;

   type Staged_TOTP_Completion_Request is record
      Request                     : TOTP_Completion_Request;
      Expected_Credential_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : TOTP_Completion_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_TOTP_Completion_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Complete_Enrollment;

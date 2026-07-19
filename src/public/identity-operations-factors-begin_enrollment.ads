with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.One_Time_Passwords.Credentials;
with Identity.Times;

package Identity.Operations.Factors.Begin_Enrollment is
   type TOTP_Begin_Request is record
      Id         : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Algorithm  : Identity.Identifiers.Registry.Registry_Id;
      Created_At : Identity.Times.Instant := 0;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : TOTP_Begin_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Factors.Begin_Enrollment;

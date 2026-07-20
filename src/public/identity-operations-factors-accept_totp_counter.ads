with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.One_Time_Passwords.Credentials;
with Identity.Operations.Contexts;
with Identity.Times;
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

   --  Audited form. A counter that has already been accepted is a reused
   --  one-time password, which is security-significant even though the
   --  operation correctly refuses it; that case, and only that case, emits
   --  identity.totp.replay-detected. Capacity is reserved before the counter
   --  advances, so a detected replay can always be recorded.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Accept_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.Identifiers.Entities.Credential_Id;
      Counter     : Identity.One_Time_Passwords.Credentials.TOTP_Counter;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status;
end Identity.Operations.Factors.Accept_TOTP_Counter;

with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.One_Time_Passwords.Credentials;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Factors.Begin_Enrollment is
   type TOTP_Begin_Request is record
      Id         : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Algorithm  : Identity.Identifiers.Registry.Registry_Id;
      Created_At : Identity.Times.Instant := 0;
   end record;

   --  Audited form. Emits identity.mfa.factor.enrollment-began, and refuses
   --  the operation if the store cannot accept that event, so a half-built
   --  factor never sits in the store unexplained.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : TOTP_Begin_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Begin_Enrollment;

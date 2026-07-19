with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Results;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identities.Subjects;
with Identity.Operations.Contexts;
with Identity.Secrets.Passwords;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Passwords.Authenticate is
   type Attempted_Request is record
      Subject             : Identity.Identities.Subjects.Authentication_Subject;
      Password            : Identity.Secrets.Passwords.Presented_Password;
      Attempt             : Identity.Identifiers.Entities.Attempt_Id;
      Correlation         : Identity.Identifiers.Operations.Correlation_Id;
      Subject_Fingerprint : Identity.Text.Bounded.Bounded_Text;
      Started_At          : Identity.Times.Instant := 0;
      Completed_At        : Identity.Times.Instant := 0;
      Lockout_Threshold   : Identity.Versions.Attempt_Count := 0;
   end record;

   function Execute
     (Repository : Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Subject    : Identity.Identities.Subjects.Authentication_Subject;
      Password   : Identity.Secrets.Passwords.Presented_Password)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Attempted_Request)
      return Identity.Authentication.Results.Password_Authentication_Result;

   --  Audited form. Emits identity.authentication.succeeded when the
   --  credential check passes and identity.authentication.rejected when it
   --  does not, and refuses the operation if the store cannot accept that
   --  event, so an attempt is never recorded without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Attempted_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.Passwords.Authenticate;

with Identity.Adapters.Repositories.Memory;
with Identity.Authentication.Results;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identities.Subjects;
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
     (Repository : Identity.Adapters.Repositories.Memory.Store;
      Subject    : Identity.Identities.Subjects.Authentication_Subject;
      Password   : Identity.Secrets.Passwords.Presented_Password)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Attempted_Request)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.Passwords.Authenticate;

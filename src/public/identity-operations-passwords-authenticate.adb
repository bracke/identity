with Identity.Accounts.Definitions;
with Identity.Accounts.States;
with Identity.Attempts.Definitions;
with Identity.Attempts.Outcomes;
with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Identifiers.Registry;
with Identity.Identities.Resolution;
with Identity.Passwords.Credentials;
with Identity.Principals.Definitions;
with Identity.Results;
with Identity.Secrets.Text;

package body Identity.Operations.Passwords.Authenticate is
   Password_Method : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.authentication.password");

   Synthetic_Password : constant Identity.Secrets.Passwords.New_Password :=
     Identity.Secrets.Text.From_UTF_8 ("identity synthetic password verifier");
   Synthetic_Verifier : constant String :=
     Identity.Crypto.Password_Hashing.Create_Verifier (Synthetic_Password);

   procedure Perform_Synthetic_Verification
     (Password : Identity.Secrets.Passwords.Presented_Password)
   is
      Result : constant Identity.Crypto.Password_Hashing.Verification_Result :=
        Identity.Crypto.Password_Hashing.Verify (Password, Synthetic_Verifier);
   begin
      pragma Unreferenced (Result);
      null;
   end Perform_Synthetic_Verification;

   function Execute
     (Repository : Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Subject    : Identity.Identities.Subjects.Authentication_Subject;
      Password   : Identity.Secrets.Passwords.Presented_Password)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Identities.Resolution.Resolution_Status;
      use type Identity.Crypto.Password_Hashing.Verification_Outcome;
      use type Identity.Accounts.States.Eligibility;
      use type Identity.Credentials.States.Credential_State;
      use type Identity.Principals.Definitions.Principal_Lifecycle;

      Resolution : constant Identity.Identities.Resolution.Resolution_Result :=
        Identity.Adapters.Repositories.Stores.Resolve (Repository, Subject);
      Credential : Identity.Passwords.Credentials.Password_Credential_Record;
      Account    : Identity.Accounts.Definitions.Account_Record;
      Principal_Record : Identity.Principals.Definitions.Principal_Record;
      Found_Credential : Boolean;
      Found_Account    : Boolean;
      Found_Principal  : Boolean;
      Verify_Result : Identity.Crypto.Password_Hashing.Verification_Result;
   begin
      if Resolution.Status /= Identity.Identities.Resolution.Resolved then
         Perform_Synthetic_Verification (Password);
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      end if;

      Identity.Adapters.Repositories.Stores.Find_Principal
        (Repository, Resolution.Principal, Found_Principal, Principal_Record);
      if not Found_Principal
        or else Principal_Record.State /= Identity.Principals.Definitions.Active
      then
         Perform_Synthetic_Verification (Password);
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      end if;

      Identity.Adapters.Repositories.Stores.Find_Active_Password
        (Repository, Resolution.Principal, Found_Credential, Credential);
      if not Found_Credential
        or else Credential.State /= Identity.Credentials.States.Active
      then
         Perform_Synthetic_Verification (Password);
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      end if;

      Identity.Adapters.Repositories.Stores.Find_Account
        (Repository, Resolution.Principal, Found_Account, Account);
      if not Found_Account then
         return (Status => Identity.Results.Conflict, Principal => (Present => False));
      end if;

      if Identity.Accounts.States.Evaluate (Account.State) = Identity.Accounts.States.Ineligible then
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      elsif Account.State.Lock_State in
        Identity.Accounts.States.Temporarily_Locked
        | Identity.Accounts.States.Indefinitely_Locked
        | Identity.Accounts.States.Unlock_Pending
      then
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      elsif Account.State.Recovery.Restricted_Session
        or else Account.State.Recovery.Required_Credential_Reestablishment
        or else Account.State.Recovery.MFA_Reenrollment
        or else Account.State.Recovery.Limited_Action_Profile
      then
         return (Status => Identity.Results.Recovery_Action_Required, Principal => (Present => False));
      elsif Identity.Accounts.States.Evaluate (Account.State) = Identity.Accounts.States.Restricted then
         return (Status => Identity.Results.Password_Change_Required, Principal => (Present => False));
      end if;

      Verify_Result := Identity.Crypto.Password_Hashing.Verify
        (Password, Identity.Text.Bounded.Image (Credential.Verifier));
      if Verify_Result.Outcome = Identity.Crypto.Password_Hashing.Verified then
         return
           (Status    => Identity.Results.Succeeded,
            Principal => (Present => True, Value => Resolution.Principal));
      else
         return (Status => Identity.Results.Rejected, Principal => (Present => False));
      end if;
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Attempted_Request)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      use type Identity.Results.Operation_Status;
      use type Identity.Versions.Attempt_Count;
      use type Identity.Identities.Resolution.Resolution_Status;
      use type Identity.Attempts.Outcomes.Attempt_Outcome;
      use type Identity.Attempts.Outcomes.Failure_Category;

      Result : constant Identity.Authentication.Results.Password_Authentication_Result :=
        Execute (Repository, Request.Subject, Request.Password);
      Resolution : constant Identity.Identities.Resolution.Resolution_Result :=
        Identity.Adapters.Repositories.Stores.Resolve (Repository, Request.Subject);
      Attempt_Status : Identity.Adapters.Repositories.Stores.Command_Status;
      Attempt_Outcome : Identity.Attempts.Outcomes.Attempt_Outcome :=
        Identity.Attempts.Outcomes.Failed;
      Failure : Identity.Attempts.Outcomes.Failure_Category :=
        Identity.Attempts.Outcomes.Password_Failure;
      Principal : Identity.Attempts.Definitions.Optional_Principal := (Present => False);
      Account_Found : Boolean := False;
      Account : Identity.Accounts.Definitions.Account_Record;
      Lock_Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      if Result.Status = Identity.Results.Succeeded then
         Attempt_Outcome := Identity.Attempts.Outcomes.Succeeded;
         Failure := Identity.Attempts.Outcomes.None;
      elsif Result.Status = Identity.Results.Conflict then
         Attempt_Outcome := Identity.Attempts.Outcomes.Conflict;
         Failure := Identity.Attempts.Outcomes.None;
      elsif Result.Status = Identity.Results.Operational_Failure then
         Attempt_Outcome := Identity.Attempts.Outcomes.Operational_Failure;
         Failure := Identity.Attempts.Outcomes.None;
      end if;

      if Result.Principal.Present then
         Principal := (Present => True, Value => Result.Principal.Value);
      elsif Resolution.Status = Identity.Identities.Resolution.Resolved then
         Principal := (Present => True, Value => Resolution.Principal);
      end if;

      Attempt_Status := Identity.Adapters.Repositories.Stores.Record_Attempt
        (Repository,
         (Id                  => Request.Attempt,
          Correlation         => Request.Correlation,
          Principal           => Principal,
          Subject_Fingerprint => Request.Subject_Fingerprint,
          Method              => Password_Method,
          Started_At          => Request.Started_At,
          Completed_At        => Request.Completed_At,
          Outcome             => Attempt_Outcome,
          Failure             => Failure,
          Disclosure          => Identity.Attempts.Outcomes.Generic_Rejection,
          Version             => 0));

      if Attempt_Status = Identity.Adapters.Repositories.Stores.Applied then
         if Attempt_Outcome = Identity.Attempts.Outcomes.Failed
           and then Failure = Identity.Attempts.Outcomes.Password_Failure
           and then Request.Lockout_Threshold > 0
           and then Principal.Present
           and then Identity.Adapters.Repositories.Stores.Failure_Count
             (Repository, Principal.Value, Identity.Attempts.Outcomes.Password_Failure)
             >= Request.Lockout_Threshold
         then
            Identity.Adapters.Repositories.Stores.Find_Account
              (Repository, Principal.Value, Account_Found, Account);
            if Account_Found then
               Account.State.Lock_State := Identity.Accounts.States.Temporarily_Locked;
               Lock_Status := Identity.Adapters.Repositories.Stores.Update_Account_State
                 (Repository, Account.Id, Principal.Value, Account.State);
               if Lock_Status /= Identity.Adapters.Repositories.Stores.Applied then
                  return
                    (Status => Identity.Results.Operational_Failure,
                     Principal => (Present => False));
               end if;
            end if;
         end if;
         return Result;
      else
         return (Status => Identity.Results.Operational_Failure, Principal => (Present => False));
      end if;
   end Execute;
end Identity.Operations.Passwords.Authenticate;

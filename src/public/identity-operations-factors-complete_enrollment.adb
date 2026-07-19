with Identity.Credentials.States;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;

package body Identity.Operations.Factors.Complete_Enrollment is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_TOTP_Enrollment
        (Repository, Credential);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : TOTP_Completion_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_TOTP_Enrollment
        (Repository,
         (Id              => Request.Id,
          Principal       => Request.Principal,
          Algorithm       => Request.Algorithm,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.TOTP_Secret, Request.Secret),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Created_At,
          Highest_Accepted_Counter => Request.Highest_Accepted_Counter,
          Version         => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_TOTP_Completion_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_TOTP_Enrollment
        (Repository,
         (Id              => Request.Request.Id,
          Principal       => Request.Request.Principal,
          Algorithm       => Request.Request.Algorithm,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.TOTP_Secret, Request.Request.Secret),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Request.Created_At,
          Highest_Accepted_Counter => Request.Request.Highest_Accepted_Counter,
          Version         => 0),
         Request.Expected_Credential_Version);
   end Execute;
end Identity.Operations.Factors.Complete_Enrollment;

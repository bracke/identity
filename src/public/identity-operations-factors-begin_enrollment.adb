with Identity.Credentials.States;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Begin_Enrollment is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_TOTP_Enrollment
        (Repository, Credential);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : TOTP_Begin_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_TOTP_Enrollment
        (Repository,
         (Id              => Request.Id,
          Principal       => Request.Principal,
          Algorithm       => Request.Algorithm,
          Secret_Verifier => Identity.Text.Bounded.From_String (""),
          State           => Identity.Credentials.States.Created,
          Created_At      => Request.Created_At,
          Highest_Accepted_Counter => 0,
          Version         => 0));
   end Execute;
end Identity.Operations.Factors.Begin_Enrollment;

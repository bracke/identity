with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Text.Bounded;

package body Identity.Operations.Passwords.Enroll is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Password   : Identity.Secrets.Passwords.New_Password)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      Envelope : constant String := Identity.Crypto.Password_Hashing.Create_Verifier (Password);
   begin
      return Identity.Adapters.Repositories.Stores.Enroll_Password
        (Repository,
         (Id        => Credential,
          Principal => Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Identity.Text.Bounded.From_String (Envelope),
          Version   => 0));
   end Execute;
end Identity.Operations.Passwords.Enroll;

with Identity.Credentials.States;
with Identity.Identifiers.Entities;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Passwords.Credentials is
   pragma Pure;

   type Password_Credential_Record is record
      Id        : Identity.Identifiers.Entities.Credential_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      State     : Identity.Credentials.States.Credential_State := Identity.Credentials.States.Active;
      Verifier  : Identity.Text.Bounded.Bounded_Text;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;

   type Password_Credential_Projection is record
      Id        : Identity.Identifiers.Entities.Credential_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      State     : Identity.Credentials.States.Credential_State :=
        Identity.Credentials.States.Active;
      Verifier_Present : Boolean := False;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;

   type Password_Credential_Authentication_Status is
     (Password_Credential_Authentication_Admitted,
      Password_Credential_Not_Activated,
      Password_Credential_Replacement_Pending,
      Password_Credential_Migration_Pending,
      Password_Credential_Expired,
      Password_Credential_Locked,
      Password_Credential_Retired,
      Password_Credential_Revoked,
      Password_Credential_Verifier_Missing);

   function Summary
     (Credential : Password_Credential_Record)
      return Password_Credential_Projection is
     ((Id               => Credential.Id,
       Principal        => Credential.Principal,
       State            => Credential.State,
       Verifier_Present =>
         Identity.Text.Bounded.Length (Credential.Verifier) > 0,
       Version          => Credential.Version));

   function Authentication_Admission
     (State            : Identity.Credentials.States.Credential_State;
      Verifier_Present : Boolean)
      return Password_Credential_Authentication_Status is
     (if not Verifier_Present
      then Password_Credential_Verifier_Missing
      else
        (case Identity.Credentials.States.Authentication_Admission (State) is
            when Identity.Credentials.States.Credential_Authentication_Admitted =>
              Password_Credential_Authentication_Admitted,
            when Identity.Credentials.States.Credential_Not_Activated =>
              Password_Credential_Not_Activated,
            when Identity.Credentials.States.Credential_Replacement_Pending =>
              Password_Credential_Replacement_Pending,
            when Identity.Credentials.States.Credential_Migration_Pending =>
              Password_Credential_Migration_Pending,
            when Identity.Credentials.States.Credential_Expired =>
              Password_Credential_Expired,
            when Identity.Credentials.States.Credential_Locked =>
              Password_Credential_Locked,
            when Identity.Credentials.States.Credential_Retired =>
              Password_Credential_Retired,
            when Identity.Credentials.States.Credential_Revoked =>
              Password_Credential_Revoked));

   function Authentication_Admission
     (Credential : Password_Credential_Record)
      return Password_Credential_Authentication_Status is
     (Authentication_Admission
        (Credential.State,
         Identity.Text.Bounded.Length (Credential.Verifier) > 0));

   function Authentication_Admission
     (Credential : Password_Credential_Projection)
      return Password_Credential_Authentication_Status is
     (Authentication_Admission (Credential.State, Credential.Verifier_Present));

   function Authentication_Accepted
     (Status : Password_Credential_Authentication_Status) return Boolean is
     (Status = Password_Credential_Authentication_Admitted);

   function Verifier_Missing_Rejection
     (Status : Password_Credential_Authentication_Status) return Boolean is
     (Status = Password_Credential_Verifier_Missing);

   function Credential_State_Rejection
     (Status : Password_Credential_Authentication_Status) return Boolean is
     (Status in Password_Credential_Not_Activated
              | Password_Credential_Replacement_Pending
              | Password_Credential_Migration_Pending
              | Password_Credential_Expired
              | Password_Credential_Locked
              | Password_Credential_Retired
              | Password_Credential_Revoked);

   function Can_Authenticate
     (Credential : Password_Credential_Record) return Boolean is
     (Authentication_Accepted (Authentication_Admission (Credential)));

   function Can_Authenticate
     (Credential : Password_Credential_Projection) return Boolean is
     (Authentication_Accepted (Authentication_Admission (Credential)));

   function Terminal
     (Credential : Password_Credential_Projection) return Boolean is
     (Credential.State in Identity.Credentials.States.Retired
                      | Identity.Credentials.States.Revoked);
end Identity.Passwords.Credentials;

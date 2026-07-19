with Identity.Credentials.States;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Service_Credentials is
   pragma Pure;

   type Service_Credential_Record is record
      Id          : Identity.Identifiers.Entities.Credential_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Class_Id    : Identity.Identifiers.Registry.Registry_Id;
      Public_Label : Identity.Text.Bounded.Bounded_Text;
      Secret_Verifier : Identity.Text.Bounded.Bounded_Text;
      State       : Identity.Credentials.States.Credential_State :=
        Identity.Credentials.States.Active;
      Version     : Identity.Versions.Entity_Version := 0;
   end record;

   type Service_Credential_Projection is record
      Id          : Identity.Identifiers.Entities.Credential_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Class_Id    : Identity.Identifiers.Registry.Registry_Id;
      Public_Label : Identity.Text.Bounded.Bounded_Text;
      Verifier_Present : Boolean := False;
      State       : Identity.Credentials.States.Credential_State :=
        Identity.Credentials.States.Active;
      Version     : Identity.Versions.Entity_Version := 0;
   end record;

   type Service_Credential_Admission_Status is
     (Service_Credential_Admitted,
      Service_Credential_Not_Activated,
      Service_Credential_Replacement_Pending,
      Service_Credential_Migration_Pending,
      Service_Credential_Expired,
      Service_Credential_Locked,
      Service_Credential_Retired,
      Service_Credential_Revoked,
      Service_Credential_Verifier_Missing);

   function Summary
     (Value : Service_Credential_Record) return Service_Credential_Projection is
     ((Id               => Value.Id,
       Principal        => Value.Principal,
       Class_Id         => Value.Class_Id,
       Public_Label     => Value.Public_Label,
       Verifier_Present =>
         Identity.Text.Bounded.Length (Value.Secret_Verifier) > 0,
       State            => Value.State,
       Version          => Value.Version));

   function Admission
     (State            : Identity.Credentials.States.Credential_State;
      Verifier_Present : Boolean) return Service_Credential_Admission_Status is
     (if not Verifier_Present
      then Service_Credential_Verifier_Missing
      else
        (case Identity.Credentials.States.Authentication_Admission (State) is
            when Identity.Credentials.States.Credential_Authentication_Admitted =>
              Service_Credential_Admitted,
            when Identity.Credentials.States.Credential_Not_Activated =>
              Service_Credential_Not_Activated,
            when Identity.Credentials.States.Credential_Replacement_Pending =>
              Service_Credential_Replacement_Pending,
            when Identity.Credentials.States.Credential_Migration_Pending =>
              Service_Credential_Migration_Pending,
            when Identity.Credentials.States.Credential_Expired =>
              Service_Credential_Expired,
            when Identity.Credentials.States.Credential_Locked =>
              Service_Credential_Locked,
            when Identity.Credentials.States.Credential_Retired =>
              Service_Credential_Retired,
            when Identity.Credentials.States.Credential_Revoked =>
              Service_Credential_Revoked));

   function Admission
     (Value : Service_Credential_Record) return Service_Credential_Admission_Status is
     (Admission
        (Value.State, Identity.Text.Bounded.Length (Value.Secret_Verifier) > 0));

   function Admission
     (Value : Service_Credential_Projection) return Service_Credential_Admission_Status is
     (Admission (Value.State, Value.Verifier_Present));

   function Admission_Accepted
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Admitted);

   function Admission_Rejected
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status /= Service_Credential_Admitted);

   function Verifier_Missing_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Verifier_Missing);

   function Credential_State_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status in Service_Credential_Not_Activated
              | Service_Credential_Replacement_Pending
              | Service_Credential_Migration_Pending
              | Service_Credential_Expired
              | Service_Credential_Locked
              | Service_Credential_Retired
              | Service_Credential_Revoked);

   function Not_Activated_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Not_Activated);

   function Replacement_Pending_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Replacement_Pending);

   function Migration_Pending_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Migration_Pending);

   function Expired_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Expired);

   function Locked_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Locked);

   function Retired_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Retired);

   function Revoked_Rejection
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status = Service_Credential_Revoked);

   function No_Mutation
     (Status : Service_Credential_Admission_Status) return Boolean is
     (Status /= Service_Credential_Admitted);

   function Can_Authenticate (Value : Service_Credential_Record) return Boolean is
     (Admission_Accepted (Admission (Value)));

   function Can_Authenticate
     (Value : Service_Credential_Projection) return Boolean is
     (Admission_Accepted (Admission (Value)));

   function Has_Public_Label
     (Value : Service_Credential_Projection) return Boolean is
     (Identity.Text.Bounded.Length (Value.Public_Label) > 0);

   function Has_Credential_Class
     (Value : Service_Credential_Projection) return Boolean is
     (Identity.Identifiers.Registry.Is_Valid (Value.Class_Id));
end Identity.Service_Credentials;

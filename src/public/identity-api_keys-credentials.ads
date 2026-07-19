with Identity.Credentials.States;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.API_Keys.Credentials is
   pragma Pure;

   type API_Key_Credential_Record is record
      Id              : Identity.Identifiers.Entities.Credential_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Public_Key_Id   : Identity.Text.Bounded.Bounded_Text;
      Credential_Class_Id : Identity.Identifiers.Registry.Registry_Id;
      Secret_Verifier : Identity.Text.Bounded.Bounded_Text;
      State           : Identity.Credentials.States.Credential_State := Identity.Credentials.States.Active;
      Created_At      : Identity.Times.Instant := 0;
      Expires_At      : Identity.Times.Expiration;
      Last_Used_At    : Identity.Times.Expiration;
      Rotation_Generation : Identity.Versions.Rotation_Generation := 0;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   type API_Key_Credential_Projection is record
      Id              : Identity.Identifiers.Entities.Credential_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Public_Key_Id   : Identity.Text.Bounded.Bounded_Text;
      Credential_Class_Id : Identity.Identifiers.Registry.Registry_Id;
      Verifier_Present : Boolean := False;
      State           : Identity.Credentials.States.Credential_State :=
        Identity.Credentials.States.Active;
      Created_At      : Identity.Times.Instant := 0;
      Expires_At      : Identity.Times.Expiration;
      Last_Used_At    : Identity.Times.Expiration;
      Rotation_Generation : Identity.Versions.Rotation_Generation := 0;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   type Authentication_Admission_Status is
     (Authentication_Allowed,
      Credential_Unusable,
      Verifier_Missing,
      Credential_Expired);

   function Summary
     (Credential : API_Key_Credential_Record)
      return API_Key_Credential_Projection is
     ((Id                  => Credential.Id,
       Principal           => Credential.Principal,
       Public_Key_Id       => Credential.Public_Key_Id,
       Credential_Class_Id => Credential.Credential_Class_Id,
       Verifier_Present    =>
         Identity.Text.Bounded.Length (Credential.Secret_Verifier) > 0,
       State               => Credential.State,
       Created_At          => Credential.Created_At,
       Expires_At          => Credential.Expires_At,
       Last_Used_At        => Credential.Last_Used_At,
       Rotation_Generation => Credential.Rotation_Generation,
       Version             => Credential.Version));

   function Authentication_Admission
     (Credential : API_Key_Credential_Record;
      Now        : Identity.Times.Instant) return Authentication_Admission_Status is
     (if not Identity.Credentials.States.Can_Authenticate (Credential.State) then
         Credential_Unusable
      elsif Identity.Text.Bounded.Length (Credential.Secret_Verifier) = 0 then
         Verifier_Missing
      elsif Identity.Times.Expired (Now, Credential.Expires_At) then
         Credential_Expired
      else
         Authentication_Allowed);

   function Authentication_Admission
     (Credential : API_Key_Credential_Projection;
      Now        : Identity.Times.Instant) return Authentication_Admission_Status is
     (if not Identity.Credentials.States.Can_Authenticate (Credential.State) then
         Credential_Unusable
      elsif not Credential.Verifier_Present then
         Verifier_Missing
      elsif Identity.Times.Expired (Now, Credential.Expires_At) then
         Credential_Expired
      else
         Authentication_Allowed);

   function Admission_Accepted
     (Status : Authentication_Admission_Status) return Boolean is
     (Status = Authentication_Allowed);

   function Admission_Rejected
     (Status : Authentication_Admission_Status) return Boolean is
     (Status /= Authentication_Allowed);

   function State_Rejected
     (Status : Authentication_Admission_Status) return Boolean is
     (Status = Credential_Unusable);

   function Verifier_Rejected
     (Status : Authentication_Admission_Status) return Boolean is
     (Status = Verifier_Missing);

   function Expiration_Rejected
     (Status : Authentication_Admission_Status) return Boolean is
     (Status = Credential_Expired);

   function No_Mutation
     (Status : Authentication_Admission_Status) return Boolean is
     (Status /= Authentication_Allowed);

   function Can_Authenticate
     (Credential : API_Key_Credential_Record;
      Now        : Identity.Times.Instant) return Boolean is
     (Admission_Accepted (Authentication_Admission (Credential, Now)));

   function Can_Authenticate
     (Credential : API_Key_Credential_Projection;
      Now        : Identity.Times.Instant) return Boolean is
     (Admission_Accepted (Authentication_Admission (Credential, Now)));

   function Has_Verifier
     (Credential : API_Key_Credential_Projection) return Boolean is
     (Credential.Verifier_Present);

   function Same_Public_Key_Id
     (Left, Right : API_Key_Credential_Record) return Boolean is
     (Identity.Text.Bounded.Equal (Left.Public_Key_Id, Right.Public_Key_Id));

   function Same_Public_Key_Id
     (Left, Right : API_Key_Credential_Projection) return Boolean is
     (Identity.Text.Bounded.Equal (Left.Public_Key_Id, Right.Public_Key_Id));

   function Matches_Public_Key_Id
     (Credential    : API_Key_Credential_Record;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text) return Boolean is
     (Identity.Text.Bounded.Equal (Credential.Public_Key_Id, Public_Key_Id));

   function Matches_Public_Key_Id
     (Credential    : API_Key_Credential_Projection;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text) return Boolean is
     (Identity.Text.Bounded.Equal (Credential.Public_Key_Id, Public_Key_Id));

   function Has_Credential_Class
     (Credential : API_Key_Credential_Record) return Boolean is
     (Identity.Identifiers.Registry.Is_Valid (Credential.Credential_Class_Id));

   function Has_Credential_Class
     (Credential : API_Key_Credential_Projection) return Boolean is
     (Identity.Identifiers.Registry.Is_Valid (Credential.Credential_Class_Id));
end Identity.API_Keys.Credentials;

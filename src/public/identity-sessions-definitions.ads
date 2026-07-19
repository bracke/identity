with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Sessions.Definitions is
   pragma Pure;

   type Session_Revocation_State is (Active, Rotated, Revoked, Expired);

   type Session_State_Use is
     (Continuity_Lookup, Rejection_Lookup, Session_Revocation,
      Session_Expiration, Session_Retention);

   type Session_State_Admission_Status is
     (Session_State_Admitted, Active_Required, Unusable_Required,
      Revocable_Required, Retained_State_Required);

   function Admission
     (State         : Session_Revocation_State;
      Session_Use   : Session_State_Use)
      return Session_State_Admission_Status is
     (case Session_Use is
         when Continuity_Lookup =>
           (if State = Active
            then Session_State_Admitted
            else Active_Required),
         when Rejection_Lookup =>
           (if State in Rotated | Revoked | Expired
            then Session_State_Admitted
            else Unusable_Required),
         when Session_Revocation =>
           (if State not in Revoked | Expired
            then Session_State_Admitted
            else Revocable_Required),
         when Session_Expiration =>
           (if State = Active
            then Session_State_Admitted
            else Active_Required),
         when Session_Retention =>
           (if State /= Active
            then Session_State_Admitted
            else Retained_State_Required));

   function Admission_Accepted
     (State       : Session_Revocation_State;
      Session_Use : Session_State_Use) return Boolean is
     (Admission (State, Session_Use) = Session_State_Admitted);

   function Admission_Accepted
     (Status : Session_State_Admission_Status) return Boolean is
     (Status = Session_State_Admitted);

   function Admission_Rejected
     (Status : Session_State_Admission_Status) return Boolean is
     (Status /= Session_State_Admitted);

   function Active_Required_Rejection
     (Status : Session_State_Admission_Status) return Boolean is
     (Status = Active_Required);

   function Unusable_Required_Rejection
     (Status : Session_State_Admission_Status) return Boolean is
     (Status = Unusable_Required);

   function Revocable_Required_Rejection
     (Status : Session_State_Admission_Status) return Boolean is
     (Status = Revocable_Required);

   function Retained_State_Required_Rejection
     (Status : Session_State_Admission_Status) return Boolean is
     (Status = Retained_State_Required);

   function No_Mutation
     (Status : Session_State_Admission_Status) return Boolean is
     (Status /= Session_State_Admitted);

   function Is_Active (State : Session_Revocation_State) return Boolean is
     (Admission_Accepted (State, Continuity_Lookup));

   function Is_Unusable (State : Session_Revocation_State) return Boolean is
     (Admission_Accepted (State, Rejection_Lookup));

   function Lookup_Reports_Revoked (State : Session_Revocation_State) return Boolean is
     (State in Rotated | Revoked);

   function Lookup_Reports_Expired (State : Session_Revocation_State) return Boolean is
     (State = Expired);

   function Can_Revoke (State : Session_Revocation_State) return Boolean is
     (Admission_Accepted (State, Session_Revocation));

   function Can_Expire (State : Session_Revocation_State) return Boolean is
     (Admission_Accepted (State, Session_Expiration));

   function Retainable (State : Session_Revocation_State) return Boolean is
     (Admission_Accepted (State, Session_Retention));

   type Optional_Credential_Id (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Credential_Id;
         when False =>
            null;
      end case;
   end record;

   type Optional_External_Provider_Id (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.External_Provider_Id;
         when False =>
            null;
      end case;
   end record;

   type Optional_Instant (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Times.Instant;
         when False =>
            null;
      end case;
   end record;

   type Session_Record is record
      Id              : Identity.Identifiers.Entities.Session_Id;
      Family          : Identity.Identifiers.Entities.Session_Family_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Credential      : Optional_Credential_Id := (Present => False);
      External_Provider : Optional_External_Provider_Id := (Present => False);
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret_Verifier : Identity.Text.Bounded.Bounded_Text;
      Assurance       : Identity.Assurance.Levels.Assurance_Level := Identity.Assurance.Levels.Basic;
      Attributes      : Identity.Assurance.Attributes.Assurance_Attributes;
      Created_At      : Identity.Times.Instant := 0;
      Original_Authenticated_At : Identity.Times.Instant := 0;
      Primary_Authenticated_At  : Identity.Times.Instant := 0;
      MFA_Completed_At          : Optional_Instant := (Present => False);
      Step_Up_At                : Optional_Instant := (Present => False);
      Last_Seen_At    : Identity.Times.Instant := 0;
      Idle_Expires_At : Identity.Times.Expiration;
      Absolute_Expires_At : Identity.Times.Expiration;
      Remembered      : Boolean := False;
      Generation      : Identity.Versions.Rotation_Generation := 0;
      State           : Session_Revocation_State := Active;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   function Same_Public_Reference
     (Left, Right : Session_Record) return Boolean is
     (Identity.Text.Bounded.Equal (Left.Public_Reference, Right.Public_Reference));
end Identity.Sessions.Definitions;

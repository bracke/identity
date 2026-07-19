with Identity.Credentials.States;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.One_Time_Passwords.Credentials is
   pragma Pure;

   type TOTP_Counter is range 0 .. 2**63 - 1;
   type TOTP_Accept_Status is
     (Accepted,
      Not_Verified,
      Replayed,
      Unknown,
      Credential_Unusable,
      Counter_Too_Old,
      State_Conflict);

   type TOTP_Credential_Record is record
      Id              : Identity.Identifiers.Entities.Credential_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Algorithm       : Identity.Identifiers.Registry.Registry_Id;
      Secret_Verifier : Identity.Text.Bounded.Bounded_Text;
      State           : Identity.Credentials.States.Credential_State := Identity.Credentials.States.Active;
      Created_At      : Identity.Times.Instant := 0;
      Highest_Accepted_Counter : TOTP_Counter := 0;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   type TOTP_Credential_Projection is record
      Id              : Identity.Identifiers.Entities.Credential_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Algorithm       : Identity.Identifiers.Registry.Registry_Id;
      State           : Identity.Credentials.States.Credential_State := Identity.Credentials.States.Created;
      Verifier_Present : Boolean := False;
      Highest_Accepted_Counter : TOTP_Counter := 0;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   function Summary
     (Credential : TOTP_Credential_Record) return TOTP_Credential_Projection is
     ((Id => Credential.Id,
       Principal => Credential.Principal,
       Algorithm => Credential.Algorithm,
       State => Credential.State,
       Verifier_Present =>
         not Identity.Text.Bounded.Equal
           (Credential.Secret_Verifier, Identity.Text.Bounded.From_String ("")),
       Highest_Accepted_Counter => Credential.Highest_Accepted_Counter,
       Version => Credential.Version));

   function Admit_Counter
     (Credential : TOTP_Credential_Record;
      Counter    : TOTP_Counter) return TOTP_Accept_Status is
     (if not Identity.Credentials.States.Can_Authenticate (Credential.State) then Credential_Unusable
      elsif Counter <= Credential.Highest_Accepted_Counter then Replayed
      else Accepted);

   function Evaluate_Presentation
     (Found      : Boolean;
      Verified   : Boolean;
      Credential : TOTP_Credential_Record;
      Counter    : TOTP_Counter) return TOTP_Accept_Status is
     (if not Found then
         Unknown
      elsif not Verified then
         Not_Verified
      else
         Admit_Counter (Credential, Counter));

   function Credential_Usable
     (Credential : TOTP_Credential_Record) return Boolean is
     (Identity.Credentials.States.Can_Authenticate (Credential.State));

   function Credential_Usable
     (Credential : TOTP_Credential_Projection) return Boolean is
     (Identity.Credentials.States.Can_Authenticate (Credential.State)
      and then Credential.Verifier_Present);

   function Terminal
     (Credential : TOTP_Credential_Projection) return Boolean is
     (Credential.State in Identity.Credentials.States.Retired | Identity.Credentials.States.Revoked);

   function Counter_Accepted
     (Status : TOTP_Accept_Status) return Boolean is
     (Status = Accepted);

   function Replay_Rejected
     (Status : TOTP_Accept_Status) return Boolean is
     (Status in Replayed | Counter_Too_Old);

   function Retryable_By_Presentation
     (Status : TOTP_Accept_Status) return Boolean is
     (Status in Not_Verified | Replayed | Counter_Too_Old);

   function Verification_Rejected
     (Status : TOTP_Accept_Status) return Boolean is
     (Status = Not_Verified);

   function Unknown_Credential
     (Status : TOTP_Accept_Status) return Boolean is
     (Status = Unknown);

   function Unusable_Credential
     (Status : TOTP_Accept_Status) return Boolean is
     (Status = Credential_Unusable);

   function Conflict
     (Status : TOTP_Accept_Status) return Boolean is
     (Status = State_Conflict);

   function No_Replay_State_Mutation
     (Status : TOTP_Accept_Status) return Boolean is
     (Status in Not_Verified | Replayed | Unknown | Credential_Unusable
              | Counter_Too_Old | State_Conflict);
end Identity.One_Time_Passwords.Credentials;

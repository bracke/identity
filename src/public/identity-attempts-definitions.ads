with Identity.Attempts.Outcomes;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Attempts.Definitions is
   pragma Pure;
   use type Identity.Times.Instant;

   type Optional_Principal (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Principal_Id;
         when False =>
            null;
      end case;
   end record;

   type Attempt_Record is record
      Id                  : Identity.Identifiers.Entities.Attempt_Id;
      Correlation         : Identity.Identifiers.Operations.Correlation_Id;
      Principal           : Optional_Principal;
      Subject_Fingerprint : Identity.Text.Bounded.Bounded_Text;
      Method              : Identity.Identifiers.Registry.Registry_Id;
      Started_At          : Identity.Times.Instant := 0;
      Completed_At        : Identity.Times.Instant := 0;
      Outcome             : Identity.Attempts.Outcomes.Attempt_Outcome :=
        Identity.Attempts.Outcomes.Failed;
      Failure             : Identity.Attempts.Outcomes.Failure_Category :=
        Identity.Attempts.Outcomes.None;
      Disclosure          : Identity.Attempts.Outcomes.Disclosure_Category :=
        Identity.Attempts.Outcomes.Generic_Rejection;
      Version             : Identity.Versions.Entity_Version := 0;
   end record;

   function Has_Resolved_Principal
     (Attempt : Attempt_Record) return Boolean is
     (Attempt.Principal.Present);

   function Completed
     (Attempt : Attempt_Record) return Boolean is
     (Attempt.Completed_At >= Attempt.Started_At);

   function Counts_As_Credential_Failure
     (Attempt : Attempt_Record) return Boolean is
     (Identity.Attempts.Outcomes.Counts_As_Credential_Failure
        (Attempt.Outcome, Attempt.Failure));

   function Disclosure_Is_Generic
     (Attempt : Attempt_Record) return Boolean is
     (Identity.Attempts.Outcomes.Generic_Public_Rejection (Attempt.Disclosure));
end Identity.Attempts.Definitions;

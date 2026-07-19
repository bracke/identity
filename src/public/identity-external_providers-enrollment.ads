with Identity.Identifiers.Entities;
with Identity.Times;

package Identity.External_Providers.Enrollment is
   pragma Pure;

   type Enrollment_Decision is
     (Require_Existing_Binding,
      Allow_Explicit_Binding,
      Allow_Policy_Controlled_JIT,
      Reject_Ambiguous,
      Reject_Untrusted);

   function Existing_Binding_Required
     (Decision : Enrollment_Decision) return Boolean is
     (Decision = Require_Existing_Binding);

   function Explicit_Binding_Allowed
     (Decision : Enrollment_Decision) return Boolean is
     (Decision = Allow_Explicit_Binding);

   function Policy_Controlled_JIT_Allowed
     (Decision : Enrollment_Decision) return Boolean is
     (Decision = Allow_Policy_Controlled_JIT);

   function Enrollment_Allowed
     (Decision : Enrollment_Decision) return Boolean is
     (Decision in Allow_Explicit_Binding | Allow_Policy_Controlled_JIT);

   function Enrollment_Rejected
     (Decision : Enrollment_Decision) return Boolean is
     (Decision in Reject_Ambiguous | Reject_Untrusted);

   function Ambiguity_Rejected
     (Decision : Enrollment_Decision) return Boolean is
     (Decision = Reject_Ambiguous);

   function Provider_Rejected
     (Decision : Enrollment_Decision) return Boolean is
     (Decision = Reject_Untrusted);

   type Enrollment_Result is record
      Decision      : Enrollment_Decision := Require_Existing_Binding;
      Principal     : Identity.Identifiers.Entities.Principal_Id;
      Provider      : Identity.Identifiers.Entities.External_Provider_Id;
      Decided_At    : Identity.Times.Instant := 0;
   end record;
end Identity.External_Providers.Enrollment;

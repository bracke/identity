with Identity.External_Providers.Definitions;
with Identity.External_Providers.Policies;

package Identity.External_Providers.Trust is
   pragma Pure;

   type Provider_Trust_Status is (Trusted, Untrusted, Suspended);

   type Provider_Admission_Decision is
     (Admit_Explicit_Binding,
      Require_Explicit_Binding,
      Allow_Policy_Controlled_JIT,
      Require_Local_Approval,
      Reject_Untrusted_Provider,
      Reject_Suspended_Provider,
      Reject_Retired_Provider,
      Reject_Replay_Not_Registered,
      Reject_Email_Auto_Link,
      Reject_Invalid_Policy);

   function Status_For
     (Definition : Identity.External_Providers.Definitions.External_Provider_Definition)
      return Provider_Trust_Status is
     (case Definition.State is
         when Identity.External_Providers.Definitions.Active => Trusted,
         when Identity.External_Providers.Definitions.Suspended => Suspended,
         when Identity.External_Providers.Definitions.Retired => Untrusted);

   function Trusted_Status (Status : Provider_Trust_Status) return Boolean is
     (Status = Trusted);
   function Untrusted_Status (Status : Provider_Trust_Status) return Boolean is
     (Status = Untrusted);
   function Suspended_Status (Status : Provider_Trust_Status) return Boolean is
     (Status = Suspended);
   function Provider_Rejected (Status : Provider_Trust_Status) return Boolean is
     (Status in Untrusted | Suspended);

   function Evaluate_Admission
     (Definition         : Identity.External_Providers.Definitions.External_Provider_Definition;
      Policy             : Identity.External_Providers.Policies.External_Provider_Policy;
      Has_Active_Binding : Boolean;
      Replay_Registered : Boolean;
      Email_Match_Only   : Boolean := False)
      return Provider_Admission_Decision;

   function Admitted (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Admit_Explicit_Binding);

   function Binding_Required
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Require_Explicit_Binding);

   function JIT_Provisioning_Allowed
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Allow_Policy_Controlled_JIT);

   function Local_Approval_Required
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Require_Local_Approval);

   function Rejected (Decision : Provider_Admission_Decision) return Boolean is
     (Decision in Reject_Untrusted_Provider
              | Reject_Suspended_Provider
              | Reject_Retired_Provider
              | Reject_Replay_Not_Registered
              | Reject_Email_Auto_Link
              | Reject_Invalid_Policy);

   function Provider_State_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision in Reject_Untrusted_Provider
              | Reject_Suspended_Provider
              | Reject_Retired_Provider);
   function Untrusted_Provider_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Reject_Untrusted_Provider);
   function Suspended_Provider_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Reject_Suspended_Provider);
   function Retired_Provider_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Reject_Retired_Provider);
   function Replay_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Reject_Replay_Not_Registered);
   function Email_Auto_Link_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Reject_Email_Auto_Link);
   function Policy_Rejected
     (Decision : Provider_Admission_Decision) return Boolean is
     (Decision = Reject_Invalid_Policy);
end Identity.External_Providers.Trust;

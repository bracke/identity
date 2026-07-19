with Identity.Identifiers.Entities;
with Identity.Identifiers.Policies;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.External_Providers.Definitions is
   pragma Pure;

   type Provider_State is (Active, Suspended, Retired);
   type JIT_Provisioning_Mode is (Disabled, Explicit_Allow, Require_Local_Approval);

   type Provider_State_Admission_Status is
     (Provider_State_Admitted,
      Provider_State_Suspended,
      Provider_State_Retired);

   type External_Provider_Definition is record
      Provider        : Identity.Identifiers.Entities.External_Provider_Id;
      Protocol        : Identity.Identifiers.Registry.Registry_Id;
      Issuer          : Identity.Text.Bounded.Bounded_Text;
      Display_Name    : Identity.Text.Bounded.Bounded_Text;
      State           : Provider_State := Active;
      JIT_Mode        : JIT_Provisioning_Mode := Disabled;
      Policy_Version  : Identity.Identifiers.Policies.Policy_Version := 1;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   function Is_Active (State : Provider_State) return Boolean is
     (State = Active);

   function Admission
     (State : Provider_State) return Provider_State_Admission_Status is
     (case State is
        when Active => Provider_State_Admitted,
        when Suspended => Provider_State_Suspended,
        when Retired => Provider_State_Retired);

   function Admission_Accepted
     (Status : Provider_State_Admission_Status) return Boolean is
     (Status = Provider_State_Admitted);

   function Admission_Rejected
     (Status : Provider_State_Admission_Status) return Boolean is
     (Status /= Provider_State_Admitted);

   function Suspended_Rejection
     (Status : Provider_State_Admission_Status) return Boolean is
     (Status = Provider_State_Suspended);

   function Retired_Rejection
     (Status : Provider_State_Admission_Status) return Boolean is
     (Status = Provider_State_Retired);

   function Can_Authenticate (State : Provider_State) return Boolean is
     (Admission_Accepted (Admission (State)));

   function JIT_Allowed (Mode : JIT_Provisioning_Mode) return Boolean is
     (Mode = Explicit_Allow);

   function Local_Approval_Required
     (Mode : JIT_Provisioning_Mode) return Boolean is
     (Mode = Require_Local_Approval);

   function Can_Use_Policy_Controlled_JIT
     (Definition : External_Provider_Definition) return Boolean is
     (Can_Authenticate (Definition.State)
      and then JIT_Allowed (Definition.JIT_Mode));
end Identity.External_Providers.Definitions;

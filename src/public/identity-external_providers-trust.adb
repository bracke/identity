package body Identity.External_Providers.Trust is

   function Evaluate_Admission
     (Definition         : Identity.External_Providers.Definitions.External_Provider_Definition;
      Policy             : Identity.External_Providers.Policies.External_Provider_Policy;
      Has_Active_Binding : Boolean;
      Replay_Registered : Boolean;
      Email_Match_Only   : Boolean := False)
      return Provider_Admission_Decision
   is
      use type Identity.External_Providers.Definitions.Provider_State;
   begin
      if not Identity.External_Providers.Policies.Valid (Policy) then
         return Reject_Invalid_Policy;
      end if;

      if Policy.Require_Trusted_Provider then
         if Definition.State = Identity.External_Providers.Definitions.Suspended then
            return Reject_Suspended_Provider;
         elsif Definition.State = Identity.External_Providers.Definitions.Retired then
            return Reject_Retired_Provider;
         end if;
      elsif not Identity.External_Providers.Definitions.Can_Authenticate
        (Definition.State)
      then
         return Reject_Untrusted_Provider;
      end if;

      if Policy.Replay_Registration_Required and then not Replay_Registered then
         return Reject_Replay_Not_Registered;
      end if;

      if Email_Match_Only and then not Policy.Email_Auto_Link_Allowed then
         return Reject_Email_Auto_Link;
      end if;

      if Has_Active_Binding then
         return Admit_Explicit_Binding;
      end if;

      if Identity.External_Providers.Definitions.Can_Use_Policy_Controlled_JIT
        (Definition)
        and then Policy.Explicit_JIT_Required
      then
         return Allow_Policy_Controlled_JIT;
      elsif Identity.External_Providers.Definitions.Local_Approval_Required
        (Definition.JIT_Mode)
      then
         return Require_Local_Approval;
      else
         return Require_Explicit_Binding;
      end if;
   end Evaluate_Admission;

end Identity.External_Providers.Trust;

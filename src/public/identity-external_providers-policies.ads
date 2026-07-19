package Identity.External_Providers.Policies is
   pragma Pure;

   type External_Provider_Policy is record
      Require_Trusted_Provider      : Boolean := True;
      Replay_Registration_Required : Boolean := True;
      Email_Auto_Link_Allowed      : Boolean := False;
      Explicit_JIT_Required        : Boolean := True;
   end record;

   type External_Provider_Policy_Validation_Status is
     (External_Provider_Policy_Valid,
      Trusted_Provider_Not_Required,
      Replay_Registration_Not_Required,
      Email_Auto_Link_Allowed_By_Policy,
      Explicit_JIT_Not_Required);

   function Validate
     (Value : External_Provider_Policy)
      return External_Provider_Policy_Validation_Status is
     (if not Value.Require_Trusted_Provider then
         Trusted_Provider_Not_Required
      elsif not Value.Replay_Registration_Required then
         Replay_Registration_Not_Required
      elsif Value.Email_Auto_Link_Allowed then
         Email_Auto_Link_Allowed_By_Policy
      elsif not Value.Explicit_JIT_Required then
         Explicit_JIT_Not_Required
      else
         External_Provider_Policy_Valid);

   function Validation_Accepted
     (Status : External_Provider_Policy_Validation_Status) return Boolean is
     (Status = External_Provider_Policy_Valid);

   function Trust_Rejected
     (Status : External_Provider_Policy_Validation_Status) return Boolean is
     (Status = Trusted_Provider_Not_Required);

   function Replay_Rejected
     (Status : External_Provider_Policy_Validation_Status) return Boolean is
     (Status = Replay_Registration_Not_Required);

   function Email_Link_Rejected
     (Status : External_Provider_Policy_Validation_Status) return Boolean is
     (Status = Email_Auto_Link_Allowed_By_Policy);

   function JIT_Rejected
     (Status : External_Provider_Policy_Validation_Status) return Boolean is
     (Status = Explicit_JIT_Not_Required);

   function Valid (Value : External_Provider_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.External_Providers.Policies;

with Identity.Accounts.States;

package Identity.Accounts.Requirements is
   pragma Pure;

   subtype Credential_Requirement_Flags is Identity.Accounts.States.Credential_Requirement_Flags;

   function Any (Value : Credential_Requirement_Flags) return Boolean is
     (Value.Password_Change_Required
      or else Value.MFA_Enrollment_Required
      or else Value.Credential_Reestablishment_Required
      or else Value.Recent_Authentication_Required);
end Identity.Accounts.Requirements;

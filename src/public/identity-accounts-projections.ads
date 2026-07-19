with Identity.Identifiers.Entities;
with Identity.Accounts.States;
with Identity.Accounts.Definitions;
with Identity.Accounts.Evaluation;
with Identity.Versions;

package Identity.Accounts.Projections is
   pragma Pure;
   use type Identity.Accounts.States.Eligibility;
   use type Identity.Accounts.States.Administrative_State;
   use type Identity.Accounts.States.Security_Lock_State;

   type Account_Projection is record
      Id        : Identity.Identifiers.Entities.Account_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      State     : Identity.Accounts.States.Account_State_View;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;

   function Summary
     (Account : Identity.Accounts.Definitions.Account_Record)
      return Account_Projection is
     ((Id => Account.Id,
       Principal => Account.Principal,
       State => Account.State,
       Version => Account.Version));

   function Evaluate
     (Account : Account_Projection)
      return Identity.Accounts.States.Eligibility is
     (Identity.Accounts.Evaluation.Evaluate (Account.State));

   function Eligible
     (Account : Account_Projection) return Boolean is
     (Evaluate (Account) = Identity.Accounts.States.Eligible);

   function Ineligible
     (Account : Account_Projection) return Boolean is
     (Evaluate (Account) = Identity.Accounts.States.Ineligible);

   function Administratively_Restricted
     (Account : Account_Projection) return Boolean is
     (Account.State.Administrative /= Identity.Accounts.States.Enabled);

   function Requires_Credential_Action
     (Account : Account_Projection) return Boolean is
     (Account.State.Requirements.Password_Change_Required
      or else Account.State.Requirements.MFA_Enrollment_Required
      or else Account.State.Requirements.Credential_Reestablishment_Required
      or else Account.State.Requirements.Recent_Authentication_Required);

   function Recovery_Restricted
     (Account : Account_Projection) return Boolean is
     (Account.State.Recovery.Restricted_Session
      or else Account.State.Recovery.Required_Credential_Reestablishment
      or else Account.State.Recovery.MFA_Reenrollment
      or else Account.State.Recovery.No_Remember_Me
      or else Account.State.Recovery.Limited_Lifetime
      or else Account.State.Recovery.Limited_Action_Profile);

   function Lock_Restricted
     (Account : Account_Projection) return Boolean is
     (Account.State.Lock_State /= Identity.Accounts.States.Not_Locked);
end Identity.Accounts.Projections;

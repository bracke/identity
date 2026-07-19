package Identity.Accounts.States is
   pragma Pure;

   type Administrative_State is (Enabled, Disabled, Suspended, Closed);
   type Lifecycle_State is (Pending_Activation, Active, Expired, Retired);
   type Verification_State is
     (No_Verification_Required, Verification_Pending, Verified, Reverification_Required);
   type Security_Lock_State is (Not_Locked, Temporarily_Locked, Indefinitely_Locked, Unlock_Pending);

   type Credential_Requirement_Flags is record
      Password_Change_Required             : Boolean := False;
      MFA_Enrollment_Required              : Boolean := False;
      Credential_Reestablishment_Required  : Boolean := False;
      Recent_Authentication_Required       : Boolean := False;
   end record;

   type Recovery_Restriction_Flags is record
      Restricted_Session                   : Boolean := False;
      Required_Credential_Reestablishment  : Boolean := False;
      MFA_Reenrollment                     : Boolean := False;
      No_Remember_Me                       : Boolean := False;
      Limited_Lifetime                     : Boolean := False;
      Limited_Action_Profile               : Boolean := False;
   end record;

   type Account_State_View is record
      Administrative : Administrative_State := Enabled;
      Lifecycle      : Lifecycle_State := Active;
      Verification   : Verification_State := No_Verification_Required;
      Lock_State     : Security_Lock_State := Not_Locked;
      Requirements   : Credential_Requirement_Flags;
      Recovery       : Recovery_Restriction_Flags;
   end record;

   type Eligibility is (Eligible, Restricted, Ineligible);

   function Eligible_State (Value : Eligibility) return Boolean is
     (Value = Eligible);

   function Restricted_State (Value : Eligibility) return Boolean is
     (Value = Restricted);

   function Ineligible_State (Value : Eligibility) return Boolean is
     (Value = Ineligible);

   function Authentication_Blocked (Value : Eligibility) return Boolean is
     (Value = Ineligible);

   type Account_State_Transition is
     (Enable_Administrative,
      Disable_Administrative,
      Suspend_Administrative,
      Close_Administrative,
      Unlock_Security,
      Require_Password_Change,
      Require_MFA_Enrollment);

   function Evaluate (State : Account_State_View) return Eligibility;

   function Can_Apply
     (State      : Account_State_View;
      Transition : Account_State_Transition) return Boolean;

   function Apply
     (State      : Account_State_View;
      Transition : Account_State_Transition) return Account_State_View;
end Identity.Accounts.States;

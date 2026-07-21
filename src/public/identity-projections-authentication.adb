package body Identity.Projections.Authentication is
   package SC renames Identity.Authentication.Security_Contexts;
   package AS renames Identity.Accounts.States;

   --  Map the account's requirement and recovery flags into the structured
   --  restrictions the downstream context carries. A Restricted eligibility
   --  (anything short of fully Eligible that still permits authentication) also
   --  raises the recovery-restricted flag.
   function Restrictions_Of
     (State       : AS.Account_State_View;
      Eligibility : AS.Eligibility) return SC.Action_Restrictions is
   begin
      return
        (Recovery_Restricted =>
           AS.Restricted_State (Eligibility)
           or else State.Recovery.Restricted_Session
           or else State.Recovery.Limited_Lifetime
           or else State.Recovery.Limited_Action_Profile,
         No_Remember_Me      => State.Recovery.No_Remember_Me,
         Restricted_Session  => State.Recovery.Restricted_Session,
         Password_Change_Required =>
           State.Requirements.Password_Change_Required,
         MFA_Enrollment_Required =>
           State.Requirements.MFA_Enrollment_Required
           or else State.Recovery.MFA_Reenrollment,
         Credential_Reestablishment_Required =>
           State.Requirements.Credential_Reestablishment_Required
           or else State.Recovery.Required_Credential_Reestablishment,
         Recent_Authentication_Required =>
           State.Requirements.Recent_Authentication_Required);
   end Restrictions_Of;

   function To_Security_Context
     (Principal                 : Identity.Identifiers.Entities.Principal_Id;
      Kind                      : Identity.Principals.Kinds.Principal_Kind;
      Assurance                 : Identity.Assurance.Levels.Assurance_Level;
      Attributes                : Identity.Assurance.Attributes.Assurance_Attributes;
      Account_State             : Identity.Accounts.States.Account_State_View;
      Account_Version           : Identity.Versions.Entity_Version;
      Original_Authenticated_At : Identity.Times.Instant;
      Primary_Authenticated_At  : Identity.Times.Instant;
      Evidence_Version          : Identity.Versions.Entity_Version := 0;
      Methods                   :
        Identity.Authentication.Security_Contexts.Authentication_Method_Set :=
          (Count => 0, Items => <>);
      Provider                  :
        Identity.Authentication.Security_Contexts.Optional_External_Provider :=
          (Present => False);
      Event_Refs                :
        Identity.Authentication.Security_Contexts.Authentication_Event_Refs :=
          (Count => 0, Items => <>);
      MFA_Completed_At          :
        Identity.Authentication.Security_Contexts.Optional_Instant :=
          (Present => False);
      Step_Up_At                :
        Identity.Authentication.Security_Contexts.Optional_Instant :=
          (Present => False);
      Session                   : Optional_Session_Facts := (Present => False))
      return Identity.Authentication.Security_Contexts.Security_Context
   is
      Eligibility : constant AS.Eligibility := AS.Evaluate (Account_State);
      Session_Ref : constant SC.Optional_Session_Id :=
        (if Session.Present
         then (Present => True, Value => Session.Id)
         else (Present => False));
      Session_Version : constant Identity.Versions.Entity_Version :=
        (if Session.Present then Session.Version else 0);
      Validity : constant SC.Optional_Instant :=
        (if Session.Present then Session.Absolute_Expires_At
         else (Present => False));
   begin
      return SC.Authenticated_Context
        (Principal                 => Principal,
         Kind                      => Kind,
         Assurance                 => Assurance,
         Attributes                => Attributes,
         Original_Authenticated_At => Original_Authenticated_At,
         Primary_Authenticated_At  => Primary_Authenticated_At,
         Revisions                 =>
           SC.Revisions_From
             (Account_Version  => Account_Version,
              Evidence_Version => Evidence_Version,
              Session_Version  => Session_Version,
              Session_Present  => Session.Present),
         Methods                   => Methods,
         Provider                  => Provider,
         Event_Refs                => Event_Refs,
         MFA_Completed_At          => MFA_Completed_At,
         Step_Up_At                => Step_Up_At,
         Session                   => Session_Ref,
         Validity_Boundary         => Validity,
         Restrictions              => Restrictions_Of (Account_State, Eligibility),
         --  Coarse eligibility: authentication is not blocked outright. A
         --  Restricted account is still authenticated, but with restrictions.
         Eligible                  =>
           not AS.Authentication_Blocked (Eligibility));
   end To_Security_Context;
end Identity.Projections.Authentication;

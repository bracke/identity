with Identity.Text.Bounded;

package Identity.Policies.Findings is
   pragma Pure;

   Max_Findings : constant Natural := 24;

   type Finding_Severity is (None, Warning, Error);
   type Finding_Code is
     (No_Finding,
      Password_Length_Above_Hard_Limit,
      Password_History_Above_Hard_Limit,
      TOTP_Skew_Above_Hard_Limit,
      Session_Retention_Above_Hard_Limit,
      Event_Attribute_Above_Hard_Limit,
      Resource_Budget_Above_Hard_Limit,
      Invalid_Password_Acceptance_Policy,
      Invalid_Password_Hashing_Policy,
      Invalid_Password_History_Policy,
      Invalid_Password_Reset_Policy,
      Invalid_Attempt_Policy,
      Invalid_Throttling_Policy,
      Invalid_Lockout_Policy,
      Invalid_MFA_Policy,
      Invalid_TOTP_Policy,
      Invalid_Session_Policy,
      Invalid_Token_Policy,
      Invalid_Verification_Policy,
      Invalid_Recovery_Policy,
      Invalid_Recovery_Code_Policy,
      Invalid_API_Key_Policy,
      Invalid_External_Provider_Policy,
      Invalid_Event_Policy,
      Invalid_Audit_Policy,
      Invalid_Public_Policy);

   type Policy_Finding is record
      Severity : Finding_Severity := None;
      Code     : Finding_Code := No_Finding;
      Message  : Identity.Text.Bounded.Bounded_Text :=
        Identity.Text.Bounded.From_String ("");
   end record;

   type Finding_List is array (Positive range 1 .. Max_Findings) of Policy_Finding;

   type Finding_Report is record
      Count    : Natural range 0 .. Max_Findings := 0;
      Findings : Finding_List := [others => <>];
   end record;

   function No_Finding_Status (Severity : Finding_Severity) return Boolean is
     (Severity = None);

   function Warning_Severity (Severity : Finding_Severity) return Boolean is
     (Severity = Warning);

   function Error_Severity (Severity : Finding_Severity) return Boolean is
     (Severity = Error);

   function Has_Findings (Report : Finding_Report) return Boolean is
     (Report.Count > 0);

   function Has_Warnings (Report : Finding_Report) return Boolean;

   function Has_Errors (Report : Finding_Report) return Boolean;
end Identity.Policies.Findings;

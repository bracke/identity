with Identity.API_Keys.Policies;
with Identity.Attempts.Policies;
with Identity.Audit.Policies;
with Identity.Events.Policies;
with Identity.External_Providers.Policies;
with Identity.Limits;
with Identity.Lockout.Policies;
with Identity.Multi_Factor.Policies;
with Identity.One_Time_Passwords.Policies;
with Identity.Passwords.History;
with Identity.Passwords.Policies;
with Identity.Passwords.Resets;
with Identity.Recovery.Policies;
with Identity.Recovery_Codes.Policies;
with Identity.Sessions.Policies;
with Identity.Throttling.Policies;
with Identity.Text.Bounded;
with Identity.Tokens.Policies;
with Identity.Verification.Policies;

package body Identity.Policies.Validation is
   procedure Add
     (Report  : in out Identity.Policies.Findings.Finding_Report;
      Code    : Identity.Policies.Findings.Finding_Code;
      Message : String)
   is
   begin
      if Report.Count < Identity.Policies.Findings.Max_Findings then
         Report.Count := Report.Count + 1;
         Report.Findings (Report.Count) :=
           (Severity => Identity.Policies.Findings.Error,
            Code => Code,
            Message => Identity.Text.Bounded.From_String (Message));
      end if;
   end Add;

   function Budget_Above_Hard_Limit
     (Value : Identity.Policies.Snapshots.Resource_Budget) return Boolean is
     (Value.Repository_Reads > Identity.Limits.Max_Repository_Reads
      or else Value.Repository_Writes > Identity.Limits.Max_Repository_Writes
      or else Value.Entities_Loaded > Identity.Limits.Max_Entities_Loaded
      or else Value.Cryptographic_Operations > Identity.Limits.Max_Cryptographic_Operations
      or else Value.Factor_Challenges > Identity.Limits.Max_Factor_Challenges
      or else Value.Events > Identity.Limits.Max_Events_Per_Operation
      or else Value.Collection_Capacity > Identity.Limits.Max_Collection_Capacity
      or else Value.Retry_Count > Identity.Limits.Max_Operation_Retries
      or else Value.Input_Bytes > Identity.Limits.Max_Input_Bytes
      or else Value.Output_Bytes > Identity.Limits.Max_Output_Bytes);

   function Validate
     (Snapshot : Identity.Policies.Snapshots.Policy_Snapshot)
      return Identity.Policies.Findings.Finding_Report
   is
      Report : Identity.Policies.Findings.Finding_Report;
   begin
      if Snapshot.Password.Maximum_Length > Identity.Limits.Max_Password_Bytes then
         Add
           (Report,
            Identity.Policies.Findings.Password_Length_Above_Hard_Limit,
            "identity.policy.password.maximum-length.above-hard-limit");
      end if;

      if Snapshot.Budget.Password_History_Checks > Identity.Limits.Max_Password_History_Checks then
         Add
           (Report,
            Identity.Policies.Findings.Password_History_Above_Hard_Limit,
            "identity.policy.password-history.above-hard-limit");
      end if;

      if Snapshot.TOTP.Accepted_Skew_Steps > Identity.Limits.Max_TOTP_Skew_Steps then
         Add
           (Report,
            Identity.Policies.Findings.TOTP_Skew_Above_Hard_Limit,
            "identity.policy.totp-skew.above-hard-limit");
      end if;

      if Snapshot.Sessions.Maximum_Retention_Days > Identity.Limits.Max_Session_Retention_Days then
         Add
           (Report,
            Identity.Policies.Findings.Session_Retention_Above_Hard_Limit,
            "identity.policy.session-retention.above-hard-limit");
      end if;

      if Snapshot.Budget.Event_Attributes > Identity.Limits.Max_Event_Attributes then
         Add
           (Report,
            Identity.Policies.Findings.Event_Attribute_Above_Hard_Limit,
            "identity.policy.event-attributes.above-hard-limit");
      end if;

      if Budget_Above_Hard_Limit (Snapshot.Budget) then
         Add
           (Report,
            Identity.Policies.Findings.Resource_Budget_Above_Hard_Limit,
            "identity.policy.resource-budget.above-hard-limit");
      end if;

      if not Identity.Passwords.Policies.Valid (Snapshot.Password_Acceptance) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Password_Acceptance_Policy,
            "identity.policy.password-acceptance.invalid");
      end if;

      if not Identity.Passwords.Policies.Valid (Snapshot.Password_Hashing) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Password_Hashing_Policy,
            "identity.policy.password-hashing.invalid");
      end if;

      if not Identity.Passwords.History.Valid (Snapshot.Password_History) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Password_History_Policy,
            "identity.policy.password-history.invalid");
      end if;

      if not Identity.Passwords.Resets.Valid (Snapshot.Password_Reset) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Password_Reset_Policy,
            "identity.policy.password-reset.invalid");
      end if;

      if not Identity.Attempts.Policies.Valid (Snapshot.Attempts) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Attempt_Policy,
            "identity.policy.attempts.invalid");
      end if;

      if not Identity.Throttling.Policies.Valid (Snapshot.Throttling) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Throttling_Policy,
            "identity.policy.throttling.invalid");
      end if;

      if not Identity.Lockout.Policies.Valid (Snapshot.Lockout) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Lockout_Policy,
            "identity.policy.lockout.invalid");
      end if;

      if not Identity.Multi_Factor.Policies.Valid (Snapshot.Assurance_MFA) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_MFA_Policy,
            "identity.policy.mfa.invalid");
      end if;

      if not Identity.One_Time_Passwords.Policies.Valid (Snapshot.TOTP_Core) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_TOTP_Policy,
            "identity.policy.totp.invalid");
      end if;

      if not Identity.Sessions.Policies.Valid (Snapshot.Sessions_Core) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Session_Policy,
            "identity.policy.sessions.invalid");
      end if;

      if not Identity.Tokens.Policies.Valid (Snapshot.Tokens_Core) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Token_Policy,
            "identity.policy.tokens.invalid");
      end if;

      if not Identity.Verification.Policies.Valid (Snapshot.Verification) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Verification_Policy,
            "identity.policy.verification.invalid");
      end if;

      if not Identity.Recovery.Policies.Valid (Snapshot.Recovery) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Recovery_Policy,
            "identity.policy.recovery.invalid");
      end if;

      if not Identity.Recovery_Codes.Policies.Valid (Snapshot.Recovery_Codes) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Recovery_Code_Policy,
            "identity.policy.recovery-codes.invalid");
      end if;

      if not Identity.API_Keys.Policies.Valid (Snapshot.API_Keys) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_API_Key_Policy,
            "identity.policy.api-keys.invalid");
      end if;

      if not Identity.External_Providers.Policies.Valid (Snapshot.External_Providers) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_External_Provider_Policy,
            "identity.policy.external-providers.invalid");
      end if;

      if not Identity.Events.Policies.Valid (Snapshot.Events_Core) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Event_Policy,
            "identity.policy.events.invalid");
      end if;

      if not Identity.Audit.Policies.Valid (Snapshot.Audit) then
         Add
           (Report,
            Identity.Policies.Findings.Invalid_Audit_Policy,
            "identity.policy.audit.invalid");
      end if;

      return Report;
   end Validate;
end Identity.Policies.Validation;

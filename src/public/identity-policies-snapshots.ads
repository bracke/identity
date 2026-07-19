with Identity.API_Keys.Policies;
with Identity.Attempts.Policies;
with Identity.Audit.Policies;
with Identity.Events.Policies;
with Identity.External_Providers.Policies;
with Identity.Identifiers.Policies;
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
with Identity.Tokens.Policies;
with Identity.Verification.Policies;
with Identity.Versions;

package Identity.Policies.Snapshots is
   pragma Pure;

   type Policy_Version_Vector is record
      Account          : Identity.Identifiers.Policies.Policy_Version := 1;
      Password         : Identity.Identifiers.Policies.Policy_Version := 1;
      Password_Hashing : Identity.Identifiers.Policies.Policy_Version := 1;
      Password_History : Identity.Identifiers.Policies.Policy_Version := 1;
      Password_Reset   : Identity.Identifiers.Policies.Policy_Version := 1;
      Attempts         : Identity.Identifiers.Policies.Policy_Version := 1;
      Throttling       : Identity.Identifiers.Policies.Policy_Version := 1;
      Lockout          : Identity.Identifiers.Policies.Policy_Version := 1;
      Assurance        : Identity.Identifiers.Policies.Policy_Version := 1;
      MFA              : Identity.Identifiers.Policies.Policy_Version := 1;
      TOTP             : Identity.Identifiers.Policies.Policy_Version := 1;
      Sessions         : Identity.Identifiers.Policies.Policy_Version := 1;
      Tokens           : Identity.Identifiers.Policies.Policy_Version := 1;
      Verification     : Identity.Identifiers.Policies.Policy_Version := 1;
      Recovery         : Identity.Identifiers.Policies.Policy_Version := 1;
      Recovery_Codes   : Identity.Identifiers.Policies.Policy_Version := 1;
      External         : Identity.Identifiers.Policies.Policy_Version := 1;
      External_Providers : Identity.Identifiers.Policies.Policy_Version := 1;
      API_Keys         : Identity.Identifiers.Policies.Policy_Version := 1;
      Events           : Identity.Identifiers.Policies.Policy_Version := 1;
      Events_Core      : Identity.Identifiers.Policies.Policy_Version := 1;
      Audit            : Identity.Identifiers.Policies.Policy_Version := 1;
   end record;

   type Resource_Budget is record
      Repository_Reads        : Natural := 64;
      Repository_Writes       : Natural := 64;
      Entities_Loaded         : Natural := 64;
      Cryptographic_Operations : Natural := 32;
      Password_History_Checks : Natural := 8;
      Factor_Challenges       : Natural := 8;
      Events                  : Natural := 16;
      Event_Attributes        : Natural := 16;
      Collection_Capacity     : Natural := 128;
      Retry_Count             : Natural := 3;
      Input_Bytes             : Natural := 4_096;
      Output_Bytes            : Natural := 4_096;
   end record;

   type Password_Acceptance_Policy is record
      Minimum_Length : Natural := 12;
      Maximum_Length : Natural := 256;
   end record;

   type Session_Policy is record
      Maximum_Retention_Days : Natural := 90;
      Rotation_Required     : Boolean := True;
   end record;

   type TOTP_Policy is record
      Accepted_Skew_Steps : Natural := 1;
      Maximum_Attempts    : Natural := 5;
   end record;

   type Policy_Snapshot is record
      Id       : Identity.Identifiers.Policies.Policy_Set_Id;
      Versions : Policy_Version_Vector;
      Format   : Identity.Versions.Format_Version := 1;
      Password : Password_Acceptance_Policy;
      Sessions : Session_Policy;
      TOTP     : TOTP_Policy;
      Budget   : Resource_Budget;
      Password_Acceptance : Identity.Passwords.Policies.Password_Acceptance_Policy;
      Password_Hashing    : Identity.Passwords.Policies.Password_Hashing_Policy;
      Password_History    : Identity.Passwords.History.History_Policy;
      Password_Reset      : Identity.Passwords.Resets.Reset_Policy;
      Attempts            : Identity.Attempts.Policies.Attempt_Policy;
      Throttling          : Identity.Throttling.Policies.Throttling_Policy;
      Lockout             : Identity.Lockout.Policies.Lockout_Policy;
      Assurance_MFA       : Identity.Multi_Factor.Policies.MFA_Policy;
      TOTP_Core           : Identity.One_Time_Passwords.Policies.TOTP_Policy;
      Sessions_Core       : Identity.Sessions.Policies.Session_Policy;
      Tokens_Core         : Identity.Tokens.Policies.Token_Policy;
      Verification        : Identity.Verification.Policies.Contact_Verification_Policy;
      Recovery            : Identity.Recovery.Policies.Recovery_Policy;
      Recovery_Codes      : Identity.Recovery_Codes.Policies.Recovery_Code_Policy;
      API_Keys            : Identity.API_Keys.Policies.API_Key_Policy;
      External_Providers  : Identity.External_Providers.Policies.External_Provider_Policy;
      Events_Core         : Identity.Events.Policies.Event_Policy;
      Audit               : Identity.Audit.Policies.Audit_Policy;
   end record;
end Identity.Policies.Snapshots;

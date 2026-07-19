with Identity.Identifiers;
with Identity.Identifiers.Policies;

package body Identity.Policies.Defaults is
   function Default_Snapshot return Identity.Policies.Snapshots.Policy_Snapshot is
     ((Id => Identity.Identifiers.Policies.Policy_Set
          (Identity.Identifiers.From_String ("10000000-0000-0000-0000-00000000d001")),
       Versions => <>,
       Format => 1,
       Password => <>,
       Sessions => <>,
       TOTP => <>,
       Budget => <>,
       Password_Acceptance => <>,
       Password_Hashing => <>,
       Password_History => <>,
       Password_Reset => <>,
       Attempts => <>,
       Throttling => <>,
       Lockout => <>,
       Assurance_MFA => <>,
       TOTP_Core => <>,
       Sessions_Core => <>,
       Tokens_Core => <>,
       Verification => <>,
       Recovery => <>,
       Recovery_Codes => <>,
       API_Keys => <>,
       External_Providers => <>,
       Events_Core => <>,
       Audit => <>));
end Identity.Policies.Defaults;

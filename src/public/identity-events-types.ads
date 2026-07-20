with Identity.Identifiers.Registry;

package Identity.Events.Types is
   Authentication_Succeeded : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.authentication.succeeded");
   Authentication_Rejected : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.authentication.rejected");
   Session_Created : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.created");
   Session_Rotated : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.rotated");
   Session_Revoked : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.revoked");
   Password_Changed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.password.changed");
   Password_Reset_Requested : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.password.reset.requested");
   Password_Reset_Completed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.password.reset.completed");
   Account_Disabled : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.disabled");
   Contact_Verified : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.contact.verified");
   MFA_Challenge_Completed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.mfa.challenge.completed");
   Recovery_Completed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery.completed");
   API_Key_Authenticated : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.api-key.authenticated");
   API_Key_Revoked : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.api-key.revoked");
   TOTP_Replay_Detected : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.totp.replay-detected");
   External_Assertion_Replay_Detected : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.external.assertion.replay-detected");

   --  V1 covers every state-changing operation, not only the interactive
   --  authentication path: an audit trail that cannot answer "who removed
   --  this factor?" or "who issued this key?" is not an audit trail.
   Principal_Created : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.principal.created");
   Principal_Retired : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.principal.retired");
   Account_Created : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.created");
   Account_Enabled : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.enabled");
   Account_Suspended : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.suspended");
   Account_Closed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.closed");
   Account_Unlocked : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.unlocked");
   Account_MFA_Required : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.mfa-required");
   Account_Password_Change_Required : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.account.password-change-required");
   Password_Enrolled : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.password.enrolled");
   API_Key_Issued : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.api-key.issued");
   API_Key_Rotated : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.api-key.rotated");
   Authentication_Transaction_Began : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.authentication.transaction.began");
   MFA_Enrollment_Began : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.mfa.factor.enrollment-began");
   MFA_Factor_Enrolled : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.mfa.factor.enrolled");
   MFA_Factor_Removed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.mfa.factor.removed");
   MFA_Challenge_Issued : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.mfa.challenge.issued");
   Recovery_Codes_Generated : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery-codes.generated");
   Recovery_Code_Consumed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery-code.consumed");
   Identity_Binding_Added : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.binding.added");
   Identity_Binding_Changed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.binding.changed");
   Identity_Binding_Revoked : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.binding.revoked");
   External_Binding_Revoked : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.external.binding.revoked");
   Token_Issued : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.issued");
   Token_Consumed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.consumed");
   Recovery_Began : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery.began");
   Recovery_Continued : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery.continued");
   Recovery_Cancelled : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery.cancelled");
   Contact_Change_Began : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.contact.change.began");
   Contact_Change_Completed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.contact.change.completed");
   External_Binding_Created : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.external.binding.created");
   Session_Expired : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.expired");
   Session_Purged : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.purged");
   Contact_Verification_Requested : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.contact.verification.requested");
   Password_Verifier_Migrated : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.password.verifier.migrated");
   Session_Renewed : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.renewed");
   Session_Assurance_Upgraded : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session.assurance-upgraded");
end Identity.Events.Types;

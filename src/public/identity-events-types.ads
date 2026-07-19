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
end Identity.Events.Types;

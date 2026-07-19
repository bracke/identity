with Identity.Identifiers.Registry;

package Identity.Crypto.Domains is
   Session_Token                 : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.session-token");
   Password_Reset_Token          : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.password-reset-token");
   Contact_Verification_Token    : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.contact-verification-token");
   API_Key                       : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.api-key");
   Recovery_Code                 : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.recovery-code");
   TOTP_Secret                   : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.totp-secret");
   Subject_Fingerprint           : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.subject-fingerprint");
   External_Assertion_Fingerprint : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.external-assertion-fingerprint");
   Event_Integrity               : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.event-integrity");
end Identity.Crypto.Domains;

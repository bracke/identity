with Identity.Identifiers.Registry;

package Identity.Credentials.Kinds is
   Password : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.credential.password");
   TOTP : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.credential.totp");
   Recovery_Code_Set : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.credential.recovery-code-set");
   API_Key : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.credential.api-key");
   External_Binding : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.credential.external-binding");
   Generic_Factor : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.credential.generic-factor");
end Identity.Credentials.Kinds;

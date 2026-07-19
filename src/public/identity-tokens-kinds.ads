with Identity.Identifiers.Registry;

package Identity.Tokens.Kinds is
   Action_Token : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.kind.action");
   Password_Reset : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.kind.password-reset");
   Contact_Verification : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.kind.contact-verification");
   Recovery_Authority : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.kind.recovery-authority");
end Identity.Tokens.Kinds;

with Identity.Identifiers.Registry;

package Identity.Tokens.Purposes is
   Password_Reset : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.password-reset");
   Contact_Verification : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.contact-verification");
   Identity_Verification : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.identity-verification");
   Contact_Change : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.contact-change");
   Recovery : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.recovery");
   Enrollment_Completion : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.enrollment-completion");
   Administrative_Activation : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.token.administrative-activation");
end Identity.Tokens.Purposes;

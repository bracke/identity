with Identity.Identifiers.Registry;

package Identity.Text.Messages is
   Authentication_Rejected : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.message.authentication-rejected");
   Token_Invalid_Or_Expired : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.message.token-invalid-or-expired");
   Operation_Conflict : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.message.operation-conflict");
   Operational_Failure : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.message.operational-failure");
end Identity.Text.Messages;

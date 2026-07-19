with Identity.Identifiers.Registry;

package Identity.Errors.Codes is
   Authentication_Rejected : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.error.authentication-rejected");
   Token_Invalid : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.error.token-invalid");
   Version_Conflict : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.error.version-conflict");
   Repository_Unavailable : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.error.repository-unavailable");
   Crypto_Unavailable : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.error.crypto-unavailable");
end Identity.Errors.Codes;

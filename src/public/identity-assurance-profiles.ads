with Identity.Identifiers.Registry;

package Identity.Assurance.Profiles is
   Basic               : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("basic");
   Interactive         : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("interactive");
   Sensitive           : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("sensitive");
   Administrative      : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("administrative");
   Service             : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("service");
   Recovery_Restricted : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("recovery-restricted");
end Identity.Assurance.Profiles;

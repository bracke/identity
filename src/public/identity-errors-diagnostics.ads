with Identity.Identifiers.Registry;

package Identity.Errors.Diagnostics is
   Diagnostic_Sink_Unavailable : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.diagnostic.sink-unavailable");
   Dependency_Failure : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.diagnostic.dependency-failure");
   Invariant_Failure : constant Identity.Identifiers.Registry.Registry_Id :=
     Identity.Identifiers.Registry.From_String ("identity.diagnostic.invariant-failure");
end Identity.Errors.Diagnostics;

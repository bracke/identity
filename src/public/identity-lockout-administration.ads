with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;

package Identity.Lockout.Administration is
   pragma Pure;

   type Administrative_Unlock_Context is record
      Actor_Present : Boolean := False;
      Reason : Identity.Identifiers.Registry.Registry_Id;
      Operation : Identity.Identifiers.Operations.Operation_Id;
      Correlation : Identity.Identifiers.Operations.Correlation_Id;
   end record;

   function Structurally_Valid (Value : Administrative_Unlock_Context) return Boolean is
     (Value.Actor_Present);
end Identity.Lockout.Administration;

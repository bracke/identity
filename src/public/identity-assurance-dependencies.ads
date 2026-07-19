with Identity.Identifiers.Registry;

package Identity.Assurance.Dependencies is
   pragma Pure;

   type Evidence_Dependency is record
      Domain : Identity.Identifiers.Registry.Registry_Id;
      Independent : Boolean := True;
   end record;

   function Counts_As_Independent (Value : Evidence_Dependency) return Boolean is
     (Value.Independent);
end Identity.Assurance.Dependencies;

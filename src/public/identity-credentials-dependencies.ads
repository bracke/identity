with Identity.Identifiers.Registry;

package Identity.Credentials.Dependencies is
   pragma Pure;
   use type Identity.Identifiers.Registry.Registry_Id;

   type Dependency_Domain is record
      Id          : Identity.Identifiers.Registry.Registry_Id;
      Independent : Boolean := True;
   end record;

   function Independent (Value : Dependency_Domain) return Boolean is
     (Value.Independent);

   function Same_Domain
     (Left, Right : Dependency_Domain) return Boolean is
     (Left.Id = Right.Id);

   function Independent_From
     (Left, Right : Dependency_Domain) return Boolean is
     (Left.Independent and then Right.Independent and then not Same_Domain (Left, Right));
end Identity.Credentials.Dependencies;

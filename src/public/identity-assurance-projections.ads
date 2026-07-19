with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Registry;

package Identity.Assurance.Projections is
   pragma Pure;

   type Assurance_Projection is record
      Profile    : Identity.Identifiers.Registry.Registry_Id;
      Level      : Identity.Assurance.Levels.Assurance_Level :=
        Identity.Assurance.Levels.Anonymous;
      Attributes : Identity.Assurance.Attributes.Assurance_Attributes;
      Recovery_Restricted : Boolean := False;
   end record;
end Identity.Assurance.Projections;

with Identity.Identifiers.Entities;
with Identity.Sessions.Definitions;
with Identity.Versions;

package Identity.Multi_Factor.Step_Up is
   pragma Pure;
   use type Identity.Identifiers.Entities.Principal_Id;
   use type Identity.Identifiers.Entities.Session_Family_Id;
   use type Identity.Identifiers.Entities.Session_Id;
   use type Identity.Versions.Rotation_Generation;

   type Step_Up_Binding is record
      Session    : Identity.Identifiers.Entities.Session_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Family     : Identity.Identifiers.Entities.Session_Family_Id;
      Generation : Identity.Versions.Rotation_Generation := 0;
   end record;

   function Matches
     (Binding : Step_Up_Binding;
      Session : Identity.Sessions.Definitions.Session_Record) return Boolean is
     (Binding.Session = Session.Id
      and then Binding.Principal = Session.Principal
      and then Binding.Family = Session.Family
      and then Binding.Generation = Session.Generation);
end Identity.Multi_Factor.Step_Up;

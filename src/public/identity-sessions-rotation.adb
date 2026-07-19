with Identity.Identifiers.Entities;

package body Identity.Sessions.Rotation
  with SPARK_Mode => On
is
   use type Identity.Identifiers.Entities.Principal_Id;
   use type Identity.Identifiers.Entities.Session_Family_Id;
   use type Identity.Versions.Rotation_Generation;

   function Can_Rotate
     (Session : Identity.Sessions.Definitions.Session_Record) return Rotation_Status
   is
   begin
      if not Identity.Sessions.Definitions.Is_Active (Session.State) then
         return Not_Active;
      elsif Session.Generation = Identity.Versions.Rotation_Generation'Last then
         return Generation_Exhausted;
      else
         return Allowed;
      end if;
   end Can_Rotate;

   function Successor_Generation
     (Session : Identity.Sessions.Definitions.Session_Record)
      return Identity.Versions.Rotation_Generation
   is
   begin
      if Session.Generation = Identity.Versions.Rotation_Generation'Last then
         return Session.Generation;
      end if;

      return Session.Generation + Identity.Versions.Rotation_Generation'(1);
   end Successor_Generation;

   function Matches_Successor_Generation
     (Predecessor, Successor : Identity.Sessions.Definitions.Session_Record)
      return Boolean
   is
   begin
      return Can_Rotate (Predecessor) = Allowed
        and then Successor.Generation = Successor_Generation (Predecessor);
   end Matches_Successor_Generation;

   function Same_Rotation_Lineage
     (Predecessor, Successor : Identity.Sessions.Definitions.Session_Record)
      return Boolean
   is
   begin
      return Predecessor.Family = Successor.Family
        and then Predecessor.Principal = Successor.Principal
        and then Matches_Successor_Generation (Predecessor, Successor);
   end Same_Rotation_Lineage;
end Identity.Sessions.Rotation;

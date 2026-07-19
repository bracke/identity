with Identity.Sessions.Definitions;
with Identity.Versions;

package Identity.Sessions.Rotation
  with SPARK_Mode => On
is
   pragma Pure;

   type Rotation_Status is (Allowed, Not_Active, Generation_Exhausted);

   function Rotation_Allowed (Status : Rotation_Status) return Boolean is
     (Status = Allowed);

   function State_Rejected (Status : Rotation_Status) return Boolean is
     (Status = Not_Active);

   function Generation_Rejected (Status : Rotation_Status) return Boolean is
     (Status = Generation_Exhausted);

   function Rotation_Rejected (Status : Rotation_Status) return Boolean is
     (Status in Not_Active | Generation_Exhausted);

   function Can_Rotate
     (Session : Identity.Sessions.Definitions.Session_Record) return Rotation_Status;

   function Successor_Generation
     (Session : Identity.Sessions.Definitions.Session_Record)
      return Identity.Versions.Rotation_Generation;

   function Matches_Successor_Generation
     (Predecessor, Successor : Identity.Sessions.Definitions.Session_Record)
      return Boolean;

   function Same_Rotation_Lineage
     (Predecessor, Successor : Identity.Sessions.Definitions.Session_Record)
      return Boolean;
end Identity.Sessions.Rotation;

package Identity.Versions
  with SPARK_Mode => On
is
   pragma Pure;

   type Entity_Version is range 0 .. 2**63 - 1;
   type Format_Version is range 1 .. 2**31 - 1;
   type Schema_Version is range 1 .. 2**31 - 1;
   type Rotation_Generation is range 0 .. 2**31 - 1;
   type Attempt_Count is range 0 .. 2**31 - 1;

   type Authentication_State_Revision is range 0 .. 2**63 - 1;
   type Evidence_Revision is range 0 .. 2**63 - 1;
   type Session_Revision is range 0 .. 2**63 - 1;

   function Same_Entity_Version
     (Left, Right : Entity_Version) return Boolean is
     (Left = Right);

   function Next_Entity_Version (Value : Entity_Version) return Entity_Version is
     (if Value = Entity_Version'Last then Entity_Version'Last else Value + 1);
end Identity.Versions;

with Identity.Identifiers.Entities;
with Identity.Principals.Projections;
with Identity.Versions;

package Identity.Adapters.Repositories.Principals is
   pragma Pure;

   type Principal_Read_Status is (Found, Not_Found, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Principal_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Principal_Read_Status) return Boolean is
     (Status = Not_Found);

   function Capacity_Rejected (Status : Principal_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Principal_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Principal_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   type Principal_View is record
      Status     : Principal_Read_Status := Not_Found;
      Principal  : Identity.Principals.Projections.Principal_Projection;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;

   type Principal_Create_Command is record
      Principal_Id : Identity.Identifiers.Entities.Principal_Id;
      Expected_New : Boolean := True;
   end record;
end Identity.Adapters.Repositories.Principals;

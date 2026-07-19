with Identity.Authentication.Challenges;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Challenges is
   pragma Pure;

   type Challenge_Read_Status is (Found, Not_Found, Expired, Consumed, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Challenge_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Challenge_Read_Status) return Boolean is
     (Status = Not_Found);

   function Expired_Status (Status : Challenge_Read_Status) return Boolean is
     (Status = Expired);

   function Consumed_Status (Status : Challenge_Read_Status) return Boolean is
     (Status = Consumed);

   function Capacity_Rejected (Status : Challenge_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Challenge_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Challenge_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Terminal_Rejection (Status : Challenge_Read_Status) return Boolean is
     (Status in Not_Found | Expired | Consumed);

   type Challenge_View is record
      Status       : Challenge_Read_Status := Not_Found;
      Challenge_Id : Identity.Identifiers.Entities.Challenge_Id;
      Challenge    : Identity.Authentication.Challenges.Challenge_Record;
      Version      : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Challenges;

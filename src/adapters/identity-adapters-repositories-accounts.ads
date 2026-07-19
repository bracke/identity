with Identity.Accounts.Definitions;
with Identity.Projections.Accounts;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Accounts is
   pragma Pure;

   type Account_Read_Status is (Found, Not_Found, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Account_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Account_Read_Status) return Boolean is
     (Status = Not_Found);

   function Capacity_Rejected (Status : Account_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Account_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Account_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   type Account_State_View is record
      Status     : Account_Read_Status := Not_Found;
      Account_Id : Identity.Identifiers.Entities.Account_Id;
      State      : Identity.Projections.Accounts.Account_State_Projection;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;

   type Account_State_Command is record
      Account          : Identity.Accounts.Definitions.Account_Record;
      Expected_Version : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Accounts;

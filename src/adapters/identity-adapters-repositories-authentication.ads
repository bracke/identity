with Identity.Authentication.Evidence;
with Identity.Authentication.Transactions;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Authentication is
   pragma Pure;

   type Authentication_View_Status is (Found, Not_Found, Expired, Consumed, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Authentication_View_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Authentication_View_Status) return Boolean is
     (Status = Not_Found);

   function Expired_Status (Status : Authentication_View_Status) return Boolean is
     (Status = Expired);

   function Consumed_Status (Status : Authentication_View_Status) return Boolean is
     (Status = Consumed);

   function Capacity_Rejected (Status : Authentication_View_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Authentication_View_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Authentication_View_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Terminal_Rejection (Status : Authentication_View_Status) return Boolean is
     (Status in Not_Found | Expired | Consumed);

   type Transaction_View is record
      Status         : Authentication_View_Status := Not_Found;
      Transaction_Id : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Transaction    : Identity.Authentication.Transactions.Authentication_Transaction_Record;
      Version        : Identity.Versions.Entity_Version := 0;
   end record;

   type Evidence_Command is record
      Principal_Id    : Identity.Identifiers.Entities.Principal_Id;
      Transaction_Id  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Evidence        : Identity.Authentication.Evidence.Evidence_Record;
      Expected_Version : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Authentication;

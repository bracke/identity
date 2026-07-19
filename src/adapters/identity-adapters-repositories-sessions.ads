with Identity.Identifiers.Entities;
with Identity.Sessions.Definitions;
with Identity.Sessions.Handles;
with Identity.Versions;

package Identity.Adapters.Repositories.Sessions is
   pragma Pure;

   type Session_Read_Status is
     (Found, Not_Found, Expired, Revoked, Replayed, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Session_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Session_Read_Status) return Boolean is
     (Status = Not_Found);

   function Expired_Status (Status : Session_Read_Status) return Boolean is
     (Status = Expired);

   function Revoked_Status (Status : Session_Read_Status) return Boolean is
     (Status = Revoked);

   function Replayed_Status (Status : Session_Read_Status) return Boolean is
     (Status = Replayed);

   function Capacity_Rejected (Status : Session_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Session_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Session_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Terminal_Rejection (Status : Session_Read_Status) return Boolean is
     (Status in Not_Found | Expired | Revoked | Replayed);

   function Security_Response_Required (Status : Session_Read_Status) return Boolean is
     (Status = Replayed);

   type Session_View is record
      Status     : Session_Read_Status := Not_Found;
      Session_Id : Identity.Identifiers.Entities.Session_Id;
      Session    : Identity.Sessions.Definitions.Session_Record;
      Handle     : Identity.Sessions.Handles.Session_Handle;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Sessions;

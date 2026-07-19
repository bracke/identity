with Identity.Credentials.Definitions;
with Identity.Credentials.Projections;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Credentials is
   pragma Pure;

   type Credential_Read_Status is (Found, Not_Found, Unusable, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Credential_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Credential_Read_Status) return Boolean is
     (Status = Not_Found);

   function Unusable_Status (Status : Credential_Read_Status) return Boolean is
     (Status = Unusable);

   function Capacity_Rejected (Status : Credential_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Credential_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Credential_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Disclosure_Collapsible (Status : Credential_Read_Status) return Boolean is
     (Status in Not_Found | Unusable);

   type Credential_View is record
      Status        : Credential_Read_Status := Not_Found;
      Credential_Id : Identity.Identifiers.Entities.Credential_Id;
      Credential    : Identity.Credentials.Projections.Credential_Projection;
      Version       : Identity.Versions.Entity_Version := 0;
   end record;

   type Credential_Command is record
      Credential       : Identity.Credentials.Definitions.Credential_Record;
      Expected_Version : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Credentials;

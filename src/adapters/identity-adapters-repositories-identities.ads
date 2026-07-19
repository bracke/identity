with Identity.Identities.Bindings;
with Identity.Identities.Resolution;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Identities is
   pragma Pure;

   type Identity_Read_Status is (Resolved, Not_Found, Ambiguous, Capacity_Exceeded, Infrastructure_Failure);

   function Resolved_Status (Status : Identity_Read_Status) return Boolean is
     (Status = Resolved);

   function Missing_Status (Status : Identity_Read_Status) return Boolean is
     (Status = Not_Found);

   function Ambiguous_Status (Status : Identity_Read_Status) return Boolean is
     (Status = Ambiguous);

   function Capacity_Rejected (Status : Identity_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Identity_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Identity_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Disclosure_Collapsible (Status : Identity_Read_Status) return Boolean is
     (Status in Not_Found | Ambiguous);

   type Identity_Resolution_View is record
      Status     : Identity_Read_Status := Not_Found;
      Resolution : Identity.Identities.Resolution.Resolution_Result;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;

   type Binding_Command is record
      Binding_Id   : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal_Id : Identity.Identifiers.Entities.Principal_Id;
      State        : Identity.Identities.Bindings.Binding_State :=
        Identity.Identities.Bindings.Pending;
      Expected_Version : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Identities;

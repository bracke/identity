with Identity.Contacts.Bindings;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Contacts is
   pragma Pure;

   type Contact_Read_Status is (Found, Not_Found, Binding_Mismatch, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Contact_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Contact_Read_Status) return Boolean is
     (Status = Not_Found);

   function Binding_Mismatch_Status (Status : Contact_Read_Status) return Boolean is
     (Status = Binding_Mismatch);

   function Capacity_Rejected (Status : Contact_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Contact_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Contact_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Disclosure_Collapsible (Status : Contact_Read_Status) return Boolean is
     (Status in Not_Found | Binding_Mismatch);

   type Contact_Binding_View is record
      Status     : Contact_Read_Status := Not_Found;
      Binding_Id : Identity.Identifiers.Entities.Contact_Binding_Id;
      Binding    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Contacts;

with Identity.Identifiers.Entities;
with Identity.Principals.Kinds;
with Identity.Versions;

package Identity.Service_Principals is
   pragma Pure;
   use type Identity.Principals.Kinds.Principal_Kind;

   type Service_Principal_Record is record
      Id      : Identity.Identifiers.Entities.Principal_Id;
      Kind    : Identity.Principals.Kinds.Principal_Kind := Identity.Principals.Kinds.Service;
      Version : Identity.Versions.Entity_Version := 0;
   end record;

   function Is_Service (Value : Service_Principal_Record) return Boolean is
     (Value.Kind = Identity.Principals.Kinds.Service);
end Identity.Service_Principals;

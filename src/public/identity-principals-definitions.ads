with Identity.Identifiers.Entities;
with Identity.Principals.Kinds;
with Identity.Versions;

package Identity.Principals.Definitions is
   pragma Pure;

   type Principal_Lifecycle is (Active, Retired);

   type Principal_Record is record
      Id      : Identity.Identifiers.Entities.Principal_Id;
      Kind    : Identity.Principals.Kinds.Principal_Kind := Identity.Principals.Kinds.Human;
      State   : Principal_Lifecycle := Active;
      Version : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Principals.Definitions;

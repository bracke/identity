with Identity.Identifiers.Entities;
with Identity.Principals.Definitions;
with Identity.Principals.Kinds;
with Identity.Principals.Lifecycle;
with Identity.Versions;

package Identity.Principals.Projections is
   pragma Pure;
   use type Identity.Principals.Definitions.Principal_Lifecycle;

   type Principal_Projection is record
      Id      : Identity.Identifiers.Entities.Principal_Id;
      Kind    : Identity.Principals.Kinds.Principal_Kind := Identity.Principals.Kinds.Human;
      State   : Identity.Principals.Definitions.Principal_Lifecycle :=
        Identity.Principals.Definitions.Active;
      Version : Identity.Versions.Entity_Version := 0;
   end record;

   function Summary
     (Principal : Identity.Principals.Definitions.Principal_Record)
      return Principal_Projection is
     ((Id => Principal.Id,
       Kind => Principal.Kind,
       State => Principal.State,
       Version => Principal.Version));

   function Active
     (Principal : Principal_Projection) return Boolean is
     (Identity.Principals.Lifecycle.Active (Principal.State));

   function Retired
     (Principal : Principal_Projection) return Boolean is
     (Principal.State = Identity.Principals.Definitions.Retired);
end Identity.Principals.Projections;

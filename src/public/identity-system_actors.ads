with Identity.Identifiers.Entities;
with Identity.Principals.Kinds;

package Identity.System_Actors is
   pragma Pure;
   use type Identity.Principals.Kinds.Principal_Kind;

   type System_Actor_Record is record
      Principal : Identity.Identifiers.Entities.Principal_Id;
      Kind      : Identity.Principals.Kinds.Principal_Kind := Identity.Principals.Kinds.System;
   end record;

   type System_Actor_Projection is record
      Principal : Identity.Identifiers.Entities.Principal_Id;
      Kind      : Identity.Principals.Kinds.Principal_Kind := Identity.Principals.Kinds.System;
      Identity_Only : Boolean := True;
      Downstream_Policy_Required : Boolean := True;
   end record;

   function Is_System (Value : System_Actor_Record) return Boolean is
     (Value.Kind = Identity.Principals.Kinds.System);
   function Establishes_Identity_Only (Value : System_Actor_Record) return Boolean is
     (Is_System (Value));
   function Requires_Downstream_Policy (Value : System_Actor_Record) return Boolean is
     (Is_System (Value));

   function Summary (Value : System_Actor_Record) return System_Actor_Projection is
     ((Principal => Value.Principal,
       Kind => Value.Kind,
       Identity_Only => Establishes_Identity_Only (Value),
       Downstream_Policy_Required => Requires_Downstream_Policy (Value)));

   function Is_System (Value : System_Actor_Projection) return Boolean is
     (Value.Kind = Identity.Principals.Kinds.System);
   function Establishes_Identity_Only
     (Value : System_Actor_Projection) return Boolean is
     (Value.Identity_Only and then Is_System (Value));
   function Requires_Downstream_Policy
     (Value : System_Actor_Projection) return Boolean is
     (Value.Downstream_Policy_Required and then Is_System (Value));
end Identity.System_Actors;

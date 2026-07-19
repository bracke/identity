generic
   type Element_Type is private;
package Identity.Optionals is
   pragma Preelaborate;

   type Optional is private;

   function None return Optional;
   function Present (Value : Element_Type) return Optional;
   function Is_Some (Value : Optional) return Boolean;
   function Get (Value : Optional) return Element_Type
     with Pre => Is_Some (Value);

private
   type Optional is record
      Present : Boolean := False;
      Item    : Element_Type;
   end record;
end Identity.Optionals;

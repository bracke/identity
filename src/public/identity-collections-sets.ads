generic
   type Element_Type is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
   Max_Capacity : Positive;
package Identity.Collections.Sets is
   pragma Pure;

   subtype Count_Type is Natural range 0 .. Max_Capacity;
   subtype Index_Type is Positive range 1 .. Max_Capacity;

   type Set is private;

   function Length (Value : Set) return Count_Type;
   function Contains (Value : Set; Element : Element_Type) return Boolean;
   function Insert
     (Value   : in out Set;
      Element : Element_Type) return Identity.Collections.Collection_Status;
   function Element
     (Value : Set;
      Index : Index_Type) return Element_Type
     with Pre => Index <= Length (Value);

private
   type Element_Array is array (Index_Type) of Element_Type;

   type Set is record
      Count : Count_Type := 0;
      Items : Element_Array;
   end record;
end Identity.Collections.Sets;

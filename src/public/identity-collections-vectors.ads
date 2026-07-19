generic
   type Element_Type is private;
   Max_Capacity : Positive;
package Identity.Collections.Vectors is
   pragma Pure;

   subtype Count_Type is Natural range 0 .. Max_Capacity;
   subtype Index_Type is Positive range 1 .. Max_Capacity;

   type Vector is private;

   function Length (Value : Vector) return Count_Type;
   function Is_Full (Value : Vector) return Boolean;
   function Append
     (Value   : in out Vector;
      Element : Element_Type) return Identity.Collections.Collection_Status;
   function Element
     (Value : Vector;
      Index : Index_Type) return Element_Type
     with Pre => Index <= Length (Value);

private
   type Element_Array is array (Index_Type) of Element_Type;

   type Vector is record
      Count : Count_Type := 0;
      Items : Element_Array;
   end record;
end Identity.Collections.Vectors;

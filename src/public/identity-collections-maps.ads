generic
   type Key_Type is private;
   type Value_Type is private;
   with function "=" (Left, Right : Key_Type) return Boolean is <>;
   Max_Capacity : Positive;
package Identity.Collections.Maps is
   pragma Pure;

   subtype Count_Type is Natural range 0 .. Max_Capacity;
   subtype Index_Type is Positive range 1 .. Max_Capacity;

   type Map is private;

   function Length (Value : Map) return Count_Type;
   function Contains (Value : Map; Key : Key_Type) return Boolean;
   function Insert
     (Value   : in out Map;
      Key     : Key_Type;
      Element : Value_Type) return Identity.Collections.Collection_Status;
   function Replace
     (Value   : in out Map;
      Key     : Key_Type;
      Element : Value_Type) return Identity.Collections.Collection_Status;
   function Get
     (Value   : Map;
      Key     : Key_Type;
      Element : out Value_Type) return Identity.Collections.Collection_Status;
   function Key_At
     (Value : Map;
      Index : Index_Type) return Key_Type
     with Pre => Index <= Length (Value);
   function Element_At
     (Value : Map;
      Index : Index_Type) return Value_Type
     with Pre => Index <= Length (Value);

private
   type Key_Array is array (Index_Type) of Key_Type;
   type Value_Array is array (Index_Type) of Value_Type;

   type Map is record
      Count  : Count_Type := 0;
      Keys   : Key_Array;
      Values : Value_Array;
   end record;
end Identity.Collections.Maps;

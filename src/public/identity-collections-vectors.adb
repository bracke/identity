package body Identity.Collections.Vectors is
   function Length (Value : Vector) return Count_Type is (Value.Count);

   function Is_Full (Value : Vector) return Boolean is
     (Value.Count = Max_Capacity);

   function Append
     (Value   : in out Vector;
      Element : Element_Type) return Identity.Collections.Collection_Status
   is
   begin
      if Is_Full (Value) then
         return Identity.Collections.Full;
      end if;

      Value.Count := Value.Count + 1;
      Value.Items (Value.Count) := Element;
      return Identity.Collections.Ok;
   end Append;

   function Element
     (Value : Vector;
      Index : Index_Type) return Element_Type
   is
   begin
      return Value.Items (Index);
   end Element;
end Identity.Collections.Vectors;

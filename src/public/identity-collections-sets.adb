package body Identity.Collections.Sets is
   function Length (Value : Set) return Count_Type is (Value.Count);

   function Contains (Value : Set; Element : Element_Type) return Boolean is
   begin
      for Index in 1 .. Value.Count loop
         if Value.Items (Index) = Element then
            return True;
         end if;
      end loop;

      return False;
   end Contains;

   function Insert
     (Value   : in out Set;
      Element : Element_Type) return Identity.Collections.Collection_Status
   is
   begin
      if Contains (Value, Element) then
         return Identity.Collections.Duplicate;
      end if;

      if Value.Count = Max_Capacity then
         return Identity.Collections.Full;
      end if;

      Value.Count := Value.Count + 1;
      Value.Items (Value.Count) := Element;
      return Identity.Collections.Ok;
   end Insert;

   function Element
     (Value : Set;
      Index : Index_Type) return Element_Type
   is
   begin
      return Value.Items (Index);
   end Element;
end Identity.Collections.Sets;

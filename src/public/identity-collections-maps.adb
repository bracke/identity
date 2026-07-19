package body Identity.Collections.Maps is
   function Find_Index (Value : Map; Key : Key_Type) return Natural is
   begin
      for Index in 1 .. Value.Count loop
         if Value.Keys (Index) = Key then
            return Index;
         end if;
      end loop;

      return 0;
   end Find_Index;

   function Length (Value : Map) return Count_Type is (Value.Count);

   function Contains (Value : Map; Key : Key_Type) return Boolean is
     (Find_Index (Value, Key) /= 0);

   function Insert
     (Value   : in out Map;
      Key     : Key_Type;
      Element : Value_Type) return Identity.Collections.Collection_Status
   is
   begin
      if Contains (Value, Key) then
         return Identity.Collections.Duplicate;
      end if;

      if Value.Count = Max_Capacity then
         return Identity.Collections.Full;
      end if;

      Value.Count := Value.Count + 1;
      Value.Keys (Value.Count) := Key;
      Value.Values (Value.Count) := Element;
      return Identity.Collections.Ok;
   end Insert;

   function Replace
     (Value   : in out Map;
      Key     : Key_Type;
      Element : Value_Type) return Identity.Collections.Collection_Status
   is
      Index : constant Natural := Find_Index (Value, Key);
   begin
      if Index = 0 then
         return Identity.Collections.Missing;
      end if;

      Value.Values (Index) := Element;
      return Identity.Collections.Ok;
   end Replace;

   function Get
     (Value   : Map;
      Key     : Key_Type;
      Element : out Value_Type) return Identity.Collections.Collection_Status
   is
      Index : constant Natural := Find_Index (Value, Key);
   begin
      if Index = 0 then
         return Identity.Collections.Missing;
      end if;

      Element := Value.Values (Index);
      return Identity.Collections.Ok;
   end Get;

   function Key_At
     (Value : Map;
      Index : Index_Type) return Key_Type
   is
   begin
      return Value.Keys (Index);
   end Key_At;

   function Element_At
     (Value : Map;
      Index : Index_Type) return Value_Type
   is
   begin
      return Value.Values (Index);
   end Element_At;
end Identity.Collections.Maps;

package body Identity.Optionals is
   function None return Optional is
      Result : Optional;
   begin
      Result.Present := False;
      return Result;
   end None;

   function Present (Value : Element_Type) return Optional is
     ((Present => True, Item => Value));

   function Is_Some (Value : Optional) return Boolean is
     (Value.Present);

   function Get (Value : Optional) return Element_Type is
     (Value.Item);
end Identity.Optionals;

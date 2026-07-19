with Identity.Limits;

package body Identity.Text.UTF_8 is
   function Continuation (Value : Character) return Boolean is
      B : constant Natural := Character'Pos (Value);
   begin
      return B in 16#80# .. 16#BF#;
   end Continuation;

   function Validate (Value : String) return UTF_8_Status is
      Index : Integer := Value'First;
      B     : Natural;
      Need  : Natural;
   begin
      if Value'Length > Identity.Limits.Max_Public_Text_Bytes then
         return Too_Large;
      end if;

      while Index <= Value'Last loop
         B := Character'Pos (Value (Index));
         if B <= 16#7F# then
            Index := Index + 1;
         elsif B in 16#C2# .. 16#DF# then
            Need := 1;
            if Index + Integer (Need) > Value'Last then
               return Invalid;
            end if;
            if not Continuation (Value (Index + 1)) then
               return Invalid;
            end if;
            Index := Index + 2;
         elsif B in 16#E0# .. 16#EF# then
            Need := 2;
            if Index + Integer (Need) > Value'Last then
               return Invalid;
            end if;
            if not Continuation (Value (Index + 1))
              or else not Continuation (Value (Index + 2))
            then
               return Invalid;
            end if;
            Index := Index + 3;
         elsif B in 16#F0# .. 16#F4# then
            Need := 3;
            if Index + Integer (Need) > Value'Last then
               return Invalid;
            end if;
            if not Continuation (Value (Index + 1))
              or else not Continuation (Value (Index + 2))
              or else not Continuation (Value (Index + 3))
            then
               return Invalid;
            end if;
            Index := Index + 4;
         else
            return Invalid;
         end if;
      end loop;

      return Valid;
   end Validate;

   function From_String (Value : String) return Identity.Text.Bounded.Bounded_Text is
   begin
      return Identity.Text.Bounded.From_String (Value);
   end From_String;
end Identity.Text.UTF_8;

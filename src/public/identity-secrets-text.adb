with Ada.Streams;
with Identity.Limits;

package body Identity.Secrets.Text is
   function Continuation (Value : Character) return Boolean is
      B : constant Natural := Character'Pos (Value);
   begin
      return B in 16#80# .. 16#BF#;
   end Continuation;

   function Validate_UTF_8 (Value : String) return Secret_Text_Status is
      Index : Integer := Value'First;
      B     : Natural;
      Need  : Natural;
   begin
      if Value'Length > Identity.Limits.Max_Secret_Bytes then
         return Too_Large;
      end if;

      while Index <= Value'Last loop
         B := Character'Pos (Value (Index));
         if B <= 16#7F# then
            Index := Index + 1;
         elsif B in 16#C2# .. 16#DF# then
            Need := 1;
            if Index + Integer (Need) > Value'Last
              or else not Continuation (Value (Index + 1))
            then
               return Invalid_UTF_8;
            end if;
            Index := Index + 2;
         elsif B in 16#E0# .. 16#EF# then
            Need := 2;
            if Index + Integer (Need) > Value'Last
              or else not Continuation (Value (Index + 1))
              or else not Continuation (Value (Index + 2))
            then
               return Invalid_UTF_8;
            end if;
            Index := Index + 3;
         elsif B in 16#F0# .. 16#F4# then
            Need := 3;
            if Index + Integer (Need) > Value'Last
              or else not Continuation (Value (Index + 1))
              or else not Continuation (Value (Index + 2))
              or else not Continuation (Value (Index + 3))
            then
               return Invalid_UTF_8;
            end if;
            Index := Index + 4;
         else
            return Invalid_UTF_8;
         end if;
      end loop;

      return Valid;
   end Validate_UTF_8;

   function From_UTF_8 (Value : String) return Secret_Text is
      Data : Ada.Streams.Stream_Element_Array (1 .. Value'Length);
      Pos  : Ada.Streams.Stream_Element_Offset := Data'First;
   begin
      use type Ada.Streams.Stream_Element_Offset;
      for Ch of Value loop
         Data (Pos) := Character'Pos (Ch);
         Pos := Pos + 1;
      end loop;
      return Identity.Secrets.Bytes.From_Bytes (Data);
   end From_UTF_8;
end Identity.Secrets.Text;

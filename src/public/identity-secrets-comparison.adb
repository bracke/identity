with Ada.Streams;
with Identity.Crypto.Constant_Time;
with Identity.Limits;

package body Identity.Secrets.Comparison is
   function Equal (Left, Right : Identity.Secrets.Bytes.Secret_Bytes) return Boolean is
      Left_Data  : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Right_Data : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Left_Last  : Natural;
      Right_Last : Natural;
   begin
      Identity.Secrets.Bytes.Borrow (Left, Left_Data, Left_Last);
      Identity.Secrets.Bytes.Borrow (Right, Right_Data, Right_Last);
      if Left_Last /= Right_Last then
         return False;
      end if;
      if Left_Last = 0 then
         return True;
      end if;
      return Identity.Crypto.Constant_Time.Equal
        (Left_Data (1 .. Ada.Streams.Stream_Element_Offset (Left_Last)),
         Right_Data (1 .. Ada.Streams.Stream_Element_Offset (Right_Last)));
   end Equal;
end Identity.Secrets.Comparison;

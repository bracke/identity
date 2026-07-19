with CryptoLib.Constant_Time;

package body Identity.Crypto.CryptoLib.Constant_Time is
   function Equal
     (Left_Value  : Ada.Streams.Stream_Element_Array;
      Right_Value : Ada.Streams.Stream_Element_Array) return Boolean is
     (Standard.CryptoLib.Constant_Time.Equal (Left_Value, Right_Value));
end Identity.Crypto.CryptoLib.Constant_Time;

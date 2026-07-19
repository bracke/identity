with Ada.Streams;

package Identity.Crypto.CryptoLib.Constant_Time is
   function Equal
     (Left_Value  : Ada.Streams.Stream_Element_Array;
      Right_Value : Ada.Streams.Stream_Element_Array) return Boolean;
end Identity.Crypto.CryptoLib.Constant_Time;

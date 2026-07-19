with Identity.Text.Bounded;

package Identity.Text.UTF_8 is
   pragma Pure;

   type UTF_8_Status is (Valid, Invalid, Too_Large);

   function Valid_Status (Status : UTF_8_Status) return Boolean is
     (Status = Valid);
   function Invalid_Status (Status : UTF_8_Status) return Boolean is
     (Status = Invalid);
   function Size_Rejected (Status : UTF_8_Status) return Boolean is
     (Status = Too_Large);
   function Rejected (Status : UTF_8_Status) return Boolean is
     (Status in Invalid | Too_Large);

   function Validate (Value : String) return UTF_8_Status;
   function From_String (Value : String) return Identity.Text.Bounded.Bounded_Text
     with Pre => Validate (Value) = Valid;
end Identity.Text.UTF_8;

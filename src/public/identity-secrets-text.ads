with Identity.Secrets.Bytes;

package Identity.Secrets.Text is
   subtype Secret_Text is Identity.Secrets.Bytes.Secret_Bytes;
   type Secret_Text_Status is (Valid, Invalid_UTF_8, Too_Large);

   function Accepted_Input (Status : Secret_Text_Status) return Boolean is
     (Status = Valid);

   function Rejected_Input (Status : Secret_Text_Status) return Boolean is
     (Status /= Valid);

   function Invalid_UTF_8_Rejected
     (Status : Secret_Text_Status) return Boolean is
     (Status = Invalid_UTF_8);

   function Size_Rejected (Status : Secret_Text_Status) return Boolean is
     (Status = Too_Large);

   --  Parses untrusted text, so it is proved rather than reviewed. The rest
   --  of this package is outside SPARK: Secret_Text is a controlled type,
   --  which SPARK does not permit.
   function Validate_UTF_8 (Value : String) return Secret_Text_Status
     with SPARK_Mode => On;

   function From_UTF_8 (Value : String) return Secret_Text
     with Pre => Validate_UTF_8 (Value) = Valid;
end Identity.Secrets.Text;

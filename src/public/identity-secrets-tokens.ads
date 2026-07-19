with Identity.Secrets.Bytes;
with Identity.Limits;

package Identity.Secrets.Tokens is
   subtype Reset_Token_Secret is Identity.Secrets.Bytes.Secret_Bytes;
   subtype Verification_Token_Secret is Identity.Secrets.Bytes.Secret_Bytes;
   type Token_Secret_Status is (Accepted, Absent, Empty, Too_Large);

   function Accepted_Input (Status : Token_Secret_Status) return Boolean is
     (Status = Accepted);

   function Rejected_Input (Status : Token_Secret_Status) return Boolean is
     (Status /= Accepted);

   function Missing_Input (Status : Token_Secret_Status) return Boolean is
     (Status in Absent | Empty);

   function Size_Rejected (Status : Token_Secret_Status) return Boolean is
     (Status = Too_Large);

   function Validate_Reset (Value : Reset_Token_Secret) return Token_Secret_Status is
     (if not Identity.Secrets.Bytes.Is_Present (Value) then Absent
      elsif Identity.Secrets.Bytes.Length (Value) = 0 then Empty
      elsif Identity.Secrets.Bytes.Length (Value) > Identity.Limits.Max_Bearer_Secret_Bytes then Too_Large
      else Accepted);

   function Validate_Verification
     (Value : Verification_Token_Secret) return Token_Secret_Status is
     (if not Identity.Secrets.Bytes.Is_Present (Value) then Absent
      elsif Identity.Secrets.Bytes.Length (Value) = 0 then Empty
      elsif Identity.Secrets.Bytes.Length (Value) > Identity.Limits.Max_Bearer_Secret_Bytes then Too_Large
      else Accepted);
end Identity.Secrets.Tokens;

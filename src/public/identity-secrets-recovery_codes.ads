with Identity.Secrets.Text;
with Identity.Secrets.Bytes;
with Identity.Limits;

package Identity.Secrets.Recovery_Codes is
   subtype Recovery_Code is Identity.Secrets.Text.Secret_Text;
   type Recovery_Code_Status is (Accepted, Absent, Empty, Too_Large);

   function Accepted_Input (Status : Recovery_Code_Status) return Boolean is
     (Status = Accepted);

   function Rejected_Input (Status : Recovery_Code_Status) return Boolean is
     (Status /= Accepted);

   function Missing_Input (Status : Recovery_Code_Status) return Boolean is
     (Status in Absent | Empty);

   function Size_Rejected (Status : Recovery_Code_Status) return Boolean is
     (Status = Too_Large);

   function Validate (Value : Recovery_Code) return Recovery_Code_Status is
     (if not Identity.Secrets.Bytes.Is_Present (Value) then Absent
      elsif Identity.Secrets.Bytes.Length (Value) = 0 then Empty
      elsif Identity.Secrets.Bytes.Length (Value) > Identity.Limits.Max_Recovery_Code_Bytes then Too_Large
      else Accepted);
end Identity.Secrets.Recovery_Codes;

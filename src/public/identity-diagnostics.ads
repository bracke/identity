with Identity.Errors;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Diagnostics is
   pragma Pure;

   type Diagnostic_Record is record
      Id      : Identity.Identifiers.Registry.Registry_Id;
      Error   : Identity.Errors.Error_Value;
      Message : Identity.Text.Bounded.Bounded_Text;
   end record;

   function Failure_Diagnostic (Value : Diagnostic_Record) return Boolean is
     (Identity.Errors.Is_Failure (Value.Error));

   function Success_Diagnostic (Value : Diagnostic_Record) return Boolean is
     (not Failure_Diagnostic (Value));

   function Safe_Image (Value : Diagnostic_Record) return Identity.Text.Bounded.Bounded_Text;
end Identity.Diagnostics;

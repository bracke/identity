with Identity.Identifiers.Operations;
with Identity.Text.Bounded;
with Identity.Times;

package Identity.Authentication.Contexts is
   pragma Pure;

   type Authentication_Context is record
      Operation   : Identity.Identifiers.Operations.Operation_Id;
      Correlation : Identity.Identifiers.Operations.Correlation_Id;
      Requested_At : Identity.Times.Instant := 0;
      Risk_Key    : Identity.Text.Bounded.Bounded_Text;
      Synthetic_Verification_Required : Boolean := True;
   end record;

   function Enumeration_Safe (Value : Authentication_Context) return Boolean is
     (Value.Synthetic_Verification_Required);
end Identity.Authentication.Contexts;

with Identity.Identifiers.Operations;
with Identity.Text.Bounded;

package Identity.Adapters.Transport_Context is
   type Transport_Context is record
      Request : Identity.Identifiers.Operations.Request_Context_Id;
      Risk_Key : Identity.Text.Bounded.Bounded_Text;
      Transport_Name : Identity.Text.Bounded.Bounded_Text;
      Supplies_Bearer_Secret : Boolean := False;
      Owns_Cookie_State       : Boolean := False;
   end record;

   function Core_Neutral (Value : Transport_Context) return Boolean is
     (not Value.Supplies_Bearer_Secret and then not Value.Owns_Cookie_State);
end Identity.Adapters.Transport_Context;

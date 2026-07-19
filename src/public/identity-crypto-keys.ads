with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Crypto.Keys is
   pragma Pure;

   type Key_State is (Active, Verification_Only, Retired, Revoked, Unavailable);

   type Key_Reference is record
      Key_Id : Identity.Text.Bounded.Bounded_Text;
      Domain : Identity.Identifiers.Registry.Registry_Id;
      State  : Key_State := Unavailable;
   end record;

   function Can_Create (Value : Key_Reference) return Boolean is
     (Value.State = Active);
   function Can_Verify (Value : Key_Reference) return Boolean is
     (Value.State in Active | Verification_Only);
end Identity.Crypto.Keys;

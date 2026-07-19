with Identity.Identifiers.Entities;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Verification.Contacts is
   pragma Pure;

   type Contact_Control_State is (Unverified, Verification_Requested, Verified, Reverification_Required);

   function Unverified_State (State : Contact_Control_State) return Boolean is
     (State = Unverified);

   function Verification_Requested_State
     (State : Contact_Control_State) return Boolean is
     (State = Verification_Requested);

   function Verified_State (State : Contact_Control_State) return Boolean is
     (State = Verified);

   function Reverification_Required_State
     (State : Contact_Control_State) return Boolean is
     (State = Reverification_Required);

   function Needs_Verification (State : Contact_Control_State) return Boolean is
     (State in Unverified | Reverification_Required);

   function Request_In_Flight (State : Contact_Control_State) return Boolean is
     (State = Verification_Requested);

   type Contact_Verification_Binding is record
      Contact_Binding : Identity.Identifiers.Entities.Contact_Binding_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Normalized_Value : Identity.Text.Bounded.Bounded_Text;
      Binding_Version : Identity.Versions.Entity_Version := 0;
      State           : Contact_Control_State := Unverified;
   end record;
end Identity.Verification.Contacts;

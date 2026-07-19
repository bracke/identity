with Identity.Contacts.Bindings;

package Identity.Contacts.Verification_State is
   pragma Pure;
   use type Identity.Contacts.Bindings.Contact_Binding_State;

   subtype Contact_Binding_State is Identity.Contacts.Bindings.Contact_Binding_State;

   function Verified (State : Contact_Binding_State) return Boolean is
     (State = Identity.Contacts.Bindings.Verified);

   function Verified
     (Binding : Identity.Contacts.Bindings.Contact_Binding_Projection)
      return Boolean is
     (Verified (Binding.State));

   function Mutable (State : Contact_Binding_State) return Boolean is
     (State in Identity.Contacts.Bindings.Pending_Verification | Identity.Contacts.Bindings.Verified);

   function Mutable
     (Binding : Identity.Contacts.Bindings.Contact_Binding_Projection)
      return Boolean is
     (Mutable (Binding.State));
end Identity.Contacts.Verification_State;

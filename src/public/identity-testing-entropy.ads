with Identity.Crypto.Capabilities;

package Identity.Testing.Entropy is
   use type Identity.Crypto.Capabilities.Capability_State;

   type Entropy_Script is record
      Available : Identity.Crypto.Capabilities.Capability_State :=
        Identity.Crypto.Capabilities.Available;
      Counter   : Natural := 0;
      Fail_Next : Boolean := False;
   end record;

   function Can_Generate (Value : Entropy_Script) return Boolean is
     (Value.Available = Identity.Crypto.Capabilities.Available and then not Value.Fail_Next);
end Identity.Testing.Entropy;

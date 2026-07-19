with Identity.Crypto.Capabilities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Crypto.MACs is
   pragma Pure;

   type MAC_Result is record
      Capability : Identity.Crypto.Capabilities.Capability_State :=
        Identity.Crypto.Capabilities.Missing;
      Algorithm  : Identity.Identifiers.Registry.Registry_Id;
      Output     : Identity.Text.Bounded.Bounded_Text;
   end record;

   function Unsupported
     (Algorithm : Identity.Identifiers.Registry.Registry_Id) return MAC_Result;
end Identity.Crypto.MACs;

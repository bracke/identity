package body Identity.Crypto.MACs is
   function Unsupported
     (Algorithm : Identity.Identifiers.Registry.Registry_Id) return MAC_Result
   is
   begin
      return
        (Capability => Identity.Crypto.Capabilities.Missing,
         Algorithm => Algorithm,
         Output => Identity.Text.Bounded.From_String (""));
   end Unsupported;
end Identity.Crypto.MACs;

package body Identity.Crypto.CryptoLib.MACs is
   function Unsupported
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.MACs.MAC_Result is
   begin
      return Identity.Crypto.MACs.Unsupported (Algorithm);
   end Unsupported;
end Identity.Crypto.CryptoLib.MACs;

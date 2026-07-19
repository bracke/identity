with Identity.Crypto.MACs;
with Identity.Identifiers.Registry;

package Identity.Crypto.CryptoLib.MACs is
   pragma Pure;

   function Unsupported
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.MACs.MAC_Result;
end Identity.Crypto.CryptoLib.MACs;

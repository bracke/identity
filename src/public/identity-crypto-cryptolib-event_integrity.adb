with Identity.Crypto.CryptoLib.MACs;

package body Identity.Crypto.CryptoLib.Event_Integrity is
   --  Event integrity tags are HMACs, so the service is configured exactly
   --  when the MAC adapter can produce them.
   function Service
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.Event_Integrity.Event_Integrity_Service is
     ((Capability =>
         Identity.Crypto.CryptoLib.MACs.Capability
           (Identity.Crypto.CryptoLib.MACs.HMAC_SHA256_Algorithm),
       Algorithm => Algorithm));
end Identity.Crypto.CryptoLib.Event_Integrity;

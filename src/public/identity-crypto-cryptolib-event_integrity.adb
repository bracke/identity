with Identity.Crypto.Capabilities;

package body Identity.Crypto.CryptoLib.Event_Integrity is
   function Service
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.Event_Integrity.Event_Integrity_Service is
     ((Capability => Identity.Crypto.Capabilities.Missing,
       Algorithm => Algorithm));
end Identity.Crypto.CryptoLib.Event_Integrity;

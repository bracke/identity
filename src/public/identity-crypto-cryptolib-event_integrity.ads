with Identity.Crypto.Event_Integrity;
with Identity.Identifiers.Registry;

package Identity.Crypto.CryptoLib.Event_Integrity is
   pragma Pure;

   function Service
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.Event_Integrity.Event_Integrity_Service;
end Identity.Crypto.CryptoLib.Event_Integrity;

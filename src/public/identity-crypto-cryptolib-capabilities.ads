with Identity.Crypto.Capabilities;

package Identity.Crypto.CryptoLib.Capabilities is
   --  Probes the bound cryptolib primitives and reports what is actually
   --  usable at run time. Nothing here is declared Available on the strength
   --  of configuration alone -- each field is established by exercising the
   --  primitive it describes.
   function Current
     return Identity.Crypto.Capabilities.Crypto_Capability_Set;
end Identity.Crypto.CryptoLib.Capabilities;

with Ada.Streams;
with Identity.Crypto.Capabilities;
with Identity.Crypto.MACs;
with Identity.Identifiers.Registry;

package Identity.Crypto.CryptoLib.MACs is
   --  Registry identifier of the one MAC primitive V1 binds.
   function HMAC_SHA256_Algorithm return Identity.Identifiers.Registry.Registry_Id;

   subtype HMAC_SHA256_Tag is Ada.Streams.Stream_Element_Array (1 .. 32);

   function HMAC_SHA256
     (Key  : Ada.Streams.Stream_Element_Array;
      Data : Ada.Streams.Stream_Element_Array) return HMAC_SHA256_Tag;

   --  Available only for algorithms this adapter actually implements.
   function Capability
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.Capabilities.Capability_State;

   --  Compute a MAC and report it as a hex-encoded MAC_Result. Algorithms the
   --  adapter does not implement yield an explicit Missing-capability result.
   function Compute
     (Algorithm : Identity.Identifiers.Registry.Registry_Id;
      Key       : Ada.Streams.Stream_Element_Array;
      Data      : Ada.Streams.Stream_Element_Array)
      return Identity.Crypto.MACs.MAC_Result;

   function Unsupported
     (Algorithm : Identity.Identifiers.Registry.Registry_Id)
      return Identity.Crypto.MACs.MAC_Result;
end Identity.Crypto.CryptoLib.MACs;

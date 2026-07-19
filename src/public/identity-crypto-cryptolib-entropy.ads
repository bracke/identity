with Ada.Streams;
with Identity.Crypto.Capabilities;
with Identity.Crypto.Entropy;

package Identity.Crypto.CryptoLib.Entropy is
   --  Entropy source backed by the operating-system CSPRNG (getrandom(2) on
   --  Linux, getentropy(2) on macOS, BCryptGenRandom on Windows). Fails closed:
   --  a False result leaves Buffer zeroed and callers must not use it.
   type OS_Source is
     limited new Identity.Crypto.Entropy.Entropy_Source with null record;

   overriding function Fill
     (Source : in out OS_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean;

   --  Always-failing source, retained so the fail-closed path stays testable.
   type Unavailable_Source is
     limited new Identity.Crypto.Entropy.Entropy_Source with null record;

   overriding function Fill
     (Source : in out Unavailable_Source;
      Buffer : out Ada.Streams.Stream_Element_Array) return Boolean;

   --  Fill Buffer from the OS CSPRNG without needing a source object.
   --  Returns False and zeroes Buffer when no OS entropy is available.
   function Fill_Bytes
     (Buffer : out Ada.Streams.Stream_Element_Array) return Boolean;

   --  Probes the OS CSPRNG; Available only when it actually yields bytes.
   function Capability return Identity.Crypto.Capabilities.Capability_State;
end Identity.Crypto.CryptoLib.Entropy;

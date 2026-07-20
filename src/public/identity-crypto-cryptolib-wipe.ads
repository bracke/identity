with System;

package Identity.Crypto.CryptoLib.Wipe is
   --  Non-elidable zeroization of secret memory.
   --
   --  Assigning zeroes to an object whose lifetime is about to end is a dead
   --  store, and an optimizing compiler is entitled to delete it -- so the
   --  scrubbing that secret containers rely on can silently not happen in a
   --  release build. This routine writes through volatile stores, which the
   --  compiler may not elide.
   procedure Scrub (Address : System.Address; Length : Natural);
end Identity.Crypto.CryptoLib.Wipe;

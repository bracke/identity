with Ada.Streams;

package Identity.Crypto.CryptoLib.Secret_Box is
   --  Authenticated encryption of a small secret at rest (AES-256-GCM).
   --
   --  Some secrets cannot be stored one-way. A TOTP shared secret is symmetric:
   --  verification recomputes the code from it, so it must be recoverable. This
   --  seals such a secret under a caller-supplied key so the stored form is
   --  ciphertext with an integrity tag, not the secret itself and not a hash of
   --  it that could never verify.

   Key_Length : constant := 32;   --  AES-256
   subtype Key_Bytes is Ada.Streams.Stream_Element_Array (1 .. Key_Length);

   Max_Secret_Length : constant := 64;
   --  A sealed box is the 12-byte nonce, the ciphertext (same length as the
   --  plaintext), and a 16-byte tag.
   Overhead : constant := 12 + 16;
   Max_Box_Length : constant := Max_Secret_Length + Overhead;

   subtype Box_Length_Range is Ada.Streams.Stream_Element_Offset
     range 0 .. Max_Box_Length;

   type Seal_Status is (Sealed, Seal_Failed);

   type Sealed_Secret (Length : Box_Length_Range := 0) is record
      Status : Seal_Status := Seal_Failed;
      Data   : Ada.Streams.Stream_Element_Array (1 .. Length) := [others => 0];
   end record;

   type Open_Status is (Opened, Tag_Rejected, Malformed);

   type Opened_Secret (Length : Box_Length_Range := 0) is record
      Status : Open_Status := Malformed;
      Data   : Ada.Streams.Stream_Element_Array (1 .. Length) := [others => 0];
   end record;

   --  Seal Secret under Key. Nonce must be 12 random bytes, unique per key; the
   --  caller supplies it (drawn from the OS CSPRNG) and it is stored inside the
   --  sealed box so Open needs only the key.
   function Seal
     (Key    : Key_Bytes;
      Nonce  : Ada.Streams.Stream_Element_Array;
      Secret : Ada.Streams.Stream_Element_Array) return Sealed_Secret
     with Pre => Nonce'Length = 12 and then Secret'Length <= Max_Secret_Length;

   --  Recover the secret; Tag_Rejected on a wrong key or tampered box.
   function Open
     (Key : Key_Bytes;
      Box : Ada.Streams.Stream_Element_Array) return Opened_Secret;
end Identity.Crypto.CryptoLib.Secret_Box;

with Identity.Crypto.CryptoLib.Wipe;

package body Identity.Secrets.Bytes is
   function From_Bytes (Value : Ada.Streams.Stream_Element_Array) return Secret_Bytes is
      Result : Secret_Bytes;
      Cursor : Natural := 1;
   begin
      Result.Present := True;
      Result.Used := Value'Length;
      for Item of Value loop
         Result.Data (Cursor) := Item;
         Cursor := Cursor + 1;
      end loop;
      return Result;
   end From_Bytes;

   function Length (Value : Secret_Bytes) return Natural is
     (Value.Used);

   function Is_Present (Value : Secret_Bytes) return Boolean is
     (Value.Present);

   procedure Clear (Value : in out Secret_Bytes) is
   begin
      --  Scrubbed through volatile stores rather than by assigning zeroes.
      --  This runs from Finalize, i.e. when the object is already dead, and a
      --  dead store is exactly what an optimizing compiler deletes -- so the
      --  plain assignment could leave the secret in memory in a release build.
      Identity.Crypto.CryptoLib.Wipe.Scrub
        (Value.Data'Address, Value.Data'Length);
      Value.Used := 0;
      Value.Present := False;
   end Clear;

   procedure Borrow
     (Value : Secret_Bytes;
      Data  : out Ada.Streams.Stream_Element_Array;
      Last  : out Natural)
   is
      Cursor : Natural := 1;
   begin
      Data := [others => 0];
      Last := Value.Used;
      for Index in Data'Range loop
         exit when Cursor > Value.Used;
         Data (Index) := Value.Data (Cursor);
         Cursor := Cursor + 1;
      end loop;
   end Borrow;

   function Redacted_Image (Value : Secret_Bytes) return String is
      pragma Unreferenced (Value);
   begin
      return "[identity-secret:redacted]";
   end Redacted_Image;

   overriding procedure Finalize (Value : in out Secret_Bytes) is
   begin
      Clear (Value);
   exception
      when others =>
         null;
   end Finalize;
end Identity.Secrets.Bytes;

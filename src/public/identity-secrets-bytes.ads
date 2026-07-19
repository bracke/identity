with Ada.Finalization;
with Ada.Streams;
with Identity.Limits;

package Identity.Secrets.Bytes is
   type Secret_Bytes is new Ada.Finalization.Controlled with private;

   function From_Bytes (Value : Ada.Streams.Stream_Element_Array) return Secret_Bytes
     with Pre => Value'Length <= Identity.Limits.Max_Secret_Bytes;
   function Is_Present (Value : Secret_Bytes) return Boolean;
   function Length (Value : Secret_Bytes) return Natural;
   procedure Clear (Value : in out Secret_Bytes);
   procedure Borrow
     (Value : Secret_Bytes;
      Data  : out Ada.Streams.Stream_Element_Array;
      Last  : out Natural)
     with Pre => Data'Length <= Identity.Limits.Max_Secret_Bytes;
   function Redacted_Image (Value : Secret_Bytes) return String;

   overriding procedure Finalize (Value : in out Secret_Bytes);

private
   subtype Buffer_Index is Positive range 1 .. Identity.Limits.Max_Secret_Bytes;
   type Buffer is array (Buffer_Index) of Ada.Streams.Stream_Element;

   type Secret_Bytes is new Ada.Finalization.Controlled with record
      Present : Boolean := False;
      Used    : Natural range 0 .. Identity.Limits.Max_Secret_Bytes := 0;
      Data    : Buffer := [others => 0];
   end record;
end Identity.Secrets.Bytes;

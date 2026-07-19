with Identity.Limits;

package Identity.Identifiers.Registry is
   pragma Pure;

   subtype Registry_Id_Length is Natural range 0 .. Identity.Limits.Max_Registry_Id_Bytes;
   subtype Registry_Id_Text is String (1 .. Identity.Limits.Max_Registry_Id_Bytes);

   type Registry_Id is private;

   function From_String (Value : String) return Registry_Id
     with Pre => Value'Length in 1 .. Identity.Limits.Max_Registry_Id_Bytes;
   function Image (Value : Registry_Id) return String;
   function Is_Valid (Value : String) return Boolean;
   function Is_Valid (Value : Registry_Id) return Boolean;

private
   type Registry_Id is record
      Length : Registry_Id_Length := 0;
      Text   : Registry_Id_Text := [others => Character'Val (0)];
   end record;
end Identity.Identifiers.Registry;

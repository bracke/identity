package Identity.Identifiers is
   pragma Pure;

   subtype Identifier_Text is String (1 .. 36);

   type Encoded_Identifier is private;

   function From_String (Value : String) return Encoded_Identifier
     with Pre => Value'Length = Identifier_Text'Length;

   function Image (Value : Encoded_Identifier) return String;
   function Is_Valid_Text (Value : String) return Boolean;

private
   type Encoded_Identifier is record
      Text : Identifier_Text := [others => '0'];
   end record;
end Identity.Identifiers;

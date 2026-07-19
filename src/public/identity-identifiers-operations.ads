package Identity.Identifiers.Operations is
   pragma Pure;

   type Operation_Id is private;
   type Correlation_Id is private;
   type Causation_Id is private;
   type Request_Context_Id is private;

   function Operation (Value : Identity.Identifiers.Encoded_Identifier) return Operation_Id;
   function Correlation (Value : Identity.Identifiers.Encoded_Identifier) return Correlation_Id;
   function Causation (Value : Identity.Identifiers.Encoded_Identifier) return Causation_Id;
   function Request_Context (Value : Identity.Identifiers.Encoded_Identifier) return Request_Context_Id;

   function To_String (Value : Operation_Id) return String;
   function To_String (Value : Correlation_Id) return String;
   function To_String (Value : Causation_Id) return String;
   function To_String (Value : Request_Context_Id) return String;

private
   type Operation_Id is new Identity.Identifiers.Encoded_Identifier;
   type Correlation_Id is new Identity.Identifiers.Encoded_Identifier;
   type Causation_Id is new Identity.Identifiers.Encoded_Identifier;
   type Request_Context_Id is new Identity.Identifiers.Encoded_Identifier;
end Identity.Identifiers.Operations;

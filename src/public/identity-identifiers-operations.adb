package body Identity.Identifiers.Operations is
   function Operation (Value : Identity.Identifiers.Encoded_Identifier) return Operation_Id is
     (Operation_Id (Value));
   function Correlation (Value : Identity.Identifiers.Encoded_Identifier) return Correlation_Id is
     (Correlation_Id (Value));
   function Causation (Value : Identity.Identifiers.Encoded_Identifier) return Causation_Id is
     (Causation_Id (Value));
   function Request_Context (Value : Identity.Identifiers.Encoded_Identifier) return Request_Context_Id is
     (Request_Context_Id (Value));

   function To_String (Value : Operation_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));

   function To_String (Value : Correlation_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));

   function To_String (Value : Causation_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));

   function To_String (Value : Request_Context_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
end Identity.Identifiers.Operations;

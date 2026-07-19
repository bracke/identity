package body Identity.Identifiers.Entities is
   function Principal (Value : Identity.Identifiers.Encoded_Identifier) return Principal_Id is
     (Principal_Id (Value));
   function Account (Value : Identity.Identifiers.Encoded_Identifier) return Account_Id is
     (Account_Id (Value));
   function Identity_Binding (Value : Identity.Identifiers.Encoded_Identifier) return Identity_Binding_Id is
     (Identity_Binding_Id (Value));
   function Contact_Binding (Value : Identity.Identifiers.Encoded_Identifier) return Contact_Binding_Id is
     (Contact_Binding_Id (Value));
   function Credential (Value : Identity.Identifiers.Encoded_Identifier) return Credential_Id is
     (Credential_Id (Value));
   function Credential_Set (Value : Identity.Identifiers.Encoded_Identifier) return Credential_Set_Id is
     (Credential_Set_Id (Value));
   function Session (Value : Identity.Identifiers.Encoded_Identifier) return Session_Id is
     (Session_Id (Value));
   function Session_Family (Value : Identity.Identifiers.Encoded_Identifier) return Session_Family_Id is
     (Session_Family_Id (Value));
   function Token (Value : Identity.Identifiers.Encoded_Identifier) return Token_Id is
     (Token_Id (Value));
   function Attempt (Value : Identity.Identifiers.Encoded_Identifier) return Attempt_Id is
     (Attempt_Id (Value));
   function Authentication_Transaction
     (Value : Identity.Identifiers.Encoded_Identifier) return Authentication_Transaction_Id is
     (Authentication_Transaction_Id (Value));
   function Challenge (Value : Identity.Identifiers.Encoded_Identifier) return Challenge_Id is
     (Challenge_Id (Value));
   function Evidence (Value : Identity.Identifiers.Encoded_Identifier) return Evidence_Id is
     (Evidence_Id (Value));
   function External_Binding (Value : Identity.Identifiers.Encoded_Identifier) return External_Binding_Id is
     (External_Binding_Id (Value));
   function External_Provider (Value : Identity.Identifiers.Encoded_Identifier) return External_Provider_Id is
     (External_Provider_Id (Value));
   function Event (Value : Identity.Identifiers.Encoded_Identifier) return Event_Id is
     (Event_Id (Value));

   function To_String (Value : Principal_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Account_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Identity_Binding_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Contact_Binding_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Credential_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Credential_Set_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Session_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Session_Family_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Token_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Attempt_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Authentication_Transaction_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Challenge_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Evidence_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : External_Binding_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : External_Provider_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
   function To_String (Value : Event_Id) return String is
     (Identity.Identifiers.Image (Identity.Identifiers.Encoded_Identifier (Value)));
end Identity.Identifiers.Entities;

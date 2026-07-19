package Identity.Identifiers.Entities is
   pragma Pure;

   type Principal_Id is private;
   type Account_Id is private;
   type Identity_Binding_Id is private;
   type Contact_Binding_Id is private;
   type Credential_Id is private;
   type Credential_Set_Id is private;
   type Session_Id is private;
   type Session_Family_Id is private;
   type Token_Id is private;
   type Attempt_Id is private;
   type Authentication_Transaction_Id is private;
   type Challenge_Id is private;
   type Evidence_Id is private;
   type External_Binding_Id is private;
   type External_Provider_Id is private;
   type Event_Id is private;

   function Principal (Value : Identity.Identifiers.Encoded_Identifier) return Principal_Id;
   function Account (Value : Identity.Identifiers.Encoded_Identifier) return Account_Id;
   function Identity_Binding (Value : Identity.Identifiers.Encoded_Identifier) return Identity_Binding_Id;
   function Contact_Binding (Value : Identity.Identifiers.Encoded_Identifier) return Contact_Binding_Id;
   function Credential (Value : Identity.Identifiers.Encoded_Identifier) return Credential_Id;
   function Credential_Set (Value : Identity.Identifiers.Encoded_Identifier) return Credential_Set_Id;
   function Session (Value : Identity.Identifiers.Encoded_Identifier) return Session_Id;
   function Session_Family (Value : Identity.Identifiers.Encoded_Identifier) return Session_Family_Id;
   function Token (Value : Identity.Identifiers.Encoded_Identifier) return Token_Id;
   function Attempt (Value : Identity.Identifiers.Encoded_Identifier) return Attempt_Id;
   function Authentication_Transaction
     (Value : Identity.Identifiers.Encoded_Identifier) return Authentication_Transaction_Id;
   function Challenge (Value : Identity.Identifiers.Encoded_Identifier) return Challenge_Id;
   function Evidence (Value : Identity.Identifiers.Encoded_Identifier) return Evidence_Id;
   function External_Binding (Value : Identity.Identifiers.Encoded_Identifier) return External_Binding_Id;
   function External_Provider (Value : Identity.Identifiers.Encoded_Identifier) return External_Provider_Id;
   function Event (Value : Identity.Identifiers.Encoded_Identifier) return Event_Id;

   function To_String (Value : Principal_Id) return String;
   function To_String (Value : Account_Id) return String;
   function To_String (Value : Identity_Binding_Id) return String;
   function To_String (Value : Contact_Binding_Id) return String;
   function To_String (Value : Credential_Id) return String;
   function To_String (Value : Credential_Set_Id) return String;
   function To_String (Value : Session_Id) return String;
   function To_String (Value : Session_Family_Id) return String;
   function To_String (Value : Token_Id) return String;
   function To_String (Value : Attempt_Id) return String;
   function To_String (Value : Authentication_Transaction_Id) return String;
   function To_String (Value : Challenge_Id) return String;
   function To_String (Value : Evidence_Id) return String;
   function To_String (Value : External_Binding_Id) return String;
   function To_String (Value : External_Provider_Id) return String;
   function To_String (Value : Event_Id) return String;

private
   type Principal_Id is new Identity.Identifiers.Encoded_Identifier;
   type Account_Id is new Identity.Identifiers.Encoded_Identifier;
   type Identity_Binding_Id is new Identity.Identifiers.Encoded_Identifier;
   type Contact_Binding_Id is new Identity.Identifiers.Encoded_Identifier;
   type Credential_Id is new Identity.Identifiers.Encoded_Identifier;
   type Credential_Set_Id is new Identity.Identifiers.Encoded_Identifier;
   type Session_Id is new Identity.Identifiers.Encoded_Identifier;
   type Session_Family_Id is new Identity.Identifiers.Encoded_Identifier;
   type Token_Id is new Identity.Identifiers.Encoded_Identifier;
   type Attempt_Id is new Identity.Identifiers.Encoded_Identifier;
   type Authentication_Transaction_Id is new Identity.Identifiers.Encoded_Identifier;
   type Challenge_Id is new Identity.Identifiers.Encoded_Identifier;
   type Evidence_Id is new Identity.Identifiers.Encoded_Identifier;
   type External_Binding_Id is new Identity.Identifiers.Encoded_Identifier;
   type External_Provider_Id is new Identity.Identifiers.Encoded_Identifier;
   type Event_Id is new Identity.Identifiers.Encoded_Identifier;
end Identity.Identifiers.Entities;

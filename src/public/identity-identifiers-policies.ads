package Identity.Identifiers.Policies is
   pragma Pure;

   type Policy_Set_Id is private;
   type Policy_Version is range 1 .. 2**31 - 1;

   function Policy_Set (Value : Identity.Identifiers.Encoded_Identifier) return Policy_Set_Id;

private
   type Policy_Set_Id is new Identity.Identifiers.Encoded_Identifier;
end Identity.Identifiers.Policies;

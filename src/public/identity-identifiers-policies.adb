package body Identity.Identifiers.Policies is
   function Policy_Set (Value : Identity.Identifiers.Encoded_Identifier) return Policy_Set_Id is
     (Policy_Set_Id (Value));
end Identity.Identifiers.Policies;

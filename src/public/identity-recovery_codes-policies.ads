with Identity.Recovery_Codes.Sets;

package Identity.Recovery_Codes.Policies is
   pragma Pure;

   type Recovery_Code_Policy is record
      Active_Set_Size : Natural range 1 .. Identity.Recovery_Codes.Sets.Max_Codes_Per_Set := 10;
      Display_Only_Once : Boolean := True;
      Replace_Set_On_Regeneration : Boolean := True;
      Reduced_Assurance_By_Default : Boolean := True;
   end record;

   type Recovery_Code_Policy_Validation_Status is
     (Recovery_Code_Policy_Valid,
      Recovery_Code_Display_Not_One_Time,
      Recovery_Code_Regeneration_Does_Not_Replace_Set,
      Recovery_Code_Assurance_Not_Reduced);

   function Validate
     (Value : Recovery_Code_Policy) return Recovery_Code_Policy_Validation_Status is
     (if not Value.Display_Only_Once then
         Recovery_Code_Display_Not_One_Time
      elsif not Value.Replace_Set_On_Regeneration then
         Recovery_Code_Regeneration_Does_Not_Replace_Set
      elsif not Value.Reduced_Assurance_By_Default then
         Recovery_Code_Assurance_Not_Reduced
      else
         Recovery_Code_Policy_Valid);

   function Validation_Accepted
     (Status : Recovery_Code_Policy_Validation_Status) return Boolean is
     (Status = Recovery_Code_Policy_Valid);

   function Display_Rejected
     (Status : Recovery_Code_Policy_Validation_Status) return Boolean is
     (Status = Recovery_Code_Display_Not_One_Time);

   function Regeneration_Rejected
     (Status : Recovery_Code_Policy_Validation_Status) return Boolean is
     (Status = Recovery_Code_Regeneration_Does_Not_Replace_Set);

   function Assurance_Rejected
     (Status : Recovery_Code_Policy_Validation_Status) return Boolean is
     (Status = Recovery_Code_Assurance_Not_Reduced);

   function Valid (Value : Recovery_Code_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Recovery_Codes.Policies;

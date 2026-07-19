package body Identity.Passwords.History is
   function Check_Admission
     (Policy : History_Policy;
      Loaded_Record_Count : History_Depth) return History_Check_Status
   is
   begin
      if Loaded_Record_Count > Policy.Maximum_Verifications then
         return Work_Limit_Exceeded;
      end if;

      return Allowed;
   end Check_Admission;

   function Evaluate_Record
     (Item           : History_Record;
      Reuse_Detected : Boolean) return History_Check_Status
   is
   begin
      if Item.Malformed then
         return Malformed_History;
      elsif Reuse_Detected then
         return Reused;
      else
         return Allowed;
      end if;
   end Evaluate_Record;
end Identity.Passwords.History;

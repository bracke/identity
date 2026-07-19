with Identity.Limits;
with Identity.Text.Bounded;

package Identity.Passwords.History is
   pragma Pure;

   subtype History_Depth is Natural range 0 .. Identity.Limits.Max_Password_History_Checks;
   type History_Check_Status is
     (Allowed,
      Reused,
      Malformed_History,
      Work_Limit_Exceeded);

   type History_Policy is record
      Depth : History_Depth := 8;
      Maximum_Verifications : History_Depth := 8;
   end record;

   type History_Policy_Validation_Status is
     (History_Policy_Valid,
      History_Verifications_Exceed_Depth);

   function Validate
     (Policy : History_Policy) return History_Policy_Validation_Status is
     (if Policy.Maximum_Verifications > Policy.Depth then
        History_Verifications_Exceed_Depth
      else
        History_Policy_Valid);

   function Validation_Accepted
     (Status : History_Policy_Validation_Status) return Boolean is
     (Status = History_Policy_Valid);

   function Verification_Budget_Rejected
     (Status : History_Policy_Validation_Status) return Boolean is
     (Status = History_Verifications_Exceed_Depth);

   function Valid (Policy : History_Policy) return Boolean is
     (Validation_Accepted (Validate (Policy)));

   type History_Record is record
      Verifier : Identity.Text.Bounded.Bounded_Text;
      Malformed : Boolean := False;
   end record;

   function Check_Admission
     (Policy : History_Policy;
      Loaded_Record_Count : History_Depth) return History_Check_Status;

   function Evaluate_Record
     (Item           : History_Record;
      Reuse_Detected : Boolean) return History_Check_Status;

   function History_Allowed
     (Status : History_Check_Status) return Boolean is
     (Status = Allowed);

   function Reuse_Rejected
     (Status : History_Check_Status) return Boolean is
     (Status = Reused);

   function Malformed_History_Rejected
     (Status : History_Check_Status) return Boolean is
     (Status = Malformed_History);

   function Work_Limit_Rejected
     (Status : History_Check_Status) return Boolean is
     (Status = Work_Limit_Exceeded);

   function No_Credential_Replacement
     (Status : History_Check_Status) return Boolean is
     (Status in Reused | Malformed_History | Work_Limit_Exceeded);
end Identity.Passwords.History;

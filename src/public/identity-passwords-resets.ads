package Identity.Passwords.Resets is
   pragma Pure;

   type Reset_Supersession_Policy is (Keep_Existing, Supersede_Prior_Unconsumed);
   type Reset_Session_Consequence is (Keep_Sessions, Revoke_Credential_Sessions, Revoke_All_Principal_Sessions);

   type Reset_Policy is record
      Supersession : Reset_Supersession_Policy := Supersede_Prior_Unconsumed;
      Sessions     : Reset_Session_Consequence := Revoke_Credential_Sessions;
      Clear_Administrative_Restrictions : Boolean := False;
   end record;

   type Reset_Policy_Validation_Status is
     (Reset_Policy_Valid,
      Reset_Clears_Administrative_Restrictions,
      Reset_Session_Consequence_Missing);

   function Revokes_Sessions (Value : Reset_Session_Consequence) return Boolean is
     (Value in Revoke_Credential_Sessions | Revoke_All_Principal_Sessions);

   function Validate
     (Value : Reset_Policy) return Reset_Policy_Validation_Status is
     (if Value.Clear_Administrative_Restrictions then
        Reset_Clears_Administrative_Restrictions
      elsif not Revokes_Sessions (Value.Sessions) then
        Reset_Session_Consequence_Missing
      else
        Reset_Policy_Valid);

   function Validation_Accepted
     (Status : Reset_Policy_Validation_Status) return Boolean is
     (Status = Reset_Policy_Valid);

   function Administrative_Clear_Rejected
     (Status : Reset_Policy_Validation_Status) return Boolean is
     (Status = Reset_Clears_Administrative_Restrictions);

   function Session_Consequence_Rejected
     (Status : Reset_Policy_Validation_Status) return Boolean is
     (Status = Reset_Session_Consequence_Missing);

   function Valid (Value : Reset_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Passwords.Resets;

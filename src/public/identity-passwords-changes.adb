package body Identity.Passwords.Changes is
   function Admission
     (Authority : Password_Change_Authority;
      Minimum   : Identity.Assurance.Levels.Assurance_Level)
      return Password_Change_Admission_Status
   is
      use type Identity.Assurance.Levels.Assurance_Level;
   begin
      if not Authority.Authenticated then
         return Password_Change_Unauthenticated;
      elsif not Authority.Recent_Authentication then
         return Password_Change_Not_Recent;
      elsif Authority.Assurance < Minimum then
         return Password_Change_Insufficient_Assurance;
      elsif Authority.Recovery_Restricted then
         return Password_Change_Recovery_Restricted;
      else
         return Password_Change_Admitted;
      end if;
   end Admission;

   function May_Change
     (Authority : Password_Change_Authority;
      Minimum   : Identity.Assurance.Levels.Assurance_Level) return Boolean
   is (Admission_Accepted (Admission (Authority, Minimum)));
end Identity.Passwords.Changes;

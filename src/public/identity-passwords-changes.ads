with Identity.Assurance.Levels;

package Identity.Passwords.Changes is
   pragma Pure;

   type Password_Change_Authority is record
      Authenticated : Boolean := False;
      Recent_Authentication : Boolean := False;
      Assurance : Identity.Assurance.Levels.Assurance_Level := Identity.Assurance.Levels.Basic;
      Current_Password_Required : Boolean := True;
      Recovery_Restricted : Boolean := False;
   end record;

   type Password_Change_Admission_Status is
     (Password_Change_Admitted,
      Password_Change_Unauthenticated,
      Password_Change_Not_Recent,
      Password_Change_Insufficient_Assurance,
      Password_Change_Recovery_Restricted);

   function Admission
     (Authority : Password_Change_Authority;
      Minimum   : Identity.Assurance.Levels.Assurance_Level)
      return Password_Change_Admission_Status;

   function Admission_Accepted
     (Status : Password_Change_Admission_Status) return Boolean is
     (Status = Password_Change_Admitted);

   function Admission_Rejected
     (Status : Password_Change_Admission_Status) return Boolean is
     (Status /= Password_Change_Admitted);

   function Unauthenticated_Rejection
     (Status : Password_Change_Admission_Status) return Boolean is
     (Status = Password_Change_Unauthenticated);

   function Recent_Authentication_Rejection
     (Status : Password_Change_Admission_Status) return Boolean is
     (Status = Password_Change_Not_Recent);

   function Assurance_Rejection
     (Status : Password_Change_Admission_Status) return Boolean is
     (Status = Password_Change_Insufficient_Assurance);

   function Recovery_Restriction_Rejection
     (Status : Password_Change_Admission_Status) return Boolean is
     (Status = Password_Change_Recovery_Restricted);

   function May_Change
     (Authority : Password_Change_Authority;
      Minimum   : Identity.Assurance.Levels.Assurance_Level) return Boolean;
end Identity.Passwords.Changes;

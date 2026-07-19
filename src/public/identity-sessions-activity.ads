with Identity.Sessions.Definitions;
with Identity.Times;

package Identity.Sessions.Activity is
   pragma Pure;

   type Activity_Admission_Status is
     (Admitted,
      Idle_Expired,
      Absolute_Expired,
      Revoked,
      Invalid_Idle_Extension);

   function Admit_Update
     (Session         : Identity.Sessions.Definitions.Session_Record;
      Now             : Identity.Times.Instant;
      Idle_Expires_At : Identity.Times.Expiration) return Activity_Admission_Status;

   function Activity_Update_Admitted
     (Status : Activity_Admission_Status) return Boolean is
     (Status = Admitted);

   function Activity_Update_Rejected
     (Status : Activity_Admission_Status) return Boolean is
     (Status /= Admitted);

   function Expiration_Rejected
     (Status : Activity_Admission_Status) return Boolean is
     (Status in Idle_Expired | Absolute_Expired);

   function Idle_Expiration_Rejected
     (Status : Activity_Admission_Status) return Boolean is
     (Status = Idle_Expired);

   function Absolute_Expiration_Rejected
     (Status : Activity_Admission_Status) return Boolean is
     (Status = Absolute_Expired);

   function Revocation_Rejected
     (Status : Activity_Admission_Status) return Boolean is
     (Status = Revoked);

   function Invalid_Extension_Rejected
     (Status : Activity_Admission_Status) return Boolean is
     (Status = Invalid_Idle_Extension);

   function No_Activity_Mutation
     (Status : Activity_Admission_Status) return Boolean is
     (Status /= Admitted);

   function May_Update_Activity
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Boolean;
end Identity.Sessions.Activity;

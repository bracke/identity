with Identity.Sessions.Expiration;

package body Identity.Sessions.Activity is
   use type Identity.Sessions.Expiration.Expiration_Status;
   use type Identity.Times.Instant;

   function Admit_Update
     (Session         : Identity.Sessions.Definitions.Session_Record;
      Now             : Identity.Times.Instant;
      Idle_Expires_At : Identity.Times.Expiration) return Activity_Admission_Status
   is
      Current_Status : constant Identity.Sessions.Expiration.Expiration_Status :=
        Identity.Sessions.Expiration.Evaluate (Session, Now);
   begin
      case Current_Status is
         when Identity.Sessions.Expiration.Current =>
            null;
         when Identity.Sessions.Expiration.Idle_Expired =>
            return Idle_Expired;
         when Identity.Sessions.Expiration.Absolute_Expired =>
            return Absolute_Expired;
         when Identity.Sessions.Expiration.Revoked =>
            return Revoked;
      end case;

      if Identity.Times.Expired (Now, Idle_Expires_At) then
         return Invalid_Idle_Extension;
      elsif Session.Absolute_Expires_At.Present
        and then Idle_Expires_At.Present
        and then Idle_Expires_At.Time_Point > Session.Absolute_Expires_At.Time_Point
      then
         return Invalid_Idle_Extension;
      else
         return Admitted;
      end if;
   end Admit_Update;

   function May_Update_Activity
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Boolean
   is
   begin
      return Identity.Sessions.Expiration.Evaluate (Session, Now) =
        Identity.Sessions.Expiration.Current;
   end May_Update_Activity;
end Identity.Sessions.Activity;

package body Identity.Authentication.Challenges is
   function Admit_Completion
     (Challenge : Challenge_Record;
      Now       : Identity.Times.Instant) return Challenge_Completion_Admission is
   begin
      case Challenge.State is
         when Issued =>
            if Identity.Times.Expired (Now, Challenge.Expires_At) then
               return Expired_By_Time;
            else
               return Admitted;
            end if;
         when Completed =>
            return Already_Completed;
         when Failed =>
            return Failed_State;
         when Expired =>
            return Expired_State;
         when Cancelled =>
            return Cancelled_State;
      end case;
   end Admit_Completion;
end Identity.Authentication.Challenges;

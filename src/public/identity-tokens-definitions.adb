package body Identity.Tokens.Definitions is
   function Admission
     (State    : Token_State;
      Action   : Token_Action;
      To_State : Token_State := Issued) return Token_Action_Admission_Status is
   begin
      if Is_Terminal (State) then
         return Token_Terminal_Rejected;
      end if;

      case Action is
         when Issue_Token =>
            if State = Issued then
               return Token_Action_Admitted;
            else
               return Token_State_Rejected;
            end if;
         when Verify_Token | Complete_Token =>
            if State in Issued | Presented | Verified then
               return Token_Action_Admitted;
            else
               return Token_State_Rejected;
            end if;
         when Advance_Token =>
            case State is
               when Issued =>
                  if To_State in Presented | Verified | Completed | Consumed
                    | Expired | Revoked | Superseded | Attempt_Limit_Reached
                  then
                     return Token_Action_Admitted;
                  end if;
               when Presented =>
                  if To_State in Verified | Completed | Consumed | Expired
                    | Revoked | Attempt_Limit_Reached
                  then
                     return Token_Action_Admitted;
                  end if;
               when Verified =>
                  if To_State in Completed | Consumed | Expired | Revoked then
                     return Token_Action_Admitted;
                  end if;
               when Completed | Consumed | Expired | Revoked | Superseded
                  | Attempt_Limit_Reached =>
                  return Token_Terminal_Rejected;
            end case;

            return Token_Advance_Rejected;
      end case;
   end Admission;

   function Can_Advance
     (From_State : Token_State;
      To_State   : Token_State) return Boolean is
   begin
      return Admission_Accepted
        (Admission (From_State, Advance_Token, To_State));
   end Can_Advance;
end Identity.Tokens.Definitions;

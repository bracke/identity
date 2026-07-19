package body Identity.Tokens.Consumption is
   function Evaluate (State : Identity.Tokens.Definitions.Token_State) return Consumption_Status is
   begin
      case State is
         when Identity.Tokens.Definitions.Issued
            | Identity.Tokens.Definitions.Presented
            | Identity.Tokens.Definitions.Verified =>
            return Can_Consume;
         when Identity.Tokens.Definitions.Consumed
            | Identity.Tokens.Definitions.Completed =>
            return Already_Consumed;
         when Identity.Tokens.Definitions.Expired =>
            return Expired;
         when Identity.Tokens.Definitions.Revoked =>
            return Revoked;
         when Identity.Tokens.Definitions.Attempt_Limit_Reached =>
            return Attempt_Limit_Reached;
         when Identity.Tokens.Definitions.Superseded =>
            return State_Conflict;
      end case;
   end Evaluate;

   function Evaluate
     (Token : Identity.Tokens.Definitions.Action_Token_Record;
      Now   : Identity.Times.Instant) return Consumption_Status is
   begin
      if Identity.Tokens.Definitions.Expired_At (Token, Now) then
         return Expired;
      else
         return Evaluate (Token.State);
      end if;
   end Evaluate;
end Identity.Tokens.Consumption;

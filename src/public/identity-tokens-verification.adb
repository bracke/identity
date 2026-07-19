package body Identity.Tokens.Verification is

   function Evaluate
     (Token            : Identity.Tokens.Definitions.Action_Token_Record;
      Expected_Purpose : Identity.Identifiers.Registry.Registry_Id;
      Secret_Verified  : Boolean;
      Binding_Matches  : Boolean;
      Now              : Identity.Times.Instant)
      return Token_Verification_Outcome
   is
   begin
      case Token.State is
         when Identity.Tokens.Definitions.Issued
            | Identity.Tokens.Definitions.Presented
            | Identity.Tokens.Definitions.Verified =>
            if Identity.Times.Expired (Now, Token.Expires_At) then
               return Expired;
            elsif not Identity.Tokens.Definitions.Purpose_Matches (Token, Expected_Purpose) then
               return Purpose_Mismatch;
            elsif not Binding_Matches then
               return Binding_Mismatch;
            end if;

            if Secret_Verified then
               return Valid;
            else
               return Not_Verified;
            end if;
         when Identity.Tokens.Definitions.Completed
            | Identity.Tokens.Definitions.Consumed =>
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

   function Evaluate_State_First
     (State   : Identity.Tokens.Definitions.Token_State;
      Expired : Boolean)
      return Token_Verification_Outcome
   is
   begin
      case State is
         when Identity.Tokens.Definitions.Issued
            | Identity.Tokens.Definitions.Presented
            | Identity.Tokens.Definitions.Verified =>
            if Expired then
               return Identity.Tokens.Verification.Expired;
            else
               return Identity.Tokens.Verification.Valid;
            end if;
         when Identity.Tokens.Definitions.Consumed
            | Identity.Tokens.Definitions.Completed =>
            return Identity.Tokens.Verification.Already_Consumed;
         when Identity.Tokens.Definitions.Superseded =>
            return Identity.Tokens.Verification.State_Conflict;
         when Identity.Tokens.Definitions.Expired =>
            return Identity.Tokens.Verification.Expired;
         when Identity.Tokens.Definitions.Revoked =>
            return Identity.Tokens.Verification.Revoked;
         when Identity.Tokens.Definitions.Attempt_Limit_Reached =>
            return Identity.Tokens.Verification.Attempt_Limit_Reached;
      end case;
   end Evaluate_State_First;

end Identity.Tokens.Verification;

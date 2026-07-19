with Identity.Identifiers.Registry;
with Identity.Times;
with Identity.Tokens.Definitions;

package Identity.Tokens.Verification is
   pragma Pure;

   type Token_Verification_Outcome is
     (Valid,
      Unknown,
      Malformed,
      Not_Verified,
      Expired,
      Already_Consumed,
      Revoked,
      Attempt_Limit_Reached,
      Purpose_Mismatch,
      Binding_Mismatch,
      State_Conflict,
      Infrastructure_Failure);

   function Evaluate
     (Token            : Identity.Tokens.Definitions.Action_Token_Record;
      Expected_Purpose : Identity.Identifiers.Registry.Registry_Id;
      Secret_Verified  : Boolean;
      Binding_Matches  : Boolean;
      Now              : Identity.Times.Instant)
      return Token_Verification_Outcome;

   function Evaluate_State_First
     (State   : Identity.Tokens.Definitions.Token_State;
      Expired : Boolean)
      return Token_Verification_Outcome;

   function Is_Valid
     (Outcome : Token_Verification_Outcome) return Boolean is
     (Outcome = Valid);

   function Terminal_Invalid
     (Outcome : Token_Verification_Outcome) return Boolean is
     (Outcome in Expired | Already_Consumed | Revoked | Attempt_Limit_Reached);

   function Disclosure_Collapsed_Invalid
     (Outcome : Token_Verification_Outcome) return Boolean is
     (Outcome in Unknown | Malformed | Not_Verified | Expired | Already_Consumed
               | Revoked | Attempt_Limit_Reached | Purpose_Mismatch
               | Binding_Mismatch | State_Conflict);

   function Retryable
     (Outcome : Token_Verification_Outcome) return Boolean is
     (Outcome in Not_Verified | State_Conflict | Infrastructure_Failure);

   function Infrastructure
     (Outcome : Token_Verification_Outcome) return Boolean is
     (Outcome = Infrastructure_Failure);
end Identity.Tokens.Verification;

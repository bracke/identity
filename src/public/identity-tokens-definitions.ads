with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Tokens.Definitions
  with SPARK_Mode => On
is
   pragma Pure;
   use type Identity.Identifiers.Entities.Principal_Id;

   type Token_State is
     (Issued, Presented, Verified, Completed, Consumed, Expired, Revoked, Superseded,
      Attempt_Limit_Reached);

   type Token_Verifiability_Status is
     (Token_Verifiable,
      State_Not_Verifiable,
      Token_Expired,
      Purpose_Different,
      Principal_Different);

   type Token_Action is
     (Issue_Token, Verify_Token, Complete_Token, Advance_Token);

   type Token_Action_Admission_Status is
     (Token_Action_Admitted, Token_State_Rejected, Token_Terminal_Rejected,
      Token_Advance_Rejected);

   type Action_Token_Record is record
      Id              : Identity.Identifiers.Entities.Token_Id;
      Purpose         : Identity.Identifiers.Registry.Registry_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Secret_Verifier : Identity.Text.Bounded.Bounded_Text;
      Issued_At       : Identity.Times.Instant := 0;
      Expires_At      : Identity.Times.Expiration;
      State           : Token_State := Issued;
      Attempts        : Identity.Versions.Attempt_Count := 0;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   function Is_Consumed_State (State : Token_State) return Boolean is
     (State in Completed | Consumed);

   function Is_Terminal (State : Token_State) return Boolean is
     (State in Completed | Consumed | Expired | Revoked | Superseded
      | Attempt_Limit_Reached);

   function Admission
     (State    : Token_State;
      Action   : Token_Action;
      To_State : Token_State := Issued) return Token_Action_Admission_Status;

   function Admission_Accepted
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status = Token_Action_Admitted);

   function Admission_Rejected
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status /= Token_Action_Admitted);

   function Action_Rejected
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status /= Token_Action_Admitted);

   function Action_State_Rejected
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status = Token_State_Rejected);

   function Action_Terminal_Rejected
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status = Token_Terminal_Rejected);

   function Action_Advance_Rejected
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status = Token_Advance_Rejected);

   function No_Mutation
     (Status : Token_Action_Admission_Status) return Boolean is
     (Status /= Token_Action_Admitted);

   function Can_Issue (State : Token_State) return Boolean is
     (Admission_Accepted (Admission (State, Issue_Token)));

   function Can_Verify (State : Token_State) return Boolean is
     (Admission_Accepted (Admission (State, Verify_Token)));

   function Can_Complete (State : Token_State) return Boolean is
     (Admission_Accepted (Admission (State, Complete_Token)));

   function Can_Advance
     (From_State : Token_State;
      To_State   : Token_State) return Boolean;

   function Expired_At
     (Token : Action_Token_Record;
      Now   : Identity.Times.Instant) return Boolean is
     (Identity.Times.Expired (Now, Token.Expires_At));

   function Purpose_Matches
     (Token    : Action_Token_Record;
      Expected : Identity.Identifiers.Registry.Registry_Id) return Boolean is
     (Identity.Identifiers.Registry.Image (Token.Purpose)
      = Identity.Identifiers.Registry.Image (Expected));

   function Bound_To_Principal
     (Token     : Action_Token_Record;
      Principal : Identity.Identifiers.Entities.Principal_Id) return Boolean is
     (Token.Principal = Principal);

   function Verifiability
     (Token            : Action_Token_Record;
      Expected_Purpose : Identity.Identifiers.Registry.Registry_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant) return Token_Verifiability_Status is
     (if not Can_Verify (Token.State) then State_Not_Verifiable
      elsif Expired_At (Token, Now) then Token_Expired
      elsif not Purpose_Matches (Token, Expected_Purpose) then Purpose_Different
      elsif not Bound_To_Principal (Token, Principal) then Principal_Different
      else Token_Verifiable);

   function Verifiability_Accepted
     (Status : Token_Verifiability_Status) return Boolean is
     (Status = Token_Verifiable);

   function Verifiability_Rejected
     (Status : Token_Verifiability_Status) return Boolean is
     (Status /= Token_Verifiable);

   function State_Rejected
     (Status : Token_Verifiability_Status) return Boolean is
     (Status = State_Not_Verifiable);

   function Expiration_Rejected
     (Status : Token_Verifiability_Status) return Boolean is
     (Status = Token_Expired);

   function Purpose_Rejected
     (Status : Token_Verifiability_Status) return Boolean is
     (Status = Purpose_Different);

   function Principal_Rejected
     (Status : Token_Verifiability_Status) return Boolean is
     (Status = Principal_Different);

   function Verifiable_For
     (Token            : Action_Token_Record;
      Expected_Purpose : Identity.Identifiers.Registry.Registry_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant) return Boolean is
     (Verifiability_Accepted
        (Verifiability (Token, Expected_Purpose, Principal, Now)));
end Identity.Tokens.Definitions;

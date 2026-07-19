with Identity.Identifiers.Entities;
with Identity.Tokens.Verification;

package Identity.Verification.Results is
   pragma Pure;

   type Verification_Result_Kind is
     (Requested,
      Completed,
      Invalid_Or_Expired,
      Binding_Mismatch,
      Attempt_Limit_Reached,
      Conflict,
      Operational_Failure);

   type Verification_Result is record
      Kind    : Verification_Result_Kind := Invalid_Or_Expired;
      Contact : Identity.Identifiers.Entities.Contact_Binding_Id;
      Token   : Identity.Tokens.Verification.Token_Verification_Outcome :=
        Identity.Tokens.Verification.Unknown;
   end record;

   function Successful (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Requested or else Kind = Completed);

   function Request_Accepted (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Requested);

   function Completion_Accepted (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Completed);

   function From_Token_Outcome
     (Outcome : Identity.Tokens.Verification.Token_Verification_Outcome)
      return Verification_Result_Kind is
     (case Outcome is
         when Identity.Tokens.Verification.Valid =>
            Completed,
         when Identity.Tokens.Verification.Binding_Mismatch =>
            Binding_Mismatch,
         when Identity.Tokens.Verification.Attempt_Limit_Reached =>
            Attempt_Limit_Reached,
         when Identity.Tokens.Verification.State_Conflict =>
            Conflict,
         when Identity.Tokens.Verification.Infrastructure_Failure =>
            Operational_Failure,
         when Identity.Tokens.Verification.Unknown
            | Identity.Tokens.Verification.Malformed
            | Identity.Tokens.Verification.Not_Verified
            | Identity.Tokens.Verification.Expired
            | Identity.Tokens.Verification.Already_Consumed
            | Identity.Tokens.Verification.Revoked
            | Identity.Tokens.Verification.Purpose_Mismatch =>
            Invalid_Or_Expired);

   function Requires_Generic_Token_Disclosure
     (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Invalid_Or_Expired
      or else Kind = Binding_Mismatch
      or else Kind = Attempt_Limit_Reached);

   function Invalid_Token_Rejection
     (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Invalid_Or_Expired);

   function Binding_Rejection (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Binding_Mismatch);

   function Attempt_Limit_Rejection
     (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Attempt_Limit_Reached);

   function Retryable_By_Presentation
     (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Invalid_Or_Expired or else Kind = Attempt_Limit_Reached);

   function Conflict (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Conflict);

   function Operational (Kind : Verification_Result_Kind) return Boolean is
     (Kind = Operational_Failure);
end Identity.Verification.Results;

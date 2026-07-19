package body Identity.Operations.Disclosure is
   function Rules_For (Profile : Disclosure_Profile) return Disclosure_Profile_Rules is
   begin
      case Profile is
         when Untrusted_Interactive | Untrusted_API =>
            return
              (Subject_Existence_Detail => False,
               Factor_Enrollment_Detail => False,
               Lockout_Detail => False,
               Retry_Timing_Detail => False,
               Contact_Destination_Detail => False,
               Diagnostic_Identifiers => False,
               Conflict_Detail => False,
               Token_State_Detail => False);
         when Authenticated_Self_Service =>
            return
              (Subject_Existence_Detail => False,
               Factor_Enrollment_Detail => True,
               Lockout_Detail => True,
               Retry_Timing_Detail => True,
               Contact_Destination_Detail => True,
               Diagnostic_Identifiers => False,
               Conflict_Detail => False,
               Token_State_Detail => False);
         when Trusted_Administrative =>
            return
              (Subject_Existence_Detail => True,
               Factor_Enrollment_Detail => True,
               Lockout_Detail => True,
               Retry_Timing_Detail => True,
               Contact_Destination_Detail => True,
               Diagnostic_Identifiers => True,
               Conflict_Detail => True,
               Token_State_Detail => False);
         when Internal_Operations =>
            return
              (Subject_Existence_Detail => True,
               Factor_Enrollment_Detail => True,
               Lockout_Detail => True,
               Retry_Timing_Detail => True,
               Contact_Destination_Detail => True,
               Diagnostic_Identifiers => True,
               Conflict_Detail => True,
               Token_State_Detail => True);
      end case;
   end Rules_For;

   function Reveals_No_More_Than
     (Left  : Disclosure_Profile_Rules;
      Right : Disclosure_Profile_Rules) return Boolean is
     ((not Left.Subject_Existence_Detail or else Right.Subject_Existence_Detail)
      and then (not Left.Factor_Enrollment_Detail or else Right.Factor_Enrollment_Detail)
      and then (not Left.Lockout_Detail or else Right.Lockout_Detail)
      and then (not Left.Retry_Timing_Detail or else Right.Retry_Timing_Detail)
      and then (not Left.Contact_Destination_Detail or else Right.Contact_Destination_Detail)
      and then (not Left.Diagnostic_Identifiers or else Right.Diagnostic_Identifiers)
      and then (not Left.Conflict_Detail or else Right.Conflict_Detail)
      and then (not Left.Token_State_Detail or else Right.Token_State_Detail));

   function Reveals_No_More_Than
     (Left  : Disclosure_Profile;
      Right : Disclosure_Profile) return Boolean is
     (Reveals_No_More_Than (Rules_For (Left), Rules_For (Right)));

   function To_Disclosure_Safe_Result
     (Status  : Identity.Results.Operation_Status;
      Profile : Disclosure_Profile := Untrusted_Interactive) return Disclosure_Status
   is
      use Identity.Results;
      Rules : constant Disclosure_Profile_Rules := Rules_For (Profile);
   begin
      case Status is
         when Succeeded =>
            return Success;
         when Rejected =>
            return Authentication_Rejected;
         when Throttled =>
            return Authentication_Throttled;
         when Additional_Factor_Required
            | Password_Change_Required
            | Verification_Required
            | Recovery_Action_Required =>
            if Rules.Factor_Enrollment_Detail then
               return Additional_Action_Required;
            else
               return Authentication_Rejected;
            end if;
         when Conflict =>
            if Rules.Conflict_Detail then
               return Conflict_Detailed;
            else
               return Authentication_Rejected;
            end if;
         when Invalid_Input =>
            return Invalid_Input;
         when Unsupported
            | Operational_Failure
            | Resource_Limit
            | Internal_Invariant_Failure =>
            return Operational_Failure;
      end case;
   end To_Disclosure_Safe_Result;

   function To_Disclosure_Safe_Result
     (Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
      Profile : Disclosure_Profile := Untrusted_Interactive) return Disclosure_Status
   is
      use Identity.Tokens.Verification;
      Rules : constant Disclosure_Profile_Rules := Rules_For (Profile);
   begin
      case Outcome is
         when Valid =>
            return Success;
         when Infrastructure_Failure =>
            return Operational_Failure;
         when State_Conflict =>
            if Rules.Conflict_Detail then
               return Conflict_Detailed;
            else
               return Token_Invalid_Or_Expired;
            end if;
         when Unknown
            | Malformed
            | Not_Verified
            | Expired
            | Already_Consumed
            | Revoked
            | Attempt_Limit_Reached
            | Purpose_Mismatch
            | Binding_Mismatch =>
            return Token_Invalid_Or_Expired;
      end case;
   end To_Disclosure_Safe_Result;
end Identity.Operations.Disclosure;

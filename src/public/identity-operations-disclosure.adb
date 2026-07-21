package body Identity.Operations.Disclosure is
   function Rules_For (Profile : Disclosure_Profile) return Disclosure_Profile_Rules is
   begin
      case Profile is
         when Untrusted_Interactive =>
            --  A human at a login form learns nothing beyond the generic
            --  outcome: no timing, no lockout, no subject existence.
            return (others => False);
         when Untrusted_API =>
            --  A machine client additionally gets a back-off time so it can
            --  honour rate limits (HTTP 429 Retry-After semantics). Retry
            --  timing carries transport throttle back-off, not account
            --  lockout -- that stays behind Lockout_Detail, which this profile
            --  does not grant -- so it is not a subject-existence oracle.
            return (Retry_Timing_Detail => True, others => False);
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

   function Project
     (Facts   : Disclosure_Facts;
      Profile : Disclosure_Profile := Untrusted_Interactive) return Disclosure_View
   is
      use Identity.Results;
      Rules : constant Disclosure_Profile_Rules := Rules_For (Profile);
   begin
      return
        (Status              => To_Disclosure_Safe_Result (Facts.Status, Profile),
         Subject_Known       =>
           (if Rules.Subject_Existence_Detail
            then (Present => True, Value => Facts.Subject_Known)
            else (Present => False)),
         Lockout             =>
           (if Rules.Lockout_Detail
            then (Present => True, Value => Facts.Locked)
            else (Present => False)),
         Retry_After_Seconds =>
           (if Rules.Retry_Timing_Detail
            then (Present => True, Value => Facts.Retry_After_Seconds)
            else (Present => False)),
         Contact_Present     =>
           (if Rules.Contact_Destination_Detail
            then (Present => True, Value => Facts.Contact_Present)
            else (Present => False)),
         Diagnostic_Present  =>
           (if Rules.Diagnostic_Identifiers
            then (Present => True, Value => Facts.Diagnostic_Present)
            else (Present => False)),
         Token_State         =>
           (if Rules.Token_State_Detail
            then (Present => True, Value => Facts.Token_State)
            else (Present => False)),
         Factor_Action       =>
           (if Rules.Factor_Enrollment_Detail
            then (Present => True,
                  Value => Facts.Status in Additional_Factor_Required
                                         | Password_Change_Required
                                         | Verification_Required
                                         | Recovery_Action_Required)
            else (Present => False)),
         Conflict_Detailed   =>
           Rules.Conflict_Detail and then Facts.Status = Conflict);
   end Project;

   function Discloses_No_More_Than
     (Narrow, Wide : Disclosure_View) return Boolean
   is
      function Subset (N, W : Optional_Boolean) return Boolean is
        (not N.Present or else (W.Present and then W.Value = N.Value));
   begin
      return
        Subset (Narrow.Subject_Known, Wide.Subject_Known)
        and then Subset (Narrow.Contact_Present, Wide.Contact_Present)
        and then Subset (Narrow.Diagnostic_Present, Wide.Diagnostic_Present)
        and then Subset (Narrow.Factor_Action, Wide.Factor_Action)
        and then (not Narrow.Lockout.Present
                  or else (Wide.Lockout.Present
                           and then Wide.Lockout.Value = Narrow.Lockout.Value))
        and then (not Narrow.Retry_After_Seconds.Present
                  or else (Wide.Retry_After_Seconds.Present
                           and then Wide.Retry_After_Seconds.Value
                                    = Narrow.Retry_After_Seconds.Value))
        and then (not Narrow.Token_State.Present
                  or else (Wide.Token_State.Present
                           and then Wide.Token_State.Value
                                    = Narrow.Token_State.Value))
        and then (not Narrow.Conflict_Detailed or else Wide.Conflict_Detailed);
   end Discloses_No_More_Than;
end Identity.Operations.Disclosure;

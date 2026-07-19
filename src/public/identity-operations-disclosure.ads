with Identity.Results;
with Identity.Tokens.Verification;

package Identity.Operations.Disclosure is
   pragma Pure;

   type Disclosure_Profile is
     (Untrusted_Interactive,
      Untrusted_API,
      Authenticated_Self_Service,
      Trusted_Administrative,
      Internal_Operations);

   type Disclosure_Status is
     (Authentication_Rejected,
      Authentication_Throttled,
      Additional_Action_Required,
      Token_Invalid_Or_Expired,
      Conflict_Hidden,
      Conflict_Detailed,
      Invalid_Input,
      Operational_Failure,
      Success);

   function Successful (Status : Disclosure_Status) return Boolean is
     (Status = Success);

   function Public_Rejection (Status : Disclosure_Status) return Boolean is
     (Status in Authentication_Rejected
              | Authentication_Throttled
              | Token_Invalid_Or_Expired
              | Conflict_Hidden);

   function Additional_Action (Status : Disclosure_Status) return Boolean is
     (Status = Additional_Action_Required);

   function Token_Invalid (Status : Disclosure_Status) return Boolean is
     (Status = Token_Invalid_Or_Expired);

   function Conflict_Detail_Hidden (Status : Disclosure_Status) return Boolean is
     (Status = Conflict_Hidden);

   function Conflict_Detail_Visible (Status : Disclosure_Status) return Boolean is
     (Status = Conflict_Detailed);

   function Invalid_Input_Status (Status : Disclosure_Status) return Boolean is
     (Status = Invalid_Input);

   function Operational_Status (Status : Disclosure_Status) return Boolean is
     (Status = Operational_Failure);

   type Disclosure_Profile_Rules is record
      Subject_Existence_Detail   : Boolean := False;
      Factor_Enrollment_Detail   : Boolean := False;
      Lockout_Detail             : Boolean := False;
      Retry_Timing_Detail        : Boolean := False;
      Contact_Destination_Detail : Boolean := False;
      Diagnostic_Identifiers     : Boolean := False;
      Conflict_Detail            : Boolean := False;
      Token_State_Detail         : Boolean := False;
   end record;

   function Rules_For (Profile : Disclosure_Profile) return Disclosure_Profile_Rules;

   function Reveals_No_More_Than
     (Left  : Disclosure_Profile_Rules;
      Right : Disclosure_Profile_Rules) return Boolean;

   function Reveals_No_More_Than
     (Left  : Disclosure_Profile;
      Right : Disclosure_Profile) return Boolean;

   function To_Disclosure_Safe_Result
     (Status  : Identity.Results.Operation_Status;
      Profile : Disclosure_Profile := Untrusted_Interactive) return Disclosure_Status;

   function To_Disclosure_Safe_Result
     (Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
      Profile : Disclosure_Profile := Untrusted_Interactive) return Disclosure_Status;
end Identity.Operations.Disclosure;

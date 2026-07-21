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

   --  Richer disclosure projection (spec 29). The coarse Disclosure_Status
   --  collapses causes; this view additionally carries the per-dimension
   --  details, each present only when the profile permits. Operations describe
   --  what they actually know in Disclosure_Facts; Project gates it into the
   --  audience-appropriate Disclosure_View. Before this, six of the eight
   --  dimension flags were never consulted -- dead fields.

   type Optional_Boolean (Present : Boolean := False) is record
      case Present is
         when True => Value : Boolean;
         when False => null;
      end case;
   end record;
   type Optional_Natural (Present : Boolean := False) is record
      case Present is
         when True => Value : Natural;
         when False => null;
      end case;
   end record;
   type Lockout_Disclosure is
     (Not_Locked, Temporarily_Locked, Indefinitely_Locked);
   type Optional_Lockout (Present : Boolean := False) is record
      case Present is
         when True => Value : Lockout_Disclosure;
         when False => null;
      end case;
   end record;
   type Token_State_Disclosure is
     (No_Token, Token_Valid, Token_Unknown, Token_Malformed, Token_Not_Verified,
      Token_Expired, Token_Consumed, Token_Revoked, Token_Attempt_Limit,
      Token_Purpose_Mismatch, Token_Binding_Mismatch, Token_State_Conflict);
   type Optional_Token_State (Present : Boolean := False) is record
      case Present is
         when True => Value : Token_State_Disclosure;
         when False => null;
      end case;
   end record;

   --  What the operation knows internally, before disclosure gating.
   type Disclosure_Facts is record
      Status              : Identity.Results.Operation_Status :=
                              Identity.Results.Rejected;
      Subject_Known       : Boolean := False;
      Locked              : Lockout_Disclosure := Not_Locked;
      Retry_After_Seconds : Natural := 0;
      Contact_Present     : Boolean := False;
      Diagnostic_Present  : Boolean := False;
      Token_State         : Token_State_Disclosure := No_Token;
   end record;

   --  The disclosure-safe view returned to a given audience. Each optional is
   --  present only when the profile permitted that dimension.
   type Disclosure_View is record
      Status              : Disclosure_Status;
      Subject_Known       : Optional_Boolean;
      Lockout             : Optional_Lockout;
      Retry_After_Seconds : Optional_Natural;
      Contact_Present     : Optional_Boolean;
      Diagnostic_Present  : Optional_Boolean;
      Token_State         : Optional_Token_State;
      Factor_Action       : Optional_Boolean;
      Conflict_Detailed   : Boolean;
   end record;

   function Project
     (Facts   : Disclosure_Facts;
      Profile : Disclosure_Profile := Untrusted_Interactive) return Disclosure_View;

   --  True when Narrow discloses no more than Wide: every detail present in
   --  Narrow is present and equal in Wide. The safety property a stricter
   --  profile must satisfy against a looser one.
   function Discloses_No_More_Than (Narrow, Wide : Disclosure_View) return Boolean;

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

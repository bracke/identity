with Identity.Identifiers.Entities;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Recovery_Codes.Sets is
   pragma Pure;

   Max_Codes_Per_Set : constant Natural := 16;

   type Recovery_Code_State is (Active, Consumed, Revoked);
   type Recovery_Code_Consume_Status is (Consumed, Not_Verified, Already_Consumed, Unknown, State_Conflict);
   type Recovery_Code_Use is (Consume_Code, Regeneration_Revocation);
   type Recovery_Code_Admission_Status is
     (Recovery_Code_Admitted, Recovery_Code_Consumed_Rejected,
      Recovery_Code_Revoked_Rejected);

   type Recovery_Code_Verifier is record
      Code_Id         : Identity.Text.Bounded.Bounded_Text;
      Secret_Verifier : Identity.Text.Bounded.Bounded_Text;
      State           : Recovery_Code_State := Active;
   end record;

   type Recovery_Code_List is array (Positive range 1 .. Max_Codes_Per_Set) of Recovery_Code_Verifier;

   type Recovery_Code_Set_Record is record
      Id        : Identity.Identifiers.Entities.Credential_Set_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      Created_At : Identity.Times.Instant := 0;
      Version   : Identity.Versions.Entity_Version := 0;
      Count     : Natural range 0 .. Max_Codes_Per_Set := 0;
      Codes     : Recovery_Code_List;
   end record;

   type Recovery_Code_Set_Projection is record
      Id             : Identity.Identifiers.Entities.Credential_Set_Id;
      Principal      : Identity.Identifiers.Entities.Principal_Id;
      Created_At     : Identity.Times.Instant := 0;
      Version        : Identity.Versions.Entity_Version := 0;
      Count          : Natural range 0 .. Max_Codes_Per_Set := 0;
      Active_Count   : Natural range 0 .. Max_Codes_Per_Set := 0;
      Consumed_Count : Natural range 0 .. Max_Codes_Per_Set := 0;
      Revoked_Count  : Natural range 0 .. Max_Codes_Per_Set := 0;
   end record;

   function Summary
     (Codes : Recovery_Code_Set_Record) return Recovery_Code_Set_Projection;

   function Has_Usable_Code
     (Codes : Recovery_Code_Set_Projection) return Boolean is
     (Codes.Active_Count > 0);

   function Fully_Consumed
     (Codes : Recovery_Code_Set_Projection) return Boolean is
     (Codes.Count > 0 and then Codes.Consumed_Count = Codes.Count);

   function Has_Revoked_Code
     (Codes : Recovery_Code_Set_Projection) return Boolean is
     (Codes.Revoked_Count > 0);

   function Fully_Revoked
     (Codes : Recovery_Code_Set_Projection) return Boolean is
     (Codes.Count > 0 and then Codes.Revoked_Count = Codes.Count);

   function Admission
     (State    : Recovery_Code_State;
      Code_Use : Recovery_Code_Use) return Recovery_Code_Admission_Status is
     (case Code_Use is
         when Consume_Code | Regeneration_Revocation =>
           (case State is
               when Active =>
                  Recovery_Code_Admitted,
               when Consumed =>
                  Recovery_Code_Consumed_Rejected,
               when Revoked =>
                  Recovery_Code_Revoked_Rejected));

   function Admission_Accepted
     (State    : Recovery_Code_State;
      Code_Use : Recovery_Code_Use) return Boolean is
     (Admission (State, Code_Use) = Recovery_Code_Admitted);

   function Admission_Rejected
     (Status : Recovery_Code_Admission_Status) return Boolean is
     (Status /= Recovery_Code_Admitted);

   function Consumed_Rejected
     (Status : Recovery_Code_Admission_Status) return Boolean is
     (Status = Recovery_Code_Consumed_Rejected);

   function Revoked_Rejected
     (Status : Recovery_Code_Admission_Status) return Boolean is
     (Status = Recovery_Code_Revoked_Rejected);

   function Active_State (State : Recovery_Code_State) return Boolean is
     (State = Active);

   function Consumed_State (State : Recovery_Code_State) return Boolean is
     (State = Consumed);

   function Revoked_State (State : Recovery_Code_State) return Boolean is
     (State = Revoked);

   function Admit_Matched_Code
     (Verifier : Recovery_Code_Verifier) return Recovery_Code_Consume_Status is
     (case Admission (Verifier.State, Consume_Code) is
         when Recovery_Code_Admitted => Consumed,
         when Recovery_Code_Consumed_Rejected => Already_Consumed,
         when Recovery_Code_Revoked_Rejected => State_Conflict);

   function Evaluate_Presentation
     (Found    : Boolean;
      Verified : Boolean;
      Verifier : Recovery_Code_Verifier) return Recovery_Code_Consume_Status is
     (if not Found then
         Unknown
      elsif not Verified then
         Not_Verified
      else
         Admit_Matched_Code (Verifier));

   function Usable (State : Recovery_Code_State) return Boolean is
     (Admission_Accepted (State, Consume_Code));

   function Consumption_Succeeded
     (Status : Recovery_Code_Consume_Status) return Boolean is
     (Status = Consumed);

   function Reuse_Rejected
     (Status : Recovery_Code_Consume_Status) return Boolean is
     (Status = Already_Consumed);

   function Retryable_By_Presentation
     (Status : Recovery_Code_Consume_Status) return Boolean is
     (Status = Not_Verified or else Status = Unknown);

   function Unknown_Code
     (Status : Recovery_Code_Consume_Status) return Boolean is
     (Status = Unknown);

   function Conflict
     (Status : Recovery_Code_Consume_Status) return Boolean is
     (Status = State_Conflict);

   function No_State_Mutation
     (Status : Recovery_Code_Consume_Status) return Boolean is
     (Status in Not_Verified | Already_Consumed | Unknown | State_Conflict);

   function Can_Revoke_During_Regeneration
     (State : Recovery_Code_State) return Boolean is
     (Admission_Accepted (State, Regeneration_Revocation));
end Identity.Recovery_Codes.Sets;

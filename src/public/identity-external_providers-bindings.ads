with Identity.Identifiers.Entities;
with Identity.External_Providers.Assertions;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.External_Providers.Bindings is
   pragma Pure;

   type External_Binding_State is (Active, Pending, Suspended, Revoked, Rebinding_Required);

   type External_Binding_Use is
     (Assertion_Authentication, Binding_Revocation, Binding_Replacement);

   type External_Binding_Admission_Status is
     (External_Binding_Admitted, Active_Required, Not_Revoked_Required);

   type External_Binding_Record is record
      Id              : Identity.Identifiers.Entities.External_Binding_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Provider        : Identity.Identifiers.Entities.External_Provider_Id;
      Issuer          : Identity.Text.Bounded.Bounded_Text;
      External_Subject : Identity.Text.Bounded.Bounded_Text;
      State           : External_Binding_State := Active;
      Created_At      : Identity.Times.Instant := 0;
      Version         : Identity.Versions.Entity_Version := 0;
   end record;

   function Admission
     (State           : External_Binding_State;
      Binding_Purpose : External_Binding_Use)
      return External_Binding_Admission_Status is
     (case Binding_Purpose is
         when Assertion_Authentication =>
           (if State = Active
            then External_Binding_Admitted
            else Active_Required),
         when Binding_Revocation | Binding_Replacement =>
           (if State = Revoked
            then Not_Revoked_Required
            else External_Binding_Admitted));

   function Admission_Accepted
     (Status : External_Binding_Admission_Status) return Boolean is
     (Status = External_Binding_Admitted);

   function Admission_Rejected
     (Status : External_Binding_Admission_Status) return Boolean is
     (Status /= External_Binding_Admitted);

   function Admission_Accepted
     (State           : External_Binding_State;
      Binding_Purpose : External_Binding_Use) return Boolean is
     (Admission_Accepted (Admission (State, Binding_Purpose)));

   function Active_Rejected
     (Status : External_Binding_Admission_Status) return Boolean is
     (Status = Active_Required);

   function Active_Rejected
     (State           : External_Binding_State;
      Binding_Purpose : External_Binding_Use) return Boolean is
     (Active_Rejected (Admission (State, Binding_Purpose)));

   function Revoked_Rejected
     (Status : External_Binding_Admission_Status) return Boolean is
     (Status = Not_Revoked_Required);

   function Revoked_Rejected
     (State           : External_Binding_State;
      Binding_Purpose : External_Binding_Use) return Boolean is
     (Revoked_Rejected (Admission (State, Binding_Purpose)));

   function No_Mutation
     (Status : External_Binding_Admission_Status) return Boolean is
     (Status /= External_Binding_Admitted);

   function Active_State (State : External_Binding_State) return Boolean is
     (State = Active);

   function Pending_State (State : External_Binding_State) return Boolean is
     (State = Pending);

   function Suspended_State (State : External_Binding_State) return Boolean is
     (State = Suspended);

   function Revoked_State (State : External_Binding_State) return Boolean is
     (State = Revoked);

   function Rebinding_Required_State
     (State : External_Binding_State) return Boolean is
     (State = Rebinding_Required);

   function Authentication_State_Rejected
     (State : External_Binding_State) return Boolean is
     (Admission (State, Assertion_Authentication) = Active_Required);

   function Lifecycle_Mutation_State_Rejected
     (State : External_Binding_State) return Boolean is
     (Admission (State, Binding_Revocation) = Not_Revoked_Required);

   function Usable_For_Authentication (State : External_Binding_State) return Boolean is
     (Admission_Accepted (State, Assertion_Authentication));

   function Can_Revoke (State : External_Binding_State) return Boolean is
     (Admission_Accepted (State, Binding_Revocation));

   function Can_Replace (State : External_Binding_State) return Boolean is
     (Admission_Accepted (State, Binding_Replacement));

   function Same_External_Key
     (Left, Right : External_Binding_Record) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left.Provider)
      = Identity.Identifiers.Entities.To_String (Right.Provider)
      and then Identity.Text.Bounded.Equal (Left.Issuer, Right.Issuer)
      and then Identity.Text.Bounded.Equal (Left.External_Subject, Right.External_Subject));

   function Same_Active_External_Key
     (Left, Right : External_Binding_Record) return Boolean is
     (Usable_For_Authentication (Left.State)
      and then Usable_For_Authentication (Right.State)
      and then Same_External_Key (Left, Right));

   function Matches_Assertion
     (Binding   : External_Binding_Record;
      Assertion : Identity.External_Providers.Assertions.Normalized_Assertion) return Boolean is
     (Identity.Identifiers.Entities.To_String (Binding.Provider)
      = Identity.Identifiers.Entities.To_String (Assertion.Provider)
      and then Identity.Text.Bounded.Equal (Binding.Issuer, Assertion.Issuer)
      and then Identity.Text.Bounded.Equal
        (Binding.External_Subject, Assertion.External_Subject));

   function Active_Matches_Assertion
     (Binding   : External_Binding_Record;
      Assertion : Identity.External_Providers.Assertions.Normalized_Assertion) return Boolean is
     (Usable_For_Authentication (Binding.State)
      and then Matches_Assertion (Binding, Assertion));
end Identity.External_Providers.Bindings;

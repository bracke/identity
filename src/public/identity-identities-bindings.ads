with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Identities.Subjects;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Identities.Bindings is
   pragma Pure;

   type Binding_State is (Active, Pending, Suspended, Revoked, Rebinding_Required);

   type Binding_Use is
     (Subject_Resolution,
      Binding_Revocation,
      Binding_Replacement);

   type Binding_Admission_Status is
     (Binding_Admitted,
      Active_Required,
      Not_Revoked_Required);

   type Binding_Record is record
      Id         : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Kind       : Identity.Identifiers.Registry.Registry_Id;
      Normalized : Identity.Text.Bounded.Bounded_Text;
      State      : Binding_State := Active;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;

   function Admission
     (State           : Binding_State;
      Binding_Purpose : Binding_Use)
      return Binding_Admission_Status is
     (case Binding_Purpose is
        when Subject_Resolution | Binding_Replacement =>
          (if State = Active then Binding_Admitted else Active_Required),
        when Binding_Revocation =>
          (if State = Revoked then Not_Revoked_Required else Binding_Admitted));

   function Admission_Accepted
     (Status : Binding_Admission_Status) return Boolean is
     (Status = Binding_Admitted);

   function Admission_Rejected
     (Status : Binding_Admission_Status) return Boolean is
     (Status /= Binding_Admitted);

   function Active_Rejected
     (Status : Binding_Admission_Status) return Boolean is
     (Status = Active_Required);

   function Revoked_Rejected
     (Status : Binding_Admission_Status) return Boolean is
     (Status = Not_Revoked_Required);

   function No_Mutation
     (Status : Binding_Admission_Status) return Boolean is
     (Status /= Binding_Admitted);

   function Usable_For_Resolution (State : Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Subject_Resolution)));

   function Can_Revoke (State : Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Binding_Revocation)));

   function Can_Replace (State : Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Binding_Replacement)));

   function Same_Active_Subject
     (Left, Right : Binding_Record) return Boolean is
     (Usable_For_Resolution (Left.State)
      and then Usable_For_Resolution (Right.State)
      and then Identity.Identifiers.Registry.Image (Left.Kind)
        = Identity.Identifiers.Registry.Image (Right.Kind)
      and then Identity.Text.Bounded.Equal (Left.Normalized, Right.Normalized));

   function Matches_Subject
     (Binding : Binding_Record;
      Subject : Identity.Identities.Subjects.Authentication_Subject) return Boolean is
     (Identity.Identifiers.Registry.Image (Binding.Kind)
      = Identity.Identifiers.Registry.Image (Subject.Kind)
      and then Identity.Text.Bounded.Equal (Binding.Normalized, Subject.Value));

   function Active_Matches_Subject
     (Binding : Binding_Record;
      Subject : Identity.Identities.Subjects.Authentication_Subject) return Boolean is
     (Usable_For_Resolution (Binding.State)
      and then Matches_Subject (Binding, Subject));
end Identity.Identities.Bindings;

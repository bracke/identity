with Identity.Identifiers.Entities;
with Identity.Times;
with Identity.Versions;

package Identity.Multi_Factor.Enrollment is
   pragma Pure;

   type Enrollment_State is (Pending, Proof_Accepted, Active, Cancelled, Expired);

   type Enrollment_Activation_Status is
     (Enrollment_Activation_Admitted,
      Enrollment_Proof_Required,
      Enrollment_Already_Active,
      Enrollment_Cancelled,
      Enrollment_Expired);

   type Enrollment_Record is record
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      State      : Enrollment_State := Pending;
      Created_At : Identity.Times.Instant := 0;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;

   function Activation_Admission
     (State : Enrollment_State) return Enrollment_Activation_Status is
     (case State is
        when Proof_Accepted => Enrollment_Activation_Admitted,
        when Pending => Enrollment_Proof_Required,
        when Active => Enrollment_Already_Active,
        when Cancelled => Enrollment_Cancelled,
        when Expired => Enrollment_Expired);

   function Activation_Admission
     (Value : Enrollment_Record) return Enrollment_Activation_Status is
     (Activation_Admission (Value.State));

   function Activation_Accepted
     (Status : Enrollment_Activation_Status) return Boolean is
     (Status = Enrollment_Activation_Admitted);

   function Proof_Required_Rejection
     (Status : Enrollment_Activation_Status) return Boolean is
     (Status = Enrollment_Proof_Required);

   function Already_Active_Rejection
     (Status : Enrollment_Activation_Status) return Boolean is
     (Status = Enrollment_Already_Active);

   function Cancelled_Rejection
     (Status : Enrollment_Activation_Status) return Boolean is
     (Status = Enrollment_Cancelled);

   function Expired_Rejection
     (Status : Enrollment_Activation_Status) return Boolean is
     (Status = Enrollment_Expired);

   function Can_Activate (Value : Enrollment_Record) return Boolean is
     (Activation_Accepted (Activation_Admission (Value)));
end Identity.Multi_Factor.Enrollment;

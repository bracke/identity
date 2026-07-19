with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Contacts.Bindings is
   pragma Pure;

   type Contact_Binding_State is
     (Pending_Verification, Verified, Retired, Revoked);

   type Contact_Binding_Record is record
      Id               : Identity.Identifiers.Entities.Contact_Binding_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Kind             : Identity.Identifiers.Registry.Registry_Id;
      Normalized_Value : Identity.Text.Bounded.Bounded_Text;
      State            : Contact_Binding_State := Pending_Verification;
      Version          : Identity.Versions.Entity_Version := 0;
   end record;

   type Contact_Binding_Projection is record
      Id               : Identity.Identifiers.Entities.Contact_Binding_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Kind             : Identity.Identifiers.Registry.Registry_Id;
      Value_Present    : Boolean := False;
      State            : Contact_Binding_State := Pending_Verification;
      Version          : Identity.Versions.Entity_Version := 0;
   end record;

   type Contact_Binding_Use is
     (Verification_Request,
      Verification_Completion,
      Contact_Change_Predecessor,
      Contact_Change_Successor,
      Contact_Value_Occupancy);

   type Contact_Binding_Admission_Status is
     (Contact_Binding_Admitted,
      Pending_Verification_Required,
      Verified_Required,
      Occupying_State_Required);

   function Summary
     (Binding : Contact_Binding_Record) return Contact_Binding_Projection is
     ((Id            => Binding.Id,
       Principal     => Binding.Principal,
       Kind          => Binding.Kind,
       Value_Present =>
         Identity.Text.Bounded.Length (Binding.Normalized_Value) > 0,
       State         => Binding.State,
       Version       => Binding.Version));

   function Admission
     (State : Contact_Binding_State;
      Binding_Use : Contact_Binding_Use) return Contact_Binding_Admission_Status is
     (case Binding_Use is
        when Verification_Request | Verification_Completion | Contact_Change_Successor =>
          (if State = Pending_Verification
           then Contact_Binding_Admitted
           else Pending_Verification_Required),
        when Contact_Change_Predecessor =>
          (if State = Verified
           then Contact_Binding_Admitted
           else Verified_Required),
        when Contact_Value_Occupancy =>
          (if State not in Retired | Revoked
           then Contact_Binding_Admitted
           else Occupying_State_Required));

   function Admission
     (Binding : Contact_Binding_Projection;
      Binding_Use : Contact_Binding_Use) return Contact_Binding_Admission_Status is
     (Admission (Binding.State, Binding_Use));

   function Admission_Accepted
     (Status : Contact_Binding_Admission_Status) return Boolean is
     (Status = Contact_Binding_Admitted);

   function Admission_Rejected
     (Status : Contact_Binding_Admission_Status) return Boolean is
     (Status /= Contact_Binding_Admitted);

   function Pending_Verification_Rejected
     (Status : Contact_Binding_Admission_Status) return Boolean is
     (Status = Pending_Verification_Required);

   function Verified_Rejected
     (Status : Contact_Binding_Admission_Status) return Boolean is
     (Status = Verified_Required);

   function Occupancy_Rejected
     (Status : Contact_Binding_Admission_Status) return Boolean is
     (Status = Occupying_State_Required);

   function No_Mutation
     (Status : Contact_Binding_Admission_Status) return Boolean is
     (Status /= Contact_Binding_Admitted);

   function Can_Request_Verification (State : Contact_Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Verification_Request)));

   function Can_Request_Verification
     (Binding : Contact_Binding_Projection) return Boolean is
     (Can_Request_Verification (Binding.State));

   function Can_Complete_Verification (State : Contact_Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Verification_Completion)));

   function Can_Complete_Verification
     (Binding : Contact_Binding_Projection) return Boolean is
     (Can_Complete_Verification (Binding.State));

   function Can_Be_Change_Predecessor (State : Contact_Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Contact_Change_Predecessor)));

   function Can_Be_Change_Predecessor
     (Binding : Contact_Binding_Projection) return Boolean is
     (Can_Be_Change_Predecessor (Binding.State));

   function Can_Be_Change_Successor (State : Contact_Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Contact_Change_Successor)));

   function Can_Be_Change_Successor
     (Binding : Contact_Binding_Projection) return Boolean is
     (Can_Be_Change_Successor (Binding.State));

   function Occupies_Contact_Value (State : Contact_Binding_State) return Boolean is
     (Admission_Accepted (Admission (State, Contact_Value_Occupancy)));

   function Occupies_Contact_Value
     (Binding : Contact_Binding_Projection) return Boolean is
     (Occupies_Contact_Value (Binding.State));

   function Same_Contact_Value
     (Left, Right : Contact_Binding_Record) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left.Principal)
      = Identity.Identifiers.Entities.To_String (Right.Principal)
      and then Identity.Identifiers.Registry.Image (Left.Kind)
        = Identity.Identifiers.Registry.Image (Right.Kind)
      and then Identity.Text.Bounded.Equal
        (Left.Normalized_Value, Right.Normalized_Value));

   function Same_Occupied_Contact_Value
     (Left, Right : Contact_Binding_Record) return Boolean is
     (Occupies_Contact_Value (Left.State)
      and then Occupies_Contact_Value (Right.State)
      and then Same_Contact_Value (Left, Right));
end Identity.Contacts.Bindings;

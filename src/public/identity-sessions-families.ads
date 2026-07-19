with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Sessions.Families is
   pragma Pure;

   type Session_Family_State is (Active, Revoking, Revoked);

   type Session_Family_Admission_Status is
     (Session_Family_Admitted,
      Session_Family_Revoking,
      Session_Family_Revoked);

   type Session_Family_Record is record
      Id         : Identity.Identifiers.Entities.Session_Family_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Generation : Identity.Versions.Rotation_Generation := 0;
      State      : Session_Family_State := Active;
   end record;

   function Admission
     (State : Session_Family_State) return Session_Family_Admission_Status is
     (case State is
        when Active => Session_Family_Admitted,
        when Revoking => Session_Family_Revoking,
        when Revoked => Session_Family_Revoked);

   function Admission
     (Value : Session_Family_Record) return Session_Family_Admission_Status is
     (Admission (Value.State));

   function Admission_Accepted
     (Status : Session_Family_Admission_Status) return Boolean is
     (Status = Session_Family_Admitted);

   function Admission_Rejected
     (Status : Session_Family_Admission_Status) return Boolean is
     (Status /= Session_Family_Admitted);

   function Revoking_Rejection
     (Status : Session_Family_Admission_Status) return Boolean is
     (Status = Session_Family_Revoking);

   function Revoked_Rejection
     (Status : Session_Family_Admission_Status) return Boolean is
     (Status = Session_Family_Revoked);

   function No_Mutation
     (Status : Session_Family_Admission_Status) return Boolean is
     (Status /= Session_Family_Admitted);

   function Active_State (State : Session_Family_State) return Boolean is
     (State = Active);

   function Revoking_State (State : Session_Family_State) return Boolean is
     (State = Revoking);

   function Revoked_State (State : Session_Family_State) return Boolean is
     (State = Revoked);

   function Terminal_State (State : Session_Family_State) return Boolean is
     (State = Revoked);

   function Usable (Value : Session_Family_Record) return Boolean is
     (Admission_Accepted (Admission (Value)));
end Identity.Sessions.Families;

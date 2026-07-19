with Identity.Versions;

package Identity.API_Keys.Rotation is
   pragma Pure;

   type Rotation_Overlap_State is (No_Overlap, Overlap_Active, Overlap_Expired);
   type Rotation_Status is (Allowed, Generation_Exhausted);
   type Rotation_Admission_Status is
     (Rotation_Admitted, Rotation_Generation_Exhausted,
      Rotation_Overlap_Expired);
   type Successor_Admission_Status is
     (Successor_Generation_Admitted,
      Successor_Predecessor_Generation_Exhausted,
      Successor_Generation_Mismatched);

   function Overlap_Usable (State : Rotation_Overlap_State) return Boolean is
     (State in No_Overlap | Overlap_Active);

   function Overlap_Terminal (State : Rotation_Overlap_State) return Boolean is
     (State = Overlap_Expired);

   function Rotation_Allowed (Status : Rotation_Status) return Boolean is
     (Status = Allowed);

   function Generation_Rejected (Status : Rotation_Status) return Boolean is
     (Status = Generation_Exhausted);

   function Admission_Accepted
     (Status : Rotation_Admission_Status) return Boolean is
     (Status = Rotation_Admitted);

   function Admission_Rejected
     (Status : Rotation_Admission_Status) return Boolean is
     (Status /= Rotation_Admitted);

   function Admission_Generation_Rejected
     (Status : Rotation_Admission_Status) return Boolean is
     (Status = Rotation_Generation_Exhausted);

   function Admission_Overlap_Rejected
     (Status : Rotation_Admission_Status) return Boolean is
     (Status = Rotation_Overlap_Expired);

   function Successor_Admission_Accepted
     (Status : Successor_Admission_Status) return Boolean is
     (Status = Successor_Generation_Admitted);

   function Successor_Admission_Rejected
     (Status : Successor_Admission_Status) return Boolean is
     (Status /= Successor_Generation_Admitted);

   function Successor_Predecessor_Rejected
     (Status : Successor_Admission_Status) return Boolean is
     (Status = Successor_Predecessor_Generation_Exhausted);

   function Successor_Mismatch_Rejected
     (Status : Successor_Admission_Status) return Boolean is
     (Status = Successor_Generation_Mismatched);

   type Rotation_Window is record
      Generation : Identity.Versions.Rotation_Generation := 0;
      State      : Rotation_Overlap_State := No_Overlap;
   end record;

   function Successor_Generation
     (Value : Rotation_Window) return Identity.Versions.Rotation_Generation;

   function Successor_Generation
     (Generation : Identity.Versions.Rotation_Generation)
      return Identity.Versions.Rotation_Generation;

   function Can_Rotate (Value : Rotation_Window) return Rotation_Status;

   function Can_Rotate
     (Generation : Identity.Versions.Rotation_Generation) return Rotation_Status;

   function Admission (Value : Rotation_Window) return Rotation_Admission_Status;

   function Admission
     (Generation : Identity.Versions.Rotation_Generation;
      State      : Rotation_Overlap_State) return Rotation_Admission_Status;

   function Matches_Successor_Generation
     (Predecessor, Successor : Identity.Versions.Rotation_Generation)
      return Boolean;

   function Successor_Admission
     (Predecessor, Successor : Identity.Versions.Rotation_Generation)
      return Successor_Admission_Status;
end Identity.API_Keys.Rotation;

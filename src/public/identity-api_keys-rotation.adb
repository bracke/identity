package body Identity.API_Keys.Rotation is
   use type Identity.Versions.Rotation_Generation;

   function Successor_Generation
     (Value : Rotation_Window) return Identity.Versions.Rotation_Generation
   is
   begin
      return Successor_Generation (Value.Generation);
   end Successor_Generation;

   function Successor_Generation
     (Generation : Identity.Versions.Rotation_Generation)
      return Identity.Versions.Rotation_Generation
   is
   begin
      if Generation = Identity.Versions.Rotation_Generation'Last then
         return Generation;
      end if;

      return Generation + Identity.Versions.Rotation_Generation'(1);
   end Successor_Generation;

   function Can_Rotate (Value : Rotation_Window) return Rotation_Status is
   begin
      return Can_Rotate (Value.Generation);
   end Can_Rotate;

   function Can_Rotate
     (Generation : Identity.Versions.Rotation_Generation) return Rotation_Status
   is
   begin
      if Generation = Identity.Versions.Rotation_Generation'Last then
         return Generation_Exhausted;
      else
         return Allowed;
      end if;
   end Can_Rotate;

   function Admission (Value : Rotation_Window) return Rotation_Admission_Status is
   begin
      return Admission (Value.Generation, Value.State);
   end Admission;

   function Admission
     (Generation : Identity.Versions.Rotation_Generation;
      State      : Rotation_Overlap_State) return Rotation_Admission_Status
   is
   begin
      if not Overlap_Usable (State) then
         return Rotation_Overlap_Expired;
      elsif Can_Rotate (Generation) = Generation_Exhausted then
         return Rotation_Generation_Exhausted;
      else
         return Rotation_Admitted;
      end if;
   end Admission;

   function Matches_Successor_Generation
     (Predecessor, Successor : Identity.Versions.Rotation_Generation)
      return Boolean
   is
   begin
      return Successor_Admission_Accepted
        (Successor_Admission (Predecessor, Successor));
   end Matches_Successor_Generation;

   function Successor_Admission
     (Predecessor, Successor : Identity.Versions.Rotation_Generation)
      return Successor_Admission_Status
   is
   begin
      if Can_Rotate (Predecessor) = Generation_Exhausted then
         return Successor_Predecessor_Generation_Exhausted;
      elsif Successor /= Successor_Generation (Predecessor) then
         return Successor_Generation_Mismatched;
      else
         return Successor_Generation_Admitted;
      end if;
   end Successor_Admission;
end Identity.API_Keys.Rotation;

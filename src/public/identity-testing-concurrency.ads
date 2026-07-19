package Identity.Testing.Concurrency is
   type Checkpoint_Barrier is record
      Required : Natural := 0;
      Arrived  : Natural := 0;
   end record;

   function Released (Value : Checkpoint_Barrier) return Boolean is
     (Value.Required > 0 and then Value.Arrived >= Value.Required);

   procedure Arrive (Value : in out Checkpoint_Barrier);
end Identity.Testing.Concurrency;

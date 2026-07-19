package body Identity.Testing.Concurrency is
   procedure Arrive (Value : in out Checkpoint_Barrier) is
   begin
      if Value.Arrived < Natural'Last then
         Value.Arrived := Value.Arrived + 1;
      end if;
   end Arrive;
end Identity.Testing.Concurrency;

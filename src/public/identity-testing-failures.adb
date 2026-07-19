package body Identity.Testing.Failures is
   procedure Consume
     (Script    : in out Failure_Script;
      Point     : Failure_Checkpoint;
      Triggered : out Boolean) is
   begin
      Triggered := Should_Fail (Script, Point);

      if Triggered then
         Script.Consumed := Script.Consumed + 1;

         if Script.Consumed >= Script.Remaining then
            Script.Armed := False;
         end if;
      end if;
   end Consume;
end Identity.Testing.Failures;

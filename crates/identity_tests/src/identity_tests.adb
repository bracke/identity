with AUnit;
with AUnit.Options;
with AUnit.Reporter.Text;
with AUnit.Run;
with Ada.Command_Line;

with Identity_Tests_Cases;

procedure Identity_Tests is
   use type AUnit.Status;
   function Run is new AUnit.Run.Test_Runner_With_Status
     (Identity_Tests_Cases.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Outcome  : constant AUnit.Status :=
     Run (Reporter, AUnit.Options.Default_Options);
begin
   if Outcome /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Identity_Tests;

with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Invariants is

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Is_Space (Value : Character) return Boolean is
     (Value = ' ' or else Value = Character'Val (9));

   function Trimmed (Line : String) return String is
      First : Natural := Line'First;
      Last  : Natural := Line'Last;
   begin
      while First <= Line'Last and then Is_Space (Line (First)) loop
         First := First + 1;
      end loop;

      while Last >= First and then Is_Space (Line (Last)) loop
         Last := Last - 1;
      end loop;

      if First > Line'Last or else Last < First then
         return "";
      end if;

      return Line (First .. Last);
   end Trimmed;

   function Registry_Path return String is
     (if Ada.Directories.Exists ("registries/invariants.json") then
        "registries/invariants.json"
      else
        "../../registries/invariants.json");

   procedure Validate (Report : out Validation_Report) is
      File                    : Ada.Text_IO.File_Type;
      Pending_Required_Tests  : Boolean := False;
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Registry_Path) then
         Ada.Text_IO.Put_Line ("invariants:missing-registry:" & Registry_Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Registry_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
            Text : constant String := Trimmed (Line);
         begin
            if Contains (Line, """id"": ""IDENTITY-") then
               Report.Invariant_Count := Report.Invariant_Count + 1;
            end if;

            if Contains (Line, """failure_severity"":") then
               Report.Failure_Severity_Count := Report.Failure_Severity_Count + 1;
            end if;

            if Pending_Required_Tests then
               if Text = "]" or else Text = "]," then
                  Report.Empty_Required_Test_Blocks :=
                    Report.Empty_Required_Test_Blocks + 1;
                  Pending_Required_Tests := False;
               elsif Text'Length > 0 then
                  Pending_Required_Tests := False;
               end if;
            end if;

            if Contains (Line, """required_tests"": [") then
               Report.Required_Test_Block_Count := Report.Required_Test_Block_Count + 1;
               Pending_Required_Tests := True;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Invariant_Count > 0
      and then Report.Required_Test_Block_Count = Report.Invariant_Count
      and then Report.Failure_Severity_Count = Report.Invariant_Count
      and then Report.Empty_Required_Test_Blocks = 0);

end Identity_Tools_Invariants;

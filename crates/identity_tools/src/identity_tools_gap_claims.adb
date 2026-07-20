with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Identity_Tools_Gap_Claims is
   use Ada.Strings.Unbounded;

   --  Suites the gates document describes, and the assertion-message prefix
   --  each one uses in the AUnit suite.
   type Suite_Id is (Atomicity, Disclosure, Events, Emission);

   function Prefix (Id : Suite_Id) return String is
     (case Id is
        when Atomicity  => "atomicity:",
        when Disclosure => "disclosure:",
        when Events     => "events:",
        when Emission   => "emission:");

   function Label (Id : Suite_Id) return String is
     (case Id is
        when Atomicity  => "atomicity",
        when Disclosure => "disclosure",
        when Events     => "events",
        when Emission   => "emission");

   function Resolve (Relative : String) return String is
     (if Ada.Directories.Exists (Relative) then Relative else "../../" & Relative);

   function Gates_Path return String is (Resolve ("tools/release-gates.txt"));

   function Suite_Path return String is
     (Resolve ("crates/identity_tests/src/identity_tests_cases.adb"));

   function Load (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Buffer, Ada.Text_IO.Get_Line (File));
         Append (Buffer, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Buffer);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Load;

   function Lowered (Text : String) return String is
      Result : String := Text;
   begin
      for Ch of Result loop
         if Ch in 'A' .. 'Z' then
            Ch := Character'Val (Character'Pos (Ch) + 32);
         end if;
      end loop;
      return Result;
   end Lowered;

   --  Case-insensitive: the gaps section is prose, so "Atomicity:" and
   --  "atomicity" must both match the suite label.
   function Contains (Text : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Lowered (Text), Lowered (Pattern)) /= 0);

   --  The gaps section is everything after the "Known gaps" heading.
   function Gaps_Section (Gates : String) return String is
      Heading : constant Natural :=
        Ada.Strings.Fixed.Index (Gates, "Known gaps");
   begin
      if Heading = 0 then
         return "";
      end if;
      return Gates (Heading .. Gates'Last);
   end Gaps_Section;

   --  True when the gaps section still says this suite does not exist.
   function Declared_Missing (Gaps : String; Id : Suite_Id) return Boolean is
      Cursor : Natural := Gaps'First;
   begin
      loop
         declare
            Line_End : Natural :=
              Ada.Strings.Fixed.Index (Gaps (Cursor .. Gaps'Last), [1 => ASCII.LF]);
         begin
            if Line_End = 0 then
               Line_End := Gaps'Last;
            end if;

            declare
               Line : constant String := Gaps (Cursor .. Line_End);
            begin
               if Contains (Line, Label (Id))
                 and then (Contains (Line, "no dedicated")
                           or else Contains (Line, "not exist"))
               then
                  return True;
               end if;
            end;

            exit when Line_End >= Gaps'Last;
            Cursor := Line_End + 1;
         end;
      end loop;
      return False;
   end Declared_Missing;

   procedure Validate (Report : out Validation_Report) is
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Gates_Path)
        or else not Ada.Directories.Exists (Suite_Path)
      then
         Report.Missing_Source := 1;
         Ada.Text_IO.Put_Line ("gap-claims:missing-source");
         return;
      end if;

      declare
         Gates : constant String := Load (Gates_Path);
         Suite : constant String := Load (Suite_Path);
         Gaps  : constant String := Gaps_Section (Gates);
      begin
         for Id in Suite_Id loop
            Report.Claims_Checked := Report.Claims_Checked + 1;

            declare
               Present : constant Boolean := Contains (Suite, """" & Prefix (Id));
               Missing : constant Boolean := Declared_Missing (Gaps, Id);
            begin
               if Present and then Missing then
                  --  The document under-claims: the suite exists.
                  Report.Stale_Gap_Claims := Report.Stale_Gap_Claims + 1;
                  Ada.Text_IO.Put_Line
                    ("gap-claims:stale-gap:" & Label (Id)
                     & ":suite exists but gaps section still lists it as missing");
               elsif not Present and then not Missing then
                  --  The document over-claims: nothing asserts this suite.
                  Report.Missing_Suites := Report.Missing_Suites + 1;
                  Ada.Text_IO.Put_Line
                    ("gap-claims:unrecorded-gap:" & Label (Id)
                     & ":no assertions carry this prefix and no gap is recorded");
               end if;
            end;
         end loop;
      end;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Missing_Source = 0
      and then Report.Claims_Checked > 0
      and then Report.Stale_Gap_Claims = 0
      and then Report.Missing_Suites = 0);

end Identity_Tools_Gap_Claims;

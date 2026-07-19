with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Evidence is

   function Prefix return String is
     (if Ada.Directories.Exists ("registries/release-artifacts.json") then ""
      else "../../");

   function Name (Id : Evidence_Id) return String is
     (case Id is
        when AUnit_Suite     => "aunit",
        when Conformance     => "conformance",
        when Gate_Self_Tests => "gate-selftests",
        when Proof           => "gnatprove",
        when Examples        => "examples");

   function Path (Id : Evidence_Id) return String is
     (Prefix & "generated/evidence/" & Name (Id) & ".txt");

   function State_Image (Value : Evidence_State) return String is
     (case Value is
        when Passed  => "passed",
        when Failed  => "failed",
        when Missing => "missing");

   --  Return the value of "<Key>:" from the evidence file, or "" if absent.
   function Field (Id : Evidence_Id; Key : String) return String is
      File   : Ada.Text_IO.File_Type;
      Marker : constant String := Key & ":";
   begin
      if not Ada.Directories.Exists (Path (Id)) then
         return "";
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path (Id));
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Line'Length > Marker'Length
              and then Line (Line'First .. Line'First + Marker'Length - 1) = Marker
            then
               declare
                  Value : constant String :=
                    Ada.Strings.Fixed.Trim
                      (Line (Line'First + Marker'Length .. Line'Last),
                       Ada.Strings.Both);
               begin
                  Ada.Text_IO.Close (File);
                  return Value;
               end;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return "";
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end Field;

   function State (Id : Evidence_Id) return Evidence_State is
      Value : constant String := Field (Id, "status");
   begin
      if Value = "passed" then
         return Passed;
      elsif Value = "failed" then
         return Failed;
      else
         --  Absent, unreadable, or unrecognised evidence is never a pass.
         return Missing;
      end if;
   end State;

   function Detail (Id : Evidence_Id) return String is
      Value : constant String := Field (Id, "detail");
   begin
      return (if Value = "" then "none" else Value);
   end Detail;

   procedure Validate (Report : out Evidence_Report) is
   begin
      Report := (others => 0);
      for Id in Evidence_Id loop
         case State (Id) is
            when Passed =>
               Report.Present := Report.Present + 1;
               Report.Passed := Report.Passed + 1;
            when Failed =>
               Report.Present := Report.Present + 1;
               Report.Failed := Report.Failed + 1;
               Ada.Text_IO.Put_Line ("evidence:failed:" & Name (Id));
            when Missing =>
               Report.Missing := Report.Missing + 1;
               Ada.Text_IO.Put_Line ("evidence:missing:" & Name (Id));
         end case;
      end loop;
   end Validate;

   function Passed (Report : Evidence_Report) return Boolean is
     (Report.Failed = 0
      and then Report.Missing = 0
      and then Report.Passed = Evidence_Id'Pos (Evidence_Id'Last) + 1);

end Identity_Tools_Evidence;

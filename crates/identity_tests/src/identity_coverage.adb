with Ada.Command_Line;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Text;

--  Code-coverage gate, measured rather than self-reported.
--
--  The identity library is exercised by a whole corpus of instrumented
--  binaries -- the AUnit suite, the conformance harness, the concurrency
--  stress main and the lifecycle example -- not by one suite. This tool builds
--  each crate with gcc coverage instrumentation, runs it, reduces the produced
--  gcov data, and unions the executed lines across every suite: a line counts
--  as covered when any suite reaches it. Measuring a single suite understates
--  coverage of everything the others reach (the Recording decorator, for one,
--  is certified by the conformance harness, not by the AUnit suite).
--
--  Each crate is processed in isolation -- clean, build, run, reduce -- so a
--  later build recompiling the shared library objects can never leave an
--  earlier binary linked against notes it no longer matches. The gate is
--  scored on body (.adb) coverage of src/public + src/adapters; package specs
--  are reported but not gated, since their expression-function lines are
--  verified statically by GNATprove.
procedure Identity_Coverage is

   use Ada.Strings.Unbounded;

   package IO renames Ada.Text_IO;
   package Files renames Project_Tools.Files;
   package Processes renames Project_Tools.Processes;
   package Text renames Project_Tools.Text;

   --  Body coverage below this percentage fails the gate. This is a ratchet set
   --  at the honest measured floor of the whole corpus, not an aspiration: it
   --  catches a regression without failing on noise. The lowest-covered files
   --  the report names are where to raise it from; raise this as they improve,
   --  never lower it silently.
   Minimum_Body       : constant Float := 72.0;
   Minimum_Body_Image : constant String := "72.0";

   --  Line numbers reached, accumulated as sets so the union across suites is
   --  exact: a line covered by any suite is covered, counted once.
   package Line_Sets is new Ada.Containers.Ordered_Sets (Positive);

   type File_Coverage is record
      Executable : Line_Sets.Set;
      Covered    : Line_Sets.Set;
   end record;

   package File_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type => String, Element_Type => File_Coverage);

   Coverage : File_Maps.Map;

   --  One body file's figures, for the lowest-covered listing in the report.
   type File_Stat is record
      Name    : Unbounded_String;
      Covered : Natural;
      Total   : Positive;
      Percent : Float;
   end record;

   package Stat_Vectors is new Ada.Containers.Vectors (Positive, File_Stat);

   function Lower_Percent (Left, Right : File_Stat) return Boolean is
     (Left.Percent < Right.Percent);

   package Stat_Sorting is new Stat_Vectors.Generic_Sorting (Lower_Percent);

   Root : constant String :=
     Files.Find_Root_Upward
       (Ada.Directories.Current_Directory, "tools/release-gates.txt");

   Object_Dir : constant String := Root & "/obj/development";
   Report     : constant String := Root & "/generated/release/coverage.txt";

   Alr_Path  : constant String := Processes.Locate_Command ("alr");
   Gcov_Path : constant String := Processes.Locate_Command ("gcov");

   --  Progress line flushed immediately: child process output bypasses this
   --  program's buffered standard output, so an unflushed trace would appear
   --  out of order or be lost if a step never returns.
   procedure Trace (Message : String) is
   begin
      IO.Put_Line (Message);
      IO.Flush;
   end Trace;

   function Trim (Value : String) return String is
     (Ada.Strings.Fixed.Trim (Value, Ada.Strings.Both));

   --  A percentage rendered to one decimal, without locale-dependent float
   --  formatting: "81.7", "36.2", "0.0".
   function Percent_Image (Covered, Total : Natural) return String is
      Value  : constant Float :=
        (if Total = 0 then 0.0 else 100.0 * Float (Covered) / Float (Total));
      Scaled : constant Integer := Integer (Float'Rounding (Value * 10.0));
   begin
      return Trim (Integer'Image (Scaled / 10)) & "."
        & Trim (Integer'Image (Scaled mod 10));
   end Percent_Image;

   procedure Delete_Matching (Directory : String; Pattern : String) is
   begin
      if Files.Directory_Exists (Directory) then
         declare
            Hits : constant Files.Path_List :=
              Files.List_Tree (Directory, Pattern);
         begin
            for Hit of Hits loop
               Files.Delete_File_If_Present (To_String (Hit));
            end loop;
         end;
      end if;
   end Delete_Matching;

   --  Coverage notes land in the library's obj/ and in each test crate's obj/;
   --  clear all of them so a crate is measured from a clean start.
   procedure Clean_Coverage_Artifacts is
      Object_Dirs : constant array (Positive range <>) of Unbounded_String :=
        [To_Unbounded_String (Root & "/obj"),
         To_Unbounded_String (Root & "/crates/identity_tests/obj"),
         To_Unbounded_String (Root & "/crates/identity_conformance/obj"),
         To_Unbounded_String (Root & "/crates/identity_examples/obj")];
   begin
      for Directory of Object_Dirs loop
         Delete_Matching (To_String (Directory), "*.gcda");
         Delete_Matching (To_String (Directory), "*.gcno");
         Delete_Matching (To_String (Directory), "*.gcov");
      end loop;
   end Clean_Coverage_Artifacts;

   procedure Add_Line
     (Key : String; Line : Positive; Is_Covered : Boolean)
   is
      Position : constant File_Maps.Cursor := Coverage.Find (Key);

      procedure Update (Ignored : String; Element : in out File_Coverage) is
         pragma Unreferenced (Ignored);
      begin
         Element.Executable.Include (Line);
         if Is_Covered then
            Element.Covered.Include (Line);
         end if;
      end Update;
   begin
      if File_Maps.Has_Element (Position) then
         Coverage.Update_Element (Position, Update'Access);
      else
         declare
            Fresh : File_Coverage;
         begin
            Fresh.Executable.Include (Line);
            if Is_Covered then
               Fresh.Covered.Include (Line);
            end if;
            Coverage.Insert (Key, Fresh);
         end;
      end if;
   end Add_Line;

   --  The library-relative key ("src/public/identity-foo.adb") for a gcov
   --  source path, or "" when the path is outside the measured subtree.
   function Library_Key (Source : String) return String is
      In_Public   : constant Natural := Text.Index (Source, "src/public/");
      In_Adapters : constant Natural := Text.Index (Source, "src/adapters/");
   begin
      if In_Public > 0 then
         return Source (In_Public .. Source'Last);
      elsif In_Adapters > 0 then
         return Source (In_Adapters .. Source'Last);
      else
         return "";
      end if;
   end Library_Key;

   --  Parse one .gcov annotated source. Each data line is
   --  "<count>:<line>:<text>"; "-" marks a non-executable line, "#####" and
   --  "=====" an executable line that never ran, any digit a covered line.
   procedure Parse_Gcov (Path : String) is
      Content : constant String := Files.Read_Raw_File (Path);
      Key     : Unbounded_String := Null_Unbounded_String;

      procedure Handle_Line (Line : String) is
         First_Colon  : constant Natural := Text.Index (Line, ":");
         Second_Colon : Natural;
      begin
         if First_Colon = 0 then
            return;
         end if;
         Second_Colon := Text.Index_From (Line, ":", First_Colon + 1);
         if Second_Colon = 0 then
            return;
         end if;

         declare
            Count_Token : constant String :=
              Trim (Line (Line'First .. First_Colon - 1));
            Line_Token  : constant String :=
              Trim (Line (First_Colon + 1 .. Second_Colon - 1));
            Rest        : constant String :=
              Line (Second_Colon + 1 .. Line'Last);
         begin
            --  A header line ("<n>:0:Source:<path>" and friends) resets the
            --  current source; only Source lines carry a path we track.
            if Line_Token = "0" then
               if Text.Starts_With (Rest, "Source:") then
                  Key := To_Unbounded_String
                    (Library_Key (Rest (Rest'First + 7 .. Rest'Last)));
               end if;
               return;
            end if;

            if Key = Null_Unbounded_String
              or else Count_Token'Length = 0
              or else Line_Token'Length = 0
            then
               return;
            end if;

            declare
               First   : constant Character := Count_Token (Count_Token'First);
               Covered : constant Boolean := First /= '#' and then First /= '=';
            begin
               if First = '-' then
                  return;
               end if;
               Add_Line
                 (To_String (Key), Positive'Value (Line_Token), Covered);
            exception
               when Constraint_Error =>
                  return;
            end;
         end;
      end Handle_Line;

      Start : Positive := Content'First;
   begin
      if Content'Length = 0 then
         return;
      end if;
      for Index in Content'Range loop
         if Content (Index) = ASCII.LF then
            Handle_Line (Content (Start .. Index - 1));
            Start := Index + 1;
         end if;
      end loop;
      if Start <= Content'Last then
         Handle_Line (Content (Start .. Content'Last));
      end if;
   end Parse_Gcov;

   --  Turn the .gcda the last runs produced into per-line coverage, union it
   --  into the map, and remove the .gcov files so the next crate starts clean.
   procedure Reduce_With_Gcov is
      Data : constant Files.Path_List :=
        Files.List_Tree (Object_Dir, "identity*.gcda");
   begin
      if Data'Length = 0 then
         return;
      end if;

      declare
         Args : GNAT.OS_Lib.Argument_List (1 .. Data'Length + 1);
      begin
         Args (1) := new String'("-b");
         for Index in Data'Range loop
            Args (Index + 1) :=
              new String'(Ada.Directories.Simple_Name (To_String (Data (Index))));
         end loop;
         declare
            Status : constant Integer :=
              Processes.Run_Status
                ("gcov", Object_Dir, Gcov_Path, Args, Quiet => True);
            pragma Unreferenced (Status);
         begin
            null;
         end;
      end;

      declare
         Reports : constant Files.Path_List :=
           Files.List_Tree (Object_Dir, "*.gcov");
      begin
         for Item of Reports loop
            Parse_Gcov (To_String (Item));
         end loop;
      end;
      Delete_Matching (Object_Dir, "*.gcov");
   end Reduce_With_Gcov;

   --  Build a crate, instrumented or plain. Force (-f) is used only on the one
   --  build that compiles the library, so fresh .gcno exist after the artifacts
   --  are cleaned; the later crate builds reuse those instrumented objects
   --  unchanged, so every corpus binary links the same library and their .gcda
   --  merge cleanly instead of a rebuild leaving an earlier binary mismatched.
   function Build
     (Crate_Dir  : String;
      Instrument : Boolean;
      Force      : Boolean := False) return Boolean
   is
      Forced_Args : constant GNAT.OS_Lib.Argument_List :=
        [new String'("build"),
         new String'("--"),
         new String'("-f"),
         new String'("-cargs"),
         new String'("-fprofile-arcs"),
         new String'("-ftest-coverage"),
         new String'("-largs"),
         new String'("-fprofile-arcs")];
      Instrumented_Args : constant GNAT.OS_Lib.Argument_List :=
        [new String'("build"),
         new String'("--"),
         new String'("-cargs"),
         new String'("-fprofile-arcs"),
         new String'("-ftest-coverage"),
         new String'("-largs"),
         new String'("-fprofile-arcs")];
      Plain_Args : constant GNAT.OS_Lib.Argument_List := [new String'("build")];
      Status     : Integer;
   begin
      if not Instrument then
         Status :=
           Processes.Run_Status
             ("build", Crate_Dir, Alr_Path, Plain_Args, Quiet => True);
      elsif Force then
         Status :=
           Processes.Run_Status
             ("build", Crate_Dir, Alr_Path, Forced_Args, Quiet => True);
      else
         Status :=
           Processes.Run_Status
             ("build", Crate_Dir, Alr_Path, Instrumented_Args, Quiet => True);
      end if;
      return Status = 0;
   end Build;

   --  Build one crate instrumented; report the failure marker on fault. Force
   --  is set on the crate whose build compiles the library.
   function Build_Instrumented
     (Crate_Dir : String; Force : Boolean := False) return Boolean is
   begin
      Trace ("coverage:phase:build:" & Ada.Directories.Simple_Name (Crate_Dir));
      if Build (Crate_Dir, Instrument => True, Force => Force) then
         return True;
      end if;
      IO.Put_Line
        ("release-check:coverage:failed:instrumented-build:"
         & Ada.Directories.Simple_Name (Crate_Dir));
      return False;
   end Build_Instrumented;

   --  Run one suite by exit status; coverage is never a reason to accept a red
   --  suite, and each suite already fails non-zero on any fault (the release
   --  check verifies their markers separately). Every run appends to the
   --  shared .gcda counters of the single instrumented library build, so the
   --  suites' reach accumulates as their union.
   function Run_Suite (Bin : String) return Boolean is
      No_Args : constant GNAT.OS_Lib.Argument_List := [];
   begin
      Trace ("coverage:phase:run:" & Ada.Directories.Simple_Name (Bin));
      if Processes.Run_Status ("run", Root, Bin, No_Args, Quiet => True) = 0 then
         return True;
      end if;
      IO.Put_Line
        ("release-check:coverage:failed:suite:"
         & Ada.Directories.Simple_Name (Bin));
      return False;
   end Run_Suite;

   --  Leave the tree with normal, non-instrumented objects for the gates that
   --  run after this one. Every crate is rebuilt even if an earlier rebuild
   --  fails, so the tree is never left half-instrumented.
   procedure Restore_Build is
   begin
      Clean_Coverage_Artifacts;
      declare
         Rebuilt_Tests : constant Boolean :=
           Build (Root & "/crates/identity_tests", Instrument => False);
         Rebuilt_Conformance : constant Boolean :=
           Build (Root & "/crates/identity_conformance", Instrument => False);
         Rebuilt_Examples : constant Boolean :=
           Build (Root & "/crates/identity_examples", Instrument => False);
      begin
         if not (Rebuilt_Tests and then Rebuilt_Conformance
                 and then Rebuilt_Examples)
         then
            IO.Put_Line ("release-check:coverage:note:restore-build-incomplete");
         end if;
      end;
   end Restore_Build;

   Tests_Dir       : constant String := Root & "/crates/identity_tests";
   Conformance_Dir : constant String := Root & "/crates/identity_conformance";
   Examples_Dir    : constant String := Root & "/crates/identity_examples";

   Measured : Boolean;

   Body_Executable, Body_Covered : Natural := 0;
   Spec_Executable, Spec_Covered : Natural := 0;
   Lowest : Stat_Vectors.Vector;

begin
   if Root = "" then
      IO.Put_Line ("release-check:coverage:failed:root-not-found");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   if Alr_Path = "" or else Gcov_Path = "" then
      IO.Put_Line ("release-check:coverage:failed:toolchain-missing");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   --  Instrument the library once, then run the whole corpus against that one
   --  build so their executed lines merge into a single set of .gcda.
   Trace ("coverage:phase:clean");
   Clean_Coverage_Artifacts;

   --  The tests build compiles the library (Force regenerates .gcno after the
   --  clean); conformance and examples reuse those instrumented objects.
   Measured :=
     Build_Instrumented (Tests_Dir, Force => True)
     and then Build_Instrumented (Conformance_Dir)
     and then Build_Instrumented (Examples_Dir);

   if Measured then
      Measured :=
        Run_Suite (Tests_Dir & "/bin/identity_tests")
        and then Run_Suite (Conformance_Dir & "/bin/identity_conformance")
        and then Run_Suite (Conformance_Dir & "/bin/identity_concurrency")
        and then Run_Suite (Examples_Dir & "/bin/identity_lifecycle");
   end if;

   if Measured then
      Trace ("coverage:phase:reduce");
      Reduce_With_Gcov;
   end if;

   --  Restore a clean build regardless of the measurement outcome.
   Trace ("coverage:phase:restore");
   Restore_Build;

   if not Measured then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   for Position in Coverage.Iterate loop
      declare
         Key      : constant String := File_Maps.Key (Position);
         Element  : constant File_Coverage := File_Maps.Element (Position);
         Total    : constant Natural := Natural (Element.Executable.Length);
         Reached  : constant Natural := Natural (Element.Covered.Length);
      begin
         if Text.Ends_With (Key, ".adb") then
            Body_Executable := Body_Executable + Total;
            Body_Covered := Body_Covered + Reached;
            if Total > 0 then
               Lowest.Append
                 (File_Stat'
                    (Name    => To_Unbounded_String
                       (Key (Key'First + 4 .. Key'Last)),
                     Covered => Reached,
                     Total   => Total,
                     Percent => 100.0 * Float (Reached) / Float (Total)));
            end if;
         else
            Spec_Executable := Spec_Executable + Total;
            Spec_Covered := Spec_Covered + Reached;
         end if;
      end;
   end loop;

   if Body_Executable = 0 then
      IO.Put_Line ("release-check:coverage:failed:no-measurement");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Stat_Sorting.Sort (Lowest);

   declare
      Combined_Covered : constant Natural := Body_Covered + Spec_Covered;
      Combined_Total   : constant Natural := Body_Executable + Spec_Executable;
      Body_Value       : constant Float :=
        100.0 * Float (Body_Covered) / Float (Body_Executable);
      Content          : Unbounded_String := Null_Unbounded_String;
      Shown            : Natural := 0;

      procedure Line (Value : String) is
      begin
         Append (Content, Value & ASCII.LF);
      end Line;
   begin
      Line ("identity library code coverage (measured via gcc/gcov)");
      Line ("scope: src/public + src/adapters; corpus: aunit + conformance"
            & " + concurrency + examples");
      Line ("");
      Line ("body (.adb)  " & Trim (Integer'Image (Body_Covered)) & "/"
            & Trim (Integer'Image (Body_Executable)) & " = "
            & Percent_Image (Body_Covered, Body_Executable)
            & "%  [gated, min " & Minimum_Body_Image & "%]");
      Line ("spec (.ads)  " & Trim (Integer'Image (Spec_Covered)) & "/"
            & Trim (Integer'Image (Spec_Executable)) & " = "
            & Percent_Image (Spec_Covered, Spec_Executable)
            & "%  [reported, GNATprove-verified]");
      Line ("combined     " & Trim (Integer'Image (Combined_Covered)) & "/"
            & Trim (Integer'Image (Combined_Total)) & " = "
            & Percent_Image (Combined_Covered, Combined_Total) & "%");
      Line ("");
      Line ("lowest-covered body files:");
      for Stat of Lowest loop
         exit when Shown = 15;
         Line ("  " & Percent_Image (Stat.Covered, Stat.Total)
               & "%  " & To_String (Stat.Name));
         Shown := Shown + 1;
      end loop;

      Ada.Directories.Create_Path (Root & "/generated/release");
      Files.Write_Text_File (Report, To_String (Content));

      if Body_Value < Minimum_Body then
         IO.Put_Line
           ("release-check:coverage:failed:body-"
            & Percent_Image (Body_Covered, Body_Executable)
            & "%-below-min-" & Minimum_Body_Image & "%");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      else
         IO.Put_Line
           ("release-check:coverage:passed:body-"
            & Percent_Image (Body_Covered, Body_Executable)
            & "%-min-" & Minimum_Body_Image & "%");
      end if;
   end;
exception
   when E : others =>
      Trace
        ("release-check:coverage:failed:exception:"
         & Ada.Exceptions.Exception_Name (E)
         & ": " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Identity_Coverage;

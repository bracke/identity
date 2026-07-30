--  gate_selftests -- negative-test harness for the identity_tools release gates.
--
--  Every release gate implemented by crates/identity_tools asserts that some
--  piece of evidence exists (a registry entry, a fixture file, a workflow gate
--  id, ...). This harness proves those gates actually FAIL when the evidence is
--  removed: a gate that never fires is indistinguishable from one that always
--  passes.
--
--  For each negative case the harness copies the repository into a throwaway
--  directory, applies exactly one targeted mutation there, runs the ORIGINAL
--  identity_tools executable with that copy as its working directory, and
--  requires both a non-zero exit status AND the specific diagnostic marker
--  belonging to the mutated gate. Requiring the marker is what keeps the suite
--  honest: the tool already exits non-zero for unrelated reasons, so an
--  exit-code-only assertion would pass vacuously even if the mutation silently
--  failed to apply. Each mutation additionally verifies that it changed
--  something and aborts the case if it did not.
--
--  Positive cases assert that the tool (and the sibling harnesses referenced by
--  the invariant registry) actually report the counts they claim to report.
--
--  Each case label is printed verbatim; the labels are the "required_tests"
--  names from registries/invariants.json and are matched literally by the
--  traceability validator in identity_tools_invariants.adb.
--
--  Usage: gate_selftests [repo-root]

with Ada.Calendar;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Text;

with Representation;
with Representation.Documents;
with Representation.Inputs;
with Representation.JSON.Documents;

procedure Gate_Selftests is

   package Files renames Project_Tools.Files;
   package Processes renames Project_Tools.Processes;
   package DM renames Representation.Documents;
   package JD renames Representation.JSON.Documents;

   use Ada.Strings.Unbounded;
   use type DM.Node_Ref;
   use type DM.Node_Kind;

   subtype Byte is Representation.Byte;
   subtype Byte_Array is Representation.Byte_Array;

   type Str_Array is array (Positive range <>) of Unbounded_String;

   Empty_Names : constant Files.Name_List (1 .. 0) := [others => <>];

   DQ  : constant String := [1 => '"'];
   LF  : constant Character := Character'Val (16#0A#);
   Sep : constant String := [1 => Character'Val (16#1F#)];

   --  Repository root and the executables/inputs the harness drives.
   Repo            : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Directories.Full_Name (Ada.Command_Line.Argument (1))
      else Ada.Directories.Current_Directory);
   Tool            : constant String :=
     Repo & "/crates/identity_tools/bin/identity_tools";
   Tests_Bin       : constant String :=
     Repo & "/crates/identity_tests/bin/identity_tests";
   Conformance_Bin : constant String :=
     Repo & "/crates/identity_conformance/bin/identity_conformance";
   Examples_Bin    : constant String :=
     Repo & "/crates/identity_examples/bin/identity_lifecycle";
   Manifest        : constant String :=
     Repo & "/tools/project_tools_workflows.toml";
   Suite_Src       : constant String :=
     Repo & "/crates/identity_tests/src/identity_tests_cases.adb";

   Work_Dir      : Unbounded_String;
   Baseline_File : Unbounded_String;
   Out_File      : Unbounded_String;

   Total_Cases  : Natural := 0;
   Passed_Cases : Natural := 0;
   Failed_Cases : Natural := 0;

   Copy_Counter : Natural := 0;

   ---------------------------------------------------------------------------
   --  Small string utilities
   ---------------------------------------------------------------------------

   function U (Item : String) return Unbounded_String
     renames To_Unbounded_String;

   function Img (Value : Integer) return String is
     (Ada.Strings.Fixed.Trim (Value'Image, Ada.Strings.Both));

   function Contains (Text : String; Pattern : String) return Boolean is
     (Project_Tools.Text.Contains (Text, Pattern));

   function Read_File (Path : String) return String is
     (if Files.File_Exists (Path) then Files.Read_Raw_File (Path) else "");

   ---------------------------------------------------------------------------
   --  Reporting
   ---------------------------------------------------------------------------

   procedure Note (Message : String) is
   begin
      Ada.Text_IO.Put_Line ("gate-selftest:note:" & Message);
   end Note;

   procedure Record_Case (Name : String; Passed : Boolean) is
   begin
      Total_Cases := Total_Cases + 1;
      if Passed then
         Passed_Cases := Passed_Cases + 1;
         Ada.Text_IO.Put_Line ("gate-selftest:PASS:" & Name);
      else
         Failed_Cases := Failed_Cases + 1;
         Ada.Text_IO.Put_Line ("gate-selftest:FAIL:" & Name);
      end if;
   end Record_Case;

   ---------------------------------------------------------------------------
   --  Assertion helpers
   ---------------------------------------------------------------------------

   --  True when Line contains every substring in Parts.
   function Line_Matches (Line : String; Parts : Str_Array) return Boolean is
   begin
      for Part of Parts loop
         if not Contains (Line, To_String (Part)) then
            return False;
         end if;
      end loop;
      return True;
   end Line_Matches;

   --  True when some single line of Path contains every substring in Parts.
   function Line_Has_All (Path : String; Parts : Str_Array) return Boolean is
      Content : constant String := Read_File (Path);
      Start   : Positive := (if Content'Length = 0 then 1 else Content'First);
   begin
      if Content'Length = 0 then
         return False;
      end if;
      for I in Content'Range loop
         if Content (I) = LF then
            if Line_Matches (Content (Start .. I - 1), Parts) then
               return True;
            end if;
            Start := I + 1;
         end if;
      end loop;
      if Start <= Content'Last then
         return Line_Matches (Content (Start .. Content'Last), Parts);
      end if;
      return False;
   end Line_Has_All;

   --  Split a Sep-joined requirement into its substrings.
   function Split_Requirement (Requirement : String) return Str_Array is
      Count : Natural := 1;
   begin
      for I in Requirement'Range loop
         if Requirement (I) = Sep (Sep'First) then
            Count := Count + 1;
         end if;
      end loop;
      declare
         Result : Str_Array (1 .. Count);
         Index  : Positive := 1;
         Start  : Positive := Requirement'First;
      begin
         for I in Requirement'Range loop
            if Requirement (I) = Sep (Sep'First) then
               Result (Index) := U (Requirement (Start .. I - 1));
               Index := Index + 1;
               Start := I + 1;
            end if;
         end loop;
         Result (Index) := U (Requirement (Start .. Requirement'Last));
         return Result;
      end;
   end Split_Requirement;

   --  A Sep-joined requirement expands to same-line substrings, checked in Path.
   function Has_Requirement (Path : String; Requirement : String)
      return Boolean is
     (Line_Has_All (Path, Split_Requirement (Requirement)));

   --  Rendered form of a requirement for diagnostics.
   function Humanize (Requirement : String) return String is
      Result : Unbounded_String;
   begin
      for I in Requirement'Range loop
         if Requirement (I) = Sep (Sep'First) then
            Append (Result, " + ");
         else
            Append (Result, Requirement (I));
         end if;
      end loop;
      return To_String (Result);
   end Humanize;

   --  True when Path exists and each substring in Parts occurs somewhere in it.
   function File_Has_All (Path : String; Parts : Str_Array) return Boolean is
      Content : constant String := Read_File (Path);
   begin
      if not Files.File_Exists (Path) then
         return False;
      end if;
      for Part of Parts loop
         if not Contains (Content, To_String (Part)) then
            return False;
         end if;
      end loop;
      return True;
   end File_Has_All;

   --  Number of lines of Path that contain Pattern.
   function Count_Lines_Containing (Path : String; Pattern : String)
      return Natural
   is
      Content : constant String := Read_File (Path);
      Start   : Positive := (if Content'Length = 0 then 1 else Content'First);
      Hits    : Natural := 0;
   begin
      if Content'Length = 0 then
         return 0;
      end if;
      for I in Content'Range loop
         if Content (I) = LF then
            if Contains (Content (Start .. I - 1), Pattern) then
               Hits := Hits + 1;
            end if;
            Start := I + 1;
         end if;
      end loop;
      if Start <= Content'Last
        and then Contains (Content (Start .. Content'Last), Pattern)
      then
         Hits := Hits + 1;
      end if;
      return Hits;
   end Count_Lines_Containing;

   ---------------------------------------------------------------------------
   --  Repository copy / tool invocation
   ---------------------------------------------------------------------------

   --  Copy the repository into a fresh directory under Work_Dir. Build products
   --  and VCS metadata are excluded: identity_tools never reads them and they
   --  dominate the copy cost.
   function Make_Copy return String is
   begin
      Copy_Counter := Copy_Counter + 1;
      declare
         Target : constant String :=
           To_String (Work_Dir) & "/copy-" & Img (Copy_Counter);
      begin
         Files.Copy_Filtered_Tree
           (Source_Dir   => Repo,
            Target_Dir   => Target,
            Skip_Entries =>
              [U ("obj"), U ("alire"), U (".git"), U ("lib"), U ("bin")],
            Skip_Files   => Empty_Names,
            Quiet        => True);
         return Target;
      exception
         when others =>
            Files.Delete_Tree (Target);
            return "";
      end;
   end Make_Copy;

   --  Run Program in Dir, capturing stdout and stderr into Output_Path.
   function Run_Captured
     (Dir : String; Program : String; Output_Path : String) return Integer is
     (Processes.Run_Shell_In_Directory
        (Directory   => Dir,
         Command     => Processes.Shell_Quote (Program),
         Quiet       => True,
         Output_File => Output_Path));

   --  Recursively count the ordinary files under Path.
   function Count_Files (Path : String) return Natural is
   begin
      if not Files.Directory_Exists (Path) then
         return 0;
      end if;
      return Files.List_Tree (Path)'Length;
   end Count_Files;

   ---------------------------------------------------------------------------
   --  Mutation primitives
   ---------------------------------------------------------------------------

   --  Rewrite Path applying Mode to lines that contain Pattern. Modes:
   --  delete-all, delete-first, replace-all, replace-first, set-line-first.
   --  Returns False when Pattern matched nothing, so a stale pattern aborts its
   --  case instead of producing a vacuous pass.
   function Edit_File
     (Path        : String;
      Mode        : String;
      Pattern     : String;
      Replacement : String := "") return Boolean
   is
      Content  : constant String := Read_File (Path);
      Is_First : constant Boolean := Project_Tools.Text.Ends_With (Mode, "-first");
      Result   : Unbounded_String;
      Hits     : Natural := 0;

      procedure Process_Line (Line : String) is
      begin
         if Contains (Line, Pattern)
           and then not (Hits > 0 and then Is_First)
         then
            Hits := Hits + 1;
            if Project_Tools.Text.Starts_With (Mode, "delete") then
               null;
            elsif Project_Tools.Text.Starts_With (Mode, "replace") then
               declare
                  Rewritten : Unbounded_String;
                  Cursor    : Positive := Line'First;
               begin
                  while Cursor <= Line'Last loop
                     if Cursor + Pattern'Length - 1 <= Line'Last
                       and then Line (Cursor .. Cursor + Pattern'Length - 1)
                                  = Pattern
                     then
                        Append (Rewritten, Replacement);
                        Cursor := Cursor + Pattern'Length;
                     else
                        Append (Rewritten, Line (Cursor));
                        Cursor := Cursor + 1;
                     end if;
                  end loop;
                  Append (Result, Rewritten);
               end;
            elsif Mode = "set-line-first" then
               Append (Result, Replacement & LF);
            end if;
         else
            Append (Result, Line);
         end if;
      end Process_Line;

      Start : Positive := (if Content'Length = 0 then 1 else Content'First);
   begin
      if not Files.File_Exists (Path) then
         return False;
      end if;
      for I in Content'Range loop
         if Content (I) = LF then
            Process_Line (Content (Start .. I));
            Start := I + 1;
         end if;
      end loop;
      if Start <= Content'Last then
         Process_Line (Content (Start .. Content'Last));
      end if;
      if Hits = 0 then
         return False;
      end if;
      Files.Write_Raw_File (Path, To_String (Result));
      return True;
   end Edit_File;

   --  Append a single Line (plus a line feed) to an existing file.
   function Append_Line_To (Path : String; Line : String) return Boolean is
   begin
      if not Files.File_Exists (Path) then
         return False;
      end if;
      Files.Append_Text_File (Path, Line & LF);
      return True;
   end Append_Line_To;

   ---------------------------------------------------------------------------
   --  Mutations. Both assembled boundary/secret words are built at run time so
   --  the harness never plants the literals it is asserting about into a
   --  scanned file.
   ---------------------------------------------------------------------------

   function Mut_Architecture (Dir : String) return Boolean is
     (Append_Line_To
        (Dir & "/src/public/identity-versions.ads",
         "--  ro" & "le assignment placeholder inserted by gate-selftests")
      and then Append_Line_To
        (Dir & "/src/public/identity-events-types.ads",
         "with Crypto" & "Lib.Hashes;"));

   function Mut_Canary (Dir : String) return Boolean is
   begin
      Ada.Directories.Create_Path (Dir & "/docs");
      Files.Write_Raw_File
        (Dir & "/docs/gate-selftest-canary.md",
         "# leak fixture" & LF & LF & "password: "
         & ("CAN" & "ARY-password-123") & LF);
      return True;
   end Mut_Canary;

   function Mut_Coverage_Evidence (Dir : String) return Boolean is
   begin
      Ada.Directories.Create_Path (Dir & "/generated/evidence");
      Files.Write_Raw_File
        (Dir & "/generated/evidence/coverage.txt",
         "status:failed" & LF & "detail:body-0.0%-below-min-80.0%" & LF);
      return True;
   end Mut_Coverage_Evidence;

   function Mut_Drop_Registry_Event (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/event-types.json", "delete-all",
         DQ & "identity.api-key.revoked" & DQ));

   function Mut_Drop_Public_Event (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/src/public/identity-events-types.ads", "delete-all",
         DQ & "identity.api-key.revoked" & DQ));

   function Mut_Sensitive_Artifact (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/release-artifacts.json", "replace-first",
         DQ & "contains_sensitive_material" & DQ & ": false",
         DQ & "contains_sensitive_material" & DQ & ": true"));

   function Mut_Drop_Required_Artifact (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/release-artifacts.json", "delete-all",
         DQ & "identity.artifact-digests" & DQ));

   function Mut_Drop_Requirement (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/persisted-formats.json", "delete-all",
         DQ & "bounded" & DQ & ": true"));

   function Mut_Drop_Format (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/persisted-formats.json", "delete-all",
         DQ & "identity.event.canonical-envelope" & DQ));

   function Mut_Drop_Fixture_File (Dir : String) return Boolean is
      Target : constant String :=
        Dir & "/fixtures/persisted-formats/secret-verifier-current.json";
   begin
      if not Files.File_Exists (Target) then
         return False;
      end if;
      Files.Delete_File_If_Present (Target);
      return not Files.Exists (Target);
   end Mut_Drop_Fixture_File;

   function Mut_Drop_Algorithm (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/crypto-algorithms.json", "delete-all",
         DQ & "identity.sha256-domain-verifier" & DQ));

   function Mut_Drop_Implementation (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/crypto-algorithms.json", "delete-all",
         DQ & "implementation" & DQ & ": " & DQ & "cryptolib" & DQ));

   function Mut_Drop_Permissions (Dir : String) return Boolean is
      Registry : constant String := Dir & "/registries/crypto-algorithms.json";
   begin
      return Edit_File
               (Registry, "delete-all", DQ & "creation_allowed" & DQ & ": true")
        and then Edit_File
               (Registry, "delete-all",
                DQ & "verification_allowed" & DQ & ": true");
   end Mut_Drop_Permissions;

   function Mut_Drop_Severity (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/invariants.json", "replace-first",
         DQ & "failure_severity" & DQ & ":",
         DQ & "failure_severity_withdrawn" & DQ & ":"));

   function Mut_Empty_Required_Tests (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/registries/invariants.json", "set-line-first",
         DQ & "required_tests" & DQ & ": [",
         "      " & DQ & "required_tests" & DQ & ": [],"));

   function Mut_Drop_Gate (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/tools/project_tools_workflows.toml", "replace-all",
         DQ & "identity-tools-events" & DQ,
         DQ & "identity-tools-events-withdrawn" & DQ));

   function Mut_Drop_Workflow (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/tools/project_tools_workflows.toml", "replace-all",
         "name = " & DQ & "fixtures-check" & DQ,
         "name = " & DQ & "fixtures-check-withdrawn" & DQ));

   function Mut_Drop_Orchestrator (Dir : String) return Boolean is
     (Edit_File
        (Dir & "/tools/project_tools_workflows.toml", "delete-all",
         "required = " & DQ & "project_tools" & DQ));

   ---------------------------------------------------------------------------
   --  Case runners
   ---------------------------------------------------------------------------

   --  A negative case: Dir is the mutated copy ("" when the copy failed),
   --  Applied says the mutation changed something, and Req_A/Req_B are the
   --  Sep-joined markers that must appear once the tool exits non-zero.
   procedure Run_Negative
     (Name    : String;
      Dir     : String;
      Applied : Boolean;
      Req_A   : String;
      Req_B   : String := "")
   is
      Ok     : Boolean := False;
      Status : Integer;
   begin
      if Dir = "" then
         Note (Name & ": repository copy failed");
      elsif not Applied then
         Note (Name & ": mutation did not apply");
      else
         Status := Run_Captured (Dir, Tool, To_String (Out_File));
         if Status = 0 then
            Note (Name & ": tool exited 0 after mutation");
         else
            Ok := True;
            if not Has_Requirement (To_String (Out_File), Req_A) then
               Note (Name & ": expected marker absent: " & Humanize (Req_A));
               Ok := False;
            end if;
            if Req_B'Length > 0
              and then not Has_Requirement (To_String (Out_File), Req_B)
            then
               Note (Name & ": expected marker absent: " & Humanize (Req_B));
               Ok := False;
            end if;
         end if;
      end if;
      if Dir /= "" then
         Files.Delete_Tree (Dir);
      end if;
      Record_Case (Name, Ok);
   end Run_Negative;

   --  A positive baseline case: the substrings must share one line of BASELINE.
   procedure Base_Line (Name : String; Parts : Str_Array) is
   begin
      Record_Case (Name, Line_Has_All (To_String (Baseline_File), Parts));
   end Base_Line;

   --  A manifest-gate positive case: the gate id must be listed in the manifest.
   procedure Manifest_Gate (Name : String; Gate : String) is
      Ok : constant Boolean := File_Has_All (Manifest, [U (DQ & Gate & DQ)]);
   begin
      if not Ok then
         Note (Name & ": gate not listed in " & Manifest & ": " & Gate);
      end if;
      Record_Case (Name, Ok);
   end Manifest_Gate;

   ---------------------------------------------------------------------------
   --  JSON: the fixtures listed by registries/persisted-formats.json.
   ---------------------------------------------------------------------------

   function To_Bytes (Value : String) return Byte_Array is
      Result : Byte_Array (1 .. Value'Length);
   begin
      for I in Result'Range loop
         Result (I) := Byte (Character'Pos (Value (Value'First + I - 1)));
      end loop;
      return Result;
   end To_Bytes;

   function To_Str (Value : Byte_Array) return String is
      Result : String (1 .. Value'Length);
   begin
      for I in Result'Range loop
         Result (I) := Character'Val (Natural (Value (Value'First + I - 1)));
      end loop;
      return Result;
   end To_Str;

   function Persisted_Fixtures (Path : String) return Str_Array is
      Content : constant String := Read_File (Path);
      Buffer  : array (1 .. 1024) of Unbounded_String;
      Count   : Natural := 0;
   begin
      if Content'Length = 0 then
         return [1 .. 0 => <>];
      end if;
      declare
         Data    : aliased constant Byte_Array := To_Bytes (Content);
         Src     : aliased Representation.Inputs.Array_Source (Data'Access);
         Doc     : DM.Document (Node_Capacity => 8192, Text_Capacity => 131_072);
         Outcome : JD.Decode_Result;
         Root    : DM.Node_Ref;
         Formats : DM.Node_Ref;
      begin
         JD.Decode (Doc, Src'Access, Outcome);
         if not Outcome.Ok then
            return [1 .. 0 => <>];
         end if;
         Root := DM.Root (Doc);
         Formats := DM.Find (Doc, Root, To_Bytes ("formats"));
         if Formats = DM.No_Node then
            return [1 .. 0 => <>];
         end if;
         for I in 1 .. DM.Length (Doc, Formats) loop
            declare
               Entry_Node    : constant DM.Node_Ref := DM.Element (Doc, Formats, I);
               Fixtures_Node : constant DM.Node_Ref :=
                 DM.Find (Doc, Entry_Node, To_Bytes ("fixtures"));
            begin
               if Fixtures_Node /= DM.No_Node then
                  for J in 1 .. DM.Length (Doc, Fixtures_Node) loop
                     declare
                        Fx : constant DM.Node_Ref :=
                          DM.Element (Doc, Fixtures_Node, J);
                     begin
                        if DM.Kind (Doc, Fx) = DM.String_Node
                          and then Count < Buffer'Last
                        then
                           Count := Count + 1;
                           Buffer (Count) := U (To_Str (DM.Text (Doc, Fx)));
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end;
      return Result : Str_Array (1 .. Count) do
         for K in 1 .. Count loop
            Result (K) := Buffer (K);
         end loop;
      end return;
   end Persisted_Fixtures;

   ---------------------------------------------------------------------------
   --  Sibling-harness and version helpers
   ---------------------------------------------------------------------------

   --  Whether BASELINE reports version metadata:
   --  ^identity_tools:identity: N. N. N:
   function Reports_Version (Content : String) return Boolean is
      Prefix : constant String := "identity_tools:identity: ";

      function Line_Reports_Version (Line : String) return Boolean is
         Pos : Positive;

         function Consume_Digits return Boolean is
            Seen : Natural := 0;
         begin
            while Pos <= Line'Last and then Line (Pos) in '0' .. '9' loop
               Pos := Pos + 1;
               Seen := Seen + 1;
            end loop;
            return Seen > 0;
         end Consume_Digits;

         function Consume (Literal : String) return Boolean is
         begin
            if Pos + Literal'Length - 1 <= Line'Last
              and then Line (Pos .. Pos + Literal'Length - 1) = Literal
            then
               Pos := Pos + Literal'Length;
               return True;
            end if;
            return False;
         end Consume;
      begin
         if not Project_Tools.Text.Starts_With (Line, Prefix) then
            return False;
         end if;
         Pos := Line'First + Prefix'Length;
         return Consume_Digits and then Consume (". ")
           and then Consume_Digits and then Consume (". ")
           and then Consume_Digits and then Consume (":");
      end Line_Reports_Version;

      Start : Positive := (if Content'Length = 0 then 1 else Content'First);
   begin
      if Content'Length = 0 then
         return False;
      end if;
      for I in Content'Range loop
         if Content (I) = LF then
            if Line_Reports_Version (Content (Start .. I - 1)) then
               return True;
            end if;
            Start := I + 1;
         end if;
      end loop;
      if Start <= Content'Last then
         return Line_Reports_Version (Content (Start .. Content'Last));
      end if;
      return False;
   end Reports_Version;

begin
   ---------------------------------------------------------------------------
   --  Working directory and baseline
   ---------------------------------------------------------------------------

   if not Files.File_Exists (Tool) then
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "gate-selftest:error:missing-executable:" & Tool);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   declare
      Token : constant Natural :=
        Natural (Ada.Calendar.Seconds (Ada.Calendar.Clock)) mod 100_000;
      Base  : constant String := Files.Temp_Dir;
      Index : Natural := 0;
   begin
      loop
         declare
            Candidate : constant String :=
              Base & "/identity-gate-selftests-" & Img (Token) & "-"
              & Img (Index);
         begin
            exit when not Files.Exists (Candidate);
            Index := Index + 1;
         end;
      end loop;
      Work_Dir :=
        U (Base & "/identity-gate-selftests-" & Img (Token) & "-" & Img (Index));
      Ada.Directories.Create_Path (To_String (Work_Dir));
   end;
   Baseline_File := U (To_String (Work_Dir) & "/baseline.txt");
   Out_File := U (To_String (Work_Dir) & "/tool-out.txt");

   declare
      Baseline_RC : constant Integer :=
        Run_Captured (Repo, Tool, To_String (Baseline_File));
   begin
      Ada.Text_IO.Put_Line ("gate-selftest:baseline-exit:" & Img (Baseline_RC));
   end;

   ---------------------------------------------------------------------------
   --  Sibling harnesses (evidence owned by AUnit / conformance / example crates)
   ---------------------------------------------------------------------------

   declare
      Aunit_Out : constant String := To_String (Work_Dir) & "/aunit.txt";
      Aunit_RC  : Integer := 1;
   begin
      if Files.File_Exists (Tests_Bin) then
         Aunit_RC := Run_Captured (Repo, Tests_Bin, Aunit_Out);
      end if;
      Record_Case
        ("AUnit verifies expanded public event constants",
         Aunit_RC = 0
         and then File_Has_All
           (Suite_Src,
            [U ("expanded V1 event constants remain public"),
             U ("Identity.Events.Types.Session_Created"),
             U ("Identity.Events.Types.Password_Reset_Requested"),
             U ("Identity.Events.Types.TOTP_Replay_Detected")]));
   end;

   declare
      Conf_Out : constant String := To_String (Work_Dir) & "/conformance.txt";
      Conf_RC  : Integer := 1;
   begin
      Files.Write_Raw_File (Conf_Out, "");
      if Files.File_Exists (Conformance_Bin) then
         Conf_RC := Run_Captured (Repo, Conformance_Bin, Conf_Out);
      end if;
      Record_Case
        ("identity_conformance builds and executable reports all V1 profiles"
         & " passed",
         Conf_RC = 0
         and then File_Has_All
           (Conf_Out, [U ("identity_conformance:crypto-core-v1:passed")])
         and then not Contains (Read_File (Conf_Out), ":failed"));
      Record_Case
        ("identity_conformance reports all V1 certification profiles",
         Conf_RC = 0
         and then File_Has_All
           (Conf_Out,
            [U ("identity_conformance:core-identity-store:passed"),
             U ("identity_conformance:interactive-authentication-store:passed"),
             U ("identity_conformance:session-store:passed"),
             U ("identity_conformance:recovery-store:passed"),
             U ("identity_conformance:federated-identity-store:passed")]));
   end;

   declare
      Examples_Out : constant String := To_String (Work_Dir) & "/examples.txt";
      Ok           : Boolean := False;
   begin
      if Files.File_Exists (Examples_Bin) then
         if Run_Captured (Repo, Examples_Bin, Examples_Out) = 0
           and then File_Has_All (Examples_Out, [U ("identity_lifecycle:ok")])
         then
            Ok := True;
         end if;
      end if;
      Record_Case ("identity_examples builds and identity_lifecycle runs", Ok);
   end;

   Record_Case
     ("identity_tools builds and executable reports version metadata",
      Reports_Version (Read_File (To_String (Baseline_File))));

   ---------------------------------------------------------------------------
   --  Negative cases
   ---------------------------------------------------------------------------

   declare
      Name    : constant String :=
        "identity_tools exits nonzero on architecture boundary violations";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Architecture (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "architecture:boundary-term:" & Sep & "identity-versions.ads",
         "architecture:crypto-import:" & Sep & "identity-events-types.ads");
   end;

   declare
      Name    : constant String :=
        "identity_tools exits nonzero on canary secret leaks";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Canary (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "secret-leak:canary:" & Sep & "gate-selftest-canary.md");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when the coverage suite reports a failure";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Coverage_Evidence (Dir);
   begin
      Run_Negative (Name, Dir, Applied, "evidence:failed:coverage");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when a public event constant lacks registry"
        & " coverage";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Registry_Event (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied, "events:missing-registry:identity.api-key.revoked");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when an event registry entry lacks a public"
        & " constant";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Public_Event (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied, "events:missing-public:identity.api-key.revoked");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when artifacts are marked sensitive";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Sensitive_Artifact (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "identity_tools:release-validation:" & Sep & ":sensitive: 1:");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when required release artifacts are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Required_Artifact (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "release-artifacts:missing-artifact:identity.artifact-digests");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when compatibility requirements are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Requirement (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "persisted-formats:missing-requirement:" & DQ & "bounded" & DQ
         & ": true");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when persisted format entries are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Drop_Format (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "persisted-formats:missing-format:identity.event.canonical-envelope");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when persisted fixture files are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Fixture_File (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "persisted-formats:missing-fixture-file:fixtures/persisted-formats/"
         & "secret-verifier-current.json");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when mandatory algorithm entries are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Drop_Algorithm (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "crypto-algorithms:missing-algorithm:identity.sha256-domain-verifier");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when cryptolib implementation binding is missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Implementation (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "crypto-algorithms:missing-field:" & DQ & "implementation" & DQ
         & ": " & DQ & "cryptolib" & DQ);
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when creation and verification permissions are"
        & " missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Permissions (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "crypto-algorithms:missing-field:" & DQ & "creation_allowed" & DQ
         & ": true",
         "crypto-algorithms:missing-field:" & DQ & "verification_allowed" & DQ
         & ": true");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when invariant failure severity is missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Drop_Severity (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "identity_tools:invariants:" & Sep & ":severity: 79:");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when invariant required tests are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Empty_Required_Tests (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied,
         "identity_tools:invariants:" & Sep & ":empty-required-tests: 1:");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when mandatory gate identifiers are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Drop_Gate (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied, "workflows:missing-gate:identity-tools-events");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when required workflow names are missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean := Dir /= "" and then Mut_Drop_Workflow (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied, "workflows:missing-workflow:fixtures-check");
   end;

   declare
      Name    : constant String :=
        "identity_tools fails when project_tools orchestration is missing";
      Dir     : constant String := Make_Copy;
      Applied : constant Boolean :=
        Dir /= "" and then Mut_Drop_Orchestrator (Dir);
   begin
      Run_Negative
        (Name, Dir, Applied, "workflows:missing-orchestrator:project_tools");
   end;

   --  Release reports are gated on validation.
   declare
      Name    : constant String :=
        "identity_tools writes release reports only after validation passes";
      Dir     : constant String := Make_Copy;
      Ok      : Boolean := False;
      Status  : Integer;
      Written : Natural;
   begin
      if Dir = "" then
         Note (Name & ": repository copy failed");
      else
         Files.Delete_Tree (Dir & "/generated/release");
         if Edit_File
              (Dir & "/registries/release-artifacts.json", "delete-all",
               DQ & "identity.release-provenance" & DQ)
         then
            Status := Run_Captured (Dir, Tool, To_String (Out_File));
            Written := Count_Files (Dir & "/generated/release");
            if Status = 0 then
               Note (Name & ": tool exited 0 after mutation");
            elsif not Has_Requirement
                        (To_String (Out_File),
                         "identity_tools:release-reports: 0:write-failures: 0:"
                         & "skipped: 1")
            then
               Note (Name & ": report generation was not skipped");
            elsif Written /= 0 then
               Note
                 (Name & ": " & Img (Written)
                  & " report file(s) written despite failing gates");
            else
               Ok := True;
            end if;
         else
            Note (Name & ": mutation did not apply");
         end if;
         Files.Delete_Tree (Dir);
      end if;
      Record_Case (Name, Ok);
   end;

   ---------------------------------------------------------------------------
   --  Positive cases -- the tool reports the counts it claims to report
   ---------------------------------------------------------------------------

   Base_Line
     ("identity_tools reports architecture boundary counts",
      [U ("identity_tools:architecture:"), U (":internal:"),
       U (":crypto-violations:"), U (":boundary-terms:")]);

   Base_Line
     ("identity_tools reports canary secret-leak counts",
      [U ("identity_tools:secret-leaks:"), U (":canary-hits:")]);

   Base_Line
     ("identity_tools reports crypto algorithm validation counts",
      [U ("identity_tools:crypto-validation: 2:classes: 2:"),
       U (":missing-algorithms: 0:missing-fields: 0")]);

   Base_Line
     ("identity_tools reports event registry coverage counts",
      [U ("identity_tools:events:"), U (":missing-public: 0:missing-registry: 0")]);

   declare
      Name           : constant String :=
        "identity_tools event registry and public constants agree in count";
      Registry_Count : constant Natural :=
        Count_Lines_Containing
          (Repo & "/registries/event-types.json", DQ & "identity.");
      Public_Count   : constant Natural :=
        Count_Lines_Containing
          (Repo & "/src/public/identity-events-types.ads",
           "constant Identity.Identifiers.Registry.Registry_Id");
      Ok             : constant Boolean :=
        Registry_Count > 0
        and then Registry_Count = Public_Count
        and then Line_Has_All
          (To_String (Baseline_File),
           [U ("identity_tools:events: " & Img (Registry_Count) & ":public: "
               & Img (Public_Count) & ":"),
            U (":missing-public: 0:missing-registry: 0")]);
   begin
      if not Ok then
         Note ("registry=" & Img (Registry_Count) & " public="
               & Img (Public_Count));
      end if;
      Record_Case (Name, Ok);
   end;

   declare
      Events_Registry : constant String := Repo & "/registries/event-types.json";
      Events_Public   : constant String :=
        Repo & "/src/public/identity-events-types.ads";
      Expected        : constant Str_Array :=
        [U ("identity.api-key.authenticated"),
         U ("identity.api-key.revoked"),
         U ("identity.totp.replay-detected"),
         U ("identity.external.assertion.replay-detected")];
   begin
      Record_Case
        ("identity_tools reports expanded V1 event registry coverage",
         Line_Has_All
           (To_String (Baseline_File),
            [U ("identity_tools:events:"),
             U (":missing-public: 0:missing-registry: 0")])
         and then File_Has_All (Events_Registry, Expected)
         and then File_Has_All (Events_Public, Expected));
   end;

   Base_Line
     ("identity_tools reports invariant registry traceability counts",
      [U ("identity_tools:invariants:"), U (":required-tests:"),
       U (":test-names:"), U (":traced:"), U (":untraced:")]);

   Base_Line
     ("identity_tools reports persisted format inventory counts",
      [U ("identity_tools:persisted-formats: 3:fixtures: 12")]);

   Base_Line
     ("identity_tools reports persisted-format validation counts",
      [U ("identity_tools:persisted-validation: 3:fixtures: 12:"),
       U (":missing-formats: 0:missing-fixtures: 0:missing-requirements: 0:"),
       U (":missing-files: 0")]);

   Base_Line
     ("identity_tools reports proof-scope validation counts",
      [U ("identity_tools:proof-validation:"),
       U (":missing-packages: 0:missing-properties: 0:")]);

   Base_Line
     ("identity_tools reports release artifact inventory counts",
      [U ("identity_tools:release-artifacts: 15:prohibited: 8:"
          & "provenance-fields: 9")]);

   Base_Line
     ("identity_tools reports release artifact validation counts",
      [U ("identity_tools:release-validation: 15:required: 15:"),
       U (":missing-artifacts: 0:missing-prohibited: 0:")]);

   Base_Line
     ("identity_tools reports release provenance field coverage",
      [U ("identity_tools:release-validation:"), U (":provenance-fields: 9:"),
       U (":missing-provenance: 0")]);

   Base_Line
     ("release artifact registry parses",
      [U ("identity_tools:release-validation:"),
       U (":missing-artifacts: 0:missing-prohibited: 0:missing-provenance: 0")]);

   --  The registry parsing and the on-disk fixture inventory are asserted
   --  together: ":missing-files: 0" is the tool's own statement that every
   --  fixture path listed in registries/persisted-formats.json resolves to a
   --  file, and the loop re-checks that claim independently so the case cannot
   --  pass on a marker alone.
   declare
      Name : constant String :=
        "persisted format registry parses and every listed fixture exists";
      Ok   : Boolean := False;
   begin
      if Line_Has_All
           (To_String (Baseline_File),
            [U ("identity_tools:persisted-validation:"),
             U (":missing-formats: 0:missing-fixtures: 0:"),
             U (":missing-files: 0")])
      then
         Ok := True;
         declare
            Fixtures : constant Str_Array :=
              Persisted_Fixtures (Repo & "/registries/persisted-formats.json");
         begin
            for Fixture of Fixtures loop
               if not Files.File_Exists
                        (Files.Join (Repo, To_String (Fixture)))
               then
                  Note (Name & ": missing fixture: " & To_String (Fixture));
                  Ok := False;
               end if;
            end loop;
         end;
      else
         Note (Name & ": baseline marker absent");
      end if;
      Record_Case (Name, Ok);
   end;

   Base_Line
     ("identity_tools reports release report generation counts",
      [U ("identity_tools:release-reports:"), U (":write-failures:"),
       U (":skipped:")]);

   Base_Line
     ("identity_tools reports workflow validation counts",
      [U ("identity_tools:workflows: 9:gates: 43:"),
       U (":missing-workflows: 0:missing-gates: 0:missing-orchestrator: 0:")]);

   ---------------------------------------------------------------------------
   --  Positive cases -- project_tools workflow manifest content
   ---------------------------------------------------------------------------

   Record_Case
     ("project_tools workflow manifest parses and lists mandatory gates",
      File_Has_All
        (Manifest,
         [U ("required = " & DQ & "project_tools" & DQ),
          U ("name = " & DQ & "release-check" & DQ)])
      and then Line_Has_All
        (To_String (Baseline_File),
         [U ("identity_tools:workflows:"),
          U (":missing-workflows: 0:missing-gates: 0:missing-orchestrator: 0:"
             & "missing-project-metadata: 0")]));

   Manifest_Gate
     ("project_tools workflows include identity-tools-architecture gate",
      "identity-tools-architecture");
   Manifest_Gate
     ("project_tools workflows include identity-tools-crypto-validation gate",
      "identity-tools-crypto-validation");
   Manifest_Gate
     ("project_tools workflows include identity-tools-events gate",
      "identity-tools-events");
   Manifest_Gate
     ("project_tools workflows include identity-tools-invariants gate",
      "identity-tools-invariants");
   Manifest_Gate
     ("project_tools workflows include identity-tools-persisted-validation gate",
      "identity-tools-persisted-validation");
   Manifest_Gate
     ("project_tools workflows include identity-tools-release-validation gate",
      "identity-tools-release-validation");
   Manifest_Gate
     ("project_tools workflows include identity-tools-secret-leaks gate",
      "identity-tools-secret-leaks");
   Manifest_Gate
     ("project_tools workflows include identity-tools-workflows gate",
      "identity-tools-workflows");

   ---------------------------------------------------------------------------
   --  Summary
   ---------------------------------------------------------------------------

   Ada.Text_IO.Put_Line
     ("gate-selftest:total:" & Img (Total_Cases) & ":passed:"
      & Img (Passed_Cases) & ":failed:" & Img (Failed_Cases));

   Files.Delete_Tree (To_String (Work_Dir));

   if Failed_Cases /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Gate_Selftests;
